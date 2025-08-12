// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testeeMain() {}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // We have deprecated `streamCpuSamplesWithUserTag` and made it always
    // return `Success` when called with any string array as the `userTags`
    // argument.
    // ignore: deprecated_member_use_from_same_package
    await service.streamCpuSamplesWithUserTag([]);
  }
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'stream_cpu_samples_with_user_tag_rpc_test.dart',
      testeeBefore: testeeMain,
    );
