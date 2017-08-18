// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compilation equivalence between source and .dill based
// compilation using the fast_startup emitter.
library dart2js.kernel.compile_from_dill_fast_startup_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';

import 'compile_from_dill_test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    await runTests(args, options: [Flags.fastStartup]);
  });
}
