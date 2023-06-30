// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import 'awaiter_stacks/harness.dart' as harness;

main() async {
  if (harness.shouldSkip()) {
    // Skip the test in this configuration.
    return;
  }

  harness.configure(currentExpectations);

  StackTrace trace = StackTrace.empty;

  A.visible(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  A.invisible(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  visible(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  invisible(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  visibleClosure(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  invisibleClosure(() => trace = StackTrace.current);
  await harness.checkExpectedStack(trace);

  harness.updateExpectations();
}

class A {
  A.visible(void Function() fun) {
    print('A.visible');
    fun();
  }

  @pragma('vm:invisible')
  A.invisible(void Function() fun) {
    print('A.invisible');
    fun();
  }
}

void visible(void Function() fun) {
  print('visible()');
  fun();
}

@pragma('vm:invisible')
void invisible(void Function() fun) {
  print('invisible()');
  fun();
}

void visibleClosure(void Function() fun) {
  visibleInner() {
    print('visibleInner');
    fun();
  }

  visibleInner();
}

void invisibleClosure(void Function() fun) {
  @pragma('vm:invisible')
  invisibleInner() {
    print('invisibleInner');
    fun();
  }

  invisibleInner();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    main.<anonymous closure> (%test%)
#1    new A.visible (%test%)
#2    main (%test%)
#3    _delayEntrypointInvocation.<anonymous closure> (isolate_patch.dart)
#4    _RawReceivePort._handleMessage (isolate_patch.dart)""",
  """
#0    main.<anonymous closure> (%test%)
#1    main (%test%)
<asynchronous suspension>""",
  """
#0    main.<anonymous closure> (%test%)
#1    visible (%test%)
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    main.<anonymous closure> (%test%)
#1    main (%test%)
<asynchronous suspension>""",
  """
#0    main.<anonymous closure> (%test%)
#1    visibleClosure.visibleInner (%test%)
#2    visibleClosure (%test%)
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    main.<anonymous closure> (%test%)
#1    invisibleClosure (%test%)
#2    main (%test%)
<asynchronous suspension>"""
];
// CURRENT EXPECTATIONS END
