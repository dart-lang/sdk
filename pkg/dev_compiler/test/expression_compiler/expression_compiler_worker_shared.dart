// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show Directory, File, HttpServer, Platform, Process, stderr, stdout;
import 'dart:isolate';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/kernel/asset_file_system.dart';
import 'package:dev_compiler/src/kernel/expression_compiler_worker.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

import 'setup_compiler_options.dart';

void runTests(SetupCompilerOptions setup, {bool verbose = false}) {
  group('expression compiler worker on startup', () {
    late Directory tempDir;
    late ReceivePort receivePort;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('foo bar');
      receivePort = ReceivePort();
    });

    tearDown(() {
      receivePort.close();
      tempDir.deleteSync(recursive: true);
    });

    test('reports failure to consumer', () async {
      expect(
          receivePort,
          emitsInOrder([
            equals(isA<SendPort>()),
            equals({
              'succeeded': false,
              'stackTrace': isNotNull,
              'exception': contains('Could not load SDK component'),
            }),
          ]));

      try {
        var badPath = 'file:///path/does/not/exist';
        await ExpressionCompilerWorker.createAndStart(
          [
            '--libraries-file',
            badPath,
            '--dart-sdk-summary',
            badPath,
            '--module-format',
            setup.moduleFormat.name,
            setup.soundNullSafety
                ? '--sound-null-safety'
                : '--no-sound-null-safety',
            if (setup.enableAsserts) '--enable-asserts',
            if (setup.canaryFeatures) '--canary',
            if (verbose) '--verbose',
          ],
          sendPort: receivePort.sendPort,
        );
      } catch (e) {
        throwsA(contains('Could not load SDK component'));
      }
    });
  });

  group('reading assets using standard file system - ', () {
    runExpressionCompilationTests(StandardFileSystemTestDriver(
      setup.soundNullSafety,
      setup.moduleFormat,
      setup.canaryFeatures,
      setup.enableAsserts,
      verbose,
    ));
  });

  group('reading assets using multiroot file system - ', () {
    runExpressionCompilationTests(MultiRootFileSystemTestDriver(
      setup.soundNullSafety,
      setup.moduleFormat,
      setup.canaryFeatures,
      setup.enableAsserts,
      verbose,
    ));
  });

  group('reading assets using asset file system -', () {
    runExpressionCompilationTests(AssetFileSystemTestDriver(
      setup.soundNullSafety,
      setup.moduleFormat,
      setup.canaryFeatures,
      setup.enableAsserts,
      verbose,
    ));
  });
}

void runExpressionCompilationTests(TestDriver driver) {
  group('expression compiler worker', () {
    setUpAll(() async {
      await driver.setUpAll();
    });

    tearDownAll(() async {
      await driver.tearDownAll();
    });

    setUp(() async {
      await driver.setUp();
    });

    tearDown(() async {
      await driver.tearDown();
    });

    test('can compile expressions in sdk', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
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
          driver.responseController.stream,
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

    test('can compile expressions in a library', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      expect(
          driver.responseController.stream,
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

    test('compile expressions include "dart.library..." environment defines.',
        () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'const bool.fromEnvironment("dart.library.html")',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      expect(
          driver.responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('true'),
            })
          ]));
    });

    test('can compile expressions in main', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'count',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {'count': 'count'},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
          driver.responseController.stream,
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

    test('can compile expressions in main (extension method)', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'ret',
        'line': 19,
        'column': 1,
        'jsModules': {},
        'jsScope': {'ret': 'ret'},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
          driver.responseController.stream,
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

    test('can compile transitive expressions in main', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().c().getNumber()',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
          driver.responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': matches(
                  r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)'),
            })
          ]));
    });

    test('can compile expressions in non-strongly-connected components', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule3').libraryUris.last,
        'moduleName': driver.config.getModule('testModule3').moduleName,
      });

      expect(
          driver.responseController.stream,
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
            }),
          ]));
    });

    test('can compile expressions in strongly connected components', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule4').libraryUris.last,
        'moduleName': driver.config.getModule('testModule4').moduleName,
      });

      expect(
          driver.responseController.stream,
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
            }),
          ]));
    });

    test('can compile series of expressions in various libraries', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().c().getNumber()',
        'line': 8,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 3,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule2').libraryUris.first,
        'moduleName': driver.config.getModule('testModule2').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule3').libraryUris.last,
        'moduleName': driver.config.getModule('testModule3').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule3').libraryUris.last,
        'moduleName': driver.config.getModule('testModule3').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().printNumber()',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
          driver.responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': matches(
                  r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)'),
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
              'compiledProcedure': contains('return formal;'),
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure':
                  matches(r'test_library[\$]?\.B\.new\(\)\.printNumber\(\)'),
            })
          ]));
    });

    test('can compile after dependency update', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().c().getNumber()',
        'line': 8,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().printNumber()',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().c().getNumber()',
        'line': 8,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.getModule('testModule3').libraryUris.last,
        'moduleName': driver.config.getModule('testModule3').moduleName,
      });

      expect(
          driver.responseController.stream,
          emitsInOrder([
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': matches(
                  r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)'),
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
                  matches(r'test_library[\$]?\.B\.new\(\)\.printNumber\(\)'),
            }),
            equals({
              'succeeded': true,
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': matches(
                  r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)'),
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
}

