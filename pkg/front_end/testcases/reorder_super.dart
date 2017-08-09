// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that super calls get reordered properly.  It exercises the
// case where the arguments to super have a type other than `dynamic`.
String events = '';

int f(x) {
  events += 'f($x)\n';
  return 0;
}

String g(x) {
  events += 'g($x)\n';
  return 'foo';
}

class B {
  num x;
  String y;
  B(this.x, this.y) {
    events += 'super($x, $y)\n';
  }
}

class C extends B {
  final z;
  C()
      : super(f(1), g(2)),
        z = f(3);
}

main() {
  new C();
  if (events != 'f(1)\ng(2)\nf(3)\nsuper(0, foo)\n') {
    throw 'Unexpected sequence of events: $events';
  }
}
