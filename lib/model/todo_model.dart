import 'package:flutter/material.dart';

String dateToString(DateTime date) {
  List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

class ToDo {
  int id;
  String name;
  DateTime deadline;
  bool isDone;

  ToDo({@required this.id, @required this.name, this.deadline, this.isDone});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deadline': deadline.toString(),
      'isDone': isDone ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'ToDo($id, $name, ${dateToString(deadline)}, $isDone)';
  }
}
