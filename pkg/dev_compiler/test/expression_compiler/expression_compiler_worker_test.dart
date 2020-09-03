// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform, Process, stderr, stdout;

import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:path/path.dart' as p;
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

import 'package:dev_compiler/src/kernel/expression_compiler_worker.dart';

/// Verbose mode for debugging
bool get verbose => false;

class ModuleConfiguration {
  final String outputPath;
  final String moduleName;
  final String libraryUri;
  final String jsFileName;
  final String fullDillFileName;

  ModuleConfiguration(
      {this.outputPath,
      this.moduleName,
      this.libraryUri,
      this.jsFileName,
      this.fullDillFileName});

  String get jsPath => p.join(outputPath, jsFileName);
  String get fullDillPath => p.join(outputPath, fullDillFileName);
}

class TestProjectConfiguration {
  final Directory rootDirectory;
  final String outputDir = 'out';

  TestProjectConfiguration(this.rootDirectory);

  ModuleConfiguration get mainModule => ModuleConfiguration(
      outputPath: outputPath,
      moduleName: 'packages/_testPackage/main',
      libraryUri: 'org-dartlang-app:/lib/main.dart',
      jsFileName: 'main.js',
      fullDillFileName: 'main.full.dill');

  ModuleConfiguration get testModule => ModuleConfiguration(
      outputPath: outputPath,
      moduleName: 'packages/_testPackage/test_library',
      libraryUri: 'package:_testPackage/test_library.dart',
      jsFileName: 'test_library.js',
      fullDillFileName: 'test_library.full.dill');

  ModuleConfiguration get testModule2 => ModuleConfiguration(
      outputPath: outputPath,
      moduleName: 'packages/_testPackage/test_library2',
      libraryUri: 'package:_testPackage/test_library2.dart',
      jsFileName: 'test_library2.js',
      fullDillFileName: 'test_library2.full.dill');

  String get root => rootDirectory.path;
  String get outputPath => p.join(root, outputDir);
  String get packagesPath => p.join(root, '.packages');

  String get sdkRoot => computePlatformBinariesLocation().path;
  String get sdkSummaryPath => p.join(sdkRoot, 'ddc_sdk.dill');
  String get librariesPath => p.join(sdkRoot, 'lib', 'libraries.json');

