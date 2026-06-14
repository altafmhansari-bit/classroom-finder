// lib/screens/home_screen.dart

import 'package:classroom_finder/providers/auth_provider.dart';
import 'package:classroom_finder/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/classroom.dart';
import '../repositories/classroom_repository.dart';
import '../widgets/classroom_card.dart';
import 'admin_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ClassroomRepository _repo = ClassroomRepository();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'all';
  String _filterFloor = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Classroom> _applyFilters(List<Classroom> classrooms) {
    return classrooms.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          c.roomNumber.toLowerCase().contains(q) ||
          c.faculty.toLowerCase().contains(q) ||
          c.department.toLowerCase().contains(q) ||
          c.subject.toLowerCase().contains(q) ||
          c.building.toLowerCase().contains(q);
      final matchesStatus = _filterStatus == 'all' || c.status == _filterStatus;
      final matchesFloor =
          _filterFloor == 'all' || c.floor.toString() == _filterFloor;
      return matchesSearch && matchesStatus && matchesFloor;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6DFF),
        foregroundColor: Colors.white,
        title: const Text(
          'Classroom Finder',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (ctx, auth, _) {
              if (auth.isTeacher) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teacher name badge
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            auth.user?.name.split(' ').first ?? 'Teacher',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Admin panel button — teachers only
                    IconButton(
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                      ),
                      tooltip: 'Admin Panel',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      ),
                    ),
                    // Logout
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Sign Out',
                      onPressed: () => _confirmLogout(context, auth),
                    ),
                  ],
                );
              }
              // Students see login button
              return IconButton(
                icon: const Icon(Icons.login, color: Colors.white),
                tooltip: 'Teacher Login',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Floor Maps',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Floor maps coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + filter bar ───────────────────────────
          Container(
            color: const Color(0xFF1A6DFF),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search by room, faculty, dept, subject...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF1A6DFF),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 10),

                // Filter chips + floor dropdown
                // Chips are in a horizontal scroll (Expanded) so they
                // never overflow. Dropdown is anchored outside the scroll.
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filterStatus == 'all',
                              color: Colors.white,
                              onTap: () =>
                                  setState(() => _filterStatus = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '🟢 Empty',
                              selected: _filterStatus == 'empty',
                              color: Colors.green.shade100,
                              onTap: () =>
                                  setState(() => _filterStatus = 'empty'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '🔴 Occupied',
                              selected: _filterStatus == 'occupied',
                              color: Colors.red.shade100,
                              onTap: () =>
                                  setState(() => _filterStatus = 'occupied'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Floor dropdown — always visible on the right
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterFloor,
                          isDense: true,
                          items: ['all', '1', '2', '3', '4']
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    f == 'all' ? 'All Floors' : 'Floor $f',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _filterFloor = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Room list ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Classroom>>(
              stream: _repo.classroomsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final all = snapshot.data ?? [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          all.isEmpty
                              ? 'No classrooms added yet'
                              : 'No classrooms found',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (all.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Teachers can add rooms via Admin Panel',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final emptyCount = filtered.where((c) => !c.isOccupied).length;
                final occupiedCount = filtered.length - emptyCount;

                return Column(
                  children: [
                    // Summary bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} room${filtered.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          _StatusBadge(
                            count: emptyCount,
                            label: 'Empty',
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            count: occupiedCount,
                            label: 'Occupied',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    // Room cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => ClassroomCard(
                          classroom: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailScreen(classroom: filtered[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip widget ────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: const Color(0xFF1A6DFF), width: 2)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? const Color(0xFF1A6DFF) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Status badge widget ───────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Logout confirm dialog ─────────────────────────────────────
void _confirmLogout(BuildContext context, AuthProvider auth) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Sign Out',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text('Sign out as ${auth.user?.name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            auth.signOut();
          },
          child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
