// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'get_supported_protocols_common.dart';
import 'get_supported_protocols_without_dds_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    VMTestHarness('get_supported_protocols_without_dds_lib.dart', args)
        .addTest(
      expectedProtocolTest(<String>[
        'VM Service',
      ]),
    )
        .run(testeeMain: testee_lib.main, extraArgs: ['--no-dds']);
