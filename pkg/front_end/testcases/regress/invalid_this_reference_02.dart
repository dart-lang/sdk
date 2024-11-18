// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Foo(String x) {
  static const int x1 = 42;
  int x2 = 42;

  int bar1({int baz = x2}) => 42;
  int bar2({int baz = x /* oops forgot the 1 */}) => 42;
}
