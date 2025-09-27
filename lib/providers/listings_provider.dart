import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';

class ListingsProvider with ChangeNotifier {
  List<Listing> _listings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMoreListings = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  List<Listing> get listings => _listings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreListings => _hasMoreListings;

  Future<void> loadListings({bool refresh = false, String? location}) async {
    if (refresh) {
      _listings.clear();
      _currentOffset = 0;
      _hasMoreListings = true;
    }

    if (_isLoading || !_hasMoreListings) return;

    _setLoading(true);
    _clearError();

    try {
      final newListings = await ApiService.getListings(
        limit: _pageSize,
        offset: _currentOffset,
        location: location,
      );

      if (newListings.length < _pageSize) {
        _hasMoreListings = false;
      }

      _listings.addAll(newListings);
      _currentOffset += newListings.length;
      
    } catch (e) {
      print('Listings Provider Error: $e');
      _setError('Failed to load listings: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLandlordListings(String landlordId) async {
    _setLoading(true);
    _clearError();

    try {
      final landlordListings = await ApiService.getListings(landlordId: landlordId);
      _listings = landlordListings;
    } catch (e) {
      _setError('Failed to load your listings');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createListing(Map<String, dynamic> listingData) async {
    _setLoading(true);
    _clearError();

    try {
      final newListing = await ApiService.createListing(listingData);
      _listings.insert(0, newListing);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create listing');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateListing(String id, Map<String, dynamic> listingData) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedListing = await ApiService.updateListing(id, listingData);
      final index = _listings.indexWhere((listing) => listing.id == id);
      if (index != -1) {
        _listings[index] = updatedListing;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update listing');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteListing(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.deleteListing(id);
      _listings.removeWhere((listing) => listing.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete listing');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Listing? getListingById(String id) {
    try {
      return _listings.firstWhere((listing) => listing.id == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}