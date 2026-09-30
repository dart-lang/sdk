// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const annotation = 0;

class C1 {
  final int v;

  const new named(this.v);

  const factory fact(int v) = C1.named;

  @annotation
  augment const factory fact(int v);
}

class C2 {
  final int v;

  const new foo(this.v);

  @annotation
  const factory fact(int v);

  augment const factory fact(int v) = C2.foo;
}

extension type const ET1(int v) {
  const factory fact(int v) = ET1.new;

  @annotation
  augment const factory fact(int v);
}

extension type const ET2(int v) {
  @annotation
  const factory fact(int v);

  augment const factory fact(int v) = ET2.new;
}