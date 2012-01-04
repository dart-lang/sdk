// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that a method reference is not an acceptable compile time constant


topMethod() { }

class ConstInit7NegativeTest {
  classMethod([var x = 
    topMethod // Error: not a compile time const.
  ]) {}
}

main() {
 new ConstInit7NegativeTest();
}
