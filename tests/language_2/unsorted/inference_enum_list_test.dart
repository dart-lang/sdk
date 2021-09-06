// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

enum E1 { a, b }
enum E2 { a, b }
enum E3 { a, b }

var v = [E1.a, E2.b];

main() {
  // Test that v is `List<Enum>`, so these assignments are OK.
  v[0] = E3.a;
  List<Enum> w = v;
}
