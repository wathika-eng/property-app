import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/review.dart';

class ReviewsController {
  static const _uuid = Uuid();

  static Future<Response> getReviewsForListing(Request request, String listingId) async {
    try {
      final db = DatabaseService.database;
      
      final reviews = db.select('''
        SELECT r.*, u.name as user_name, u.profile_image as user_profile_image
        FROM reviews r
        JOIN users u ON r.user_id = u.id
        WHERE r.listing_id = ?
        ORDER BY r.created_at DESC
      ''', [listingId]);

      final reviewList = reviews.map((row) => Review.fromRow(row).toJson()).toList();

      return Response.ok(
        json.encode({'reviews': reviewList}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch reviews'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> createReview(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      
      // Get user info from request context (set by auth middleware)
      final userId = request.context['userId'] as String;
      final userEmail = request.context['userEmail'] as String;

      final listingId = data['listing_id'] as String?;
      final rating = data['rating'] as num?;
      final comment = data['comment'] as String?;

      if (listingId == null || rating == null || comment == null) {
        return Response.badRequest(
          body: json.encode({'error': 'Listing ID, rating, and comment are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (rating < 1 || rating > 5) {
        return Response.badRequest(
          body: json.encode({'error': 'Rating must be between 1 and 5'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final db = DatabaseService.database;

      // Check if user has already reviewed this listing
      final existingReview = db.select(
        'SELECT id FROM reviews WHERE user_id = ? AND listing_id = ?',
        [userId, listingId],
      );

      if (existingReview.isNotEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'You have already reviewed this listing'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get user name
      final userResult = db.select('SELECT name, profile_image FROM users WHERE id = ?', [userId]);
      if (userResult.isEmpty) {
        return Response.badRequest(
          body: json.encode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final userName = userResult.first['name'] as String;
      final userProfileImage = userResult.first['profile_image'] as String?;

      // Create review
      final review = Review(
        id: _uuid.v4(),
        listingId: listingId,
        userId: userId,
        userName: userName,
        userProfileImage: userProfileImage,
        rating: rating.toDouble(),
        comment: comment,
        createdAt: DateTime.now(),
      );

      db.execute(
        '''INSERT INTO reviews (id, listing_id, user_id, user_name, user_profile_image, rating, comment, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          review.id,
          review.listingId,
          review.userId,
          review.userName,
          review.userProfileImage,
          review.rating,
          review.comment,
          review.createdAt.toIso8601String(),
        ],
      );

      // Update listing's average rating and review count
      final ratingResult = db.select(
        'SELECT AVG(rating) as avg_rating, COUNT(*) as review_count FROM reviews WHERE listing_id = ?',
        [listingId],
      );

      if (ratingResult.isNotEmpty) {
        final avgRating = (ratingResult.first['avg_rating'] as num).toDouble();
        final reviewCount = ratingResult.first['review_count'] as int;

        db.execute(
          'UPDATE listings SET rating = ?, review_count = ? WHERE id = ?',
          [avgRating, reviewCount, listingId],
        );
      }

      return Response.ok(
        json.encode({
          'message': 'Review created successfully',
          'review': review.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to create review'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> getUserReviews(Request request) async {
    try {
      // Get user info from request context (set by auth middleware)
      final userId = request.context['userId'] as String;

      final db = DatabaseService.database;
      
      final reviews = db.select('''
        SELECT r.*, l.title as listing_title, l.images as listing_images
        FROM reviews r
        JOIN listings l ON r.listing_id = l.id
        WHERE r.user_id = ?
        ORDER BY r.created_at DESC
      ''', [userId]);

      final reviewList = reviews.map((row) {
        final review = Review.fromRow(row);
        final reviewJson = review.toJson();
        reviewJson['listing_title'] = row['listing_title'];
        reviewJson['listing_images'] = row['listing_images'];
        return reviewJson;
      }).toList();

      return Response.ok(
        json.encode({'reviews': reviewList}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to fetch user reviews'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  static Future<Response> deleteReview(Request request, String reviewId) async {
    try {
      // Get user info from request context (set by auth middleware)
      final userId = request.context['userId'] as String;

      final db = DatabaseService.database;

      // Check if review exists and belongs to user
      final reviewResult = db.select(
        'SELECT listing_id FROM reviews WHERE id = ? AND user_id = ?',
        [reviewId, userId],
      );

      if (reviewResult.isEmpty) {
        return Response.notFound(
          json.encode({'error': 'Review not found or access denied'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final listingId = reviewResult.first['listing_id'] as String;

      // Delete review
      db.execute('DELETE FROM reviews WHERE id = ?', [reviewId]);

      // Update listing's average rating and review count
      final ratingResult = db.select(
        'SELECT AVG(rating) as avg_rating, COUNT(*) as review_count FROM reviews WHERE listing_id = ?',
        [listingId],
      );

      if (ratingResult.isNotEmpty && ratingResult.first['review_count'] as int > 0) {
        final avgRating = (ratingResult.first['avg_rating'] as num).toDouble();
        final reviewCount = ratingResult.first['review_count'] as int;

        db.execute(
          'UPDATE listings SET rating = ?, review_count = ? WHERE id = ?',
          [avgRating, reviewCount, listingId],
        );
      } else {
        // No reviews left, reset to 0
        db.execute(
          'UPDATE listings SET rating = 0.0, review_count = 0 WHERE id = ?',
          [listingId],
        );
      }

      return Response.ok(
        json.encode({'message': 'Review deleted successfully'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to delete review'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}