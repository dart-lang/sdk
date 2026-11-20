// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that single stepping does not pause where compiled code has no
// pause point: at the allocation of a closure, at the stack check at the
// start of each loop iteration, or before evaluating the value of a yield.

import 'common/service_test_common.dart';
import 'step_through_explicit_pause_points_lib.dart' as testee_lib;

const List<String> stops = [
  'LINE_J', // The call to callClosure, not the closure allocation.
  'LINE_C',
  'LINE_D',
  'LINE_J', // The entry of the closure.
  'LINE_K',
  'LINE_L',
  'LINE_E',
  'LINE_M', // The declaration of closure, not the closure allocation.
  'LINE_P',
  'LINE_M', // The entry of the closure.
  'LINE_N',
  'LINE_O',
  'LINE_Q', // The iterable, not the stack check of the loop.
  'LINE_Q',
  'LINE_R',
  'LINE_Q',
  'LINE_Q',
  'LINE_R',
  'LINE_Q',
  'LINE_S',
  'LINE_F',
  'LINE_S',
  'LINE_G', // The value of the yield, before the yield itself.
  'LINE_A',
  'LINE_B',
  'LINE_G',
  'LINE_S',
  'LINE_T',
  'LINE_S',
  'LINE_H',
  'LINE_U',
];

void main([args = const <String>[]]) {
  var harness = IsolateTestHarness(
    'step_through_explicit_pause_points_lib.dart',
    args,
  )
      .hasPausedAtStart()
      .setBreakpointAtLine('LINE_I')
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_I');
  for (final stop in stops) {
    harness = harness.stepInto().hasStoppedAtBreakpoint().stoppedAtLine(stop);
  }
  harness.resumeIsolate().run(
        testeeMain: testee_lib.main,
        pauseOnStart: true,
      );
}
