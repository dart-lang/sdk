// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/src/dart_io_extensions.dart';
import 'package:test/test.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String kSetHttpEnableTimelineLogging =
    'ext.dart.io.setHttpEnableTimelineLogging';
const String kGetHttpEnableTimelineLogging =
    'ext.dart.io.getHttpEnableTimelineLogging';
Future<void> setup() async {}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id);
    // Ensure all HTTP service extensions are registered.
    expect(isolate.extensionRPCs.length, greaterThanOrEqualTo(2));
    expect(
        isolate.extensionRPCs.contains(kGetHttpEnableTimelineLogging), isTrue);
    expect(
        isolate.extensionRPCs.contains(kSetHttpEnableTimelineLogging), isTrue);
  },
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id;
    dynamic response = await service.getHttpEnableTimelineLogging(isolateId);
    expect(response.enabled, false);

    await service.setHttpEnableTimelineLogging(isolateId, true);

    response = await service.getHttpEnableTimelineLogging(isolateId);
    expect(response.enabled, true);

    await service.setHttpEnableTimelineLogging(isolateId, false);

    response = await service.getHttpEnableTimelineLogging(isolateId);
    expect(response.enabled, false);
  },
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, testeeBefore: setup);
