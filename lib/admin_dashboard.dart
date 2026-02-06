import 'package:flutter/material.dart';
import 'admin_booking_details.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'widgets/skeleton.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool isMaintenanceMode = false;
  String searchQuery = "";
  Map<String, dynamic>? stats;
  List<dynamic> partners = [];
  List<dynamic> recentBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => isLoading = true);
    try {
      final statsResponse = await _apiService.getAdminStats();
      final partnersResponse = await _apiService.getAdminPartners();

      if (statsResponse['success']) {
        stats = statsResponse['data'];
        isMaintenanceMode = stats?['maintenanceMode'] ?? false;
        recentBookings = stats?['recentBookings'] ?? [];
      }

      if (partnersResponse['success']) {
        partners = partnersResponse['data'];
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    final originalValue = isMaintenanceMode;
    setState(() => isMaintenanceMode = value);
    try {
      final response = await _apiService.updateMaintenanceMode(value);
      if (!response['success']) {
        setState(() => isMaintenanceMode = originalValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update maintenance mode')),
        );
      }
    } catch (e) {
      setState(() => isMaintenanceMode = originalValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating maintenance mode')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2F1E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Portal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.logout, color: Colors.red),
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
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: isLoading && stats == null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: List.generate(
                              4,
                              (index) => const Skeleton(borderRadius: 20),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Skeleton(height: 100, borderRadius: 20),
                          const SizedBox(height: 32),
                          const Skeleton(height: 25, width: 150),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 3,
                            itemBuilder: (context, index) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Skeleton(height: 80, borderRadius: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildStatCard(
                                'PARTNERS',
                                '${stats?['totalPartners'] ?? 0}',
                                Icons.people_outline,
                                const Color(0xFFEBF5FF),
                                Colors.blue,
                              ),
                              _buildStatCard(
                                'TRIPS',
                                '${stats?['totalTrips'] ?? 0}',
                                Icons.inventory_2_outlined,
                                const Color(0xFFFFF7ED),
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'BOOKINGS',
                                '${stats?['totalBookings'] ?? 0}',
                                Icons.assignment_turned_in_outlined,
                                const Color(0xFFF0FDF4),
                                Colors.green,
                              ),
                              _buildStatCard(
                                'REVENUE',
                                '₹${(stats?['totalEarnings'] ?? 0) / 100000}L',
                                Icons.currency_rupee,
                                const Color(0xFFFAF5FF),
                                Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Global Settings
                          _buildSectionHeader('Global Settings'),
                          const SizedBox(height: 16),
                          _buildMaintenanceCard(),
                          const SizedBox(height: 32),

                          // Recent Bookings
                          if (recentBookings.isNotEmpty) ...[
                            _buildSectionHeader('Recent Bookings'),
                            const SizedBox(height: 16),
                            ...recentBookings
                                .take(3)
                                .map(
                                  (booking) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildBookingCard(
                                      context,
                                      booking['partnerName'] ?? 'Partner',
                                      booking['tripTitle'] ?? 'Untitled Trip',
                                      '₹${booking['totalAmount'] ?? '0'}',
                                      booking['status'] ?? 'Pending',
                                      id: booking['id'].toString(),
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 20),
                          ],

                          // Partners List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('Registered Partners'),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${partners.length} Total',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          ...partners
                              .where(
                                (p) => p['name']
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()),
                              )
                              .map(
                                (partner) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildPartnerCard(
                                    partner['name'] ?? 'Unknown',
                                    partner['is_blocked']
                                        ? 'blocked'
                                        : 'active',
                                    '${partner['trip_count'] ?? 0} Trips',
                                    'Since ${partner['createdAt'] != null ? DateFormat('MMM yyyy').format(DateTime.parse(partner['createdAt'])) : 'N/A'}',
                                  ),
                                ),
                              ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Under Maintenance Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Normal users will be blocked from accessing the app.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: isMaintenanceMode,
            onChanged: _toggleMaintenance,
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search partners...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          border: InputBorder.none,
          suffixIcon: Icon(Icons.search, color: Color(0xFF219653), size: 18),
        ),
      ),
    );
  }

  Widget _buildPartnerCard(
    String name,
    String status,
    String trips,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF219653),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: status == 'active' ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 10,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trips,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '| $date',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    String name,
    String trip,
    String amount,
    String status, {
    String? id,
  }) {
    return InkWell(
      onTap: () {
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminBookingDetailsPage(bookingId: id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F1E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF219653),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    trip,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF219653),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
