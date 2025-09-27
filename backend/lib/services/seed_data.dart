import 'package:uuid/uuid.dart';
import 'database_service.dart';
import 'auth_service.dart';

class SeedData {
  static const _uuid = Uuid();

  static Future<void> seedDatabase() async {
    final db = DatabaseService.database;

    // Check if data already exists
    final existingUsers = db.select('SELECT COUNT(*) as count FROM users');
    if (existingUsers.first['count'] > 0) {
      print('Database already seeded, skipping...');
      return;
    }

    print('Seeding database with demo data...');

    // Seed users
    final users = _createDemoUsers();
    for (final user in users) {
      db.execute(
        '''INSERT INTO users (id, email, password_hash, name, profile_image, is_landlord, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          user['id'],
          user['email'],
          user['password_hash'],
          user['name'],
          user['profile_image'],
          user['is_landlord'],
          user['created_at'],
        ],
      );
    }

    // Seed listings
    final listings = _createDemoListings();
    for (final listing in listings) {
      db.execute(
        '''INSERT INTO listings (id, title, description, price, location, address, 
           images, bedrooms, bathrooms, max_guests, amenities, rating, review_count,
           landlord_id, landlord_name, is_available, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          listing['id'], listing['title'], listing['description'], listing['price'],
          listing['location'], listing['address'], listing['images'],
          listing['bedrooms'], listing['bathrooms'], listing['max_guests'],
          listing['amenities'], listing['rating'], listing['review_count'],
          listing['landlord_id'], listing['landlord_name'], listing['is_available'],
          listing['created_at'],
        ],
      );
    }

    print('Database seeded successfully!');
  }

  static List<Map<String, dynamic>> _createDemoUsers() {
    final now = DateTime.now().toIso8601String();
    
    return [
      {
        'id': 'user1',
        'email': 'john@example.com',
        'password_hash': AuthService.hashPassword('password123'),
        'name': 'John Doe',
        'profile_image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        'is_landlord': 0,
        'created_at': now,
      },
      {
        'id': 'user2',
        'email': 'jane@example.com',
        'password_hash': AuthService.hashPassword('password123'),
        'name': 'Jane Smith',
        'profile_image': 'https://images.unsplash.com/photo-1494790108755-2616b332e234?w=150&h=150&fit=crop&crop=face',
        'is_landlord': 0,
        'created_at': now,
      },
      {
        'id': 'landlord1',
        'email': 'sarah@example.com',
        'password_hash': AuthService.hashPassword('password123'),
        'name': 'Sarah Johnson',
        'profile_image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        'is_landlord': 1,
        'created_at': now,
      },
      {
        'id': 'landlord2',
        'email': 'mike@example.com',
        'password_hash': AuthService.hashPassword('password123'),
        'name': 'Mike Wilson',
        'profile_image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        'is_landlord': 1,
        'created_at': now,
      },
      {
        'id': 'landlord3',
        'email': 'emma@example.com',
        'password_hash': AuthService.hashPassword('password123'),
        'name': 'Emma Davis',
        'profile_image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face',
        'is_landlord': 1,
        'created_at': now,
      },
    ];
  }

  static List<Map<String, dynamic>> _createDemoListings() {
    final now = DateTime.now().toIso8601String();
    
    return [
      {
        'id': _uuid.v4(),
        'title': 'Modern Downtown Loft',
        'description': 'Stylish loft in the heart of downtown with exposed brick walls, high ceilings, and modern amenities. Walking distance to restaurants, cafes, and public transport.',
        'price': 120.0,
        'location': 'New York, NY',
        'address': '123 Broadway Ave, New York, NY 10001',
        'images': 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 2,
        'bathrooms': 1,
        'max_guests': 4,
        'amenities': 'WiFi,Kitchen,Air Conditioning,Heating,TV,Workspace',
        'rating': 4.8,
        'review_count': 127,
        'landlord_id': 'landlord1',
        'landlord_name': 'Sarah Johnson',
        'is_available': 1,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'title': 'Cozy Beach House',
        'description': 'Charming beach house just steps from the sand. Perfect for a romantic getaway or family vacation. Includes beach gear and outdoor shower.',
        'price': 200.0,
        'location': 'Malibu, CA',
        'address': '456 Ocean Drive, Malibu, CA 90265',
        'images': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 3,
        'bathrooms': 2,
        'max_guests': 6,
        'amenities': 'WiFi,Kitchen,Air Conditioning,Parking,TV,Balcony,Garden',
        'rating': 4.9,
        'review_count': 89,
        'landlord_id': 'landlord2',
        'landlord_name': 'Mike Wilson',
        'is_available': 1,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'title': 'Luxury Mountain Cabin',
        'description': 'Secluded mountain cabin with stunning views, hot tub, and fireplace. Perfect for nature lovers seeking peace and tranquility.',
        'price': 180.0,
        'location': 'Aspen, CO',
        'address': '789 Pine Ridge, Aspen, CO 81611',
        'images': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 4,
        'bathrooms': 3,
        'max_guests': 8,
        'amenities': 'WiFi,Kitchen,Heating,Parking,TV,Workspace,Balcony',
        'rating': 4.7,
        'review_count': 156,
        'landlord_id': 'landlord3',
        'landlord_name': 'Emma Davis',
        'is_available': 1,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'title': 'Historic Townhouse',
        'description': 'Beautiful historic townhouse in charming neighborhood. Recently renovated while preserving original character and charm.',
        'price': 95.0,
        'location': 'Boston, MA',
        'address': '321 Beacon St, Boston, MA 02116',
        'images': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 1,
        'bathrooms': 1,
        'max_guests': 2,
        'amenities': 'WiFi,Kitchen,Air Conditioning,Heating,TV',
        'rating': 4.6,
        'review_count': 78,
        'landlord_id': 'landlord1',
        'landlord_name': 'Sarah Johnson',
        'is_available': 1,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'title': 'Urban Studio Apartment',
        'description': 'Sleek studio apartment in trendy neighborhood. Perfect for business travelers and city explorers. Close to metro and attractions.',
        'price': 85.0,
        'location': 'Seattle, WA',
        'address': '654 Capitol Hill, Seattle, WA 98102',
        'images': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 1,
        'bathrooms': 1,
        'max_guests': 2,
        'amenities': 'WiFi,Kitchen,Air Conditioning,Heating,TV,Workspace,Gym',
        'rating': 4.4,
        'review_count': 234,
        'landlord_id': 'landlord2',
        'landlord_name': 'Mike Wilson',
        'is_available': 1,
        'created_at': now,
      },
      {
        'id': _uuid.v4(),
        'title': 'Family-Friendly Suburban Home',
        'description': 'Spacious family home with large backyard, swimming pool, and game room. Perfect for family vacations and group stays.',
        'price': 150.0,
        'location': 'Austin, TX',
        'address': '987 Oak Tree Lane, Austin, TX 78701',
        'images': 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80,https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
        'bedrooms': 4,
        'bathrooms': 3,
        'max_guests': 8,
        'amenities': 'WiFi,Kitchen,Air Conditioning,Heating,Parking,Pool,TV,Laundry,Garden',
        'rating': 4.8,
        'review_count': 167,
        'landlord_id': 'landlord3',
        'landlord_name': 'Emma Davis',
        'is_available': 1,
        'created_at': now,
      },
    ];
  }
}