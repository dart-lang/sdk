// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var a = [null];

typedef void func();

main() {
  func local = a[0];
  Expect.isFalse(local is func);
  a[0] = 42;
}
