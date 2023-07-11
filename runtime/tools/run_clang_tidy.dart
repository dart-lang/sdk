// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:pool/pool.dart';

// "perfetto_build_flags.h" is included by some Perfetto headers that we
// include, but it is generated at build-time. We prevent clang-tidy from
// reporting a "file not found" error by ensuring that this file exists in
// Iout/DebugX64/gen and passing
// -Iout/DebugX64/gen/third_party/perfetto/build_config to clang-tidy below.
Future<void> generatePerfettoBuildFlags() async {
  final processResult = await Process.run(
    './tools/build.py',
    ['-mdebug', '-ax64', '--no-goma', 'third_party/perfetto/gn:gen_buildflags'],
  );

  final int exitCode = processResult.exitCode;
  final String stdout = processResult.stdout.trim();
  final String stderr = processResult.stderr.trim();

  if (exitCode != 0) {
    print('exit-code: $exitCode');
    print('stdout:');
    print('${stdout}');
    print('stderr:');
    print('${stderr}');
  }
}

const String clangTidy = './buildtools/linux-x64/clang/bin/clang-tidy';

List<String> compilerFlagsForFile(String filepath) {
  String arch = "X64";
  if (filepath.contains("_arm.")) arch = "ARM";
  if (filepath.contains("_arm64.")) arch = "ARM64";
  if (filepath.contains("_riscv.")) arch = "RISCV64";
  // Skipping IA32 because it neither has a simulator nor works with crossword
  // and the host architecture is fixed.

  final flags = <String>[
    '-Iruntime',
    '-Ithird_party',
    '-Iruntime/include',
    '-Ithird_party/boringssl/src/include',
    '-Ithird_party/perfetto/include',
    '-Ithird_party/zlib',
    '-Iout/DebugX64/gen/third_party/perfetto/build_config',
    '-DTARGET_ARCH_$arch',
    '-DTESTING',
    '-std=c++17',
    '-x',
    'c++',
  ];
  return flags;
}

final pool = new Pool(max(1, Platform.numberOfProcessors ~/ 2));

