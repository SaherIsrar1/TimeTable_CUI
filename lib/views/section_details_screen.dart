import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/section_details_viewmodel.dart';

/// Section details screen.
/// Stays StatefulWidget ONLY for the AnimationController (glow effect on
/// ongoing classes). All data, timer, and time calculations are in
/// [SectionDetailsViewModel].
class SectionDetailsScreen extends StatefulWidget {
  const SectionDetailsScreen({super.key});

  @override
  State<SectionDetailsScreen> createState() => _SectionDetailsScreenState();
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.5,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0074D9).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF0074D9), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF001F3F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF001F3F);
    const accentColor = Color(0xFF0074D9);

    return Consumer<SectionDetailsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: Text(
              vm.sectionId,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: primaryColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Day",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 10),

                // Day Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: vm.days.map((day) {
                    bool isSelected = vm.selectedDay == day;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton(
                          onPressed: () => vm.setDay(day),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? primaryColor : Colors.white,
                            foregroundColor:
                                isSelected ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            elevation: 1,
                          ),
                          child: Text(day.substring(0, 3),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Text(
                    "${vm.classes.length} ${vm.classes.length == 1 ? 'Class' : 'Classes'}",
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 10),

                Expanded(
                  child: vm.loading
                      ? Center(
                          child: CircularProgressIndicator(color: accentColor))
                      : vm.classes.isEmpty
                          ? Center(
                              child: Text(
                                  "No classes scheduled for ${vm.selectedDay}",
                                  style:
                                      const TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: vm.classes.length,
                              itemBuilder: (context, index) {
                                final cls = vm.classes[index];
                                final period =
                                    cls['period']?.toString() ?? '';
                                final time = vm.getTimeFromPeriod(period);
                                final displayTime =
                                    vm.getDisplayTimeFromPeriod(period);
                                final teacher = cls['teacher'] ?? '';
                                final room = cls['room'] ?? '';
                                final course = cls['course'] ?? '';

                                final durationText =
                                    vm.calculateDuration(time);
                                final statusText = vm.getStatus(time);
                                final isOngoing = vm.isOngoing(time);

                                final parts = displayTime.split('-');
                                final startTime = parts.isNotEmpty
                                    ? parts[0].trim()
                                    : '';
                                final endTime = parts.length > 1
                                    ? parts[1].trim()
                                    : '';

                                return AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, child) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          if (isOngoing)
                                            BoxShadow(
                                              color: accentColor.withOpacity(
                                                  0.3 *
                                                      _glowController.value),
                                              blurRadius: 12 *
                                                  _glowController.value,
                                              spreadRadius:
                                                  2 * _glowController.value,
                                            )
                                          else
                                            BoxShadow(
                                              color: Colors.black12
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Time Column
                                          SizedBox(
                                            width: 75,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(startTime,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14.5,
                                                        color: primaryColor)),
                                                Container(
                                                  height: 36,
                                                  width: 1.3,
                                                  color: accentColor,
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 3),
                                                ),
                                                Text(endTime,
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13)),
                                                const SizedBox(height: 5),
                                                if (statusText.isNotEmpty)
                                                  Text(
                                                    statusText,
                                                    textAlign:
                                                        TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: statusText ==
                                                              "Completed"
                                                          ? Colors.grey
                                                          : statusText
                                                                  .contains(
                                                                      "Remaining")
                                                              ? Colors.orange
                                                              : statusText
                                                                      .contains(
                                                                          "Starts")
                                                                  ? Colors
                                                                      .green
                                                                  : Colors
                                                                      .grey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Class Info Column
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(course,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15,
                                                        color: primaryColor)),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person,
                                                        size: 15,
                                                        color: accentColor),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: Text(teacher,
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .black87,
                                                              fontSize:
                                                                  13.5)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 5,
                                                  runSpacing: 4,
                                                  children: [
                                                    _buildTag(room),
                                                    _buildTag(durationText),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
