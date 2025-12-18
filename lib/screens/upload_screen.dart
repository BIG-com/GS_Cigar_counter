import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inventory_model.dart';
import 'mode_selection_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재고 조사'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showUserGuide,
            tooltip: '사용법 가이드',
          ),
        ],
      ),
      body: Consumer<InventoryModel>(
        builder: (context, inventoryModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더 섹션
                _buildHeaderSection(),
                const SizedBox(height: 32),

                // 파일 업로드 섹션
                _buildUploadSection(inventoryModel),
                const SizedBox(height: 24),

                // 도움말 섹션
                _buildHelpSection(),

                // 에러 메시지
                if (inventoryModel.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorSection(inventoryModel.errorMessage!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Cigar Counter',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Excel 파일을 업로드하여\n재고 조사를 시작하세요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(InventoryModel inventoryModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Excel 파일 업로드',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Excel 파일을 선택하세요',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading || inventoryModel.isLoading
                  ? null
                  : () => _pickAndUploadFile(inventoryModel),
              icon: _isLoading || inventoryModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(
                _isLoading || inventoryModel.isLoading
                    ? '파일 처리 중...'
                    : 'Excel 파일 선택',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '파일 형식 안내',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpItem('📄', '지원 형식', '.xlsx 파일만 지원됩니다'),
            _buildHelpItem('📊', '필수 컬럼', '상품명, 바코드 컬럼이 필요합니다'),
            _buildHelpItem('🏷️', '헤더 인식', '첫 번째 행을 헤더로 인식합니다'),
            _buildHelpItem('📁', '파일 선택', '파일 선택 버튼으로 쉽게 업로드하세요'),
            _buildHelpItem('🔍', '자동 감지', '상품명/바코드 컬럼을 자동으로 찾습니다'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorSection(String errorMessage) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile(InventoryModel inventoryModel) async {
    try {
      setState(() => _isLoading = true);

      print('FilePicker 시작 - 안정적인 구현');

      // 2024년 최신 안정적인 FilePicker 구현
      FilePickerResult? result;

      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls'],
          allowMultiple: false,
        );
      } catch (e) {
        print('특정 형식 선택 실패, 일반 파일 선택으로 재시도: $e');
        // 확장자 제한이 실패하면 모든 파일 허용 후 수동 검증
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final String fileName = file.name.toLowerCase();

        print('선택된 파일: ${file.name}');
        print('파일 크기: ${file.size} 바이트');

        // 파일 확장자 수동 검증
        if (!fileName.endsWith('.xlsx') && !fileName.endsWith('.xls')) {
          _showErrorDialog('Excel 파일(.xlsx 또는 .xls)만 선택 가능합니다.');
          return;
        }

        // 파일 크기 검증 (10MB 제한)
        if (file.size > 10 * 1024 * 1024) {
          _showErrorDialog('파일이 너무 큽니다. 10MB 이하의 파일을 선택해주세요.');
          return;
        }

        Uint8List? bytes;

        // 플랫폼별 파일 읽기
        if (file.bytes != null) {
          // 웹 또는 바이트가 직접 제공되는 경우
          bytes = file.bytes!;
          print('바이트에서 파일 읽기 성공');
        } else if (file.path != null) {
          // 모바일/데스크톱에서 경로로 파일 읽기
          try {
            final File fileObj = File(file.path!);
            bytes = await fileObj.readAsBytes();
            print('경로에서 파일 읽기 성공: ${file.path}');
          } catch (e) {
            print('경로에서 파일 읽기 실패: $e');
            _showErrorDialog('파일을 읽을 수 없습니다. 다른 파일을 시도해주세요.');
            return;
          }
        } else {
          _showErrorDialog('파일 데이터에 접근할 수 없습니다.');
          return;
        }

        if (bytes != null && bytes.isNotEmpty) {
          print('Excel 파일 처리 시작: ${bytes.length} 바이트');

          // Excel 파일 로드
          await inventoryModel.loadFromExcelBytes(bytes);

          if (inventoryModel.entries.isNotEmpty && mounted) {
            print('Excel 로드 성공: ${inventoryModel.entries.length}개 항목');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ModeSelectionScreen(),
              ),
            );
          } else if (inventoryModel.errorMessage != null) {
            _showErrorDialog(inventoryModel.errorMessage!);
          } else {
            _showErrorDialog('Excel 파일에서 상품 데이터를 찾을 수 없습니다.');
          }
        } else {
          _showErrorDialog('파일이 비어있습니다.');
        }
      } else {
        print('파일 선택이 취소되었습니다.');
      }
    } catch (e) {
      print('FilePicker 오류: $e');
      _showErrorDialog('파일 선택 중 오류가 발생했습니다.\n\n오류: ${e.toString()}\n\n다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _showErrorDialog(String message) {
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

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '사용법 가이드',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 내용
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 시작 안내
                      _buildGuideSection(
                        icon: Icons.play_circle_outline,
                        iconColor: Colors.green,
                        title: '📱 시작하기',
                        content: '재고 조사 앱은 엑셀 파일에 있는 상품들의 수량을 쉽게 입력할 수 있도록 도와줍니다.',
                      ),

                      const Divider(height: 32),

                      // 1단계
                      _buildGuideStep(
                        stepNumber: 1,
                        stepColor: Colors.blue,
                        title: 'Excel 파일 준비',
                        items: [
                          '상품명과 바코드가 적힌 엑셀 파일(.xlsx)을 준비하세요',
                          '첫 번째 줄(1행)에는 "상품명"과 "바코드" 제목이 있어야 해요',
                          '파일 크기는 10MB 이하여야 합니다',
                          '',
                          '🏷️ 진열대 구분 (커스텀 모드용):',
                          '  • ##### 1차 ##### (진열대 구분 행)',
                          '  • ##### 2차 ##### (다음 진열대)',
                          '',
                          '⚠️ 무시할 섹션:',
                          '  • ##### 보류 ##### (보류 상품 무시)',
                          '  • ##### 단종 ##### (단종 상품 무시)',
                        ],
                        example: '예) A1: 상품명, B1: 바코드',
                      ),

                      const Divider(height: 32),

                      // 2단계
                      _buildGuideStep(
                        stepNumber: 2,
                        stepColor: Colors.orange,
                        title: '파일 업로드',
                        items: [
                          '메인 화면에서 "Excel 파일 선택" 버튼을 눌러주세요',
                          '준비한 엑셀 파일을 선택하세요',
                          '앱이 자동으로 상품 목록을 불러옵니다',
                          '진열대 구분과 보류/단종 섹션을 자동으로 인식합니다',
                        ],
                      ),

                      const Divider(height: 32),

                      // 3단계
                      _buildGuideStep(
                        stepNumber: 3,
                        stepColor: Colors.purple,
                        title: '입력 모드 선택',
                        items: [
                          '일반 모드: 1자리 숫자만 입력 (0~9)',
                          '  → 숫자를 누르면 바로 다음 상품으로 이동',
                          '보루 모드: 1~2자리 숫자 입력 (0~99)',
                          '  → 1자리: 확인 버튼을 눌러야 다음으로 이동',
                          '  → 2자리: 자동으로 다음 상품으로 이동',
                        ],
                      ),

                      const Divider(height: 32),

                      // 4단계 (새로 추가)
                      _buildGuideStep(
                        stepNumber: 4,
                        stepColor: Colors.indigo,
                        title: '진행 방식 선택',
                        items: [
                          '일반 진행: 엑셀 파일 순서대로 모든 상품 입력',
                          '  → 전체 상품을 한 번에 조사할 때 사용',
                          '',
                          '커스텀 진행: 진열대를 선택해서 입력',
                          '  → 진열대별로 나눠서 조사할 때 사용',
                          '  → 진열대 선택 화면에서 원하는 진열대 선택',
                          '  → 각 진열대의 첫 상품명과 진행률 확인 가능',
                          '  → 완료된 진열대는 "완료" 표시',
                        ],
                      ),

                      const Divider(height: 32),

                      // 5단계
                      _buildGuideStep(
                        stepNumber: 5,
                        stepColor: Colors.teal,
                        title: '수량 입력하기',
                        items: [
                          '바코드와 상품명을 확인하세요',
                          '화면 아래 숫자 버튼을 눌러 수량을 입력하세요',
                          '"QUANTITY" 부분에 입력한 숫자가 표시됩니다',
                          '잘못 입력했다면 "이전" 버튼(<)으로 돌아가세요',
                          '재고가 없다면 "다음" 버튼(>)으로 건너뛰세요',
                          '',
                          '💡 커스텀 모드에서:',
                          '  • 선택한 진열대의 상품만 입력',
                          '  • 진행률이 상단에 표시됩니다',
                        ],
                      ),

                      const Divider(height: 32),

                      // 6단계 (새로 추가)
                      _buildGuideStep(
                        stepNumber: 6,
                        stepColor: Colors.deepPurple,
                        title: '커스텀 모드: 진열대 완료',
                        items: [
                          '선택한 진열대의 모든 상품을 입력하면',
                          '완료 안내 화면이 나타납니다',
                          '',
                          '📋 다음 진열대 버튼:',
                          '  → 진열대 선택 화면으로 이동',
                          '  → 다른 진열대를 선택해서 계속 입력',
                          '',
                          '📊 조사 결과 보기 버튼:',
                          '  → 지금까지 입력한 내용 확인',
                          '  → 결과를 저장하거나 공유',
                        ],
                      ),

                      const Divider(height: 32),

                      // 7단계
                      _buildGuideStep(
                        stepNumber: 7,
                        stepColor: Colors.pink,
                        title: '결과 확인 및 저장',
                        items: [
                          '입력한 내용을 다시 확인할 수 있습니다',
                          '엑셀 파일로 저장하거나 공유할 수 있어요',
                          '',
                          '📌 일반 진행 모드:',
                          '  • 모든 상품 입력 완료 시 자동 이동',
                          '',
                          '📌 커스텀 진행 모드:',
                          '  • "조사 결과 보기" 선택 시 이동',
                          '  • 입력 완료 시간순으로 정렬되어 표시',
                          '  • 뒤로가기 시 진열대 선택 화면으로',
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 팁
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                Text(
                                  '💡 유용한 팁',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTipItem('바코드 스캔 기능을 사용하면 더 빠르게 찾을 수 있어요'),
                            _buildTipItem('상단 바코드 아이콘을 눌러보세요'),
                            _buildTipItem('목록 버튼을 누르면 전체 상품 목록을 볼 수 있어요'),
                            _buildTipItem('커스텀 모드에서는 진열대별로 나눠서 작업할 수 있어요'),
                            _buildTipItem('완료된 진열대는 초록색 "완료" 표시가 나타납니다'),
                            _buildTipItem('진열대 선택 화면에서 첫 상품명과 진행률을 확인하세요'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '이해했어요!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required int stepNumber,
    required Color stepColor,
    required String title,
    required List<String> items,
    String? example,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: stepColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        if (example != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 44),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              example,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓ ', style: TextStyle(fontSize: 14, color: Colors.amber)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

}