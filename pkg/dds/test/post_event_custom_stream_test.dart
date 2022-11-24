// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';
import 'post_event_custom_stream_script.dart' as script;

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    // process = await spawnDartProcess(
    //   'post_event_custom_stream_script.dart',
    // );
  });
  /**
   * TODO: Delete this comment/note
   * have 2 files,
   * in the script file, probably want to have places where you call debugger (pause here essentially)
   * synchronize on that to make sure that you get there
   * once you get there then sub to the stream
   * once all that subscription is set up then you resume the isolate then post an event
   * you would have a completer in the stream the receive the message. 
   * await the future for the completer and then finish
   * default timeout is fine
   */
  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('sends a postEvent over a custom stream', () async {
    process = await spawnDartProcess(
      'post_event_custom_stream_script.dart',
    );
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service = await vmServiceConnectUri(dds.wsUri.toString());
    final completer = Completer<Event>();
    final isolateId = (await service.getVM()).isolates!.first.id!;

    service.streamListen(script.customStreamId);
    service.onEvent(script.customStreamId).listen((event) {
      completer.complete(event);
    });

    await service.resume(isolateId);

    final event = await completer.future;
    expect(event.extensionKind, equals(script.eventKind));
    expect(event.extensionData?.data, equals(script.eventData));
  });
}
