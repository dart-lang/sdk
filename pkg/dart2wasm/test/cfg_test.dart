// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ir_test.dart';

void main(List<String> args) async {
  await runIrTestSuite(
    args,
    testDirectory: 'pkg/dart2wasm/test/cfg_tests',
    watExtension: '.cfg.wat',
    isCfgTest: true,
  );
}
