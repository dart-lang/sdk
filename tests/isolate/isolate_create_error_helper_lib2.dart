// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate.create.error_helper2_lib;

// This library has a main method with wrong parameters.

void main(a, b, c) {
  print("Three required positional parameters: $a, $b, $c");
}
