import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://crm.unzolo.com/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      await setToken(data['data']['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  // Trip Endpoints
  Future<Map<String, dynamic>> getTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/trips'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getInactiveTrips() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/trips/deleted'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> recoverTrip(String id) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/$id/recover'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteTrip(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/trips/$id'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateTrip(
    String id,
    Map<String, dynamic> data,
  ) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/trips/$id'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: _getHeaders(token),
      body: jsonEncode(tripData),
    );
    return jsonDecode(response.body);
  }

  // Booking Endpoints
  Future<Map<String, dynamic>> getTripBookings(String tripId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings?tripId=$tripId'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    final token = await getToken();
    // Map frontend fields to backend fields if necessary
    final payload = {
      'tripId': bookingData['tripId'],
      'members': bookingData['participants'] ?? bookingData['members'],
      'concessionAmount':
          bookingData['concession'] ?? bookingData['concessionAmount'] ?? 0,
      'paymentType': bookingData['paymentType'] ?? 'advance',
      'paymentMethod': bookingData['paymentMethod'] ?? 'Cash',
      'memberCount': bookingData['memberCount'],
      'preferredDate': bookingData['preferredDate'],
      'totalPackagePrice': bookingData['totalPackagePrice'],
    };

    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  // Expense Endpoints
  Future<Map<String, dynamic>> getExpenses(String tripId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/trip/$tripId'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> expenseData,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/expenses'),
    );

    request.headers.addAll({'Authorization': 'Bearer $token'});

    expenseData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/expenses/$id'),
    );

    request.headers.addAll({'Authorization': 'Bearer $token'});

    expenseData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$expenseId'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  // Dashboard/Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  // Admin Endpoints
  Future<Map<String, dynamic>> getAdminStats() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminPartners() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/partners'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAdminBookingDetails(String id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/bookings/$id'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  // Customer Endpoints
  Future<Map<String, dynamic>> getCustomers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/customers'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  // Enquiry Endpoints
  Future<Map<String, dynamic>> getEnquiries() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/enquiries'),
      headers: _getHeaders(token),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateMaintenanceMode(bool isEnabled) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/settings/maintenance'),
      headers: _getHeaders(token),
      body: jsonEncode({'isEnabled': isEnabled}),
    );
    return jsonDecode(response.body);
  }
}
