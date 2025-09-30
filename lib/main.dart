import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/inventory_model.dart';
import 'screens/upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('시카 앱 시작: 로컬 저장소 모드');
  print('FilePicker 초기화 준비 완료');

  runApp(const SikaApp());
}

class SikaApp extends StatelessWidget {
  const SikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventoryModel(),
      child: MaterialApp(
        title: '시카',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // cardTheme temporarily removed due to compatibility issues
        ),
        home: const UploadScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
