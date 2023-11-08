// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';

//
// Test framework
//

class _ParsedFrame {
  const _ParsedFrame();

  static _ParsedFrame parse(String frame) {
    if (frame == '<asynchronous suspension>') {
      return const _AsynchronousGap();
    } else {
      return _DartFrame.parse(frame);
    }
  }
}

class _DartFrame extends _ParsedFrame {
  final int no;
  final String symbol;
  final String location;
  final int? lineNo;

  _DartFrame({
    required this.no,
    required this.symbol,
    required this.location,
    required this.lineNo,
  });

  static final _pattern = RegExp(
      r'^#(?<no>\d+)\s+(?<symbol>[^(]+)(\((?<location>((\w+://)?[/\w]+:)?[^:]+)(:(?<line>\d+)(:(?<column>\d+))?)?\))?$');

  static _DartFrame parse(String frame) {
    final match = _pattern.firstMatch(frame);
    if (match == null) {
      throw 'Failed to parse: $frame';
    }

    final no = int.parse(match.namedGroup('no')!);
    final symbol = match.namedGroup('symbol')!.trim();
    var location = match.namedGroup('location')!;
    if (location.endsWith('_test.dart')) {
      location = '%test%';
    }
    final lineNo =
        location.endsWith('utils.dart') || location.endsWith('tests.dart')
            ? match.namedGroup('line')
            : null;

    return _DartFrame(
      no: no,
      symbol: symbol,
      location: location.split('/').last,
      lineNo: lineNo != null ? int.parse(lineNo) : null,
    );
  }

  @override
  String toString() =>
      '#$no    $symbol ($location${lineNo != null ? ':$lineNo' : ''})';

  @override
  bool operator ==(Object other) {
    if (other is! _DartFrame) {
      return false;
    }

    return no == other.no &&
        symbol == other.symbol &&
        location == other.location &&
        lineNo == other.lineNo;
  }
}

class _AsynchronousGap extends _ParsedFrame {
  const _AsynchronousGap();

  @override
  String toString() => '<asynchronous suspension>';
}

final _lineRE = RegExp(r'^(?:#(?<number>\d+)|<asynchronous suspension>)');

Future<List<_ParsedFrame>> _parseStack(String text) async {
  if (text.contains('*** *** ***')) {
    // Looks like DWARF stack traces mode.
    text = await Stream.fromIterable(text.split('\n'))
        .transform(DwarfStackTraceDecoder(_dwarf!))
        .where(_lineRE.hasMatch)
        .join('\n');
  }

  return text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map(_ParsedFrame.parse)
      .toList();
}

const _updatingExpectations = bool.fromEnvironment('update.expectations');

final _updatedExpectations = <String>[];
late final List<String> _currentExpectations;

var _testIndex = 0;

late final Dwarf? _dwarf;

void configure(List<String> currentExpectations,
    {String debugInfoFilename = 'debug.so'}) {
  try {
    final testCompilationDir = Platform.environment['TEST_COMPILATION_DIR'];
    if (testCompilationDir != null) {
      debugInfoFilename = path.join(testCompilationDir, debugInfoFilename);
    }
    _dwarf = Dwarf.fromFile(debugInfoFilename)!;
  } on FileSystemException {
    // We're not running in precompiled mode, so the file doesn't exist and
    // we can continue normally.
  }
  _currentExpectations = currentExpectations;
}

Future<void> runTest(Future<void> Function() body) async {
  try {
    await body();
  } catch (e, st) {
    await checkExpectedStack(st);
  }
}

Future<void> checkExpectedStack(StackTrace st) async {
  final expectedFramesString = _testIndex < _currentExpectations.length
      ? _currentExpectations[_testIndex]
      : '';
  final stackTraceString = st.toString();
  final gotFrames = await _parseStack(stackTraceString);
  final normalizedStack = gotFrames.join('\n');
  if (_updatingExpectations) {
    _updatedExpectations.add(normalizedStack);
  } else {
    if (normalizedStack != expectedFramesString) {
      final expectedFrames = await _parseStack(expectedFramesString);
      final isDwarfMode = stackTraceString.contains('*** *** ***');
      print('''
STACK TRACE MISMATCH -----------------
GOT:
$normalizedStack
EXPECTED:
$expectedFramesString
--------------------------------------
To regenate expectations run:
\$ ${Platform.executable} -Dupdate.expectations=true ${Platform.script}
--------------------------------------
''');
      if (isDwarfMode) {
        print('''
--------------------------------------
RAW STACK:
$st
--------------------------------------
''');
      }

      Expect.equals(
          expectedFrames.length, gotFrames.length, 'wrong number of frames');
      for (var i = 0; i < expectedFrames.length; i++) {
        final expectedFrame = expectedFrames[i];
        final gotFrame = gotFrames[i];
        if (expectedFrame == gotFrame) {
          continue;
        }

        if (expectedFrame is _DartFrame && gotFrame is _DartFrame) {
          Expect.equals(expectedFrame.symbol, gotFrame.symbol,
              'at frame #$i mismatched function name');
          Expect.equals(expectedFrame.location, gotFrame.location,
              'at frame #$i mismatched location');
          Expect.equals(expectedFrame.lineNo, gotFrame.lineNo,
              'at frame #$i mismatched line location');
        }

        Expect.equals(expectedFrame, gotFrame);
      }
    }
  }
  _testIndex++;
}

void updateExpectations([String? expectationsFile]) {
  if (!_updatingExpectations) {
    return;
  }

  final sourceFilePath = expectationsFile != null
      ? path.join(path.dirname(Platform.script.toFilePath()), expectationsFile)
      : Platform.script.toFilePath();
  final sourceFile = File(sourceFilePath);

  final source = sourceFile.readAsStringSync();

  final expectationsStart = source.lastIndexOf('// CURRENT EXPECTATIONS BEGIN');
  final updatedExpectationsString =
      [for (var s in _updatedExpectations) '"""\n$s"""'].join(",\n");

  final newSource = source.substring(0, expectationsStart) +
      """
// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [${updatedExpectationsString}];
// CURRENT EXPECTATIONS END
""";

  sourceFile.writeAsStringSync(newSource);
  print('updated expectations in ${sourceFile}!');
}

// Check if we are running with obfuscation but without DWARF stack traces
// then we don't have a way to deobfuscate the stack trace.
bool shouldSkip() {
  final stack = StackTrace.current.toString();
  final isObfuscateMode = !stack.contains('shouldSkip');
  final isDwarfStackTracesMode = stack.contains('*** ***');

  // We should skip the test if we are running without DWARF stack
  // traces enabled but with obfuscation.
  return !isDwarfStackTracesMode && isObfuscateMode;
}
