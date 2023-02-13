// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String get foo => "foo";
  Object? get bar => null;
}

test(dynamic x) {
  if (x case A(foo: "", bar: String y as String)) {
    return y;
  } else {
    return null;
  }
}
