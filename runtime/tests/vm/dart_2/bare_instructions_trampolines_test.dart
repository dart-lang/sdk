// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--always-generate-trampolines-for-testing --use-bare-instructions

// We use a reasonable sized test and run it with the above options.
import 'hello_fuchsia_test.dart' as test;

main(args) {
  test.main(args);
}
