// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
  indexOf(item) => 42;

  // This call get:indexOf has a known receiver type, so is is potentially
  // eligible for a dummy receiver optimization.
  getIndexOf() => this.indexOf;
}

var getIndexOfA = (a) => a.getIndexOf();

var getter1 = (a) => a.indexOf;

var getter2 = (a) {
  // Known interceptor.
  if (a is String) return a.indexOf;

  // Call needs to be indirect to avoid inlining.
  if (a is A) return getIndexOfA(a);

  return a.indexOf;
};

var inscrutable;

main() {
  inscrutable = (x) => x;

  var array = ['foo', 'bar', [], [], new A(), new A(), const [], const A()];

  array = inscrutable(array);
  getter1 = inscrutable(getter1);
  getter2 = inscrutable(getter2);
  getIndexOfA = inscrutable(getIndexOfA);

  var set = new Set.from(array.map(getter1));

  // Closures should be distinct since they are closures bound to distinct
  // objects.
  Expect.equals(array.length, set.length);

  // And repeats should be equal to existing closures and add no new elements.
  set.addAll(array.map(getter1));
  Expect.equals(array.length, set.length);

  // And closures created in different optimization contexts should be equal.
  set.addAll(array.map(getter2));
  Expect.equals(array.length, set.length);

  for (int i = 0; i < array.length; i++) {
    Expect.equals(array[i], array[i]);

    Expect.isTrue(set.contains(getter1(array[i])));

    Expect.equals(getter1(array[i]), getter1(array[i]));
    Expect.equals(getter1(array[i]), getter2(array[i]));
    Expect.equals(getter2(array[i]), getter1(array[i]));
    Expect.equals(getter2(array[i]), getter2(array[i]));

    Expect.equals(getter1(array[i]).hashCode, getter1(array[i]).hashCode);
    Expect.equals(getter1(array[i]).hashCode, getter2(array[i]).hashCode);
    Expect.equals(getter2(array[i]).hashCode, getter1(array[i]).hashCode);
    Expect.equals(getter2(array[i]).hashCode, getter2(array[i]).hashCode);

    for (int j = 0; j < array.length; j++) {
      if (i == j) continue;

      Expect.notEquals(getter1(array[i]), getter1(array[j]));
      Expect.notEquals(getter1(array[i]), getter2(array[j]));
      Expect.notEquals(getter2(array[i]), getter1(array[j]));
      Expect.notEquals(getter2(array[i]), getter2(array[j]));
    }
  }
}
