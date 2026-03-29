import 'package:flutter/material.dart';

enum Priority { high, medium, low }

class Todo {
  final String id;
  String title;
  bool isCompleted;
  DateTime createdAt;
  DateTime dueDate;
  Priority priority;
  String memo;

  Todo({
    required this.id,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = Priority.medium,
    this.memo = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ★ JSON（Map型）に変換する
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'priority': priority.index, // Enumは数字(0,1,2)で保存
    'memo': memo,
  };

  // ★ JSON（Map型）から復元する
  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'],
    createdAt: DateTime.parse(json['createdAt']),
    dueDate: DateTime.parse(json['dueDate']),
    priority: Priority.values[json['priority']],
    memo: json['memo'],
  );
}