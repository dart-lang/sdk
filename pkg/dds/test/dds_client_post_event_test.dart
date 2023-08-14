// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/src/rpc_error_codes.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/src/vm_service.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  late final Process process;
  late final DartDevelopmentService dds;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      pauseOnStart: false,
    );
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('Ensure postEvent behaves as expected', () async {
    expect(dds.isRunning, true);
    int caughtCount = 0;
    final service = await vmServiceConnectUri(dds.wsUri.toString());
    final originalExtensionData = {'some': 'testData'};
    // Test if the custom stream doesn't exist yet, we throw an error.
    try {
      await service.postEvent('testStream', 'testKind', originalExtensionData);
    } on vm.RPCError catch (e) {
      expect(e.code, RpcErrorCodes.kCustomStreamDoesNotExist);
      caughtCount++;
    }
    expect(caughtCount, 1);
    // Test if using a core stream, we throw an error.
    try {
      await service.postEvent('Logging', 'testKind', originalExtensionData);
    } on vm.RPCError catch (e) {
      expect(e.code, RpcErrorCodes.kCoreStreamNotAllowed);
      caughtCount++;
    }
    expect(caughtCount, 2);

    // Test when the stream exists that the event is propagated.
    final completer = Completer<void>();
    ExtensionData? eventExtensionData;

    service.onEvent('testStream').listen((event) {
      eventExtensionData = event.extensionData;
      completer.complete();
    });
    await service.streamListen('testStream');
    await service.postEvent('testStream', 'testKind', originalExtensionData);

    await completer.future;
    expect(eventExtensionData?.data, equals(originalExtensionData));
  });
}
