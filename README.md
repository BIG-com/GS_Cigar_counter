# Cigar Counter - 바코드 재고 조사 앱

Flutter로 개발된 바코드 스캔 기반 재고 조사 앱입니다.

## 주요 기능

- 📊 **Excel 파일 업로드**: 상품명과 바코드가 포함된 Excel 파일 업로드
- 📷 **바코드 스캔**: 실시간 카메라로 바코드 스캔하여 상품 찾기
- 🔢 **수량 입력**: 직관적인 숫자 패드로 재고 수량 입력
- 📈 **진행률 표시**: 실시간 작업 진행률 및 통계
- 💾 **데이터 공유**: Excel, 텍스트 형태로 결과 공유
- ☁️ **Firebase 연동**: 클라우드 데이터 저장 (선택사항)

## 안드로이드 스튜디오 실행 가이드

### 1. 시스템 요구사항
- Android Studio Arctic Fox 이상
- Flutter SDK 3.0.0 이상
- Java 11 이상
- Android SDK API 21 이상

### 2. 프로젝트 설정
```bash
# 의존성 설치
flutter pub get

# Android 빌드 확인
flutter doctor

# 안드로이드 에뮬레이터 또는 실제 기기 연결 확인
flutter devices
```

### 3. 실행
```bash
# 디버그 모드 실행
flutter run

# 릴리즈 모드 실행
flutter run --release
```

### 4. 문제 해결

#### 카메라 권한 문제
- Android: `android/app/src/main/AndroidManifest.xml`에 카메라 권한 추가됨
- iOS: `ios/Runner/Info.plist`에 카메라 사용 설명 추가됨

#### Firebase 관련 오류
Firebase 설정이 없어도 앱이 정상 실행됩니다. Firebase 기능은 선택사항입니다.

Firebase를 사용하려면:
1. Firebase 콘솔에서 프로젝트 생성
2. `google-services.json` (Android) 파일 추가
3. `GoogleService-Info.plist` (iOS) 파일 추가

#### 빌드 오류 해결
```bash
# 클린 빌드
flutter clean
flutter pub get

# Android 빌드 확인
cd android
./gradlew clean
./gradlew build

# 캐시 삭제
flutter pub cache repair
```

#### 일반적인 오류 해결

**권한 오류 (Permission Denied)**
- 카메라 권한이 자동으로 요청됩니다
- 거부 시 앱 설정에서 수동으로 권한 허용

**Gradle 빌드 오류**
- JDK 11 사용 확인
- Android SDK 34 설치 확인
- Gradle 캐시 삭제: `cd android && ./gradlew --stop`

**카메라 초기화 실패**
- 에뮬레이터가 아닌 실제 기기 사용 권장
- 카메라 하드웨어가 있는 기기 사용

## 사용법

1. **Excel 파일 준비**: 첫 번째 컬럼에 상품명, 두 번째 컬럼에 바코드 포함
2. **파일 업로드**: 앱에서 Excel 파일 선택
3. **바코드 스캔**: 카메라로 바코드 스캔하여 해당 상품으로 이동
4. **수량 입력**: 숫자 패드로 재고 수량 입력
5. **결과 확인**: 요약 화면에서 통계 확인 및 데이터 공유

## 기술 스택

- **Frontend**: Flutter (Dart)
- **상태 관리**: Provider
- **카메라**: mobile_scanner
- **바코드**: barcode_widget
- **파일 처리**: file_picker, excel
- **데이터 공유**: share_plus
- **클라우드**: Firebase (선택사항)

## 폴더 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── inventory_model.dart  # 재고 상태 관리
│   └── product_entry.dart    # 상품 엔터티
├── screens/                  # 화면 UI
│   ├── upload_screen.dart    # 파일 업로드
│   ├── entry_screen.dart     # 수량 입력
│   ├── barcode_scanner_screen.dart  # 바코드 스캔
│   └── summary_screen.dart   # 결과 요약
├── services/                 # 비즈니스 로직
│   ├── excel_service.dart    # Excel 처리
│   ├── barcode_service.dart  # 바코드 처리
│   ├── firebase_service.dart # Firebase 연동
│   └── share_service.dart    # 데이터 공유
└── widgets/                  # 재사용 컴포넌트
    └── quantity_input.dart   # 수량 입력 위젯
```

## 라이선스

MIT License# GS_Cigar_counter