class ModuleConfiguration {
  final Uri root;
  final String outputDir;
  final List<String> libraryUris;
  final List<ModuleConfiguration> dependencies;
  final String moduleName;
  final String jsFileName;
  final String fullDillFileName;
  final String summaryDillFileName;

  ModuleConfiguration({
    required this.root,
    required this.outputDir,
    required this.moduleName,
    required this.libraryUris,
    required this.dependencies,
    required this.jsFileName,
    required this.fullDillFileName,
    required this.summaryDillFileName,
  });

  Uri get jsUri => root.resolve('$outputDir/$jsFileName');
  Uri get multiRootFullDillUri =>
      Uri.parse('org-dartlang-app:///$outputDir/$fullDillFileName');
  Uri get multiRootSummaryUri =>
      Uri.parse('org-dartlang-app:///$outputDir/$summaryDillFileName');

  Uri get relativeFullDillUri => Uri.parse('$outputDir/$fullDillFileName');
  Uri get relativeSummaryUri => Uri.parse('$outputDir/$summaryDillFileName');

  String get fullDillPath => root.resolve('$outputDir/$fullDillFileName').path;
  String get summaryDillPath =>
      root.resolve('$outputDir/$summaryDillFileName').path;
}

class TestProjectConfiguration {
  static final String outputDir = 'out';

  final Directory rootDirectory;
  final bool soundNullSafety;
  final ModuleFormat moduleFormat;
  late final Map<String, ModuleConfiguration> modules;

  TestProjectConfiguration(
      this.rootDirectory, this.soundNullSafety, this.moduleFormat);

