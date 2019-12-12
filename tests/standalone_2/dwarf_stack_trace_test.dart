// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--dwarf-stack-traces --save-debugging-info=dwarf.so

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:vm/dwarf/convert.dart';
import 'package:vm/dwarf/dwarf.dart';

@pragma("vm:prefer-inline")
bar() {
  // Keep the 'throw' and its argument on separate lines.
  throw // force linebreak with dartfmt
      "Hello, Dwarf!";
}

@pragma("vm:never-inline")
foo() {
  bar();
}

Future<void> main() async {
  String rawStack;
  try {
    foo();
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

  final dwarf = Dwarf.fromFile("dwarf.so");

  await checkStackTrace(rawStack, dwarf, expectedCallsInfo);
}

Future<void> checkStackTrace(String rawStack, Dwarf dwarf,
    List<List<CallInfo>> expectedCallsInfo) async {
  final expectedAllCallsInfo = expectedCallsInfo;
  final expectedExternalCallInfo = removeInternalCalls(expectedCallsInfo);

  print("");
  print("Raw stack trace:");
  print(rawStack);

  var rawLines =
      await Stream.value(rawStack).transform(const LineSplitter()).toList();

  final pcAddresses =
      collectPCOffsets(rawLines).map((pc) => pc.virtualAddress(dwarf)).toList();

  // We should have at least enough PC addresses to cover the frames we'll be
  // checking.
  expect(pcAddresses.length, greaterThanOrEqualTo(expectedAllCallsInfo.length));

  final externalFramesInfo =
      pcAddresses.map((i) => dwarf.callInfo(i)?.toList()).toList();

  final allFramesInfo = pcAddresses
      .map((i) => dwarf.callInfo(i, includeInternalFrames: true)?.toList())
      .toList();

  print("");
  print("Call information for PC addresses:");
  for (var i = 0; i < pcAddresses.length; i++) {
    print("For PC 0x${pcAddresses[i].toRadixString(16)}:");
    print("  Calls corresponding to user or library code:");
    externalFramesInfo[i]?.forEach((frame) => print("    ${frame}"));
    print("  All calls:");
    allFramesInfo[i]?.forEach((frame) => print("    ${frame}"));
  }

  // Check that our results are also consistent.
  checkConsistency(externalFramesInfo, allFramesInfo);

  checkFrames(externalFramesInfo, expectedExternalCallInfo);
  checkFrames(allFramesInfo, expectedAllCallsInfo);

  final externalSymbolizedLines = await Stream.fromIterable(rawLines)
      .transform(DwarfStackTraceDecoder(dwarf))
      .toList();

  final externalSymbolizedCalls =
      externalSymbolizedLines.where((s) => s.startsWith('#')).toList();

  print("");
  print("Symbolized external-only stack trace:");
  externalSymbolizedLines.forEach(print);
  print("");
  print("Extracted calls:");
  externalSymbolizedCalls.forEach(print);

  final allSymbolizedLines = await Stream.fromIterable(rawLines)
      .transform(DwarfStackTraceDecoder(dwarf, includeInternalFrames: true))
      .toList();

  final allSymbolizedCalls =
      allSymbolizedLines.where((s) => s.startsWith('#')).toList();

  print("");
  print("Symbolized full stack trace:");
  allSymbolizedLines.forEach(print);
  print("");
  print("Extracted calls:");
  allSymbolizedCalls.forEach(print);

  final expectedExternalStrings = extractCallStrings(expectedExternalCallInfo);
  // There are two strings in the list for each line in the output.
  final expectedExternalCallCount = expectedExternalStrings.length ~/ 2;
  final expectedStrings = extractCallStrings(expectedAllCallsInfo);
  final expectedCallCount = expectedStrings.length ~/ 2;

  expect(externalSymbolizedCalls.length,
      greaterThanOrEqualTo(expectedExternalCallCount));
  expect(allSymbolizedCalls.length, greaterThanOrEqualTo(expectedCallCount));

  // Strip off any unexpected lines, so we can also make sure we didn't get
  // unexpected calls prior to those calls we expect.
  final externalCallsTrace =
      externalSymbolizedCalls.sublist(0, expectedExternalCallCount).join('\n');
  final allCallsTrace =
      allSymbolizedCalls.sublist(0, expectedCallCount).join('\n');

  expect(externalCallsTrace, stringContainsInOrder(expectedExternalStrings));
  expect(allCallsTrace, stringContainsInOrder(expectedStrings));
}

final expectedCallsInfo = <List<CallInfo>>[
  // The first frame should correspond to the throw in bar, which was inlined
  // into foo (so we'll get information for two calls for that PC address).
  [
    CallInfo(
        function: "bar",
        filename: "dwarf_stack_trace_test.dart",
        line: 18,
        inlined: true),
    CallInfo(
        function: "foo",
        filename: "dwarf_stack_trace_test.dart",
        line: 24,
        inlined: false)
  ],
  // The second frame corresponds to call to foo in main.
  [
    CallInfo(
        function: "main",
        filename: "dwarf_stack_trace_test.dart",
        line: 30,
        inlined: false)
  ],
  // Internal frames have non-positive line numbers in the call information.
  [
    CallInfo(
        function: "main",
        filename: "dwarf_stack_trace_test.dart",
        line: 0,
        inlined: false),
  ]
];

List<List<CallInfo>> removeInternalCalls(List<List<CallInfo>> original) =>
    original
        .map((frame) => frame.where((call) => call.line > 0).toList())
        .toList();

void checkConsistency(
    List<List<CallInfo>> externalFrames, List<List<CallInfo>> allFrames) {
  // We should have the same number of frames for both external-only
  // and combined call information.
  expect(externalFrames.length, equals(allFrames.length));
  // There should be no frames in either version where we failed to look up
  // call information.
  expect(externalFrames, everyElement(isNotNull));
  expect(allFrames, everyElement(isNotNull));
  // All frames in the internal-including version should have at least one
  // piece of call information.
  expect(allFrames, everyElement(isNotEmpty));
  // External-only call information should only include call information with
  // positive line numbers.
  expect(
      externalFrames, everyElement(everyElement(predicate((c) => c.line > 0))));
  // The information in the external-only and combined call information should
  // be consistent for external frames.
  for (var i = 0; i < allFrames.length; i++) {
    expect(externalFrames[i], anyOf(isEmpty, equals(allFrames[i])));
  }
}

void checkFrames(
    List<List<CallInfo>> framesInfo, List<List<CallInfo>> expectedInfo) {
  // There may be frames below those we check.
  expect(framesInfo.length, greaterThanOrEqualTo(expectedInfo.length));

  // We can't just use deep equality, since we only have the filenames in the
  // expected version, not the whole path, and we don't really care if
  // non-positive line numbers match, as long as they're both non-positive.
  for (var i = 0; i < expectedInfo.length; i++) {
    for (var j = 0; j < expectedInfo[i].length; j++) {
      final got = framesInfo[i][j];
      final expected = expectedInfo[i][j];
      expect(got.function, equals(expected.function));
      expect(got.inlined, equals(expected.inlined));
      expect(path.basename(got.filename), equals(expected.filename));
      if (expected.line > 0) {
        expect(got.line, equals(expected.line));
      } else {
        expect(got.line, lessThanOrEqualTo(0));
      }
    }
  }
}

List<String> extractCallStrings(List<List<CallInfo>> expectedCalls) {
  var ret = <String>[];
  for (final frame in expectedCalls) {
    for (final call in frame) {
      ret.add(call.function);
      if (call.line > 0) {
        ret.add("${call.filename}:${call.line}");
      } else {
        ret.add("${call.filename}:??");
      }
    }
  }
  return ret;
}
