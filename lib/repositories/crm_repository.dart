import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/department.dart';
import '../services/logger_service.dart';

class CRMRepository {
  static const String _keyDepartments = 'crm_departments';

  Future<SharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<List<Department>> getDepartments() async {
    final prefs = await _getPrefs();
    final String? data = prefs.getString(_keyDepartments);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Department.fromJson(e)).toList();
    } catch (e) {
      LoggerService.log("CRMRepository Error: $e");
      return [];
    }
  }

  Future<void> saveDepartments(List<Department> departments) async {
    final prefs = await _getPrefs();
    final String encoded = jsonEncode(departments.map((e) => e.toJson()).toList());
    await prefs.setString(_keyDepartments, encoded);
  }

  Future<void> addDepartment(Department department) async {
    final departments = await getDepartments();
    departments.add(department);
    await saveDepartments(departments);
  }

  Future<void> removeDepartment(String id) async {
    final departments = await getDepartments();
    departments.removeWhere((d) => d.id == id);
    await saveDepartments(departments);
  }

  Future<void> updateDepartment(Department department) async {
    final departments = await getDepartments();
    final index = departments.indexWhere((d) => d.id == department.id);
    if (index != -1) {
      departments[index] = department;
      await saveDepartments(departments);
    }
  }
}
