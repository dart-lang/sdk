// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lazyCode;

void stopTheBuck() {
  // Line number of print call must match breakpoint request
  // in deferred_code_test.dart.
  print("The debugger stops here.");
}
