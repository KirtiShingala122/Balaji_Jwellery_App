import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class DashboardProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
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
      final futures = await Future.wait([
        _databaseService.getTotalCategories(),
        _databaseService.getTotalProducts(),
        _databaseService.getTotalCustomers(),
        _databaseService.getTotalSales(),
      ]);

      _totalCategories = futures[0] as int;
      _totalProducts = futures[1] as int;
      _totalCustomers = futures[2] as int;
      _totalSales = futures[3] as double;

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
