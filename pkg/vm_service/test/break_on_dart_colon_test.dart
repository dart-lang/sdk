// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:vm_service/vm_service.dart';

import 'break_on_dart_colon_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

IsolateTest expectHitBreakpoint(String uri, int line) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final bpt = await service.addBreakpointWithScriptUri(isolateId, uri, line);
    await resumeIsolate(service, isolateRef);
    await hasStoppedAtBreakpoint(service, isolateRef);
    await stoppedAtLine(line)(service, isolateRef);
    await service.removeBreakpoint(isolateId, bpt.id!);
  };
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('break_on_dart_colon_lib.dart', args)
        .hasStoppedAtBreakpoint()
        // Dart libraries are not debuggable by default
        .markDartColonLibrariesDebuggable()
        .addCustomTest(
          expectHitBreakpoint(
            'org-dartlang-sdk:///sdk/lib/core/print.dart',
            19, // Line in core/print.dart
          ),
        )
        .addCustomTest(expectHitBreakpoint('dart:core/print.dart', 19))
        .addCustomTest(expectHitBreakpoint('/core/print.dart', 19))
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
