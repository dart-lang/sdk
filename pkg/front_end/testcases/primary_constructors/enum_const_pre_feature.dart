// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.10

enum E7 {
  a(0), // Error
  b.named(1);

  final int? c;
  E7(this.c); // Error
  const E7.named(int? c) : this(c); // Error
  const factory E7.fact(int? c) => E7(c); // Error
  const factory E7.redirect(int? c) = E7; // Error
}

enum E8 {
  a(0),
  b.named(1); // Error

  final int? c;
  const E8(this.c);
  E8.named(int? c) : this(c); // Error
  factory E8.fact(int? c) => E8(c); // Error
  factory E8.redirect(int? c) = E8; // Error
}

enum E9 {
  a(0),
  b.named(1);

  final int? c;
  const E9(this.c) {} // Error
  E9.named(this.c) {} // Error
}
