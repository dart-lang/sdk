// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((logRecord) {
    developer.log(logRecord.message,
        time: logRecord.time,
        sequenceNumber: logRecord.sequenceNumber,
        level: logRecord.level.value,
        name: logRecord.loggerName,
        zone: null,
        error: logRecord.error,
        stackTrace: logRecord.stackTrace);
  });
  new Timer.periodic(new Duration(seconds: 1), (t) {
    Logger.root.info('INFO MESSAGE');
  });
  new Timer.periodic(new Duration(seconds: 1), (t) {
    Logger.root.fine('FINE MESSAGE');
  });
}
