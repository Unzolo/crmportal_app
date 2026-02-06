import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'cancel_booking.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? booking;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await _apiService.getBookingDetails(widget.bookingId);
      if (response['success']) {
        setState(() {
          booking = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
          'Booking Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E8B57)),
            )
          : booking == null
          ? const Center(child: Text('Booking not found'))
          : Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildParticipantsSection(context),
                          const SizedBox(height: 32),
                          _buildPaymentSummary(),
                          const SizedBox(height: 32),
                          _buildPaymentTimeline(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: booking != null
          ? _buildBottomButtons(context)
          : null,
    );
  }

  Widget _buildHeader() {
    final trip = booking?['Trip'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              trip?['title'] ?? 'Untitled Trip',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                booking?['status']?.toString().toUpperCase() ?? 'PENDING',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              '${trip?['startDate'] != null ? DateFormat('dd MMM').format(DateTime.parse(trip['startDate'])) : 'N/A'} - ${trip?['endDate'] != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(trip['endDate'])) : 'N/A'}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(BuildContext context) {
    final participants = booking?['Customers'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Participants Details'),
        const SizedBox(height: 16),
        ...participants.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: p['status'] == 'cancelled'
                    ? Border.all(color: Colors.red.shade100)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: p['status'] == 'cancelled'
                          ? Colors.red
                          : const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: p['status'] == 'cancelled'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p['age'] ?? 'N/A'} yrs • ${p['gender'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p['isPrimary'] == true ? 'PRIMARY' : 'MEMBER',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final total =
        double.tryParse(booking?['totalCost']?.toString() ?? '0') ?? 0;
    final paid =
        double.tryParse(booking?['netPaidAmount']?.toString() ?? '0') ?? 0;
    final remaining =
        double.tryParse(booking?['remainingAmount']?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Summary'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'TOTAL AMOUNT',
                    '₹${total.toStringAsFixed(0)}',
                    Colors.black,
                  ),
                  _buildSummaryItem(
                    'PAID SO FAR',
                    '₹${paid.toStringAsFixed(0)}',
                    const Color(0xFF2E7D32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REMAINING BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                  Text(
                    '₹${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: remaining > 0
                          ? const Color(0xFFD32F2F)
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
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
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTimeline() {
    final payments = booking?['Payments'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Timeline'),
        const SizedBox(height: 24),
        ...payments.map(
          (p) => _buildTimelineItem(
            p['type'] == 'advance' ? 'Advance Payment' : 'Partial Payment',
            DateFormat(
              'd MMM, yyyy HH:mm',
            ).format(DateTime.parse(p['paymentDate'] ?? p['createdAt'])),
            '₹${p['amount']}',
            p['method']?.toString().toUpperCase() ?? 'N/A',
          ),
        ),
        _buildTimelineItem(
          'Booking Created',
          booking?['createdAt'] != null
              ? DateFormat(
                  'd MMM, yyyy HH:mm',
                ).format(DateTime.parse(booking?['createdAt']))
              : 'N/A',
          '',
          '',
          isLast: true,
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String date,
    String amount,
    String method, {
    bool isFirst = false,
    bool isLast = false,
    IconData icon = Icons.currency_rupee,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFA5D6A7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8F5E9), width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade100),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (amount.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {}, // TODO: Implement update payment
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Update Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CancelBookingPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
