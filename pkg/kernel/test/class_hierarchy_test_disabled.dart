// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'class_hierarchy_self_check.dart';

main() {
  test('All-pairs class hierarchy tests on dart2js', () {
    testClassHierarchyOnProgram(
        loadProgramFromBinary('test/data/dart2js.dill'));
  });
}
