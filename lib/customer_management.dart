import 'package:flutter/material.dart';
import 'api_service.dart';
import 'widgets/skeleton.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> customers = [];
  bool isLoading = true;
  String searchQuery = "";
  String selectedFilter = 'All Customers';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => isLoading = true);
    try {
      final response = await _apiService.getCustomers();
      if (response['success']) {
        setState(() {
          customers = response['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = customers.where((c) {
      final matchesSearch =
          c['name']?.toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ??
          true;
      final matchesFilter =
          selectedFilter == 'All Customers' ||
          (selectedFilter == 'Repeat Travelers' && (c['tripCount'] ?? 0) > 1);
      return matchesSearch && matchesFilter;
    }).toList();

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
          'Customers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => searchQuery = v),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or contact number...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              suffixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF2E7D32),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => selectedFilter = 'All Customers',
                                ),
                                child: _buildFilterChip(
                                  'All Customers',
                                  selectedFilter == 'All Customers',
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setState(
                                  () => selectedFilter = 'Repeat Travelers',
                                ),
                                child: _buildFilterChip(
                                  'Repeat Travelers',
                                  selectedFilter == 'Repeat Travelers',
                                  icon: Icons.access_time,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchCustomers,
                      child: isLoading && customers.isEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Skeleton(
                                    height: 200,
                                    borderRadius: 20,
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                final lastTripTitle =
                                    customer['lastTrip'] != null
                                    ? customer['lastTrip']['title']
                                    : 'N/A';
                                final lastTripDate =
                                    customer['lastTrip'] != null
                                    ? customer['lastTrip']['date']
                                    : 'N/A';
                                final totalTrips = customer['totalTrips'] ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildCustomerCard(
                                    name: customer['name'] ?? 'Unknown',
                                    phone: customer['contactNumber'] ?? 'N/A',
                                    details:
                                        '${customer['gender'] ?? 'N/A'}, ${customer['age'] ?? 'N/A'}',
                                    totalTrips: totalTrips.toString(),
                                    lastTrip: lastTripTitle,
                                    status: totalTrips > 1 ? 'REPEAT' : 'NEW',
                                    statusColor: totalTrips > 1
                                        ? Colors.blue
                                        : Colors.green,
                                    lastTripDate: lastTripDate,
                                    initial:
                                        (customer['name'] ?? 'U')
                                            .toString()
                                            .isNotEmpty
                                        ? (customer['name'] ?? 'U')[0]
                                              .toUpperCase()
                                        : 'U',
                                    avatarColor: Colors.green.shade50,
                                    textColor: Colors.green.shade700,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.blueGrey,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard({
    required String name,
    required String phone,
    required String details,
    required String totalTrips,
    required String lastTrip,
    required String status,
    required Color statusColor,
    required String lastTripDate,
    required String initial,
    required Color avatarColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(
                          details,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F8F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('TOTAL TRIPS', totalTrips),
              _buildStatItem('LAST TRIP', lastTrip),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Last trip on $lastTripDate',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
