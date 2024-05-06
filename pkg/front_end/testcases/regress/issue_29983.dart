// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f() sync* {
  // Error: Returning value from generator: forbidden.
  return missing;
}

// Error: Arrow generator: forbidden.
g() sync* => dummy;

h() sync* {
  // OK: Local function returning value within generator: permitted.
  (() => "return")();
}

main() {}
