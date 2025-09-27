import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/common_widgets.dart' as widgets;
import '../../utils/theme.dart';
import 'listing_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookmarksProvider>(context, listen: false).loadBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<BookmarksProvider>(
        builder: (context, bookmarksProvider, child) {
          if (bookmarksProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookmarksProvider.bookmarks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => bookmarksProvider.loadBookmarks(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: bookmarksProvider.bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarksProvider.bookmarks[index];
                final listing = bookmark['listing'];
                
                // Create a temporary Listing object from the bookmark data
                final listingObj = _createListingFromBookmark(listing);

                return ListingCard(
                  listing: listingObj,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listingObj),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and save your favorite places',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          widgets.CustomButton(
            text: 'Explore Listings',
            onPressed: () {
              // Navigate back to home tab
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  // Helper method to convert bookmark listing data to Listing object
  dynamic _createListingFromBookmark(Map<String, dynamic> listingData) {
    // This is a simplified conversion - in a real app, you'd want to
    // fetch the full listing data from the API
    return MockListing(
      id: listingData['id'],
      title: listingData['title'],
      price: listingData['price'].toDouble(),
      location: listingData['location'],
      images: List<String>.from(listingData['images']),
      rating: listingData['rating'].toDouble(),
      landlordName: listingData['landlord_name'],
    );
  }
}

// Temporary mock listing class for bookmarks display
class MockListing {
  final String id;
  final String title;
  final double price;
  final String location;
  final List<String> images;
  final double rating;
  final String landlordName;

  MockListing({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.images,
    required this.rating,
    required this.landlordName,
  });

  // Mock values for missing properties
  String get description => 'This is a bookmarked listing.';
  String get address => location;
  int get bedrooms => 2;
  int get bathrooms => 1;
  int get maxGuests => 4;
  List<String> get amenities => ['WiFi', 'Kitchen', 'Air Conditioning'];
  int get reviewCount => 50;
  String get landlordId => 'mock-landlord';
  bool get isAvailable => true;
  DateTime get createdAt => DateTime.now();
  DateTime? get availableFrom => null;
  DateTime? get availableTo => null;
}