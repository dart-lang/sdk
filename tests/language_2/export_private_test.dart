// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that private dart:_ libraries cannot be imported.

export "dart:_internal"; // //# 01: compile-time error

main() {
  print("Done.");
}
