// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  Logger.root.info('Starting Observatory');
  GoogleChart.initOnce().then((_) {
    // Charts loaded, initialize polymer.
    Logger.root.info('Initializing Polymer');
    initPolymer();
  });
}