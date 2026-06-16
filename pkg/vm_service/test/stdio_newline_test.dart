// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'stdio_newline_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'stdio_newline_lib.dart',
      args,
    )
        // The testeee will print the VM service is listening message
        // which could race with the regular stdio prints from the testee
        // The first debugger stop ensures we have these VM service
        // messages outputed before the testee writes anything to stdout.
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          await service.resume(isolateRef.id!);
        })
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          print('At breakpoint');
          final completer = Completer<void>();
          late StreamSubscription stdoutSub;
          bool started = false;
          stdoutSub = service.onStdoutEvent.listen((event) async {
            final output = decodeBase64(event.bytes!);
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
        })
        .run(testeeMain: testee_lib.main);
