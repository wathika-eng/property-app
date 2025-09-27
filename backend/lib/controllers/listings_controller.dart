import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/listing.dart';

class ListingsController {
  static const _uuid = Uuid();

  static Future<Response> getListings(Request request) async {
    try {
      final db = DatabaseService.database;
      final queryParams = request.url.queryParameters;
      
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
      final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;
      final location = queryParams['location'];
      final landlordId = queryParams['landlord_id'];

      String query = 'SELECT * FROM listings WHERE is_available = 1';
      List<String> params = [];

      if (location != null && location.isNotEmpty) {
        query += ' AND location LIKE ?';
        params.add('%$location%');
      }

      if (landlordId != null && landlordId.isNotEmpty) {
        query += ' AND landlord_id = ?';
        params.add(landlordId);
      }

      query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
      params.addAll([limit.toString(), offset.toString()]);

      final result = db.select(query, params);
      final listings = result.map((row) => Listing.fromMap(row).toJson()).toList();

      return Response.ok(
        json.encode({'listings': listings}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch listings'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getListing(Request request, String id) async {
    try {
      final db = DatabaseService.database;

      final result = db.select(
        'SELECT * FROM listings WHERE id = ?',
        [id],
      );

      if (result.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Listing not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final listing = Listing.fromMap(result.first);

      return Response.ok(
        json.encode({'listing': listing.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch listing'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> createListing(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final userId = request.context['userId'] as String;
      final isLandlord = request.context['isLandlord'] as bool;

      if (!isLandlord) {
        return Response.forbidden(
          json.encode({'error': 'Only landlords can create listings'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final title = data['title'] as String?;
      final description = data['description'] as String?;
      final price = data['price'] as num?;
      final location = data['location'] as String?;
      final address = data['address'] as String?;
      final images = data['images'] as List<dynamic>?;
      final bedrooms = data['bedrooms'] as num?;
      final bathrooms = data['bathrooms'] as num?;
      final maxGuests = data['max_guests'] as num?;
      final amenities = data['amenities'] as List<dynamic>?;
      final landlordName = data['landlord_name'] as String?;

      if (title == null || description == null || price == null ||
          location == null || address == null || images == null ||
          bedrooms == null || bathrooms == null || maxGuests == null ||
          amenities == null || landlordName == null) {
        return Response.badRequest(
          body: json.encode({'error': 'All required fields must be provided'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final listing = Listing(
        id: _uuid.v4(),
        title: title,
        description: description,
        price: price.toDouble(),
        location: location,
        address: address,
        images: images.cast<String>(),
        bedrooms: bedrooms.toInt(),
        bathrooms: bathrooms.toInt(),
        maxGuests: maxGuests.toInt(),
        amenities: amenities.cast<String>(),
        landlordId: userId,
        landlordName: landlordName,
        createdAt: DateTime.now(),
      );

      final db = DatabaseService.database;

      db.execute(
        '''INSERT INTO listings (id, title, description, price, location, address, 
           images, bedrooms, bathrooms, max_guests, amenities, rating, review_count,
           landlord_id, landlord_name, is_available, available_from, available_to, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          listing.id, listing.title, listing.description, listing.price,
          listing.location, listing.address, listing.images.join(','),
          listing.bedrooms, listing.bathrooms, listing.maxGuests,
          listing.amenities.join(','), listing.rating, listing.reviewCount,
          listing.landlordId, listing.landlordName, listing.isAvailable ? 1 : 0,
          listing.availableFrom?.toIso8601String(),
          listing.availableTo?.toIso8601String(),
          listing.createdAt.toIso8601String(),
        ],
      );

      return Response.ok(
        json.encode({'listing': listing.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create listing'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateListing(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final userId = request.context['userId'] as String;
      final isLandlord = request.context['isLandlord'] as bool;

      if (!isLandlord) {
        return Response.forbidden(
          json.encode({'error': 'Only landlords can update listings'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if listing exists and belongs to the landlord
      final existing = db.select(
        'SELECT * FROM listings WHERE id = ? AND landlord_id = ?',
        [id, userId],
      );

      if (existing.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Listing not found or access denied'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final listing = Listing.fromMap(existing.first);
      
      // Update fields if provided
      final updatedListing = Listing(
        id: listing.id,
        title: data['title'] ?? listing.title,
        description: data['description'] ?? listing.description,
        price: data['price']?.toDouble() ?? listing.price,
        location: data['location'] ?? listing.location,
        address: data['address'] ?? listing.address,
        images: data['images']?.cast<String>() ?? listing.images,
        bedrooms: data['bedrooms']?.toInt() ?? listing.bedrooms,
        bathrooms: data['bathrooms']?.toInt() ?? listing.bathrooms,
        maxGuests: data['max_guests']?.toInt() ?? listing.maxGuests,
        amenities: data['amenities']?.cast<String>() ?? listing.amenities,
        rating: listing.rating,
        reviewCount: listing.reviewCount,
        landlordId: listing.landlordId,
        landlordName: listing.landlordName,
        isAvailable: data['is_available'] ?? listing.isAvailable,
        availableFrom: listing.availableFrom,
        availableTo: listing.availableTo,
        createdAt: listing.createdAt,
      );

      db.execute(
        '''UPDATE listings SET title = ?, description = ?, price = ?, location = ?,
           address = ?, images = ?, bedrooms = ?, bathrooms = ?, max_guests = ?,
           amenities = ?, is_available = ?
           WHERE id = ?''',
        [
          updatedListing.title, updatedListing.description, updatedListing.price,
          updatedListing.location, updatedListing.address, updatedListing.images.join(','),
          updatedListing.bedrooms, updatedListing.bathrooms, updatedListing.maxGuests,
          updatedListing.amenities.join(','), updatedListing.isAvailable ? 1 : 0,
          id,
        ],
      );

      return Response.ok(
        json.encode({'listing': updatedListing.toJson()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update listing'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteListing(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final isLandlord = request.context['isLandlord'] as bool;

      if (!isLandlord) {
        return Response.forbidden(
          json.encode({'error': 'Only landlords can delete listings'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if listing exists and belongs to the landlord
      final existing = db.select(
        'SELECT id FROM listings WHERE id = ? AND landlord_id = ?',
        [id, userId],
      );

      if (existing.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Listing not found or access denied'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      db.execute('DELETE FROM listings WHERE id = ?', [id]);

      return Response.ok(
        json.encode({'message': 'Listing deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to delete listing'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}