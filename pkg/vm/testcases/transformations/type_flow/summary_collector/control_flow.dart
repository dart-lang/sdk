// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {}

class C2 {}

class C3 {}

class C4 {}

enum TestEnum { v1, v2 }

foo(x) {}
bar(x) {}
baz(x) {}

sequence() {
  dynamic x = C1();
  x = C2();
  x = C3();
  return x;
}

if1(bool cond) {
  dynamic x = C1();
  if (cond) {
    x = C2();
    foo(x);
  }
  return x;
}

if2(bool cond1, bool cond2) {
  dynamic x = C1();
  if (cond1) {
    foo(x);
  } else {
    x = C2();
    if (cond2) {
      bar(x);
    }
  }
  return x;
}

if3(bool cond1, bool cond2) {
  dynamic x = C1();
  if (foo(x = C2()) || foo(x = C3())) {
    bar(x);
  }
  return x;
}

if4() {
  dynamic x = C1();
  if (foo(x = C2()) && foo(x = C3())) {
    bar(x);
  }
  return x;
}

if5(bool cond) {
  dynamic x = C1();
  if (cond) {
    x = C2();
    return;
  }
  foo(x);
}

if6a(bool x) {
  if (x) {
    foo(x);
  } else {
    bar(x);
  }
  baz(x);
}

if6b(x) {
  if (x) {
    foo(x);
  } else {
    bar(x);
  }
  baz(x);
}

if7(int x, String y, dynamic z) {
  if ((x == 5) && (y == 'hi') && (z != null)) {
    foo(x);
    foo(y);
    foo(z);
  }
}

if8(x) {
  if (x is String) {
    foo(x);
    x = 42;
  }
}

if9(TestEnum x) {
  if (x == TestEnum.v1) {
    foo(x);
  }
}

conditional1(bool cond1, bool cond2) {
  dynamic x = C1();
  dynamic y = foo(x = C2()) ? (x = C3()) : (x = C4());
  foo(x);
  bar(y);
}

conditional2(bool cond1, bool cond2) {
  dynamic x = C1();
  dynamic y = foo(x = C2()) ? (x = C3()) : foo([x = C4(), throw 'error']);
  foo(x);
  bar(y);
}

loop1() {
  dynamic x = C1();
  while (foo(x)) {
    var y = C2();
    bar(x);
    x = y;
  }
  return x;
}

loop2() {
  dynamic x = C1();
  do {
    foo(x);
    x = C2();
    bar(x);
  } while (bar(x = C3()));
  return x;
}

loop3() {
  dynamic x = C1();
  while (foo(x = C2())) {
    var y = C3();
    bar(x);
    x = y;
  }
  return x;
}

loop4() {
  dynamic x = C1();
  for (var y in [foo(x = C2())]) {
    foo(x);
    x = C3();
  }
  return x;
}

loop5() {
  dynamic x = C1();
  while (foo(x)) {
    x = C2();
    if (bar(x)) {
      break;
    }
    x = C3();
  }
  return x;
}

loop6() {
  dynamic x = C1();
  while (foo(x)) {
    x = C2();
    if (bar(x)) {
      continue;
    }
    x = C3();
  }
  return x;
}

try1() {
  dynamic x = C1();
  try {
    x = C2();
  } catch (e, st) {
    foo(x);
    x = C3();
  } finally {
    bar(x);
    x = C4();
  }
  return x;
}

closure1() {
  dynamic x = C1();
  foo(x);
  foo(() {
    bar(x);
  });
  x = C2();
}

closure2() {
  dynamic x = C1();
  foo(x);
  foo(() {
    x = C2();
  });
  return x;
}

switch1(int selector) {
  dynamic x = C1();
  switch (selector) {
    case 1:
      x = C2();
      break;
    case 2:
      x = C3();
  }
  return x;
}

switch2(int selector) {
  dynamic x = C1();
  switch (selector) {
    case 1:
      x = C2();
      break;
    default:
      x = C3();
  }
  return x;
}

switch3(int selector) {
  dynamic x = C1();
  switch (selector) {
    case 1:
      x = C2();
      continue L2;
    L2:
    case 2:
      foo(x);
      x = C3();
      break;
  }
  return x;
}

void cast1(x) {
  foo(x as C1);
  bar(x);
}

main() {}
