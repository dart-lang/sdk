// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the experiment in the 'SharedOptions' comment is passed by the
// test runner.

import 'dart:io';

import 'package:expect/expect.dart';

// SharedOptions=--enable-experiment=test-experiment
main() {
  Expect.isTrue(Platform.executableArguments
      .contains("--enable-experiment=test-experiment"));
}
