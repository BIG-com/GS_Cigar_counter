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
  ProgressMode? _progressMode; // 선택된 진행 방식 저장
  String? _selectedSection; // 커스텀 모드에서 선택된 진열대
  final Set<String> _completedSections = {}; // 완료된 진열대 목록

  // Getters
  List<ProductEntry> get entries => List.unmodifiable(_entries);

  // 커스텀 모드일 때는 선택된 진열대의 상품만 반환 (진열대 구분 항목 제외)
  List<ProductEntry> get filteredEntries {
    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      return _entries
          .where((e) => e.displaySection == _selectedSection && !e.isSectionDivider)
          .toList();
    }
    return List.unmodifiable(_entries);
  }

  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isFinished {
    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      return _currentIndex >= filteredEntries.length;
    }
    return _currentIndex >= _entries.length;
  }

  ProductEntry? get currentEntry {
    if (isFinished) return null;

    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      final filtered = filteredEntries;
      return _currentIndex < filtered.length ? filtered[_currentIndex] : null;
    }
    return _entries[_currentIndex];
  }

  InputMode? get inputMode => _inputMode;
  ProgressMode? get progressMode => _progressMode;
  String? get selectedSection => _selectedSection;

  // 완료된 항목들만 반환
  List<ProductEntry> get recordedEntries {
    final entries = _entries.where((e) => e.quantity != null).toList();

    // 커스텀 모드: recordedAt 기준 오름차순 정렬 (완료 시간순)
    if (_progressMode == ProgressMode.custom) {
      entries.sort((a, b) {
        if (a.recordedAt == null && b.recordedAt == null) return 0;
        if (a.recordedAt == null) return 1;
        if (b.recordedAt == null) return -1;
        return a.recordedAt!.compareTo(b.recordedAt!);
      });
    }

    return entries;
  }

  // 진행률 계산
  double get progress {
    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      final filtered = filteredEntries;
      return filtered.isEmpty ? 0.0 : _currentIndex / filtered.length;
    }
    return _entries.isEmpty ? 0.0 : _currentIndex / _entries.length;
  }

  // 총 항목 수
  int get totalItems {
    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      return filteredEntries.length;
    }
    return _entries.length;
  }

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
      String? currentDisplaySection; // 현재 진열대 상태 추적
      final nameCol = productNameCol;
      final codeCol = barcodeCol;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length > math.max(nameCol, codeCol)) {
          final productNameCell = row[nameCol];
          final barcodeCell = row[codeCol];

          if (productNameCell?.value != null && barcodeCell?.value != null) {
            final productName = productNameCell!.value.toString().trim();
            final barcode = barcodeCell!.value.toString().trim();

            if (productName.isNotEmpty && barcode.isNotEmpty) {
              // 1단계: 보류/단종 구분 행 체크
              final ignorePattern = RegExp(r'#+\s*(보류|단종)\s*#+');
              if (ignorePattern.hasMatch(productName)) {
                currentDisplaySection = null; // 이후 상품들 무시
                continue; // 구분 행 자체도 추가 안 함
              }

              // 2단계: 진열대 구분 행 패턴 확인: ##### n차 #####
              final sectionPattern = RegExp(r'#+\s*(\d+차)\s*#+');
              final match = sectionPattern.firstMatch(productName);

              if (match != null && match.group(1) != null) {
                // 진열대 구분 행 발견
                currentDisplaySection = match.group(1)!; // "1차", "2차" 등

                // 진열대 구분 항목 추가
                _entries.add(ProductEntry(
                  productName: productName,
                  barcode: barcode,
                  isSectionDivider: true,
                  displaySection: currentDisplaySection,
                ));
              } else {
                // 3단계: 일반 상품 행 (currentDisplaySection이 null이 아닐 때만 추가)
                if (currentDisplaySection != null) {
                  _entries.add(ProductEntry(
                    productName: productName,
                    barcode: barcode,
                    displaySection: currentDisplaySection,
                  ));
                }
              }
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

    if (_progressMode == ProgressMode.custom && _selectedSection != null) {
      // 커스텀 모드: 필터링된 리스트에서 현재 항목을 찾아서 실제 _entries에서 수정
      final filtered = filteredEntries;
      if (_currentIndex >= filtered.length) return;

      final currentItem = filtered[_currentIndex];
      final actualIndex = _entries.indexWhere(
        (e) => e.productName == currentItem.productName && e.barcode == currentItem.barcode,
      );

      if (actualIndex != -1) {
        _entries[actualIndex] = _entries[actualIndex].copyWith(
          quantity: quantity,
          recordedAt: DateTime.now(),
        );
      }
    } else {
      // 일반 모드
      _entries[_currentIndex] = _entries[_currentIndex].copyWith(
        quantity: quantity,
        recordedAt: DateTime.now(),
      );
    }

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

  /// 진행 방식 설정
  void setProgressMode(ProgressMode mode) {
    _progressMode = mode;
    notifyListeners();
  }

  /// 진열대 선택
  void selectSection(String section) {
    _selectedSection = section;
    _currentIndex = 0; // 인덱스 초기화
    notifyListeners();
  }

  /// 진열대 목록 가져오기 (진열대 구분 항목 제외)
  List<String> getSections() {
    final sections = <String>{};
    for (final entry in _entries) {
      if (entry.displaySection != null && !entry.isSectionDivider) {
        sections.add(entry.displaySection!);
      }
    }

    final sectionList = sections.toList();

    // "n차" 형식에서 숫자를 추출하여 숫자 기준으로 정렬
    sectionList.sort((a, b) {
      final numA = int.tryParse(a.replaceAll('차', ''));
      final numB = int.tryParse(b.replaceAll('차', ''));

      if (numA != null && numB != null) {
        return numA.compareTo(numB); // 숫자 비교
      }

      // 숫자 추출 실패 시 문자열 정렬
      return a.compareTo(b);
    });

    return sectionList;
  }

  /// 특정 진열대의 상품 목록 가져오기 (진열대 구분 항목 제외)
  List<ProductEntry> getEntriesBySection(String section) {
    return _entries
        .where((e) => e.displaySection == section && !e.isSectionDivider)
        .toList();
  }

  /// 특정 진열대의 첫 번째 상품 가져오기
  ProductEntry? getFirstProductBySection(String section) {
    final sectionEntries = _entries
        .where((e) => e.displaySection == section && !e.isSectionDivider)
        .toList();

    return sectionEntries.isNotEmpty ? sectionEntries.first : null;
  }

  /// 특정 진열대가 완료되었는지 확인
  bool isSectionCompleted(String section) {
    return _completedSections.contains(section);
  }

  /// 진열대 완료 표시
  void markSectionAsCompleted(String section) {
    _completedSections.add(section);
    notifyListeners();
  }

  /// 현재 진열대의 모든 상품이 입력 완료되었는지 확인
  bool isCurrentSectionFinished() {
    if (_selectedSection == null || _progressMode != ProgressMode.custom) {
      return false;
    }

    final sectionEntries = getEntriesBySection(_selectedSection!);
    if (sectionEntries.isEmpty) return false;

    // 진열대의 모든 상품이 수량 입력되었는지 확인
    return sectionEntries.every((entry) => entry.quantity != null);
  }

  /// 데이터 초기화
  void clear() {
    _entries.clear();
    _currentIndex = 0;
    _summaryScrollPosition = 0.0; // 스크롤 위치도 초기화
    _selectedSummaryItems.clear(); // 선택 상태도 초기화
    _inputMode = null; // 입력 모드도 초기화
    _progressMode = null; // 진행 방식도 초기화
    _selectedSection = null; // 선택된 진열대도 초기화
    _completedSections.clear(); // 완료된 진열대 목록도 초기화
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

