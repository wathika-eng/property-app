import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking.dart';
import '../../widgets/common_widgets.dart' as widgets;
import '../../utils/theme.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingsProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<BookingsProvider>(
        builder: (context, bookingsProvider, child) {
          if (bookingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = bookingsProvider.bookings;
          final now = DateTime.now();

          final upcomingBookings = bookings.where((booking) => 
            booking.checkIn.isAfter(now) && booking.status == 'confirmed'
          ).toList();

          final pastBookings = bookings.where((booking) => 
            booking.checkOut.isBefore(now) && booking.status == 'confirmed'
          ).toList();

          final cancelledBookings = bookings.where((booking) => 
            booking.status == 'cancelled'
          ).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(upcomingBookings, 'upcoming'),
              _buildBookingsList(pastBookings, 'past'),
              _buildBookingsList(cancelledBookings, 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<BookingsProvider>(context, listen: false).loadBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isLandlord = Provider.of<AuthProvider>(context, listen: false).isLandlord;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.listingTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            if (isLandlord) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Guest: ${booking.userName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${booking.guests} ${booking.guests == 1 ? 'guest' : 'guests'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${booking.numberOfNights} ${booking.numberOfNights == 1 ? 'night' : 'nights'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booking.status == 'confirmed' && booking.checkIn.isAfter(DateTime.now()) && !isLandlord) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: widgets.CustomButton(
                      text: 'Cancel Booking',
                      onPressed: () => _showCancelDialog(booking),
                      isOutlined: true,
                      backgroundColor: AppColors.error,
                      textColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        text = 'Confirmed';
        break;
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'upcoming':
        title = 'No upcoming bookings';
        subtitle = 'Your future trips will appear here';
        icon = Icons.calendar_month;
        break;
      case 'past':
        title = 'No past bookings';
        subtitle = 'Your travel history will appear here';
        icon = Icons.history;
        break;
      case 'cancelled':
        title = 'No cancelled bookings';
        subtitle = 'Cancelled bookings will appear here';
        icon = Icons.cancel;
        break;
      default:
        title = 'No bookings';
        subtitle = 'Your bookings will appear here';
        icon = Icons.calendar_today;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (type == 'upcoming') ...[
            const SizedBox(height: 24),
            widgets.CustomButton(
              text: 'Explore Places',
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
        ],
      ),
    );
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final bookingsProvider = Provider.of<BookingsProvider>(context, listen: false);
              
              final success = await bookingsProvider.updateBookingStatus(
                booking.id,
                'cancelled',
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(bookingsProvider.errorMessage ?? 'Failed to cancel booking'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}