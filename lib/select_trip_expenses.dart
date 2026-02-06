import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'manage_expenses.dart';
import 'package:intl/intl.dart';

class SelectTripExpensesPage extends StatefulWidget {
  const SelectTripExpensesPage({super.key});

  @override
  State<SelectTripExpensesPage> createState() => _SelectTripExpensesPageState();
}

class _SelectTripExpensesPageState extends State<SelectTripExpensesPage> {
  int selectedTabIndex = 0; // 0 for Camps, 1 for Packages
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchTrips();
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
          'Manage Expenses',
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
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final trips = appState.trips.where((trip) {
                    final type = trip['type']?.toString().toLowerCase() ?? '';
                    final isCorrectType =
                        (selectedTabIndex == 0 && type == 'camp') ||
                        (selectedTabIndex == 1 && type == 'package');
                    final matchesSearch =
                        trip['title']?.toString().toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        true;
                    return isCorrectType && matchesSearch;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () => appState.fetchTrips(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Select Trip'),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose a camp or package to manage its expenses',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 24),
                          _buildTypeTabs(appState),
                          const SizedBox(height: 32),
                          Text(
                            selectedTabIndex == 0
                                ? 'UPCOMING CAMPS'
                                : 'UPCOMING PACKAGES',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (appState.isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2E7D32),
                              ),
                            )
                          else if (trips.isEmpty)
                            const Center(child: Text('No trips found'))
                          else
                            ...trips.map(
                              (trip) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildTripCard(context, trip),
                              ),
                            ),
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

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search by title or destination',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                suffixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: const Icon(Icons.tune, color: Color(0xFF2E7D32), size: 20),
        ),
      ],
    );
  }

  Widget _buildTypeTabs(AppState appState) {
    final campCount = appState.trips.where((t) => t['type'] == 'camp').length;
    final packageCount = appState.trips
        .where((t) => t['type'] == 'package')
        .length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 0
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Camps ($campCount)',
                    style: TextStyle(
                      color: selectedTabIndex == 0
                          ? const Color(0xFF2E7D32)
                          : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 1
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Packages ($packageCount)',
                    style: TextStyle(
                      color: selectedTabIndex == 1
                          ? const Color(0xFF2E7D32)
                          : Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
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

  Widget _buildTripCard(BuildContext context, dynamic trip) {
    final title = trip['title'] ?? 'Untitled';
    final location = trip['destination'] ?? 'Unknown';
    final price = trip['price']?.toString() ?? '0';
    final expenses = trip['totalExpenses']?.toString() ?? '0';
    final startDate = trip['startDate'] != null
        ? DateFormat('dd MMM').format(DateTime.parse(trip['startDate']))
        : 'N/A';
    final endDate = trip['endDate'] != null
        ? DateFormat('dd MMM, yyyy').format(DateTime.parse(trip['endDate']))
        : 'N/A';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageExpensesPage(
              tripId: trip['id'].toString(),
              tripTitle: title,
              tripLocation: location,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    trip['type'] == 'camp'
                        ? Icons.terrain
                        : Icons.inventory_2_outlined,
                    color: const Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$startDate - $endDate',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRIP PRICE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.currency_rupee,
                          color: Color(0xFFE57373),
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EXPENSES',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹$expenses',
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
