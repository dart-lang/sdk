// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for locateSingleElement bug.

import 'package:expect/expect.dart';

class T {
  foo() => 'T.foo'; // This is the single element.
}

class C implements T {
  // There is a warning that C does not implement 'foo'.
}

@NoInline()
@AssumeDynamic()
assumeT(x) {
  // returns inferred subtype(T).
  if (x is T) return x;
  throw "Not T";
}

var log = [];
demo() {
  log.add(new T()); // T is created.
  var a = assumeT(new C()); // C is created.

  // The call "a.foo()" should be a NoSuchMethodError, but a bug in
  // locateSingleElement used to lead to T.foo being inlined.  There is a single
  // method. T.foo, that matches subtype(T), but it should be rejected because
  // not all instantiated classes that are subtype(T) have that method.
  log.add(a.foo());
}

main() {
  Expect.throws(demo);
}
