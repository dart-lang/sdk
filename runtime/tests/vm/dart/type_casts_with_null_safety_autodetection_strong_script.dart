// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test script for type_casts_with_null_safety_autodetection_test.dart which
// is supposed to run in strong mode because it is opted-in.

import 'package:expect/expect.dart';

dynamic nullObj;

@pragma('vm:never-inline')
typeCast<T>(x) => x as T;

doTests() {
  typeCast<dynamic>(nullObj);
  typeCast<void>(nullObj);
  Expect.throwsTypeError(() => typeCast<Object>(nullObj));
  Expect.throwsTypeError(() => typeCast<int>(nullObj));
  typeCast<List<int>>(<int>[]);
  Expect.throwsTypeError(() => typeCast<List<int>>(<Null>[]));
}

main() {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
  print('OK(strong)');
}
