// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/52182

import "package:expect/expect.dart";

main() {
  // https://github.com/dart-lang/sdk/issues/52182
  Expect.isTrue(RegExp(r'a[^x]b', unicode: true).hasMatch('a\uD800\uDD01b'));
}
