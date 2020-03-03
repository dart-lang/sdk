// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--dwarf-stack-traces --save-debugging-info=dwarf.so

import 'dart:convert';
import 'dart:io';

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

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

  final rawLines =
      await Stream.value(rawStack).transform(const LineSplitter()).toList();

  final pcOffsets = collectPCOffsets(rawLines).toList();

  // We should have at least enough PC addresses to cover the frames we'll be
  // checking.
  Expect.isTrue(pcOffsets.length >= expectedAllCallsInfo.length);

  final virtualAddresses =
      pcOffsets.map((o) => dwarf.virtualAddressOf(o)).toList();

  final externalFramesInfo = <List<CallInfo>>[];
  final allFramesInfo = <List<CallInfo>>[];

  for (final addr in virtualAddresses) {
    externalFramesInfo.add(dwarf.callInfoFor(addr)?.toList());
    allFramesInfo
        .add(dwarf.callInfoFor(addr, includeInternalFrames: true)?.toList());
  }

  print("");
  print("Call information for PC addresses:");
  for (var i = 0; i < virtualAddresses.length; i++) {
    print("For PC 0x${virtualAddresses[i].toRadixString(16)}:");
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

  Expect.isTrue(externalSymbolizedCalls.length >= expectedExternalCallCount);
  Expect.isTrue(allSymbolizedCalls.length >= expectedCallCount);

  // Strip off any unexpected lines, so we can also make sure we didn't get
  // unexpected calls prior to those calls we expect.
  final externalCallsTrace =
      externalSymbolizedCalls.sublist(0, expectedExternalCallCount).join('\n');
  final allCallsTrace =
      allSymbolizedCalls.sublist(0, expectedCallCount).join('\n');

  Expect.stringContainsInOrder(externalCallsTrace, expectedExternalStrings);
  Expect.stringContainsInOrder(allCallsTrace, expectedStrings);
}

final expectedCallsInfo = <List<CallInfo>>[
  // The first frame should correspond to the throw in bar, which was inlined
  // into foo (so we'll get information for two calls for that PC address).
  [
    CallInfo(
        function: "bar",
        filename: "dwarf_stack_trace_test.dart",
        line: 17,
        inlined: true),
    CallInfo(
        function: "foo",
        filename: "dwarf_stack_trace_test.dart",
        line: 23,
        inlined: false)
  ],
  // The second frame corresponds to call to foo in main.
  [
    CallInfo(
        function: "main",
        filename: "dwarf_stack_trace_test.dart",
        line: 29,
        inlined: false)
  ],
  // Don't assume anything about any of the frames below the call to foo
  // in main, as this makes the test too brittle.
];

List<List<CallInfo>> removeInternalCalls(List<List<CallInfo>> original) =>
    original
        .map((frame) => frame.where((call) => call.line > 0).toList())
        .toList();

void checkConsistency(
    List<List<CallInfo>> externalFrames, List<List<CallInfo>> allFrames) {
  // We should have the same number of frames for both external-only
  // and combined call information.
  Expect.equals(externalFrames.length, allFrames.length);

  for (var frame in externalFrames) {
    // There should be no frames in either version where we failed to look up
    // call information.
    Expect.isNotNull(frame);

    // External-only call information should only include call information with
    // positive line numbers.
    for (var call in frame) {
      Expect.isTrue(call.line > 0);
    }
  }

  for (var frame in allFrames) {
    // There should be no frames in either version where we failed to look up
    // call information.
    Expect.isNotNull(frame);

    // All frames in the internal-including version should have at least one
    // piece of call information.
    Expect.isTrue(frame.isNotEmpty);
  }

  // The information in the external-only and combined call information should
  // be consistent for external frames.
  for (var i = 0; i < allFrames.length; i++) {
    if (externalFrames[i].isNotEmpty) {
      Expect.listEquals(externalFrames[i], allFrames[i]);
    }
  }
}

void checkFrames(
    List<List<CallInfo>> framesInfo, List<List<CallInfo>> expectedInfo) {
  // There may be frames below those we check.
  Expect.isTrue(framesInfo.length >= expectedInfo.length);

  // We can't just use deep equality, since we only have the filenames in the
  // expected version, not the whole path, and we don't really care if
  // non-positive line numbers match, as long as they're both non-positive.
  for (var i = 0; i < expectedInfo.length; i++) {
    for (var j = 0; j < expectedInfo[i].length; j++) {
      final got = framesInfo[i][j];
      final expected = expectedInfo[i][j];
      Expect.equals(got.function, expected.function);
      Expect.equals(got.inlined, expected.inlined);
      Expect.equals(path.basename(got.filename), expected.filename);
      if (expected.line > 0) {
        Expect.equals(got.line, expected.line);
      } else {
        Expect.isTrue(got.line <= 0);
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
