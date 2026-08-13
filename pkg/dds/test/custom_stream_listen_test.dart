// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  // Ensure the DDS allows for listening to a custom stream.
  (VmService service) async {
    try {
      await service.streamListen('Foo');
    } catch (e) {
      fail('Unable to subscribe to a custom stream: $e');
    }
  }
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'custom_stream_listen_test.dart',
    );
