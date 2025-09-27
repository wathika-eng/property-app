import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../models/booking.dart';
import '../models/bookmark.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;
  
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Authentication
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    bool isLandlord = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConstants.authRegister}'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
        'is_landlord': isLandlord,
      }),
    );

    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      // Save token and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, data['token']);
      await prefs.setString(AppConstants.userKey, json.encode(data['user']));
      await prefs.setBool(AppConstants.isLandlordKey, data['user']['is_landlord']);
    }
    
    return {
      'success': response.statusCode == 200,
      'data': data,
    };
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConstants.authLogin}'),
      headers: await _getHeaders(includeAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      // Save token and user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, data['token']);
      await prefs.setString(AppConstants.userKey, json.encode(data['user']));
      await prefs.setBool(AppConstants.isLandlordKey, data['user']['is_landlord']);
    }
    
    return {
      'success': response.statusCode == 200,
      'data': data,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.isLandlordKey);
  }

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        return User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getAuthToken();
    return token != null;
  }

  // Listings
  static Future<List<Listing>> getListings({
    int limit = 20,
    int offset = 0,
    String? location,
    String? landlordId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (location != null) queryParams['location'] = location;
    if (landlordId != null) queryParams['landlord_id'] = landlordId;

    final uri = Uri.parse('$baseUrl${AppConstants.listings}').replace(
      queryParameters: queryParams,
    );

    try {
      // Don't require auth for general listings - allow guest browsing
      final response = await http.get(uri, headers: await _getHeaders(includeAuth: false));
      
      print('API Request: ${uri.toString()}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final listingsJson = data['listings'] as List;
        return listingsJson.map((json) => Listing.fromJson(json)).toList();
      }
      
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('API Service Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Listing> getListing(String id) async {
    // Don't require auth for viewing individual listings - allow guest browsing
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.listings}/$id'),
      headers: await _getHeaders(includeAuth: false),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Listing.fromJson(data['listing']);
    }
    
    throw Exception('Failed to load listing');
  }

  static Future<Listing> createListing(Map<String, dynamic> listingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConstants.listings}'),
      headers: await _getHeaders(),
      body: json.encode(listingData),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Listing.fromJson(data['listing']);
    }
    
    throw Exception('Failed to create listing');
  }

  static Future<Listing> updateListing(String id, Map<String, dynamic> listingData) async {
    final response = await http.put(
      Uri.parse('$baseUrl${AppConstants.listings}/$id'),
      headers: await _getHeaders(),
      body: json.encode(listingData),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Listing.fromJson(data['listing']);
    }
    
    throw Exception('Failed to update listing');
  }

  static Future<void> deleteListing(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl${AppConstants.listings}/$id'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete listing');
    }
  }

  // Bookmarks
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.bookmarks}'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['bookmarks']);
    }
    
    throw Exception('Failed to load bookmarks');
  }

  static Future<void> addBookmark(String listingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConstants.bookmarks}'),
      headers: await _getHeaders(),
      body: json.encode({'listing_id': listingId}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to add bookmark');
    }
  }

  static Future<void> removeBookmark(String listingId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl${AppConstants.bookmarks}/$listingId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to remove bookmark');
    }
  }

  static Future<bool> isBookmarked(String listingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.bookmarks}/$listingId/check'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_bookmarked'] ?? false;
    }
    
    return false;
  }

  // Bookings
  static Future<List<Booking>> getBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl${AppConstants.bookings}'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final bookingsJson = data['bookings'] as List;
      return bookingsJson.map((json) => Booking.fromJson(json)).toList();
    }
    
    throw Exception('Failed to load bookings');
  }

  static Future<Booking> createBooking({
    required String listingId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConstants.bookings}'),
      headers: await _getHeaders(),
      body: json.encode({
        'listing_id': listingId,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'guests': guests,
        'total_price': totalPrice,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Booking.fromJson(data['booking']);
    }
    
    final errorData = json.decode(response.body);
    throw Exception(errorData['error'] ?? 'Failed to create booking');
  }

  static Future<void> updateBookingStatus(String bookingId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl${AppConstants.bookings}/$bookingId/status'),
      headers: await _getHeaders(),
      body: json.encode({'status': status}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update booking status');
    }
  }

  // Reviews
  static Future<Map<String, dynamic>> getReviews(String listingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/listings/$listingId/reviews'),
      headers: await _getHeaders(includeAuth: false),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  static Future<Map<String, dynamic>> createReview({
    required String listingId,
    required double rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: await _getHeaders(),
      body: json.encode({
        'listing_id': listingId,
        'rating': rating,
        'comment': comment,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create review');
    }
  }

  static Future<Map<String, dynamic>> getUserReviews() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reviews/user'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user reviews');
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/reviews/$reviewId'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete review');
    }
  }
}