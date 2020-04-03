// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// This test checks that annotations on enum values are preserved by the
// compiler.

const int hest = 42;

class Fisk<T> {
  final T x;
  const Fisk.fisk(this.x);
}

enum Foo {
  @hest
  bar,
  @Fisk.fisk(hest)
  baz,
  cafebabe,
}

main() {}
