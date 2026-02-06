import 'package:flutter/material.dart';
import 'api_service.dart';

class CreateTripPage extends StatefulWidget {
  final Map<String, dynamic>? trip;
  const CreateTripPage({super.key, this.trip});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  String? selectedType; // 'Camp' or 'Package'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _groupSizeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _advanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _initFormData(widget.trip!);
    }
  }

  void _initFormData(Map<String, dynamic> trip) {
    selectedType = (trip['type']?.toString().toLowerCase() == 'camp')
        ? 'Camp'
        : 'Package';
    _titleController.text = trip['title'] ?? '';
    _destinationController.text = trip['destination'] ?? '';
    _priceController.text = trip['price']?.toString() ?? '';
    _advanceController.text = trip['advanceAmount']?.toString() ?? '';
    _groupSizeController.text =
        trip['groupSize'] ?? trip['capacity']?.toString() ?? '';
    if (trip['category'] != null) {
      // Ensure category matches dropdown items or handle custom
      // For simplicity, we assume it matches one of the options or is null
      _selectedCategory = trip['category'];
    }
    if (trip['startDate'] != null) {
      _startDate = DateTime.tryParse(trip['startDate']);
    }
    if (trip['endDate'] != null) {
      _endDate = DateTime.tryParse(trip['endDate']);
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
        title: Text(
          widget.trip != null
              ? 'Edit Trip'
              : (selectedType == null ? 'Select Trip Type' : 'Create Trip'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
              child: selectedType == null
                  ? _buildTypeSelection()
                  : _buildCreateForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const Text(
              'Trip Type',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the type of trip to list',
          style: TextStyle(color: Colors.grey.shade500),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTypeCard('Camp', Icons.landscape_outlined, () {
              setState(() => selectedType = 'Camp');
            }),
            _buildTypeCard('Package Trip', Icons.inventory_2, () {
              setState(() => selectedType = 'Package');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7F2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E8B57),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSubmitting = false;

  Future<void> _submitTrip() async {
    if (_titleController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and destination')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiService = ApiService();
      final isPackage = selectedType?.toLowerCase() == 'package';

      final Map<String, dynamic> tripData = {
        'type': selectedType?.toLowerCase(),
        'title': _titleController.text,
        'destination': _destinationController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'advanceAmount': double.tryParse(_advanceController.text) ?? 0.0,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'category': isPackage ? _selectedCategory : null,
        'groupSize': isPackage ? null : _groupSizeController.text,
        'capacity': isPackage
            ? (int.tryParse(_groupSizeController.text) ?? 0)
            : 0,
      };

      final response = widget.trip != null
          ? await apiService.updateTrip(widget.trip!['id'].toString(), tripData)
          : await apiService.createTrip(tripData);
      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip created successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to create trip'),
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelRow(
            'Trip Type',
            onActionTap: () {
              setState(() => selectedType = null);
            },
            actionLabel: 'Edit Type',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedType == 'Camp'
                        ? Icons.landscape_outlined
                        : Icons.inventory_2,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  selectedType!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (selectedType == 'Camp') ...[
            _buildInputLabel('Trip Title'),
            _buildTextField(_titleController, 'e.g. Riverside Camp'),
            const SizedBox(height: 20),
            _buildInputLabel('Destination'),
            _buildTextField(_destinationController, 'e.g. Wayanad'),
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
                      _buildPriceField(controller: _priceController),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Advance'),
                      _buildPriceField(controller: _advanceController),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildInputLabel('Package Title'),
            _buildTextField(_titleController, 'e.g. Kerala Package'),
            const SizedBox(height: 20),
            _buildInputLabel('Destination'),
            _buildTextField(_destinationController, 'e.g. Munnar'),
            const SizedBox(height: 20),
            _buildInputLabel('Category'),
            _buildDropdown(),
            const SizedBox(height: 20),
            _buildInputLabel('Group Size'),
            _buildTextField(_groupSizeController, 'e.g. 10-15 people'),
            const SizedBox(height: 20),
            _buildInputLabel('Package Price (per person)'),
            _buildPriceField(controller: _priceController),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.trip != null ? 'Update Trip' : 'Create Trip',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelRow(
    String label, {
    required VoidCallback onActionTap,
    required String actionLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2E8B57),
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: onActionTap,
          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
          label: Text(
            actionLabel,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: Text(
            'Select Category',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          isExpanded: true,
          items: [
            'Adventure',
            'Relaxation',
            'Family',
            'Cultural',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildPriceField({required TextEditingController controller}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.currency_rupee,
          color: Color(0xFF2E8B57),
          size: 20,
        ),
        hintText: 'Amount',
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
              : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}")
        : (_endDate == null
              ? 'Select Date'
              : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}");

    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: TextStyle(
                color: (isStart ? _startDate : _endDate) == null
                    ? Colors.grey.shade300
                    : Colors.black,
              ),
            ),
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF2E8B57),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
