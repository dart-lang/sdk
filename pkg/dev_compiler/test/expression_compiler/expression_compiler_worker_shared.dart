// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show Directory, File, HttpServer, Platform, Process, stderr, stdout;
import 'dart:isolate';

import 'package:browser_launcher/browser_launcher.dart';
import 'package:build_integration/file_system/multi_root.dart';
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

/// Verbose mode for debugging
bool get verbose => false;

void runTests(String moduleFormat, bool soundNullSafety) {
  group('expression compiler worker on startup', () {
    Directory tempDir;
    ReceivePort receivePort;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('foo bar');
      receivePort = ReceivePort();
    });

    tearDown(() async {
      tempDir.deleteSync(recursive: true);
      receivePort.close();
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
            moduleFormat,
            soundNullSafety ? '--sound-null-safety' : '--no-sound-null-safety',
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
    runExpressionCompilationTests(
        StandardFileSystemTestDriver(soundNullSafety, moduleFormat));
  });

  group('reading assets using multiroot file system - ', () {
    runExpressionCompilationTests(
        MultiRootFileSystemTestDriver(soundNullSafety, moduleFormat));
  });

  group('reading assets using asset file system -', () {
    runExpressionCompilationTests(
        AssetFileSystemTestDriver(soundNullSafety, moduleFormat));
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

    test('can compile expressions in sdk', () async {
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

    test('can compile expressions in a library', () async {
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
        'libraryUri': driver.config.testModule.libraryUri,
        'moduleName': driver.config.testModule.moduleName,
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
        () async {
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
        'libraryUri': driver.config.testModule.libraryUri,
        'moduleName': driver.config.testModule.moduleName,
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

    test('can compile expressions in main', () async {
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
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

    test('can compile expressions in main (extension method)', () async {
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
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

    test('can compile transitive expressions in main', () async {
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
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
              'compiledProcedure':
                  contains('new test_library.B.new().c().getNumber()'),
            })
          ]));
    });

    test('can compile series of expressions in various libraries', () async {
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.testModule.libraryUri,
        'moduleName': driver.config.testModule.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 3,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.testModule2.libraryUri,
        'moduleName': driver.config.testModule2.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 3,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.testModule3.libraryUri,
        'moduleName': driver.config.testModule3.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().printNumber()',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
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
              'compiledProcedure':
                  contains('new test_library.B.new().c().getNumber()'),
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 5,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.testModule.libraryUri,
        'moduleName': driver.config.testModule.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'B().printNumber()',
        'line': 9,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
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
        'libraryUri': driver.config.mainModule.libraryUri,
        'moduleName': driver.config.mainModule.moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'formal',
        'line': 3,
        'column': 1,
        'jsModules': {},
        'jsScope': {'formal': 'formal'},
        'libraryUri': driver.config.testModule3.libraryUri,
        'moduleName': driver.config.testModule3.moduleName,
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
              'compiledProcedure':
                  contains('new test_library.B.new().c().getNumber()'),
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
              'compiledProcedure':
                  contains('new test_library.B.new().c().getNumber()'),
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

  Uri get jsUri => root.resolve('$outputDir/$jsFileName');
  Uri get multiRootFullDillUri =>
      Uri.parse('org-dartlang-app:///$outputDir/$fullDillFileName');
  Uri get multiRootSummaryUri =>
      Uri.parse('org-dartlang-app:///$outputDir/$summaryDillFileName');

  Uri get relativeFullDillUri => Uri.parse('$outputDir/$fullDillFileName');
  Uri get realtiveSummaryUri => Uri.parse('$outputDir/$summaryDillFileName');

  String get fullDillPath => root.resolve('$outputDir/$fullDillFileName').path;
  String get summaryDillPath =>
      root.resolve('$outputDir/$summaryDillFileName').path;
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

  List get inputUris => [
        {
          'path': '${mainModule.multiRootFullDillUri}',
          'summaryPath': '${mainModule.multiRootSummaryUri}',
          'moduleName': mainModule.moduleName
        },
        {
          'path': '${testModule.multiRootFullDillUri}',
          'summaryPath': '${testModule.multiRootSummaryUri}',
          'moduleName': testModule.moduleName
        },
        {
          'path': '${testModule2.multiRootFullDillUri}',
          'summaryPath': '${testModule2.multiRootSummaryUri}',
          'moduleName': testModule2.moduleName
        },
        {
          'path': '${testModule3.multiRootFullDillUri}',
          'summaryPath': '${testModule3.multiRootSummaryUri}',
          'moduleName': testModule3.moduleName
        },
      ];

  List get inputRelativeUris => [
        {
          'path': '${mainModule.multiRootFullDillUri}',
          'summaryPath': '${mainModule.multiRootSummaryUri}',
          'moduleName': mainModule.moduleName
        },
        {
          'path': '${testModule.multiRootFullDillUri}',
          'summaryPath': '${testModule.multiRootSummaryUri}',
          'moduleName': testModule.moduleName
        },
        {
          'path': '${testModule2.multiRootFullDillUri}',
          'summaryPath': '${testModule2.multiRootSummaryUri}',
          'moduleName': testModule2.moduleName
        },
        {
          'path': '${testModule3.multiRootFullDillUri}',
          'summaryPath': '${testModule3.multiRootSummaryUri}',
          'moduleName': testModule3.moduleName
        },
      ];

  List get inputPaths => [
        {
          'path': mainModule.fullDillPath,
          'summaryPath': mainModule.summaryDillPath,
          'moduleName': mainModule.moduleName
        },
        {
          'path': testModule.fullDillPath,
          'summaryPath': testModule.summaryDillPath,
          'moduleName': testModule.moduleName
        },
        {
          'path': testModule2.fullDillPath,
          'summaryPath': testModule2.summaryDillPath,
          'moduleName': testModule2.moduleName
        },
        {
          'path': testModule3.fullDillPath,
          'summaryPath': testModule3.summaryDillPath,
          'moduleName': testModule3.moduleName
        },
      ];

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

abstract class TestDriver {
  final bool soundNullSafety;
  final String moduleFormat;

  FileSystem fileSystem;
  FileSystem assetFileSystem;

  Directory tempDir;
  TestProjectConfiguration config;
  List inputs;

  StreamController<Map<String, dynamic>> requestController;
  StreamController<Map<String, dynamic>> responseController;
  ExpressionCompilerWorker worker;
  Future<void> workerDone;

  TestDriver(this.soundNullSafety, this.moduleFormat);

  /// Initialize file systems, inputs, and start servers if needed.
  Future<void> start();

  Future<void> stop() => workerDone;

  Future<void> setUpAll() async {
    tempDir = Directory.systemTemp.createTempSync('foo bar');
    config = TestProjectConfiguration(tempDir, soundNullSafety, moduleFormat);

    await start();

    // Build the project.
    config.createTestProject();
    var kernelGenerator = DDCKernelGenerator(config);
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
      verbose: verbose,
    );
    workerDone = worker.run();
  }

  Future<void> tearDown() async {
    unawaited(requestController.close());
    await workerDone;
    unawaited(responseController.close());
    worker?.close();
  }
}

class StandardFileSystemTestDriver extends TestDriver {
  StandardFileSystemTestDriver(bool soundNullSafety, String moduleFormat)
      : super(soundNullSafety, moduleFormat);

  @override
  Future<void> start() async {
    inputs = config.inputPaths;
    fileSystem = MultiRootFileSystem(
        'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);
    assetFileSystem = StandardFileSystem.instance;
  }
}

class MultiRootFileSystemTestDriver extends TestDriver {
  MultiRootFileSystemTestDriver(bool soundNullSafety, String moduleFormat)
      : super(soundNullSafety, moduleFormat);

  @override
  Future<void> start() async {
    inputs = config.inputUris;
    fileSystem = MultiRootFileSystem(
        'org-dartlang-app', [tempDir.uri], StandardFileSystem.instance);
    assetFileSystem = fileSystem;
  }
}

class AssetFileSystemTestDriver extends TestDriver {
  TestAssetServer server;
  int port;

  AssetFileSystemTestDriver(bool soundNullSafety, String moduleFormat)
      : super(soundNullSafety, moduleFormat);

  @override
  Future<void> start() async {
    inputs = config.inputRelativeUris;
    fileSystem = MultiRootFileSystem(
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
  HttpServer server;

  TestAssetServer(this.fileSystem);

  FutureOr<Response> handler(Request request) async {
    var requested = request.requestedUri.path;
    final uri = Uri.parse('org-dartlang-app:/$requested');

    assert(requested.startsWith('/'));
    final path = requested.substring(1);

    try {
      var entity = fileSystem.entityForUri(uri);
      if (await entity.existsAsyncIfPossible()) {
        if (request.method == 'HEAD') {
          var headers = {
            'content-length': null,
            ...request.headers,
          };
          return Response.ok(null, headers: headers);
        }

        if (request.method == 'GET') {
          // 'readAsBytes'
          var contents = await entity.readAsBytesAsyncIfPossible();
          var headers = {
            'content-length': '${contents.length}',
            ...request.headers,
          };
          return Response.ok(contents, headers: headers);
        }
      }
      return Response.notFound(path);
    } catch (e, s) {
      return Response.internalServerError(body: '$e:$s');
    }
  }

  Future<void> start(String hostname, int port) async {
    server = await HttpMultiServer.bind(hostname, port);
    serveRequests(server, handler);
  }

  void stop() {
    server?.close(force: true);
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

    Directory.fromUri(config.outputPath).createSync();

    // generate test_library3.full.dill
    var args = [
      dartdevc,
      config.testModule3.libraryUri,
      '-o',
      config.testModule3.jsUri.toFilePath(),
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
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      config.moduleFormat,
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
      config.testModule2.jsUri.toFilePath(),
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
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      config.moduleFormat,
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
      '${config.testModule2.multiRootSummaryUri}='
          '${config.testModule2.moduleName}',
      '-o',
      config.testModule.jsUri.toFilePath(),
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
      config.packagesPath.path,
      if (config.soundNullSafety) '--sound-null-safety',
      if (!config.soundNullSafety) '--no-sound-null-safety',
      '--modules',
      config.moduleFormat,
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
      '${config.testModule3.multiRootSummaryUri}='
          '${config.testModule3.moduleName}',
      '--summary',
      '${config.testModule.multiRootSummaryUri}='
          '${config.testModule.moduleName}',
      '-o',
      config.mainModule.jsUri.toFilePath(),
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
      config.moduleFormat,
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
