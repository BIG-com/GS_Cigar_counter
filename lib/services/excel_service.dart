import 'dart:typed_data';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_entry.dart';

class ExcelService {
  /// Excel 파일에서 상품 데이터 로드
  static Future<List<ProductEntry>> loadFromFile(Uint8List bytes) async {
    try {
      print('Excel 파일 로드 시작: ${bytes.length} 바이트');

      final excel = Excel.decodeBytes(bytes);
      final List<ProductEntry> products = [];

      // 첫 번째 시트 가져오기
      if (excel.tables.isEmpty) {
        throw Exception('Excel 파일에 시트가 없습니다.');
      }

      final sheetName = excel.tables.keys.first;
      if (sheetName == null) {
        throw Exception('유효한 시트를 찾을 수 없습니다.');
      }

      final Sheet? sheet = excel.tables[sheetName];
      if (sheet == null) {
        throw Exception('시트를 읽을 수 없습니다.');
      }

      // 헤더 행 찾기
      int? productNameCol;
      int? barcodeCol;

      // 첫 번째 행에서 헤더 찾기
      if (sheet.rows.isNotEmpty) {
        final headerRow = sheet.rows[0];
        for (int i = 0; i < headerRow.length; i++) {
          final cell = headerRow[i];
          if (cell?.value != null) {
            final cellValue = cell!.value.toString().toLowerCase().trim();
            if (cellValue.contains('상품명') || cellValue.contains('제품명') || cellValue.contains('product')) {
              productNameCol = i;
            } else if (cellValue.contains('바코드') || cellValue.contains('barcode') || cellValue.contains('코드')) {
              barcodeCol = i;
            }
          }
        }
      }

      if (productNameCol == null || barcodeCol == null) {
        throw Exception('필수 컬럼을 찾을 수 없습니다. (상품명, 바코드 컬럼이 필요합니다)');
      }

      // 데이터 행 읽기 (헤더 제외)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.length > productNameCol && row.length > barcodeCol) {
          final productNameCell = row[productNameCol];
          final barcodeCell = row[barcodeCol];

          if (productNameCell?.value != null && barcodeCell?.value != null) {
            final productName = productNameCell.value.toString().trim();
            final barcode = barcodeCell.value.toString().trim();

            if (productName.isNotEmpty && barcode.isNotEmpty) {
              products.add(ProductEntry(
                productName: productName,
                barcode: barcode,
              ));
            }
          }
        }
      }

      print('Excel 파일에서 ${products.length}개 상품 로드 완료');
      return products;

    } catch (e) {
      print('Excel 파일 로드 실패: $e');
      throw Exception('Excel 파일을 읽는 중 오류가 발생했습니다: $e');
    }
  }

  /// 기록된 데이터를 Excel 파일로 내보내기
  static Future<File> exportToFile(List<ProductEntry> entries) async {
    try {
      print('Excel 파일 내보내기 시작: ${entries.length}개 항목');

      final excel = Excel.createExcel();
      final sheetName = 'InventoryData';
      final sheet = excel[sheetName];

      // 헤더 추가
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('날짜');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('상품명');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('바코드');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('수량');

      // 데이터 추가
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final rowIndex = i + 2; // 헤더 다음 행부터 시작

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(entry.recordedAt?.toIso8601String().substring(0, 19) ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(entry.productName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
          TextCellValue(entry.barcode);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value =
          IntCellValue(entry.quantity ?? 0);
      }

      // 파일 저장
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/inventory_$timestamp.xlsx');

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        print('Excel 파일 내보내기 완료: ${file.path}');
        return file;
      } else {
        throw Exception('Excel 파일 생성에 실패했습니다.');
      }

    } catch (e) {
      print('Excel 파일 내보내기 실패: $e');
      throw Exception('Excel 파일 내보내기 중 오류가 발생했습니다: $e');
    }
  }

  /// Excel 파일 유효성 검사 (모조 구현)
  static bool isValidExcelFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return extension == 'xlsx' || extension == 'xls';
  }

  /// 파일 크기가 적절한지 확인 (모조 구현)
  static bool isValidFileSize(int sizeInBytes) {
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    return sizeInBytes <= maxSizeInBytes;
  }
}