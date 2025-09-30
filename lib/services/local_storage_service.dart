import 'dart:convert';
import '../models/product_entry.dart';

/// 인메모리 로컬 저장소 서비스
/// SharedPreferences 대신 임시로 메모리에 데이터를 저장합니다
/// 추후 SharedPreferences나 다른 영구 저장소로 업그레이드 예정
class LocalStorageService {
  static const String _storageKey = 'inventory_records';

  // 인메모리 저장소
  static final Map<String, String> _memoryStorage = <String, String>{};

  /// 메모리 저장소에서 데이터 가져오기 (SharedPreferences 인터페이스 모방)
  static String? _getString(String key) {
    return _memoryStorage[key];
  }

  /// 메모리 저장소에 데이터 저장하기 (SharedPreferences 인터페이스 모방)
  static void _setString(String key, String value) {
    _memoryStorage[key] = value;
  }

  /// 메모리 저장소에서 키 삭제 (SharedPreferences 인터페이스 모방)
  static void _remove(String key) {
    _memoryStorage.remove(key);
  }

  /// 저장된 모든 기록을 로드
  static Future<List<ProductEntry>> _loadAllEntries() async {
    try {
      final String? jsonString = _getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => ProductEntry.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('로컬 저장소 로드 실패: ${e.toString()}');
    }
  }

  /// 모든 기록을 저장
  static Future<void> _saveAllEntries(List<ProductEntry> entries) async {
    try {
      final String jsonString = json.encode(
        entries.map((entry) => entry.toMap()).toList()
      );
      _setString(_storageKey, jsonString);
    } catch (e) {
      throw Exception('로컬 저장소 저장 실패: ${e.toString()}');
    }
  }

  /// 여러 항목을 로컬 저장소에 저장
  static Future<void> saveEntries(List<ProductEntry> newEntries) async {
    try {
      final existingEntries = await _loadAllEntries();

      // 새 항목들 중 수량이 있는 것만 필터링
      final validEntries = newEntries.where((entry) => entry.quantity != null).toList();

      // 기존 기록에 새 기록 추가
      final allEntries = <ProductEntry>[...existingEntries, ...validEntries];

      // 날짜 순으로 정렬 (최근 것부터) - null safety 완전 처리
      allEntries.sort((ProductEntry a, ProductEntry b) {
        final DateTime aDate = a.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate = b.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      await _saveAllEntries(allEntries);
    } catch (e) {
      throw Exception('로컬 저장 실패: ${e.toString()}');
    }
  }

  /// 단일 항목을 로컬 저장소에 저장
  static Future<void> saveEntry(ProductEntry entry) async {
    if (entry.quantity != null) {
      await saveEntries([entry]);
    }
  }

  /// 저장된 기록들을 날짜별로 조회
  static Future<List<ProductEntry>> getEntriesByDate(DateTime date) async {
    try {
      final allEntries = await _loadAllEntries();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return allEntries.where((entry) {
        final recordedAt = entry.recordedAt;
        if (recordedAt == null) return false;
        return recordedAt.isAfter(startOfDay) &&
               recordedAt.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      throw Exception('날짜별 조회 실패: ${e.toString()}');
    }
  }

  /// 모든 기록을 조회 (최근 순)
  static Future<List<ProductEntry>> getAllEntries({int limit = 100}) async {
    try {
      final allEntries = await _loadAllEntries();

      // 이미 날짜순으로 정렬되어 있으므로 limit만 적용
      if (allEntries.length <= limit) {
        return allEntries;
      }

      return allEntries.take(limit).toList();
    } catch (e) {
      throw Exception('전체 기록 조회 실패: ${e.toString()}');
    }
  }

  /// 특정 상품의 기록 조회
  static Future<List<ProductEntry>> getEntriesByProduct(String productName) async {
    try {
      final allEntries = await _loadAllEntries();
      return allEntries.where((entry) => entry.productName == productName).toList();
    } catch (e) {
      throw Exception('상품별 조회 실패: ${e.toString()}');
    }
  }

  /// 특정 기간의 기록 조회
  static Future<List<ProductEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allEntries = await _loadAllEntries();
      return allEntries.where((entry) {
        final recordedAt = entry.recordedAt;
        if (recordedAt == null) return false;
        return recordedAt.isAfter(startDate) &&
               recordedAt.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw Exception('기간별 조회 실패: ${e.toString()}');
    }
  }

  /// 기록 삭제 (인덱스 기반)
  static Future<void> deleteEntry(int index) async {
    try {
      final allEntries = await _loadAllEntries();
      if (index >= 0 && index < allEntries.length) {
        allEntries.removeAt(index);
        await _saveAllEntries(allEntries);
      }
    } catch (e) {
      throw Exception('기록 삭제 실패: ${e.toString()}');
    }
  }

  /// 특정 조건의 기록 삭제
  static Future<void> deleteEntryByCondition(ProductEntry targetEntry) async {
    try {
      final allEntries = await _loadAllEntries();
      allEntries.removeWhere((entry) =>
        entry.productName == targetEntry.productName &&
        entry.barcode == targetEntry.barcode &&
        entry.recordedAt?.millisecondsSinceEpoch == targetEntry.recordedAt?.millisecondsSinceEpoch
      );
      await _saveAllEntries(allEntries);
    } catch (e) {
      throw Exception('조건부 삭제 실패: ${e.toString()}');
    }
  }

  /// 총 기록 수 조회
  static Future<int> getTotalCount() async {
    try {
      final allEntries = await _loadAllEntries();
      return allEntries.length;
    } catch (e) {
      throw Exception('총 개수 조회 실패: ${e.toString()}');
    }
  }

  /// 오늘의 기록 수 조회
  static Future<int> getTodayCount() async {
    try {
      final today = DateTime.now();
      final todayEntries = await getEntriesByDate(today);
      return todayEntries.length;
    } catch (e) {
      throw Exception('오늘 기록 수 조회 실패: ${e.toString()}');
    }
  }

  /// 모든 데이터 초기화 (개발/테스트용)
  static Future<void> clearAllData() async {
    try {
      _remove(_storageKey);
    } catch (e) {
      throw Exception('데이터 초기화 실패: ${e.toString()}');
    }
  }

  /// 데이터 백업 (JSON 문자열로 내보내기)
  static Future<String> exportData() async {
    try {
      final allEntries = await _loadAllEntries();
      return json.encode(allEntries.map((entry) => entry.toMap()).toList());
    } catch (e) {
      throw Exception('데이터 내보내기 실패: ${e.toString()}');
    }
  }

  /// 데이터 복원 (JSON 문자열에서 가져오기)
  static Future<void> importData(String jsonData) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonData);
      final entries = jsonList
          .map((item) => ProductEntry.fromMap(item as Map<String, dynamic>))
          .toList();

      await _saveAllEntries(entries);
    } catch (e) {
      throw Exception('데이터 가져오기 실패: ${e.toString()}');
    }
  }
}