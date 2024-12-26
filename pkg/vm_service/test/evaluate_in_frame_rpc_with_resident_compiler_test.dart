// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';
import 'evaluate_in_frame_rpc_test_common.dart';

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      evaluateInFrameRpcTests,
      'evaluate_in_frame_rpc_with_resident_compiler_test.dart',
      testeeConcurrent: testeeMain,
      shouldTesteeBeLaunchedWithDartRunResident: true,
    );
