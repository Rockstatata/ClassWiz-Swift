# 📘 PRODUCT REQUIREMENTS DOCUMENT (PRD)

## Product Name

**Classwiz**

### Tagline

*An intelligent class routine and attendance management system*

---

## 1. Product Overview

**Classwiz** is a role-based academic management mobile application designed to help students, teachers, and administrators manage class routines, attendance records, and academic insights through a unified, cloud-backed system.

The application combines:

* API-driven backend services
* Offline-first mobile computing principles
* Attendance analytics and prediction logic
* Secure role-based access control
* Optional AI-assisted insight generation

Classwiz is not just an attendance tracker — it is a **decision-support system for academic participation**.

---

## 2. Problem Statement

Traditional academic attendance systems suffer from several limitations:

* Attendance is recorded but not analyzed
* Students lack clarity on eligibility and recovery options
* Teachers manage attendance manually with limited analytics
* Administrative configuration (courses, routines, assignments) is fragmented
* Most systems lack mobile offline support

As a result, attendance data exists, but **actionable understanding does not**.

---

## 3. Objectives

### Primary Objectives

* Digitize class routine and attendance management
* Provide real-time and historical attendance tracking
* Support students in understanding attendance eligibility
* Reduce teacher workload through structured workflows
* Enable administrators to configure the academic system centrally

### Secondary Objectives

* Demonstrate mobile computing concepts (offline sync, cloud APIs)
* Implement role-based access control
* Introduce analytics and predictive logic
* Ensure scalability within Firebase free plan constraints

---

## 4. Target Users & Roles

### User Roles

| Role          | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| Student       | Views personal attendance, routines, analytics, and peer comparison |
| Teacher       | Manages attendance for assigned courses and views teaching schedule |
| Administrator | Configures courses, routines, batches, and teacher assignments      |

The application dynamically adapts its interface and permissions based on authenticated user roles.

---

## 5. System Architecture (High Level)

```
SwiftUI Mobile Application
    ↓
Firebase Authentication (API)
    ↓
Cloud Firestore (Database API)
    ↓
Cloud Functions (Validation, Aggregation)
    ↓
Optional LLM API (Insight Explanation Layer)
```

Firebase acts as the **source of truth**, while optional LLM integration serves as an **interpretation layer**, not a decision maker.

---

## 6. Functional Requirements

---

### 6.1 Authentication & User Management

* Secure login using Firebase Authentication
* Role resolution at login (Student / Teacher / Admin)
* Session persistence using tokens
* Secure local storage for authentication state

---

### 6.2 Student Module

#### 6.2.1 Class Routine Viewer

* Weekly routine display
* Course, time, room, and instructor information
* Semester-wise routine selection
* Offline access to cached routines

---

#### 6.2.2 Attendance Tracking

* Course-wise attendance percentage
* Historical attendance records
* Read-only access to own attendance
* Real-time sync when online

---

#### 6.2.3 Attendance Intelligence Engine

The system calculates:

* Current attendance percentage
* Minimum number of classes required to reach eligibility
* Maximum allowable future absences

Example:

> “You must attend the next 3 consecutive classes to reach 75%.”

All calculations are deterministic and rule-based.

---

#### 6.2.4 Risk Classification

Attendance status is categorized as:

* 🟢 Safe (≥80%)
* 🟡 Warning (75–79%)
* 🔴 Critical (<75%)

Smart alerts are triggered when risk levels change.

---

#### 6.2.5 Classmates & Leaderboard

* Displays classmates from the same batch and course
* Ranked by attendance percentage
* Read-only, privacy-controlled access
* Optional anonymized ranking

Purpose:

* Increase engagement
* Promote attendance awareness

---

#### 6.2.6 Attendance Simulator (“What-If”)

* Students simulate future absences
* System predicts final attendance percentage
* Eligibility status shown instantly

This feature supports informed academic decision-making.

---

### 6.3 Teacher Module

#### 6.3.1 Teacher Dashboard

* List of assigned courses
* Daily and weekly teaching schedule
* Class calendar view

---

#### 6.3.2 Attendance Management

* View enrolled students per course
* Mark attendance for each class session
* Edit attendance within a limited time window
* View course-wise attendance analytics

Teachers can only manage attendance for courses assigned to them.

---

### 6.4 Administrator Module

#### 6.4.1 Course Management (CRUD)

* Create, update, and archive courses
* Manage course codes, names, and credits
* Courses act as the foundation for routines and attendance

---

#### 6.4.2 Batch & Semester Management

* Create academic batches
* Assign batches to semesters
* Control batch-wise routines and enrollments

---

#### 6.4.3 Routine Management (CRUD)

* Define class schedules
* Assign courses to time slots
* Assign rooms and instructors
* Resolve conflicts

---

#### 6.4.4 Teacher Assignment

* Assign teachers to courses and batches
* Control which classes a teacher can access
* Maintain a clear academic hierarchy

---

## 7. Data Model Overview (Firestore)

```
users/
batches/
courses/
teacherAssignments/
routines/
attendance/
analytics/
```

Data is denormalized where necessary to optimize read performance within Firebase free plan limits.

---

## 8. Security & Access Control

* Role-based access enforced via Firestore security rules
* Students:

  * Read own attendance
  * Read aggregated leaderboard data
* Teachers:

  * Write attendance only for assigned courses
* Administrators:

  * Full CRUD access

Sensitive academic data is protected through token-based authentication and secure local storage.

---

## 9. Offline-First Mobile Computing Support

* Routine and attendance data cached locally
* Application remains usable without network connectivity
* Automatic synchronization when connectivity is restored
* “Last synced” status shown to users

This design aligns with real-world mobile usage scenarios.

---

## 10. Analytics & Visualization

* Course-wise attendance charts
* Trend analysis (weekly/monthly)
* Attendance distribution comparisons
* Semester-to-semester performance comparison

Charts focus on **interpretation**, not raw numbers.

---

## 11. Optional LLM Integration

### Purpose

The LLM is used strictly as an **explanation and insight generation layer**.

### Approved Use Cases

* Natural language explanation of attendance status
* Personalized recovery suggestions based on rule outputs
* Human-readable routine summaries

### Key Principle

> All academic rules and calculations are handled by deterministic logic.
> The LLM never makes academic decisions.

---

## 12. Non-Functional Requirements

* SwiftUI-based responsive UI
* MVVM architecture
* Clean separation of concerns
* Error handling and retry mechanisms
* Dark mode support
* Scalable codebase for future extension

---

## 13. Project Evaluation Strengths

Classwiz demonstrates:

✅ API-driven cloud architecture
✅ Offline-first mobile design
✅ Role-based system modeling
✅ Full CRUD functionality
✅ Analytics and predictive logic
✅ Responsible AI integration
✅ Real-world academic workflows

---

## 14. One-Paragraph Viva Summary (Memorize This)

> “Classwiz is a role-based academic management system that integrates class routines, attendance tracking, analytics, and decision-support logic into a single mobile application. Using cloud APIs, offline mobile computing principles, and secure access control, the system supports students, teachers, and administrators while providing intelligent insights rather than just raw data.”

---

## 15. Conclusion

Classwiz evolves a conventional attendance application into a **complete academic management and decision-support system**, designed with scalability, usability, and real institutional workflows in mind.

---

