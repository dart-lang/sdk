// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Entrypoint to run dynamic module tests.
library;

import 'package:args/args.dart';

import 'load.dart';
import 'model.dart';
import 'target.dart';
import 'util.dart';

void main(List<String> args) async {
  final suiteRoot = repoRoot.resolve('pkg/dynamic_modules/test/data/');
  var tests = loadAllTests(suiteRoot);
  final parser = ArgParser()
    ..addFlag('help', help: 'Help message', negatable: false, abbr: 'h')
    ..addOption('test',
        help: 'Run a single test, rather than the entire suite',
        allowed: tests.map((t) => t.name).toList(),
        abbr: 't')
    ..addOption('runtime',
        help: 'Which runtime to use to run the test configuration',
        allowed: Target.values.map((v) => v.name),
        defaultsTo: Target.ddc.name,
        abbr: 'r')
    ..addOption('configuration',
        help: 'Configuration to use for reporting test results', abbr: 'c')
    ..addFlag('verbose',
        help: 'Show a lot of information', negatable: false, abbr: 'v');
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
      Target.ddc => UnimplementedExecutor(logger),
      Target.aot => UnimplementedExecutor(logger),
      Target.dart2wasm => UnimplementedExecutor(logger),
    };

    final results = <DynamicModuleTestResult>[];
    for (final t in tests) {
      results.add(await _runSingleTest(t, executor));
    }
    _reportResults(results);
  } finally {
    executor.suiteComplete();
  }
}

/// Takes the steps to build the artifacts needed by a test and then execute it
/// on the target environment.
Future<DynamicModuleTestResult> _runSingleTest(
    DynamicModuleTest test, TargetExecutor target) async {
  try {
    await target.compileApplication(test);
    for (var name in test.dynamicModules.keys) {
      await target.compileDynamicModule(test, name);
    }
  } catch (e, st) {
    return DynamicModuleTestResult.compileError(test, '$e\n$st');
  }

  try {
    await target.executeApplication(test);
  } catch (e, st) {
    return DynamicModuleTestResult.runtimeError(test, '$e\n$st');
  }

  return DynamicModuleTestResult.pass(test);
}

/// Generates a report of the test results in the JSON format
/// that is expected by our testing infrastructure.
void _reportResults(List<DynamicModuleTestResult> results) {
  // TODO(sigmund): replace this with proper infra reporting
  bool fail = false;
  print('Test results:');
  for (var result in results) {
    print('  ${result.name}: ${result.status}');
    if (result.status != Status.pass) fail = true;
  }
  if (fail) throw "Some tests failed...";
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
