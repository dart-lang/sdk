// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N implicit_call_tearoffs`

class C {
  void call() {}
  void other() {}
}

class C2 {
  void call<T>(T arg) {}
}

void callIt(void Function() f) {
  f();
}

void callIt2(void Function(int) f) {
  f(0);
}

void Function() r1() => C(); // LINT
void Function() r2() => C().call; // OK
void Function() r3(C c) => c; // LINT
void Function() r4(C c) => c.call; // OK

void Function() r5(C? c1, C c2) {
  return c1 ?? c2; // LINT
}

void Function() r6(C? c1, C c2) {
  return c1?.call ?? c2.call; // OK
}

void Function() r7() {
  return C()..other(); // LINT
}

void Function() r8() {
  return (C()..other()).call; // OK
}

List<void Function()> r9(C c) {
  return [c]; // LINT
}

List<void Function()> r10(C c) {
  return [c.call]; // OK
}

void Function(int) r11(C2 c) => c; // LINT
void Function(int) r12(C2 c) => c.call; // OK

void main() {
  callIt(C()); // LINT
  callIt(C().call); // OK
  Function f1 = C(); // LINT
  Function f2 = C().call; // OK
  void Function() f3 = C(); // LINT
  void Function() f4 = C().call; // OK

  final c = C();
  callIt(c); // LINT
  callIt(c.call); // OK
  Function f5 = c; // LINT
  Function f6 = c.call; // OK
  void Function() f7 = c; // LINT
  void Function() f8 = c.call; // OK

  <void Function()>[
    C(), // LINT
    C().call, //OK
    c, // LINT
    c.call, // OK
  ];

  callIt2(C2()); // LINT
  callIt2(C2().call); // OK
  callIt2(C2()<int>); // LINT
  callIt2(C2().call<int>); // OK
  Function f9 = C2(); // LINT
  Function f10 = C2().call; // OK
  Function f11 = C2()<int>; // LINT
  Function f12 = C2().call<int>; // OK
  void Function<T>(T) f13 = C2(); // LINT
  void Function<T>(T) f14 = C2().call; // OK
  void Function(int) f15 = C2(); // LINT
  void Function(int) f16 = C2().call; // OK
  void Function(int) f17 = C2()<int>; // LINT
  void Function(int) f18 = C2().call<int>; // OK

  final c2 = C2();
  callIt2(c2); // LINT
  callIt2(c2.call); // OK
  callIt2(c2<int>); // LINT
  callIt2(c2.call<int>); // OK
  Function f19 = c2; // LINT
  Function f20 = c2.call; // OK
  Function f21 = c2<int>; // LINT
  Function f22 = c2.call<int>; // OK
  void Function<T>(T) f23 = c2; // LINT
  void Function<T>(T) f24 = c2.call; // OK
  void Function(int) f25 = c2; // LINT
  void Function(int) f26 = c2.call; // OK
  void Function(int) f27 = c2<int>; // LINT
  void Function(int) f28 = c2.call<int>; // OK

  <void Function(int)>[
    C2(), // LINT
    C2().call, //OK
    C2()<int>, // LINT
    C2().call<int>, //OK
    c2, // LINT
    c2.call, // OK
    c2<int>, // LINT
    c2.call<int>, // OK
  ];

  C2()<int>; // LINT
  c2<int>; // LINT
}
