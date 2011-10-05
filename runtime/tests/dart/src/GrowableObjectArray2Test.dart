// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test GrowableArray.dart.
// VMOptions=--expose_core_impl

class GrowableObjectArray2Test {
  static testMain() {
    var g = new GrowableObjectArray();
    Expect.equals(true, g is Array);
    Expect.equals(true, g is GrowableObjectArray);
    Expect.equals(true, g.isEmpty());
    for (int i = 0; i < 100; i++) {
      g.add(1);
    }
    g.add(1001);
    Expect.equals(101, g.length);
    Expect.equals(1001, g[100]);
    Expect.equals(false, g.isEmpty());
    Expect.equals(1001, g.last());
    Expect.equals(1001, g.removeLast());
    Expect.equals(100, g.length);

    var f = new GrowableObjectArray();
    var object_array = new Array(20);
    for (int i = 0; i < object_array.length; i++) {
      f.add(2);
      object_array[i] = 5;
    }
    object_array.copyFrom(f, 0, 0, f.length);
    for (int i = 0; i < f.length; i++) {
      Expect.equals(2, object_array[i]);
    }
    f.copyFrom(g, 10, 0, 2);
    Expect.equals(20, f.length);

    bool exception_caught = false;
    try {
      var elem = g[g.length];
    } catch (IndexOutOfRangeException e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    Array<int> plain_array = [4, 3, 9, 12, -4, 9];
    GrowableObjectArray h = new GrowableObjectArray.withCapacity(4);
    plain_array.forEach((elem) { h.add(elem); });
    int compare(a, b) {
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    }
    h.sort(compare);
    Expect.equals(6, h.length);
    Expect.equals(-4, h[0]);
    Expect.equals(12, h[h.length - 1]);
    Set<int> t = new Set<int>.from(h);
    Expect.equals(true, t.contains(9));
    Expect.equals(true, t.contains(-4));
    Expect.equals(false, t.contains(-3));
    Expect.equals(5, t.length);

    h.clear();
    Array array = const [0, 1, 2, 3, 4];
    h.addAll(array);
    Expect.equals(5, h.length);
  }
}

main() {
  GrowableObjectArray2Test.testMain();
}
