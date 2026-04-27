// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class RegisterEvent {
  final String eventData;
  final int timestamp;

  RegisterEvent({required this.eventData, required this.timestamp});

  factory RegisterEvent.fromJson(Map<String, dynamic> json) {
    return RegisterEvent(
      eventData: json['eventData'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'eventData': eventData, 'timestamp': timestamp};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterEvent &&
        other.eventData == eventData &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(eventData, timestamp);

  @override
  String toString() =>
      'RegisterEvent(eventData: $eventData, timestamp: $timestamp)';
}
