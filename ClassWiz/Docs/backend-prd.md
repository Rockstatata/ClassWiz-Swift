# 📘 BACKEND & DATABASE PRD

## Project: **Classwiz**

---

## 1. Backend Overview

### Backend Philosophy

Classwiz uses a **Backend-as-a-Service (BaaS)** model, primarily powered by **Firebase**, to:

* Minimize infrastructure overhead
* Enable rapid development
* Support real-time data sync
* Provide offline-first mobile behavior

The backend is **API-driven**, **role-aware**, and **secure by design**.

---

## 2. Backend Technology Stack

### Core Services Used

| Layer                    | Technology               | Purpose                 |
| ------------------------ | ------------------------ | ----------------------- |
| Authentication           | Firebase Authentication  | User identity & session |
| Database                 | Cloud Firestore          | Primary data storage    |
| Backend Logic            | Cloud Functions          | Validation, aggregation |
| Notifications (Optional) | Firebase Cloud Messaging | Alerts                  |
| AI Layer (Optional)      | External LLM API         | Insight explanation     |

📌 All services are selected to remain within **Firebase free-tier constraints**.

---

## 3. Architectural Design

### High-Level Architecture

```
SwiftUI Client
   ↓ (SDK / REST APIs)
Firebase Authentication
   ↓
Cloud Firestore
   ↓
Cloud Functions
   ↓
(Optional) LLM API
```

### Architectural Principles

* **Client is thin**: no sensitive logic
* **Firestore is source of truth**
* **Cloud Functions handle validation**
* **LLM is non-authoritative**

---

## 4. Authentication & Identity Management

### 4.1 Authentication Method

* Email + password authentication
* Student ID / institutional email mapping
* Firebase-issued JWT tokens

### 4.2 Role Assignment Strategy

Each user has a **single authoritative role**:

```
student | teacher | admin
```

Stored in:

```
users/{userId}.role
```

### 4.3 Session Handling

* Tokens automatically refreshed by Firebase SDK
* Client stores minimal auth state
* Role resolved immediately after login

---

## 5. Database Design (Cloud Firestore)

### Design Philosophy

* **Denormalized reads** (Firestore-optimized)
* **Minimal write amplification**
* **Predictable query patterns**
* **Strict access via security rules**

---

## 6. Firestore Collections & Schemas

---

### 6.1 `users` Collection

**Purpose:** Identity + role metadata

```
users/{userId}
```

| Field     | Type      | Description               |
| --------- | --------- | ------------------------- |
| name      | String    | Full name                 |
| email     | String    | Login identifier          |
| role      | String    | student / teacher / admin |
| batchId   | String    | Student batch (nullable)  |
| createdAt | Timestamp | Account creation          |

📌 **Single source of truth for role resolution**

---

### 6.2 `batches` Collection

**Purpose:** Academic grouping

```
batches/{batchId}
```

| Field      | Type   | Description       |
| ---------- | ------ | ----------------- |
| name       | String | e.g. CSE 3A       |
| semesterId | String | Academic semester |
| year       | Number | Academic year     |

---

### 6.3 `courses` Collection (Admin CRUD)

**Purpose:** Master course list

```
courses/{courseId}
```

| Field    | Type    | Description      |
| -------- | ------- | ---------------- |
| code     | String  | CSE-321          |
| name     | String  | Database Systems |
| credit   | Number  | Credit hours     |
| isActive | Boolean | Archived or not  |

📌 Courses are **referenced everywhere**, never duplicated.

---

### 6.4 `teacherAssignments` Collection

**Purpose:** Access control & teaching scope

```
teacherAssignments/{assignmentId}
```

| Field     | Type   | Description   |
| --------- | ------ | ------------- |
| teacherId | String | User ID       |
| courseId  | String | Course taught |
| batchId   | String | Batch taught  |

📌 This collection defines **what a teacher can access**.

---

### 6.5 `routines` Collection

**Purpose:** Timetable management

```
routines/{routineId}
```

