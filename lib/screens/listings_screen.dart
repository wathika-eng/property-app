import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/listings_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/common_widgets.dart' as widgets;
import '../widgets/auth_guard.dart';
import '../utils/theme.dart';
import 'user/listing_detail_screen.dart';
import 'auth/login_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listingsProvider = Provider.of<ListingsProvider>(context, listen: false);
      
      // Load listings for everyone (guests and authenticated users)
      listingsProvider.loadListings(refresh: true);
      
      // Only load bookmarks if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        final bookmarksProvider = Provider.of<BookmarksProvider>(context, listen: false);
        bookmarksProvider.loadBookmarks();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final listingsProvider = Provider.of<ListingsProvider>(context, listen: false);
      if (!listingsProvider.isLoading && listingsProvider.hasMoreListings) {
        listingsProvider.loadListings(location: _searchQuery.isNotEmpty ? _searchQuery : null);
      }
    }
  }

  void _onSearch() {
    final listingsProvider = Provider.of<ListingsProvider>(context, listen: false);
    listingsProvider.loadListings(
      refresh: true,
      location: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildListingsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${user?.name ?? 'Guest'}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your perfect stay',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!authProvider.isLoggedIn) ...[
                widgets.CustomButton(
                  text: 'Sign In',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  isOutlined: true,
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user?.profileImage != null 
                        ? NetworkImage(user!.profileImage!)
                        : null,
                    child: user?.profileImage == null
                        ? Text(
                            user?.name.isNotEmpty == true 
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: widgets.SearchBar(
        hintText: 'Where do you want to stay?',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onSearch: _onSearch,
      ),
    );
  }

  Widget _buildListingsList() {
    return Consumer<ListingsProvider>(
      builder: (context, listingsProvider, child) {
        if (listingsProvider.isLoading && listingsProvider.listings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (listingsProvider.errorMessage != null) {
          return _buildErrorState(listingsProvider.errorMessage!);
        }

        if (listingsProvider.listings.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => listingsProvider.loadListings(
            refresh: true,
            location: _searchQuery.isNotEmpty ? _searchQuery : null,
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: listingsProvider.listings.length + 
                      (listingsProvider.hasMoreListings ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= listingsProvider.listings.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final listing = listingsProvider.listings[index];
              return ListingCard(
                listing: listing,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListingDetailScreen(listing: listing),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No listings found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          widgets.CustomButton(
            text: 'Clear Search',
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              _onSearch();
            },
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          widgets.CustomButton(
            text: 'Try Again',
            onPressed: () {
              final listingsProvider = Provider.of<ListingsProvider>(context, listen: false);
              listingsProvider.loadListings(refresh: true);
            },
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomNav() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          // Simple bottom nav for guests
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.background,
            elevation: 8,
            currentIndex: 0, // Always show listings as active
            onTap: (index) {
              if (index == 0) return; // Already on listings
              // For other tabs, show auth guard
              AuthGuard.showAuthRequired(
                context,
                feature: index == 1 ? 'Bookmarks' : 'Bookings',
              );
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Bookmarks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
            ],
          );
        } else {
          // For authenticated users, redirect to main navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.background,
            elevation: 8,
            currentIndex: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Bookmarks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Bookings',
              ),
            ],
          );
        }
      },
    );
  }
}