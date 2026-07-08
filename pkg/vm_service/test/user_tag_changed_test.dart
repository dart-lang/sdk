// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'user_tag_changed_lib.dart' as testee_lib;

late StreamQueue<Event> stream;

Future<void> main([args = const <String>[]]) async => await IsolateTestHarness(
      'user_tag_changed_lib.dart',
      args,
    )
        .hasPausedAtStart()
        .addCustomTest((VmService service, IsolateRef isolate) async {
          await service.streamListen(EventStreams.kProfiler);
          stream = StreamQueue(
            service.onProfilerEvent.transform(
              SingleSubscriptionTransformer<Event, Event>(),
            ),
          );
        })
        .resumeIsolate()
        .hasStoppedAtExit()
        .addCustomTest((VmService service, IsolateRef isolate) async {
          await service.streamCancel(EventStreams.kProfiler);
          expect(await stream.hasNext, true);

          var event = await stream.next;
          expect(event.kind, EventKind.kUserTagChanged);
          expect(event.isolate, isNotNull);
          expect(event.updatedTag, 'Foo');
          expect(event.previousTag, 'Default');

          expect(await stream.hasNext, true);
          event = await stream.next;
          expect(event.kind, EventKind.kUserTagChanged);
          expect(event.isolate, isNotNull);
          expect(event.updatedTag, 'Default');
          expect(event.previousTag, 'Foo');
        })
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          pauseOnExit: true,
        );