| Field     | Type   | Description      |
| --------- | ------ | ---------------- |
| courseId  | String | Course reference |
| teacherId | String | Assigned teacher |
| batchId   | String | Target batch     |
| day       | String | Monday–Friday    |
| startTime | String | 09:00            |
| endTime   | String | 10:30            |
| room      | String | Optional         |

📌 Read-heavy, rarely updated.

---

### 6.6 `attendance` Collection

**Purpose:** Core academic records

```
attendance/{attendanceId}
```

| Field     | Type      | Description      |
| --------- | --------- | ---------------- |
| studentId | String    | User ID          |
| courseId  | String    | Course           |
| date      | Timestamp | Class date       |
| status    | String    | present / absent |
| markedBy  | String    | Teacher ID       |

📌 **Append-only design** (immutability principle).

---

### 6.7 `analytics` Collection (Derived Data)

**Purpose:** Performance optimization

```
analytics/{docId}
```

| Field             | Type   | Description               |
| ----------------- | ------ | ------------------------- |
| userId            | String | Student                   |
| courseId          | String | Course                    |
| attendancePercent | Number | Cached                    |
| riskLevel         | String | Safe / Warning / Critical |

📌 Updated via Cloud Functions.

---

## 7. Security Rules (Critical Section)

### 7.1 Security Design Principles

* Least privilege access
* Role-based enforcement
* Server-side validation
* Zero trust on client

---

### 7.2 Access Matrix

| Role    | Read                   | Write           |
| ------- | ---------------------- | --------------- |
| Student | Own data + leaderboard | ❌               |
| Teacher | Assigned courses       | Attendance only |
| Admin   | All                    | All             |

---

### 7.3 Example Rule (Conceptual)

```js
allow write: if
  request.auth.token.role == "teacher"
  && isAssignedTeacher(request.auth.uid, resource.data.courseId);
```

📌 **This alone can win you marks.**

---

## 8. Cloud Functions (Backend Logic Layer)

### Why Cloud Functions?

* Keep logic off client
* Enforce consistency
* Secure API keys
* Control costs

---

### Key Functions

| Function            | Purpose                |
| ------------------- | ---------------------- |
| validateAttendance  | Teacher authorization  |
| updateAnalytics     | Attendance aggregation |
| generateLeaderboard | Batch-wise ranking     |
| generateInsights    | LLM explanation        |

---

## 9. Leaderboard Backend Logic

### Scope Control

* Same batch
* Same course
* Aggregated percentage only

### Query Flow

```
attendance → aggregation → ranking → response
```

📌 No raw data leakage.

---

## 10. Offline & Sync Strategy

### Firestore Capabilities

* Local cache
* Automatic sync
* Conflict resolution

### Application-Level Handling

* Disable writes when offline
* Show last sync timestamp
* Graceful fallback UI

---

## 11. Optional LLM Integration (Backend-Controlled)

### Why Backend Only?

* API key safety
* Rate limiting
* Auditability

### LLM Input

* Rule-based outputs
* Attendance statistics

### LLM Output

* Human-readable explanation
* No decision authority

---

## 12. Performance & Cost Control

### Free Plan Optimization

* Denormalized reads
* Aggregated analytics
* Minimal listeners
* On-demand Cloud Functions
* Cached LLM responses

---

## 13. Failure Handling & Reliability

* Retry on transient failures
* Graceful degradation
* Clear error messaging
* Audit logs for admin actions

---

## 14. Compliance & Data Integrity

* Read-only student records
* Append-only attendance
* Role-bound write access
* Administrative audit trail

---

## 15. Backend Evaluation Strength (Why This Is Strong)

Classwiz backend demonstrates:

✅ Cloud-native architecture
✅ Role-based security enforcement
✅ Scalable NoSQL data modeling
✅ Offline-first support
✅ Proper separation of concerns
✅ Responsible AI usage

---

## 16. One-Line Backend Summary (Viva Gold)

> “The backend of Classwiz is a role-secured, API-driven cloud system built on Firebase, designed to support offline mobile clients, enforce academic workflows, and provide derived analytics through controlled server-side logic.”

---
