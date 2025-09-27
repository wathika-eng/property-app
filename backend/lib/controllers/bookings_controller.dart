import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';

class BookingsController {
  static const _uuid = Uuid();

  static Future<Response> getBookings(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final isLandlord = request.context['isLandlord'] as bool;
      final db = DatabaseService.database;

      String query;
      List<String> params;

      if (isLandlord) {
        // Landlord sees bookings for their listings
        query = '''
          SELECT b.*, l.landlord_id
          FROM bookings b
          JOIN listings l ON b.listing_id = l.id
          WHERE l.landlord_id = ?
          ORDER BY b.created_at DESC
        ''';
        params = [userId];
      } else {
        // User sees their own bookings
        query = 'SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC';
        params = [userId];
      }

      final result = db.select(query, params);
      
      final bookings = result.map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'user_name': row['user_name'],
          'listing_id': row['listing_id'],
          'listing_title': row['listing_title'],
          'check_in': row['check_in'],
          'check_out': row['check_out'],
          'guests': row['guests'],
          'total_price': row['total_price'],
          'status': row['status'],
          'created_at': row['created_at'],
        };
      }).toList();

      return Response.ok(
        json.encode({'bookings': bookings}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch bookings'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> createBooking(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final userId = request.context['userId'] as String;

      final listingId = data['listing_id'] as String?;
      final checkIn = data['check_in'] as String?;
      final checkOut = data['check_out'] as String?;
      final guests = data['guests'] as num?;
      final totalPrice = data['total_price'] as num?;

      if (listingId == null || checkIn == null || checkOut == null ||
          guests == null || totalPrice == null) {
        return Response.badRequest(
          body: json.encode({'error': 'All booking fields are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Get listing and user info
      final listingResult = db.select(
        'SELECT title, max_guests, landlord_id FROM listings WHERE id = ? AND is_available = 1',
        [listingId],
      );

      if (listingResult.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Listing not found or not available'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userResult = db.select(
        'SELECT name FROM users WHERE id = ?',
        [userId],
      );

      if (userResult.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final listing = listingResult.first;
      final user = userResult.first;

      // Check if guests exceed max capacity
      if (guests.toInt() > listing['max_guests']) {
        return Response.badRequest(
          body: json.encode({'error': 'Number of guests exceeds maximum capacity'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if user is not booking their own listing
      if (listing['landlord_id'] == userId) {
        return Response.badRequest(
          body: json.encode({'error': 'You cannot book your own listing'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse dates
      final checkInDate = DateTime.parse(checkIn);
      final checkOutDate = DateTime.parse(checkOut);

      if (checkOutDate.isBefore(checkInDate) || checkInDate.isBefore(DateTime.now())) {
        return Response.badRequest(
          body: json.encode({'error': 'Invalid booking dates'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check for conflicting bookings
      final conflicts = db.select(
        '''SELECT id FROM bookings 
           WHERE listing_id = ? AND status != 'cancelled'
           AND ((check_in <= ? AND check_out > ?) OR (check_in < ? AND check_out >= ?))''',
        [listingId, checkIn, checkIn, checkOut, checkOut],
      );

      if (conflicts.isNotEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Listing is not available for these dates'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final bookingId = _uuid.v4();
      final createdAt = DateTime.now();

      db.execute(
        '''INSERT INTO bookings (id, user_id, user_name, listing_id, listing_title,
           check_in, check_out, guests, total_price, status, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          bookingId, userId, user['name'], listingId, listing['title'],
          checkIn, checkOut, guests.toInt(), totalPrice.toDouble(),
          'confirmed', createdAt.toIso8601String(),
        ],
      );

      return Response.ok(
        json.encode({
          'booking': {
            'id': bookingId,
            'user_id': userId,
            'user_name': user['name'],
            'listing_id': listingId,
            'listing_title': listing['title'],
            'check_in': checkIn,
            'check_out': checkOut,
            'guests': guests.toInt(),
            'total_price': totalPrice.toDouble(),
            'status': 'confirmed',
            'created_at': createdAt.toIso8601String(),
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create booking'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> updateBookingStatus(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final userId = request.context['userId'] as String;
      final isLandlord = request.context['isLandlord'] as bool;

      final status = data['status'] as String?;

      if (status == null || !['pending', 'confirmed', 'cancelled'].contains(status)) {
        return Response.badRequest(
          body: json.encode({'error': 'Valid status is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if booking exists and user has permission
      String query;
      List<String> params;

      if (isLandlord) {
        query = '''
          SELECT b.id FROM bookings b
          JOIN listings l ON b.listing_id = l.id
          WHERE b.id = ? AND l.landlord_id = ?
        ''';
        params = [id, userId];
      } else {
        query = 'SELECT id FROM bookings WHERE id = ? AND user_id = ?';
        params = [id, userId];
      }

      final result = db.select(query, params);

      if (result.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Booking not found or access denied'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      db.execute(
        'UPDATE bookings SET status = ? WHERE id = ?',
        [status, id],
      );

      return Response.ok(
        json.encode({'message': 'Booking status updated successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to update booking status'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}