  void createTestProject() {
    var pubspec = rootDirectory.uri.resolve('pubspec.yaml');
    File.fromUri(pubspec)
      ..createSync()
      ..writeAsStringSync('''
name: _testPackage
version: 1.0.0

environment:
  sdk: '>=2.8.0 <3.0.0'
''');

    var packages = rootDirectory.uri.resolve('.packages');
    File.fromUri(packages)
      ..createSync()
      ..writeAsStringSync('''
_testPackage:lib/
''');

    var main = rootDirectory.uri.resolve('lib/main.dart');
    File.fromUri(main)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:_testPackage/test_library.dart';

var global = 0;

void main() {
  var count = 0;
  // line 7
  print('Global is: \${++global}');
  print('Count is: \${++count}');

  B b = new B();
}
''');

    var testLibrary = rootDirectory.uri.resolve('lib/test_library.dart');
    File.fromUri(testLibrary)
      ..createSync()
      ..writeAsStringSync('''
import 'package:_testPackage/test_library2.dart';

int testLibraryFunction(int formal) {
  return formal; // line 4
}

int callLibraryFunction2(int formal) {
  return testLibraryFunction2(formal); // line 8
}

class B {
  C c() => new C();
}
''');

    var testLibrary2 = rootDirectory.uri.resolve('lib/test_library2.dart');
    File.fromUri(testLibrary2)
      ..createSync()
      ..writeAsStringSync('''
int testLibraryFunction2(int formal) {
  return formal; // line 2
}

class C {
  int getNumber() => 42;
}
''');
  }
}

void main() async {
  group('Expression compiler worker (webdev simulation) - ', () {
    ExpressionCompilerWorker worker;
    Future workerDone;
    StreamController<Map<String, dynamic>> requestController;
    StreamController<Map<String, dynamic>> responseController;
    Directory tempDir;
    TestProjectConfiguration config;
    List inputs;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('foo bar');
      config = TestProjectConfiguration(tempDir);

      // simulate webdev
      config.createTestProject();
      var kernelGenerator = DDCKernelGenerator(config);
      await kernelGenerator.generate();

      inputs = [
        {
          'path': config.mainModule.fullDillPath,
          'moduleName': config.mainModule.moduleName
        },
        {
          'path': config.testModule.fullDillPath,
          'moduleName': config.testModule.moduleName
        },
        {
          'path': config.testModule2.fullDillPath,
          'moduleName': config.testModule2.moduleName
        },
      ];
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
    });

    setUp(() async {
      var fileSystem = MultiRootFileSystem(
          'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);

      requestController = StreamController<Map<String, dynamic>>();
      responseController = StreamController<Map<String, dynamic>>();
      worker = await ExpressionCompilerWorker.create(
        librariesSpecificationUri: Uri.file(config.librariesPath),
        // We should be able to load everything from dill and not require
        // source parsing. Webdev and google3 integration currently rely on that.
        // Make the test fail on source reading by not providing a packages.
        packagesFile: null,
        sdkSummary: Uri.file(config.sdkSummaryPath),
        fileSystem: fileSystem,
        requestStream: requestController.stream,
        sendResponse: responseController.add,
        verbose: verbose,
      );
      workerDone = worker.start();
    });

    tearDown(() async {
      unawaited(requestController.close());
      await workerDone;
      unawaited(responseController.close());
    });

    test('can load dependencies and compile expressions in sdk', () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'other',
        'line': 107,
        'column': 1,
        'jsModules': {},
        'jsScope': {'other': 'other'},
        'libraryUri': 'dart:collection',
        'moduleName': 'dart_sdk',
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return other;'),
            })
          ]));
    }, skip: 'Evaluating expressions in SDK is not supported yet');

    test('can load dependencies and compile expressions in a library',
        () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 4,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': config.testModule.libraryUri,
        'moduleName': config.testModule.moduleName,
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return formal;'),
            })
          ]));
    });

    test('can load dependencies and compile expressions in main', () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'count',
        'line': 7,
        'column': 1,
        'jsModules': {},
        'jsScope': {'count': 'count'},
        'libraryUri': config.mainModule.libraryUri,
        'moduleName': config.mainModule.moduleName,
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return count;'),
            })
          ]));
    });

    test('can load dependencies and compile transitive expressions in main',
        () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().c().getNumber()',
        'line': 7,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': config.mainModule.libraryUri,
        'moduleName': config.mainModule.moduleName,
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure':
                  contains('return new test_library.B.new().c().getNumber()'),
            })
          ]));
    });
  });

  group('Expression compiler worker (google3 simulation) - ', () {
    ExpressionCompilerWorker worker;
    Future workerDone;
    StreamController<Map<String, dynamic>> requestController;
    StreamController<Map<String, dynamic>> responseController;
    Directory tempDir;
    TestProjectConfiguration config;
    List inputs;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('foo bar');
      config = TestProjectConfiguration(tempDir);

      // simulate google3
      config.createTestProject();
      var kernelGenerator = BazelKernelWorkerGenerator(config);
      await kernelGenerator.generate();

      inputs = [
        {
          'path': config.mainModule.fullDillPath,
          'moduleName': config.mainModule.moduleName
        },
      ];
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
    });

    setUp(() async {
      var fileSystem = MultiRootFileSystem(
          'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);

      requestController = StreamController<Map<String, dynamic>>();
      responseController = StreamController<Map<String, dynamic>>();
      worker = await ExpressionCompilerWorker.create(
        librariesSpecificationUri: Uri.file(config.librariesPath),
        packagesFile: null,
        sdkSummary: Uri.file(config.sdkSummaryPath),
        fileSystem: fileSystem,
        requestStream: requestController.stream,
        sendResponse: responseController.add,
        verbose: verbose,
      );
      workerDone = worker.start();
    });

    tearDown(() async {
      unawaited(requestController.close());
      await workerDone;
      unawaited(responseController.close());
    });

    test('can load dependencies and compile expressions in sdk', () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'other',
        'line': 107,
        'column': 1,
        'jsModules': {},
        'jsScope': {'other': 'other'},
        'libraryUri': 'dart:collection',
        'moduleName': 'dart_sdk',
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return other;'),
            })
          ]));
    }, skip: 'Evaluating expressions in SDK is not supported yet');

    test('can load dependencies and compile expressions in a library',
        () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 4,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': config.testModule.libraryUri,
        'moduleName': config.mainModule.moduleName,
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return formal;'),
            })
          ]));
    });

    test('can load dependencies and compile expressions in main', () async {
      requestController.add({
        'command': 'UpdateDeps',
        'inputs': inputs,
      });

      requestController.add({
        'command': 'CompileExpression',
        'expression': 'count',
        'line': 7,
        'column': 1,
        'jsModules': {},
        'jsScope': {'count': 'count'},
        'libraryUri': config.mainModule.libraryUri,
        'moduleName': config.mainModule.moduleName,
      });

      expect(
          responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'compiledProcedure': contains('return count;'),
            })
          ]));
    });
  }, skip: 'bazel kernel worker does not support full kernel generation yet');
}

/// Uses DDC to generate kernel from the test code
/// in order to simulate webdev environment
class DDCKernelGenerator {
  final TestProjectConfiguration config;

  DDCKernelGenerator(this.config);

  Future<int> generate() async {
    var dart = Platform.resolvedExecutable;
    var dartdevc =
        p.join(p.dirname(dart), 'snapshots', 'dartdevc.dart.snapshot');

    Directory(config.outputPath)..createSync();

    // generate test_library2.full.dill
    var args = [
      dartdevc,
      config.testModule2.libraryUri,
      '--no-summarize',
      '-o',
      config.testModule2.jsPath,
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath,
      '--multi-root',
      config.root,
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath,
    ];

    var exitCode = await runProcess(dart, args, config.root);
    if (exitCode != 0) {
      return exitCode;
    }

    // generate test_library.full.dill
    args = [
      dartdevc,
      config.testModule.libraryUri,
      '--no-summarize',
      '--summary',
      '${config.testModule2.fullDillPath}=${config.testModule2.moduleName}',
      '-o',
      config.testModule.jsPath,
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath,
      '--multi-root',
      config.root,
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath,
    ];

    exitCode = await runProcess(dart, args, config.root);
    if (exitCode != 0) {
      return exitCode;
    }

    // generate main.full.dill
    args = [
      dartdevc,
      config.mainModule.libraryUri,
      '--no-summarize',
      '--summary',
      '${config.testModule2.fullDillPath}=${config.testModule2.moduleName}',
      '--summary',
      '${config.testModule.fullDillPath}=${config.testModule.moduleName}',
      '-o',
      config.mainModule.jsPath,
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath,
      '--multi-root',
      config.root,
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath,
    ];

    return await runProcess(dart, args, config.root);
  }
}

/// Uses bazel kernel worker to generate kernel from test code
/// in order to simulate google3 environment
/// TODO: split into 3 modules
class BazelKernelWorkerGenerator {
  TestProjectConfiguration config;

  BazelKernelWorkerGenerator(this.config);

  Future<void> generate() async {
    var dart = Platform.resolvedExecutable;
    var kernelWorker =
        p.join(p.dirname(dart), 'snapshots', 'kernel_worker.dart.snapshot');

    var args = [
      kernelWorker,
      '--target',
      'ddc',
      '--output',
      config.mainModule.fullDillPath,
      '--dart-sdk-summary',
      config.sdkSummaryPath,
      '--exclude-non-sources',
      '--source',
      config.mainModule.libraryUri,
      '--source',
      config.testModule.libraryUri,
      '--source',
      config.testModule2.libraryUri,
      '--multi-root',
      config.root,
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages-file',
      '.packages',
      '--verbose'
    ];

    return await runProcess(dart, args, config.root);
  }
}

Future<int> runProcess(
    String command, List<String> args, String workingDirectory) async {
  if (verbose) {
    print('Running command in $workingDirectory:'
        '\n\t $command ${args.join(' ')}, ');
  }
  var process =
      await Process.start(command, args, workingDirectory: workingDirectory)
          .then((Process process) {
    process
      ..stdout.transform(utf8.decoder).listen(stdout.write)
      ..stderr.transform(utf8.decoder).listen(stderr.write);
    return process;
  });

  return await process.exitCode;
}
