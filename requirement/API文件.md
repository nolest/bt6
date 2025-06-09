# API文件
# 智能寶寶生活記錄應用

**文件版本**：1.0.0  
**更新日期**：2025年5月31日  
**作者**：開發設計團隊

## 目錄

1. [概述](#1-概述)
   1. [文件目的](#11-文件目的)
   2. [API架構](#12-api架構)
   3. [認證與安全](#13-認證與安全)
   4. [錯誤處理](#14-錯誤處理)

2. [iCloud API整合](#2-icloud-api整合)
   1. [CloudKit框架概述](#21-cloudkit框架概述)
   2. [用戶認證](#22-用戶認證)
   3. [數據同步API](#23-數據同步api)
   4. [文件存儲API](#24-文件存儲api)
   5. [錯誤處理](#25-錯誤處理)

3. [Dropbox API整合](#3-dropbox-api整合)
   1. [Dropbox SDK概述](#31-dropbox-sdk概述)
   2. [用戶認證](#32-用戶認證)
   3. [文件上傳API](#33-文件上傳api)
   4. [文件下載API](#34-文件下載api)
   5. [備份與恢復API](#35-備份與恢復api)
   6. [錯誤處理](#36-錯誤處理)

4. [Deepseek GAI API整合](#4-deepseek-gai-api整合)
   1. [API概述](#41-api概述)
   2. [API密鑰管理](#42-api密鑰管理)
   3. [照片分析API](#43-照片分析api)
   4. [發展評估API](#44-發展評估api)
   5. [作息規律分析API](#45-作息規律分析api)
   6. [個性化建議API](#46-個性化建議api)
   7. [請求限制與緩存策略](#47-請求限制與緩存策略)
   8. [錯誤處理](#48-錯誤處理)

5. [Facebook API整合](#5-facebook-api整合)
   1. [Facebook SDK概述](#51-facebook-sdk概述)
   2. [用戶認證](#52-用戶認證)
   3. [社群分享API](#53-社群分享api)
   4. [動態獲取API](#54-動態獲取api)
   5. [互動API](#55-互動api)
   6. [隱私設置](#56-隱私設置)
   7. [錯誤處理](#57-錯誤處理)

6. [本地API接口](#6-本地api接口)
   1. [數據模型接口](#61-數據模型接口)
   2. [業務邏輯接口](#62-業務邏輯接口)
   3. [UI組件接口](#63-ui組件接口)

## 1. 概述

### 1.1 文件目的

本API文件旨在詳細說明智能寶寶生活記錄應用與外部服務（iCloud、Dropbox、Deepseek GAI、Facebook）的整合接口，以及應用內部模塊間的API接口。文檔面向開發團隊，提供完整的API使用指南，包括接口定義、參數說明、認證方式、使用場景和錯誤處理等。

### 1.2 API架構

智能寶寶生活記錄應用採用純客戶端架構，所有功能和操作都在iOS應用內實現，僅通過API與外部服務進行必要的數據交換。API架構分為以下幾個部分：

1. **雲端存儲API**：與iCloud和Dropbox整合，實現數據同步和備份功能
2. **人工智能API**：與Deepseek GAI服務整合，實現照片分析、發展評估、作息規律分析等功能
3. **社群API**：與Facebook整合，實現社群分享和互動功能
4. **本地API**：應用內部模塊間的接口，實現數據訪問、業務邏輯和UI交互

### 1.3 認證與安全

各API的認證與安全策略：

1. **iCloud API**：使用Apple ID認證，通過CloudKit框架自動處理
2. **Dropbox API**：使用OAuth 2.0認證，需用戶授權
3. **Deepseek GAI API**：使用API密鑰認證，採用多密鑰策略和客戶端安全存儲
4. **Facebook API**：使用OAuth 2.0認證，需用戶授權

所有API調用均採用HTTPS加密傳輸，敏感數據在本地加密存儲，API密鑰使用安全存儲機制保護。

### 1.4 錯誤處理

API錯誤處理遵循以下原則：

1. 所有API調用都應包含錯誤處理機制
2. 網絡錯誤應提供重試機制
3. 認證錯誤應引導用戶重新授權
4. API限制錯誤應實施退避策略
5. 用戶友好的錯誤提示，隱藏技術細節
6. 錯誤日誌記錄用於後續分析

## 2. iCloud API整合

### 2.1 CloudKit框架概述

智能寶寶生活記錄應用使用Apple的CloudKit框架與iCloud服務整合，實現數據同步和備份功能。CloudKit提供了公共數據庫和私有數據庫，應用主要使用私有數據庫存儲用戶數據。

**主要功能**：
- 用戶數據同步
- 照片和影片備份
- 設置同步
- 多設備數據共享

### 2.2 用戶認證

**接口名稱**：`checkiCloudAccountStatus`

**描述**：檢查用戶iCloud賬戶狀態，確認是否已登入並啟用iCloud Drive

**請求**：
```swift
func checkiCloudAccountStatus() -> (isAvailable: Bool, error: Error?)
```

**響應**：
- `isAvailable`：布爾值，表示iCloud是否可用
- `error`：錯誤信息，如果有

**使用場景**：
- 應用啟動時
- 進入設置頁面時
- 嘗試同步數據前

**錯誤處理**：
- 未登入iCloud賬戶：提示用戶登入
- iCloud Drive未啟用：提示用戶啟用
- 權限不足：請求必要權限

### 2.3 數據同步API

#### 2.3.1 保存記錄

**接口名稱**：`saveRecordToCloud`

**描述**：將寶寶記錄保存到iCloud

**請求**：
```swift
func saveRecordToCloud(record: BabyRecord) -> (success: Bool, recordID: String?, error: Error?)
```

**參數**：
- `record`：寶寶記錄對象，包含記錄類型、時間、詳情等

**響應**：
- `success`：布爾值，表示保存是否成功
- `recordID`：字符串，成功保存後的記錄ID
- `error`：錯誤信息，如果有

**使用場景**：
- 創建新記錄時
- 編輯現有記錄時

**錯誤處理**：
- 網絡錯誤：本地保存，稍後重試
- 配額超限：提示用戶清理iCloud存儲
- 衝突：實施合併策略

#### 2.3.2 獲取記錄

**接口名稱**：`fetchRecordsFromCloud`

**描述**：從iCloud獲取寶寶記錄

**請求**：
```swift
func fetchRecordsFromCloud(babyID: String, startDate: Date?, endDate: Date?, recordType: RecordType?, limit: Int?) -> (records: [BabyRecord]?, error: Error?)
```

**參數**：
- `babyID`：寶寶ID
- `startDate`：開始日期（可選）
- `endDate`：結束日期（可選）
- `recordType`：記錄類型（可選）
- `limit`：返回記錄數量限制（可選）

**響應**：
- `records`：寶寶記錄數組
- `error`：錯誤信息，如果有

**使用場景**：
- 應用啟動時
- 切換寶寶時
- 下拉刷新時
- 查看歷史記錄時

**錯誤處理**：
- 網絡錯誤：顯示本地數據，提示同步失敗
- 權限錯誤：提示用戶檢查權限
- 數據不存在：顯示空狀態

#### 2.3.3 刪除記錄

**接口名稱**：`deleteRecordFromCloud`

**描述**：從iCloud刪除寶寶記錄

**請求**：
```swift
func deleteRecordFromCloud(recordID: String) -> (success: Bool, error: Error?)
```

**參數**：
- `recordID`：要刪除的記錄ID

**響應**：
- `success`：布爾值，表示刪除是否成功
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶刪除記錄時

**錯誤處理**：
- 網絡錯誤：本地標記刪除，稍後重試
- 記錄不存在：視為刪除成功
- 權限錯誤：提示用戶檢查權限

### 2.4 文件存儲API

#### 2.4.1 上傳照片/影片

**接口名稱**：`uploadMediaToCloud`

**描述**：將照片或影片上傳到iCloud

**請求**：
```swift
func uploadMediaToCloud(mediaData: Data, metadata: MediaMetadata) -> (success: Bool, fileURL: URL?, error: Error?)
```

**參數**：
- `mediaData`：媒體文件數據
- `metadata`：媒體元數據，包含類型、時間、關聯記錄等

**響應**：
- `success`：布爾值，表示上傳是否成功
- `fileURL`：URL，成功上傳後的文件URL
- `error`：錯誤信息，如果有

**使用場景**：
- 拍攝新照片/影片時
- 從相冊選擇照片/影片時

**錯誤處理**：
- 網絡錯誤：本地保存，稍後重試
- 存儲空間不足：提示用戶清理iCloud存儲
- 文件過大：提示壓縮或分段上傳

#### 2.4.2 下載照片/影片

**接口名稱**：`downloadMediaFromCloud`

**描述**：從iCloud下載照片或影片

**請求**：
```swift
func downloadMediaFromCloud(fileURL: URL) -> (success: Bool, mediaData: Data?, error: Error?)
```

**參數**：
- `fileURL`：要下載的文件URL

**響應**：
- `success`：布爾值，表示下載是否成功
- `mediaData`：媒體文件數據
- `error`：錯誤信息，如果有

**使用場景**：
- 查看照片/影片詳情時
- 離線使用前預下載

**錯誤處理**：
- 網絡錯誤：提示重試
- 文件不存在：提示文件可能已刪除
- 下載中斷：支持斷點續傳

### 2.5 錯誤處理

iCloud API可能返回的常見錯誤及處理方式：

| 錯誤代碼 | 錯誤描述 | 處理方式 |
|---------|---------|---------|
| CKError.notAuthenticated | 用戶未登入iCloud | 提示用戶登入iCloud賬戶 |
| CKError.quotaExceeded | iCloud存儲空間不足 | 提示用戶清理iCloud存儲 |
| CKError.networkFailure | 網絡連接失敗 | 本地保存數據，稍後自動重試 |
| CKError.networkUnavailable | 網絡不可用 | 切換到離線模式，恢復連接後同步 |
| CKError.serverResponseLost | 服務器響應丟失 | 實施指數退避重試策略 |
| CKError.assetFileNotFound | 媒體文件不存在 | 提示用戶文件可能已刪除 |
| CKError.permissionFailure | 權限不足 | 提示用戶檢查iCloud權限設置 |

## 3. Dropbox API整合

### 3.1 Dropbox SDK概述

智能寶寶生活記錄應用使用Dropbox SDK與Dropbox服務整合，作為iCloud的替代或補充選項，實現數據備份和恢復功能。

**主要功能**：
- 完整數據備份
- 數據恢復
- 照片和影片備份
- 數據導出

### 3.2 用戶認證

**接口名稱**：`authenticateDropbox`

**描述**：進行Dropbox OAuth認證

**請求**：
```swift
func authenticateDropbox(fromViewController: UIViewController) -> (success: Bool, error: Error?)
```

**參數**：
- `fromViewController`：發起認證的視圖控制器

**響應**：
- `success`：布爾值，表示認證是否成功
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶首次連接Dropbox時
- 認證過期需重新認證時

**錯誤處理**：
- 用戶取消認證：不做處理，視為正常流程
- 認證失敗：提示重試或選擇其他備份方式
- 網絡錯誤：提示檢查網絡連接

**接口名稱**：`checkDropboxAuthStatus`

**描述**：檢查Dropbox認證狀態

**請求**：
```swift
func checkDropboxAuthStatus() -> (isAuthenticated: Bool, username: String?)
```

**響應**：
- `isAuthenticated`：布爾值，表示是否已認證
- `username`：字符串，已認證的用戶名

**使用場景**：
- 應用啟動時
- 進入設置頁面時
- 嘗試備份/恢復前

### 3.3 文件上傳API

**接口名稱**：`uploadFileToDropbox`

**描述**：將文件上傳到Dropbox

**請求**：
```swift
func uploadFileToDropbox(fileData: Data, path: String, overwrite: Bool) -> (success: Bool, metadata: DropboxFileMetadata?, error: Error?)
```

**參數**：
- `fileData`：文件數據
- `path`：Dropbox中的目標路徑
- `overwrite`：是否覆蓋現有文件

**響應**：
- `success`：布爾值，表示上傳是否成功
- `metadata`：上傳文件的元數據
- `error`：錯誤信息，如果有

**使用場景**：
- 創建備份時
- 上傳照片/影片時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 存儲空間不足：提示用戶清理Dropbox空間
- 路徑不存在：自動創建路徑
- 文件已存在且不覆蓋：生成唯一文件名

### 3.4 文件下載API

**接口名稱**：`downloadFileFromDropbox`

**描述**：從Dropbox下載文件

**請求**：
```swift
func downloadFileFromDropbox(path: String) -> (success: Bool, fileData: Data?, error: Error?)
```

**參數**：
- `path`：Dropbox中的文件路徑

**響應**：
- `success`：布爾值，表示下載是否成功
- `fileData`：文件數據
- `error`：錯誤信息，如果有

**使用場景**：
- 恢復備份時
- 查看備份文件時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 文件不存在：提示用戶檢查路徑
- 下載中斷：支持斷點續傳

### 3.5 備份與恢復API

**接口名稱**：`createBackupToDropbox`

**描述**：創建應用數據完整備份到Dropbox

**請求**：
```swift
func createBackupToDropbox(includeMedia: Bool) -> (success: Bool, backupPath: String?, error: Error?)
```

**參數**：
- `includeMedia`：是否包含媒體文件

**響應**：
- `success`：布爾值，表示備份是否成功
- `backupPath`：備份文件在Dropbox中的路徑
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶手動創建備份時
- 定期自動備份時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 存儲空間不足：提示用戶清理Dropbox空間
- 備份過程中斷：支持斷點續傳

**接口名稱**：`restoreBackupFromDropbox`

**描述**：從Dropbox恢復備份

**請求**：
```swift
func restoreBackupFromDropbox(backupPath: String, overwriteExisting: Bool) -> (success: Bool, error: Error?)
```

**參數**：
- `backupPath`：備份文件在Dropbox中的路徑
- `overwriteExisting`：是否覆蓋現有數據

**響應**：
- `success`：布爾值，表示恢復是否成功
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶手動恢復備份時
- 設備更換後數據遷移時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 備份文件損壞：提示用戶選擇其他備份
- 恢復過程中斷：支持斷點續傳
- 版本不兼容：提供版本兼容性處理

### 3.6 錯誤處理

Dropbox API可能返回的常見錯誤及處理方式：

| 錯誤代碼 | 錯誤描述 | 處理方式 |
|---------|---------|---------|
| AuthError | 認證錯誤 | 引導用戶重新認證 |
| RateLimitError | 請求頻率超限 | 實施指數退避重試策略 |
| NetworkError | 網絡連接失敗 | 提供重試選項，檢查網絡連接 |
| PathError | 路徑不存在 | 自動創建路徑或提示用戶檢查路徑 |
| InsufficientSpaceError | 存儲空間不足 | 提示用戶清理Dropbox空間 |
| AccessError | 訪問權限不足 | 提示用戶檢查Dropbox權限設置 |
| FileConflictError | 文件衝突 | 生成唯一文件名或提示用戶選擇操作 |

## 4. Deepseek GAI API整合

### 4.1 API概述

智能寶寶生活記錄應用與Deepseek GAI服務整合，實現照片分析、發展評估、作息規律分析和個性化建議等AI功能。所有AI分析功能均為可選，用戶可自行決定是否啟用雲端分析。

**主要功能**：
- 照片情緒分析
- 發展里程碑識別
- 睡眠模式深度分析
- 作息規律高級識別
- 個性化育兒建議生成

### 4.2 API密鑰管理

為防止API密鑰濫用和盜用，應用採用以下安全策略：

1. **多密鑰策略**：應用內嵌入3-5個API密鑰
2. **設備分配**：根據設備ID的哈希值將用戶分配到不同的密鑰
3. **代碼混淆**：使用代碼混淆技術保護密鑰
4. **分段存儲**：密鑰分段存儲，運行時動態組合
5. **定期更新**：通過應用更新機制定期更新API密鑰

**接口名稱**：`getDeepseekAPIKey`

**描述**：獲取當前設備使用的Deepseek API密鑰

**請求**：
```swift
func getDeepseekAPIKey() -> String
```

**響應**：
- 返回當前設備使用的API密鑰

**使用場景**：
- 發起GAI分析請求前

### 4.3 照片分析API

**接口名稱**：`analyzePhoto`

**描述**：分析寶寶照片，識別情緒、發展里程碑等

**請求**：
```swift
func analyzePhoto(photoData: Data, analysisTypes: [AnalysisType]) -> (success: Bool, results: [String: Any]?, error: Error?)
```

**參數**：
- `photoData`：照片數據（JPEG/PNG格式）
- `analysisTypes`：分析類型數組，可包含：
  - `emotion`：情緒分析
  - `milestone`：里程碑識別
  - `development`：發展評估

**HTTP請求示例**：
```
POST https://api.deepseek.com/v1/baby/analyze
Content-Type: multipart/form-data
Authorization: Bearer {api_key}

{
  "image": [binary data],
  "analysis_types": ["emotion", "milestone", "development"],
  "baby_age_months": 12,
  "device_id": "anonymized-device-id"
}
```

**響應**：
- `success`：布爾值，表示分析是否成功
- `results`：分析結果，包含各分析類型的結果
- `error`：錯誤信息，如果有

**HTTP響應示例**：
```json
{
  "success": true,
  "results": {
    "emotion": {
      "primary_emotion": "happy",
      "confidence": 0.92,
      "secondary_emotions": [
        {"emotion": "curious", "confidence": 0.45},
        {"emotion": "excited", "confidence": 0.38}
      ]
    },
    "milestone": {
      "milestones_detected": [
        {"milestone": "social_smile", "confidence": 0.87},
        {"milestone": "eye_tracking", "confidence": 0.76}
      ],
      "age_appropriate": true
    },
    "development": {
      "areas": [
        {"area": "social", "score": 85, "percentile": 75},
        {"area": "motor", "score": 90, "percentile": 82},
        {"area": "cognitive", "score": 88, "percentile": 78}
      ],
      "overall_assessment": "developing_well",
      "suggested_activities": [
        "interactive_play",
        "outdoor_exploration"
      ]
    }
  }
}
```

**使用場景**：
- 用戶上傳新照片時
- 用戶請求分析現有照片時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- API限制錯誤：提示用戶稍後再試
- 分析失敗：提供替代分析選項或本地分析
- 照片不適合分析：提示用戶上傳清晰的寶寶照片

### 4.4 發展評估API

**接口名稱**：`assessDevelopment`

**描述**：基於記錄數據評估寶寶發展情況

**請求**：
```swift
func assessDevelopment(babyID: String, ageMonths: Int, developmentData: [String: Any]) -> (success: Bool, assessment: DevelopmentAssessment?, error: Error?)
```

**參數**：
- `babyID`：寶寶ID（匿名化）
- `ageMonths`：寶寶月齡
- `developmentData`：發展數據，包含各領域的觀察記錄

**HTTP請求示例**：
```
POST https://api.deepseek.com/v1/baby/development
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "baby_id": "anonymized-id",
  "age_months": 12,
  "development_data": {
    "motor": {
      "can_walk_with_support": true,
      "can_stand_alone": false,
      "can_pick_up_small_objects": true
    },
    "language": {
      "babbles": true,
      "says_mama_dada": true,
      "understands_simple_commands": true
    },
    "social": {
      "plays_interactive_games": true,
      "responds_to_name": true,
      "shows_stranger_anxiety": true
    },
    "cognitive": {
      "explores_objects": true,
      "finds_hidden_objects": true,
      "imitates_actions": true
    }
  },
  "device_id": "anonymized-device-id"
}
```

**響應**：
- `success`：布爾值，表示評估是否成功
- `assessment`：發展評估結果
- `error`：錯誤信息，如果有

**HTTP響應示例**：
```json
{
  "success": true,
  "assessment": {
    "overall_status": "on_track",
    "areas": [
      {
        "area": "motor",
        "status": "on_track",
        "percentile": 65,
        "next_milestones": ["walking_alone", "climbing_stairs"]
      },
      {
        "area": "language",
        "status": "advanced",
        "percentile": 85,
        "next_milestones": ["first_words", "two_word_phrases"]
      },
      {
        "area": "social",
        "status": "on_track",
        "percentile": 70,
        "next_milestones": ["cooperative_play", "follows_two_step_instructions"]
      },
      {
        "area": "cognitive",
        "status": "on_track",
        "percentile": 75,
        "next_milestones": ["sorting_shapes", "problem_solving"]
      }
    ],
    "recommendations": [
      {
        "area": "motor",
        "activities": ["push_toys", "climbing_games"]
      },
      {
        "area": "language",
        "activities": ["reading_together", "naming_objects"]
      }
    ]
  }
}
```

**使用場景**：
- 定期發展評估時
- 用戶請求發展分析時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 數據不足：提示用戶添加更多觀察記錄
- API限制錯誤：提示用戶稍後再試

### 4.5 作息規律分析API

**接口名稱**：`analyzeRoutinePatterns`

**描述**：分析寶寶的作息規律，提供優化建議

**請求**：
```swift
func analyzeRoutinePatterns(babyID: String, routineData: [RoutineRecord], timeSpan: TimeSpan) -> (success: Bool, patterns: RoutinePatterns?, error: Error?)
```

**參數**：
- `babyID`：寶寶ID（匿名化）
- `routineData`：作息記錄數據，包含睡眠、餵食等記錄
- `timeSpan`：分析時間跨度（天/週/月）

**HTTP請求示例**：
```
POST https://api.deepseek.com/v1/baby/routine
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "baby_id": "anonymized-id",
  "time_span": "week",
  "routine_data": {
    "sleep": [
      {"date": "2025-05-24", "start_time": "20:30", "end_time": "06:45", "quality": "good"},
      {"date": "2025-05-25", "start_time": "20:45", "end_time": "06:30", "quality": "fair"},
      // 更多睡眠記錄...
    ],
    "feeding": [
      {"date": "2025-05-24", "time": "07:30", "type": "breast", "duration": 15},
      {"date": "2025-05-24", "time": "11:45", "type": "bottle", "amount": 120},
      // 更多餵食記錄...
    ],
    "diaper": [
      {"date": "2025-05-24", "time": "08:15", "type": "wet"},
      {"date": "2025-05-24", "time": "12:30", "type": "dirty"},
      // 更多尿布記錄...
    ]
  },
  "device_id": "anonymized-device-id"
}
```

**響應**：
- `success`：布爾值，表示分析是否成功
- `patterns`：識別出的作息規律
- `error`：錯誤信息，如果有

**HTTP響應示例**：
```json
{
  "success": true,
  "patterns": {
    "sleep": {
      "average_night_duration": 10.2,
      "average_bedtime": "20:38",
      "average_wake_time": "06:40",
      "consistency_score": 85,
      "nap_pattern": "two_naps",
      "sleep_quality_trend": "improving"
    },
    "feeding": {
      "average_frequency": 6.5,
      "average_interval": 3.2,
      "consistency_score": 78,
      "feeding_pattern": "regular"
    },
    "overall_routine": {
      "regularity_score": 82,
      "predictability": "high",
      "identified_schedule": [
        {"activity": "wake_up", "typical_time": "06:40", "consistency": 90},
        {"activity": "morning_feeding", "typical_time": "07:15", "consistency": 85},
        {"activity": "morning_nap", "typical_time": "09:30", "consistency": 75},
        // 更多日程項目...
      ]
    },
    "recommendations": [
      {
        "type": "sleep",
        "suggestion": "Consider moving bedtime 15 minutes earlier for better night sleep quality",
        "confidence": 0.85
      },
      {
        "type": "feeding",
        "suggestion": "Feeding pattern is well established, maintain current schedule",
        "confidence": 0.92
      }
    ],
    "predictions": [
      {"activity": "next_feeding", "predicted_time": "15:30", "confidence": 0.88},
      {"activity": "next_nap", "predicted_time": "13:15", "confidence": 0.82},
      {"activity": "bedtime", "predicted_time": "20:30", "confidence": 0.90}
    ]
  }
}
```

**使用場景**：
- 週/月作息分析時
- 智能排程功能使用時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 數據不足：提示用戶添加更多記錄
- API限制錯誤：提示用戶稍後再試

### 4.6 個性化建議API

**接口名稱**：`generatePersonalizedSuggestions`

**描述**：基於寶寶數據生成個性化育兒建議

**請求**：
```swift
func generatePersonalizedSuggestions(babyID: String, babyData: BabyData, suggestionTypes: [SuggestionType]) -> (success: Bool, suggestions: [Suggestion]?, error: Error?)
```

**參數**：
- `babyID`：寶寶ID（匿名化）
- `babyData`：寶寶數據，包含年齡、發展情況、喜好等
- `suggestionTypes`：建議類型數組，可包含：
  - `activities`：活動建議
  - `development`：發展促進建議
  - `nutrition`：營養建議
  - `sleep`：睡眠建議

**HTTP請求示例**：
```
POST https://api.deepseek.com/v1/baby/suggestions
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "baby_id": "anonymized-id",
  "baby_data": {
    "age_months": 12,
    "development_status": {
      "motor": "on_track",
      "language": "advanced",
      "social": "on_track",
      "cognitive": "on_track"
    },
    "preferences": {
      "favorite_activities": ["music", "outdoor"],
      "food_preferences": ["fruits", "yogurt"],
      "sleep_habits": ["needs_dark_room", "light_sleeper"]
    },
    "recent_milestones": ["first_steps", "waves_goodbye"]
  },
  "suggestion_types": ["activities", "development", "sleep"],
  "device_id": "anonymized-device-id"
}
```

**響應**：
- `success`：布爾值，表示生成是否成功
- `suggestions`：個性化建議數組
- `error`：錯誤信息，如果有

**HTTP響應示例**：
```json
{
  "success": true,
  "suggestions": [
    {
      "type": "activities",
      "title": "Music and Movement",
      "description": "Since your baby enjoys music, try incorporating simple dance movements to help develop gross motor skills while playing favorite songs.",
      "benefits": ["motor_development", "sensory_stimulation", "joy"],
      "implementation_tips": [
        "Use simple instruments like shakers or drums",
        "Demonstrate movements for baby to imitate",
        "Keep sessions short (5-10 minutes) and fun"
      ]
    },
    {
      "type": "development",
      "title": "Language Expansion",
      "description": "Your baby is showing advanced language skills. Expand vocabulary by naming objects and actions throughout the day.",
      "benefits": ["vocabulary_growth", "communication_skills"],
      "implementation_tips": [
        "Read books with varied vocabulary",
        "Narrate daily activities in detail",
        "Respond to babbling as if having a conversation"
      ]
    },
    {
      "type": "sleep",
      "title": "Consistent Bedtime Routine",
      "description": "For light sleepers, a very consistent bedtime routine can help improve sleep quality.",
      "benefits": ["better_sleep_quality", "easier_bedtime"],
      "implementation_tips": [
        "Keep the same 3-4 activities in the same order each night",
        "Ensure room is completely dark",
        "Consider white noise to mask household sounds"
      ]
    }
  ]
}
```

**使用場景**：
- 智慧助理頁面顯示建議時
- 用戶請求特定類型建議時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 數據不足：提示用戶添加更多記錄
- API限制錯誤：提示用戶稍後再試

### 4.7 請求限制與緩存策略

為防止API濫用和優化用戶體驗，應用實施以下限制和緩存策略：

1. **請求頻率限制**：
   - 照片分析：每小時最多10次，每天最多30次
   - 發展評估：每天最多5次
   - 作息分析：每天最多3次
   - 個性化建議：每天最多5次

2. **智能緩存**：
   - 相同照片的分析結果緩存7天
   - 發展評估結果緩存3天
   - 作息分析結果緩存1天
   - 個性化建議緩存2天

3. **離線功能**：
   - 緩存的分析結果在離線時可用
   - 基本的本地分析功能在離線時可用

**接口名稱**：`checkAPIQuota`

**描述**：檢查API使用配額

**請求**：
```swift
func checkAPIQuota(analysisType: AnalysisType) -> (remainingQuota: Int, resetTime: Date?)
```

**參數**：
- `analysisType`：分析類型

**響應**：
- `remainingQuota`：剩餘配額
- `resetTime`：配額重置時間

**使用場景**：
- 發起GAI分析請求前
- 顯示剩餘分析次數時

### 4.8 錯誤處理

Deepseek GAI API可能返回的常見錯誤及處理方式：

| 錯誤代碼 | 錯誤描述 | 處理方式 |
|---------|---------|---------|
| 401 | 未授權/API密鑰無效 | 嘗試使用備用API密鑰 |
| 403 | 禁止訪問 | 檢查API密鑰權限 |
| 429 | 請求過多 | 實施指數退避重試策略，顯示剩餘配額和重置時間 |
| 500 | 服務器錯誤 | 提供重試選項，報告錯誤 |
| 503 | 服務不可用 | 切換到本地分析模式，稍後重試 |
| 400 | 請求參數錯誤 | 檢查請求參數，調整後重試 |
| 413 | 請求實體過大 | 壓縮照片後重試 |

## 5. Facebook API整合

### 5.1 Facebook SDK概述

智能寶寶生活記錄應用使用Facebook SDK與Facebook平台整合，實現社群分享和互動功能。用戶可以選擇性地連接Facebook賬戶，分享寶寶成長里程碑和照片，並與其他父母互動。

**主要功能**：
- Facebook賬戶連接
- 分享寶寶照片和里程碑
- 獲取社群動態
- 互動（讚、評論、分享）

### 5.2 用戶認證

**接口名稱**：`loginWithFacebook`

**描述**：使用Facebook賬戶登入

**請求**：
```swift
func loginWithFacebook(fromViewController: UIViewController, permissions: [String]) -> (success: Bool, userID: String?, error: Error?)
```

**參數**：
- `fromViewController`：發起登入的視圖控制器
- `permissions`：請求的權限數組，如 ["public_profile", "email", "user_posts"]

**響應**：
- `success`：布爾值，表示登入是否成功
- `userID`：Facebook用戶ID
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶首次登入時
- 用戶連接Facebook賬戶時

**錯誤處理**：
- 用戶取消登入：不做處理，視為正常流程
- 登入失敗：提示重試或選擇其他登入方式
- 權限被拒絕：提示用戶必要權限的重要性

**接口名稱**：`checkFacebookLoginStatus`

**描述**：檢查Facebook登入狀態

**請求**：
```swift
func checkFacebookLoginStatus() -> (isLoggedIn: Bool, userID: String?, permissions: [String]?)
```

**響應**：
- `isLoggedIn`：布爾值，表示是否已登入
- `userID`：Facebook用戶ID
- `permissions`：已授權的權限數組

**使用場景**：
- 應用啟動時
- 進入社群頁面時
- 嘗試分享內容前

### 5.3 社群分享API

**接口名稱**：`shareToFacebook`

**描述**：分享內容到Facebook

**請求**：
```swift
func shareToFacebook(content: FacebookShareContent, fromViewController: UIViewController) -> (success: Bool, postID: String?, error: Error?)
```

**參數**：
- `content`：分享內容，可包含文字、照片、鏈接等
- `fromViewController`：發起分享的視圖控制器

**響應**：
- `success`：布爾值，表示分享是否成功
- `postID`：發布的帖子ID
- `error`：錯誤信息，如果有

**使用場景**：
- 分享寶寶照片時
- 分享里程碑時
- 分享統計數據時

**錯誤處理**：
- 用戶取消分享：不做處理，視為正常流程
- 分享失敗：提示重試
- 權限不足：提示用戶授予必要權限

### 5.4 動態獲取API

**接口名稱**：`fetchCommunityFeed`

**描述**：獲取社群動態

**請求**：
```swift
func fetchCommunityFeed(limit: Int, offset: Int) -> (success: Bool, posts: [FacebookPost]?, error: Error?)
```

**參數**：
- `limit`：返回帖子數量限制
- `offset`：分頁偏移量

**響應**：
- `success`：布爾值，表示獲取是否成功
- `posts`：帖子數組
- `error`：錯誤信息，如果有

**使用場景**：
- 進入社群頁面時
- 下拉刷新時
- 加載更多內容時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 權限不足：提示用戶授予必要權限
- 無內容：顯示空狀態

### 5.5 互動API

**接口名稱**：`likePost`

**描述**：對帖子點讚

**請求**：
```swift
func likePost(postID: String) -> (success: Bool, error: Error?)
```

**參數**：
- `postID`：帖子ID

**響應**：
- `success`：布爾值，表示點讚是否成功
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶點讚帖子時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 權限不足：提示用戶授予必要權限
- 已點讚：切換為取消讚

**接口名稱**：`commentOnPost`

**描述**：對帖子發表評論

**請求**：
```swift
func commentOnPost(postID: String, message: String) -> (success: Bool, commentID: String?, error: Error?)
```

**參數**：
- `postID`：帖子ID
- `message`：評論內容

**響應**：
- `success`：布爾值，表示評論是否成功
- `commentID`：評論ID
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶評論帖子時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 權限不足：提示用戶授予必要權限
- 內容被拒絕：提示用戶修改評論內容

### 5.6 隱私設置

**接口名稱**：`updatePrivacySettings`

**描述**：更新Facebook分享隱私設置

**請求**：
```swift
func updatePrivacySettings(settings: FacebookPrivacySettings) -> (success: Bool, error: Error?)
```

**參數**：
- `settings`：隱私設置，包含默認分享範圍等

**響應**：
- `success`：布爾值，表示更新是否成功
- `error`：錯誤信息，如果有

**使用場景**：
- 用戶修改隱私設置時

**錯誤處理**：
- 網絡錯誤：提供重試選項
- 設置被拒絕：提示用戶嘗試其他設置

### 5.7 錯誤處理

Facebook API可能返回的常見錯誤及處理方式：

| 錯誤代碼 | 錯誤描述 | 處理方式 |
|---------|---------|---------|
| 2 | 暫時性錯誤 | 稍後自動重試 |
| 4 | 應用請求限制 | 實施指數退避重試策略 |
| 102 | 會話已過期 | 引導用戶重新登入 |
| 190 | 訪問令牌無效 | 引導用戶重新授權 |
| 200 | 權限錯誤 | 提示用戶授予必要權限 |
| 10 | 應用配置錯誤 | 檢查應用設置，報告錯誤 |
| 368 | 內容被拒絕 | 提示用戶修改內容 |

## 6. 本地API接口

### 6.1 數據模型接口

#### 6.1.1 寶寶記錄接口

**接口名稱**：`BabyRecordManager`

**描述**：管理寶寶記錄的CRUD操作

**主要方法**：
```swift
// 創建記錄
func createRecord(record: BabyRecord) -> (success: Bool, recordID: String?, error: Error?)

// 獲取記錄
func getRecord(recordID: String) -> (record: BabyRecord?, error: Error?)

// 獲取記錄列表
func getRecords(babyID: String, startDate: Date?, endDate: Date?, recordType: RecordType?, limit: Int?, offset: Int?) -> (records: [BabyRecord]?, error: Error?)

// 更新記錄
func updateRecord(recordID: String, updatedRecord: BabyRecord) -> (success: Bool, error: Error?)

// 刪除記錄
func deleteRecord(recordID: String) -> (success: Bool, error: Error?)
```

**使用場景**：
- 添加/編輯/刪除記錄時
- 查看記錄列表時
- 生成統計數據時

#### 6.1.2 寶寶管理接口

**接口名稱**：`BabyManager`

**描述**：管理寶寶資料的CRUD操作

**主要方法**：
```swift
// 添加寶寶
func addBaby(baby: Baby) -> (success: Bool, babyID: String?, error: Error?)

// 獲取寶寶資料
func getBaby(babyID: String) -> (baby: Baby?, error: Error?)

// 獲取所有寶寶
func getAllBabies() -> (babies: [Baby]?, error: Error?)

// 更新寶寶資料
func updateBaby(babyID: String, updatedBaby: Baby) -> (success: Bool, error: Error?)

// 刪除寶寶
func deleteBaby(babyID: String) -> (success: Bool, error: Error?)

// 設置當前選中寶寶
func setCurrentBaby(babyID: String) -> (success: Bool, error: Error?)

// 獲取當前選中寶寶
func getCurrentBaby() -> (baby: Baby?, error: Error?)
```

**使用場景**：
- 添加/編輯/刪除寶寶資料時
- 切換當前寶寶時
- 顯示寶寶列表時

#### 6.1.3 媒體管理接口

**接口名稱**：`MediaManager`

**描述**：管理照片和影片的CRUD操作

**主要方法**：
```swift
// 保存媒體
func saveMedia(media: Media) -> (success: Bool, mediaID: String?, error: Error?)

// 獲取媒體
func getMedia(mediaID: String) -> (media: Media?, error: Error?)

// 獲取媒體列表
func getMediaList(babyID: String, startDate: Date?, endDate: Date?, mediaType: MediaType?, tags: [String]?, limit: Int?, offset: Int?) -> (mediaList: [Media]?, error: Error?)

// 更新媒體
func updateMedia(mediaID: String, updatedMedia: Media) -> (success: Bool, error: Error?)

// 刪除媒體
func deleteMedia(mediaID: String) -> (success: Bool, error: Error?)

// 添加標籤
func addTag(mediaID: String, tag: String) -> (success: Bool, error: Error?)

// 移除標籤
func removeTag(mediaID: String, tag: String) -> (success: Bool, error: Error?)
```

**使用場景**：
- 保存/編輯/刪除照片和影片時
- 查看媒體庫時
- 添加/移除標籤時

### 6.2 業務邏輯接口

#### 6.2.1 統計分析接口

**接口名稱**：`StatisticsAnalyzer`

**描述**：生成和分析統計數據

**主要方法**：
```swift
// 生成餵食統計
func generateFeedingStatistics(babyID: String, startDate: Date, endDate: Date) -> (statistics: FeedingStatistics?, error: Error?)

// 生成睡眠統計
func generateSleepStatistics(babyID: String, startDate: Date, endDate: Date) -> (statistics: SleepStatistics?, error: Error?)

// 生成尿布統計
func generateDiaperStatistics(babyID: String, startDate: Date, endDate: Date) -> (statistics: DiaperStatistics?, error: Error?)

// 生成成長統計
func generateGrowthStatistics(babyID: String, startDate: Date, endDate: Date) -> (statistics: GrowthStatistics?, error: Error?)

// 生成綜合統計
func generateOverallStatistics(babyID: String, startDate: Date, endDate: Date) -> (statistics: OverallStatistics?, error: Error?)
```

**使用場景**：
- 查看統計頁面時
- 生成報告時
- 分析趨勢時

#### 6.2.2 智能助理接口

**接口名稱**：`SmartAssistant`

**描述**：提供智能助理功能

**主要方法**：
```swift
// 生成智能排程
func generateSmartSchedule(babyID: String, date: Date) -> (schedule: SmartSchedule?, error: Error?)

// 獲取育兒建議
func getParentingAdvice(babyID: String, topic: String?) -> (advice: [ParentingAdvice]?, error: Error?)

// 分析睡眠模式
func analyzeSleepPattern(babyID: String, timeSpan: TimeSpan) -> (analysis: SleepAnalysis?, error: Error?)

// 分析作息規律
func analyzeRoutinePattern(babyID: String, timeSpan: TimeSpan) -> (analysis: RoutineAnalysis?, error: Error?)

// 獲取今日建議
func getTodaySuggestions(babyID: String) -> (suggestions: [Suggestion]?, error: Error?)
```

**使用場景**：
- 查看智能助理頁面時
- 請求特定建議時
- 查看睡眠/作息分析時

#### 6.2.3 家庭成員管理接口

**接口名稱**：`FamilyMemberManager`

**描述**：管理家庭成員和權限

**主要方法**：
```swift
// 添加家庭成員
func addFamilyMember(member: FamilyMember) -> (success: Bool, memberID: String?, error: Error?)

// 獲取家庭成員
func getFamilyMember(memberID: String) -> (member: FamilyMember?, error: Error?)

// 獲取所有家庭成員
func getAllFamilyMembers() -> (members: [FamilyMember]?, error: Error?)

// 更新家庭成員
func updateFamilyMember(memberID: String, updatedMember: FamilyMember) -> (success: Bool, error: Error?)

// 刪除家庭成員
func deleteFamilyMember(memberID: String) -> (success: Bool, error: Error?)

// 生成邀請碼
func generateInvitationCode() -> (code: String?, expiryDate: Date?, error: Error?)

// 驗證邀請碼
func validateInvitationCode(code: String) -> (isValid: Bool, familyID: String?, error: Error?)

// 設置權限
func setPermissions(memberID: String, permissions: [Permission]) -> (success: Bool, error: Error?)

// 檢查權限
func checkPermission(memberID: String, permission: Permission) -> (hasPermission: Bool, error: Error?)
```

**使用場景**：
- 管理家庭成員時
- 設置權限時
- 邀請新成員時

### 6.3 UI組件接口

#### 6.3.1 記錄表單接口

**接口名稱**：`RecordFormController`

**描述**：管理記錄表單的顯示和提交

**主要方法**：
```swift
// 初始化表單
func initForm(recordType: RecordType, existingRecord: BabyRecord? = nil) -> (form: RecordForm?, error: Error?)

// 驗證表單
func validateForm(form: RecordForm) -> (isValid: Bool, errors: [String]?)

// 提交表單
func submitForm(form: RecordForm) -> (success: Bool, record: BabyRecord?, error: Error?)

// 取消表單
func cancelForm() -> Void
```

**使用場景**：
- 添加新記錄時
- 編輯現有記錄時

#### 6.3.2 圖表組件接口

**接口名稱**：`ChartController`

**描述**：管理統計圖表的顯示

**主要方法**：
```swift
// 生成折線圖
func generateLineChart(data: [ChartDataPoint], options: ChartOptions) -> (chart: LineChart?, error: Error?)

// 生成柱狀圖
func generateBarChart(data: [ChartDataPoint], options: ChartOptions) -> (chart: BarChart?, error: Error?)

// 生成餅圖
func generatePieChart(data: [ChartDataPoint], options: ChartOptions) -> (chart: PieChart?, error: Error?)

// 更新圖表數據
func updateChartData(chart: Chart, newData: [ChartDataPoint]) -> (success: Bool, error: Error?)
```

**使用場景**：
- 顯示統計數據時
- 更新圖表數據時

#### 6.3.3 照片瀏覽器接口

**接口名稱**：`PhotoBrowserController`

**描述**：管理照片瀏覽和編輯

**主要方法**：
```swift
// 初始化瀏覽器
func initBrowser(mediaList: [Media], initialIndex: Int) -> (browser: PhotoBrowser?, error: Error?)

// 顯示照片詳情
func showPhotoDetails(mediaID: String) -> (details: MediaDetails?, error: Error?)

// 編輯照片
func editPhoto(mediaID: String, editOptions: EditOptions) -> (success: Bool, updatedMedia: Media?, error: Error?)

// 分享照片
func sharePhoto(mediaID: String, shareOptions: ShareOptions) -> (success: Bool, error: Error?)
```

**使用場景**：
- 瀏覽照片時
- 查看照片詳情時
- 編輯照片時
- 分享照片時
