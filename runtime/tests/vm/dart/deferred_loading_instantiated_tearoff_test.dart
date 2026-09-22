// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "deferred_loading_instantiated_tearoff_lib.dart" deferred as lib;

main() async {
  await lib.loadLibrary();
  await lib.main();
}