  void initialize() {
    final testModule4 = ModuleConfiguration(
        root: root,
        outputDir: outputDir,
        moduleName: 'packages/_testPackage/test_library4',
        libraryUris: [
          'package:_testPackage/test_library7.dart',
          'package:_testPackage/test_library6.dart',
        ],
        dependencies: [],
        jsFileName: 'test_library4.js',
        fullDillFileName: 'test_library4.full.dill',
        summaryDillFileName: 'test_library4.dill');

    final testModule3 = ModuleConfiguration(
        root: root,
        outputDir: outputDir,
        moduleName: 'packages/_testPackage/test_library3',
        libraryUris: [
          'package:_testPackage/test_library5.dart',
          'package:_testPackage/test_library4.dart',
          'package:_testPackage/test_library3.dart',
        ],
        dependencies: [],
        jsFileName: 'test_library3.js',
        fullDillFileName: 'test_library3.full.dill',
        summaryDillFileName: 'test_library3.dill');

    final testModule2 = ModuleConfiguration(
        root: root,
        outputDir: outputDir,
        moduleName: 'packages/_testPackage/test_library2',
        libraryUris: ['package:_testPackage/test_library2.dart'],
        dependencies: [],
        jsFileName: 'test_library2.js',
        fullDillFileName: 'test_library2.full.dill',
        summaryDillFileName: 'test_library2.dill');

    final testModule = ModuleConfiguration(
        root: root,
        outputDir: outputDir,
        moduleName: 'packages/_testPackage/test_library',
        libraryUris: ['package:_testPackage/test_library.dart'],
        dependencies: [testModule2],
        jsFileName: 'test_library.js',
        fullDillFileName: 'test_library.full.dill',
        summaryDillFileName: 'test_library.dill');

    final mainModule = ModuleConfiguration(
        root: root,
        outputDir: outputDir,
        moduleName: 'packages/_testPackage/main',
        libraryUris: ['org-dartlang-app:/lib/main.dart'],
        dependencies: [testModule3, testModule2, testModule],
        jsFileName: 'main.js',
        fullDillFileName: 'main.full.dill',
        summaryDillFileName: 'main.dill');

    modules = {
      'testModule4': testModule4,
      'testModule3': testModule3,
      'testModule2': testModule2,
      'testModule': testModule,
      'mainModule': mainModule,
    };
  }

  String get rootPath => rootDirectory.path;
  Uri get root => rootDirectory.uri;
  Uri get outputPath => root.resolve(outputDir);
  Uri get packagesPath => root.resolve('package_config.json');

  Uri get sdkRoot => computePlatformBinariesLocation();
  // Use the outline copied to the released SDK.
  // Unsound .dill files are not longer in the released SDK so this file must be
  // read from the build output directory.
  Uri get sdkSummaryPath => soundNullSafety
      ? sdkRoot.resolve('ddc_outline.dill')
      : computePlatformBinariesLocation(forceBuildDir: true)
          .resolve('ddc_outline_unsound.dill');
  Uri get librariesPath => sdkRoot.resolve('lib/libraries.json');

  List get inputUris => [
        for (var module in modules.values) ...[
          {
            'path': '${module.multiRootFullDillUri}',
            'summaryPath': '${module.multiRootSummaryUri}',
            'moduleName': module.moduleName
          },
        ]
      ];

  List get inputRelativeUris => [
        for (var module in modules.values) ...[
          {
            'path': '${module.multiRootFullDillUri}',
            'summaryPath': '${module.multiRootSummaryUri}',
            'moduleName': module.moduleName
          },
        ]
      ];

  List get inputPaths => [
        for (var module in modules.values) ...[
          {
            'path': module.fullDillPath,
            'summaryPath': module.summaryDillPath,
            'moduleName': module.moduleName
          },
        ]
      ];

  ModuleConfiguration getModule(String name) => modules[name]!;

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
  testLibraryFunctionD(D());
  testLibraryFunctionE();
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

    // Non-strongly connected component of libraries
    var testLibrary3 = root.resolve('lib/test_library3.dart');
    File.fromUri(testLibrary3)
      ..createSync()
      ..writeAsStringSync('''

import 'package:_testPackage/test_library4.dart';

int testLibraryFunction3(int formal) {
  return formal; // line 5
}

D testLibraryFunctionD(D formal) {
  return formal; // line 9
}

class D {}

void testLibraryFunctionE() {
  E();
}
''');

    var testLibrary4 = root.resolve('lib/test_library4.dart');
    File.fromUri(testLibrary4)
      ..createSync()
      ..writeAsStringSync('''
class E {}
''');

    // Unconnected library
    var testLibrary5 = root.resolve('lib/test_library5.dart');
    File.fromUri(testLibrary5)
      ..createSync()
      ..writeAsStringSync('''
class F {}
''');

    // Strongly connected component of libraries
    var testLibrary6 = root.resolve('lib/test_library6.dart');
    File.fromUri(testLibrary6)
      ..createSync()
      ..writeAsStringSync('''

import 'package:_testPackage/test_library7.dart';

D testLibraryFunctionD(D formal) {
  return formal; // line 5
}

class D {}

void testLibraryFunctionE() {
  E();
}
''');

