// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.test_util;

import 'dart:io';

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

void configureTest() {
  if (!Platform.environment.containsKey('COVERALLS_TOKEN')) {
    groupSep = " > ";
    useCompactVMConfiguration();
  }
}
