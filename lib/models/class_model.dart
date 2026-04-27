/// Represents a single class/period entry in a timetable document.
class ClassModel {
  final String period;
  final String course;
  final String room;
  final String teacher;
  final String section;

  ClassModel({
    required this.period,
    required this.course,
    required this.room,
    required this.teacher,
    required this.section,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      period: map['period']?.toString() ?? '',
      course: map['course']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      teacher: map['teacher']?.toString() ?? '',
      section: map['section']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'period': period,
        'course': course,
        'room': room,
        'teacher': teacher,
        'section': section,
      };
}
