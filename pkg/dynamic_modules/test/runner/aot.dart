// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the [TargetExecutor] for the Dart AOT runtime.
library;

import 'dart:io';
import '../common/testing.dart' as helper;

import 'model.dart';
import 'util.dart';
import 'target.dart';

/// Logic to build and execute dynamic modules in Dart AOT.
///
/// In particular:
///   * The initial app is built as a regular AOT target, except that
///     a dynamic interface is used to retain any API that may be used by
///     dynamic modules.
///   * For dynamic modules, code is compiled to bytecode and we validate that
///     the module only accesses what's allowed by the dynamic interface.
///   * Unlike DDC, we don't use the embedder to load dynamic code, but include
///     the logic for that as part of the Dart application.
///
/// Note: this assumes that [Platform.resolvedExecutable] is a VM built with the
/// `--dart_dynamic_modules` build flag.
class AotExecutor implements TargetExecutor {
  static const rootScheme = 'dev-dart-app';
  late final bool _shouldCleanup;
  late final Directory _tmp;
  final Logger _logger;

  AotExecutor(this._logger) {
    /// Allow using an environment variable to run tests on a fixed directory.
    /// This prevents the directory from getting deleted too.
    var path = Platform.environment['TMP_DIR'] ?? '';
    if (path.isEmpty) {
      _tmp = Directory.systemTemp.createTempSync('_dynamic_module-');
      _shouldCleanup = true;
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

  Future _buildKernel(
      String testName, String source, Uri sourceDir, bool isAot) async {
    assert(source == 'main.dart');
    var testDir = _tmp.uri.resolve(testName).toFilePath();
    var aotTag = isAot ? "aot" : "no_aot";
    var args = [
      '--disable-dart-dev',
      genKernelSnapshot.toFilePath(),
      '--target',
      'vm',
      '--packages',
      '${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      '-Ddart.vm.profile=false',
      '-Ddart.vm.product=true',
      if (isAot) '--aot' else '--no-aot',
      '--platform',
      vmPlatformDill.toFilePath(),
      '--output',
      '${source}_$aotTag.dill',
      '--verbosity=all',
      '--filesystem-root',
      sourceDir.resolve('../../').toFilePath(),
      '--filesystem-scheme',
      rootScheme,
      '--dynamic-interface',
      '$rootScheme:/data/$testName/dynamic_interface.yaml',
      '$rootScheme:/data/$testName/$source',
    ];
    await runProcess(aotRuntimeBin.toFilePath(), args, testDir, _logger,
        'kernel $aotTag $testName/$source');
  }

  @override
  Future compileApplication(DynamicModuleTest test) async {
    _ensureDirectory(test.name);
    _logger.info('Compile ${test.name} app');
    await _buildKernel(test.name, test.main, test.folder, true);
    await _buildKernel(test.name, test.main, test.folder, false);

    var testDir = _tmp.uri.resolve(test.name).toFilePath();
    var args = [
      '--snapshot-kind=app-aot-elf',
      '--elf=${test.main}.snapshot',
      '${test.main}_aot.dill',
    ];
    await runProcess(genSnapshotBin.toFilePath(), args, testDir, _logger,
        'aot snapshot ${test.name}/${test.main}');
  }

  @override
  Future compileDynamicModule(DynamicModuleTest test, String name) async {
    _logger.info('Compile module ${test.name}.$name');
    _ensureDirectory('${test.name}/modules');
    var testDir = _tmp.uri.resolve(test.name).toFilePath();
    var source = test.dynamicModules[name]!;
    var args = [
      '--disable-dart-dev',
      dart2bytecodeSnapshot.toFilePath(),
      '--platform',
      vmPlatformDill.toFilePath(),
      '--target',
      'vm',
      '--packages',
      '${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      '-Ddart.vm.profile=false',
      '-Ddart.vm.product=true',
      '--import-dill',
      '${test.main}_no_aot.dill',
      '--validate',
      '$rootScheme:/data/${test.name}/dynamic_interface.yaml',
      '--verbosity=all',
      '--filesystem-root',
      test.folder.resolve('../../').toFilePath(),
      '--filesystem-scheme',
      rootScheme,
      '--output',
      '$source.bytecode',
      '$rootScheme:/data/${test.name}/$source',
    ];
    await runProcess(aotRuntimeBin.toFilePath(), args, testDir, _logger,
        'compile bytecode ${test.name}/$source');
  }

  @override
  Future executeApplication(DynamicModuleTest test) async {
    _logger.info('Execute ${test.name}');
    _ensureDirectory(test.name);

    // We generate a self contained script that loads necessary preambles,
    // ddc module loader, the necessary modules (the SDK and the main module),
    // and finally launches the app.
    var testDir = _tmp.uri.resolve('${test.name}/');
    var result = await runProcess(
        aotRuntimeBin.toFilePath(),
        [
          '${test.main}.snapshot',
        ],
        testDir.toFilePath(),
        _logger,
        'executable test ${test.main}.exe');
    var stdout = result.stdout as String;
    if (!stdout.contains(helper.successToken)) {
      _logger.error('Error: test didn\'t complete as expected.\n'
          'Make sure the test finishes and calls `helper.done()`.\n'
          'Test output:\n$stdout');
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
