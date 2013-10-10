// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that malformed types used in extends, implements, and with clauses
// cause compile-time errors.

import 'package:expect/expect.dart';

class A<T> {}

class C
  extends Unresolved /// 01: compile-time error
  extends A<Unresolved> /// 02: static type warning
  extends Object with Unresolved /// 03: compile-time error
  extends Object with A<Unresolved> /// 04: static type warning
  implements Unresolved /// 05: compile-time error
  implements A<Unresolved> /// 06: static type warning
  <A> extends A<int> /// 07: compile-time error
  <A> extends A<Unresolved> /// 08: compile-time error
  <A> extends Object with A<int> /// 09: compile-time error
  <A> extends Object with A<Unresolved> /// 10: compile-time error
  <A> implements A<int> /// 11: compile-time error
  <A> implements A<Unresolved> /// 12: compile-time error
{

}

void main() {
  new C();
  Expect.isTrue(new C() is A<String> && new C() is A<int>); /// 02: continued
  Expect.isTrue(new C() is A<String> && new C() is A<int>); /// 04: continued
  Expect.isTrue(new C() is A<String> && new C() is A<int>); /// 06: continued
}