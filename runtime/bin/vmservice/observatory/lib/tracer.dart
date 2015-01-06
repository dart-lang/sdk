// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tracer;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:observe/observe.dart';

_deepCopy(src) {
  if (src is Map) {
    var dest = {};
    src.forEach((key, val) {
        dest[key] = _deepCopy(val);
    });
    return dest;
  } else if (src is List) {
    var dest = [];
    src.forEach((val) {
        dest.add(_deepCopy(val));
    });
    return dest;
  } else {
    return src;
  }
}

class TraceEvent {
  TraceEvent.msg(this._time, this.message, Map originalMap) {
    map = _deepCopy(originalMap);
  }

  String get timeStamp => "T+${_time}us";

  String toString() {
    return "[${timeStamp}] ${message}";
  }

  int _time;
  String message;
  Map map;
}

class Tracer extends Observable {
  // The current global tracer.
  static Tracer get current => _current;

  static Tracer _current;

  static void start() {
    if (_current == null) {
      _current = new Tracer();
    }
  }
  static void stop() {
    if (_current != null) {
      _current.cancel();
      _current = null;
    }
  }
  
  // The tracer subscribes to all logging events.
  StreamSubscription loggerSub = null;

  // The start time for the current request.
  Stopwatch _time;

  // A list of all tracing events for thre current request.
  ObservableList<TraceEvent> events = new ObservableList<TraceEvent>();

  Tracer() {
    _time = new Stopwatch();
    _time.start();
    loggerSub = Logger.root.onRecord.listen((LogRecord rec) {
        // Echo all log messages to the trace.
        trace('${rec.level.name}: ${rec.message}');
      });
    reset();
  }

  void cancel() {
    loggerSub.cancel();
  }

  void reset() {
    _time.reset();
    events.clear();
  }

  TraceEvent trace(String message, {Map map: null}) {
    var event = new TraceEvent.msg(_time.elapsedMicroseconds, message, map);
    events.add(event);
    return event;
  } 
}
