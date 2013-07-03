// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var cyclicStatic = cyclicStatic + 1;

cyclicInitialization() {
  return cyclicStatic;
}

main() {
  bool hasThrown = false;
  try {
    cyclicStatic + 1;
  } catch(e) {
    hasThrown = true;
    Expect.isTrue(e.stackTrace is StackTrace,
                  "$e doesn't have a non-null stack trace");
  }
  Expect.isTrue(hasThrown);
}
