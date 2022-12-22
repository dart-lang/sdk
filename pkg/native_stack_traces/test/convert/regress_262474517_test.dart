// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:native_stack_traces/src/convert.dart';
import 'package:native_stack_traces/src/dwarf.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('convert tests', defineConvertTests);
}

final String pkgDir = Platform.script.resolve('../..').toFilePath();

void defineConvertTests() {
  test('b/262474517 regression', () async {
    final inputDir = path.join(pkgDir, 'testcases', 'convert');
    // Test with a prefix without four spaces between prefix and trace.
    testPath(path.join(inputDir, 'regress_262474517_trace.txt'));
    // Test for no prefix or whitespace at all.
    testPath(path.join(inputDir, 'regress_262474517_trace_2.txt'));
  });
}

void testPath(String inputPath) async {
  final contents = await File(inputPath).readAsLines();
  final pcOffsets = collectPCOffsets(contents);
  expect(pcOffsets.map((o) => o.offset).toList(),
      [0x14e87f, 0x2a4e27, 0x4ee12b, 0x477fc7]);
  expect(pcOffsets.map((o) => o.section).toList(), [
    InstructionsSection.isolate,
    InstructionsSection.isolate,
    InstructionsSection.isolate,
    InstructionsSection.isolate
  ]);
}
