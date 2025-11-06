// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests SendPort.send from isolate group-shared mutator.
//
// VMOptions=--experimental-shared-data
// VMOptions=--experimental-shared-data --use-slow-path
// VMOptions=--experimental-shared-data --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --test_il_serialization
// VMOptions=--experimental-shared-data --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --profiler --profile_vm=false

import 'dart:isolate';

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

main() async {
  asyncStart();
  ReceivePort rp = ReceivePort();
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        rp.sendPort.send("hello");
      });
    },
    (e) =>
        e is ArgumentError && e.toString().contains('Only trivially-immutable'),
  );
  rp.close();
  asyncEnd();
}
