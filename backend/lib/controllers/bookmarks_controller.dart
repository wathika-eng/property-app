import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';

class BookmarksController {
  static const _uuid = Uuid();

  static Future<Response> getBookmarks(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final db = DatabaseService.database;

      final result = db.select(
        '''SELECT b.*, l.title, l.price, l.location, l.images, l.rating, l.landlord_name
           FROM bookmarks b 
           JOIN listings l ON b.listing_id = l.id 
           WHERE b.user_id = ? 
           ORDER BY b.created_at DESC''',
        [userId],
      );

      final bookmarks = result.map((row) {
        return {
          'id': row['id'],
          'user_id': row['user_id'],
          'listing_id': row['listing_id'],
          'created_at': row['created_at'],
          'listing': {
            'id': row['listing_id'],
            'title': row['title'],
            'price': row['price'],
            'location': row['location'],
            'images': row['images'].toString().split(','),
            'rating': row['rating'],
            'landlord_name': row['landlord_name'],
          },
        };
      }).toList();

      return Response.ok(
        json.encode({'bookmarks': bookmarks}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch bookmarks'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> addBookmark(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      final userId = request.context['userId'] as String;

      final listingId = data['listing_id'] as String?;

      if (listingId == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Listing ID is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if listing exists
      final listingExists = db.select(
        'SELECT id FROM listings WHERE id = ?',
        [listingId],
      );

      if (listingExists.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Listing not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if bookmark already exists
      final existing = db.select(
        'SELECT id FROM bookmarks WHERE user_id = ? AND listing_id = ?',
        [userId, listingId],
      );

      if (existing.isNotEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'Listing already bookmarked'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final bookmarkId = _uuid.v4();
      final createdAt = DateTime.now();

      db.execute(
        'INSERT INTO bookmarks (id, user_id, listing_id, created_at) VALUES (?, ?, ?, ?)',
        [bookmarkId, userId, listingId, createdAt.toIso8601String()],
      );

      return Response.ok(
        json.encode({
          'bookmark': {
            'id': bookmarkId,
            'user_id': userId,
            'listing_id': listingId,
            'created_at': createdAt.toIso8601String(),
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to add bookmark'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> removeBookmark(Request request, String listingId) async {
    try {
      final userId = request.context['userId'] as String;
      final db = DatabaseService.database;

      final result = db.execute(
        'DELETE FROM bookmarks WHERE user_id = ? AND listing_id = ?',
        [userId, listingId],
      );

      return Response.ok(
        json.encode({'message': 'Bookmark removed successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to remove bookmark'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> checkBookmark(Request request, String listingId) async {
    try {
      final userId = request.context['userId'] as String;
      final db = DatabaseService.database;

      final result = db.select(
        'SELECT id FROM bookmarks WHERE user_id = ? AND listing_id = ?',
        [userId, listingId],
      );

      return Response.ok(
        json.encode({'is_bookmarked': result.isNotEmpty}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to check bookmark'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}