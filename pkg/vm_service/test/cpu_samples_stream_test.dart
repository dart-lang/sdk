// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'cpu_samples_stream_lib.dart' as testee_lib;

late StreamSubscription sub;

void main([args = const <String>[]]) =>
    IsolateTestHarness('cpu_samples_stream_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolate) async {
      // TODO(bkonyi): re-enable after sample streaming is fixed.
      // See https://github.com/dart-lang/sdk/issues/46825
      /*final completer = Completer<void>();
        int count = 0;
        int previousOrigin = 0;
        sub = service.onProfilerEvent.listen((event) async {
          count++;
          expect(event.kind, EventKind.kCpuSamples);
          expect(event.cpuSamples, isNotNull);
          expect(event.cpuSamples!.samples!.isNotEmpty, true);
          if (previousOrigin != 0) {
            expect(
              event.cpuSamples!.timeOriginMicros! >= previousOrigin,
              true,
            );
          }
          previousOrigin = event.cpuSamples!.timeOriginMicros!;

          if (count == 2) {
            await sub.cancel();
            completer.complete();
          }
        });
        await service.streamListen(EventStreams.kProfiler);

        await completer.future;
        await service.streamCancel(EventStreams.kProfiler);
        */
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: [
        '--sample-buffer-duration=1',
        '--profile-vm',
      ],
    );
