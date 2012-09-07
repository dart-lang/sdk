// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When attempting to call a nonexistent static method, getter or setter, check
// that a NoSuchMethodException is thrown.

class C {}

main() {
  Expect.throws(() => C.hest = 1, (e) => e is NoSuchMethodException); /// 01: static type warning
  Expect.throws(() => C.hest, (e) => e is NoSuchMethodException);     /// 02: static type warning
  Expect.throws(() => C.hest(), (e) => e is NoSuchMethodException);   /// 03: static type warning
}
