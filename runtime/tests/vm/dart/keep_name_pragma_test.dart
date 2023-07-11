// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--resolve-dwarf-paths --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;

final dwarfPath =
    path.join(Platform.environment['TEST_COMPILATION_DIR']!, 'debug.so');
final usesObfuscation =
    const String.fromEnvironment("test_runner.configuration")
        .contains('obfuscate');
final usesDwarf =
    const String.fromEnvironment("test_runner.configuration").contains('dwarf');

Future<void> main(List<String> args) async {
  if (Platform.isAndroid) return;

  final List<String> stack = await run(6);
  final o = usesObfuscation ? '!' : '';

  compareFrames([
    '${o}bottom',
    'KeepClass.keepMethod',
    '${o}NormalClass.normalMethod',
    'keepStatic',
    '${o}normalStatic',
    '${o}run',
  ], stack);
}

void compareFrames(List<String> patterns, List<String> stack) {
  if (patterns.length != stack.length) {
    throw 'Expected ${patterns.length} frames';
  }
  print('Comparing this pattern: \n  ${patterns.join('\n  ')}');
  print('Against these frames: \n  ${stack.join('\n  ')}');
  for (int i = 0; i < patterns.length; ++i) {
    final pattern = patterns[i];
    final frame = stack[i];
    if (pattern.startsWith('!')) {
      Expect.notEquals(pattern.substring(1), frame);
    } else {
      Expect.equals(pattern, frame);
    }
  }
  print('');
}

@pragma('vm:never-inline')
void bottom() {
  throw 'bad';
}

@pragma('vm:keep-name')
class KeepClass {
  @pragma('vm:never-inline')
  @pragma('vm:keep-name')
  void keepMethod() {
    bottom();
  }
}

class NormalClass {
  @pragma('vm:never-inline')
  void normalMethod() {
    keep.keepMethod();
  }
}

final normal = NormalClass();
final keep = KeepClass();

@pragma('vm:never-inline')
@pragma('vm:keep-name')
void keepStatic() {
  normal.normalMethod();
}

@pragma('vm:never-inline')
void normalStatic() {
  keepStatic();
}

Future<List<String>> run(int n) async {
  try {
    normalStatic();
  } catch (e, s) {
    List<String> lines = s.toString().split('\n');
    if (usesDwarf) {
      final dwarf = Dwarf.fromFile(dwarfPath)!;
      lines = await Stream<String>.fromIterable(lines)
          .transform(DwarfStackTraceDecoder(dwarf))
          .toList();
    }
    final start = lines.indexWhere((line) => line.startsWith('#0'));
    lines = lines.skip(start).take(n).toList();
    return lines.map((String line) {
      line = line.substring(line.indexOf(' ')).trim();
      line = line.substring(0, line.indexOf(' ')).trim();
      return line;
    }).toList();
  }
  throw 'failed';
}
