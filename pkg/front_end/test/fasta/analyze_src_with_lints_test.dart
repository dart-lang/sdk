// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:testing/src/run_tests.dart" as testing show main;

main() async {
  return await testing.main(<String>[
    "--config=pkg/front_end/testing_with_lints.json",
    "--verbose",
    "analyze"
  ]);
}
