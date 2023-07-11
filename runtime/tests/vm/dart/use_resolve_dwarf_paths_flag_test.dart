// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that --resolve-dwarf-paths outputs absolute and relative
// paths in DWARF information.
//
// VMOptions=--dwarf-stack-traces --resolve-dwarf-paths --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as p;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (Platform.isAndroid) {
    return;
  }

  final isDwarfStackTraces = StackTrace.current.toString().contains('*** ***');
  if (!isDwarfStackTraces) {
    return;
  }

  final dwarfPath =
      p.join(Platform.environment['TEST_COMPILATION_DIR']!, 'debug.so');
  final dwarf = Dwarf.fromFile(dwarfPath)!;

  final stack = StackTrace.current.toString();
  print(stack);
  final offsets = collectPCOffsets(stack.split('\n'));
  print(offsets);
  checkDwarfInfo(dwarf, offsets);
}

void checkDwarfInfo(Dwarf dwarf, Iterable<PCOffset> offsets) {
  final filenames = <String>{};
  for (final offset in offsets) {
    final callInfo = offset.callInfoFrom(dwarf, includeInternalFrames: true);
    Expect.isNotNull(callInfo);
    Expect.isNotEmpty(callInfo!);
    for (final e in callInfo) {
      Expect.isTrue(e is DartCallInfo, 'Call is not from the Dart source: $e.');
      final entry = e as DartCallInfo;
      var filename = entry.filename;
      if (!filename.startsWith('/')) {
        filename = p.join(sdkDir, filename);
      }
      if (filenames.add(filename)) {
        Expect.isTrue(
            File(filename).existsSync(), 'File $filename does not exist.');
      }
    }
  }
  print('Checked filenames:');
  for (final filename in filenames) {
    print('- ${filename}');
  }
  Expect.isNotEmpty(filenames);
  Expect.isNotEmpty(filenames
      .where((p) => p.endsWith('use_resolve_dwarf_paths_flag_test.dart')));
}
