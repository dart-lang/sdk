// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../tools/heapsnapshot/test/cli_test.dart' as cli_test;
import '../../../tools/heapsnapshot/test/expression_test.dart' as expr_test;
import '../../../tools/heapsnapshot/test/completion_test.dart' as comp_test;

import 'use_flag_test_helper.dart';

main(List<String> args) {
  if (!buildDir.contains('Release') || isSimulator) return;

  // The cli_test may launch subprocesses using Platform.script, if it does we
  // delegate subprocess logic to it.
  if (!args.isEmpty) {
    cli_test.main(args);
    return;
  }

  cli_test.main();
  expr_test.main();
  comp_test.main();
}
