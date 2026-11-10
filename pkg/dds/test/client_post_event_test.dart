// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds_launcher.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

const _customStream = 'testStream';
const _eventKind = 'testKind';

void main() {
  late Process process;
  late DartDevelopmentServiceLauncher dds;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      pauseOnStart: false,
    );
    dds = await DartDevelopmentServiceLauncher.start(
      remoteVmServiceUri: remoteVmServiceUri,
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('Ensure postEvent behaves as expected', () async {
    final service = await vmServiceConnectUri(dds.wsUri.toString());
    addTearDown(service.dispose);
    final originalExtensionData = <String, Object?>{'some': 'testData'};
    // Test if the custom stream doesn't exist yet, we throw an error.
    await expectLater(
      service.postEvent(_customStream, _eventKind, originalExtensionData),
      throwsA(
        isA<RPCError>().having(
          (e) => e.code,
          'code',
          RPCErrorKind.kCustomStreamDoesNotExist.code,
        ),
      ),
    );
    // Test if using a core stream, we throw an error.
    await expectLater(
      service.postEvent(
        EventStreams.kLogging,
        _eventKind,
        originalExtensionData,
      ),
      throwsA(
        isA<RPCError>().having(
          (e) => e.code,
          'code',
          RPCErrorKind.kCoreStreamNotAllowed.code,
        ),
      ),
    );

    // Test when the stream exists that the event is propagated.
    final firstEventFuture = service.onEvent(_customStream).first;
    await service.streamListen(_customStream);
    await service.postEvent(_customStream, _eventKind, originalExtensionData);

    final firstEvent = await firstEventFuture;
    expect(firstEvent.type, equals('Event'));
    expect(firstEvent.extensionData?.data, equals(originalExtensionData));

    // Test canceling the custom stream subscription causes postEvent to throw.
    await service.streamCancel(_customStream);
    await expectLater(
      service.postEvent(_customStream, _eventKind, originalExtensionData),
      throwsA(
        isA<RPCError>().having(
          (e) => e.code,
          'code',
          RPCErrorKind.kCustomStreamDoesNotExist.code,
        ),
      ),
    );

    // Test re-subscribing to the custom stream allows posting events again.
    final resubscribedEventFuture = service.onEvent(_customStream).first;
    await service.streamListen(_customStream);
    await service.postEvent(_customStream, _eventKind, originalExtensionData);

    final resubscribedEvent = await resubscribedEventFuture;
    expect(resubscribedEvent.type, equals('Event'));
    expect(
      resubscribedEvent.extensionData?.data,
      equals(originalExtensionData),
    );
  });
}
