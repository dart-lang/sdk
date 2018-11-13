// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

import 'dart:async';

import 'snapshot_test_helper.dart';

Future<void> main() => runAppJitBytecodeTest();
