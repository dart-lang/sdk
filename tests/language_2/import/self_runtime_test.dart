// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that private names cannot be imported even if the library imports
// itself.

library import_self;

import "package:expect/expect.dart";

// Eliminate the import of the unmodified file or else the analyzer
// will generate the static error in the import_self_test_none case.


var _x = "The quick brown fox jumps over the dazy log";

main() {

}
