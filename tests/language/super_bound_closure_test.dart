// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@AssumeDynamic()
@NoInline()
confuse(x) => x;

class A {
  bar([var optional = 1]) => 498 + optional;
  bar2({namedOptional: 2}) => 40 + namedOptional;
  bar3(x, [var optional = 3]) => x + 498 + optional;
  bar4(x, {namedOptional: 4}) => 422 + x + namedOptional;

  // Gee is the same as bar, but we make sure that gee is used. Potentially
  // this yields different code if the redirecting stub exists.
  gee([var optional = 1]) => 498 + optional;
  gee2({namedOptional: 2}) => 40 + namedOptional;
  gee3(x, [var optional = 3]) => x + 498 + optional;
  gee4(x, {namedOptional: 4}) => 422 + x + namedOptional;

  // Use identifiers that could be intercepted.
  add([var optional = 33]) => 1234 + optional;
  trim({namedOptional: 22}) => 1313 + namedOptional;
  sublist(x, [optional = 44]) => 4321 + optional + x;
  splitMapJoin(x, {onMatch: 55, onNonMatch: 66}) =>
      111 + x + onMatch + onNonMatch;

  // Other interceptable identifiers, but all of them are used.
  shuffle([var optional = 121]) => 12342 + optional;
  toList({growable: 2233}) => 13131 + growable;
  lastIndexOf(x, [optional = 424]) => 14321 + optional + x;
  lastWhere(x, {orElse: 555}) => x + 1213 + 555;
}

class B extends A {
  // The closure `super.bar` is invoked without the optional argument.
  // Dart2js must not generate a `bar$0 => bar$1(null)` closure, since that
  // would redirect to B's `bar$1`. Instead it must enforce that `bar$0` in
  // `A` redirects to A's bar$1.
  foo() => confuse(super.bar)();
  foo2() => confuse(super.bar)(2);
  foo3() => confuse(super.bar2)();
  foo4() => confuse(super.bar2)(namedOptional: 77);
  foo5() => confuse(super.bar3)(-3);
  foo6() => confuse(super.bar3)(-11, -19);
  foo7() => confuse(super.bar4)(0);
  foo8() => confuse(super.bar4)(3, namedOptional: 77);

  fooGee() => confuse(super.gee)();
  fooGee2() => confuse(super.gee)(2);
  fooGee3() => confuse(super.gee2)();
  fooGee4() => confuse(super.gee2)(namedOptional: 77);
  fooGee5() => confuse(super.gee3)(-3);
  fooGee6() => confuse(super.gee3)(-11, -19);
  fooGee7() => confuse(super.gee4)(0);
  fooGee8() => confuse(super.gee4)(3, namedOptional: 77);

  fooIntercept() => confuse(super.add)();
  fooIntercept2() => confuse(super.add)(2);
  fooIntercept3() => confuse(super.trim)();
  fooIntercept4() => confuse(super.trim)(namedOptional: 77);
  fooIntercept5() => confuse(super.sublist)(-3);
  fooIntercept6() => confuse(super.sublist)(-11, -19);
  fooIntercept7() => confuse(super.splitMapJoin)(0);
  fooIntercept8() => confuse(super.splitMapJoin)(3, onMatch: 77, onNonMatch: 8);

  fooIntercept21() => confuse(super.shuffle)();
  fooIntercept22() => confuse(super.shuffle)(2);
  fooIntercept23() => confuse(super.toList)();
  fooIntercept24() => confuse(super.toList)(growable: 77);
  fooIntercept25() => confuse(super.lastIndexOf)(-3);
  fooIntercept26() => confuse(super.lastIndexOf)(-11, -19);
  fooIntercept27() => confuse(super.lastWhere)(0);
  fooIntercept28() => confuse(super.lastWhere)(3, orElse: 77);

  bar([var optional]) => -1; //       //# 01: static type warning
  bar2({ namedOptional }) => -1; //   //# 01: continued
  bar3(x, [var optional]) => -1; //   //# 01: continued
  bar4(x, { namedOptional }) => -1; //# 01: continued

  gee([var optional]) => -1; //       //# 01: continued
  gee2({ namedOptional }) => -1; //   //# 01: continued
  gee3(x, [var optional]) => -1; //   //# 01: continued
  gee4(x, { namedOptional }) => -1; //# 01: continued

  add([var optional = 33]) => -1;
  trim({namedOptional: 22}) => -1;
  sublist(x, [optional = 44]) => -1;
  splitMapJoin(x, {onMatch: 55, onNonMatch: 66}) => -1;

  shuffle([var optional = 121]) => -1;
  toList({growable: 2233}) => -1;
  lastIndexOf(x, [optional = 424]) => -1;
  lastWhere(x, {orElse: 555}) => -1;
}

main() {
  var list = [new A(), new B(), [], "foo"];
  var a = list[confuse(0)];
  var b = list[confuse(1)];
  var ignored = list[confuse(2)];
  var ignored2 = list[confuse(3)];

  var t = b.gee() + b.gee2() + b.gee3(9) + b.gee4(19);
  Expect.equals(-4, t); //# 01: continued
  t = b.shuffle() + b.toList() + b.lastIndexOf(1) + b.lastWhere(2);
  Expect.equals(-4, t);

  Expect.equals(499, b.foo()); // //# 01: continued
  Expect.equals(500, b.foo2()); //# 01: continued
  Expect.equals(42, b.foo3()); // //# 01: continued
  Expect.equals(117, b.foo4()); //# 01: continued
  Expect.equals(498, b.foo5()); //# 01: continued
  Expect.equals(468, b.foo6()); //# 01: continued
  Expect.equals(426, b.foo7()); //# 01: continued
  Expect.equals(502, b.foo8()); //# 01: continued

  Expect.equals(499, b.fooGee()); // //# 01: continued
  Expect.equals(500, b.fooGee2()); //# 01: continued
  Expect.equals(42, b.fooGee3()); // //# 01: continued
  Expect.equals(117, b.fooGee4()); //# 01: continued
  Expect.equals(498, b.fooGee5()); //# 01: continued
  Expect.equals(468, b.fooGee6()); //# 01: continued
  Expect.equals(426, b.fooGee7()); //# 01: continued
  Expect.equals(502, b.fooGee8()); //# 01: continued

  Expect.equals(1267, b.fooIntercept());
  Expect.equals(1236, b.fooIntercept2());
  Expect.equals(1335, b.fooIntercept3());
  Expect.equals(1390, b.fooIntercept4());
  Expect.equals(4362, b.fooIntercept5());
  Expect.equals(4291, b.fooIntercept6());
  Expect.equals(232, b.fooIntercept7());
  Expect.equals(199, b.fooIntercept8());

  Expect.equals(12463, b.fooIntercept21());
  Expect.equals(12344, b.fooIntercept22());
  Expect.equals(15364, b.fooIntercept23());
  Expect.equals(13208, b.fooIntercept24());
  Expect.equals(14742, b.fooIntercept25());
  Expect.equals(14291, b.fooIntercept26());
  Expect.equals(1768, b.fooIntercept27());
  Expect.equals(1771, b.fooIntercept28());
}
