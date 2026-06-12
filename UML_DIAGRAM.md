# SmartAid — UML Architecture Diagrams

This document contains the full set of UML and architecture diagrams for the SmartAid project.

---

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "Mobile App (Flutter)"
        UI["🖥️ Presentation Layer\nScreens · Widgets · Visualization"]
        BL["⚙️ Business Logic Layer\nServices · Providers · Analytics"]
        DATA["🗄️ Data Layer\nRepositories · Models"]
    end

    subgraph "Firebase Backend"
        AUTH["🔐 Firebase Auth\nEmail / Password"]
        FS["📦 Cloud Firestore\nUser · Medications · Appointments\nDose Logs · Health Records"]
    end

    subgraph "External APIs"
        GEMINI["🤖 Google Gemini AI\nHealth Narrative Generation"]
        OVERPASS["🗺️ Overpass API\nNearby POI (OpenStreetMap)"]
    end

    subgraph "On-Device"
        MLKIT["📷 ML Kit OCR\nPill Verification"]
        SENSOR["📡 Accelerometer\nFall Detection"]
        SQLITE["💾 SQLite (sqflite)\nOffline Queue"]
    end

    UI --> BL
    BL --> DATA
    DATA --> FS
    BL --> AUTH
    BL --> GEMINI
    BL --> OVERPASS
    BL --> MLKIT
    BL --> SENSOR
    BL --> SQLITE
```

---

## 2. Class Diagram — Data Models

```mermaid
classDiagram
    class UserModel {
        +String uid
        +String email
        +bool isDoctor
        +List~String~ emergencyContacts
        +bool shareDataResearch
        +DateTime createdAt
        +fromFirestore(doc) UserModel$
        +toMap() Map
    }

    class MedicationModel {
        +String id
        +String userId
        +String name
        +int dailyDoseLimit
        +List~String~ scheduledTimes
        +DateTime createdAt
        +fromFirestore(doc) MedicationModel$
        +toMap() Map
    }

    class DoseLogModel {
        +String medicationId
        +String medicationName
        +String userId
        +String date
        +int count
        +DateTime lastTaken
        +fromFirestore(doc) DoseLogModel$
        +toMap() Map
    }

    class AppointmentModel {
        +String id
        +String userId
        +String doctorName
        +String reason
        +DateTime dateTime
        +fromFirestore(doc) AppointmentModel$
        +toMap() Map
    }

    class HealthRecordModel {
        +String id
        +String userId
        +String fileName
        +String localPath
        +DateTime createdAt
        +fromFirestore(doc) HealthRecordModel$
        +toMap() Map
    }

    class NearbyPoiModel {
        +String id
        +String name
        +double lat
        +double lon
        +String amenityType
    }

    UserModel "1" --> "many" MedicationModel : owns
    UserModel "1" --> "many" AppointmentModel : has
    UserModel "1" --> "many" HealthRecordModel : stores
    MedicationModel "1" --> "many" DoseLogModel : generates
```

---

## 3. Class Diagram — Repository Layer

```mermaid
classDiagram
    class UserRepository {
        -FirebaseFirestore _db
        +getUserStream(uid) Stream~UserModel~
        +updateEmergencyContacts(uid, contacts) Future
        +updateConsent(uid, consent) Future
    }

    class MedicationRepository {
        -FirebaseFirestore _db
        +getMedicationsStream(uid) Stream~List~MedicationModel~~
        +addMedication(uid, med) Future
        +deleteMedication(uid, medId) Future
        +logDose(uid, medId, name, limit) Future
        +getDoseLogStream(uid, medId, date) Stream~DoseLogModel~
        +getAllDoseLogsStream(uid) Stream~List~DoseLogModel~~
        +getAdherenceHistory(uid, days) Future~Map~
    }

    class AppointmentRepository {
        -FirebaseFirestore _db
        +getAppointmentsStream(uid) Stream~List~AppointmentModel~~
        +addAppointment(uid, appt) Future
        +updateAppointment(uid, appt) Future
        +deleteAppointment(uid, apptId) Future
    }

    class HealthRecordRepository {
        -FirebaseFirestore _db
        +getHealthRecordsStream(uid) Stream~List~HealthRecordModel~~
        +saveRecordMetadata(uid, fileName, localPath) Future
        +deleteRecord(uid, record) Future
        +openLocalFile(path) Future~bool~
    }

    class DoctorDashboardRepository {
        -FirebaseFirestore _db
        +getCumulativeStatsStream() Stream~DoctorDashboardStats~
        +getConsentingPatientsStream() Stream~List~
    }

    class PlacesRepository {
        -http.Client _client
        +fetchNearbyPlaces(lat, lon, amenity) Future~List~PlaceModel~~
    }

    UserRepository --> UserModel
    MedicationRepository --> MedicationModel
    MedicationRepository --> DoseLogModel
    AppointmentRepository --> AppointmentModel
    HealthRecordRepository --> HealthRecordModel
    DoctorDashboardRepository --> DoctorDashboardStats
    PlacesRepository --> PlaceModel
