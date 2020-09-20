// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test script for type_casts_with_null_safety_autodetection_test.dart which
// is supposed to run in weak mode because it is opted-out.

// @dart=2.6

import 'package:expect/expect.dart';

dynamic nullObj;

@pragma('vm:never-inline')
typeCast<T>(x) => x as T;

void doTests() {
  typeCast<dynamic>(nullObj);
  typeCast<void>(nullObj);
  typeCast<Object>(nullObj);
  typeCast<int>(nullObj);
  typeCast<List<int>>(<int>[]);
  typeCast<List<int>>(<Null>[]);
}

main() {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
  print('OK(weak)');
}
