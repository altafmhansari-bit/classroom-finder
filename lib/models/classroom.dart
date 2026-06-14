// lib/models/classroom.dart

class Classroom {
  final String id;
  final String roomNumber;
  final int floor;
  final String building;
  final int capacity;
  final String department;
  final String faculty;
  final String subject;
  final Map<String, dynamic> schedule;
  final String status;
  final String lastUpdated; // ✅ FIX: changed int → String
  // Firebase stores lastUpdated as an ISO string
  // e.g. "2024-01-01T10:00:00.000". Keeping it
  // as int was causing a cast error.
  final String updatedBy;

  Classroom({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.building,
    required this.capacity,
    required this.department,
    required this.faculty,
    required this.subject,
    required this.schedule,
    required this.status,
    required this.lastUpdated,
    required this.updatedBy,
  });

  bool get isOccupied => status == 'occupied';

  factory Classroom.fromMap(String id, Map<dynamic, dynamic> map) {
    return Classroom(
      id: id,
      roomNumber: map['roomNumber']?.toString() ?? '',
      // ✅ FIX: _parseInt safely handles String, int, or null from Firebase
      floor: _parseInt(map['floor']),
      building: map['building']?.toString() ?? '',
      capacity: _parseInt(map['capacity']),
      department: map['department']?.toString() ?? '',
      faculty: map['faculty']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      schedule: map['schedule'] != null
          ? Map<String, dynamic>.from(map['schedule'] as Map)
          : {},
      status: map['status']?.toString() ?? 'empty',
      // ✅ FIX: lastUpdated stored as ISO string by repository
      lastUpdated: map['lastUpdated']?.toString() ?? '',
      updatedBy: map['updatedBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomNumber': roomNumber,
      'floor': floor,
      'building': building,
      'capacity': capacity,
      'department': department,
      'faculty': faculty,
      'subject': subject,
      'schedule': schedule,
      'status': status,
      'lastUpdated': lastUpdated,
      'updatedBy': updatedBy,
    };
  }

  Classroom copyWith({String? status, String? lastUpdated, String? updatedBy}) {
    return Classroom(
      id: id,
      roomNumber: roomNumber,
      floor: floor,
      building: building,
      capacity: capacity,
      department: department,
      faculty: faculty,
      subject: subject,
      schedule: schedule,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

// ── Safe int parser ───────────────────────────────────────────
// Firebase can return numbers as int, double, or String depending
// on how/when data was written. This handles all three cases.
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
