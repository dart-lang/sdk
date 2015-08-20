// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch bool debugger({bool when: true,
                     String message}) native "Developer_debugger";

patch Object inspect(Object object) native "Developer_inspect";

patch void log(String message,
               {DateTime time,
                int sequenceNumber,
                int level: 0,
                String name: '',
                Zone zone,
                Object error,
                StackTrace stackTrace}) {
  if (message is! String) {
    throw new ArgumentError(message, "message", "Must be a String");
  }
  if (time == null) {
    time = new DateTime.now();
  }
  if (time is! DateTime) {
    throw new ArgumentError(time, "time", "Must be a DateTime");
  }
  if (sequenceNumber == null) {
    sequenceNumber = _nextSequenceNumber++;
  } else {
    _nextSequenceNumber = sequenceNumber + 1;
  }
  _log(message,
       time.millisecondsSinceEpoch,
       sequenceNumber,
       level,
       name,
       zone,
       error,
       stackTrace);
}

int _nextSequenceNumber = 0;

_log(String message,
     int timestamp,
     int sequenceNumber,
     int level,
     String name,
     Zone zone,
     Object error,
     StackTrace stackTrace) native "Developer_log";
