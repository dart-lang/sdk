// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program importing the core library explicitly.

#library("ImportCoreImplNoPrefixTest.dart");
#import("dart:coreimpl");

main() {
  var e = new SplayTreeMap();
  print('"dart:coreimpl" imported, $e allocated');
}
