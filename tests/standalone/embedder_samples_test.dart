import 'dart:io';

import 'package:expect/expect.dart';

void checkSamples(
  String binaryBasename,
  List<String> args, {
  bool skipIfNotBuilt = false,
}) {
  // Shared library variant.
  checkSample(binaryBasename, args, skipIfNotBuilt: skipIfNotBuilt);
  // Static variant.
  checkSample('${binaryBasename}_static', args, skipIfNotBuilt: skipIfNotBuilt);
}

void checkSample(
  String binary,
  List<String> args, {
  bool skipIfNotBuilt = false,
}) {
  if (Platform.isWindows) {
    binary = '$binary.exe';
  }
  if (!File(binary).existsSync()) {
    if (skipIfNotBuilt) {
      return;
    } else {
      Expect.fail('Binary $binary does not exist!');
    }
  }
  final result = Process.runSync(binary, args);
  Expect.equals(
    0,
    result.exitCode,
    'process $binary failed:\n'
    '  exit code: ${result.exitCode}\n'
    '  -- stdout --\n'
    '${result.stdout}'
    '  -- stderr --\n'
    '${result.stderr}\n'
    '  ------------',
  );
}

void main() {
  final executable = File(Platform.executable).absolute.path;
  final out = executable.substring(0, executable.lastIndexOf('dart') - 1);

  checkSamples('$out/run_main_kernel', ['$out/gen/hello_kernel.dart.snapshot']);
  checkSamples('$out/run_two_programs_kernel', [
    '$out/gen/program1_kernel.dart.snapshot',
    '$out/gen/program2_kernel.dart.snapshot',
  ]);
  checkSamples('$out/run_timer_kernel', [
    '$out/gen/timer_kernel.dart.snapshot',
  ]);
  checkSamples('$out/run_timer_async_kernel', [
    '$out/gen/timer_kernel.dart.snapshot',
  ]);
  // FFI samples aren't built on some platforms.
  checkSamples('$out/run_futures_kernel', [
    '$out/gen/futures_kernel.dart.snapshot',
  ], skipIfNotBuilt: true);

  // AOT Samples aren't built on some platforms.
  checkSamples('$out/run_main_aot', [
    '$out/hello_aot.snapshot',
  ], skipIfNotBuilt: true);
  checkSamples('$out/run_two_programs_aot', [
    '$out/program1_aot.snapshot',
    '$out/program2_aot.snapshot',
  ], skipIfNotBuilt: true);
  checkSamples('$out/run_timer_aot', [
    '$out/timer_aot.snapshot',
  ], skipIfNotBuilt: true);
  checkSamples('$out/run_timer_async_aot', [
    '$out/timer_aot.snapshot',
  ], skipIfNotBuilt: true);
  checkSamples('$out/run_futures_aot', [
    '$out/futures_aot.snapshot',
  ], skipIfNotBuilt: true);
}
