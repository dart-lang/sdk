// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Imported library has wrong order of import and source tags.

library Script1NegativeTest.dart;

import "script1_negative_lib.dart";

main() {
  print("Should not reach here.");
}
