# ClassWiz — Copilot Instructions

Project context
- Project: ClassWiz — An Intelligent Class Routine and Attendance Management System
- Platform: iOS
- Framework: SwiftUI
- Backend: Firebase (Authentication, Cloud Firestore, Cloud Functions)
- Roles: student, teacher, admin

References
1. App Prd : app-prd.md
2. Backend Prd : backend-prd.md
3. Readme : README.md

Purpose
These instructions provide guidance to GitHub Copilot / code assistants to keep suggestions aligned with the project's architecture, security model, and coding conventions. Make sure you always refer to the above documents for context and constraints before generating code snippets.

Core principles
1. Role-Based Access Control (RBAC)
   - Enforce role validation before rendering or exposing role-specific UI/UX.
   - Users have a single authoritative role: `student | teacher | admin` (stored in `users/{userId}.role`).
   - Resolve role immediately after Firebase authentication and use it to gate UI and network calls.

2. Offline-First Design
   - Prefer Firestore's offline persistence and local caching for critical reads.
   - Suggest lightweight, resilient UI states for offline scenarios.
   - Provide sync awareness in the UI (sync pending, last synced, etc.).

3. Data Architecture
   - Favor denormalized read patterns optimized for Firestore queries.
   - Use references (IDs) instead of duplicating master data (e.g., `courseId`, `batchId`, `teacherId`).
   - Push validation and aggregation logic to Cloud Functions; keep client logic thin.

4. Security
   - Recommend Firestore Security Rules that strictly limit reads/writes based on authenticated role and ownership.
   - Do not recommend storing sensitive tokens locally; use the Firebase SDK session handling.
   - Validate and sanitize inputs before writing to Firestore.

Firebase integration standards
- Authentication: Email + password via Firebase Authentication
- Database: Cloud Firestore (denormalized collections)
- Backend logic: Cloud Functions for validation and aggregation
- Notifications: Firebase Cloud Messaging (optional)
- AI: Optional external LLM API for non-authoritative, explanatory insights

Key collections & schemas (guidance)
- `users/{userId}`: { name, email, role, batchId, createdAt }
- `batches/{batchId}`: { name, semesterId, year }
- `courses/{courseId}`: { code, name, credit, isActive }
- `teacherAssignments/{assignmentId}`: { teacherId, courseId, batchId }
- `routines/{routineId}`: { courseId, teacherId, batchId, day, startTime, endTime, room }
- `attendance/{attendanceId}`: { studentId, courseId, date, status }

Feature-specific guidance
- Student features: attendance percentage, risk classification (🟢 Safe ≥80%, 🟡 Warning 75–79%, 🔴 Critical <75%), "what-if" simulator, classmates leaderboard with privacy controls.
- Teacher features: access only to assigned courses, attendance marking, edit window restriction, course analytics.
- Admin features: CRUD for courses/batches/routines, teacher assignment, system configuration.

SwiftUI and code conventions
- Follow MVVM: separate Views, ViewModels, Models, and Services.
- Use `@StateObject` for ViewModels and `@EnvironmentObject` for shared app state (like authenticated user & role).
- Keep UI declarative and free of heavy business logic; place logic in ViewModels or Services.
- Create reusable components (risk badge, attendance card, routine row) and previews.

Testing & validation
- Test each role (student, teacher, admin) independently.
- Test offline behavior and sync reconciliation.
- Validate Firestore Security Rules with representative user accounts before deployment.

Developer ergonomics
- Prefer concise, idiomatic Swift and SwiftUI patterns.
- Suggest small, focused code changes and prioritize safe migrations (avoid large refactors without tests).
- When proposing database schema changes, include migration notes and expected query patterns.

Brief examples (patterns to prefer)
- MVVM ViewModel pattern for Firestore listeners and publishers
- Small service wrappers around Firebase SDK calls with retry and error mapping
- Lightweight abstractions for role-based UI toggles (e.g., `RoleBasedView<Content>`)

Notes for Copilot / assistants
- Keep suggestions aligned with the above security and architecture constraints.
- When in doubt, prefer explicitness and safety over clever shortcuts.
- If recommending new dependencies, prefer well-known, actively maintained packages and explain why.

---

Thank you — use these instructions to keep all code suggestions consistent with ClassWiz's goals and constraints.
