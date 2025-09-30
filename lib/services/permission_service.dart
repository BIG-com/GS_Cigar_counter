import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// 카메라 권한 요청
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('카메라 권한 요청 실패: $e');
      return false;
    }
  }

  /// 카메라 권한 상태 확인
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      print('카메라 권한 상태 확인 실패: $e');
      return false;
    }
  }

  /// 저장소 권한 요청
  static Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      print('저장소 권한 요청 실패: $e');
      return false;
    }
  }

  /// 앱 설정으로 이동
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('앱 설정 열기 실패: $e');
    }
  }

  /// 모든 필요한 권한 요청
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};

    // 카메라 권한
    results['camera'] = await requestCameraPermission();

    // 저장소 권한 (Android 12 이하에서만 필요)
    results['storage'] = await requestStoragePermission();

    return results;
  }

  /// 파일 접근 권한 확인 및 요청 (Android 13+)
  static Future<bool> requestFilePermission() async {
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Android 13+ 에서는 특정 파일 타입 권한 사용
      final photoStatus = await Permission.photos.request();
      return photoStatus.isGranted;
    } catch (e) {
      print('파일 권한 요청 실패: $e');
      return false;
    }
  }
}