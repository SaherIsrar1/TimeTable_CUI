import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/timetable_viewmodel.dart';
import '../viewmodels/section_details_viewmodel.dart';
import '../viewmodels/teacher_details_viewmodel.dart';
import '../services/search_history_service.dart';
import 'free_slots_screen.dart';
import 'portal_screen.dart';
import 'section_details_screen.dart';
import 'teacher_details_screen.dart';

/// Main timetable search screen with recent-search history and improved ranking.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late TimetableViewModel _vm;

  /// Whether the search field is focused AND the query is empty
  /// → show recent-search dropdown
  bool _showRecents = false;

  static const Color _primaryColor = Color(0xFF001F3F);
  static const Color _accentColor = Color(0xFF0074D9);
  static const Color _backgroundColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _vm = context.read<TimetableViewModel>();
    _vm.addListener(_onVmChanged);
    // Start on Sections tab
    _vm.changeTab(1);

    _searchFocus.addListener(() {
      // Show recents when focused and query is empty
      final focused = _searchFocus.hasFocus;
      final empty = _searchController.text.isEmpty;
      if (mounted) setState(() => _showRecents = focused && empty);
    });

    _searchController.addListener(() {
      final empty = _searchController.text.isEmpty;
      final focused = _searchFocus.hasFocus;
      if (mounted) setState(() => _showRecents = focused && empty);
    });
  }

  /// Shows a SnackBar when the ViewModel reports an error.
  void _onVmChanged() {
    if (_vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.errorMessage!)),
      );
      _vm.clearError();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FreeSlotsScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PortalScreen()),
      );
    }
  }

  /// Called when the user taps a result card or a recent-search chip.
  void _navigateToItem(
      TimetableViewModel vm, String itemId, String itemName) async {
    // Save to history
    final type = vm.selectedTab == 0 ? 'teacher' : 'section';
    await vm.saveToHistory(id: itemId, name: itemName, type: type);

    // Dismiss keyboard
    _searchFocus.unfocus();

    if (!mounted) return;

    if (vm.selectedTab == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => SectionDetailsViewModel(sectionId: itemId),
            child: const SectionDetailsScreen(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => TeacherDetailsViewModel(teacherId: itemId),
            child: const TeacherDetailsScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimetableViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: const Text(
              "CUI Timetable",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: _primaryColor,
            elevation: 0,
          ),



          body: GestureDetector(
            // Dismiss keyboard / recents when tapping outside
            onTap: () {
              _searchFocus.unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            vm.changeTab(0);
                            _searchController.clear();
                            _searchFocus.unfocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vm.selectedTab == 0
                                ? _primaryColor
                                : Colors.white,
                            foregroundColor: vm.selectedTab == 0
                                ? Colors.white
                                : _primaryColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Teachers",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            vm.changeTab(1);
                            _searchController.clear();
                            _searchFocus.unfocus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vm.selectedTab == 1
                                ? _primaryColor
                                : Colors.white,
                            foregroundColor: vm.selectedTab == 1
                                ? Colors.white
                                : _primaryColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Sections",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar + Recent overlay (inside a Stack)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchArea(vm),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: vm.loading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: _accentColor))
                      : _showRecents
                          ? const SizedBox.shrink()
                          : _buildSearchResults(vm),
                ),
              ],
            ),
          ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: _accentColor,
            unselectedItemColor: Colors.grey,
            onTap: _onBottomNavTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                label: "Timetable",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                label: "Slots",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "Portal",
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar + recents dropdown
  // ---------------------------------------------------------------------------

  Widget _buildSearchArea(TimetableViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search TextField ──────────────────────────────────────────────
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          style: const TextStyle(
              color: _primaryColor, fontWeight: FontWeight.w500),
          cursorColor: _accentColor,
          onChanged: (query) {
            if (vm.selectedTab == 1) {
              vm.fetchSections(query);
            } else {
              vm.fetchTeachers(query);
            }
          },
          decoration: InputDecoration(
            hintText: vm.selectedTab == 0
                ? "Search teachers (e.g., Abrar or Hammad)..."
                : "Search sections (e.g., FA24-BSE-7A)...",
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.black45),
                    onPressed: () {
                      _searchController.clear();
                      vm.selectedTab == 1
                          ? vm.fetchSections('')
                          : vm.fetchTeachers('');
                    },
                  )
                : null,
            hintStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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

        // ── Recent searches panel (shown when focused + query empty) ──────
        if (_showRecents) _buildRecentsPanel(vm),
      ],
    );
  }

  Widget _buildRecentsPanel(TimetableViewModel vm) {
    final recents = vm.currentRecent;
    final type = vm.selectedTab == 0 ? 'teacher' : 'section';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: recents.isEmpty
          ? Padding(
              key: const ValueKey('empty'),
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'No recent ${type}s',
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : Container(
              key: const ValueKey('list'),
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 10, 8, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.history,
                            size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        const Text(
                          'Recently searched',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black45,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => vm.clearHistory(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 12,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Recent items list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recents.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 60, endIndent: 16),
                    itemBuilder: (context, index) {
                      final entry = recents[index];
                      return _RecentTile(
                        entry: entry,
                        onTap: () =>
                            _navigateToItem(vm, entry.id, entry.name),
                        onDismiss: () =>
                            vm.removeFromHistory(entry.id, entry.type),
                      );
                    },
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search results list
  // ---------------------------------------------------------------------------

  Widget _buildSearchResults(TimetableViewModel vm) {
    final bool isSearching = _searchController.text.isNotEmpty;
    final List<Map<String, dynamic>> currentList =
        vm.selectedTab == 1 ? vm.sections : vm.teachers;
    final String itemType = vm.selectedTab == 1 ? 'section' : 'teacher';
    final bool noResults = currentList.isEmpty && isSearching;
    final bool initialPrompt = currentList.isEmpty && !isSearching;

    if (noResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              "No ${itemType}s found",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try a different spelling or keyword",
              style: const TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      );
    } else if (initialPrompt) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded,
                size: 60, color: _accentColor.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              "Search for a $itemType",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: currentList.length,
        itemBuilder: (context, index) {
          final item = currentList[index];
          final itemId = item['id'] as String;
          final itemTitle = (item['name'] ?? itemId) as String;

          return _ResultCard(
            itemId: itemId,
            itemTitle: itemTitle,
            query: _searchController.text.trim(),
            onTap: () => _navigateToItem(vm, itemId, itemTitle),
          );
        },
      );
    }
  }
}

