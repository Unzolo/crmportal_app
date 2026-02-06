import 'package:flutter/material.dart';

class EditTripPage extends StatefulWidget {
  final String initialTitle;
  final String initialDestination;
  final String initialPrice;
  final String initialType;

  const EditTripPage({
    super.key,
    this.initialTitle = 'test',
    this.initialDestination = 'munnar',
    this.initialPrice = '8000',
    this.initialType = 'Camp',
  });

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  late String selectedType;
  late TextEditingController _titleController;
  late TextEditingController _destinationController;
  late TextEditingController _priceController;
  final TextEditingController _advanceController = TextEditingController(
    text: '2000',
  );
  DateTime? _startDate = DateTime(2026, 2, 17);
  DateTime? _endDate = DateTime(2026, 2, 19);

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    _titleController = TextEditingController(text: widget.initialTitle);
    _destinationController = TextEditingController(
      text: widget.initialDestination,
    );
    _priceController = TextEditingController(text: widget.initialPrice);
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
          'Edit Trip',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () =>
                _showDeleteConfirmation(context, _titleController.text),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Trip Type'),
                    const SizedBox(height: 8),
                    _buildTypeToggle(),
                    const SizedBox(height: 24),
                    _buildInputLabel('Trip Title'),
                    _buildTextField(_titleController, 'e.g. Kerala'),
                    const SizedBox(height: 20),
                    _buildInputLabel('Destination'),
                    _buildTextField(_destinationController, 'e.g. Munnar'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Start Date'),
                              _buildDatePickerField(true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('End Date'),
                              _buildDatePickerField(false),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Total Price'),
                              _buildPriceField(_priceController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Advance amount'),
                              _buildPriceField(_advanceController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Update Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedType = 'Camp'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'Camp'
                      ? const Color(0xFF2E8B57)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.landscape_outlined,
                      color: selectedType == 'Camp'
                          ? Colors.white
                          : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Camp',
                      style: TextStyle(
                        color: selectedType == 'Camp'
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedType = 'Package'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedType == 'Package'
                      ? const Color(0xFF2E8B57)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: selectedType == 'Package'
                          ? Colors.white
                          : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Package',
                      style: TextStyle(
                        color: selectedType == 'Package'
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E8B57),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade300),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(bool isStart) {
    String dateText = isStart
        ? (_startDate == null
              ? 'Select Date'
              : "${_getMonthName(_startDate!.month)} ${_startDate!.day}th, ${_startDate!.year}")
        : (_endDate == null
              ? 'Select Date'
              : "${_getMonthName(_endDate!.month)} ${_endDate!.day}th, ${_endDate!.year}");

    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
            } else {
              _endDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: Colors.green.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(
                  color: (isStart ? _startDate : _endDate) == null
                      ? Colors.grey.shade300
                      : Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildPriceField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.currency_rupee,
          color: Color(0xFF2E8B57),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "$title"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform delete logic here
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to manage bookings
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$title" deleted successfully')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
