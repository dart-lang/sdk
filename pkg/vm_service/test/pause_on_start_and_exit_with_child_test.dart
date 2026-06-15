// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'pause_on_start_and_exit_with_child_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'pause_on_start_and_exit_with_child_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Disabling these flags will result in any new isolates spawned not
          // pausing on start or exit. However, existing isolates will maintain their
          // existing flags and the main isolate should pause at exit.
          await service.setFlag('pause_isolates_on_start', 'false');
          await service.setFlag('pause_isolates_on_exit', 'false');
        })
        .resumeIsolate()
        // When the main isolate is resumed, we expect the child isolate to spawn and
        // immediately exit after sending a message to the main isolate. The main
        // isolate will only exit when `port` is closed after the message sent by the
        // child is received.
        .hasStoppedAtExit()
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
          extraArgs: [
            '--trace-service',
            '--trace-service-verbose',
          ],
        );
