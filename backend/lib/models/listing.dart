class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String address;
  final List<String> images;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String landlordId;
  final String landlordName;
  final bool isAvailable;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.address,
    required this.images,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.amenities,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.landlordId,
    required this.landlordName,
    this.isAvailable = true,
    this.availableFrom,
    this.availableTo,
    required this.createdAt,
  });

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      location: map['location'],
      address: map['address'],
      images: map['images'].toString().split(','),
      bedrooms: map['bedrooms'],
      bathrooms: map['bathrooms'],
      maxGuests: map['max_guests'],
      amenities: map['amenities'].toString().split(','),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['review_count'] ?? 0,
      landlordId: map['landlord_id'],
      landlordName: map['landlord_name'],
      isAvailable: map['is_available'] == 1,
      availableFrom: map['available_from'] != null
          ? DateTime.parse(map['available_from'])
          : null,
      availableTo: map['available_to'] != null
          ? DateTime.parse(map['available_to'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'address': address,
      'images': images.join(','),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_guests': maxGuests,
      'amenities': amenities.join(','),
      'rating': rating,
      'review_count': reviewCount,
      'landlord_id': landlordId,
      'landlord_name': landlordName,
      'is_available': isAvailable ? 1 : 0,
      'available_from': availableFrom?.toIso8601String(),
      'available_to': availableTo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'address': address,
      'images': images,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'max_guests': maxGuests,
      'amenities': amenities,
      'rating': rating,
      'review_count': reviewCount,
      'landlord_id': landlordId,
      'landlord_name': landlordName,
      'is_available': isAvailable,
      'available_from': availableFrom?.toIso8601String(),
      'available_to': availableTo?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}