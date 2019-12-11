// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  int Function(Null) f = (x) => 1; // Runtime type is int Function(Object)
  Expect.isTrue(f is int Function(Null));
  Expect.isTrue(f is int Function(String));
  Expect.isTrue(f is int Function(Object));
  int Function(String) g = (x) => 1; // Runtime type is int Function(String)
  Expect.isTrue(g is int Function(Null));
  Expect.isTrue(g is int Function(String));
  Expect.isFalse(g is int Function(Object));
}
