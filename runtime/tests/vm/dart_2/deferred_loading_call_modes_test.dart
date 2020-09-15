// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_bare_instructions=false
// VMOptions=--use_bare_instructions=true --use_table_dispatch=false
// VMOptions=--use_bare_instructions=true --use_table_dispatch=true

import "splay_test.dart" deferred as splay; // Some non-trivial code.

main() async {
  await splay.loadLibrary();
  splay.main();
}
