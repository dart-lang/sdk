#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.run_all;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'dom_test.dart' as dom_test;
import 'parser_feature_test.dart' as parser_feature_test;
import 'parser_test.dart' as parser_test;
import 'tokenizer_test.dart' as tokenizer_test;

main(List<String> args) {
  var pattern = new RegExp(args.length > 0 ? args[0] : '.');
  useCompactVMConfiguration();

  void addGroup(testFile, testMain) {
    if (pattern.hasMatch(testFile)) {
      group(testFile.replaceAll('_test.dart', ':'), testMain);
    }
  }

  addGroup('dom_test.dart', dom_test.main);
  addGroup('parser_feature_test.dart', parser_feature_test.main);
  addGroup('parser_test.dart', parser_test.main);
  addGroup('tokenizer_test.dart', tokenizer_test.main);
}
