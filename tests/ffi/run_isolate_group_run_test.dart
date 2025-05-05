// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests IsolateGroup.runSync - what works, what doesn't.
//
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --use-slow-path
// VMOptions=--experimental-shared-data --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --test_il_serialization
// VMOptions=--experimental-shared-data --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --profiler --profile_vm=false

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'dart:concurrent';
import 'dart:isolate';

import "package:expect/expect.dart";

var foo = 42;

@pragma('vm:never-inline')
updateFoo() {
  foo = 56;
}

main() {
  Expect.equals(42, IsolateGroup.runSync(() => 42));

  Expect.listEquals([1, 2, 3], IsolateGroup.runSync(() => [1, 2, 3]));

  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        throw "error";
      });
    },
    (e) => e == "error",
    'Expect thrown error',
  );

  // Documenting current limitations.
  Expect.notEquals(() {
    IsolateGroup.runSync(() {
      return Isolate.current;
    });
  }, Isolate.current);
  //
  // Following crashes VM since field_table is not set up on
  // isolate group mutator thread.
  //
  // Expect.throws(() {
  //   IsolateGroup.runSync(() {
  //     print('42');
  //   });
  // }, (e) => e is Error && e.toString().contains("Unsupported operation"));

  // updateFoo();
  // Expect.equals(
  //   IsolateGroup.runSync(() {
  //     return foo;
  //   }),
  //   42,
  // );

  print("All tests completed :)");
}
