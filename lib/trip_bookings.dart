import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'booking_details.dart';
import 'create_booking.dart';
import 'package:intl/intl.dart';
import 'widgets/skeleton.dart';

class TripBookingsPage extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  final String location;
  final String date;
  final String price;

  const TripBookingsPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.location,
    required this.date,
    required this.price,
  });

  @override
  State<TripBookingsPage> createState() => _TripBookingsPageState();
}

class _TripBookingsPageState extends State<TripBookingsPage> {
  String selectedFilter = 'All';
  bool _isOverviewExpanded = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(
        context,
        listen: false,
      ).fetchTripBookings(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Bookings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateBookingPage(tripId: widget.tripId),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Add', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final bookings = appState.tripBookings;
                  final filteredBookings = bookings.where((b) {
                    final status = b['status']?.toString().toLowerCase() ?? '';
                    final isFilterMatch =
                        selectedFilter == 'All' ||
                        (selectedFilter == 'Advance Paid' &&
                            status == 'advance paid') ||
                        (selectedFilter == 'Partially Paid' &&
                            status == 'partially paid') ||
                        (selectedFilter == 'Fully Paid' &&
                            status == 'fully paid');

                    final customers = b['Customers'] as List?;
                    final primaryCustomer = customers?.firstWhere(
                      (c) => c['isPrimary'] == true,
                      orElse: () =>
                          customers.isNotEmpty ? customers.first : null,
                    );
                    final contactName = primaryCustomer?['name'] ?? 'Unknown';

                    final isSearchMatch = contactName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    );

                    return isFilterMatch && isSearchMatch;
                  }).toList();

                  // Calculate stats for overview
                  final totalCollected = bookings.fold(
                    0.0,
                    (sum, b) =>
                        sum +
                        (double.tryParse(b['paidAmount']?.toString() ?? '0') ??
                            0),
                  );
                  final totalPending = bookings.fold(
                    0.0,
                    (sum, b) =>
                        sum +
                        ((double.tryParse(b['totalCost']?.toString() ?? '0') ??
                                0) -
                            (double.tryParse(
                                  b['paidAmount']?.toString() ?? '0',
                                ) ??
                                0)),
                  );
                  final confirmedSlots = bookings
                      .where((b) => b['status'] != 'cancelled')
                      .fold(
                        0,
                        (sum, b) =>
                            sum +
                            (int.tryParse(
                                  b['memberCount']?.toString() ?? '1',
                                ) ??
                                1),
                      );
                  final advPaidCount = bookings
                      .where((b) => b['status'] == 'advance paid')
                      .length;
                  final fullPaidCount = bookings
                      .where((b) => b['status'] == 'fully paid')
                      .length;

                  return RefreshIndicator(
                    onRefresh: () => appState.fetchTripBookings(widget.tripId),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTripSummaryCard(bookings.length),
                          if (_isOverviewExpanded) ...[
                            const SizedBox(height: 16),
                            _buildOverviewSection(
                              confirmedSlots,
                              totalCollected,
                              totalPending,
                              advPaidCount,
                              fullPaidCount,
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildFilterTabs(),
                          const SizedBox(height: 24),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 32),
                          _buildBookingsHeader(filteredBookings.length),
                          const SizedBox(height: 16),
                          if (appState.isLoading &&
                              appState.tripBookings.isEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Skeleton(
                                    height: 120,
                                    borderRadius: 20,
                                  ),
                                );
                              },
                            )
                          else if (filteredBookings.isEmpty)
                            const Center(child: Text('No bookings found'))
                          else
                            ...filteredBookings.map((booking) {
                              final customers = booking['Customers'] as List?;
                              final primaryCustomer = customers?.firstWhere(
                                (c) => c['isPrimary'] == true,
                                orElse: () => customers.isNotEmpty
                                    ? customers.first
                                    : null,
                              );
                              final contactName =
                                  primaryCustomer?['name'] ?? 'Unknown';
                              final contactPhone =
                                  primaryCustomer?['contactNumber'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildBookingCard(
                                  id: booking['id'].toString(),
                                  status: booking['status'] ?? 'Pending',
                                  name: '$contactName - $contactPhone',
                                  adults:
                                      int.tryParse(
                                        booking['memberCount']?.toString() ??
                                            '1',
                                      ) ??
                                      1,
                                  paid:
                                      booking['paidAmount']?.toString() ?? '0',
                                  total:
                                      booking['totalCost']?.toString() ?? '0',
                                  time: booking['createdAt'] != null
                                      ? DateFormat('dd MMM, yyyy HH:mm').format(
                                          DateTime.parse(booking['createdAt']),
                                        )
                                      : 'N/A',
                                  icon: Icons.inventory_2,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummaryCard(int bookingCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tripTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _isOverviewExpanded = !_isOverviewExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isOverviewExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                widget.location,
                style: TextStyle(color: Colors.grey.shade400),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  width: 1,
                  height: 14,
                  color: Colors.grey.shade200,
                ),
              ),
              Text(
                '$bookingCount Bookings',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.date,
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${widget.price}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Advance Paid', 'Partially Paid', 'Fully Paid'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E8B57)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2E8B57)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search customer',
                hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                border: InputBorder.none,
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.green.shade600,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Icon(
            Icons.tune_outlined,
            color: Colors.green.shade600,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$count Bookings',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(
            Icons.download_outlined,
            color: Color(0xFF2E8B57),
            size: 18,
          ),
          label: const Text(
            'Download',
            style: TextStyle(
              color: Color(0xFF2E8B57),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard({
    required String id,
    required String status,
    required String name,
    required int adults,
    required String time,
    required IconData icon,
    String? paid,
    String? total,
  }) {
    Color statusColor = Colors.grey;
    switch (status.toLowerCase()) {
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'fully paid':
        statusColor = Colors.green;
        break;
      case 'partially paid':
        statusColor = Colors.blue;
        break;
      case 'advance paid':
        statusColor = Colors.orange;
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailsPage(bookingId: id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$adults Adults',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                            if (paid != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '₹$paid / ',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '₹$total',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(
    int slots,
    double collected,
    double pending,
    int advCount,
    int fullCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Overview'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'CONFIRMED SLOTS',
                '$slots',
                Icons.people_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildMultiStatCard(advCount, fullCount)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'TOTAL COLLECTED',
                '₹${collected.toStringAsFixed(0)}',
                Icons.assignment_turned_in_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'TOTAL PENDING',
                '₹${pending.toStringAsFixed(0)}',
                Icons.access_time,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 5,
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade300,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color == Colors.red
                        ? Colors.red
                        : (color == Colors.green
                              ? Colors.green.shade700
                              : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiStatCard(int advCount, int fullCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ADV PAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$advCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'FULL PAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$fullCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
