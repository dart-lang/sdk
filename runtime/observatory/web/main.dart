// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'package:observatory/elements.dart';

main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
      if (rec.level == Level.WARNING &&
          rec.message.startsWith('Error evaluating expression') &&
          (rec.message.contains("Can't assign to null: ") ||
           rec.message.contains('Expression is not assignable: '))) {
        // Suppress flaky polymer errors.
        return;
      }
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  await initElements();
  Logger.root.info('Starting Observatory');
  await initPolymer();
  Logger.root.info('Polymer initialized');
  await Polymer.onReady;
  Logger.root.info('Polymer elements have been upgraded');
}
