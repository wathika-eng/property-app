import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/listing.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/common_widgets.dart' as widgets;
import '../../widgets/image_carousel.dart';
import '../../utils/theme.dart';

class BookingScreen extends StatefulWidget {
  final Listing listing;

  const BookingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;
  
  @override
  Widget build(BuildContext context) {
    final nights = _checkInDate != null && _checkOutDate != null 
        ? _checkOutDate!.difference(_checkInDate!).inDays 
        : 0;
    final totalPrice = nights > 0 ? widget.listing.price * nights : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Your Stay'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildListingPreview(),
                  const SizedBox(height: 24),
                  _buildDateSelection(),
                  const SizedBox(height: 24),
                  _buildGuestSelection(),
                  const SizedBox(height: 24),
                  _buildPriceBreakdown(nights, totalPrice),
                ],
              ),
            ),
          ),
          _buildBottomBar(totalPrice),
        ],
      ),
    );
  }

  Widget _buildListingPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: ImageCarousel(
                  images: widget.listing.images,
                  height: 80,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.listing.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.listing.rating} • ${widget.listing.reviewCount} reviews',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select dates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    'Check-in',
                    _checkInDate,
                    (date) => setState(() => _checkInDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker(
                    'Check-out',
                    _checkOutDate,
                    (date) => setState(() => _checkOutDate = date),
                    minDate: _checkInDate?.add(const Duration(days: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected, {
    DateTime? minDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: minDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(selectedDate)
                  : 'Add date',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selectedDate != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Number of guests',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _guests > 1
                          ? () => setState(() => _guests--)
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _guests > 1 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        _guests.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _guests < widget.listing.maxGuests
                          ? () => setState(() => _guests++)
                          : null,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: _guests < widget.listing.maxGuests 
                            ? AppColors.primary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Maximum ${widget.listing.maxGuests} guests',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(int nights, double totalPrice) {
    if (nights == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${widget.listing.price.toStringAsFixed(0)} × $nights nights'),
                Text('\$${totalPrice.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double totalPrice) {
    final canBook = _checkInDate != null && 
                   _checkOutDate != null && 
                   _checkOutDate!.isAfter(_checkInDate!) &&
                   _guests >= 1 && 
                   _guests <= widget.listing.maxGuests;

    return Consumer<BookingsProvider>(
      builder: (context, bookingsProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: widgets.CustomButton(
              text: canBook ? 'Reserve for \$${totalPrice.toStringAsFixed(0)}' : 'Select dates',
              onPressed: canBook ? () => _handleBooking(bookingsProvider, totalPrice) : null,
              isLoading: bookingsProvider.isLoading,
              width: double.infinity,
            ),
          ),
        );
      },
    );
  }

  void _handleBooking(BookingsProvider bookingsProvider, double totalPrice) async {
    final success = await bookingsProvider.createBooking(
      listingId: widget.listing.id,
      checkIn: _checkInDate!,
      checkOut: _checkOutDate!,
      guests: _guests,
      totalPrice: totalPrice,
    );

    if (success && mounted) {
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Your booking at ${widget.listing.title} has been confirmed.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            widgets.CustomButton(
              text: 'View Bookings',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to listing detail
                // Navigate to bookings tab would require more complex navigation
              },
              width: double.infinity,
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingsProvider.errorMessage ?? 'Booking failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}