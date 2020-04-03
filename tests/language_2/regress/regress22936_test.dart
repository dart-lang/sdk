// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 22936.

import 'package:expect/expect.dart';

bool fooCalled = false;

foo() {
  fooCalled = true;
  return null;
}

main() {
  final x = null;
  try {
    x = /*@compile-error=unspecified*/ foo();
  } on NoSuchMethodError {}
  Expect.isTrue(fooCalled);
}
