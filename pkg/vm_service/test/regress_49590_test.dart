// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

class FakeVmService implements VmServiceInterface {
  @override
  noSuchMethod(Invocation invocation) {}
}

void main() {
  // Regression test for https://github.com/dart-lang/sdk/issues/49590
  test('VmServerConnection does not accept StreamSink<Map<String, Object>>',
      () {
    final requestController = StreamController<Map<String, Object>>();
    final responseController = StreamController<Map<String, Object>>();
    try {
      final connection = VmServerConnection(
        requestController.stream,
        responseController.sink,
        ServiceExtensionRegistry(),
        FakeVmService(),
      );
      print(connection);
      fail('Created invalid VmServerConnection');
    } on StateError {
      // Expected
    }
  });
}