// =============================================================================
// _RecentTile — single row in the recents dropdown
// =============================================================================

class _RecentTile extends StatelessWidget {
  final RecentSearchEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _RecentTile({
    required this.entry,
    required this.onTap,
    required this.onDismiss,
  });

  static const Color _accentColor = Color(0xFF0074D9);
  static const Color _primaryColor = Color(0xFF001F3F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history,
                  size: 18, color: _accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                  Text(
                    entry.type == 'teacher' ? 'Teacher' : 'Section',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.black38),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ResultCard — search result with highlighted matching text
// =============================================================================

class _ResultCard extends StatelessWidget {
  final String itemId;
  final String itemTitle;
  final String query;
  final VoidCallback onTap;

  const _ResultCard({
    required this.itemId,
    required this.itemTitle,
    required this.query,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF001F3F);
  static const Color _accentColor = Color(0xFF0074D9);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: _accentColor.withOpacity(0.15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF0F4F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _accentColor.withOpacity(0.18),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    itemId.length >= 2
                        ? itemId.substring(0, 2).toUpperCase()
                        : itemId.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Highlighted title
              Expanded(
                child: _HighlightedText(
                  text: itemTitle,
                  query: query,
                  baseStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _primaryColor,
                  ),
                  highlightStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _accentColor,
                    backgroundColor: Color(0xFFD6EAFF),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: _accentColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _HighlightedText — highlights matching substring in result cards
// =============================================================================

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lText = text.toLowerCase();
    final lQuery = query.toLowerCase();
    final idx = lText.indexOf(lQuery);

    if (idx == -1) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(children: [
        if (idx > 0)
          TextSpan(text: text.substring(0, idx), style: baseStyle),
        TextSpan(
            text: text.substring(idx, idx + query.length),
            style: highlightStyle),
        if (idx + query.length < text.length)
          TextSpan(
              text: text.substring(idx + query.length), style: baseStyle),
      ]),
    );
  }
}
