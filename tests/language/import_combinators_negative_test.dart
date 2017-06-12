// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program importing with show/hide combinators.

library importCombinatorsNegativeTest;

import "import1_lib.dart" show hide, show hide ugly;

main() {
  print(hide);
  print(show);
  print(ugly); // Resolution error, identifier 'ugly ' is hidden.
}
