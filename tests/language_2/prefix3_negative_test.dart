// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// Using the same prefix name while importing two different libraries is
// not an error but both library1.dart and library2.dart define 'foo' which
// results in a duplicate definition error.

library Prefix3NegativeTest.dart;

import "library1.dart" as lib2; // defines 'foo'.
import "library2.dart" as lib2; // also defines 'foo'.

main() {
  lib2.foo = 1;
}
