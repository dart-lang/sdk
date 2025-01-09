// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'breakpoint_resolution_after_reloading_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) => runIsolateTests(
      args,
      breakpointResolutionAfterReloadingTests,
      'breakpoint_resolution_after_reloading_test.dart',
      testeeConcurrent: testeeMain,
    );
