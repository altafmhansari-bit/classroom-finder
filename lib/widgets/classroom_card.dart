// lib/widgets/classroom_card.dart

import 'package:flutter/material.dart';
import '../models/classroom.dart';

class ClassroomCard extends StatelessWidget {
  final Classroom classroom;
  final VoidCallback onTap;

  const ClassroomCard({
    super.key,
    required this.classroom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOccupied = classroom.isOccupied;
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Row(
          children: [
            // Room number badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6DFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  classroom.roomNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1A6DFF),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classroom.subject.isNotEmpty
                        ? classroom.subject
                        : 'No class scheduled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${classroom.faculty} · ${classroom.building}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // ✅ FIX: Removed SingleChildScrollView wrapper.
                  // It was causing the Row to render at infinite width
                  // with no constraints, producing the 23px overflow.
                  // Row inside an Expanded Column is already constrained.
                  // ✅ FIX: Wrapped both Text widgets in Flexible so they
                  // shrink/ellipsize instead of pushing the Row wider than
                  // the available space.
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Floor ${classroom.floor}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.people_outline,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${classroom.capacity} seats',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ✅ FIX: Status pill — added shrinkWrap protection so
            // the pill never pushes past the card edge on narrow screens.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOccupied ? Icons.circle : Icons.circle_outlined,
                    size: 8,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOccupied ? 'Occupied' : 'Empty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
