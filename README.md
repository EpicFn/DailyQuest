# Daily Quest · 데일리퀘스트

매일 반복할 퀘스트를 관리하고, 달성 기록을 확인하는 오프라인 모바일 어플리케이션

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
