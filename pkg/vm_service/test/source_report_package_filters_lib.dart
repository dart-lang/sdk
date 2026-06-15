// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:math';
import 'package:test/test.dart';
import 'package:test_package/has_part.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  // Use functions from various packages, so we can get coverage for them.
  print(Point(123, 456)); // dart:math
  print(anything); // package:test/test.dart
  print(decodeBase64('SGkh')); // package:vm_service/vm_service.dart
  print(removeAdjacentDuplicates([])); // common/service_test_common.dart
  foo(); // package:test_package/has_part.dart

  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