```

---

## 4. Class Diagram — Service Layer

```mermaid
classDiagram
    class MedicationService {
        -MedicationRepository medicationRepository
        +getMedicationsStream(uid) Stream
        +addMedication(uid, data) Future
        +logIntake(userId, medicationId, name, limit) Future
        +getDoseLogStream(uid, medId, date) Stream
        +getAllDoseLogsStream(uid) Stream
        +todayKey() String
    }

    class AppointmentService {
        -AppointmentRepository appointmentRepository
        +getAppointmentsStream(uid) Stream
        +addAppointment(uid, data) Future
        +updateAppointment(uid, appt) Future
        +deleteAppointment(uid, id) Future
    }

    class HealthRecordService {
        -HealthRecordRepository healthRecordRepository
        +getHealthRecordsStream(uid) Stream
        +saveRecordMetadata(uid, fileName, localPath) Future
        +deleteRecord(uid, record) Future
        +openLocalFile(path) Future~bool~
    }

    class UserService {
        -UserRepository userRepository
        +getUserStream(uid) Stream~UserModel~
        +addEmergencyContact(uid, contact) Future
        +removeEmergencyContact(uid, contact) Future
        +updateConsent(uid, consent) Future
    }

    class FallDetectionService {
        -StreamSubscription _subscription
        -Timer _countdownTimer
        -bool _sosActive
        +List~String~ emergencyContacts
        +String emergencyNumber
        +Function onCountdown
        +Function onSosSent
        +startListening() void
        +stopListening() void
        +cancelSos() void
        -_triggerFallProtocol() void
        -_sendSos() Future
    }

    class PillVerificationService {
        -TextRecognizer _textRecognizer
        -ImagePicker _picker
        +scanAndVerify(expectedMedName) Future~PillScanResult~
        -_fuzzyContains(haystack, needle) bool
        +dispose() void
    }

    class PdfExportService {
        +generateAndSharePdf(report) Future
        -_buildPdfContent(report) pw.Document
    }

    class OfflineSyncService {
        -MedicationRepository medicationRepository
        -AppointmentRepository appointmentRepository
        -LocalDbService _localDb
        +bool isSyncing
        +int pendingCount
        +syncPending() Future
        -_listenToConnectivity() void
    }

    class LocalDbService {
        -Database _db
        +queueOperation(table, data) Future
        +getPendingOperations() Future~List~
        +markSynced(id) Future
        +initDb() Future
    }

    MedicationService --> MedicationRepository
    AppointmentService --> AppointmentRepository
    HealthRecordService --> HealthRecordRepository
    UserService --> UserRepository
    OfflineSyncService --> LocalDbService
    OfflineSyncService --> MedicationRepository
    OfflineSyncService --> AppointmentRepository
```

---

## 5. Class Diagram — Analytics & AI

```mermaid
classDiagram
    class AdherenceAnalyticsService {
        -MedicationRepository medicationRepository
        +getAdherenceRate(uid, days) Future~double~
        +getWeeklyBreakdown(uid) Future~Map~
    }

    class ResearchAnalyticsService {
        -DoctorDashboardRepository doctorDashboardRepository
        +getCumulativeStatsStream() Stream~DoctorDashboardStats~
        +getConsentingPatientsStream() Stream~List~
    }

    class ProductInsightsService {
        -MedicationRepository medicationRepository
        +generatePatientProfile(uid) Future~PatientAdherenceProfile~
        +generateCohortInsight(stats) CohortInsight
    }

    class PatientAdherenceProfile {
        +TodayStats todayStats
        +List~WeeklyPoint~ weeklyTimeline
        +int consecutivePerfectDays
        +DailyInsight dailyInsight
        +empty() PatientAdherenceProfile$
    }

    class TodayStats {
        +int totalExpectedDoses
        +int takenDoses
        +double adherencePercent
    }

    class DailyInsight {
        +String title
        +String message
        +InsightSentiment sentiment
    }

    class DoctorDashboardStats {
        +int totalPatients
        +double averageAdherence
        +Map medicationDistribution
    }

    class AiInsightService {
        -GenerativeModel _model
        -String apiKey
        +generateNarrative(uid, context) Future~String~
    }

    class ReportGenerationService {
        -MedicationService medicationService
        -AppointmentService appointmentService
        -ProductInsightsService insightsService
        +generatePatientReport(uid) Future~PatientReport~
    }

    ProductInsightsService --> PatientAdherenceProfile
    PatientAdherenceProfile --> TodayStats
    PatientAdherenceProfile --> DailyInsight
    ResearchAnalyticsService --> DoctorDashboardStats
    ReportGenerationService --> MedicationService
    ReportGenerationService --> AppointmentService
    ReportGenerationService --> ProductInsightsService
