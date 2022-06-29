// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "loading_unit_root_has_only_export_lib1.dart" deferred as lib;

main() async {
  await lib.loadLibrary();
  Expect.equals(lib.foo(), "in lib2");
}
