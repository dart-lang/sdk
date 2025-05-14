// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';
import 'evaluate_with_scope_test_common.dart';

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      evaluteWithScopeTests,
      'evaluate_with_scope_test.dart',
      testeeBefore: testeeMain,
      pauseOnExit: true,
    );
