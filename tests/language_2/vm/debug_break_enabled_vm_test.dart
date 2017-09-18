// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=5 --enable-debug-break --no-background-compilation

// Verify that the optimizer does not trip over the debug break (StopInstr).

test(i) {
  if (i.isOdd) {
    break "never_hit";
  }
  // "crash" is not an allowed outcome specifier.
  // Use "ok" instead and mark the status file with "Crash, OK".
  if (i == 18) {
    break "hit"; //  //# 01: ok
  }
}

void main() {
  for (var i = 0; i < 20; i += 2) {
    test(i);
  }
}
