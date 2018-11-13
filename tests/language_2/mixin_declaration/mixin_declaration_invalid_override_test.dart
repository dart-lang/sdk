// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various invalid super-constraints for mixin declarations.

abstract class UnaryNum {
  num foo(num x);
}

// Overides must still be valid, wrt. signatures and types.

mixin M3 on UnaryNum {
  // M3.foo is a valid override of UnaryNum.foo
  num foo(num x) => super.foo(x) * 2;
}

// Invalid signature override (overriding optional parameter with required).
class C3 implements UnaryNum {
  // C3.foo is a valid override of UnaryNum.foo
  num foo([num x]) => x ?? 17;
}
// M3.foo is not a valid override for C3.foo.
class A3 extends C3 //
    with M3 //# 06: compile-time error
{}

// Invalid type override (overriding `int` return with `num` return).
class C4 implements UnaryNum {
  // C4.foo is a valid override of UnaryNum.foo
  int foo(num x) => x.toInt();
}
// M3.foo is not a valid override for C4.foo.
class A4 extends C4 //
    with M3 //# 07: compile-time error
{}

// It's not required to have an implementation of members which are not super-
// invoked, if the application class is abstract.
abstract class C5 {
  num foo(num x);
  num bar(num x);
}
mixin M5 on C5 {
  num baz(num x) => super.foo(x);
}
abstract class C5Foo implements C5 {
  num foo(num x) => x;
}
abstract class C5Bar implements C5 {
  num bar(num x) => x;
}

// Valid abstract class, super-invocation of foo hits implementation,
// even if bar is still abstract.
abstract class A5Foo = C5Foo with M5;
// Invalid since super-invocaton of foo does not hit concrete implementation.
abstract class _ = C5Bar with M5;  //# 08: compile-time error

class A5FooConcrete = A5Foo with C5Bar;

main() {
  Expect.equals(42, A5FooConcrete().baz(42));
}