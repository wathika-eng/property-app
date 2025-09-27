import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookmarksProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookmarks = [];
  Set<String> _bookmarkedListingIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isBookmarked(String listingId) => _bookmarkedListingIds.contains(listingId);

  Future<void> loadBookmarks() async {
    _setLoading(true);
    _clearError();

    try {
      _bookmarks = await ApiService.getBookmarks();
      _bookmarkedListingIds = _bookmarks
          .map((bookmark) => bookmark['listing_id'] as String)
          .toSet();
    } catch (e) {
      _setError('Failed to load bookmarks');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleBookmark(String listingId) async {
    final wasBookmarked = _bookmarkedListingIds.contains(listingId);
    
    // Optimistically update UI
    if (wasBookmarked) {
      _bookmarkedListingIds.remove(listingId);
      _bookmarks.removeWhere((bookmark) => bookmark['listing_id'] == listingId);
    } else {
      _bookmarkedListingIds.add(listingId);
    }
    notifyListeners();

    try {
      if (wasBookmarked) {
        await ApiService.removeBookmark(listingId);
      } else {
        await ApiService.addBookmark(listingId);
      }
      return true;
    } catch (e) {
      // Revert optimistic update on error
      if (wasBookmarked) {
        _bookmarkedListingIds.add(listingId);
      } else {
        _bookmarkedListingIds.remove(listingId);
        _bookmarks.removeWhere((bookmark) => bookmark['listing_id'] == listingId);
      }
      notifyListeners();
      _setError(wasBookmarked ? 'Failed to remove bookmark' : 'Failed to add bookmark');
      return false;
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