// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that "class" cannot be used as identifier.

class foo {}

void main() {
  int class = 10; //# 01: syntax error
  print("$class"); //# 02: compile-time error
}
