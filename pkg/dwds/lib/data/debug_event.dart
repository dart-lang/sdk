// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DebugEvent {
  final String kind;
  final String eventData;
  final int timestamp;

  DebugEvent({
    required this.kind,
    required this.eventData,
    required this.timestamp,
  });

  factory DebugEvent.fromJson(Map<String, dynamic> json) {
    return DebugEvent(
      kind: json['kind'] as String,
      eventData: json['eventData'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'kind': kind, 'eventData': eventData, 'timestamp': timestamp};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebugEvent &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          eventData == other.eventData &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(kind, eventData, timestamp);

  @override
  String toString() =>
      'DebugEvent(kind: $kind, eventData: $eventData, timestamp: $timestamp)';
}

/// A batched group of events, currently always Debugger.scriptParsed
class BatchedDebugEvents {
  final List<DebugEvent> events;

  BatchedDebugEvents({required this.events});

  factory BatchedDebugEvents.fromJson(Map<String, dynamic> json) {
    return BatchedDebugEvents(
      events: (json['events'] as List)
          .map((e) => DebugEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'events': events.map((e) => e.toJson()).toList()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchedDebugEvents &&
          runtimeType == other.runtimeType &&
          _listEquals(events, other.events);

  @override
  int get hashCode => Object.hashAll(events);

  @override
  String toString() => 'BatchedDebugEvents(events: $events)';
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
