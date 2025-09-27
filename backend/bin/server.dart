import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/services/database_service.dart';
import '../lib/controllers/auth_controller.dart';
import '../lib/controllers/listings_controller.dart';
import '../lib/controllers/bookmarks_controller.dart';
import '../lib/controllers/bookings_controller.dart';
import '../lib/controllers/reviews_controller.dart';
import '../lib/utils/middleware.dart';
import '../lib/services/seed_data.dart';

void main() async {
  // Initialize database
  DatabaseService.database;
  
  // Seed demo data
  await SeedData.seedDatabase();

  // Configure routes
  final router = Router();

  // Auth routes (no auth middleware)
  router.post('/api/auth/register', AuthController.register);
  router.post('/api/auth/login', AuthController.login);
  router.get('/api/auth/profile', AuthController.profile);

  // Listings routes
  router.get('/api/listings', ListingsController.getListings);
  router.get('/api/listings/<id>', ListingsController.getListing);
  router.post('/api/listings', ListingsController.createListing);
  router.put('/api/listings/<id>', ListingsController.updateListing);
  router.delete('/api/listings/<id>', ListingsController.deleteListing);

  // Bookmarks routes
  router.get('/api/bookmarks', BookmarksController.getBookmarks);
  router.post('/api/bookmarks', BookmarksController.addBookmark);
  router.delete('/api/bookmarks/<listingId>', BookmarksController.removeBookmark);
  router.get('/api/bookmarks/<listingId>/check', BookmarksController.checkBookmark);

  // Bookings routes
  router.get('/api/bookings', BookingsController.getBookings);
  router.post('/api/bookings', BookingsController.createBooking);
  router.put('/api/bookings/<id>/status', BookingsController.updateBookingStatus);

  // Reviews routes
  router.get('/api/listings/<listingId>/reviews', ReviewsController.getReviewsForListing);
  router.post('/api/reviews', ReviewsController.createReview);
  router.get('/api/reviews/user', ReviewsController.getUserReviews);
  router.delete('/api/reviews/<reviewId>', ReviewsController.deleteReview);

  // Configure middleware pipeline
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware())
      .addHandler(router);

  // Start server
  final server = await serve(pipeline, 'localhost', 8080);
  print('StaySpace Backend Server running on http://${server.address.host}:${server.port}');

  // Handle shutdown gracefully
  ProcessSignal.sigint.watch().listen((signal) {
    print('Shutting down server...');
    DatabaseService.close();
    server.close(force: true);
  });
}