// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:logging/logging.dart';
import 'package:observatory_2/elements.dart';
import 'package:stack_trace/stack_trace.dart';

main() async {
  Chain.capture(() async {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
    Logger.root.info('Starting Observatory');
    document.body.children
        .insert(0, new ObservatoryApplicationElement.created().element);
  });
}
