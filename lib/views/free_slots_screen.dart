import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/free_slots_viewmodel.dart';
import 'timetable_screen.dart';
import 'portal_screen.dart';

/// Free slots screen — reads from [FreeSlotsViewModel] via Consumer.
/// Converted to StatelessWidget; all state is managed by the ViewModel.
class FreeSlotsScreen extends StatelessWidget {
  const FreeSlotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FreeSlotsViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: const Text(
              "Slots",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF001F3F),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Selector
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(vm.days.length, (index) {
                      bool selected = vm.selectedDay == index;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ElevatedButton(
                            onPressed: () => vm.setDay(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selected
                                  ? const Color(0xFF001F3F)
                                  : Colors.white,
                              foregroundColor: selected
                                  ? Colors.white
                                  : Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              elevation: 1,
                            ),
                            child: Text(
                              vm.dayShortNames[index],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Slot Selector
                const Text(
                  "Select Time Slot",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vm.slots.length,
                    itemBuilder: (context, index) {
                      bool selected = vm.selectedSlot == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => vm.setSlot(index),
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF001F3F)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF001F3F)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vm.slots[index]["label"]!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vm.slots[index]["time"]!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Classrooms",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Chip(
                      label: Text("${vm.availableRooms.length}"),
                      labelStyle: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                vm.loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF001F3F),
                          ),
                        ),
                      )
                    : vm.availableRooms.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.do_not_disturb_alt_outlined,
                                      size: 80,
                                      color: Colors.orange.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No Free Classrooms!",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "All rooms are occupied in this slot",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: vm.availableRooms.map((roomName) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.meeting_room_outlined,
                                        color: Colors.green.shade500,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            roomName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${vm.slots[vm.selectedSlot]["label"]} • ${vm.slots[vm.selectedSlot]["time"]}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Free",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                const SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            selectedItemColor: const Color(0xFF0074D9),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TimetableScreen()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PortalScreen()),
                );
              }
            },
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
}
