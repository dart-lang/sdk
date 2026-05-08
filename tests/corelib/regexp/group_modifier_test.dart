// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var r = new RegExp(r"(?i:hello) world");
  Expect.isTrue(r.hasMatch("hello world"));
  Expect.isTrue(r.hasMatch("HELLO world"));
  Expect.isFalse(r.hasMatch("hello WORLD"));
  Expect.isFalse(r.hasMatch("HELLO WORLD"));

  r = new RegExp(r"(?-i:hello) world", caseSensitive: false);
  Expect.isTrue(r.hasMatch("hello world"));
  Expect.isFalse(r.hasMatch("HELLO world"));
  Expect.isTrue(r.hasMatch("hello WORLD"));
  Expect.isFalse(r.hasMatch("HELLO WORLD"));
}
