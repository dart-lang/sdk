// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.


// Expect a compile-time error below:
// No default values allowed in closure type definitions.
typedef void Callback([String msg = ""]);

main() {
  Expect.equals(true, false);
}
