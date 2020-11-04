// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_null_checks`

int? i;

int? j1 = i!; // LINT
int? j2 = (i!); // LINT

m1a(int? p) => m1a(i!); // LINT
m1b(int? p) => m1b((i!)); // LINT

m2a({required String s, int? p}) => m2a(p: i!, s: ''); // LINT
m2b({required String s, int? p}) => m2b(p: (i!), s: ('')); // LINT

class A {
  A([int? p]) {
    A(i!); // LINT
    A((i!)); // LINT
  }

  m1a(int? p) => m1a(i!); // LINT
  m1b(int? p) => m1b((i!)); // LINT

  m2a({required String s, int? p}) => m2a(p: i!, s: ''); // LINT
  m2b({required String s, int? p}) => m2b(p: (i!), s: ('')); // LINT

  m3a(int? p) => p!; // OK
  m3b(int? p) {
    return p!; // OK
  }

  operator +(int? p) => A() + i!; // LINT
  operator -(int? p) => A() + (i!); // LINT
}

int? f1(int? i) => i!; // LINT
int? f2(int? i) { return i!; } // LINT

f3(int? i) {
  int? v;
  v = i!; // LINT
}

f4(int? p) {
  int? v;
  v ??= 1;
  v += p!; // OK
}

autoPromote() {
  int? v2;
  v2 = v2!; // OK
}

f5(int? p) {
  int? v1;
  v1 ??= p!; // OK
}

f6(int? p) {
  return B() + p!; // OK
}

