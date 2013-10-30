#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.run;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'dart:io' show Options;

import 'builder_test.dart' as builder_test;
import 'end2end_test.dart' as end2end_test;
import 'parser_test.dart' as parser_test;
import 'printer_test.dart' as printer_test;
import 'refactor_test.dart' as refactor_test;
import 'span_test.dart' as span_test;
import 'utils_test.dart' as utils_test;
import 'vlq_test.dart' as vlq_test;

main(List<String> arguments) {
  var pattern = new RegExp(arguments.length > 0 ? arguments[0] : '.');
  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('builder_test.dart', builder_test.main);
  addGroup('end2end_test.dart', end2end_test.main);
  addGroup('parser_test.dart', parser_test.main);
  addGroup('printer_test.dart', printer_test.main);
  addGroup('refactor_test.dart', refactor_test.main);
  addGroup('span_test.dart', span_test.main);
  addGroup('utils_test.dart', utils_test.main);
  addGroup('vlq_test.dart', vlq_test.main);
}
