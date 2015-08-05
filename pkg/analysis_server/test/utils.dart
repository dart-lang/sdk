// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.test.utils;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

void initializeTestEnvironment() {
  groupSep = ' | ';
  JavaFile.pathContext = path.posix;
}
