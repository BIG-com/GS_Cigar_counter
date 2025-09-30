import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/inventory_model.dart';
import '../widgets/quantity_input.dart';
import '../services/barcode_service.dart';
import 'summary_screen.dart';
import 'barcode_scanner_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  String? _lastCheckedBarcode;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryModel>(
      builder: (context, inventoryModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('수량 입력'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF9575CD),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => _openBarcodeScanner(inventoryModel),
                tooltip: '바코드 스캔',
              ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () => _navigateToSummary(),
                tooltip: '목록 보기',
              ),
            ],
          ),
          body: _buildBody(inventoryModel),
        );
      },
    );
  }

  Widget _buildBody(InventoryModel inventoryModel) {
    if (inventoryModel.entries.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    if (inventoryModel.isFinished) {
      // 모든 항목 완료 시 자동으로 요약 화면으로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToSummary();
      });
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('모든 항목 입력이 완료되었습니다!'),
          ],
        ),
      );
    }

    final currentEntry = inventoryModel.currentEntry;
    if (currentEntry == null) {
      return const Center(child: Text('현재 항목이 없습니다.'));
    }

    // 바코드 11111111 체크 및 다이얼로그 표시
    if (currentEntry.barcode == '11111111' && _lastCheckedBarcode != currentEntry.barcode) {
      _lastCheckedBarcode = currentEntry.barcode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSpecialBarcodeDialog(context, inventoryModel);
      });
    }

    return Column(
      children: [
        // 진행률 표시
        _buildProgressIndicator(inventoryModel),

        // 현재 항목 정보
        Expanded(
          child: SingleChildScrollView(
            child: _buildCurrentItem(inventoryModel, currentEntry),
          ),
        ),

        // 수량 입력 위젯
        _buildQuantityInput(inventoryModel),

        // 네비게이션 버튼
        _buildNavigationButtons(inventoryModel),
      ],
    );
  }

  Widget _buildProgressIndicator(InventoryModel inventoryModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행률',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${inventoryModel.currentIndex + 1} / ${inventoryModel.totalItems}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: inventoryModel.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentItem(InventoryModel inventoryModel, currentEntry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // 1. 바코드 (최우선) - 애플 스타일 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 상품명 (바코드 위에 작게 표시)
                if (currentEntry.productName.isNotEmpty) ...[
                  Text(
                    currentEntry.productName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: currentEntry.barcode == '11111111' ? Colors.red : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                Text(
                  currentEntry.barcode.isNotEmpty
                      ? currentEntry.barcode
                      : '바코드 없음',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // 바코드 표시 영역 - 무조건 보여줌
                Container(
                  width: 280,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _buildBarcodeWidget(currentEntry.barcode),
                ),
                const SizedBox(height: 8),

              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. 수량 상태 표시 (있는 경우)
          if (currentEntry.quantity != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759), // iOS 시스템 그린
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '입력된 수량: ${currentEntry.quantity}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

        ],
      ),
    );
  }

  Widget _buildQuantityInput(InventoryModel inventoryModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: QuantityInput(
        onQuantitySelected: (quantity) {
          inventoryModel.setQuantityForCurrent(quantity);
        },
      ),
    );
  }

  Widget _buildNavigationButtons(InventoryModel inventoryModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 이전 버튼 - 애플 스타일 secondary
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: inventoryModel.currentIndex > 0
                    ? Colors.white
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: inventoryModel.currentIndex > 0 ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: TextButton(
                onPressed: inventoryModel.currentIndex > 0
                    ? () => inventoryModel.goToPrevious()
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '이전',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: inventoryModel.currentIndex > 0
                        ? Colors.black
                        : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 건너뛰기 버튼
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => inventoryModel.setQuantityForCurrent(0),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '건너뛰기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 다음/완료 버튼 - 애플 스타일 primary
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: inventoryModel.currentEntry?.quantity != null
                    ? const Color(0xFF007AFF) // iOS 시스템 블루
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: inventoryModel.currentEntry?.quantity != null ? [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: TextButton(
                onPressed: inventoryModel.currentEntry?.quantity != null
                    ? () {
                        if (inventoryModel.isFinished) {
                          _navigateToSummary();
                        }
                      }
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  inventoryModel.isFinished ? '완료' : '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: inventoryModel.currentEntry?.quantity != null
                        ? Colors.white
                        : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityConfirmation(int quantity) {
    // 간단한 피드백 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('수량 $quantity 입력됨'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SummaryScreen(),
      ),
    );
  }


  void _openBarcodeScanner(InventoryModel inventoryModel) async {
    try {
      final result = await Navigator.of(context).push<BarcodeScanResult>(
        MaterialPageRoute(
          builder: (context) => BarcodeScannerScreen(
            products: inventoryModel.entries,
            onBarcodeScanned: (result) {
              Navigator.of(context).pop(result);
            },
          ),
        ),
      );

      if (result != null && result.hasMatch && result.productIndex != null) {
        // 매칭된 상품으로 이동
        inventoryModel.goToIndex(result.productIndex!);

        // 성공 피드백
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.matchedProduct!.productName} 상품으로 이동했습니다',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('바코드 스캔 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('입력 중단'),
        content: const Text('현재까지 입력한 데이터가 저장되지 않을 수 있습니다.\\n정말 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 화면 나가기
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  // 바코드 타입을 결정하는 헬퍼 메서드
  Barcode _getBarcodeType(String data) {
    // 숫자만 포함된 데이터의 길이에 따라 바코드 타입 결정
    if (RegExp(r'^\d+$').hasMatch(data)) {
      if (data.length == 13) {
        return Barcode.ean13();
      } else if (data.length == 8) {
        return Barcode.ean8();
      } else if (data.length == 12) {
        return Barcode.upcA();
      }
    }
    // 기본값은 Code128 (가장 범용적)
    return Barcode.code128();
  }

  // 바코드 위젯을 빌드하는 헬퍼 메서드
  Widget _buildBarcodeWidget(String barcodeData) {
    // 바코드 데이터가 없거나 비어있을 때 기본 바코드 생성
    String displayData = barcodeData.isNotEmpty ? barcodeData : '1234567890128';

    try {
      return BarcodeWidget(
        barcode: _getBarcodeType(displayData),
        data: displayData,
        width: 248,
        height: 88,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => _buildFallbackBarcode(displayData),
      );
    } catch (e) {
      // 바코드 생성 실패 시에도 기본 바코드 표시
      return _buildFallbackBarcode(displayData);
    }
  }

  // 대체 바코드 위젯 (Code128로 강제 생성)
  Widget _buildFallbackBarcode(String data) {
    try {
      return BarcodeWidget(
        barcode: Barcode.code128(),
        data: data.isNotEmpty ? data : '1234567890',
        width: 248,
        height: 88,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => _buildPlaceholderBarcode(),
      );
    } catch (e) {
      return _buildPlaceholderBarcode();
    }
  }

  // 최종 대체 바코드 (가장 간단한 형태)
  Widget _buildPlaceholderBarcode() {
    try {
      return BarcodeWidget(
        barcode: Barcode.code128(),
        data: 'NO BARCODE',
        width: 248,
        height: 88,
        drawText: false,
        color: Colors.black,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code,
              size: 48,
              color: Colors.black54,
            ),
            SizedBox(height: 8),
            Text(
              '바코드 표시 불가',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // 모든 바코드 생성이 실패할 경우 아이콘만 표시
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code,
            size: 48,
            color: Colors.black54,
          ),
          SizedBox(height: 8),
          Text(
            '바코드 표시 불가',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  // 상품명에서 차수 추출하는 헬퍼 메서드
  String _extractStageFromProductName(String productName) {
    // ##### 1차 ##### 또는 ##### 2차 ##### 형태에서 차수 추출
    final RegExp regExp = RegExp(r'#+\s*(\d+차)\s*#+');
    final match = regExp.firstMatch(productName);

    if (match != null && match.group(1) != null) {
      return match.group(1)!; // "1차", "2차" 등 반환
    }

    // 다른 패턴도 체크 (예: "1차", "2차"가 단독으로 있는 경우)
    final RegExp simpleRegExp = RegExp(r'(\d+차)');
    final simpleMatch = simpleRegExp.firstMatch(productName);

    if (simpleMatch != null && simpleMatch.group(1) != null) {
      return simpleMatch.group(1)!;
    }

    return "1차"; // 기본값
  }

  // 특수 바코드 11111111 다이얼로그
  void _showSpecialBarcodeDialog(BuildContext context, InventoryModel inventoryModel) {
    final currentEntry = inventoryModel.currentEntry;
    final stage = currentEntry != null ? _extractStageFromProductName(currentEntry.productName) : "1차";

    showDialog(
      context: context,
      barrierDismissible: false, // 백그라운드 터치로 닫기 방지
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.blue, size: 28),
            SizedBox(width: 8),
            Text('재고 확인'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$stage 진열대 조사가 완료되었습니다.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '이제 창고 재고와 비교하여 재고 현황을 확인해 주세요.\n\n재고 확인 후 계속 진행하시겠습니까?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 다음 상품으로 이동
              if (!inventoryModel.isFinished) {
                inventoryModel.setQuantityForCurrent(0); // 수량 0으로 설정하고 다음으로 이동
                _lastCheckedBarcode = null; // 다음 체크를 위해 리셋
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

}