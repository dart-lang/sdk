// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `enum` is considered a keyword and therefore invalid as the name of
// declarations.

main() {
  var enum; //# 01: compile-time error
}
