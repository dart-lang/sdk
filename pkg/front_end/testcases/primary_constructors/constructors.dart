// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  int i;

  new (this.i);
}

class C2 {
  final int i;

  const new (this.i);
}

class C3 {
  int i;

  new named({required this.i});
}

class C4 {
  final int i;

  const new named({required this.i});
}

class C5 {
  int i;

  factory (int i) => new C5._(i);

  new _ (this.i);
}

class C6 {
  final int i;

  factory (int i) => C6._(i);

  const new _ (this.i);
}


class C7 {
  int i;

  factory ({required int i}) = C7._;

  new _ ({required this.i});
}

class C8 {
  final int i;

  const factory (int i) = C8._;

  const new _ (this.i);
}

class C9 {
  int i;

  factory named (int i) => new C9._(i);

  new _ (this.i);
}

class C10 {
  final int i;

  factory named (int i) => C10._(i);

  const new _ (this.i);
}


class C11 {
  int i;

  factory named ({required int i}) = C11._;

  new _ ({required this.i});
}

class C12 {
  final int i;

  const factory named (int i) = C12._;

  const new _ (this.i);
}

class C13 {
  int i;

  new (int i) : this._(i);

  new _ (this.i);
}

class C14 {
  final int i;

  const new (int i) : this._(i);

  const new _ (this.i);
}

class C15 {
  int i;

  new named({required int i}) : this._(i);

  new _ (this.i);
}

class C16 {
  final int i;

  const new named({required int i}) : this._(i);

  const new _ (this.i);
}


main() {
  C1(0);
  new C1(1);

  C2(0);
  new C2(1);
  const C2(2);

  C3.named(i: 0);
  new C3.named(i: 1);

  C4.named(i: 0);
  new C4.named(i: 1);
  const C4.named(i: 2);

  C5(0);
  new C5(1);
  C5._(2);
  new C5._(3);

  C6(0);
  new C6(1);
  C6._(2);
  new C6._(3);
  const C6._(4);

  C7(i: 0);
  new C7(i: 1);
  C7._(i: 2);
  new C7._(i: 3);

  C8(0);
  new C8(1);
  const C8(2);
  C8._(3);
  new C8._(4);
  const C8._(5);

  C9.named(0);
  new C9.named(1);
  C9._(2);
  new C9._(3);

  C10.named(0);
  new C10.named(1);
  C10._(2);
  new C10._(3);
  const C10._(4);

  C11.named(i: 0);
  new C11.named(i: 1);
  C11._(i: 2);
  new C11._(i: 3);

  C12.named(0);
  new C12.named(1);
  const C12.named(2);
  C12._(3);
  new C12._(4);
  const C12._(5);

  C13(0);
  new C13(1);
  C13._(2);
  new C13._(3);

  C14(0);
  new C14(1);
  const C14(2);
  C14._(3);
  new C14._(4);
  const C14._(5);

  C15.named(i: 0);
  new C15.named(i: 1);
  C15._(2);
  new C15._(3);

  C16.named(i: 0);
  new C16.named(i: 1);
  const C16.named(i: 2);
  C16._(3);
  new C16._(4);
  const C16._(5);
}
