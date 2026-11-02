# Daily Quest · 데일리퀘스트

매일 반복할 퀘스트를 관리하고, 달성 기록을 확인하는 오프라인 모바일 어플리케이션

# 모바일 다운로드 및 설치

**Android 7.0 이상**에서 사용할 수 있습니다. iPhone에서는 APK를 설치할 수 없습니다.

1. 스마트폰의 Chrome 또는 삼성 인터넷에서 **[최신 릴리스](https://github.com/EpicFn/DailyQuest/releases/latest)**를 엽니다.
2. 릴리스 하단의 **Assets**를 펼치고 **`app-release.apk`**를 누릅니다. `Source code` 파일은 설치 파일이 아닙니다.
3. 다운로드가 끝나면 알림 또는 **내 파일 → 다운로드**에서 APK를 엽니다.
4. 설치 권한을 요청하면 **설정 → 이 출처 허용 / 이 소스에서 가져온 앱 설치 허용**을 켠 뒤 돌아와 **설치**를 누릅니다. 메뉴 이름은 기기에 따라 다를 수 있습니다.
5. 설치가 끝나면 **데일리퀘스트**를 실행합니다. 설치에 사용한 브라우저나 파일 앱의 출처 허용은 다시 꺼도 됩니다.

업데이트 전에는 앱에서 기록을 백업한 뒤, **기존 앱을 삭제하지 않고** 새 APK를 설치하세요. 서명이 다르다는 오류가 나면 삭제부터 하지 말고 백업 여부와 설치 파일을 먼저 확인하세요.

[Android 외부 앱 설치 안내](https://support.google.com/pixelphone/answer/7391672?hl=ko)

# 사용 방법

### 1. **퀘스트 관리**

<img width="388" height="822" alt="image" src="https://github.com/user-attachments/assets/3fa3e59e-0a5f-4615-8930-acad371b76e0" />

- 카테고리를 선택하고 퀘스트를 추가
- 진행 중·전체·카테고리별 목록
- 퀘스트 수정·삭제·활성화 상태 변경 가능

### 2. **오늘의 도전**

<img width="388" height="822" alt="image" src="https://github.com/user-attachments/assets/0afe9cb5-76ef-4e6a-be17-da34001216fd" />

- 완수한 퀘스트를 완료 체크
- 오늘의 달성률을 확인

### 3. **도전 기록**

<img width="388" height="822" alt="image" src="https://github.com/user-attachments/assets/33ad667d-8beb-4a27-a463-b772d94a2d9f" />

- 날짜별 달성률을 확인
- 날짜를 눌러 해당 일의 기록을 확인

### 4. **백업 및 복원** 

<img width="370" height="238" alt="image" src="https://github.com/user-attachments/assets/653bd7aa-7fff-4f95-930a-e945a3d68e29" />

- 기록을 파일로 저장하거나 복원
- 복원하면 현재 기록는 백업 내용으로 교체

# 시연

https://github.com/user-attachments/assets/f19dc54c-11f0-4b9a-91bb-fbecfd4910f2


# 기술 스택


- **앱:** Flutter · Dart · Material 3
- **데이터 저장:** SQLite (`sqflite`)
- **달력·날짜:** `table_calendar` · `intl`
- **파일 백업·복원:** JSON · `file_picker`
- **테스트:** `flutter_test` · `sqflite_common_ffi`
