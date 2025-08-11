// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entrypoint to run dynamic module tests.
library;

import 'dart:io';

import 'package:args/args.dart';

import 'vm.dart';
import 'dart2wasm.dart';
import 'ddc.dart';
import 'load.dart';
import 'model.dart';
import 'target.dart';
import 'util.dart';

void main(List<String> args) async {
  final suiteRoot = repoRoot.resolve('pkg/dynamic_modules/test/data/');
  var tests = loadAllTests(suiteRoot);
  final parser = ArgParser()
    ..addFlag('help', help: 'Help message', negatable: false, abbr: 'h')
    ..addOption(
      'test',
      help: 'Run a single test, rather than the entire suite',
      allowed: tests.map((t) => t.name).toList(),
      abbr: 't',
    )
    ..addOption(
      'runtime',
      help: 'Which runtime to use to run the test configuration',
      allowed: Target.values.map((v) => v.name),
      defaultsTo: Target.ddc.name,
      abbr: 'r',
    )
    ..addOption(
      'configuration',
      help: 'Configuration to use for reporting test results',
      abbr: 'n',
    )
    ..addOption(
      'output-directory',
      help: 'location where to emit the json-l result and log files',
    )
    ..addFlag(
      'verbose',
      help: 'Show a lot of information',
      negatable: false,
      abbr: 'v',
    );
  final options = parser.parse(args);
  if (options['help'] as bool) {
    print(parser.usage);
    return;
  }

  var singleTest = options['test'] as String?;
  if (singleTest != null) {
    tests = [...tests.where((t) => t.name == singleTest)];
  }

  final logger = Logger(options['verbose'] as bool);

  final target = Target.values.firstWhere((v) => v.name == options['runtime']);
  late TargetExecutor executor;
  try {
    executor = switch (target) {
      Target.ddc => DdcExecutor(logger),
      Target.aot => VmExecutor(logger, mode: VmMode.aot),
      Target.jit => VmExecutor(logger, mode: VmMode.jit),
      Target.dart2wasm => Dart2wasmExecutor(logger),
    };

    final results = <DynamicModuleTestResult>[];
    for (final t in tests) {
      final testResult = await _runSingleTest(t, executor);
      if (testResult.status != Status.pass) {
        logger.error(testResult.details);
      }
      results.add(testResult);
    }
    final result = _reportResults(
      results,
      writeLog: singleTest == null,
      configuration: options['configuration'],
      logDir: options['output-directory'],
    );
    if (result != 0) {
      exitCode = result;
    }
  } finally {
    executor.suiteComplete();
  }
}

/// Takes the steps to build the artifacts needed by a test and then execute it
/// on the target environment.
Future<DynamicModuleTestResult> _runSingleTest(
  DynamicModuleTest test,
  TargetExecutor target,
) async {
  var timer = Stopwatch()..start();
  try {
    await target.compileApplication(test);
    for (var name in test.dynamicModules.keys) {
      await target.compileDynamicModule(test, name);
    }
  } catch (e, st) {
    return DynamicModuleTestResult.compileError(test, '$e\n$st', timer.elapsed);
  }

  try {
    await target.executeApplication(test);
  } catch (e, st) {
    return DynamicModuleTestResult.runtimeError(test, '$e\n$st', timer.elapsed);
  }

  return DynamicModuleTestResult.pass(test, timer.elapsed);
}

/// Generates a report of the test results in the JSON format
/// that is expected by our testing infrastructure.
int _reportResults(
  List<DynamicModuleTestResult> results, {
  required bool writeLog,
  String? configuration,
  String? logDir,
}) {
  bool fail = false;
  print('Test results:');
  for (var result in results) {
    print('  ${result.name}: ${result.status}');
    if (result.status != Status.pass) fail = true;
  }
  if (fail) print('Error: some tests failed');

  if (writeLog) {
    if (logDir == null) {
      print('Error: no output directory provided, logs won\'t be emitted.');
      return 1;
    }
    if (configuration == null) {
      print('Error: no configuration name provided, logs won\'t be emitted.');
      return 1;
    }

    // Ensure the directory URI ends with a path separator.
    var dirUri = Directory(logDir).uri;
    File.fromUri(dirUri.resolve('results.json')).writeAsStringSync(
      results.map((r) => '${r.toRecordJson(configuration)}\n').join(),
      flush: true,
    );
    File.fromUri(dirUri.resolve('logs.json')).writeAsStringSync(
      results
          .where((r) => r.status != Status.pass)
          .map((r) => '${r.toLogJson(configuration)}\n')
          .join(),
      flush: true,
    );

    print('Success: log files emitted under $dirUri');
  } else if (fail) {
    return 1;
  }
  return 0;
}

/// Placeholder until we implement all executors.
class UnimplementedExecutor implements TargetExecutor {
  UnimplementedExecutor(Logger logger);

  @override
  Future<void> suiteComplete() async => throw UnimplementedError();

  @override
  Future compileApplication(DynamicModuleTest test) async =>
      throw UnimplementedError();

  @override
  Future compileDynamicModule(DynamicModuleTest test, String name) async =>
      throw UnimplementedError();

  @override
  Future executeApplication(DynamicModuleTest test) async =>
      throw UnimplementedError();
}
