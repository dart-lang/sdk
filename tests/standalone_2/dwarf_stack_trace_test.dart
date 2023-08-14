// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/dwarf.so

import 'dart:convert';
import 'dart:io';

import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

@pragma("vm:prefer-inline")
bar() {
  // Keep the 'throw' and its argument on separate lines.
  throw // force linebreak with dart format
      "Hello, Dwarf!";
}

@pragma("vm:never-inline")
foo() {
  bar();
}

Future<void> main() async {
  String rawStack = "";
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

  final dwarf = Dwarf.fromFile(
      path.join(Platform.environment['TEST_COMPILATION_DIR'], "dwarf.so"));

  await checkStackTrace(rawStack, dwarf, expectedCallsInfo);
}

Future<void> checkStackTrace(String rawStack, Dwarf dwarf,
    List<List<DartCallInfo>> expectedCallsInfo) async {
  print("");
  print("Raw stack trace:");
  print(rawStack);

  final rawLines =
      await Stream.value(rawStack).transform(const LineSplitter()).toList();

  final pcOffsets = collectPCOffsets(rawLines).toList();
  Expect.isNotEmpty(pcOffsets);

  print('PCOffsets:');
  for (final offset in pcOffsets) {
    print('* $offset');
  }
  print('');

  // We should have at least enough PC addresses to cover the frames we'll be
  // checking.
  Expect.isTrue(pcOffsets.length >= expectedCallsInfo.length);

  final isolateStart = dwarf.isolateStartAddress(pcOffsets.first.architecture);
  Expect.isNotNull(isolateStart);
  print('Isolate start offset: 0x${isolateStart.toRadixString(16)}');

  // The addresses of the stack frames in the separate DWARF debugging info.
  final virtualAddresses =
      pcOffsets.map((o) => dwarf.virtualAddressOf(o)).toList();

  print('Virtual addresses from PCOffsets:');
  for (final address in virtualAddresses) {
    print('* 0x${address.toRadixString(16)}');
  }
  print('');

  // Some double-checks using other information in the non-symbolic stack trace.
  final dsoBase = dsoBaseAddresses(rawLines).single;
  print('DSO base address: 0x${dsoBase.toRadixString(16)}');

  final absoluteIsolateStart = isolateStartAddresses(rawLines).single;
  print('Absolute isolate start address: '
      '0x${absoluteIsolateStart.toRadixString(16)}');

  final absolutes = absoluteAddresses(rawLines);
  // The relocated addresses of the stack frames in the loaded DSO. These is
  // only guaranteed to be the same as virtualAddresses if the built-in ELF
  // generator was used to create the snapshot.
  final relocatedAddresses = absolutes.map((a) => a - dsoBase);

  print('Relocated absolute addresses:');
  for (final address in relocatedAddresses) {
    print('* 0x${address.toRadixString(16)}');
  }
  print('');

  // Explicits will be empty if not generating ELF snapshots directly, which
  // means we can't depend on virtual addresses in the snapshot lining up with
  // those in the separate debugging information.
  final explicits = explicitVirtualAddresses(rawLines);
  if (explicits.isNotEmpty) {
    print('Explicit virtual addresses:');
    for (final address in explicits) {
      print('* 0x${address.toRadixString(16)}');
    }
    print('');
    // Direct-to-ELF snapshots should have a build ID.
    Expect.isNotNull(dwarf.buildId);
    Expect.deepEquals(explicits, virtualAddresses);

    // This is an ELF snapshot, so check that these two are the same.
    Expect.deepEquals(virtualAddresses, relocatedAddresses);
  }

  final gotCallsInfo = <List<DartCallInfo>>[];

  for (final offset in pcOffsets) {
    final externalCallInfo = dwarf.callInfoForPCOffset(offset);
    Expect.isNotNull(externalCallInfo);
    final allCallInfo =
        dwarf.callInfoForPCOffset(offset, includeInternalFrames: true);
    Expect.isNotNull(allCallInfo);
    for (final call in externalCallInfo) {
      Expect.isTrue(call is DartCallInfo, "got non-Dart call info ${call}");
      Expect.isFalse(call.isInternal);
      Expect.isTrue(allCallInfo.contains(call),
          "External call info ${call} is not among all calls");
    }
    for (final call in allCallInfo) {
      if (!call.isInternal) {
        Expect.isTrue(externalCallInfo.contains(call),
            "External call info ${call} is not among external calls");
      }
    }
    gotCallsInfo.add(externalCallInfo.cast<DartCallInfo>().toList());
  }

  print("");
  print("Call information for PC addresses:");
  for (var i = 0; i < virtualAddresses.length; i++) {
    print("For PC 0x${virtualAddresses[i].toRadixString(16)}:");
    print("  Calls corresponding to user or library code:");
    gotCallsInfo[i].forEach((frame) => print("    ${frame}"));
  }

  // Remove empty entries which correspond to skipped internal frames.
  gotCallsInfo.removeWhere((calls) => calls.isEmpty);

  checkFrames(gotCallsInfo, expectedCallsInfo);

  final gotSymbolizedLines = await Stream.fromIterable(rawLines)
      .transform(DwarfStackTraceDecoder(dwarf, includeInternalFrames: false))
      .toList();

  final gotSymbolizedCalls =
      gotSymbolizedLines.where((s) => s.startsWith('#')).toList();

  print("");
  print("Symbolized stack trace:");
  gotSymbolizedLines.forEach(print);
  print("");
  print("Extracted calls:");
  gotSymbolizedCalls.forEach(print);

  final expectedStrings = extractCallStrings(expectedCallsInfo);
  // There are two strings in the list for each line in the output.
  final expectedCallCount = expectedStrings.length ~/ 2;

  Expect.isTrue(gotSymbolizedCalls.length >= expectedCallCount);

  // Strip off any unexpected lines, so we can also make sure we didn't get
  // unexpected calls prior to those calls we expect.
  final gotCallsTrace =
      gotSymbolizedCalls.sublist(0, expectedCallCount).join('\n');

  Expect.stringContainsInOrder(gotCallsTrace, expectedStrings);
}

