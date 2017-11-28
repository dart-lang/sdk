// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that import prefixes within an imported library don't shadow
// names re-exported by that library.

import "package:expect/expect.dart";
import "export_not_shadowed_by_prefix_helper.dart";

main() {
  f();
  Expect.isTrue(f_called);
}
