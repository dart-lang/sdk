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
    Expect.deepEquals(
        collectPCOffsets(dwarfTrace1), collectPCOffsets(dwarfTrace2));

    // Check that translating the DWARF stack trace (without internal frames)
    // matches the symbolic stack trace.
    final dwarf = Dwarf.fromFile(scriptDwarfDebugInfo);
    assert(dwarf != null);
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

    Expect.deepEquals(translatedStackFrames, originalStackFrames);
  });
}

final _symbolicFrameRE = RegExp(r'^#\d+\s+');

Iterable<String> onlySymbolicFrameLines(Iterable<String> lines) {
  return lines.where((line) => _symbolicFrameRE.hasMatch(line));
}
