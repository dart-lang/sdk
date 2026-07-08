// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'gc_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness('gc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final Completer completer = Completer();
      // Expect at least this many GC events.
      int gcCountdown = 3;
      late final StreamSubscription sub;
      sub = service.onGCEvent.listen((stream) {
        if (--gcCountdown == 0) {
          sub.cancel();
          completer.complete();
        }
      });
      await service.streamListen(EventStreams.kGC);
      return completer.future;
    }).run(testeeMain: testee_lib.main);
