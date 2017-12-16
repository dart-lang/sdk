// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error*/

class C {
  var x;
  void f() {}
}

void test(C c) {
  c.x;
  c. /*@error=UndefinedGetter*/ y;
  c.f();
  c. /*@error=UndefinedMethod*/ g();
  c.x = null;
  c. /*@error=UndefinedSetter*/ y = null;
}

main() {}
