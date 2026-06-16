// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'kill_paused_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('kill_paused_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Kill the app.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      await service.kill(isolateId);
    }).run(testeeMain: testee_lib.main);
