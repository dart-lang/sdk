// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
  foo() => 42;
}

class B {
  foo() => 42;
}

main() {
  // Use an array to defeat type inferencing.
  var array = [new A(), new A(), new B(), new B()];
  var set = new Set.from(array.map((a) => a.foo));
  Expect.equals(array.length, set.length);
  set.addAll(array.map((a) => a.foo));
  Expect.equals(array.length, set.length);

  for (int i = 0; i < array.length; i += 2) {
    Expect.isTrue(set.contains(array[i].foo));
    Expect.equals(array[i], array[i]);
    Expect.equals(array[i].foo, array[i].foo);
    Expect.equals(array[i].foo.hashCode, array[i].foo.hashCode);
    for (int j = 0; j < array.length; j++) {
      if (i == j) continue;
      Expect.notEquals(array[i].foo, array[j].foo);
    }
  }

  // Try with dart2js intercepted types.
  array = ['foo', 'bar', [], [], const []];
  set = new Set.from(array.map((a) => a.indexOf));
  Expect.equals(array.length, set.length);
  set.addAll(array.map((a) => a.indexOf));
  Expect.equals(array.length, set.length);

  for (int i = 0; i < array.length; i += 2) {
    Expect.isTrue(set.contains(array[i].indexOf));
    Expect.equals(array[i], array[i]);
    Expect.equals(array[i].indexOf, array[i].indexOf);
    Expect.equals(array[i].indexOf.hashCode, array[i].indexOf.hashCode);
    for (int j = 0; j < array.length; j++) {
      if (i == j) continue;
      Expect.notEquals(array[i].indexOf, array[j].indexOf);
    }
  }

  array = [const A(), const A()];
  set = new Set.from(array.map((a) => a.foo));
  Expect.equals(1, set.length);
  set.addAll(array.map((a) => a.foo));
  Expect.equals(1, set.length);

  Expect.isTrue(set.contains(array[0].foo));
  Expect.equals(array[0].foo, array[0].foo);
  Expect.equals(array[0].foo.hashCode, array[0].foo.hashCode);
  Expect.equals(array[0].foo, array[1].foo);
  Expect.equals(array[0].foo.hashCode, array[1].foo.hashCode);

  array = [const [], const []];
  set = new Set.from(array.map((a) => a.indexOf));
  Expect.equals(1, set.length);
  set.addAll(array.map((a) => a.indexOf));
  Expect.equals(1, set.length);

  Expect.isTrue(set.contains(array[0].indexOf));
  Expect.equals(array[0].indexOf, array[0].indexOf);
  Expect.equals(array[0].indexOf.hashCode, array[0].indexOf.hashCode);
  Expect.equals(array[0].indexOf, array[1].indexOf);
  Expect.equals(array[0].indexOf.hashCode, array[1].indexOf.hashCode);
}
