// MockData.swift
// ClassWiz – PreviewData
//
// Static sample data for SwiftUI Previews and development testing.

import Foundation

// MARK: - Mock Users

enum MockData {
    // MARK: - Users

    static let studentUser = AppUser(
        id: "student_001",
        name: "Aryan Islam",
        email: "aryan@university.edu",
        role: .student,
        batchId: "batch_cse3a",
        isApproved: true,
        createdAt: Date()
    )

    static let teacherUser = AppUser(
        id: "teacher_001",
        name: "Dr. Sarah Ahmed",
        email: "sarah.ahmed@university.edu",
        role: .teacher,
        batchId: nil,
        isApproved: true,
        createdAt: Date()
    )

    static let adminUser = AppUser(
        id: "admin_001",
        name: "Admin User",
        email: "admin@university.edu",
        role: .admin,
        batchId: nil,
        isApproved: true,
        createdAt: Date()
    )

    static let students: [AppUser] = [
        studentUser,
        AppUser(id: "student_002", name: "Nadia Rahman",   email: "nadia@university.edu",  role: .student, batchId: "batch_cse3a", isApproved: true),
        AppUser(id: "student_003", name: "Rifat Hossain",  email: "rifat@university.edu",   role: .student, batchId: "batch_cse3a", isApproved: true),
        AppUser(id: "student_004", name: "Priya Sharma",   email: "priya@university.edu",   role: .student, batchId: "batch_cse3a", isApproved: true),
        AppUser(id: "student_005", name: "Mehedi Hasan",   email: "mehedi@university.edu",  role: .student, batchId: "batch_cse3a", isApproved: true),
    ]

    // MARK: - Batches

    static let batch = Batch(id: "batch_cse3a", name: "CSE 3A", semesterId: "Spring 2026", year: 2026)
    static let batch2 = Batch(id: "batch_cse3b", name: "CSE 3B", semesterId: "Spring 2026", year: 2026)
    static let batches: [Batch] = [batch, batch2]

    // MARK: - Courses

    static let courses: [Course] = [
        Course(id: "course_db", code: "CSE-321", name: "Database Systems", credit: 3, isActive: true),
        Course(id: "course_algo", code: "CSE-305", name: "Algorithms", credit: 3, isActive: true),
        Course(id: "course_os", code: "CSE-311", name: "Operating Systems", credit: 3, isActive: true),
        Course(id: "course_net", code: "CSE-341", name: "Computer Networks", credit: 3, isActive: true),
        Course(id: "course_sw", code: "CSE-361", name: "Software Engineering", credit: 2, isActive: true),
    ]

    // MARK: - Routines

    static let routines: [Routine] = [
        Routine(id: "r1", courseId: "course_db",   teacherId: "teacher_001", batchId: "batch_cse3a", day: .sunday,    startTime: "09:00", endTime: "10:30", room: "Room-301"),
        Routine(id: "r2", courseId: "course_algo",  teacherId: "teacher_001", batchId: "batch_cse3a", day: .sunday,    startTime: "11:00", endTime: "12:30", room: "Room-205"),
        Routine(id: "r3", courseId: "course_os",    teacherId: "teacher_001", batchId: "batch_cse3a", day: .monday,    startTime: "09:00", endTime: "10:30", room: "Lab-101"),
        Routine(id: "r4", courseId: "course_net",   teacherId: "teacher_001", batchId: "batch_cse3a", day: .tuesday,   startTime: "13:00", endTime: "14:30", room: "Room-402"),
        Routine(id: "r5", courseId: "course_sw",    teacherId: "teacher_001", batchId: "batch_cse3a", day: .wednesday, startTime: "10:00", endTime: "11:30", room: "Room-301"),
        Routine(id: "r6", courseId: "course_db",    teacherId: "teacher_001", batchId: "batch_cse3a", day: .thursday,  startTime: "09:00", endTime: "10:30", room: "Lab-201"),
    ]

    // MARK: - Attendance Records (sample for student_001)

    static let attendanceRecords: [AttendanceRecord] = {
        var records: [AttendanceRecord] = []
        let calendar = Calendar.current
        let courseIds = ["course_db", "course_algo", "course_os"]

        for courseId in courseIds {
            for i in 0..<20 {
                let date = calendar.date(byAdding: .day, value: -(i * 3), to: Date())!
                let status: AttendanceStatus = (i % 5 == 0) ? .absent : .present
                records.append(AttendanceRecord(
                    id: "\(courseId)_\(i)",
                    studentId: "student_001",
                    courseId: courseId,
                    date: date,
                    status: status,
                    markedBy: "teacher_001"
                ))
            }
        }
        return records
    }()

    // MARK: - Mock AppState

    static func makeStudentAppState() -> AppState {
        let state = AppState()
        state.signIn(user: studentUser)
        return state
    }

    static func makeTeacherAppState() -> AppState {
        let state = AppState()
        state.signIn(user: teacherUser)
        return state
    }

    static func makeAdminAppState() -> AppState {
        let state = AppState()
        state.signIn(user: adminUser)
        return state
    }

    // MARK: - Mock CourseAttendanceStat

    static let courseStats: [CourseAttendanceStat] = [
        CourseAttendanceStat(id: "course_db",   course: courses[0], totalClasses: 20, presentCount: 18, absentCount: 2,  percentage: 90.0, risk: .safe),
        CourseAttendanceStat(id: "course_algo", course: courses[1], totalClasses: 18, presentCount: 14, absentCount: 4,  percentage: 77.8, risk: .warning),
        CourseAttendanceStat(id: "course_os",   course: courses[2], totalClasses: 22, presentCount: 15, absentCount: 7,  percentage: 68.2, risk: .critical),
        CourseAttendanceStat(id: "course_net",  course: courses[3], totalClasses: 16, presentCount: 14, absentCount: 2,  percentage: 87.5, risk: .safe),
        CourseAttendanceStat(id: "course_sw",   course: courses[4], totalClasses: 12, presentCount: 10, absentCount: 2,  percentage: 83.3, risk: .safe),
    ]

    // MARK: - Mock RoutineDisplayItems

    static let routineDisplayItems: [RoutineDisplayItem] = [
        RoutineDisplayItem(id: "r1", routine: routines[0], courseName: "Database Systems",   courseCode: "CSE-321", teacherName: "Dr. Sarah Ahmed", isActive: false),
        RoutineDisplayItem(id: "r2", routine: routines[1], courseName: "Algorithms",          courseCode: "CSE-305", teacherName: "Dr. Sarah Ahmed", isActive: false),
        RoutineDisplayItem(id: "r3", routine: routines[2], courseName: "Operating Systems",   courseCode: "CSE-311", teacherName: "Dr. Sarah Ahmed", isActive: false),
    ]

    // MARK: - Mock TeacherAssignment

    static let teacherAssignments: [TeacherAssignment] = [
        TeacherAssignment(id: "ta1", teacherId: "teacher_001", courseId: "course_db",   batchId: "batch_cse3a"),
        TeacherAssignment(id: "ta2", teacherId: "teacher_001", courseId: "course_algo", batchId: "batch_cse3a"),
        TeacherAssignment(id: "ta3", teacherId: "teacher_001", courseId: "course_os",   batchId: "batch_cse3a"),
    ]
}
