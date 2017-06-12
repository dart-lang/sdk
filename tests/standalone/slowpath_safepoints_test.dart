// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that safepoints associated with slowpaths don't mark non-existing values
// alive.
// VMOptions=--optimization-counter-threshold=5 --no-inline_alloc --gc_at_instance_allocation=_Double --no-background-compilation

class C {
  final next;
  C(this.next);
}

noop(a1, a2, a3, a4, a5, a6, a7, a8, a9) => 0;

crash(f, i) {
  final obj1 = new C(null);
  final obj2 = new C(obj1);
  final obj3 = new C(obj2);
  final obj4 = new C(obj3);
  final obj5 = new C(obj4);
  final obj6 = new C(obj5);
  final obj7 = new C(obj6);
  final obj8 = new C(obj7);
  final obj9 = new C(obj8);

  f(obj1, obj2, obj3, obj4, obj5, obj6, obj7, obj8, obj9);
  f(obj1, obj2, obj3, obj4, obj5, obj6, obj7, obj8, obj9);

  final d1 = (i + 0).toDouble();
  final d2 = (i + 1).toDouble();
  final d3 = (i + 2).toDouble();
  final d4 = (i + 3).toDouble();
  final d5 = (i + 4).toDouble();
  final d6 = (i + 5).toDouble();
  final d7 = (i + 6).toDouble();
  final d8 = (i + 7).toDouble();
  final d9 = (i + 8).toDouble();

  f(d1, d2, d3, d4, d5, d6, d7, d8, d9);
  f(d1, d2, d3, d4, d5, d6, d7, d8, d9);
}

main() {
  for (var i = 0; i < 10; i++) {
    print(i);
    crash(noop, 10);
  }
}
