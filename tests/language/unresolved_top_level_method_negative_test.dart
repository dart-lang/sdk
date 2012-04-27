// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an unresolved method call at the top level does not crash
// the parser.

var a = b();

main() {
  print(a);
}
