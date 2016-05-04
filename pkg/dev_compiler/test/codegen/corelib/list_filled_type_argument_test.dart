// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var a = new List<int>.filled(42, 42);
  Expect.isTrue(a is List<int>);
  Expect.isFalse(a is List<String>);

  a = new List<int>.filled(42, 42, growable: true);
  Expect.isTrue(a is List<int>);
  Expect.isFalse(a is List<String>);
}
