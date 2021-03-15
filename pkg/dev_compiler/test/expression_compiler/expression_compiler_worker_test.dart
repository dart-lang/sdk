// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
  final Uri root;
  final String outputDir;
  final String libraryUri;
  final String moduleName;
  final String jsFileName;
  final String fullDillFileName;
  final String summaryDillFileName;

  ModuleConfiguration(
      {this.root,
      this.outputDir,
      this.moduleName,
      this.libraryUri,
      this.jsFileName,
      this.fullDillFileName,
      this.summaryDillFileName});

  Uri get jsPath => root.resolve('$outputDir/$jsFileName');
  Uri get fullDillPath => root.resolve('$outputDir/$fullDillFileName');
  Uri get summaryDillPath => root.resolve('$outputDir/$summaryDillFileName');
}

class TestProjectConfiguration {
  final Directory rootDirectory;
  final String outputDir = 'out';
  final bool soundNullSafety;
  final String moduleFormat;

  TestProjectConfiguration(
      this.rootDirectory, this.soundNullSafety, this.moduleFormat);

  ModuleConfiguration get mainModule => ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/main',
      libraryUri: 'org-dartlang-app:/lib/main.dart',
      jsFileName: 'main.js',
      fullDillFileName: 'main.full.dill',
      summaryDillFileName: 'main.dill');

  ModuleConfiguration get testModule => ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library',
      libraryUri: 'package:_testPackage/test_library.dart',
      jsFileName: 'test_library.js',
      fullDillFileName: 'test_library.full.dill',
      summaryDillFileName: 'test_library.dill');

  // TODO(annagrin): E.g. this module should have a file included that's not
  // directly reachable from the libraryUri (i.e. where "too much" has been
  // bundled).
  ModuleConfiguration get testModule2 => ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library2',
      libraryUri: 'package:_testPackage/test_library2.dart',
      jsFileName: 'test_library2.js',
      fullDillFileName: 'test_library2.full.dill',
      summaryDillFileName: 'test_library2.dill');

  ModuleConfiguration get testModule3 => ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library3',
      libraryUri: 'package:_testPackage/test_library3.dart',
      jsFileName: 'test_library3.js',
      fullDillFileName: 'test_library3.full.dill',
      summaryDillFileName: 'test_library3.dill');

  String get rootPath => rootDirectory.path;
  Uri get root => rootDirectory.uri;
  Uri get outputPath => root.resolve(outputDir);
  Uri get packagesPath => root.resolve('package_config.json');

  Uri get sdkRoot => computePlatformBinariesLocation();
  Uri get sdkSummaryPath => soundNullSafety
      ? sdkRoot.resolve('ddc_outline_sound.dill')
      : sdkRoot.resolve('ddc_sdk.dill');
  Uri get librariesPath => sdkRoot.resolve('lib/libraries.json');

  void createTestProject() {
    var pubspec = root.resolve('pubspec.yaml');
    File.fromUri(pubspec)
      ..createSync()
      ..writeAsStringSync('''
name: _testPackage
version: 1.0.0

environment:
  sdk: '>=2.8.0 <3.0.0'
''');

    File.fromUri(packagesPath)
      ..createSync()
      ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "_testPackage",
            "rootUri": "./lib",
            "packageUri": "./"
          }
        ]
      }
      ''');

    var main = root.resolve('lib/main.dart');
    File.fromUri(main)
      ..createSync(recursive: true)
      ..writeAsStringSync('''

import 'package:_testPackage/test_library.dart';
import 'package:_testPackage/test_library3.dart';

var global = 0;

void main() {
  var count = 0;
  // line 9
  print('Global is: \${++global}');
  print('Count is: \${++count}');

  B b = new B();
}

extension NumberParsing on String {
  int parseInt() {
    var ret = int.parse(this);
    // line 19
    return ret;
  }
}

void linkToImports() {
  testLibraryFunction(42);
  testLibraryFunction3(42);
}
''');

    var testLibrary = root.resolve('lib/test_library.dart');
    File.fromUri(testLibrary)
      ..createSync()
      ..writeAsStringSync('''

import 'package:_testPackage/test_library2.dart';

int testLibraryFunction(int formal) {
  return formal; // line 5
}

int callLibraryFunction2(int formal) {
  return testLibraryFunction2(formal); // line 9
}

class B {
  C c() => new C();
  void printNumber() {
    print(c().getNumber() + 1);
  }
}
''');

    var testLibrary2 = root.resolve('lib/test_library2.dart');
    File.fromUri(testLibrary2)
      ..createSync()
      ..writeAsStringSync('''

