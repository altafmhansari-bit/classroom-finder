// lib/screens/detail_screen.dart

import 'package:classroom_finder/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/classroom.dart';
import '../repositories/classroom_repository.dart';

class DetailScreen extends StatefulWidget {
  final Classroom classroom;

  const DetailScreen({super.key, required this.classroom});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ClassroomRepository _repo = ClassroomRepository();
  bool _isUpdating = false;

  Future<void> _toggleStatus() async {
    final newStatus = widget.classroom.isOccupied ? 'empty' : 'occupied';
    setState(() => _isUpdating = true);

    final auth = context.read<AuthProvider>();
    final updatedBy = auth.user?.name ?? 'teacher';

    try {
      await _repo.updateStatus(
        roomId: widget.classroom.id,
        newStatus: newStatus,
        updatedBy: updatedBy,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Room marked as ${newStatus.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: newStatus == 'occupied'
                ? Colors.red
                : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A6DFF)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classroom;
    final isOccupied = c.isOccupied;
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6DFF),
        foregroundColor: Colors.white,
        title: Text('Room ${c.roomNumber}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status hero card ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.8), statusColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isOccupied
                        ? Icons.meeting_room
                        : Icons.door_back_door_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOccupied ? 'OCCUPIED' : 'EMPTY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOccupied
                        ? 'Class is currently in session'
                        : 'Room is available to use',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated by: ${c.updatedBy}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Details card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  _infoRow(Icons.numbers, 'Room', c.roomNumber),
                  _infoRow(Icons.apartment, 'Building', c.building),
                  _infoRow(Icons.layers, 'Floor', 'Floor ${c.floor}'),
                  _infoRow(Icons.people, 'Capacity', '${c.capacity} seats'),
                  _infoRow(Icons.school, 'Department', c.department),
                  _infoRow(
                    Icons.person,
                    'Faculty',
                    c.faculty.isNotEmpty ? c.faculty : 'N/A',
                  ),
                  _infoRow(
                    Icons.book,
                    'Subject',
                    c.subject.isNotEmpty ? c.subject : 'N/A',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Schedule card ───────────────────────────────
            if (c.schedule.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    ...c.schedule.entries.map((entry) {
                      final day =
                          entry.key[0].toUpperCase() + entry.key.substring(1);
                      final times = entry.value as Map;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            // Fixed-width day pill
                            Container(
                              width: 90,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1A6DFF,
                                ).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A6DFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ✅ FIX: Expanded absorbs the remaining row
                            // width so the time text never overflows.
                            // The 90px day pill + 12px gap were eating
                            // into the constrained 246px parent, leaving
                            // only 144px for the time — which wasn't
                            // enough for long strings like "09:00 – 11:30".
                            Expanded(
                              child: Text(
                                '${times['start']} – ${times['end']}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // ── Toggle button (teachers only) ───────────────
            Consumer<AuthProvider>(
              builder: (ctx, auth, _) {
                if (!auth.isTeacher) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        // ✅ FIX: Flexible prevents this text from
                        // overflowing on narrow screens
                        Flexible(
                          child: Text(
                            'Only teachers can update room status',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _toggleStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOccupied ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: (isOccupied ? Colors.green : Colors.red)
                          .withOpacity(0.4),
                    ),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            isOccupied
                                ? Icons.door_back_door_outlined
                                : Icons.meeting_room,
                          ),
                    label: Text(
                      _isUpdating
                          ? 'Updating...'
                          : isOccupied
                          ? 'Mark as EMPTY'
                          : 'Mark as OCCUPIED',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                'Changes are instantly visible to everyone',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
