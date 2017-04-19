// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that an inline function type inside a `Function` type isn't a
// parser error.

typedef F = int Function(int f(String x));

main() {
  F f = null;
  String Function(String g(int y)) g = null;
}
