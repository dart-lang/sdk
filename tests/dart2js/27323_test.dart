// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

class C {
  noSuchMethod(i) => i.typeArguments;
}

class D {
  foo<U, V>() => [U, V];
}

@pragma('dart2js:noInline')
test(dynamic x) {
  dynamic typeArguments = x.foo<int, String>();
  Expect.equals(int, typeArguments[0]);
  Expect.equals(String, typeArguments[1]);
}

main() {
  test(new C());
  test(new D()); //# 01: ok
}
