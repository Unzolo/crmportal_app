import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class AdminBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const AdminBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<AdminBookingDetailsPage> createState() =>
      _AdminBookingDetailsPageState();
}

class _AdminBookingDetailsPageState extends State<AdminBookingDetailsPage> {
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
      final response = await _apiService.getAdminBookingDetails(
        widget.bookingId,
      );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF219653)),
            )
          : booking == null
          ? const Center(child: Text('Booking not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildParticipantsSection(),
                  const SizedBox(height: 32),
                  _buildPaymentSummary(),
                  const SizedBox(height: 32),
                  _buildPaymentTimeline(),
                ],
              ),
            ),
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
              trip?['title'] ?? 'N/A',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F1E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                booking?['status']?.toString().toUpperCase() ?? 'PENDING',
                style: const TextStyle(
                  color: Color(0xFF219653),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '${trip?['startDate'] != null ? DateFormat('dd MMM').format(DateTime.parse(trip['startDate'])) : 'N/A'} - ${trip?['endDate'] != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(trip['endDate'])) : 'N/A'}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final participants = booking?['Participants'] as List? ?? [];
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: p['status'] == 'cancelled'
                          ? Colors.red
                          : const Color(0xFF219653),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: p['status'] == 'cancelled'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '${p['age']} yrs • ${p['gender']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p['isPrimary'] == true)
                    const Text(
                      'PRIMARY',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
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
        double.tryParse(booking?['totalAmount']?.toString() ?? '0') ?? 0;
    final paid =
        double.tryParse(booking?['paidAmount']?.toString() ?? '0') ?? 0;
    final remaining = total - paid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Summary'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(24),
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
                    const Color(0xFF219653),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REMAINING BALANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '₹${remaining.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEB5757),
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
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
            title: p['type'] == 'advance'
                ? 'Advance Payment'
                : 'Partial Payment',
            date: DateFormat(
              'd MMM, yyyy HH:mm',
            ).format(DateTime.parse(p['createdAt'])),
            amount: '₹${p['amount']}',
            method: p['method']?.toString().toUpperCase() ?? 'N/A',
          ),
        ),
        _buildTimelineItem(
          title: 'Booking Created',
          date: booking?['createdAt'] != null
              ? DateFormat(
                  'd MMM, yyyy HH:mm',
                ).format(DateTime.parse(booking!['createdAt']))
              : 'N/A',
          amount: '',
          method: '',
          isLast: true,
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String amount,
    required String method,
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
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFB9DBC8),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFF1F5F9)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F1E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF219653), size: 16),
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
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
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
                    color: Color(0xFF219653),
                    fontSize: 14,
                  ),
                ),
                Text(
                  method,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
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
          height: 20,
          width: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF219653),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
