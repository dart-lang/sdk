// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:expect/expect.dart';

import 'use_flag_test_helper.dart';

void main() {
  final buildId = NativeRuntime.buildId;
  if (isAOTRuntime) {
    Expect.isNotNull(buildId);
    Expect.isTrue(buildId!.isNotEmpty, 'Build ID is an empty string');
  } else {
    Expect.isNull(buildId); // Should be null in JIT mode.
  }
  print(buildId);
}
