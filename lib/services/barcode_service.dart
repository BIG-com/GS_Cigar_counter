import 'package:flutter/material.dart';
import '../models/product_entry.dart';

// BarcodeType enum 정의 (충돌 방지)
enum AppBarcodeType {
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
}

class BarcodeService {
  /// 바코드 타입 감지 및 검증
  static AppBarcodeType detectBarcodeType(String barcodeData) {
    // EAN-13 (13자리)
    if (barcodeData.length == 13 && RegExp(r'^\\d{13}$').hasMatch(barcodeData)) {
      return AppBarcodeType.ean13;
    }
    // EAN-8 (8자리)
    else if (barcodeData.length == 8 && RegExp(r'^\\d{8}$').hasMatch(barcodeData)) {
      return AppBarcodeType.ean8;
    }
    // UPC-A (12자리)
    else if (barcodeData.length == 12 && RegExp(r'^\\d{12}$').hasMatch(barcodeData)) {
      return AppBarcodeType.upcA;
    }
    // UPC-E (6자리)
    else if (barcodeData.length == 6 && RegExp(r'^\\d{6}$').hasMatch(barcodeData)) {
      return AppBarcodeType.upcE;
    }
    // Code 128 (가변 길이)
    else if (barcodeData.isNotEmpty) {
      return AppBarcodeType.code128;
    }

    // 기본값
    return AppBarcodeType.code128;
  }

  // barcode_widget conversion method removed due to missing dependency

  /// 바코드가 유효한지 검증
  static bool isValidBarcode(String barcodeData) {
    if (barcodeData.isEmpty) return false;

    // 최소 길이 검증
    if (barcodeData.length < 3) return false;

    // 최대 길이 검증 (일반적인 바코드는 30자를 넘지 않음)
    if (barcodeData.length > 30) return false;

    return true;
  }

  /// 바코드 데이터 정규화 (앞뒤 공백 제거, 대소문자 통일 등)
  static String normalizeBarcode(String barcodeData) {
    return barcodeData.trim().toUpperCase();
  }

  /// 상품 목록에서 바코드로 상품 찾기
  static ProductEntry? findProductByBarcode(
    List<ProductEntry> products,
    String scannedBarcode
  ) {
    final normalizedScanned = normalizeBarcode(scannedBarcode);

    // 정확한 매칭 우선
    for (final product in products) {
      if (normalizeBarcode(product.barcode) == normalizedScanned) {
        return product;
      }
    }

    // 부분 매칭 (바코드 끝부분이 일치하는 경우)
    for (final product in products) {
      final normalizedProduct = normalizeBarcode(product.barcode);
      if (normalizedProduct.endsWith(normalizedScanned) ||
          normalizedScanned.endsWith(normalizedProduct)) {
        return product;
      }
    }

    return null;
  }

  /// 상품 목록에서 바코드로 인덱스 찾기
  static int findProductIndexByBarcode(
    List<ProductEntry> products,
    String scannedBarcode
  ) {
    final normalizedScanned = normalizeBarcode(scannedBarcode);

    // 정확한 매칭 우선
    for (int i = 0; i < products.length; i++) {
      if (normalizeBarcode(products[i].barcode) == normalizedScanned) {
        return i;
      }
    }

    // 부분 매칭
    for (int i = 0; i < products.length; i++) {
      final normalizedProduct = normalizeBarcode(products[i].barcode);
      if (normalizedProduct.endsWith(normalizedScanned) ||
          normalizedScanned.endsWith(normalizedProduct)) {
        return i;
      }
    }

    return -1; // 찾지 못함
  }

  /// 바코드 데이터의 체크섬 검증 (EAN-13용)
  static bool validateEAN13Checksum(String barcode) {
    if (barcode.length != 13) return false;

    try {
      final digits = barcode.split('').map(int.parse).toList();
      int sum = 0;

      for (int i = 0; i < 12; i++) {
        sum += digits[i] * (i % 2 == 0 ? 1 : 3);
      }

      final checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == digits[12];
    } catch (e) {
      return false;
    }
  }

  /// 스캔 결과 분석 및 정보 제공
  static Map<String, dynamic> analyzeBarcodeData(String barcodeData) {
    final normalized = normalizeBarcode(barcodeData);
    final type = detectBarcodeType(normalized);
    final isValid = isValidBarcode(normalized);

    String description = '';
    switch (type) {
      case AppBarcodeType.ean13:
        description = 'EAN-13 (유럽 상품 코드)';
        break;
      case AppBarcodeType.ean8:
        description = 'EAN-8 (짧은 유럽 상품 코드)';
        break;
      case AppBarcodeType.upcA:
        description = 'UPC-A (미국 상품 코드)';
        break;
      case AppBarcodeType.upcE:
        description = 'UPC-E (짧은 미국 상품 코드)';
        break;
      case AppBarcodeType.code128:
        description = 'Code 128 (범용 바코드)';
        break;
    }

    return {
      'original': barcodeData,
      'normalized': normalized,
      'type': type,
      'description': description,
      'isValid': isValid,
      'length': normalized.length,
    };
  }

  /// 바코드 위젯 생성 헬퍼 (모조 구현)
  /// 실제 바코드 위젯은 추후 구현 예정
  static Widget createBarcodeWidget({
    required String data,
    double? width,
    double? height,
    Color? color,
    Color? backgroundColor,
    bool showText = true,
  }) {
    return Container(
      width: width ?? 200,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code,
            size: 40,
            color: Colors.black54,
          ),
          if (showText) ...[
            const SizedBox(height: 8),
            Text(
              data,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 바코드 스캔 결과 클래스
class BarcodeScanResult {
  final String data;
  final AppBarcodeType type;
  final bool isValid;
  final DateTime scannedAt;
  final ProductEntry? matchedProduct;
  final int? productIndex;

  BarcodeScanResult({
    required this.data,
    required this.type,
    required this.isValid,
    required this.scannedAt,
    this.matchedProduct,
    this.productIndex,
  });

  factory BarcodeScanResult.fromScan(
    String data,
    List<ProductEntry> products
  ) {
    final normalized = BarcodeService.normalizeBarcode(data);
    final type = BarcodeService.detectBarcodeType(normalized);
    final isValid = BarcodeService.isValidBarcode(normalized);
    final matchedProduct = BarcodeService.findProductByBarcode(products, normalized);
    final productIndex = BarcodeService.findProductIndexByBarcode(products, normalized);

    return BarcodeScanResult(
      data: normalized,
      type: type,
      isValid: isValid,
      scannedAt: DateTime.now(),
      matchedProduct: matchedProduct,
      productIndex: productIndex != -1 ? productIndex : null,
    );
  }

  bool get hasMatch => matchedProduct != null;
}