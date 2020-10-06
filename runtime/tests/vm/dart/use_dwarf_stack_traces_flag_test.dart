// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that the flag for --dwarf-stack-traces given at AOT
// compile-time will be used at runtime (irrespective if other values were
// passed to the runtime).

// OtherResources=use_dwarf_stack_traces_flag_program.dart

import "dart:async";
import "dart:io";

import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

main(List<String> args) async {
  if (!isAOTRuntime) {
    return; // Running in JIT: AOT binaries not available.
  }

  if (Platform.isAndroid) {
    return; // SDK tree and dart_bootstrap not available on the test device.
  }

  // These are the tools we need to be available to run on a given platform:
  if (!await testExecutable(genSnapshot)) {
    throw "Cannot run test as $genSnapshot not available";
  }
  if (!await testExecutable(aotRuntime)) {
    throw "Cannot run test as $aotRuntime not available";
  }
  if (!File(platformDill).existsSync()) {
    throw "Cannot run test as $platformDill does not exist";
  }

  await withTempDir('dwarf-flag-test', (String tempDir) async {
    final cwDir = path.dirname(Platform.script.toFilePath());
    final script = path.join(cwDir, 'use_dwarf_stack_traces_flag_program.dart');
    final scriptDill = path.join(tempDir, 'flag_program.dill');

    // Compile script to Kernel IR.
    await run(genKernel, <String>[
      '--aot',
      '--platform=$platformDill',
      '-o',
      scriptDill,
      script,
    ]);

    // Run the AOT compiler with/without Dwarf stack traces.
    final scriptDwarfSnapshot = path.join(tempDir, 'dwarf.so');
    final scriptNonDwarfSnapshot = path.join(tempDir, 'non_dwarf.so');
    final scriptDwarfDebugInfo = path.join(tempDir, 'debug_info.so');
    await Future.wait(<Future>[
      run(genSnapshot, <String>[
        // We test --dwarf-stack-traces-mode, not --dwarf-stack-traces, because
        // the latter is a handler that sets the former and also may change
        // other flags. This way, we limit the difference between the two
        // snapshots and also directly test the flag saved as a VM global flag.
        '--dwarf-stack-traces-mode',
        '--save-debugging-info=$scriptDwarfDebugInfo',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptDwarfSnapshot',
        scriptDill,
      ]),
      run(genSnapshot, <String>[
        '--no-dwarf-stack-traces-mode',
        '--snapshot-kind=app-aot-elf',
        '--elf=$scriptNonDwarfSnapshot',
        scriptDill,
      ]),
    ]);

    // Run the resulting Dwarf-AOT compiled script.
    final dwarfTrace1 = await runError(aotRuntime, <String>[
      '--dwarf-stack-traces-mode',
      scriptDwarfSnapshot,
      scriptDill,
    ]);
    final dwarfTrace2 = await runError(aotRuntime, <String>[
      '--no-dwarf-stack-traces-mode',
      scriptDwarfSnapshot,
      scriptDill,
    ]);

    // Run the resulting non-Dwarf-AOT compiled script.
    final nonDwarfTrace1 = await runError(aotRuntime, <String>[
      '--dwarf-stack-traces-mode',
      scriptNonDwarfSnapshot,
      scriptDill,
    ]);
    final nonDwarfTrace2 = await runError(aotRuntime, <String>[
      '--no-dwarf-stack-traces-mode',
      scriptNonDwarfSnapshot,
      scriptDill,
    ]);

    // Ensure the result is based off the flag passed to gen_snapshot, not
    // the one passed to the runtime.
    Expect.deepEquals(nonDwarfTrace1, nonDwarfTrace2);

    // For DWARF stack traces, we can't guarantee that the stack traces are
    // textually equal on all platforms, but if we retrieve the PC offsets
    // out of the stack trace, those should be equal.
    final tracePCOffsets1 = collectPCOffsets(dwarfTrace1);
    final tracePCOffsets2 = collectPCOffsets(dwarfTrace2);
    Expect.deepEquals(tracePCOffsets1, tracePCOffsets2);

    // Check that translating the DWARF stack trace (without internal frames)
    // matches the symbolic stack trace.
    final dwarf = Dwarf.fromFile(scriptDwarfDebugInfo)!;

    // Check that build IDs match for traces.
    Expect.isNotNull(dwarf.buildId);
    print('Dwarf build ID: "${dwarf.buildId!}"');
    final buildId1 = buildId(dwarfTrace1);
    Expect.isFalse(buildId1.isEmpty);
    print('Trace 1 build ID: "${buildId1}"');
    Expect.equals(dwarf.buildId, buildId1);
    final buildId2 = buildId(dwarfTrace2);
    Expect.isFalse(buildId2.isEmpty);
    print('Trace 2 build ID: "${buildId2}"');
    Expect.equals(dwarf.buildId, buildId2);

    final translatedDwarfTrace1 = await Stream.fromIterable(dwarfTrace1)
        .transform(DwarfStackTraceDecoder(dwarf))
        .toList();

    final translatedStackFrames = onlySymbolicFrameLines(translatedDwarfTrace1);
    final originalStackFrames = onlySymbolicFrameLines(nonDwarfTrace1);

    print('Stack frames from translated non-symbolic stack trace:');
    translatedStackFrames.forEach(print);
    print('');

    print('Stack frames from original symbolic stack trace:');
    originalStackFrames.forEach(print);
    print('');

    Expect.isTrue(translatedStackFrames.length > 0);
    Expect.isTrue(originalStackFrames.length > 0);

    // In symbolic mode, we don't store column information to avoid an increase
    // in size of CodeStackMaps. Thus, we need to strip any columns from the
    // translated non-symbolic stack to compare them via equality.
    final columnStrippedTranslated = removeColumns(translatedStackFrames);

    print('Stack frames from translated non-symbolic stack trace, no columns:');
    columnStrippedTranslated.forEach(print);
    print('');

    Expect.deepEquals(columnStrippedTranslated, originalStackFrames);

    // Since we compiled directly to ELF, there should be a DSO base address
    // in the stack trace header and 'virt' markers in the stack frames.

    // The offsets of absolute addresses from their respective DSO base
    // should be the same for both traces.
    final dsoBase1 = dsoBaseAddresses(dwarfTrace1).single;
    final dsoBase2 = dsoBaseAddresses(dwarfTrace2).single;

    final absTrace1 = absoluteAddresses(dwarfTrace1);
    final absTrace2 = absoluteAddresses(dwarfTrace2);

    final relocatedFromDso1 = absTrace1.map((a) => a - dsoBase1);
    final relocatedFromDso2 = absTrace2.map((a) => a - dsoBase2);

    Expect.deepEquals(relocatedFromDso1, relocatedFromDso2);

    // The relocated addresses marked with 'virt' should match between the
    // different runs, and they should also match the relocated address
    // calculated from the PCOffset for each frame as well as the relocated
    // address for each frame calculated using the respective DSO base.
    final virtTrace1 = explicitVirtualAddresses(dwarfTrace1);
    final virtTrace2 = explicitVirtualAddresses(dwarfTrace2);

    Expect.deepEquals(virtTrace1, virtTrace2);

    Expect.deepEquals(
        virtTrace1, tracePCOffsets1.map((o) => o.virtualAddressIn(dwarf)));
    Expect.deepEquals(
        virtTrace2, tracePCOffsets2.map((o) => o.virtualAddressIn(dwarf)));

    Expect.deepEquals(virtTrace1, relocatedFromDso1);
    Expect.deepEquals(virtTrace2, relocatedFromDso2);
  });
}

final _buildIdRE = RegExp(r"build_id: '([a-f\d]+)'");
String buildId(Iterable<String> lines) {
  for (final line in lines) {
    final match = _buildIdRE.firstMatch(line);
    if (match != null) {
      return match.group(1)!;
    }
  }
  return '';
}

final _symbolicFrameRE = RegExp(r'^#\d+\s+');

Iterable<String> onlySymbolicFrameLines(Iterable<String> lines) {
  return lines.where((line) => _symbolicFrameRE.hasMatch(line));
}

final _columnsRE = RegExp(r'[(](.*:\d+):\d+[)]');

Iterable<String> removeColumns(Iterable<String> lines) sync* {
  for (final line in lines) {
    final match = _columnsRE.firstMatch(line);
    if (match != null) {
      yield line.replaceRange(match.start, match.end, '(${match.group(1)!})');
    } else {
      yield line;
    }
  }
}

Iterable<int> parseUsingAddressRegExp(RegExp re, Iterable<String> lines) sync* {
  for (final line in lines) {
    final match = re.firstMatch(line);
    if (match != null) {
      yield int.parse(match.group(1)!, radix: 16);
    }
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
