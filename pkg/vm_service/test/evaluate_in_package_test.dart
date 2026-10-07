// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_in_package_lib.dart' as testee_lib;

const String breakpointFile = 'package:test_package/the_part.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_in_package_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtUriAndLine(breakpointFile, 'LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      await evaluateInFrameAndExpect(service, isolateId, '1 + 1', '2');
      await evaluateInFrameAndExpect(service, isolateId, 'foo', 'Foo!');
    }).run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
      pauseOnExit: true,
      launchTesteeWithDartRunResident: true,
    );
