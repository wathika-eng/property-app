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
  final DateTime createdAt;
  final DateTime? availableFrom;
  final DateTime? availableTo;

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
    required this.rating,
    required this.reviewCount,
    required this.landlordId,
    required this.landlordName,
    this.isAvailable = true,
    required this.createdAt,
    this.availableFrom,
    this.availableTo,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      location: json['location'],
      address: json['address'],
      images: json['images'] is List 
          ? List<String>.from(json['images'])
          : List<String>.from(json['images'].split(',')),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      maxGuests: json['max_guests'],
      amenities: json['amenities'] is List 
          ? List<String>.from(json['amenities'])
          : List<String>.from(json['amenities'].split(',')),
      rating: json['rating'].toDouble(),
      reviewCount: json['review_count'],
      landlordId: json['landlord_id'],
      landlordName: json['landlord_name'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      createdAt: DateTime.parse(json['created_at']),
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'])
          : null,
      availableTo: json['available_to'] != null
          ? DateTime.parse(json['available_to'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
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
      'created_at': createdAt.toIso8601String(),
      'available_from': availableFrom?.toIso8601String(),
      'available_to': availableTo?.toIso8601String(),
    };
  }

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    String? address,
    List<String>? images,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    List<String>? amenities,
    double? rating,
    int? reviewCount,
    String? landlordId,
    String? landlordName,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? availableFrom,
    DateTime? availableTo,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      address: address ?? this.address,
      images: images ?? this.images,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      landlordId: landlordId ?? this.landlordId,
      landlordName: landlordName ?? this.landlordName,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
    );
  }
}