// Exclude running the linter on those files.
final Set<String> excludedFiles = Set<String>.from([
  // These files are not valid cc files but rather cc templates
  'runtime/bin/abi_version_in.cc',
  'runtime/bin/builtin_in.cc',
  'runtime/bin/snapshot_in.cc',
  'runtime/lib/libgen_in.cc',
  'runtime/vm/version_in.cc',

  // These files cannot be analyzed by itself (must be included indirectly).
  'runtime/bin/android.h',
  'runtime/bin/eventhandler_android.h',
  'runtime/bin/eventhandler_fuchsia.h',
  'runtime/bin/eventhandler_linux.h',
  'runtime/bin/eventhandler_macos.h',
  'runtime/bin/eventhandler_win.h',
  'runtime/bin/namespace_android.h',
  'runtime/bin/namespace_fuchsia.h',
  'runtime/bin/namespace_linux.h',
  'runtime/bin/namespace_macos.h',
  'runtime/bin/namespace_win.h',
  'runtime/bin/platform_macos.h',
  'runtime/bin/platform_macos_cocoa.h',
  'runtime/bin/socket_base_android.h',
  'runtime/bin/socket_base_fuchsia.h',
  'runtime/bin/socket_base_linux.h',
  'runtime/bin/socket_base_macos.h',
  'runtime/bin/socket_base_win.h',
  'runtime/bin/thread_absl.h',
  'runtime/bin/thread_android.h',
  'runtime/bin/thread_fuchsia.h',
  'runtime/bin/thread_linux.h',
  'runtime/bin/thread_macos.h',
  'runtime/bin/thread_win.h',
  'runtime/platform/atomic_android.h',
  'runtime/platform/atomic_fuchsia.h',
  'runtime/platform/atomic_linux.h',
  'runtime/platform/atomic_macos.h',
  'runtime/platform/atomic_win.h',
  'runtime/platform/utils_android.h',
  'runtime/platform/utils_fuchsia.h',
  'runtime/platform/utils_linux.h',
  'runtime/platform/utils_macos.h',
  'runtime/platform/utils_win.h',
  'runtime/vm/compiler/assembler/assembler_arm.h',
  'runtime/vm/compiler/assembler/assembler_arm64.h',
  'runtime/vm/compiler/assembler/assembler_ia32.h',
  'runtime/vm/compiler/assembler/assembler_riscv.h',
  'runtime/vm/compiler/assembler/assembler_x64.h',
  'runtime/vm/compiler/runtime_offsets_extracted.h',
  'runtime/vm/constants_arm.h',
  'runtime/vm/constants_arm64.h',
  'runtime/vm/constants_ia32.h',
  'runtime/vm/constants_riscv.h',
  'runtime/vm/constants_x64.h',
  'runtime/vm/cpu_arm.h',
  'runtime/vm/cpu_arm64.h',
  'runtime/vm/cpu_ia32.h',
  'runtime/vm/cpu_riscv.h',
  'runtime/vm/cpu_x64.h',
  'runtime/vm/instructions_arm.h',
  'runtime/vm/instructions_arm64.h',
  'runtime/vm/instructions_ia32.h',
  'runtime/vm/instructions_riscv.h',
  'runtime/vm/instructions_x64.h',
  'runtime/vm/os_thread_absl.h',
  'runtime/vm/os_thread_android.h',
  'runtime/vm/os_thread_fuchsia.h',
  'runtime/vm/os_thread_linux.h',
  'runtime/vm/os_thread_macos.h',
  'runtime/vm/os_thread_win.h',
  'runtime/vm/regexp_assembler_bytecode_inl.h',
  'runtime/vm/simulator_arm.h',
  'runtime/vm/simulator_arm64.h',
  'runtime/vm/simulator_riscv.h',
  'runtime/vm/simulator_x64.h',
  'runtime/vm/stack_frame_arm.h',
  'runtime/vm/stack_frame_arm64.h',
  'runtime/vm/stack_frame_ia32.h',
  'runtime/vm/stack_frame_riscv.h',
  'runtime/vm/stack_frame_x64.h',

  // Only available in special builds
  'runtime/bin/io_service_no_ssl.h',
  'runtime/bin/utils_win.h',
  'runtime/vm/compiler/backend/locations_helpers_arm.h',
]);

final defineSets = [
  [
    '-DDEBUG',
  ],
  [
    '-DNDEBUG',
  ],
  [
    '-DNDEBUG',
    '-DPRODUCT',
  ],
  [
    '-DDART_PRECOMPILER',
    '-DDEBUG',
  ],
  [
    '-DDART_PRECOMPILER',
    '-DNDEBUG',
  ],
  [
    '-DDART_PRECOMPILER',
    '-DNDEBUG',
    '-DPRODUCT',
  ],
];

main(List<String> files) async {
  await generatePerfettoBuildFlags();

  bool isFirstFailure = true;

  files = files.where((filepath) => !excludedFiles.contains(filepath)).toList();

  // Analyze the [files] in parallel.
  for (List<String> defines in defineSets) {
    await Future.wait(files.map((String filepath) async {
      // The `runtime/.clang-tidy` file has the enabled checks in it.
      final args = <String>['-quiet', filepath, '--']
        ..addAll(compilerFlagsForFile(filepath))
        ..addAll(defines);
      final processResult =
          await pool.withResource(() => Process.run(clangTidy, args));

      final int exitCode = processResult.exitCode;
      final String stdout = processResult.stdout.trim();
      final String stderr = processResult.stderr.trim();

      if (exitCode != 0 || stdout.isNotEmpty) {
        if (!isFirstFailure) {
          print('');
          print('------------------------------------------------------------');
          print('');
        }
        isFirstFailure = false;
      }

      if (exitCode != 0) {
        print('command: $clangTidy ${args.join(" ")}');
        print('exit-code: $exitCode');
        print('stdout:');
        print('${stdout}');
        print('stderr:');
        print('${stderr}');
      } else if (stdout.isNotEmpty) {
        // The actual lints go to stdout.
        print(stdout);
      }
    }));
  }
}
