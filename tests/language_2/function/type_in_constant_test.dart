// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that consts can be created with inlined function types as type
/// arguments.

import 'package:expect/expect.dart';

class A<T> {
  const A();
}

@pragma('dart2js:noInline')
test(a, b) {
  Expect.notEquals(a, b);
}

main() {
  test(const A<int Function()>(), const A<String Function()>());
  test(const A<int>(), const A<String Function()>());
  test(const A<int Function()>(), const A<String>());
}
