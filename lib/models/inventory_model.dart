import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import '../models/product_entry.dart';
import '../services/local_storage_service.dart';
import '../screens/mode_selection_screen.dart';

class InventoryModel extends ChangeNotifier {
  final List<ProductEntry> _entries = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  double _summaryScrollPosition = 0.0; // SummaryScreen ListView 스크롤 위치 저장
  final Set<int> _selectedSummaryItems = {}; // SummaryScreen에서 선택된 아이템들의 인덱스
  InputMode? _inputMode; // 선택된 입력 모드 저장

  // Getters
  List<ProductEntry> get entries => List.unmodifiable(_entries);
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFinished => _currentIndex >= _entries.length;
  ProductEntry? get currentEntry =>
      isFinished ? null : _entries[_currentIndex];
  InputMode? get inputMode => _inputMode;

  // 완료된 항목들만 반환
  List<ProductEntry> get recordedEntries =>
      _entries.where((e) => e.quantity != null).toList();

  // 진행률 계산
  double get progress =>
      _entries.isEmpty ? 0.0 : _currentIndex / _entries.length;

  // 총 항목 수
  int get totalItems => _entries.length;

  // 기록된 항목 수
  int get recordedItems => recordedEntries.length;

  // 스크롤 위치 저장/복원 메서드
  double get summaryScrollPosition => _summaryScrollPosition;

  void saveSummaryScrollPosition(double position) {
    _summaryScrollPosition = position;
    // 스크롤 위치는 UI 상태이므로 notifyListeners 호출하지 않음
  }

  // 선택된 상품목록 상태 관리 메서드들
  Set<int> get selectedSummaryItems => Set.unmodifiable(_selectedSummaryItems);

  void toggleSummaryItemSelection(int index) {
    if (_selectedSummaryItems.contains(index)) {
      _selectedSummaryItems.remove(index);
    } else {
      _selectedSummaryItems.add(index);
    }
    // 선택 상태는 UI에 즉시 반영되어야 하므로 notifyListeners 호출하지 않음
  }

  bool isSummaryItemSelected(int index) {
    return _selectedSummaryItems.contains(index);
  }

  void clearSummarySelection() {
    _selectedSummaryItems.clear();
    // 선택 상태는 UI에 즉시 반영되어야 하므로 notifyListeners 호출하지 않음
  }

  /// Excel 파일에서 데이터 로드
  Future<void> loadFromExcelBytes(Uint8List bytes) async {
    try {
      _setLoading(true);
      _clearError();

      _entries.clear();

      print('Excel 파일 로드 시작: ${bytes.length} 바이트');

      // Excel 파일 파싱
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('Excel 파일에 시트가 없습니다.');
      }

      // 첫 번째 시트 가져오기
      final String sheetName = excel.tables.keys.first;
      final Sheet sheet = excel.tables[sheetName]!;

      // 헤더 행에서 컬럼 찾기
      int? productNameCol;
      int? barcodeCol;

      if (sheet.rows.isNotEmpty) {
        final headerRow = sheet.rows[0];
        for (int i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell?.value != null) {
            final cellValue = cell!.value.toString().toLowerCase().trim();
            if (cellValue.contains('상품명') ||
                cellValue.contains('제품명') ||
                cellValue.contains('product') ||
                cellValue.contains('name')) {
              productNameCol = i;
            } else if (cellValue.contains('바코드') ||
                       cellValue.contains('barcode') ||
                       cellValue.contains('코드') ||
                       cellValue.contains('code')) {
              barcodeCol = i;
            }
          }
        }
      }

      if (productNameCol == null || barcodeCol == null) {
        throw Exception('필수 컬럼을 찾을 수 없습니다.\n상품명(Product Name), 바코드(Barcode) 컬럼이 필요합니다.');
      }

      // 데이터 행 읽기 (헤더 제외)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length > math.max(productNameCol!, barcodeCol!)) {
          final productNameCell = row[productNameCol];
          final barcodeCell = row[barcodeCol];

          if (productNameCell?.value != null && barcodeCell?.value != null) {
            final productName = productNameCell!.value.toString().trim();
            final barcode = barcodeCell!.value.toString().trim();

            if (productName.isNotEmpty && barcode.isNotEmpty) {
              _entries.add(ProductEntry(
                productName: productName,
                barcode: barcode,
              ));
            }
          }
        }
      }

      _currentIndex = 0;

      if (_entries.isEmpty) {
        throw Exception('Excel 파일에서 유효한 상품 데이터를 찾을 수 없습니다.\n파일 형식을 확인해주세요.');
      }

      print('Excel 파일에서 ${_entries.length}개 상품 로드 완료');
      notifyListeners();
    } catch (e) {
      print('Excel 파일 로드 실패: $e');
      _setError('Excel 파일 로드 실패: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 현재 항목에 수량 설정 후 다음 항목으로 이동
  void setQuantityForCurrent(int quantity) {
    if (isFinished || quantity < 0 || quantity > 99) return;

    _entries[_currentIndex] = _entries[_currentIndex].copyWith(
      quantity: quantity,
      recordedAt: DateTime.now(),
    );

    _currentIndex++;
    notifyListeners();
  }

  /// 이전 항목으로 돌아가기
  void goToPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  /// 특정 인덱스로 이동
  void goToIndex(int index) {
    if (index >= 0 && index < _entries.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// 특정 항목의 수량 수정
  void updateQuantityAt(int index, int? quantity) {
    if (index >= 0 && index < _entries.length) {
      _entries[index] = _entries[index].copyWith(
        quantity: quantity,
        recordedAt: quantity != null ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  /// 기록된 데이터를 CSV 파일로 내보내기
  Future<File> exportRecordedToExcel() async {
    try {
      _setLoading(true);

      print('CSV 파일 내보내기: ${recordedEntries.length}개 항목');

      final buffer = StringBuffer();
      buffer.writeln('Date,ProductName,Barcode,Quantity');

      for (final entry in recordedEntries) {
        buffer.writeln('${entry.recordedAt?.toIso8601String() ?? ''},${entry.productName},${entry.barcode},${entry.quantity ?? 0}');
      }

      final dir = Directory.systemTemp;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final path = '${dir.path}/inventory_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      return file;
    } catch (e) {
      _setError('CSV 내보내기 실패: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 로컬 저장소에 데이터 저장 (Firebase는 추후 업데이트 예정)
  Future<void> saveToLocalStorage() async {
    try {
      _setLoading(true);
      await LocalStorageService.saveEntries(recordedEntries);
    } catch (e) {
      _setError('로컬 저장 실패: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 입력 모드 설정
  void setInputMode(InputMode mode) {
    _inputMode = mode;
    notifyListeners();
  }

  /// 데이터 초기화
  void clear() {
    _entries.clear();
    _currentIndex = 0;
    _summaryScrollPosition = 0.0; // 스크롤 위치도 초기화
    _selectedSummaryItems.clear(); // 선택 상태도 초기화
    _inputMode = null; // 입력 모드도 초기화
    _clearError();
    notifyListeners();
  }

  // Private methods
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
  }
}

