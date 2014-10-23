// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {}

const
    bool   /// 01: ok
    int    /// 02: static type warning, checked mode compile-time error
    String /// 03: static type warning, checked mode compile-time error
    Foo    /// 04: static type warning, checked mode compile-time error
    a = const bool.fromEnvironment('a');

const
    bool   /// 05: ok
    int    /// 06: static type warning, checked mode compile-time error
    String /// 07: static type warning, checked mode compile-time error
    Foo    /// 08: static type warning, checked mode compile-time error
    b = const bool.fromEnvironment('b');

const
    bool   /// 09: static type warning
    int    /// 10: ok
    String /// 11: static type warning
    Foo    /// 12: static type warning
    c = const int.fromEnvironment('c');

const
    bool   /// 13: static type warning
    int    /// 14: static type warning
    String /// 15: ok
    Foo    /// 16: static type warning
    d = const String.fromEnvironment('d');

main() {
  Expect.equals(a, false);
  Expect.equals(b, false);
  Expect.equals(c, null);
  Expect.equals(d, null);
}