    var testLibrary7 = root.resolve('lib/test_library7.dart');
    File.fromUri(testLibrary7)
      ..createSync()
      ..writeAsStringSync('''
import 'package:_testPackage/test_library6.dart';

class E {
  void foo(D bar) {}
}
''');
  }
}

abstract class TestDriver {
  final bool soundNullSafety;
  final ModuleFormat moduleFormat;
  final bool canaryFeatures;
  final bool enableAsserts;
  final bool verbose;

  late FileSystem assetFileSystem;

  late Directory tempDir;
  late TestProjectConfiguration config;
  late List inputs;

  late StreamController<Map<String, dynamic>> requestController;
  late StreamController<Map<String, dynamic>> responseController;
  ExpressionCompilerWorker? worker;
  Future<void>? workerDone;

  TestDriver(
    this.soundNullSafety,
    this.moduleFormat,
    this.canaryFeatures,
    this.enableAsserts,
    this.verbose,
  );

  /// Initialize file systems, inputs, and start servers if needed.
  Future<void> start();

  Future<void>? stop() => workerDone;

  Future<void> setUpAll() async {
    tempDir = Directory.systemTemp.createTempSync('foo bar');
    config = TestProjectConfiguration(tempDir, soundNullSafety, moduleFormat)
      ..initialize();

    await start();

    // Build the project.
    config.createTestProject();
    var kernelGenerator = DDCKernelGenerator(config, verbose);
    await kernelGenerator.generate();
  }

  Future<void> tearDownAll() async {
    await stop();
    tempDir.deleteSync(recursive: true);
  }

  Future<void> setUp() async {
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
      fileSystem: assetFileSystem,
      requestStream: requestController.stream,
      sendResponse: responseController.add,
      soundNullSafety: soundNullSafety,
      moduleFormat: moduleFormat,
      canaryFeatures: canaryFeatures,
      enableAsserts: enableAsserts,
      verbose: verbose,
    );
    workerDone = worker?.run();
  }

  Future<void> tearDown() async {
    unawaited(requestController.close());
    await workerDone;
    unawaited(responseController.close());
    worker?.close();
  }
}

class StandardFileSystemTestDriver extends TestDriver {
  StandardFileSystemTestDriver(
    bool soundNullSafety,
    ModuleFormat moduleFormat,
    bool canaryFeatures,
    bool enableAsserts,
    bool verbose,
  ) : super(soundNullSafety, moduleFormat, canaryFeatures, enableAsserts,
            verbose);

  @override
  Future<void> start() async {
    inputs = config.inputPaths;
    assetFileSystem = StandardFileSystem.instance;
  }
}

class MultiRootFileSystemTestDriver extends TestDriver {
  MultiRootFileSystemTestDriver(
    bool soundNullSafety,
    ModuleFormat moduleFormat,
    bool canaryFeatures,
    bool enableAsserts,
    bool verbose,
  ) : super(soundNullSafety, moduleFormat, canaryFeatures, enableAsserts,
            verbose);

  @override
  Future<void> start() async {
    inputs = config.inputUris;
    var fileSystem = MultiRootFileSystem(
        'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);
    assetFileSystem = fileSystem;
  }
}

class AssetFileSystemTestDriver extends TestDriver {
  late TestAssetServer server;
  late int port;

  AssetFileSystemTestDriver(
    bool soundNullSafety,
    ModuleFormat moduleFormat,
    bool canaryFeatures,
    bool enableAsserts,
    bool verbose,
  ) : super(soundNullSafety, moduleFormat, canaryFeatures, enableAsserts,
            verbose);

  @override
  Future<void> start() async {
    inputs = config.inputRelativeUris;
    var fileSystem = MultiRootFileSystem(
        'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);
    port = await findUnusedPort();
    server = TestAssetServer(fileSystem);
    assetFileSystem = AssetFileSystem(fileSystem, 'localhost', '$port');
    await server.start('localhost', port);
  }

  @override
  Future<void> stop() async {
    server.stop();
    await super.stop();
    (assetFileSystem as AssetFileSystem).close();
  }
}

class TestAssetServer {
  FileSystem fileSystem;
  HttpServer? server;

