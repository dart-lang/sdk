// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing isolate communication with
// typed objects.
// VMOptions=--disassemble --no-background-compilation --enable-malloc-hooks=false
// VMOptions=--disassemble --print-variable-descriptors --no-background-compilation --enable-malloc-hooks=false

// Tests proper object recognition in disassembler.

f(x) {
  return "foo";
}

main() {
  print(f(0));
}
