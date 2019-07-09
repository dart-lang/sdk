// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Check places that are *not* supposed to be constant contexts,
// but which do require constant values, do not introduce an implicit const.
// Nested expressions still do.
// (Also acts as regression test for http:/dartbug.com/36533)

class C {
  final v;

  // Initializer of final field in class with const constructor.
  // Can't use `const C()`, it's a cyclic constant dependency.
  final i1 = []; //# 1: compile-time error
  final i2 = const [];
  final i3 = const [[]];

  const C([this.v]);

  // Initializer expression in generative const constructor.
  const C.c1() : v = C(); //# 2: compile-time error
  const C.c2() : v = const C();
  const C.c3() : v = const C(C());

  // Expression in redirecting generative const constuctor.
  const C.r1() : this(C()); //# 3: compile-time error
  const C.r2() : this(const C());
  const C.r3() : this(const C(C()));

  // Default value of positional optional parameter.
  static List<C> foo([
    p1 = C(), //# 4: compile-time error
    p2 = const C(),
    p3 = const C(C()),
  ]) =>
      [p2, p3];

  // Default value of named optional parameter.
  static List<C> bar({
    p1 = C(), //# 5: compile-time error
    p2 = const C(),
    p3 = const C(C()),
  }) =>
      [p2, p3];
}

void main() {
  var c = const C();
  var cc = const C(C());

  // Check that const constructors can be invoked without `const`,
  // creating new instances every time.
  var nc1 = C();
  var nc2 = C.c2();
  var nc3 = C.c3();
  var nc4 = C.r2();
  var nc5 = C.r3();
  Expect.allDistinct([nc1, nc2, nc3, nc4, nc5, c, cc]);

  // Check that const invocations create identical objects.
  Expect.identical(c, C.c2().v);
  Expect.identical(cc, C.c3().v);

  Expect.identical(c, C.r2().v);
  Expect.identical(cc, C.r3().v);

  Expect.identical(const [], C().i2);
  Expect.identical(const [[]], C().i3);

  Expect.identical(c, C.foo()[0]);
  Expect.identical(cc, C.foo()[1]);

  Expect.identical(c, C.bar()[0]);
  Expect.identical(cc, C.bar()[1]);
}
