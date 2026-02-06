import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'create_trip.dart';
import 'manage_bookings.dart';
import 'select_trip_expenses.dart';
import 'customer_management.dart';
import 'widgets/skeleton.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.green[100],
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<AppState>(
                      builder: (context, appState, child) {
                        return Text(
                          'Welcome, ${appState.profile?['name'] ?? 'Partner'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Staging CRM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Consumer<AppState>(
                      builder: (context, appState, child) {
                        return IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      appState.logout();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.person),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    await appState.fetchDashboardStats();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Header
                        _buildSectionHeader('Quick Stats'),
                        const SizedBox(height: 10),
                        Consumer<AppState>(
                          builder: (context, appState, child) {
                            if (appState.errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  appState.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 10),

                        // Stat Cards Grid
                        Consumer<AppState>(
                          builder: (context, appState, child) {
                            if (appState.isLoading &&
                                appState.dashboardStats == null) {
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 2.2,
                                children: List.generate(
                                  4,
                                  (index) => const Skeleton(borderRadius: 15),
                                ),
                              );
                            }
                            final stats = appState.dashboardStats;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.2,
                              children: [
                                _buildStatCard(
                                  'TOTAL TRIPS\nCOUNT',
                                  '${stats?['totalTrips'] ?? 0}',
                                  Icons.inventory_2_outlined,
                                  Colors.green.shade50,
                                  Colors.green.shade700,
                                ),
                                _buildStatCard(
                                  'TOTAL\nBOOKINGS',
                                  '${stats?['totalBookings'] ?? 0}',
                                  Icons.assignment_turned_in_outlined,
                                  Colors.green.shade50,
                                  Colors.green.shade700,
                                ),
                                _buildStatCard(
                                  'TOTAL\nEARNINGS',
                                  '₹${stats?['totalEarnings']?.toString() ?? '0'}',
                                  Icons.currency_rupee,
                                  Colors.green.shade50,
                                  Colors.green.shade700,
                                ),
                                _buildStatCard(
                                  'MONTHLY\nEARNINGS',
                                  '₹${stats?['monthlyEarnings']?.toString() ?? '0'}',
                                  Icons.currency_rupee,
                                  Colors.green.shade50,
                                  Colors.green.shade700,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions Header
                        _buildSectionHeader('Quick Actions'),
                        const SizedBox(height: 20),

                        // Action Cards List
                        _buildActionCard(
                          'Create New',
                          'Create and list new camps',
                          Icons.add_box_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateTripPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          'Manage Bookings',
                          'View and manage booking for packages',
                          Icons.assignment_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageBookingsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          'Manage Expenses',
                          'Track and manage trip expenses',
                          Icons.currency_rupee,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectTripExpensesPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionCard(
                          'Customer Management',
                          'View history of all previous travelers',
                          Icons.group_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CustomerManagementPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade300,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F1E8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF219653), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
