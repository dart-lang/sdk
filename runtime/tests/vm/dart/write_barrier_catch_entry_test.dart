// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--gc_at_throw --verify_before_gc --verify_after_gc --verify_store_buffer

// Regression test for https://github.com/dart-lang/sdk/issues/60836.
// Write barrier elimination applies when there is no potential Dart call
// between a StoreFieldInstr and an AllocateObjectInstr. But the control flow
// between all potentially throwing instructions in a try block and the
// corresponding catch block is not explicitly repreresented in the flow graph,
// so the writer barrier elimination pass needs to handle catch entries
// specially.

class Context {
  var error;
  var stack;
}

@pragma("vm:never-inline")
indirectThrow() => indirectThrow2();

@pragma("vm:never-inline")
indirectThrow2() => throw "Exception!";

@pragma("vm:never-inline")
Context foo() {
  final context = new Context();
  try {
    context.error = 1; // Write barrier elimination okay.
    indirectThrow();
    context.error = 2; // Write barrier elimination not okay.
  } catch (e, st) {
    context.error = e; // Write barrier elimination not okay.
    context.stack = st; // Write barrier elimination not okay.
  }
  return context;
}

main() {
  for (int i = 0; i < 3; i++) {
    final context = foo();
    print(context.error);
    print(context.stack);
  }
  print("Okay");
}
