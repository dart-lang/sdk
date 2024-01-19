// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

const String kHttpEnableTimelineLogging =
    'ext.dart.io.httpEnableTimelineLogging';

Future<void> setup() async {}

Future<void> waitForStreamEvent(
  VmService service,
  IsolateRef isolateRef,
  bool state,
) async {
  final completer = Completer<void>();
  final isolateId = isolateRef.id!;
  late StreamSubscription sub;
  sub = service.onExtensionEvent.listen((event) {
    expect(event.extensionKind, 'HttpTimelineLoggingStateChange');
    expect(event.extensionData!.data['isolateId'], isolateRef.id);
    expect(event.extensionData!.data['enabled'], state);
    sub.cancel();
    completer.complete();
  });
  await service.streamListen(EventStreams.kExtension);
  await service.httpEnableTimelineLogging(isolateId, state);
  await completer.future;
  await service.streamCancel(EventStreams.kExtension);
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    // Ensure all HTTP service extensions are registered.
    expect(isolate.extensionRPCs!.length, greaterThanOrEqualTo(2));
    expect(isolate.extensionRPCs!.contains(kHttpEnableTimelineLogging), isTrue);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    dynamic response = await service.httpEnableTimelineLogging(isolateId, null);
    expect(response.enabled, false);

    await waitForStreamEvent(service, isolateRef, true);
    response = await service.httpEnableTimelineLogging(isolateId, null);
    expect(response.enabled, true);

    await waitForStreamEvent(service, isolateRef, false);
    response = await service.httpEnableTimelineLogging(isolateId);
    expect(response.enabled, false);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'http_enable_timeline_logging_service_test.dart',
      testeeBefore: setup,
    );
