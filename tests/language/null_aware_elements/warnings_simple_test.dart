// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import 'package:expect/expect.dart';

List<int> testList(int x) {
  return <int>[?x];
//             ^
// [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
}

Set<int> testSet(int x) {
  return <int>{?x};
  //           ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
}

Map<int, String> testMapKey(int x) {
  return <int, String>{?x: ""};
  //                   ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
}

Map<String, int> testMapValue(int x) {
  return <String, int>{"": ?x};
  //                       ^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
}

main() {
  Expect.listEquals(testList(0), <int>[0]);
  Expect.setEquals(testSet(0), <int>{0});
  Expect.mapEquals(testMapKey(0), <int, String>{0: ""});
  Expect.mapEquals(testMapValue(0), <String, int>{"": 0});
}
