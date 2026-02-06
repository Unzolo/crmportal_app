import 'api_service.dart';
import 'package:flutter/material.dart';

class CreateBookingPage extends StatefulWidget {
  final String tripId;
  const CreateBookingPage({super.key, required this.tripId});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class ParticipantFormControllers {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  String selectedGender = 'Male';

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    placeController.dispose();
  }
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final ApiService _apiService = ApiService();
  int participantCount = 1;
  final TextEditingController _concessionController = TextEditingController(
    text: '0',
  );
  final List<ParticipantFormControllers> _participantControllers = [
    ParticipantFormControllers(),
  ];
  bool isLoading = false;
  Map<String, dynamic>? trip;

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    try {
      // Wait, there's no getTripDetails? I'll use fetchTrips from appState or just use the current trip data passed from previous page
      // Actually ManageBookingsPage has all trips. I'll just assume we need trip title and price.
      // I'll fetch it from the API if possible.
      final tripsRes = await _apiService.getTrips();
      if (tripsRes['success']) {
        final trips = tripsRes['data'] as List;
        setState(() {
          trip = trips.firstWhere((t) => t['id'].toString() == widget.tripId);
        });
      }
    } catch (e) {
      debugPrint('Error fetching trip details: $e');
    }
  }

  @override
  void dispose() {
    _concessionController.dispose();
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateParticipantCount(int newCount) {
    if (newCount < 1) return;
    setState(() {
      if (newCount > participantCount) {
        for (int i = 0; i < newCount - participantCount; i++) {
          _participantControllers.add(ParticipantFormControllers());
        }
      } else {
        for (int i = 0; i < participantCount - newCount; i++) {
          if (_participantControllers.length > 1) {
            _participantControllers.last.dispose();
            _participantControllers.removeLast();
          }
        }
      }
      participantCount = newCount;
    });
  }

  Future<void> _submitBooking() async {
    setState(() => isLoading = true);
    try {
      final participants = _participantControllers
          .map(
            (c) => {
              'name': c.nameController.text,
              'age': int.tryParse(c.ageController.text) ?? 20,
              'gender': c.selectedGender,
              'phone': c.phoneController.text,
              'place': c.placeController.text,
              'isPrimary': _participantControllers.indexOf(c) == 0,
            },
          )
          .toList();

      final response = await _apiService.createBooking({
        'tripId': widget.tripId,
        'participants': participants,
        'concession': double.tryParse(_concessionController.text) ?? 0,
        // Additional payment details can be added here if needed
      });

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to create booking'),
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
          'Create Booking',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepHeader('Participants'),
                    const SizedBox(height: 24),
                    _buildParticipantCounter(),
                    const SizedBox(height: 24),
                    _buildConcessionCard(),
                    const SizedBox(height: 32),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _participantControllers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        return _buildParticipantForm(index);
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildContinueButton(),
                  ],
                ),
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

  Widget _buildParticipantCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: Colors.green, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Participants Count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Row(
            children: [
              _buildCounterBtn(
                Icons.remove,
                () => _updateParticipantCount(participantCount - 1),
              ),
              const SizedBox(width: 16),
              Text(
                '$participantCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _buildCounterBtn(
                Icons.add,
                () => _updateParticipantCount(participantCount + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green.shade700, size: 20),
      ),
    );
  }

  Widget _buildConcessionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 18,
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Concession / Opt-outs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If any amenities like travel opted out, enter amount to reduce',
            style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _concessionController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.currency_rupee,
                color: Colors.red,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade50),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantForm(int index) {
    bool isPrimary = index == 0;
    var controllers = _participantControllers[index];

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2E8B57),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPrimary ? 'Primary Contact' : 'Member ${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF2E8B57),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Full Name'),
                    _buildFormTextField(
                      controllers.nameController,
                      'Enter Name',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Gender'),
                    _buildGenderDropdown(controllers),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isPrimary) ...[
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Contact Number'),
                      _buildFormTextField(
                        controllers.phoneController,
                        'Phone number',
                        isPhone: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Age'),
                    _buildFormTextField(
                      controllers.ageController,
                      '0',
                      isPhone: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Place (Optional)'),
          _buildFormTextField(controllers.placeController, 'Enter City/Place'),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildFormTextField(
    TextEditingController controller,
    String hint, {
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(ParticipantFormControllers controllers) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controllers.selectedGender,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: ['Male', 'Female', 'Other'].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              controllers.selectedGender = val!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _submitBooking(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E8B57),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Confirm Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
