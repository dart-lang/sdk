// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the [TargetExecutor] for DDC.
library;

import 'dart:io';
import '../common/testing.dart' as helper;

import 'model.dart';
import 'util.dart';
import 'target.dart';

/// Logic to build and execute dynamic modules in DDC.
///
/// In particular:
///   * The initial app is built as a regular DDC target, except that
///     a dynamic interface is used to validate that the public API matches
///     real declarations.
///   * For dynamic modules, DDC validates that the module only accesses what's
///     allowed by the dynamic interface.
///   * For dynamic modules, DDC also produces a slighly different output
///     to implement library isolation.
///   * Tests are executed in d8 using a custom bootstrapping logic. Eventually
///     this logic needs to be centralized inside the compiler.
class DdcExecutor implements TargetExecutor {
  static const rootScheme = 'dev-dart-app';
  late final bool _shouldCleanup;
  late final Directory _tmp;
  final Logger _logger;

  DdcExecutor(this._logger) {
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

  // TODO(sigmund): add support to run also in the ddc-canary mode.
  Future _compile(
      String testName, String source, Uri sourceDir, bool isMain) async {
    var testDir = _tmp.uri.resolve(testName).toFilePath();
    var args = [
      '--packages=${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      ddcAotSnapshot.toFilePath(),
      '--modules=ddc',
      '--no-summarize',
      '--no-source-map',
      '--multi-root',
      '${sourceDir.resolve('../../')}',
      '--multi-root-scheme',
      rootScheme,
      '$rootScheme:/data/$testName/$source',
      '--dart-sdk-summary',
      '$ddcSdkOutline',
      // Note: this needs to change if we ever intend to support packages within
      // the dynamic loading tests themselves
      '--packages=${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      if (!isMain) ...[
        // TODO(sigmund): consider specifying the module name directly
        '--dynamic-module',
        '--summary=main.dart.dill=main.dart',
      ],
      '-o',
      '$source.js',
    ];
    await runProcess(dartAotBin.toFilePath(), args, testDir, _logger,
        'compile $testName/$source');
  }

  Future _buildKernelOutline(
      String testName, String source, Uri sourceDir) async {
    assert(source == 'main.dart');
    var testDir = _tmp.uri.resolve(testName).toFilePath();
    var args = [
      '--packages=${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      kernelWOrkerAotSnapshot.toFilePath(),
      '--summary-only',
      '--target',
      'ddc',
      '--multi-root',
      '${sourceDir.resolve('../../')}',
      '--multi-root-scheme',
      rootScheme,
      '--packages-file=${repoRoot.toFilePath()}/.dart_tool/package_config.json',
      '--dart-sdk-summary',
      '$ddcSdkOutline',
      '--source',
      '$rootScheme:/data/$testName/$source',
      '--output',
      '$source.dill',
    ];

    await runProcess(dartAotBin.toFilePath(), args, testDir, _logger,
        'sumarize $testName/$source');
  }

  @override
  Future compileApplication(DynamicModuleTest test) async {
    _ensureDirectory(test.name);
    _logger.info('Compile ${test.name} app');
    await _buildKernelOutline(test.name, test.main, test.folder);
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
    // ddc module loader, the necessary modules (the SDK and the main module),
    // and finally launches the app.
    var testDir = _tmp.uri.resolve('${test.name}/');
    var bootstrapUri = testDir.resolve('bootstrap.js');
    // TODO(sigmund): remove hardwired entrypoint name
    File.fromUri(bootstrapUri).writeAsStringSync('''
      load('${ddcPreamblesJs.toFilePath()}');        // preambles/d8.js
      load('${ddcSealNativeObjectJs.toFilePath()}'); // seal_native_object.js
      load('${ddcModuleLoaderJs.toFilePath()}');     // ddc_module_loader.js
      load('${ddcSdkJs.toFilePath()}');              // dart_sdk.js
      load('main.dart.js');                          // compiled test module

      self.dartMainRunner(function () {
        dart_library.configure(
          "_dynamic_module_test",                 // app name
          {
            dynamicModuleLoader: (uri, onLoad) => {
              let name = uri;                     // our test framework simply
                                                  // provides the module name as
                                                  // the uri.
              load(`modules/\${name}.js`);
              onLoad(name);
          },
        });
        dart_library.start(
          "_dynamic_module_test",                 // app name
          '00000000-0000-0000-0000-000000000000', // uuid
          "main.dart",                            // module
          "data__${test.name}__main",             // library containing main
          false
        );
      });
    ''');
    var result = await runProcess(
        d8Uri.toFilePath(),
        [bootstrapUri.toFilePath()],
        testDir.toFilePath(),
        _logger,
        'd8 ${test.name}/bootstrap.js');
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
