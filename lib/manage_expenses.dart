import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'widgets/skeleton.dart';

class ManageExpensesPage extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  final String tripLocation;

  const ManageExpensesPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    this.tripLocation = 'Unknown',
  });

  @override
  State<ManageExpensesPage> createState() => _ManageExpensesPageState();
}

class _ManageExpensesPageState extends State<ManageExpensesPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> expenses = [];
  Map<String, dynamic> summary = {'total': 0, 'byCategory': {}, 'count': 0};
  bool isLoading = true;

  final Map<String, IconData> categoryIcons = {
    'food': Icons.restaurant,
    'transportation': Icons.directions_bus,
    'accommodation': Icons.hotel,
    'activities': Icons.local_activity,
    'equipment': Icons.build_outlined,
    'other': Icons.more_horiz,
  };

  final Map<String, Color> categoryColors = {
    'food': Colors.orange,
    'transportation': Colors.blue,
    'accommodation': Colors.purple,
    'activities': Colors.teal,
    'equipment': Colors.green,
    'other': Colors.grey,
  };

  String _formatCategory(String key) {
    if (key == 'accommodation') return 'Stay';
    if (key == 'transportation') return 'Transport';
    return key[0].toUpperCase() + key.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      final response = await _apiService.getExpenses(widget.tripId);
      if (response['success'] == true) {
        final data = response['data'] ?? {};
        setState(() {
          expenses = data['expenses'] ?? [];
          summary =
              data['summary'] ?? {'total': 0, 'byCategory': {}, 'count': 0};
        });
        if (expenses.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No expenses found for trip ${widget.tripId}'),
            ),
          );
        }
      } else {
        if (mounted) {
          final msg = response['message'] ?? 'Unknown error';
          final err = response['error']?.toString() ?? '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $msg $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      final response = await _apiService.deleteExpense(id);
      if (response['success'] == true) {
        setState(() {
          expenses.removeWhere((e) => e['id'].toString() == id);
        });
        _fetchExpenses(); // Refresh summary stats
      } else {
        debugPrint('Delete failed: ${response['message']}');
      }
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF1F8F4,
      ), // Light greenish background match
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
              child: isLoading
                  ? _buildSkeletonLoading()
                  : RefreshIndicator(
                      onRefresh: _fetchExpenses,
                      color: const Color(0xFF2E7D32),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Trip Expenses'),
                            Padding(
                              padding: const EdgeInsets.only(left: 17, top: 4),
                              child: Text(
                                '${widget.tripTitle} • ${widget.tripLocation}'
                                    .toLowerCase(),
                                style: TextStyle(
                                  color: Colors.blueGrey.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSummarySection(),
                            const SizedBox(height: 32),
                            _buildBreakdownSection(),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader('ALL TRANSACTIONS'),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddExpenseSheet(context),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'New Expense',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTransactionsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 30, width: 200),
          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Skeleton(height: 100)),
              SizedBox(width: 16),
              Expanded(child: Skeleton(height: 100)),
            ],
          ),
          const SizedBox(height: 32),
          const Skeleton(height: 20, width: 200),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Skeleton(height: 100, borderRadius: 20),
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

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'TOTAL',
            '₹${summary['total']}',
            Icons.currency_rupee,
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'ITEMS',
            '${summary['count']}',
            Icons.receipt_long_outlined,
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade200,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final byCat = summary['byCategory'] as Map? ?? {};
    if (byCat.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BREAKDOWN BY CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade200,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: byCat.entries.map((e) {
              final percentage =
                  (double.tryParse(e.value.toString()) ?? 0) /
                  (double.tryParse(summary['total'].toString()) ?? 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          categoryIcons[e.key] ?? Icons.more_horiz,
                          size: 18,
                          color: Colors.blueGrey.shade200,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatCategory(e.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${e.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey.shade200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          categoryColors[e.key] ?? const Color(0xFF2E7D32),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('No transactions recorded yet'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) => _buildTransactionCard(expenses[index]),
    );
  }

  Widget _buildTransactionCard(dynamic expense) {
    final cat = expense['category'] ?? 'other';
    final date = expense['date'] != null
        ? DateFormat('dd MMM, yyyy').format(DateTime.parse(expense['date']))
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (categoryColors[cat] ?? Colors.grey).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              categoryIcons[cat] ?? Icons.more_horiz,
              color: (categoryColors[cat] ?? Colors.grey).withOpacity(0.4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (categoryColors[cat] ?? Colors.grey).withOpacity(
                          0.05,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatCategory(cat).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: (categoryColors[cat] ?? Colors.grey)
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• $date',
                      style: TextStyle(
                        color: Colors.blueGrey.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  expense['description'] ?? 'No description',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${expense['amount']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _showEditExpenseSheet(context, expense);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteExpense(expense['id'].toString()),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Colors.red.shade300,
                      ),
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

  void _showAddExpenseSheet(BuildContext context) {
    _showExpenseSheet(context);
  }

  void _showEditExpenseSheet(
    BuildContext context,
    Map<String, dynamic> expense,
  ) {
    _showExpenseSheet(context, expense: expense);
  }

  void _showExpenseSheet(
    BuildContext context, {
    Map<String, dynamic>? expense,
  }) {
    final bool isEdit = expense != null;
    final amountController = TextEditingController(
      text: expense?['amount']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: expense?['description'] ?? '',
    );
    final paidByController = TextEditingController(
      text: expense?['paidBy'] ?? '',
    );
    final notesController = TextEditingController(
      text: expense?['notes'] ?? '',
    );
    String? selectedCat = expense?['category'];
    DateTime selectedDate = DateTime.now();
    if (expense != null && expense['date'] != null) {
      selectedDate = DateTime.parse(expense['date']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    isEdit ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildInputLabel('Category'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCat,
                      isExpanded: true,
                      hint: Text(
                        'Select category',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      items: categoryIcons.keys
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                _formatCategory(e),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => selectedCat = v),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInputLabel('Description'),
                TextField(
                  controller: descController,
                  decoration: _inputDecoration('e.g., Hotel stay for 2 nights'),
                ),
                const SizedBox(height: 24),
                _buildInputLabel('Amount'),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    '0',
                    prefix: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInputLabel('Date'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          DateFormat('MMMM dth, yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInputLabel('Paid By (Optional)'),
                TextField(
                  controller: paidByController,
                  decoration: _inputDecoration('e.g., John Doe'),
                ),
                const SizedBox(height: 24),
                _buildInputLabel('Notes (Optional)'),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: _inputDecoration('Add any additional notes...'),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty || selectedCat == null)
                        return;

                      final Map<String, dynamic> data = {
                        'tripId': widget.tripId,
                        'amount': amountController.text,
                        'description': descController.text,
                        'category': selectedCat,
                        'date': selectedDate.toIso8601String(),
                        'paidBy': paidByController.text,
                        'notes': notesController.text,
                      };

                      final res = isEdit
                          ? await _apiService.updateExpense(
                              expense['id'].toString(),
                              data,
                            )
                          : await _apiService.createExpense(data);

                      if (res['success'] == true) {
                        Navigator.pop(context);
                        _fetchExpenses();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed: ${res['message'] ?? 'Unknown'} ${res['error'] ?? ''}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Update Expense' : 'Add Expense',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefix != null
          ? Icon(prefix, size: 18, color: Colors.blueGrey.shade200)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }
}
