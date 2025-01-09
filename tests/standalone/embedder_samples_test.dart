import 'dart:io';

import 'package:expect/expect.dart';

void main() {
  final executable = Platform.executable;
  final outDir = executable.substring(0, executable.lastIndexOf('dart'));

  final runKernelExecutable = outDir + 'run_kernel';

  final result = Process.runSync(runKernelExecutable, []);
  Expect.equals(
    0,
    result.exitCode,
    'process failed:\n'
    '  exit code: ${result.exitCode}\n'
    '  -- stdout --\n'
    '${result.stdout}'
    '  -- stderr --\n'
    '${result.stderr}\n'
    '  ------------',
  );
}
