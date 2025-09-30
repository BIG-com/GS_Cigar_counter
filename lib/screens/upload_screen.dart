import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inventory_model.dart';
import 'entry_screen.dart';

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
                builder: (context) => const EntryScreen(),
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

}