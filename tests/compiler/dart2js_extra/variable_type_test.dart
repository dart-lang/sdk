// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int foo(int i) {
  i = 'fisk';  /// 01: static type warning
  return 'kat';  /// 02: static type warning
}

main() {
  foo(42);
  foo('hest');  /// 03: static type warning
}
