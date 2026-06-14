// lib/repositories/classroom_repository.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/classroom.dart';

class ClassroomRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('classrooms');

  // ── Real-time stream of all classrooms ────────────────────
  Stream<List<Classroom>> classroomsStream() {
    return _db.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) {
        return Classroom.fromMap(
          e.key as String,
          Map<String, dynamic>.from(e.value as Map),
        );
      }).toList();
    });
  }

  // ── Update status only (teacher marks room occupied/empty) ─
  Future<void> updateStatus({
    required String roomId,
    required String newStatus,
    required String updatedBy,
  }) async {
    await _db.child(roomId).update({
      'status': newStatus,
      'updatedBy': updatedBy,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // ── Add a brand new classroom ─────────────────────────────
  Future<void> addClassroom({
    required String roomNumber,
    required String building,
    required int floor,
    required String faculty,
    required String subject,
    required int capacity,
    required String department,
    required String updatedBy,
  }) async {
    // Use push() to auto-generate a unique Firebase key
    final newRef = _db.push();
    await newRef.set({
      'roomNumber': roomNumber,
      'building': building,
      'floor': floor,
      'faculty': faculty,
      'subject': subject,
      'capacity': capacity,
      'department': department,
      'status': 'empty', // new rooms start as empty
      'updatedBy': updatedBy,
      'lastUpdated': DateTime.now().toIso8601String(),
      'schedule': {}, // empty schedule by default
    });
  }

  // ── Edit an existing classroom's details ──────────────────
  Future<void> updateClassroom({
    required String roomId,
    required String roomNumber,
    required String building,
    required int floor,
    required String faculty,
    required String subject,
    required int capacity,
    required String department,
    required String updatedBy,
  }) async {
    // update() only touches the specified fields — does NOT
    // overwrite status or schedule set by other operations.
    await _db.child(roomId).update({
      'roomNumber': roomNumber,
      'building': building,
      'floor': floor,
      'faculty': faculty,
      'subject': subject,
      'capacity': capacity,
      'department': department,
      'updatedBy': updatedBy,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // ── Delete a classroom permanently ────────────────────────
  Future<void> deleteClassroom(String roomId) async {
    await _db.child(roomId).remove();
  }
}
