// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Symbols in libraries imported by the prefixed library should not be visible

library Prefix11NegativeTest.dart;

import "library12.dart" as lib12;

main() {
  var obj = new lib12.Library11(1); // Error, method should not be visible
}
