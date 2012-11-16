// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js specific test to make sure String.hashCode behaves as
// intended.

main() {
  Expect.equals(67633152, 'a'.hashCode);
  Expect.equals(37224448, 'b'.hashCode);
}
