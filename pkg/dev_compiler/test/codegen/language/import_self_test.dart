// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that private names cannot be imported even if the library imports
// itself.

library import_self;

import "package:expect/expect.dart";

// Eliminate the import of the unmodified file or else the analyzer
// will generate the static warning in the import_self_test_none case.
import "import_self_test.dart" as p;  /// 01: continued

var _x = "The quick brown fox jumps over the dazy log";

main() {
  var t = "Falsches Üben von Xylophonmusik quält jeden größeren Zwerg";

  // Check that referencing p._x causes a warning from the analyzer,
  // and the runtime fails to resolve p._x, even though it refers to
  // top level variable _x of this file.
  Expect.throws(() { t = p._x; },  /// 01: static type warning
                (e) => e is NoSuchMethodError);  /// 01: continued

  Expect.isTrue(t.endsWith("Zwerg"));
}
