// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  static const member = C();
  const C();
}

void test(dynamic d) {
  d == .member;
  d != .member;
}
