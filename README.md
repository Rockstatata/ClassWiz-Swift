
# Classwiz

**An Intelligent Class Routine and Attendance Management System**

---

## Table of Contents

1. Project Overview
2. Motivation
3. Key Features
4. User Roles and Capabilities
5. System Architecture
6. Technology Stack
7. Backend Design (Firebase)
8. Database Schema Overview
9. Security and Access Control
10. Offline-First Design
11. Attendance Intelligence and Analytics
12. Optional AI Integration
13. Project Structure
14. Development Setup
15. Implementation Roadmap
16. Evaluation Highlights
17. Future Enhancements

---

## 1. Project Overview

Classwiz is a role-based academic management mobile application designed to manage class routines, attendance records, and attendance analytics for students, teachers, and administrators.

Unlike traditional attendance applications that only record data, Classwiz focuses on **analysis, interpretation, and decision support**, helping users understand attendance requirements, risks, and recovery strategies.

The application is built using **SwiftUI** for iOS and uses **Firebase** as a cloud-based backend with offline-first support.

---

## 2. Motivation

Most academic attendance systems suffer from the following limitations:

* Attendance is stored but not analyzed
* Students do not understand eligibility or recovery requirements
* Teachers manage attendance manually without analytics
* Administrators lack a centralized system for configuration
* Mobile connectivity issues are not handled gracefully

Classwiz addresses these problems by combining:

* Cloud-based APIs
* Role-based access control
* Attendance intelligence logic
* Offline-first mobile computing principles

---

## 3. Key Features

* Role-based access for Students, Teachers, and Administrators
* Weekly and semester-based class routine management
* Secure attendance tracking
* Attendance percentage calculation and risk classification
* Attendance leaderboard for classmates (privacy controlled)
* Teacher class calendar and attendance management
* Administrative CRUD for courses, routines, and assignments
* Offline-first support with automatic synchronization
* Optional AI-powered attendance explanations

---

## 4. User Roles and Capabilities

### Student

* View class routine (online and offline)
* View personal attendance statistics
* See attendance risk level
* Compare attendance with classmates (leaderboard)
* Simulate future absences and eligibility
* Request attendance correction (optional)

### Teacher

* View assigned courses and teaching schedule
* Mark and manage attendance for assigned classes
* View course-wise attendance analytics
* Access a calendar-style class overview

### Administrator

* Manage courses (CRUD)
* Manage batches and semesters
* Create and update class routines
* Assign teachers to courses and batches
* Control system-wide academic configuration

---

## 5. System Architecture

```
SwiftUI Mobile Application
        |
        | Firebase SDK (API calls)
        v
Firebase Authentication
        |
        v
Cloud Firestore
        |
        v
Cloud Functions (Validation, Aggregation)
        |
        v
Optional LLM API (Explanation Layer)
```

The client application remains lightweight, while security, validation, and aggregation logic are handled by backend services.

---

## 6. Technology Stack

### Frontend

* Swift
* SwiftUI
* MVVM Architecture
* Combine

### Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions
* Firebase Cloud Messaging (optional)

### Optional AI

* External LLM API (used only for explanation and summaries)

---

## 7. Backend Design (Firebase)

Classwiz uses Firebase as a Backend-as-a-Service (BaaS) platform.

### Key Backend Responsibilities

* User authentication and session management
* Secure data storage and synchronization
* Role-based authorization
* Aggregation of attendance analytics
* Optional AI insight generation

The backend is designed to operate efficiently within the Firebase free plan.

---

## 8. Database Schema Overview

Firestore collections include:

```
users/
batches/
courses/
teacherAssignments/
routines/
attendance/
analytics/
```

### Design Principles

* Denormalized reads for performance
* Append-only attendance records
* Derived analytics stored separately
* Predictable query patterns

---

## 9. Security and Access Control

Security is enforced using Firestore security rules.

### Access Control Summary

* Students can read only their own attendance data
* Students can read aggregated leaderboard data
* Teachers can write attendance only for assigned courses
* Administrators have full CRUD access

All sensitive operations are validated server-side using Cloud Functions.

---

## 10. Offline-First Design

Classwiz is designed using mobile computing principles.

### Offline Capabilities

* Cached routines and attendance data
* Read access available without network
* Automatic synchronization on reconnect
* Visual indication of last sync time

Writes are restricted or queued appropriately when offline.

---

## 11. Attendance Intelligence and Analytics

Attendance intelligence is implemented using deterministic logic, not AI.

### Features

* Attendance percentage calculation
* Risk classification:

  * Safe (≥80%)
  * Warning (75–79%)
  * Critical (<75%)
* Recovery calculation:

  * Minimum required future attendance
* Attendance trend visualization
* Semester-wise performance comparison

These features provide decision support rather than raw data.

---

## 12. Optional AI Integration

AI is used strictly as an **explanation layer**.

### Approved Use Cases

* Natural language explanation of attendance status
* Personalized recovery summaries
* Routine summaries

### Important Principle

All academic rules and calculations are performed by deterministic logic.
The AI never makes academic decisions.

AI requests are handled through backend Cloud Functions to ensure security and cost control.

---

## 13. Project Structure

```
Classwiz/
├── App/
├── Core/
├── Services/
├── Models/
├── ViewModels/
├── Views/
├── Utilities/
├── Resources/
└── PreviewData/
```

This structure follows MVVM and clean architecture principles, separating UI, logic, and backend interaction.

---

## 14. Development Setup

### Prerequisites

* Xcode (iOS 16+)
* Apple Developer Account (free tier)
* Firebase Project

### Setup Steps

1. Clone the repository
2. Open the project in Xcode
3. Configure Firebase and add `GoogleService-Info.plist`
4. Enable Authentication and Firestore in Firebase Console
5. Run the project on simulator or device

---

## 15. Implementation Roadmap

### Phase 1

* Authentication
* Role-based routing
* Student routine and attendance view

### Phase 2

* Teacher attendance management
* Attendance intelligence logic
* Leaderboard feature

### Phase 3

* Admin CRUD operations
* Security rules enforcement
* Offline-first optimization

### Phase 4

* UI polish
* Error handling
* Optional AI integration

---

## 16. Evaluation Highlights

This project demonstrates:

* API-driven cloud architecture
* Offline-first mobile computing design
* Role-based system modeling
* Full CRUD backend configuration
* Analytics and predictive logic
* Secure and scalable backend design
* Responsible and limited AI usage

---

## 17. Future Enhancements

* GPA correlation with attendance
* Institutional ERP integration
* Cross-department analytics
* Web dashboard for administrators
* Push notification automation
* Multi-university support

---

## Conclusion

Classwiz is a complete academic management and decision-support system that goes beyond traditional attendance tracking. By combining cloud APIs, mobile-first design, analytics, and secure access control, it provides a realistic and scalable solution to academic attendance management.

---

