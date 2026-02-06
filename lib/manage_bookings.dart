import 'package:crmportal_app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_bookings.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'create_trip.dart'; // Reusing create_trip for edit
import 'widgets/skeleton.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  int selectedTabIndex = 0; // 0 for Camps, 1 for Packages
  String searchQuery = "";
  // Sorting state
  String _sortBy = 'date'; // 'date', 'price', 'title'
  bool _isAscending = true; // true = Oldest/Low/A-Z, false = Latest/High/Z-A

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
          'Manage Bookings',
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
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  final filteredTrips = appState.trips.where((trip) {
                    final isTypeMatch = selectedTabIndex == 0
                        ? trip['type']?.toString().toLowerCase() == 'camp'
                        : trip['type']?.toString().toLowerCase() == 'package';
                    final isSearchMatch =
                        trip['title'].toString().toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        trip['destination'].toString().toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                    return isTypeMatch && isSearchMatch;
                  }).toList();

                  // Sort the list
                  filteredTrips.sort((a, b) {
                    int result = 0;
                    if (_sortBy == 'date') {
                      final dateA =
                          DateTime.tryParse(a['startDate'] ?? '') ??
                          DateTime(0);
                      final dateB =
                          DateTime.tryParse(b['startDate'] ?? '') ??
                          DateTime(0);
                      result = dateA.compareTo(dateB);
                    } else if (_sortBy == 'price') {
                      final priceA =
                          double.tryParse(a['price']?.toString() ?? '0') ?? 0;
                      final priceB =
                          double.tryParse(b['price']?.toString() ?? '0') ?? 0;
                      result = priceA.compareTo(priceB);
                    } else if (_sortBy == 'title') {
                      result = (a['title']?.toString() ?? '')
                          .toLowerCase()
                          .compareTo(
                            (b['title']?.toString() ?? '').toLowerCase(),
                          );
                    }
                    return _isAscending ? result : -result;
                  });

                  final campsCount = appState.trips
                      .where(
                        (t) => t['type']?.toString().toLowerCase() == 'camp',
                      )
                      .length;
                  final packagesCount = appState.trips
                      .where(
                        (t) => t['type']?.toString().toLowerCase() == 'package',
                      )
                      .length;

                  return RefreshIndicator(
                    onRefresh: () => appState.fetchTrips(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepHeader('Select Trip'),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a camp or package to manage its bookings',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 24),
                          _buildTabs(campsCount, packagesCount),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTabIndex == 0
                                    ? 'UPCOMING CAMPS'
                                    : 'UPCOMING PACKAGES',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showTrashBottomSheet,
                                icon: Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                                label: Text(
                                  'TRASH',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (appState.errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      appState.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () => appState.fetchTrips(),
                                    color: Colors.red.shade700,
                                  ),
                                ],
                              ),
                            ),
                          if (appState.isLoading && appState.trips.isEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Skeleton(
                                    height: 180,
                                    borderRadius: 20,
                                  ),
                                );
                              },
                            )
                          else if (filteredTrips.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Text('No trips found'),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredTrips.length,
                              itemBuilder: (context, index) {
                                final trip = filteredTrips[index];
                                final startDate = trip['startDate'] != null
                                    ? DateTime.parse(trip['startDate'])
                                    : null;
                                final endDate = trip['endDate'] != null
                                    ? DateTime.parse(trip['endDate'])
                                    : null;

                                final dateRange =
                                    startDate != null && endDate != null
                                    ? '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('dd, yyyy').format(endDate)}'
                                    : 'No date set';

                                final cardDate =
                                    startDate != null && endDate != null
                                    ? '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}'
                                    : 'No date';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TripBookingsPage(
                                                tripId: trip['id'].toString(),
                                                tripTitle:
                                                    trip['title'] ??
                                                    'Unknown Trip',
                                                location:
                                                    trip['destination'] ??
                                                    'Unknown Location',
                                                date: dateRange,
                                                price:
                                                    trip['price']?.toString() ??
                                                    '0',
                                              ),
                                        ),
                                      );
                                    },
                                    child: _buildTripCard(
                                      context: context,
                                      trip: trip,
                                      title: trip['title'] ?? 'Unknown Trip',
                                      date: cardDate,
                                      location:
                                          trip['destination'] ??
                                          'Unknown Location',
                                      price: trip['price']?.toString() ?? '0',
                                      icon:
                                          trip['type']
                                                  ?.toString()
                                                  .toLowerCase() ==
                                              'camp'
                                          ? Icons.landscape_outlined
                                          : Icons.inventory_2_outlined,
                                    ),
                                  ),
                                );
                              },
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
                hintText: 'Search by title or destination',
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
        const SizedBox(width: 12),
        PopupMenuButton<void>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          elevation: 4,
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 220),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: StatefulBuilder(
                builder: (context, setMenuState) {
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SORT BY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSortOption('Trip Date', 'date', setMenuState),
                        _buildSortOption('Price', 'price', setMenuState),
                        _buildSortOption('Title', 'title', setMenuState),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'ORDER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildOrderOption(
                                'Oldest',
                                true,
                                setMenuState,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildOrderOption(
                                'Latest',
                                false,
                                setMenuState,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          child: Container(
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
        ),
      ],
    );
  }

  Widget _buildTabs(int campsCount, int packagesCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F2),
        borderRadius: BorderRadius.circular(15),
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Camps ($campsCount)',
                    style: TextStyle(
                      color: selectedTabIndex == 0
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Packages ($packagesCount)',
                    style: TextStyle(
                      color: selectedTabIndex == 1
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
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

  Widget _buildTripCard({
    required BuildContext context,
    required Map<String, dynamic> trip,
    required String title,
    required String date,
    required String location,
    required String price,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit Button
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTripPage(trip: trip),
                    ),
                  );
                  if (result == true && context.mounted) {
                    Provider.of<AppState>(context, listen: false).fetchTrips();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9), // Light green
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF2E7D32), // Dark green
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              GestureDetector(
                onTap: () => _confirmDelete(context, trip['id'].toString()),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE), // Light red
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFC62828), // Red
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIP PRICE',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$price',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String tripId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'Are you sure you want to delete this trip? It will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ApiService();
                final res = await api.deleteTrip(tripId);
                if (res['success'] == true) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip deleted successfully'),
                      ),
                    );
                    Provider.of<AppState>(context, listen: false).fetchTrips();
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    StateSetter setMenuState,
  ) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setMenuState(() {
          _sortBy = value;
        });
        setState(() {}); // Update main page to sort immediately
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.green.shade800 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderOption(
    String label,
    bool isAscending,
    StateSetter setMenuState,
  ) {
    final isSelected = _isAscending == isAscending;
    return GestureDetector(
      onTap: () {
        setMenuState(() {
          _isAscending = isAscending;
        });
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.green.shade800 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  void _showTrashBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return TrashBottomSheetContent(scrollController: scrollController);
        },
      ),
    );
  }
}

class TrashBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  const TrashBottomSheetContent({super.key, required this.scrollController});

  @override
  State<TrashBottomSheetContent> createState() =>
      _TrashBottomSheetContentState();
}

class _TrashBottomSheetContentState extends State<TrashBottomSheetContent> {
  List<dynamic> _trashTrips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrashTrips();
  }

  Future<void> _fetchTrashTrips() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final response = await apiService.getInactiveTrips();
      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _trashTrips = response['data'] ?? [];
            _error = null;
          });
        }
      } else {
        if (mounted) {
          setState(
            () => _error = response['message'] ?? 'Failed to fetch trash',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverTrip(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.recoverTrip(id);
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip recovered successfully!')),
          );
          _fetchTrashTrips();
          // Ideally refresh parent too, but context is different.
          // Could pass a callback or rely on user refreshing/Popping.
          Provider.of<AppState>(context, listen: false).fetchTrips();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to recover: ${response['message']}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Handle bar
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: const Color(0xFF2E7D32),
              size: 28,
            ), // Updated icon to match "Recover" concept or use restore
            const SizedBox(width: 12),
            const Text(
              'Recover Deleted Trips',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading
              ? ListView.separated(
                  controller: widget.scrollController,
                  itemCount: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, __) =>
                      const Skeleton(height: 100, borderRadius: 20),
                )
              : _trashTrips.isEmpty
              ? Center(
                  child: Text(
                    _error != null ? _error! : 'No deleted trips found',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _trashTrips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final trip = _trashTrips[index];
                    final isCamp =
                        trip['type']?.toString().toLowerCase() == 'camp';
                    return Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F7F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCamp
                                  ? Icons.landscape_outlined
                                  : Icons.inventory_2_outlined,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip['title'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildChip(
                                      isCamp ? 'CAMP' : 'PACKAGE',
                                      const Color(0xFFF1F5F9),
                                      Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (trip['destination'] ?? 'Unknown')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _recoverTrip(trip['id'].toString()),
                            icon: const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text("Recover"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bg, Color content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: content,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
