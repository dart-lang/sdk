// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A1:checks=[],instance*/
class A1 {}

// Constructor calls are always statically invoked, so there is no checks at the
// entry and the `Test1` constructor does not cause any checks.
/*class: B1:checks=[],instance*/
class B1 implements A1 {}

/*class: Test1:checks=[],instance*/
class Test1 {
  A1 x;
  @noInline
  Test1(this.x);
}

/*class: A2:checks=[],instance*/
class A2 {}

// Constructor bodies are always statically resolved, so there is no checks at
// the entry and the `Test2` constructor body does not cause any checks.
/*class: B2:checks=[],instance*/
class B2 implements A2 {}

/*class: Test2:checks=[]*/
abstract class Test2 {
  @noInline
  Test2(A2 x) {
    print(x);
  }
}

/*class: Use:checks=[],instance*/
class Use extends Test2 {
  Use.A2() : super(new A2());
  Use.B2() : super(new B2());
}

main() {
  new Test1(new A1());
  new Test1(new B1());
  new Test1(null);

  new Use.A2();
  new Use.B2();
}
