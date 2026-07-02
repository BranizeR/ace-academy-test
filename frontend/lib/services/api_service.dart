import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/sport.dart';
import '../models/batch.dart';
import '../models/coach.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class ApiService {
  static const String baseUrl = 'http://10.228.143.100:8000/api';

  static const String _tokenKey = 'jwt_token';
  static const String _refreshKey = 'jwt_refresh_token';

  static String? _accessToken;
  static String? _refreshToken;

  // INITIALIZE TOKENS
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshKey);
  }

  // LOGIN
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);
        await prefs.setString(_refreshKey, _refreshToken!);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // LOGOUT
  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // REFRESH TOKEN
  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // HELPER METHODS
  static Map<String, String> get headers {
    final Map<String, String> headerMap = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      headerMap['Authorization'] = 'Bearer $_accessToken';
    }
    return headerMap;
  }

  static Future<http.Response> _sendRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        response = await requestFn();
      } else {
        await logout();
        throw Exception('Session expired. Please login again.');
      }
    }
    return response;
  }

  static Exception _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('detail')) {
        return Exception(body['detail']);
      }
      if (body is Map) {
        final firstError = body.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return Exception(firstError.first.toString());
        }
        return Exception(firstError.toString());
      }
    } catch (_) {}
    return Exception('Server error: ${response.statusCode}');
  }

  // ================== SPORT MODULE ==================

  static Future<List<Sport>> getSports({String? search}) async {
    final uri = Uri.parse('$baseUrl/sports/${search != null ? "?search=$search" : ""}');
    final response = await _sendRequest(() => http.get(uri, headers: headers));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.map((item) => Sport.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<Sport> createSport(Sport sport) async {
    final response = await _sendRequest(() => http.post(
          Uri.parse('$baseUrl/sports/'),
          headers: headers,
          body: jsonEncode({
            'name': sport.name,
            'description': sport.description,
          }),
        ));
    if (response.statusCode == 201) {
      return Sport.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  // ================== BATCH MODULE ==================

  static Future<List<Batch>> getBatches({String? search}) async {
    final uri = Uri.parse('$baseUrl/batches/${search != null ? "?search=$search" : ""}');
    final response = await _sendRequest(() => http.get(uri, headers: headers));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.map((item) => Batch.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<Batch> createBatch(Batch batch) async {
    final response = await _sendRequest(() => http.post(
          Uri.parse('$baseUrl/batches/'),
          headers: headers,
          body: jsonEncode(batch.toJson()),
        ));
    if (response.statusCode == 201) {
      return Batch.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  // ================== COACH MODULE ==================

  static Future<List<Coach>> getCoaches({String? search}) async {
    final uri = Uri.parse('$baseUrl/coaches/${search != null ? "?search=$search" : ""}');
    final response = await _sendRequest(() => http.get(uri, headers: headers));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.map((item) => Coach.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<Coach> createCoach(Coach coach) async {
    final response = await _sendRequest(() => http.post(
          Uri.parse('$baseUrl/coaches/'),
          headers: headers,
          body: jsonEncode(coach.toJson()),
        ));
    if (response.statusCode == 201) {
      return Coach.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  // ================== STUDENT MODULE ==================

  static Future<List<Student>> getStudents({String? search}) async {
    final uri = Uri.parse('$baseUrl/students/${search != null ? "?search=$search" : ""}');
    final response = await _sendRequest(() => http.get(uri, headers: headers));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.map((item) => Student.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<Student> enrollStudent(Student student) async {
    final response = await _sendRequest(() => http.post(
          Uri.parse('$baseUrl/students/'),
          headers: headers,
          body: jsonEncode(student.toJson()),
        ));
    if (response.statusCode == 201) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  // ================== ATTENDANCE MODULE ==================

  static Future<List<Attendance>> getAttendance({int? batchId, String? date}) async {
    final queryParams = <String>[];
    if (batchId != null) queryParams.add('batch_id=$batchId');
    if (date != null) queryParams.add('date=$date');
    final queryStr = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response = await _sendRequest(() => http.get(
          Uri.parse('$baseUrl/attendance/$queryStr'),
          headers: headers,
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'] ?? [];
      return results.map((item) => Attendance.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<Attendance> markAttendance(Attendance attendance) async {
    final response = await _sendRequest(() => http.post(
          Uri.parse('$baseUrl/attendance/'),
          headers: headers,
          body: jsonEncode(attendance.toJson()),
        ));
    if (response.statusCode == 201) {
      return Attendance.fromJson(jsonDecode(response.body));
    } else {
      throw _handleError(response);
    }
  }

  // ================== DASHBOARD MODULE ==================

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _sendRequest(() => http.get(
          Uri.parse('$baseUrl/dashboard/'),
          headers: headers,
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw _handleError(response);
    }
  }
}
