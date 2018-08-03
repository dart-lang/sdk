// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to generate wrong code for
// it. The bug happened in the SSA type propagation.

class A {
  next() => new B();
  doIt() => null;
  bool get isEmpty => false;
  foo() => 42;
  bar() => 54;
}

bool entered = false;

class B extends A {
  foo() => 54;
  doIt() => new A();
  bool get isEmpty => true;
  bar() => entered = true;
}

// (1) At initialization phase of the type propagation, [a] would be
//     marked as [exact A].
// (2) Will make the loop phi [b] typed [null, exact A].
// (3) Will create a [HTypeKnown] [exact A] for [b].
// (4) Will create a [HTypeKnown] [exact A] for [b] and update users
//     of [b] to use this [HTypeKnown] instead.
// (5) [a] will be updated to [subclass A].
// (6) Will change the [HTypeKnown] of [b] from [exact A] to [subclass A].
// (7) Receiver is [subclass A] and it will refine it to
//     [subclass A]. We used to wrongly assume there was
//     no need to update the [HTypeKnown] created in (3).
// (8) Consider that bar is called on an [exact A] (the [HTypeKnown]
//     created in (3)) and remove the call because it does not have
//     any side effects.

main() {
  var a = new A();
  for (var i in [42]) {
    a = a.next();
  }

  // (1, 5)

  var b = a;
  while (b.isEmpty) {
    // (4, 6)
    b.foo(); // (3, 7)
    b.bar(); // (8)
    b = b.doIt(); // (2)
  }

  if (!entered) throw 'Test failed';
}
