// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program importing the core library explicitly.

library ImportCollectionNoPrefixTest.dart;

import "dart:collection";

main() {
  var e = new SplayTreeMap();
  print('"dart:collection" imported, $e allocated');
}
