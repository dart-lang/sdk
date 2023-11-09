// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void test() {
  print('start');
  debugger();
  print('stdout');

  debugger();
  print('print');

  debugger();
  stderr.write('stderr');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    late StreamSubscription stdoutSub;
    bool started = false;
    stdoutSub = service.onStdoutEvent.listen((event) async {
      final output = utf8.decode(base64Decode(event.bytes!));
      // DDS buffers log history and sends each entry as an event upon the
      // initial stream subscription. Wait for the initial sentinel before
      // executing test logic.
      if (!started) {
        started = output == 'start';
        return;
      }
      expect(event.kind, EventKind.kWriteEvent);
      expect(output, 'stdout');
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
      final decoded = utf8.decode(base64Decode(event.bytes!));
      expect(decoded, 'print');
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
      expect(utf8.decode(base64Decode(event.bytes!)), 'stderr');
      await service.streamCancel(EventStreams.kStderr);
      await stderrSub.cancel();
      completer.complete();
    });
    await service.streamListen(EventStreams.kStderr);
    await service.resume(isolateRef.id!);
    await completer.future;
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'capture_stdio_test.dart',
      testeeConcurrent: test,
    );
