import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// barcode_widget temporarily removed due to dependency issues
import '../models/inventory_model.dart';
import '../services/share_service.dart';
import 'upload_screen.dart';
import 'entry_screen.dart';
import 'statistics_screen.dart';
import 'mode_selection_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final ScrollController _scrollController = ScrollController(); // 스크롤 위치 저장용 컨트롤러

  @override
  void initState() {
    super.initState();
    // 스크롤 변경 감지를 위한 리스너 추가
    _scrollController.addListener(_onScrollChanged);
    // 화면이 생성된 후 스크롤 위치 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  void _onScrollChanged() {
    // 스크롤이 변경될 때마다 위치 저장 (디바운싱 없이 즉시 저장)
    if (_scrollController.hasClients) {
      final inventoryModel = context.read<InventoryModel>();
      inventoryModel.saveSummaryScrollPosition(_scrollController.offset);
    }
  }

  @override
  void dispose() {
    // 현재 스크롤 위치 저장
    _saveScrollPosition();
    _scrollController.dispose();
    super.dispose();
  }

  void _restoreScrollPosition() {
    final inventoryModel = context.read<InventoryModel>();
    final savedPosition = inventoryModel.summaryScrollPosition;

    if (_scrollController.hasClients && savedPosition > 0) {
      _scrollController.animateTo(
        savedPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      final inventoryModel = context.read<InventoryModel>();
      inventoryModel.saveSummaryScrollPosition(_scrollController.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재고 조사 결과'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final inventoryModel = context.read<InventoryModel>();
            final inputMode = inventoryModel.inputMode ?? InputMode.normal;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EntryScreen(inputMode: inputMode),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StatisticsScreen()),
            ),
            tooltip: '통계 보기',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showDeveloperInfo(context),
            tooltip: '제작자 정보',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showRestartDialog(context),
            tooltip: '새로 시작',
          ),
        ],
      ),
      body: Consumer<InventoryModel>(
        builder: (context, inventoryModel, child) {
          final recordedEntries = inventoryModel.recordedEntries;

          return Column(
            children: [
              // 간단한 헤더 정보만 표시
              _buildSimpleHeader(context, inventoryModel),

              // 상품 목록 (메인 컨텐츠)
              Expanded(
                child: _buildEntriesList(context, recordedEntries, inventoryModel),
              ),

              // 액션 버튼 섹션
              _buildActionButtons(context, inventoryModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context, InventoryModel inventoryModel) {
    final recordedItems = inventoryModel.recordedItems;

    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0), // 상하 마진 줄임
      child: Card(
        elevation: 1, // 그림자 줄임
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 패딩 줄임
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Theme.of(context).primaryColor,
                size: 20, // 아이콘 크기 줄임
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '입력된 상품 $recordedItems개',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                ),
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text('통계', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 기존 통계 섹션은 제거되고 Statistics 페이지로 이동
  Widget _buildOldStatisticsSection(BuildContext context, InventoryModel inventoryModel) {
    final totalItems = inventoryModel.totalItems;
    final recordedItems = inventoryModel.recordedItems;
    final completionRate = totalItems > 0 ? (recordedItems / totalItems * 100) : 0.0;
    final totalQuantity = inventoryModel.recordedEntries
        .map((e) => e.quantity ?? 0)
        .fold(0, (sum, qty) => sum + qty);

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '조사 통계',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '총 상품',
                      totalItems.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '입력 완료',
                      recordedItems.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '완료율',
                      '${completionRate.toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '총 수량',
                      totalQuantity.toString(),
                      Icons.analytics,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    BuildContext context,
    List recordedEntries,
    InventoryModel inventoryModel,
  ) {
    if (recordedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '입력된 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final inventoryModel = context.read<InventoryModel>();
                final inputMode = inventoryModel.inputMode ?? InputMode.normal;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => EntryScreen(inputMode: inputMode),
                  ),
                );
              },
              child: const Text('입력하러 가기'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0), // 상단 마진 제거
      child: Card(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 패딩 줄임
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: Theme.of(context).primaryColor,
                    size: 18, // 아이콘 크기 줄임
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '상품 목록',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${recordedEntries.length}개',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                key: const PageStorageKey('product_list'), // 스크롤 위치 자동 저장을 위한 키
                controller: _scrollController, // 스크롤 컨트롤러 추가
                padding: EdgeInsets.zero, // ListView 내부 패딩 제거
                itemCount: recordedEntries.length,
                itemBuilder: (context, index) {
                  final entry = recordedEntries[index];
                  return _buildEntryListItem(context, entry, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryListItem(BuildContext context, entry, int index) {
    return Consumer<InventoryModel>(
      builder: (context, inventoryModel, child) {
        final isSelected = inventoryModel.isSummaryItemSelected(index);

        return InkWell(
          onTap: () {
            inventoryModel.toggleSummaryItemSelection(index);
            // UI 업데이트를 위해 setState 호출
            setState(() {});
          },
          child: Container(
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                radius: 16, // 크기 줄임
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                    : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12, // 폰트 크기 줄임
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                entry.productName.isNotEmpty ? entry.productName : '상품명 없음',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '바코드: ${entry.barcode.isNotEmpty ? entry.barcode : '없음'}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  if (entry.recordedAt != null)
                    Text(
                      '입력시간: ${entry.recordedAt!.toLocal().toString().substring(0, 19)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.7)
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // padding 증가
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                      : _getQuantityColor(entry.quantity ?? 0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20), // 더 둥글게
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                        : _getQuantityColor(entry.quantity ?? 0).withValues(alpha: 0.3),
                    width: 2, // 테두리 굵게
                  ),
                ),
                child: Text(
                  '${entry.quantity ?? 0}',
                  style: TextStyle(
                    fontSize: 20, // 폰트 크기 증가 (기본 14 → 20)
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : _getQuantityColor(entry.quantity ?? 0),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getQuantityColor(int quantity) {
    if (quantity == 0) return Colors.grey;
    if (quantity <= 3) return Colors.orange;
    if (quantity <= 6) return Colors.blue;
    return Colors.green;
  }

  Widget _buildActionButtons(BuildContext context, InventoryModel inventoryModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 공유 버튼들
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: inventoryModel.recordedEntries.isNotEmpty
                      ? () => _shareAsExcel(context, inventoryModel)
                      : null,
                  icon: const Icon(Icons.share),
                  label: const Text('Excel 공유'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: inventoryModel.recordedEntries.isNotEmpty
                      ? () => _shareAsSummary(context, inventoryModel)
                      : null,
                  icon: const Icon(Icons.summarize),
                  label: const Text('요약 공유'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Firebase 저장 및 새로 시작 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: inventoryModel.recordedEntries.isNotEmpty
                      ? () => _saveToLocalStorage(context, inventoryModel)
                      : null,
                  icon: const Icon(Icons.save),
                  label: const Text('로컬 저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRestartDialog(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로 시작'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareAsExcel(BuildContext context, InventoryModel inventoryModel) async {
    try {
      _showLoadingDialog(context, 'Excel 파일 생성 중...');

      await ShareService.shareInventoryData(inventoryModel.recordedEntries);

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      _showErrorDialog(context, 'Excel 공유 실패: ${e.toString()}');
    }
  }

  Future<void> _shareAsSummary(BuildContext context, InventoryModel inventoryModel) async {
    try {
      await ShareService.shareSummary(inventoryModel.recordedEntries);
    } catch (e) {
      _showErrorDialog(context, '요약 공유 실패: ${e.toString()}');
    }
  }

  Future<void> _saveToLocalStorage(BuildContext context, InventoryModel inventoryModel) async {
    try {
      _showLoadingDialog(context, '로컬 저장소에 저장 중...');

      await inventoryModel.saveToLocalStorage();

      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로컬 저장소에 성공적으로 저장되었습니다!\n(Firebase는 추후 업데이트 예정)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showErrorDialog(context, '로컬 저장 실패:\n${e.toString()}');
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새로 시작'),
        content: const Text('현재 데이터를 모두 지우고 새로 시작하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final inventoryModel = context.read<InventoryModel>();
              inventoryModel.clear();
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const UploadScreen()),
                (route) => false,
              );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 8),
            Text('제작자 정보'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '개발자: 김준호',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('kjh961112@naver.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text('카카오톡 ID: kjh961112'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // _getBarcodeType method removed - was used for barcode_widget which is temporarily disabled
}