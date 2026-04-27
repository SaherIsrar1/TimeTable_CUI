import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';

// ── App palette ──────────────────────────────────────────────────────────────
const Color _primaryColor = Color(0xFF001F3F);
const Color _accentColor = Color(0xFF0074D9);
const Color _sheetBg = Color(0xFFF9FAFB);

/// Shows a modal bottom sheet to configure class notifications.
Future<void> showNotificationSetup(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<NotificationViewModel>(),
      child: const _NotificationSetupSheet(),
    ),
  );
}

class _NotificationSetupSheet extends StatefulWidget {
  const _NotificationSetupSheet();

  @override
  State<_NotificationSetupSheet> createState() =>
      _NotificationSetupSheetState();
}

class _NotificationSetupSheetState extends State<_NotificationSetupSheet>
    with SingleTickerProviderStateMixin {
  late int _step;

  String? _selectedRole;
  String? _selectedId;

  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _searchResults = [];
  bool _searching = false;

  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );

    final vm = context.read<NotificationViewModel>();
    _step = vm.isActive ? -1 : 0;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final collection = _selectedRole == 'student'
          ? 'timetablestudents'
          : 'timetableTeachers';

      final snapshot =
          await FirebaseFirestore.instance.collection(collection).get();

      final lq = query.trim().toLowerCase();
      final results = snapshot.docs
          .where((d) => d.id.toLowerCase().contains(lq))
          .map((d) => d.id)
          .toList();

      results.sort((a, b) {
        int rank(String id) {
          final l = id.toLowerCase();
          if (l == lq) return 0;
          if (l.startsWith(lq)) return 1;
          return 2;
        }
        return rank(a).compareTo(rank(b));
      });

      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('[NotificationSetup] search error: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _confirm() async {
    if (_selectedRole == null || _selectedId == null) return;

    final vm = context.read<NotificationViewModel>();
    final success = await vm.activateNotifications(
      role: _selectedRole!,
      id: _selectedId!,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _step = 2);
      _successCtrl.forward(from: 0);
    } else {
      setState(() {});
    }
  }

  Future<void> _turnOff() async {
    final vm = context.read<NotificationViewModel>();
    await vm.clearNotifications();
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _step == -1
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: _accentColor,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _step == -1
                        ? 'Notification Settings'
                        : 'Set Class Notifications',
                    style: const TextStyle(
                      color: _primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black45),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.black.withOpacity(0.08)),
            if (_step >= 0) _StepIndicator(currentStep: _step),
            if (_step >= 0) const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == -1
                      ? _buildActiveStep()
                      : _step == 0
                          ? _buildRoleStep()
                          : _step == 1
                              ? _buildSearchStep()
                              : _buildSuccessStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step -1: Active profile ─────────────────────────────────────────────

  Widget _buildActiveStep() {
    final vm = context.watch<NotificationViewModel>();
    final isTeacher = vm.savedRole == 'teacher';
    final roleIcon = isTeacher ? '👨‍🏫' : '🎓';
    final roleLabel = isTeacher ? 'Teacher' : 'Student';

    return Column(
      key: const ValueKey('active'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // Active profile card with blue accent
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _accentColor.withOpacity(0.12),
                _accentColor.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active,
                    color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(roleIcon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: _accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.savedId ?? '',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Notifications are ON',
                      style: TextStyle(
                          color: Colors.green.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Turn Off button
        Consumer<NotificationViewModel>(
          builder: (_, vm, __) => ElevatedButton.icon(
            onPressed: vm.isLoading ? null : _turnOff,
            icon: vm.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.notifications_off_rounded),
            label: Text(
              vm.isLoading ? 'Turning off...' : 'Turn Off Notifications',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Reconfigure button
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Change Notification Profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accentColor,
            side: const BorderSide(color: _accentColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 0: Role selection ──────────────────────────────────────────────

  Widget _buildRoleStep() {
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Who are you?',
          style: TextStyle(color: Colors.black54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _RoleCard(
          icon: '🎓',
          title: 'Student',
          onTap: () {
            setState(() {
              _selectedRole = 'student';
              _step = 1;
              _searchResults = [];
              _searchCtrl.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: '👨‍🏫',
          title: 'Teacher',
          onTap: () {
            setState(() {
              _selectedRole = 'teacher';
              _step = 1;
              _searchResults = [];
              _searchCtrl.clear();
            });
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 1: Search & select ─────────────────────────────────────────────

  Widget _buildSearchStep() {
    final isStudent = _selectedRole == 'student';
    final vm = context.watch<NotificationViewModel>();

    return Column(
      key: const ValueKey('search'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back
        GestureDetector(
          onTap: () => setState(() {
            _step = 0;
            _selectedId = null;
            _searchResults = [];
            _searchCtrl.clear();
          }),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios, color: _accentColor, size: 16),
              const SizedBox(width: 4),
              Text('Back',
                  style: TextStyle(color: _accentColor, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isStudent ? 'Search your section' : 'Search your name',
          style: const TextStyle(
            color: _primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isStudent ? 'e.g. BSCS-7A, BSIT-5B' : 'e.g. Dr. Ahsan, Dr. Sara',
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
        const SizedBox(height: 16),
        // Search field
        TextField(
          controller: _searchCtrl,
          onChanged: _search,
          style: const TextStyle(color: _primaryColor),
          cursorColor: _accentColor,
          decoration: InputDecoration(
            hintText:
                isStudent ? 'Type section name...' : 'Type teacher name...',
            hintStyle: const TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search, color: _accentColor),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accentColor),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accentColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Error
        if (vm.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              vm.errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        // Results — blue-accented tiles
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final id = _searchResults[i];
              final isSelected = _selectedId == id;
              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accentColor.withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _accentColor
                        : _accentColor.withOpacity(0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(isSelected ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isStudent ? Icons.group : Icons.person,
                      color: _accentColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    id,
                    style: TextStyle(
                      color: isSelected ? _accentColor : _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: _accentColor, size: 22)
                      : const Icon(Icons.arrow_forward_ios,
                          color: _accentColor, size: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () => setState(() => _selectedId = id),
                ),
              );
            },
          ),
        ] else if (_searchCtrl.text.isNotEmpty && !_searching)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              children: [
                const Icon(Icons.search_off, color: Colors.black26, size: 40),
                const SizedBox(height: 8),
                Text(
                  isStudent ? 'No section found' : 'No teacher found',
                  style: const TextStyle(color: Colors.black45),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        // Confirm
        if (_selectedId != null)
          Consumer<NotificationViewModel>(
            builder: (_, vm, __) => ElevatedButton.icon(
              onPressed: vm.isLoading ? null : _confirm,
              icon: vm.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.notifications_active),
              label: Text(
                vm.isLoading ? 'Setting up...' : 'Enable Notifications',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 2: Success ─────────────────────────────────────────────────────

  Widget _buildSuccessStep() {
    final isStudent = _selectedRole == 'student';

    return ScaleTransition(
      scale: _successScale,
      child: Column(
        key: const ValueKey('success'),
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.green, size: 52),
          ),
          const SizedBox(height: 24),
          Text(
            isStudent
                ? 'You\'re all set, Student! 🎓'
                : 'You\'re all set, Teacher! 👨‍🏫',
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Notifications are enabled for\n$_selectedId',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be notified 10 minutes before\neach class, every weekday.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('Done'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? Colors.green
                : isActive
                    ? _accentColor
                    : Colors.black12,
          ),
        );
      }),
    );
  }
}

/// Role selection cards — solid light blue, minimal
class _RoleCard extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