  TestAssetServer(this.fileSystem);

  FutureOr<Response> handler(Request request) async {
    var requested = request.requestedUri.path;
    final uri = Uri.parse('org-dartlang-app:/$requested');

    assert(requested.startsWith('/'));
    final path = requested.substring(1);

    try {
      var entity = fileSystem.entityForUri(uri);
      if (await entity.existsAsyncIfPossible()) {
        if (request.method == 'HEAD' || request.method == 'GET') {
          // 'readAsBytes'
          var contents = await entity.readAsBytesAsyncIfPossible();
          var headers = {
            'content-length': '${contents.length}',
            ...request.headers,
          };
          return Response.ok(request.method == 'GET' ? contents : null,
              headers: headers);
        }
      }
      return Response.notFound(path);
    } catch (e, s) {
      return Response.internalServerError(body: '$e:$s');
    }
  }

  Future<void> start(String hostname, int port) async {
    server = await HttpMultiServer.bind(hostname, port);
    serveRequests(server!, handler);
  }

  void stop() {
    server?.close(force: true);
  }
}

/// Uses DDC to generate kernel from the test code
/// in order to simulate webdev environment
class DDCKernelGenerator {
  final TestProjectConfiguration config;
  final bool verbose;
  static final dart = Platform.resolvedExecutable;
  static final sdkPath =
      computePlatformBinariesLocation(forceBuildDir: true).toFilePath();

  static final dartdevc =
      p.join(sdkPath, 'dart-sdk', 'bin', 'snapshots', 'dartdevc.dart.snapshot');
  static final kernelWorker = p.join(
      sdkPath, 'dart-sdk', 'bin', 'snapshots', 'kernel_worker.dart.snapshot');

  DDCKernelGenerator(this.config, this.verbose);

  Future<int> generate() async {
    Directory.fromUri(config.outputPath).createSync();

    // generate summaries
    var exitCode = 0;
    for (var module in config.modules.values) {
      exitCode = await _generateSummary(module);
      expect(exitCode, 0,
          reason: 'Failed to generate summary dill for ${module.moduleName}');
    }

    // generate full dill
    for (var module in config.modules.values) {
      exitCode = await _generateFullDill(module);
      expect(exitCode, 0,
          reason: 'Failed to generate full dill for ${module.moduleName}');
    }
    return exitCode;
  }

  Future<int> _generateSummary(ModuleConfiguration module) async {
    final args = [
      kernelWorker,
      for (var lib in module.libraryUris) '--source=$lib',
      for (var dependency in module.dependencies)
        '--input-summary=${dependency.multiRootSummaryUri}',
      '--output=${module.relativeSummaryUri.toFilePath()}',
      '--dart-sdk-summary=${config.sdkSummaryPath.path}',
      '--multi-root=${config.root}',
      '--multi-root-scheme=org-dartlang-app',
      '--exclude-non-sources',
      '--summary-only',
      '--reuse-compiler-result',
      '--use-incremental-compiler',
      '--packages-file=${config.packagesPath.path}',
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
    ];

    return runProcess(dart, args, config.rootPath, verbose);
  }

  Future<int> _generateFullDill(ModuleConfiguration module) async {
    final args = [
      dartdevc,
      ...module.libraryUris,
      for (var dependency in module.dependencies) ...[
        '--summary',
        '${dependency.multiRootSummaryUri}=${dependency.moduleName}'
      ],
      '-o',
      module.jsUri.toFilePath(),
      '--source-map',
      '--experimental-emit-debug-metadata',
      '--emit-debug-symbols',
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
      config.moduleFormat.name,
      '--no-summarize',
    ];

    return await runProcess(dart, args, config.rootPath, verbose);
  }
}

Future<int> runProcess(String command, List<String> args,
    String workingDirectory, bool verbose) async {
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
