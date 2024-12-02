// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities used by various parts of the test harness.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ffi' show Abi;

/// Locate the root of the SDK repository.
///
/// Note: we don't search for the directory "sdk" because this may not be
/// available when running this test in a shard.
Uri repoRoot = (() {
  Uri script = Platform.script;
  var segments = script.pathSegments;
  var index = segments.lastIndexOf('pkg');
  if (index == -1) {
    exitCode = 1;
    throw "error: cannot find the root of the Dart SDK";
  }
  return script.resolve("../" * (segments.length - index - 1));
})();

String _outFolder = Platform.isMacOS ? 'xcodebuild' : 'out';

String configuration = () {
  var env = Platform.environment['DART_CONFIGURATION'];
  if (env != null) return env;
  var folderSegments = _dartBin.resolve('.').pathSegments;
  for (int i = folderSegments.length - 1; i > 0; i--) {
    if (folderSegments[i] == _outFolder) {
      var candidate = folderSegments[i + 1];
      if (candidate.startsWith('Debug') ||
          candidate.startsWith('Release') ||
          candidate.startsWith('Product')) {
        return candidate;
      }
    }
  }
  return 'ReleaseX64';
}();

// See also utils/gen_kernel/BUILD.gn:
// dartaotruntime has dart_product_config applied to it and is built in product
// mode in both release and product builds.
bool get useProduct => !configuration.startsWith('Debug');

String buildFolder = '$_outFolder/$configuration/';
String arch = Abi.current().toString().split('_')[1];
String _d8Path = (() {
  if (Platform.isWindows) {
    return 'third_party/d8/windows/$arch/d8.exe';
  } else if (Platform.isLinux) {
    return 'third_party/d8/linux/$arch/d8';
  } else if (Platform.isMacOS) {
    return 'third_party/d8/macos/$arch/d8';
  } else {
    throw UnsupportedError('Unsupported platform for running d8: '
        '${Platform.operatingSystem}');
  }
})();

Uri d8Uri = repoRoot.resolve(_d8Path);
Uri _dartBin = Uri.file(Platform.resolvedExecutable);
Uri dartAotBin = _dartBin
    .resolve(Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime');
Uri ddcAotSnapshot = _dartBin.resolve('snapshots/dartdevc_aot.dart.snapshot');
Uri kernelWorkerAotSnapshot =
    _dartBin.resolve('snapshots/kernel_worker_aot.dart.snapshot');
Uri buildRootUri = repoRoot.resolve(buildFolder);
Uri ddcSdkOutline = buildRootUri.resolve('ddc_outline.dill');
Uri ddcSdkJs = buildRootUri.resolve('gen/utils/ddc/stable/sdk/ddc/dart_sdk.js');
Uri ddcPreamblesJs = repoRoot
    .resolve('sdk/lib/_internal/js_dev_runtime/private/preambles/d8.js');
Uri ddcSealNativeObjectJs = repoRoot.resolve(
    'sdk/lib/_internal/js_runtime/lib/preambles/seal_native_object.js');
Uri ddcModuleLoaderJs =
    repoRoot.resolve('pkg/dev_compiler/lib/js/ddc/ddc_module_loader.js');

Uri genKernelSnapshot =
    buildRootUri.resolve('gen/gen_kernel_aot.dart.snapshot');
Uri genSnapshotBin =
    buildRootUri.resolve(useProduct ? 'gen_snapshot_product' : 'gen_snapshot');
Uri dart2bytecodeSnapshot =
    buildRootUri.resolve('gen/dart2bytecode.dart.snapshot');
Uri aotRuntimeBin = buildRootUri
    .resolve(useProduct ? 'dartaotruntime_product' : 'dartaotruntime');
Uri vmPlatformDill = buildRootUri.resolve('vm_platform_strong.dill');

// Encodes test results in the format expected by Dart's CI infrastructure.
class TestResultOutcome {
  // This encoder must generate each output element on its own line.
  final _encoder = JsonEncoder();
  final String configuration;
  final String suiteName;
  final String testName;
  late Duration elapsedTime;
  final String expectedResult;
  late bool matchedExpectations;
  String testOutput;

  TestResultOutcome({
    required this.configuration,
    this.suiteName = 'dynamic_modules',
    required this.testName,
    this.expectedResult = 'Pass',
    this.testOutput = '',
  });

  String toRecordJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'suite': suiteName,
        'test_name': testName,
        'time_ms': elapsedTime.inMilliseconds,
        'expected': expectedResult,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'matches': expectedResult == expectedResult,
      });

  String toLogJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'log': testOutput,
      });
}

/// Runs [command] with [arguments] in [workingDirectory], and if [verbose] is
/// `true` then it logs the full command.
Future<ProcessResult> runProcess(String command, List<String> arguments,
    String workingDirectory, Logger logger, String message) async {
  logger
      .info('command:\n$command ${arguments.join(' ')} from $workingDirectory');
  final result =
      await Process.run(command, arguments, workingDirectory: workingDirectory);
  logger.info('Exit code: ${result.exitCode}');
  if (result.exitCode != 0) {
    logger.warning('STDOUT: ${result.stdout}');
    logger.warning('STDERR: ${result.stderr}');
    throw 'Error on $message: $command ${arguments.join(' ')} from $workingDirectory\n\n'
        'stdout:\n${result.stdout}\n\n'
        'stderr:\n${result.stderr}';
  } else {
    logger.info('STDOUT: ${result.stdout}');
    logger.info('STDERR: ${result.stderr}');
  }
  return result;
}

/// API to easily control verbosity of the test harness.
class Logger {
  final bool verbose;
  Logger([this.verbose = false]);
  void info(String message) {
    if (verbose) print(message);
  }

  void warning(String message) => print(message);
  void error(String message) => print(message);
}