```

---

## 6. Sequence Diagram — User Login & Navigation

```mermaid
sequenceDiagram
    actor User
    participant AuthScreen
    participant FirebaseAuth
    participant GoRouter
    participant MainScreen

    User->>AuthScreen: Enter email + password
    AuthScreen->>FirebaseAuth: signInWithEmailAndPassword()
    FirebaseAuth-->>AuthScreen: UserCredential (success)
    FirebaseAuth-->>GoRouter: authStateChanges() emits user
    GoRouter->>GoRouter: redirect() — isLoggedIn=true, path='/' 
    GoRouter->>MainScreen: Navigate to MainScreen
    MainScreen-->>User: Home screen displayed
```

---

## 7. Sequence Diagram — Log a Medication Dose

```mermaid
sequenceDiagram
    actor Patient
    participant HomeScreen
    participant MedicationService
    participant MedicationRepository
    participant Firestore
    participant OfflineSyncService

    Patient->>HomeScreen: Tap medication card
    HomeScreen->>MedicationService: logIntake(userId, medicationId, name, limit)
    MedicationService->>MedicationRepository: logDose(...)

    alt Online
        MedicationRepository->>Firestore: Set dose_log document
        Firestore-->>MedicationRepository: success
        MedicationRepository-->>HomeScreen: Stream updates
        HomeScreen-->>Patient: Card shows "Taken ✓"
    else Offline
        MedicationService->>OfflineSyncService: queueOperation(logDose)
        OfflineSyncService->>LocalDbService: INSERT into pending_ops
        HomeScreen-->>Patient: Optimistic UI update
        Note over OfflineSyncService: Syncs when connectivity restored
    end
```

---

## 8. Sequence Diagram — Fall Detection & SOS

```mermaid
sequenceDiagram
    actor Patient
    participant EmergencyScreen
    participant FallDetectionService
    participant Accelerometer
    participant SMSDialer

    Patient->>EmergencyScreen: Toggle "Fall Monitoring" ON
    EmergencyScreen->>FallDetectionService: startListening()
    FallDetectionService->>Accelerometer: accelerometerEventStream().listen()

    loop Every sensor tick
        Accelerometer-->>FallDetectionService: AccelerometerEvent (x, y, z)
        FallDetectionService->>FallDetectionService: magnitude = sqrt(x²+y²+z²)
        alt magnitude > 25.0 m/s²
            FallDetectionService->>FallDetectionService: _triggerFallProtocol()
            FallDetectionService->>EmergencyScreen: onCountdown(10)
            loop 10-second countdown
                FallDetectionService->>EmergencyScreen: onCountdown(n--)
            end
            alt Patient taps "I'm OK"
                Patient->>EmergencyScreen: cancelEmergency()
                EmergencyScreen->>FallDetectionService: cancelSos()
            else Countdown reaches 0
                FallDetectionService->>SMSDialer: SMS to each emergency contact
                FallDetectionService->>SMSDialer: tel:108 (ambulance)
                FallDetectionService->>EmergencyScreen: onSosSent()
            end
        end
    end
```

---

## 9. Sequence Diagram — Pill Verification (OCR)

```mermaid
sequenceDiagram
    actor Patient
    participant AddMedicineScreen
    participant PillVerificationService
    participant Camera
    participant MLKit

    Patient->>AddMedicineScreen: Tap "Verify Pill" button
    AddMedicineScreen->>PillVerificationService: scanAndVerify(expectedMedName)
    PillVerificationService->>Camera: ImagePicker.pickImage(source: camera)
    Camera-->>PillVerificationService: XFile (image path)
    PillVerificationService->>MLKit: TextRecognizer.processImage(InputImage)
    MLKit-->>PillVerificationService: RecognizedText (blocks)
    PillVerificationService->>PillVerificationService: fuzzyMatch(scannedText, expectedName)
    PillVerificationService-->>AddMedicineScreen: PillScanResult(isMatch, scannedText)
    AddMedicineScreen-->>Patient: ✅ "Correct pill" OR ❌ "Mismatch detected"
