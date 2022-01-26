// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a relatively large program (kernel compiler)
// can be compiled with --hash_map_probes_limit.

// VMOptions=--hash_map_probes_limit=1000

import "package:vm/kernel_front_end.dart";

main(List<String> args) async {
  await runCompiler(createCompilerArgParser().parse(['--help']), '');
}
