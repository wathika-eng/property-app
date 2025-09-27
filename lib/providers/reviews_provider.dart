import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewsProvider with ChangeNotifier {
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;
  
  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReviews(String listingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getReviews(listingId);
      final List<dynamic> reviewsJson = response['reviews'];
      _reviews = reviewsJson.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      _reviews = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview({
    required String listingId,
    required double rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createReview(
        listingId: listingId,
        rating: rating,
        comment: comment,
      );

      // Add the new review to the list
      final newReview = Review.fromJson(response['review']);
      _reviews.insert(0, newReview);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Review>> getUserReviews() async {
    try {
      final response = await ApiService.getUserReviews();
      final List<dynamic> reviewsJson = response['reviews'];
      return reviewsJson.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    try {
      await ApiService.deleteReview(reviewId);
      _reviews.removeWhere((review) => review.id == reviewId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearReviews() {
    _reviews.clear();
    _error = null;
    notifyListeners();
  }

  // Check if current user can review (i.e., has booked and completed stay)
  bool canUserReview(String listingId, String userId) {
    // Check if user has already reviewed this listing
    final hasReviewed = _reviews.any((review) => 
        review.listingId == listingId && review.userId == userId);
    
    return !hasReviewed;
  }
}