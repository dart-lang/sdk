// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void test() {
  print('started');
  debugger();
  print('lf1\ntrail');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    print('At breakpoint');
    final completer = Completer<void>();
    late StreamSubscription stdoutSub;
    bool started = false;
    stdoutSub = service.onStdoutEvent.listen((event) async {
      final output = utf8.decode(base64Decode(event.bytes!));
      // DDS buffers log history and sends each entry as an event upon the
      // initial stream subscription. Wait for the initial sentinel before
      // executing test logic.
      if (!started) {
        started = output == 'started\n';
        return;
      }
      expect(output, 'lf1\ntrail\n');
      await stdoutSub.cancel();
      await service.streamCancel(EventStreams.kStdout);
      completer.complete();
    });
    await service.streamListen(EventStreams.kStdout);
    await service.resume(isolateRef.id!);
    await completer.future;
  },
];

Future<void> main(args) => runIsolateTests(
      args,
      tests,
      'stdio_newline_test.dart',
      testeeConcurrent: test,
    );
