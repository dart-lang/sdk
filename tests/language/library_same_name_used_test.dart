// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'X' is defined as an interface in lib1 and a class implementing that
// interface in lib2.  Use of #import prefixes should allow this.

library main;
import "library_same_name_used_lib1.dart";

main() {
  var x = makeX();
  Expect.equals('lib2.X', '$x');
}
