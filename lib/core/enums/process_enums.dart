import 'package:flutter/material.dart';

enum ProcessSort {
  name(Icons.text_fields),
  pid(Icons.tag),
  user(Icons.person),
  memory(Icons.memory),
  state(Icons.play_circle);

  const ProcessSort(this.icon);
  final IconData icon;

  String get label => switch (this) {
    ProcessSort.name => 'Name',
    ProcessSort.pid => 'PID', 
    ProcessSort.user => 'User',
    ProcessSort.memory => 'Memory',
    ProcessSort.state => 'State',
  };
}