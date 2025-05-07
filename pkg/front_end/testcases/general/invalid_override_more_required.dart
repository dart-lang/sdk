// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  foo(String x) {}
}

class Sub extends Super {
  foo(String x, Symbol y) {}
}
