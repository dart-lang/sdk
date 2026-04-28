// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1() {
  a
}

enum const E2() {
  a
}

enum const E3() {
  a;
  final int? b; // Error
}

enum const E4() { // Error
  a;
  int? b;
}

enum E5() {
  a;
  final int? b;
  this : b = 0;
}

enum E6(int? x) {
  a(0);
  final int? b;
  this : b = x;
}

enum E7 {
  a(0),
  b.named(1);

  final int? c;
  new(this.c);
  const new named(int? c) : this(c);
  const factory fact(int? c) => E7(c); // Error
  const factory redirect(int? c) = E7; // Error
}

enum E8 {
  a(0),
  b.named(1);

  final int? c;
  const new(this.c);
  new named(int? c) : this(c);
  factory fact(int? c) => E8(c); // Error
  factory redirect(int? c) = E8; // Error
}

enum E9 {
  a(0),
  b.named(1);

  final int? c;
  const new(this.c) {} // Error
  new named(this.c) {} // Error
}
