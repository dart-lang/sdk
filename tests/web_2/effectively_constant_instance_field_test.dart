// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--omit-implicit-checks

import 'package:expect/expect.dart';

class C {
  const C();
}

class A {
  var field = const C();
}

class B {
  var field;
}

@pragma('dart2js:noInline')
test(o) => o.field;

main() {
  Expect.isNotNull(test(new A()));
  Expect.isNull(test(new B()));
}
