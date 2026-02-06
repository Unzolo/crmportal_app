import 'package:flutter/material.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _profile;
  List<dynamic> _trips = [];
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get profile => _profile;
  List<dynamic> get trips => _trips;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    final token = await _apiService.getToken();
    if (token != null) {
      await fetchProfile();
      await fetchDashboardStats();
    }
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getProfile();
      if (response['success']) {
        _profile = response['data'];
        _errorMessage = null;
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch profile';
        // If profile fetch fails with 401/403, we should probably logout
        if (_errorMessage?.contains('Unauthorized') ?? false) {
          logout();
        }
      }
    } catch (e) {
      _errorMessage = 'Error fetching profile: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getDashboardStats();
      if (response['success']) {
        _dashboardStats = response['data'];
        _errorMessage = null;
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch stats';
      }
    } catch (e) {
      _errorMessage = 'Error fetching dashboard stats: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrips() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getTrips();
      if (response['success']) {
        _trips = response['data'];
        _errorMessage = null;
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch trips';
      }
    } catch (e) {
      _errorMessage = 'Error fetching trips: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.login(email, password);
      if (response['success']) {
        await fetchProfile();
        await fetchDashboardStats();
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _tripBookings = [];
  Map<String, dynamic>? _tripSummary;

  List<dynamic> get tripBookings => _tripBookings;
  Map<String, dynamic>? get tripSummary => _tripSummary;

  Future<void> fetchTripBookings(String tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getTripBookings(tripId);
      if (response['success']) {
        final data = response['data'];
        if (data is Map) {
          _tripBookings = data['bookings'] ?? [];
          _tripSummary = data['summary'];
        } else if (data is List) {
          _tripBookings = data;
          _tripSummary = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching trip bookings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _profile = null;
    _trips = [];
    _tripBookings = [];
    _dashboardStats = null;
    notifyListeners();
  }
}
