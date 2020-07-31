// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=appjit_cha_deopt_test_body.dart
// VMOptions=--optimization-counter-threshold=100 --deterministic

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

import 'dart:async';
import 'dart:io' show Platform;

import 'snapshot_test_helper.dart';

Future<void> main() =>
    runAppJitTest(Platform.script.resolve('appjit_cha_deopt_test_body.dart'));
