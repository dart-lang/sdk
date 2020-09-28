// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--dwarf_stack_traces=true
/// VMOptions=--dwarf_stack_traces=false

import "prefix_importer_tree_shaken_immediate.dart" as i;

main() async {
  await i.load();
  print(await i.foo());
}
