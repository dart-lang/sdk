// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

base class A {
  void _m(int _) {}
  void public() => _m(0);
}

abstract base class B extends A {
  void _m(num _);
}
