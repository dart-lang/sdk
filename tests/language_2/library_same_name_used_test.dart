// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'X' is defined as an abstract class in lib1 and a class implementing that
// abstract class in lib2.  Use of import prefixes should allow this.

library main;

import "package:expect/expect.dart";
import "library_same_name_used_lib1.dart";

main() {
  var x = makeX();
  Expect.equals('lib2.X', '$x');
}
