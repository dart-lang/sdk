// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should fail to load because we are importing two libraries
// which define the same top level name foo, and we are referring to the name.

import "library1.dart"; // Defines top level variable 'foo'
import "library2.dart"; // Defines top level variable 'foo'

class X
extends baw //  //# 05: compile-time error
{}

main() {
  print(foo); //# 00: compile-time error
  print(bar()); //# 01: compile-time error
  print(baz()); //# 02: compile-time error
  print(bay()); //# 03: compile-time error
  print(main is bax); //# 04: compile-time error
  var x = new X();
  print("No error expected if ambiguous definitions are not used.");
}
