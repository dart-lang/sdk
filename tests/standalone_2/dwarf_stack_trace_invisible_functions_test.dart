// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/dwarf_invisible_functions.so

import 'dart:io';

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;

import 'dwarf_stack_trace_test.dart' as dwarf_stack_trace_test;

const int LINE_A = 25;
const int LINE_B = 31;
const int LINE_C = 38;
const int LINE_D = 46;
const int LINE_E = 58;

@pragma("vm:prefer-inline")
bar() {
  // Keep the 'throw' and its argument on separate lines.
  throw // force linebreak with dart format // LINE_A
      "Hello, Dwarf!";
}

@pragma("vm:never-inline")
foo() {
  bar(); // LINE_B
}

@pragma("vm:never-inline")
bazz(void Function() func) {
  // Call through tear-off (implicit closure function) which should be
  // omitted from the stack trace.
  func(); // LINE_C
}

class A<T> {
  A();

  @pragma("vm:never-inline")
  void add(T x) {
    bazz(foo); // LINE_D
  }
}

dynamic aa = int.parse('1') == 1 ? A() : [];

Future<void> main() async {
  String rawStack = "";
  try {
    // Dynamic call to a generic-covariant method goes through the
    // dynamic invocation forwarder function, which should be
    // omitted from the stack trace.
    aa.add(42); // LINE_E
  } catch (e, st) {
    rawStack = st.toString();
  }

  if (path.basenameWithoutExtension(Platform.executable) !=
      "dart_precompiled_runtime") {
    return; // Not running from an AOT compiled snapshot.
  }

  if (Platform.isAndroid) {
    return; // Generated dwarf.so not available on the test device.
  }

  final dwarf = Dwarf.fromFile(path.join(
      Platform.environment["TEST_COMPILATION_DIR"],
      "dwarf_invisible_functions.so"));

  await dwarf_stack_trace_test.checkStackTrace(
      rawStack, dwarf, expectedCallsInfo);
}

final expectedCallsInfo = <List<DartCallInfo>>[
  // Frame 1: the throw in bar, which was inlined
  // into foo (so we'll get information for two calls for that PC address).
  [
    DartCallInfo(
        function: "bar",
        filename: "dwarf_stack_trace_invisible_functions_test.dart",
        line: LINE_A,
        column: 3,
        inlined: true),
    DartCallInfo(
        function: "foo",
        filename: "dwarf_stack_trace_invisible_functions_test.dart",
        line: LINE_B,
        column: 3,
        inlined: false)
  ],
  // Frame 2: call to foo in bazz.
  [
    DartCallInfo(
        function: "bazz",
        filename: "dwarf_stack_trace_invisible_functions_test.dart",
        line: LINE_C,
        column: 3,
        inlined: false)
  ],
  // Frame 3: call to bazz in A.method.
  [
    DartCallInfo(
        function: "A.add",
        filename: "dwarf_stack_trace_invisible_functions_test.dart",
        line: LINE_D,
        column: 5,
        inlined: false)
  ],
  // Frame 4: the call to foo in main.
  [
    DartCallInfo(
        function: "main",
        filename: "dwarf_stack_trace_invisible_functions_test.dart",
        line: LINE_E,
        column: 8,
        inlined: false)
  ],
  // Don't assume anything about any of the frames below the main,
  // as this makes the test too brittle.
];