```

---

## 10. Component Diagram — Full System

```mermaid
graph LR
    subgraph "Flutter App"
        subgraph "Presentation"
            AUTH_S["AuthScreen"]
            HOME["HomeScreen"]
            MED["Add Medicine\nScreen"]
            APPT["Add Appointment\nScreen"]
            EMRG["EmergencyScreen"]
            MAP["Nearby Hospitals\nScreen"]
            REC["Health Records\nScreen"]
            PROF["ProfileScreen"]
            DOC["Doctor\nDashboard"]
        end

        subgraph "Services"
            MS["MedicationService"]
            AS["AppointmentService"]
            HS["HealthRecordService"]
            US["UserService"]
            FDS["FallDetectionService"]
            PVS["PillVerificationService"]
            PDF["PdfExportService"]
            OSS["OfflineSyncService"]
            AIS["AiInsightService"]
            RGS["ReportGenerationService"]
        end

        subgraph "Repositories"
            MR["MedicationRepo"]
            AR["AppointmentRepo"]
            HR["HealthRecordRepo"]
            UR["UserRepo"]
            DR["DoctorDashboardRepo"]
            PR["PlacesRepo"]
        end

        subgraph "Analytics"
            AAS["AdherenceAnalytics\nService"]
            RAS["ResearchAnalytics\nService"]
            PIS["ProductInsights\nService"]
        end
    end

    subgraph "Firebase"
        FAUTH["Firebase Auth"]
        FST["Cloud Firestore"]
    end

    subgraph "External"
        GEM["Gemini AI API"]
        OVP["Overpass API\n(OpenStreetMap)"]
        MLKIT2["Google ML Kit"]
        SENSOR2["Accelerometer\nSensor"]
    end

    HOME --> MS
    HOME --> AS
    HOME --> PIS
    HOME --> AIS
    HOME --> RGS
    HOME --> OSS
    EMRG --> FDS
    MAP --> PR
    REC --> HS
    REC --> MS
    PROF --> US
    DOC --> RAS
    DOC --> PIS
    MED --> PVS

    MS --> MR
    AS --> AR
    HS --> HR
    US --> UR
    AAS --> MR
    RAS --> DR
    PIS --> MR
    RGS --> MS
    RGS --> AS
    RGS --> PIS
    OSS --> MR
    OSS --> AR

    MR --> FST
    AR --> FST
    HR --> FST
    UR --> FST
    DR --> FST
    PR --> OVP

    AUTH_S --> FAUTH
    AIS --> GEM
    PVS --> MLKIT2
    FDS --> SENSOR2
```

---

## 11. State Diagram — Medication Dose Flow

```mermaid
stateDiagram-v2
    [*] --> NoDosesToday : App opens, no meds logged

    NoDosesToday --> TodaySchedule : Medications loaded from Firestore

    state TodaySchedule {
        [*] --> Pending
        Pending --> LoggingInProgress : User taps card
        LoggingInProgress --> Taken : Firestore write success
        LoggingInProgress --> OfflineQueued : No internet
        OfflineQueued --> Taken : Connectivity restored → sync
        Taken --> [*] : Max daily doses reached
    }

    TodaySchedule --> AdherenceCalculated : End of day / midnight
    AdherenceCalculated --> [*]
```

---

## 12. Deployment Diagram

```mermaid
graph TB
    subgraph "User's Device"
        APP["SmartAid Flutter App\n(Android / iOS / Web / Windows)"]
        LOCALDB["SQLite\nOffline Queue"]
        LOCALFILES["Local File System\nHealth Records"]
    end

    subgraph "Google Cloud (Firebase)"
        FAUTH2["Firebase Authentication"]
        FST2["Cloud Firestore\n(NoSQL Database)"]
    end

    subgraph "Google AI"
        GEM2["Gemini API\n(generativelanguage.googleapis.com)"]
    end

    subgraph "OpenStreetMap Infrastructure"
        OSM["OSM Tile Server\ntile.openstreetmap.org"]
        OVPAPI["Overpass API\noverpass-api.de"]
    end

    APP <--> FAUTH2
    APP <--> FST2
    APP <--> GEM2
    APP <--> OSM
    APP <--> OVPAPI
    APP <--> LOCALDB
    APP <--> LOCALFILES
```

---

> **Note:** These diagrams are rendered using [Mermaid](https://mermaid.js.org/). GitHub renders Mermaid diagrams natively in Markdown files.
