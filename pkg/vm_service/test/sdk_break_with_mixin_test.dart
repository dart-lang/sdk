// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'sdk_break_with_mixin_lib.dart' as testee_lib;

const String uri = 'org-dartlang-sdk:///sdk/lib/collection/set.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('sdk_break_with_mixin_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .markDartColonLibrariesDebuggable()
        .addCustomTestWithParser((service, isolateRef, scriptParser) async {
          final line = scriptParser.lineForRegExp(
              RegExp(r'void forEach\(void f\(E element\)\) \{'),
              script: '../../../sdk/lib/collection/set.dart');
          print('Setting breakpoint for line $line in $uri');
          final Breakpoint bpt = await service.addBreakpointWithScriptUri(
              isolateRef.id!, uri, line);
          print('Breakpoint is $bpt');
          expect(bpt, isNotNull);
        })
        .resumeProgramRecordingStops(true)
        .checkRecordedStops(debugPrint: true)
        .run(
          testeeMain: testee_lib.main,
          pauseOnStart: false,
          pauseOnExit: true,
        );
