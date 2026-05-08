// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1() {
  C1.other(); // Error
}

class C2() {
  new other1(); // Error
  new other2(); // Error
}

class C3() {
  new other() : this(); // Ok
}

class C4() {
  new other() : this(); // Ok
}

class C5.primary() {
  new(); // Error
}

class C6.primary() {
  new() : this.primary(); // Ok
}

enum E1() {
  a(), b.other();
  const E1.other(); // Error
}

enum E2() {
  a(), b.other1(), c.other2();
  const new other1(); // Error
  const new other2(); // Error
}

enum E3() {
  a(), b.other();
  const new other() : this(); // Ok
}

enum E4() {
  a(), b.other();
  const new other() : this(); // Ok
}

enum E5.primary() {
  a(), b.primary();
  const new(); // Error
}

enum E6.primary() {
  a(), b.primary();
  const new() : this.primary(); // Ok
}

extension type ET1(int i) {
  ET1.other(this.i); // Ok
}

extension type E2T(int i) {
  new other(int i) : this(i); // Ok
}

extension type ET3.primary(int i) {
  new(this.i); // Ok
}

extension type ET4.primary(int i) {
  new(int i) : this.primary(i); // Ok
}