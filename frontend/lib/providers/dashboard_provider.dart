import 'package:balaji_imitation_admin/services/dashboard_service.dart';
import 'package:flutter/foundation.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  int _totalCategories = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  double _totalSales = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  int get totalCategories => _totalCategories;
  int get totalProducts => _totalProducts;
  int get totalCustomers => _totalCustomers;
  double get totalSales => _totalSales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dashboardService.getDashboardStats();

      _totalCategories = data['totalCategories'] ?? 0;
      _totalProducts = data['totalProducts'] ?? 0;
      _totalCustomers = data['totalCustomers'] ?? 0;
      _totalSales = (data['totalSales'] ?? 0.0).toDouble();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
