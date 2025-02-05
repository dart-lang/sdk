// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for https://dartbug.com/59603.

import 'common/test_helper.dart';
import 'forward_compile_expression_error_from_external_client_test_common.dart';

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'forward_compile_expression_error_from_external_client_with_dds_test.dart',
      pauseOnExit: true,
    );