int testLibraryFunction2(int formal) {
  return formal; // line 3
}

class C {
  int getNumber() => 42;
}
''');

    var testLibrary3 = root.resolve('lib/test_library3.dart');
    File.fromUri(testLibrary3)
      ..createSync()
      ..writeAsStringSync('''

int testLibraryFunction3(int formal) {
  return formal; // line 3
}
''');
  }
}

void main() async {
  for (var moduleFormat in ['amd', 'ddc']) {
    group('$moduleFormat module format -', () {
      for (var soundNullSafety in [true, false]) {
        group('${soundNullSafety ? "sound" : "unsound"} null safety -', () {
          for (var summarySupport in [true, false]) {
            group('${summarySupport ? "" : "no "}debugger summary support -',
                () {
              group('expression compiler worker', () {
                ExpressionCompilerWorker worker;
                Future workerDone;
                StreamController<Map<String, dynamic>> requestController;
                StreamController<Map<String, dynamic>> responseController;
                Directory tempDir;
                TestProjectConfiguration config;
                List inputs;

                setUpAll(() async {
                  tempDir = Directory.systemTemp.createTempSync('foo bar');
                  config = TestProjectConfiguration(
                      tempDir, soundNullSafety, moduleFormat);

                  // simulate webdev
                  config.createTestProject();
                  var kernelGenerator = DDCKernelGenerator(config);
                  await kernelGenerator.generate();

                  inputs = [
                    {
                      'path': config.mainModule.fullDillPath.path,
                      if (summarySupport)
                        'summaryPath': config.mainModule.summaryDillPath.path,
                      'moduleName': config.mainModule.moduleName
                    },
                    {
                      'path': config.testModule.fullDillPath.path,
                      if (summarySupport)
                        'summaryPath': config.testModule.summaryDillPath.path,
                      'moduleName': config.testModule.moduleName
                    },
                    {
                      'path': config.testModule2.fullDillPath.path,
                      if (summarySupport)
                        'summaryPath': config.testModule2.summaryDillPath.path,
                      'moduleName': config.testModule2.moduleName
                    },
                    {
                      'path': config.testModule3.fullDillPath.path,
                      if (summarySupport)
                        'summaryPath': config.testModule3.summaryDillPath.path,
                      'moduleName': config.testModule3.moduleName
                    },
                  ];
                });

                tearDownAll(() async {
                  tempDir.deleteSync(recursive: true);
                });

                setUp(() async {
                  var fileSystem = MultiRootFileSystem('org-dartlang-app',
                      [tempDir.uri], StandardFileSystem.instance);

                  requestController = StreamController<Map<String, dynamic>>();
                  responseController = StreamController<Map<String, dynamic>>();
                  worker = await ExpressionCompilerWorker.create(
                    librariesSpecificationUri: config.librariesPath,
                    // We should be able to load everything from dill and not
                    // require source parsing. Webdev and google3 integration
                    // currently rely on that. Make the test fail on source
                    // reading by not providing a packages file.
                    packagesFile: null,
                    sdkSummary: config.sdkSummaryPath,
                    fileSystem: fileSystem,
                    requestStream: requestController.stream,
                    sendResponse: responseController.add,
                    soundNullSafety: soundNullSafety,
                    verbose: verbose,
                  );
                  workerDone = worker.start();
                });

                tearDown(() async {
                  unawaited(requestController.close());
                  await workerDone;
                  unawaited(responseController.close());
                });

                test('can compile expressions in sdk', () async {
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
                          'infos': isEmpty,
                          'compiledProcedure': contains('return other;'),
                        })
                      ]));
                }, skip: 'Evaluating expressions in SDK is not supported yet');

                test('can compile expressions in a library', () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 5,
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
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        })
                      ]));
                });

                test('can compile expressions in main', () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'count',
                    'line': 9,
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
                          'infos': isEmpty,
                          'compiledProcedure': contains('return count;'),
                        })
                      ]));
                });

                test('can compile expressions in main (extension method)',
                    () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'ret',
                    'line': 19,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'ret': 'ret'},
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
                          'infos': isEmpty,
                          'compiledProcedure': contains('return ret;'),
                        })
                      ]));
                });

                test('can compile transitive expressions in main', () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().c().getNumber()',
                    'line': 9,
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
                          'infos': isEmpty,
                          'compiledProcedure': contains(
                              'new test_library.B.new().c().getNumber()'),
                        })
                      ]));
                });

                test('can compile series of expressions in various libraries',
                    () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().c().getNumber()',
                    'line': 8,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {},
                    'libraryUri': config.mainModule.libraryUri,
                    'moduleName': config.mainModule.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 5,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'formal': 'formal'},
                    'libraryUri': config.testModule.libraryUri,
                    'moduleName': config.testModule.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 3,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'formal': 'formal'},
                    'libraryUri': config.testModule2.libraryUri,
                    'moduleName': config.testModule2.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 3,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'formal': 'formal'},
                    'libraryUri': config.testModule3.libraryUri,
                    'moduleName': config.testModule3.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().printNumber()',
                    'line': 9,
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
                          'infos': isEmpty,
                          'compiledProcedure': contains(
                              'new test_library.B.new().c().getNumber()'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure':
                              contains('test_library.B.new().printNumber()'),
                        })
                      ]));
                });

                test('can compile after dependency update', () async {
                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().c().getNumber()',
                    'line': 8,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {},
                    'libraryUri': config.mainModule.libraryUri,
                    'moduleName': config.mainModule.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 5,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'formal': 'formal'},
                    'libraryUri': config.testModule.libraryUri,
                    'moduleName': config.testModule.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().printNumber()',
                    'line': 9,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {},
                    'libraryUri': config.mainModule.libraryUri,
                    'moduleName': config.mainModule.moduleName,
                  });

                  requestController.add({
                    'command': 'UpdateDeps',
                    'inputs': inputs,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'B().c().getNumber()',
                    'line': 8,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {},
                    'libraryUri': config.mainModule.libraryUri,
                    'moduleName': config.mainModule.moduleName,
                  });

                  requestController.add({
                    'command': 'CompileExpression',
                    'expression': 'formal',
                    'line': 3,
                    'column': 1,
                    'jsModules': {},
                    'jsScope': {'formal': 'formal'},
                    'libraryUri': config.testModule3.libraryUri,
                    'moduleName': config.testModule3.moduleName,
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
                          'infos': isEmpty,
                          'compiledProcedure': contains(
                              'new test_library.B.new().c().getNumber()'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure':
                              contains('test_library.B.new().printNumber()'),
                        }),
                        equals({
                          'succeeded': true,
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains(
                              'new test_library.B.new().c().getNumber()'),
                        }),
                        equals({
                          'succeeded': true,
                          'errors': isEmpty,
                          'warnings': isEmpty,
                          'infos': isEmpty,
                          'compiledProcedure': contains('return formal;'),
                        }),
                      ]));
                });
              });
            });
          }
        });
      }
    });
  }
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

    Directory.fromUri(config.outputPath)..createSync();

    // generate test_library3.full.dill
    var args = [
      dartdevc,
      config.testModule3.libraryUri,
      '-o',
      config.testModule3.jsPath.toFilePath(),
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath.path,
      '--multi-root',
      '${config.root}',
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      '${config.moduleFormat}',
    ];

    var exitCode = await runProcess(dart, args, config.rootPath);
    if (exitCode != 0) {
      return exitCode;
    }

    // generate test_library2.full.dill
    args = [
      dartdevc,
      config.testModule2.libraryUri,
      '-o',
      config.testModule2.jsPath.toFilePath(),
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath.path,
      '--multi-root',
      '${config.root}',
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      '${config.moduleFormat}',
    ];

    exitCode = await runProcess(dart, args, config.rootPath);
    if (exitCode != 0) {
      return exitCode;
    }

    // generate test_library.full.dill
    args = [
      dartdevc,
      config.testModule.libraryUri,
      '--summary',
      '${config.testModule2.summaryDillPath}=${config.testModule2.moduleName}',
      '-o',
      config.testModule.jsPath.toFilePath(),
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath.path,
      '--multi-root',
      '${config.root}',
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      '${config.moduleFormat}',
    ];

    exitCode = await runProcess(dart, args, config.rootPath);
    if (exitCode != 0) {
      return exitCode;
    }

    // generate main.full.dill
    args = [
      dartdevc,
      config.mainModule.libraryUri,
      '--summary',
      '${config.testModule3.summaryDillPath}=${config.testModule3.moduleName}',
      '--summary',
      '${config.testModule.summaryDillPath}=${config.testModule.moduleName}',
      '-o',
      config.mainModule.jsPath.toFilePath(),
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--experimental-output-compiled-kernel',
      '--dart-sdk-summary',
      config.sdkSummaryPath.path,
      '--multi-root',
      '${config.root}',
      '--multi-root-scheme',
      'org-dartlang-app',
      '--packages',
      config.packagesPath.toFilePath(),
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      '${config.moduleFormat}',
    ];

    return await runProcess(dart, args, config.rootPath);
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
