class ProductEntry {
  final String productName;
  final String barcode;
  int? quantity;
  DateTime? recordedAt;

  ProductEntry({
    required this.productName,
    required this.barcode,
    this.quantity,
    this.recordedAt,
  });

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toMap() => {
        'productName': productName,
        'barcode': barcode,
        'quantity': quantity,
        'recordedAt': recordedAt?.toIso8601String(),
      };

  // Firestore에서 데이터를 가져올 때 사용
  factory ProductEntry.fromMap(Map<String, dynamic> map) {
    return ProductEntry(
      productName: map['productName'] ?? '',
      barcode: map['barcode'] ?? '',
      quantity: map['quantity'],
      recordedAt: map['recordedAt'] != null
          ? DateTime.parse(map['recordedAt'])
          : null,
    );
  }

  // 디버깅을 위한 문자열 표현
  @override
  String toString() {
    return 'ProductEntry(productName: $productName, barcode: $barcode, quantity: $quantity, recordedAt: $recordedAt)';
  }

  // 수량이 입력되었는지 확인
  bool get hasQuantity => quantity != null;

  // 복사본 생성 (수량 업데이트 시 사용)
  ProductEntry copyWith({
    String? productName,
    String? barcode,
    int? quantity,
    DateTime? recordedAt,
  }) {
    return ProductEntry(
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}