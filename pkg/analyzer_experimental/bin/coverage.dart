// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library runtime.coverage;

import "package:logging/logging.dart" as log;

import 'package:analyzer_experimental/src/services/runtime/coverage_impl.dart';


main() {
  var logger = log.Logger.root;
  logger.level = log.Level.ALL;
  logger.onRecord.listen((log.LogRecord record) {
    String levelString = record.level.toString();
    while (levelString.length < 6) levelString += ' ';
    print('${record.time}: ${levelString} ${record.message}');
  });
  // TODO(scheglov) get script from options
  new CoverageServer('/Users/scheglov/dart/Test/bin').start();
}