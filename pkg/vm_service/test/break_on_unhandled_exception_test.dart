// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

// Test checks to make sure we don't encounter any unhandled exceptions
// in the URL lookup code.
// (please see https://github.com/dart-lang/sdk/issues/53334 for more details).

import 'break_on_unhandled_exception_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('break_on_unhandled_exception_lib.dart', args)
        .hasStoppedAtBreakpoint()
        // Add breakpoint
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
