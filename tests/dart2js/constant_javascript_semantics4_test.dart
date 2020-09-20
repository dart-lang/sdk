// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure we use JavaScript semantics when compiling compile-time constants.

// In checked mode, this return will not fail. If the compiler thinks
// it will, then dead code will remove the throw in the main method.
int getInt() {
  return -0.0;
}

main() {
  getInt();
  throw 'Should fail';
}