final expectedCallsInfo = <List<DartCallInfo>>[
  // The first frame should correspond to the throw in bar, which was inlined
  // into foo (so we'll get information for two calls for that PC address).
  [
    DartCallInfo(
        function: "bar",
        filename: "dwarf_stack_trace_test.dart",
        line: 19,
        column: 3,
        inlined: true),
    DartCallInfo(
        function: "foo",
        filename: "dwarf_stack_trace_test.dart",
        line: 25,
        column: 3,
        inlined: false)
  ],
  // The second frame corresponds to call to foo in main.
  [
    DartCallInfo(
        function: "main",
        filename: "dwarf_stack_trace_test.dart",
        line: 31,
        column: 5,
        inlined: false)
  ],
  // Don't assume anything about any of the frames below the call to foo
  // in main, as this makes the test too brittle.
];

void checkFrames(
    List<List<DartCallInfo>> gotInfo, List<List<DartCallInfo>> expectedInfo) {
  // There may be frames below those we check.
  Expect.isTrue(gotInfo.length >= expectedInfo.length);

  // We can't just use deep equality, since we only have the filenames in the
  // expected version, not the whole path, and we don't really care if
  // non-positive line numbers match, as long as they're both non-positive.
  for (var i = 0; i < expectedInfo.length; i++) {
    for (var j = 0; j < expectedInfo[i].length; j++) {
      final got = gotInfo[i][j];
      final expected = expectedInfo[i][j];
      Expect.equals(expected.function, got.function);
      Expect.equals(expected.inlined, got.inlined);
      Expect.equals(expected.filename, path.basename(got.filename));
      if (expected.isInternal) {
        Expect.isTrue(got.isInternal);
      } else {
        Expect.equals(expected.line, got.line);
      }
    }
  }
}

List<String> extractCallStrings(List<List<CallInfo>> expectedCalls) {
  var ret = <String>[];
  for (final frame in expectedCalls) {
    for (final call in frame) {
      if (call is DartCallInfo) {
        ret.add(call.function);
        if (call.isInternal) {
          ret.add("${call.filename}:??");
        } else {
          ret.add("${call.filename}:${call.line}");
        }
      }
    }
  }
  return ret;
}

Iterable<int> parseUsingAddressRegExp(RegExp re, Iterable<String> lines) sync* {
  for (final line in lines) {
    final match = re.firstMatch(line);
    if (match == null) continue;
    final s = match.group(1);
    if (s == null) continue;
    yield int.parse(s, radix: 16);
  }
}

final _absRE = RegExp(r'abs ([a-f\d]+)');

Iterable<int> absoluteAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_absRE, lines);

final _virtRE = RegExp(r'virt ([a-f\d]+)');

Iterable<int> explicitVirtualAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_virtRE, lines);

final _dsoBaseRE = RegExp(r'isolate_dso_base: ([a-f\d]+)');

Iterable<int> dsoBaseAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_dsoBaseRE, lines);

final _isolateStartRE = RegExp(r'isolate_instructions: ([a-f\d]+)');

Iterable<int> isolateStartAddresses(Iterable<String> lines) =>
    parseUsingAddressRegExp(_isolateStartRE, lines);
