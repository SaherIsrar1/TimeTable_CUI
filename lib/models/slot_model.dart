/// Represents a classroom-slot entry used in the Free Slots screen.
class SlotModel {
  final String room;
  final String period;

  SlotModel({required this.room, required this.period});

  factory SlotModel.fromMap(Map<String, dynamic> map) {
    return SlotModel(
      room: map['room']?.toString() ?? 'Unknown Room',
      period: map['period']?.toString() ?? '',
    );
  }
}
