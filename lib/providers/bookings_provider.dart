import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingsProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBookings() async {
    _setLoading(true);
    _clearError();

    try {
      _bookings = await ApiService.getBookings();
    } catch (e) {
      _setError('Failed to load bookings');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking({
    required String listingId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newBooking = await ApiService.createBooking(
        listingId: listingId,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        totalPrice: totalPrice,
      );
      
      _bookings.insert(0, newBooking);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await ApiService.updateBookingStatus(bookingId, status);
      
      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(status: status);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update booking status');
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