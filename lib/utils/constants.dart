class AppConstants {
  static const String appName = 'StaySpace';
  static const String baseUrl = 'https://property-app-backend-9typ.onrender.com/api';
  
  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String listings = '/listings';
  static const String bookings = '/bookings';
  static const String bookmarks = '/bookmarks';
  static const String users = '/users';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String isLandlordKey = 'is_landlord';
  
  // Default Values
  static const int defaultListingLimit = 20;
  static const double defaultImageAspectRatio = 1.2;
  
  // Sample Images for Demo
  static const List<String> sampleImages = [
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
  ];
  
  // Sample Amenities
  static const List<String> availableAmenities = [
    'WiFi',
    'Kitchen',
    'Air Conditioning',
    'Heating',
    'Parking',
    'Pool',
    'Gym',
    'Laundry',
    'TV',
    'Workspace',
    'Balcony',
    'Garden',
    'Pet Friendly',
    'Wheelchair Accessible',
  ];
}