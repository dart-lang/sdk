// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void test() {
  debugger();
  print('start');
  debugger();
  print('stdout');

  debugger();
  print('print');

  debugger();
  stderr.write('stderr');
}

var tests = <IsolateTest>[
  // The testeee will print the VM service is listening message
  // which could race with the regular stdio prints from the testee
  // The first debugger stop ensures we have these VM service
  // messages outputed before the testee writes anything to stdout.
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    await service.resume(isolateRef.id!);
  },
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late StreamSubscription stdoutSub;
    bool started = false;
    stdoutSub = service.onStdoutEvent.listen((event) async {
      final output = decodeBase64(event.bytes!);
      // DDS buffers log history and sends each entry as an event upon the
      // initial stream subscription. Wait for the initial sentinel before
      // executing test logic.
      if (!started) {
        started = output == 'start\n';
        return;
      }
      expect(event.kind, EventKind.kWriteEvent);
      expect(output, 'stdout\n');
      await stdoutSub.cancel();
      await service.streamCancel(EventStreams.kStdout);
      completer.complete();
    });
    await service.streamListen(EventStreams.kStdout);
    await service.resume(isolateRef.id!);
    await completer.future;
  },
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late StreamSubscription stdoutSub;
    stdoutSub = service.onStdoutEvent.listen((event) async {
      expect(event.kind, EventKind.kWriteEvent);
      final decoded = decodeBase64(event.bytes!);
      expect(decoded, 'print\n');
      await service.streamCancel(EventStreams.kStdout);
      await stdoutSub.cancel();
      completer.complete();
    });
    await service.streamListen(EventStreams.kStdout);
    await service.resume(isolateRef.id!);
    await completer.future;
  },
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late StreamSubscription stderrSub;
    stderrSub = service.onStderrEvent.listen((event) async {
      // DDS buffers log history and sends each entry as an event upon the
      // initial stream subscription. We don't need to wait for a sentinel here
      // before executing the test logic since nothing is written to stderr
      // outside this test.
      //
      // If this test starts failing, the VM service or dartdev has started
      // writing to stderr and this test should be updated.
      expect(event.kind, EventKind.kWriteEvent);
      expect(decodeBase64(event.bytes!), 'stderr');
      await service.streamCancel(EventStreams.kStderr);
      await stderrSub.cancel();
      completer.complete();
    });
    await service.streamListen(EventStreams.kStderr);
    await service.resume(isolateRef.id!);
    await completer.future;
  },
];

Future<void> main(args) => runIsolateTests(
      args,
      tests,
      'capture_stdio_test.dart',
      testeeConcurrent: test,
    );
