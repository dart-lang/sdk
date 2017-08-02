// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_string_buffer`

class A {
  String buffer;

  void foo(int n) {
    int aux = n;
    while (aux-- > 0) {
      buffer += 'a'; // LINT
    }
  }

  void bar(int count) {
    int auxCount = count;
    while (auxCount-- > 0) {
      buffer += baz(); // LINT
    }
  }

  String baz() {
    buffer = buffer + buffer;
    return buffer;
  }
}

void badStringInterpolation() {
  String buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = '${buffer}a'; // LINT
  }
}

void goodStringInterpolation() {
  String buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = 'a$buffer'; // OK
  }

}

void foo() {
  String buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer += 'a'; // LINT
  }
}

void foo2() {
  String buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = '${buffer + 'a'}a'; // LINT
  }
}

void foo3() {
  String buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = buffer + 'a'; // LINT
  }
}

void bar() {
  String buffer = '';
  while (buffer.length < 10) {
    buffer += 'a'; // LINT
  }
}

void bar2() {
  String buffer = '';
  do {
    buffer += 'a'; // LINT
  } while (buffer.length < 10);
}

void bar3() {
  String buffer = '';
  for (final s in [ 'a', 'b']) {
    buffer += s; // LINT
  }
}

void bar4() {
  String buffer = '';
  for (final s in [ 'a', 'b']) {
    (buffer += s); // LINT
  }
}

void bar5() {
  for (final s in [ 'a', 'b']) {
    String str;
    str += s; // OK
  }
}

class B {
  operator +(B other) => this;

  B m1() {
    B b = new B();
    for (int i = 0; i < 10; i++) {
      b = b + this; // OK
    }
    return b;
  }

  B m2() {
    B b = new B();
    for (int i = 0; i < 10; i++) {
      b += this; // OK
    }
    return b;
  }
}
