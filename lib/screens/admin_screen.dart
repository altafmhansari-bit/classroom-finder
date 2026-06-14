// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/classroom.dart';
import '../repositories/classroom_repository.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isTeacher) {
      return const Scaffold(body: Center(child: Text('Access denied.')));
    }
    return const _AdminContent();
  }
}

class _AdminContent extends StatefulWidget {
  const _AdminContent();

  @override
  State<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<_AdminContent> {
  final ClassroomRepository _repo = ClassroomRepository();

  Future<void> _deleteRoom(Classroom c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Room?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Room ${c.roomNumber} will be permanently removed. This cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.deleteClassroom(c.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Room ${c.roomNumber} deleted'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _openForm({Classroom? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomFormSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6DFF),
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          StreamBuilder<List<Classroom>>(
            stream: _repo.classroomsStream(),
            builder: (_, snap) {
              final count = snap.data?.length ?? 0;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count rooms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Classroom>>(
        stream: _repo.classroomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classrooms yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add the first room',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (_, i) => _AdminRoomTile(
              classroom: rooms[i],
              onEdit: () => _openForm(existing: rooms[i]),
              onDelete: () => _deleteRoom(rooms[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF1A6DFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Room',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ── Admin room tile ───────────────────────────────────────────
class _AdminRoomTile extends StatelessWidget {
  final Classroom classroom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminRoomTile({
    required this.classroom,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = classroom;
    final isOccupied = c.isOccupied;
    final statusColor = isOccupied ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A6DFF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              c.roomNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1A6DFF),
              ),
            ),
          ),
        ),
        title: Text(
          c.subject.isNotEmpty ? c.subject : 'No subject',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              c.faculty.isNotEmpty ? c.faculty : 'No faculty',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // ✅ FIX: The subtitle area inside ListTile trailing is very
            // narrow (~76px). Using mainAxisSize.min + unconstrained texts
            // overflows. Switch to a Row that fills available width and
            // wrap BOTH text widgets in Flexible so they share the space.
            Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'Floor ${c.floor}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.apartment, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    c.building,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1A6DFF),
                size: 22,
              ),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 22,
              ),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit bottom sheet ───────────────────────────────────
class _RoomFormSheet extends StatefulWidget {
  final Classroom? existing;
  const _RoomFormSheet({this.existing});

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  final _repo = ClassroomRepository();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late final TextEditingController _roomNumberCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _facultyCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _departmentCtrl;

  int _floor = 1;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _roomNumberCtrl = TextEditingController(text: e?.roomNumber ?? '');
    _buildingCtrl = TextEditingController(text: e?.building ?? '');
    _facultyCtrl = TextEditingController(text: e?.faculty ?? '');
    _subjectCtrl = TextEditingController(text: e?.subject ?? '');
    _capacityCtrl = TextEditingController(text: e?.capacity.toString() ?? '');
    _departmentCtrl = TextEditingController(text: e?.department ?? '');
    _floor = e?.floor ?? 1;
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _buildingCtrl.dispose();
    _facultyCtrl.dispose();
    _subjectCtrl.dispose();
    _capacityCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final updatedBy = auth.user?.name ?? 'teacher';

    try {
      if (_isEdit) {
        await _repo.updateClassroom(
          roomId: widget.existing!.id,
          roomNumber: _roomNumberCtrl.text.trim(),
          building: _buildingCtrl.text.trim(),
          floor: _floor,
          faculty: _facultyCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 0,
          department: _departmentCtrl.text.trim(),
          updatedBy: updatedBy,
        );
      } else {
        await _repo.addClassroom(
          roomNumber: _roomNumberCtrl.text.trim(),
          building: _buildingCtrl.text.trim(),
          floor: _floor,
          faculty: _facultyCtrl.text.trim(),
          subject: _subjectCtrl.text.trim(),
          capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 0,
          department: _departmentCtrl.text.trim(),
          updatedBy: updatedBy,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Room updated successfully!'
                  : 'Room added successfully!',
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A6DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEdit
                          ? Icons.edit_outlined
                          : Icons.add_business_outlined,
                      color: const Color(0xFF1A6DFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ FIX: Expanded prevents the title from overflowing
                  // the header Row on narrow bottom sheets
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Room' : 'Add New Room',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    _SectionLabel('Room Info'),

                    _FormField(
                      controller: _roomNumberCtrl,
                      label: 'Room Number *',
                      hint: 'e.g. 101, A-204',
                      icon: Icons.numbers,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Room number is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _buildingCtrl,
                      label: 'Building *',
                      hint: 'e.g. Main Block, Science Wing',
                      icon: Icons.apartment,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Building is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _SectionLabel('Floor'),
                    const SizedBox(height: 8),

                    // ✅ FIX: Floor picker was 5×48px + 5×10px margin
                    // = 290px which overflows on narrow screens (246px).
                    // Expanded makes each button fill an equal fraction
                    // of the available width — works on any screen size.
                    Row(
                      children: [1, 2, 3, 4, 5].map((f) {
                        final selected = _floor == f;
                        final isLast = f == 5;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _floor = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: EdgeInsets.only(right: isLast ? 0 : 8),
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1A6DFF)
                                    : const Color(0xFF1A6DFF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '$f',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF1A6DFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    _SectionLabel('Faculty & Subject'),

                    _FormField(
                      controller: _facultyCtrl,
                      label: 'Faculty Name',
                      hint: 'e.g. Dr. Sharma',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _subjectCtrl,
                      label: 'Subject',
                      hint: 'e.g. Data Structures',
                      icon: Icons.book_outlined,
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _capacityCtrl,
                      label: 'Capacity (seats)',
                      hint: 'e.g. 60',
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            int.tryParse(v.trim()) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _FormField(
                      controller: _departmentCtrl,
                      label: 'Department',
                      hint: 'e.g. Computer Science',
                      icon: Icons.school_outlined,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6DFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Save Changes' : 'Add Classroom',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF1A6DFF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A6DFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
