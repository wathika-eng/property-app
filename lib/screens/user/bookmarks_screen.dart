import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../widgets/listing_card.dart';
import '../../models/listing.dart';
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

          if (bookmarksProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      bookmarksProvider.errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    widgets.CustomButton(
                      text: 'Sign In',
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                    ),
                  ],
                ),
              ),
            );
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
  Listing _createListingFromBookmark(Map<String, dynamic> listingData) {
    return Listing(
      id: listingData['id'] ?? 'unknown',
      title: listingData['title'] ?? 'Untitled',
      description: listingData['description'] ?? 'Bookmarked listing',
      price: (listingData['price'] as num?)?.toDouble() ?? 0.0,
      location: listingData['location'] ?? '',
      address: listingData['location'] ?? '',
      images: listingData['images'] is List
          ? List<String>.from(listingData['images'])
          : (listingData['images'] is String
              ? List<String>.from(listingData['images'].toString().split(','))
              : <String>[]),
      bedrooms: listingData['bedrooms'] ?? 1,
      bathrooms: listingData['bathrooms'] ?? 1,
      maxGuests: listingData['max_guests'] ?? 4,
      amenities: listingData['amenities'] is List
          ? List<String>.from(listingData['amenities'])
          : <String>[],
      rating: (listingData['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: listingData['review_count'] ?? 0,
      landlordId: listingData['landlord_id'] ?? 'unknown',
      landlordName: listingData['landlord_name'] ?? '',
      createdAt: DateTime.tryParse(listingData['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// Remove the MockListing class as it is no longer needed