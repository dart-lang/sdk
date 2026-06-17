// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_script_test;

import 'common/test_helper.dart';

part 'field_script_other.dart';

var tests = 1;

void code() {
  print(otherField); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
