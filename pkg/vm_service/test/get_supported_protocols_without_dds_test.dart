// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';
import 'get_supported_protocols_common.dart';

final tests = <VMTest>[
  expectedProtocolTest(<String>[
    'VM Service',
  ]),
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'get_supported_protocols_with_dds_test.dart',
      extraArgs: ['--no-dds'],
    );
