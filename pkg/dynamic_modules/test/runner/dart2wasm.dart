// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the [TargetExecutor] for dart2wasm.
library;

import 'dart:io';
import '../common/testing.dart' as helper;

import 'model.dart';
import 'util.dart';
import 'target.dart';

/// Logic to build and execute dynamic modules in dart2wasm.
///
/// In particular:
///   * The initial app is built as a regular dart2wasm target, except that
///     a dynamic interface is used to define hooks that dynamic modules update
///     when loaded. The dynamic interface also prevents treeshaking of some
///     entities.
///   * For dynamic modules, dart2wasm validates that the module only accesses
///     what's allowed by the dynamic interface.
///   * For dynamic modules, dart2wasm exports a specific entry point function.
class Dart2wasmExecutor implements TargetExecutor {
  static const rootScheme = 'dev-dart-app';
  late final bool _shouldCleanup;
  late final Directory _tmp;
  final Logger _logger;

  Dart2wasmExecutor(this._logger) {
    /// Allow using an environment variable to run tests on a fixed directory.
    /// This prevents the directory from getting deleted too.
    var path = Platform.environment['TMP_DIR'] ?? '';
    if (path.isEmpty) {
      _tmp = Directory.systemTemp.createTempSync('_dynamic_module-');
      _shouldCleanup = false;
    } else {
      _tmp = Directory(path);
      if (!_tmp.existsSync()) _tmp.createSync();
      _shouldCleanup = false;
    }
  }

  @override
  Future<void> suiteComplete() async {
    if (!_shouldCleanup) return;
    try {
      _tmp.delete(recursive: true);
    } on FileSystemException {
      // Windows bots sometimes fail to delete folders, and can make tests
      // flaky. It is OK in those cases to leak some files in the tmp folder,
      // these will eventually be cleared when a new bot instance is created.
      _logger.warning('Error trying to delete $_tmp');
    }
  }

  Future _compile(
    String testName,
    String source,
    Uri sourceDir,
    bool isMain,
  ) async {
    var testDir = _tmp.uri.resolve(testName).toFilePath();
    var args = [
      '--compiler-asserts',
      '--packages=${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      '--multi-root=${sourceDir.resolve('../../').toFilePath()}',
      '--multi-root-scheme=$rootScheme',
      // This is required while binaryen lacks support for partially closed
      // world optimizations.
      '-O0',
      '--extra-compiler-option=--dynamic-module-type=${isMain ? "main" : "submodule"}',
      '--extra-compiler-option=--dynamic-module-main=main.dart.dill',
      '--extra-compiler-option=--dynamic-module-interface='
          '$rootScheme:/data/$testName/dynamic_interface.yaml',
      '$rootScheme:/data/$testName/$source',
      '$source.wasm',
    ];
    await runProcess(
      compileBenchmark.toFilePath(),
      args,
      testDir,
      _logger,
      'compile $testName/$source',
    );
  }

  @override
  Future compileApplication(DynamicModuleTest test) async {
    _ensureDirectory(test.name);
    _logger.info('Compile ${test.name} app');
    await _compile(test.name, test.main, test.folder, true);
  }

  @override
  Future compileDynamicModule(DynamicModuleTest test, String name) async {
    _logger.info('Compile module ${test.name}.$name');
    _ensureDirectory(test.name);
    await _compile(test.name, test.dynamicModules[name]!, test.folder, false);
  }

  @override
  Future executeApplication(DynamicModuleTest test) async {
    _logger.info('Execute ${test.name}');
    _ensureDirectory(test.name);

    // We generate a self contained script that loads necessary preambles,
    // dart2wasm module loader, the necessary modules (the SDK and the main
    // module), and finally launches the app.
    var testDir = _tmp.uri.resolve('${test.name}/');
    var result = await runProcess(
      runBenchmark.toFilePath(),
      ['${test.main}.wasm'],
      testDir.toFilePath(),
      _logger,
      'run_benchmark ${test.main}.wasm',
    );
    var stdout = result.stdout as String;
    if (!stdout.contains(helper.successToken)) {
      _logger.error(
        'Error: test didn\'t complete as expected.\n'
        'Make sure the test finishes and calls `helper.done()`.\n'
        'Test output:\n$stdout',
      );
      throw Exception('missing helper.done');
    }
  }

  void _ensureDirectory(String name) {
    var dir = Directory.fromUri(_tmp.uri.resolve(name));
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }
}
