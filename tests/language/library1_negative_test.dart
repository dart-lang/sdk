// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test should fail to load because we are importing two libraries
// which define the same top level name foo, and we are referring to the name.

library Library1NegativeTest;
import "library1.dart";  // Defines top level variable 'foo'
import "library2.dart";  // Defines top level variable 'foo'


main() {
  Expect.equals(0, foo); // Reference ambiguous name 'foo'
}
