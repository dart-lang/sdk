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
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:http_multi_server/http_multi_server.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

import '../shared_test_options.dart';

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
        ]),
      );

      try {
        var badPath = 'file:///path/does/not/exist';
        await ExpressionCompilerWorker.createAndStart([
          '--libraries-file',
          badPath,
          '--dart-sdk-summary',
          badPath,
          '--module-format',
          setup.moduleFormat.name,
          if (setup.enableAsserts) '--enable-asserts',
          if (setup.canaryFeatures) '--canary',
          if (verbose) '--verbose',
        ], sendPort: receivePort.sendPort);
      } catch (e) {
        throwsA(contains('Could not load SDK component'));
      }
    });
  });

  group('reading assets using standard file system - ', () {
    runExpressionCompilationTests(StandardFileSystemTestDriver(setup, verbose));
  });

  group('reading assets using multiroot file system - ', () {
    runExpressionCompilationTests(
      MultiRootFileSystemTestDriver(setup, verbose),
    );
  });

  group('reading assets using asset file system -', () {
    runExpressionCompilationTests(AssetFileSystemTestDriver(setup, verbose));
  });
}

void runExpressionCompilationTests(ExpressionCompilerWorkerTestDriver driver) {
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

    test('can compile library level expressions in sdk 0-based', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      // Library level expressions can use line and column 0.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'postEvent',
        'line': 0,
        'column': 0,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': 'dart:developer',
        'moduleName': 'dart_sdk',
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          // TODO(nshahan): https://github.com/dart-lang/sdk/issues/62643
          if (driver.setup.canaryFeatures &&
              driver.setup.moduleFormat == ModuleFormat.ddc)
            equals({
              'succeeded': false,
              'errors': [
                'Expression evaluation in the context of an SDK library '
                    'is not currently supported in this environment.',
              ],
              'warnings': [],
              'infos': [],
              'compiledProcedure': null,
            })
          else
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': stringContainsInOrder([
                'developer',
                'postEvent',
              ]),
            }),
        ]),
      );
    });

    test('can compile library level expressions in sdk 1-based', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      // Library level expressions can use line and column 1.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'postEvent',
        'line': 1,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': 'dart:developer',
        'moduleName': 'dart_sdk',
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          // TODO(nshahan): https://github.com/dart-lang/sdk/issues/62643
          if (driver.setup.canaryFeatures &&
              driver.setup.moduleFormat == ModuleFormat.ddc)
            equals({
              'succeeded': false,
              'errors': [
                'Expression evaluation in the context of an SDK library '
                    'is not currently supported in this environment.',
              ],
              'warnings': [],
              'infos': [],
              'compiledProcedure': null,
            })
          else
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': stringContainsInOrder([
                'developer',
                'postEvent',
              ]),
            }),
        ]),
      );
    });

    test('cannot compile scoped expressions in sdk', () {
      // Support for general expression evaluation in the SDK is not supported.
      // In great part, this is because we don't have the right plumbing of
      // metadata to support looking up scope information for general purpose
      // expressions in any scope.
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
          equals({'succeeded': true}),
          // When support is added, we should expect to see:
          //   'succeeded': true,
          //   'errors': isEmpty,
          //   'warnings': isEmpty,
          //   'infos': isEmpty,
          //   'compiledProcedure': contains('return other;'),
          equals({
            'succeeded': false,
            'exception': contains(
              'Expression compilation inside SDK is not supported yet',
            ),
            'stackTrace': isNotNull,
          }),
        ]),
      );
    });

    test('does not crash on line 0 in a library', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': '1 + 1',
        'line': 0,
        'column': 0,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('1 + 1;'),
          }),
        ]),
      );
    });

    test('does not crash on line thats too high in a library', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': '1 + 1',
        'line': 10000000,
        'column': 1,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': '2 + 2',
        'line': 1,
        'column': 10000000,
        'jsModules': {},
        'jsScope': {},
        'libraryUri': driver.config.getModule('testModule').libraryUris.first,
        'moduleName': driver.config.getModule('testModule').moduleName,
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('1 + 1;'),
          }),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('2 + 2;'),
          }),
        ]),
      );
    });

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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return formal;'),
          }),
        ]),
      );
    });

    test(
      'compile expressions include "dart.library..." environment defines.',
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
            equals({'succeeded': true}),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('true'),
            }),
          ]),
        );
      },
    );

    test(
      'compile expressions include correct import format for module system',
      () {
        driver.requestController.add({
          'command': 'UpdateDeps',
          'inputs': driver.inputs,
        });

        driver.requestController.add({
          'command': 'CompileExpression',
          'expression': '5 is int && 5.isOdd',
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
            equals({'succeeded': true}),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': driver.setup.emitLibraryBundle
                  ? StringContainsUnordered([
                      '"dart:core"',
                      '"dart:_runtime"',
                      '"dart:_rti"',
                      '"dartx"',
                    ])
                  : contains('\'dart_sdk\''),
            }),
          ]),
        );
      },
    );

    test('can compile expressions in main', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'count',
        'line': 9,
        'column': 3,
        'jsModules': {},
        'jsScope': {'count': 'count'},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return count;'),
          }),
        ]),
      );
    });

    test('can compile expressions in main (extension method)', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'ret',
        'line': 18,
        'column': 5,
        'jsModules': {},
        'jsScope': {'ret': 'ret'},
        'libraryUri': driver.config.getModule('mainModule').libraryUris.first,
        'moduleName': driver.config.getModule('mainModule').moduleName,
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return ret;'),
          }),
        ]),
      );
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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': matches(
              r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)',
            ),
          }),
        ]),
      );
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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return formal;'),
          }),
        ]),
      );
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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return formal;'),
          }),
        ]),
      );
    });

    test('can compile expressions in part file without script uri', () {
      driver.requestController.add({
        'command': 'UpdateDeps',
        'inputs': driver.inputs,
      });

      // We're really in the main file - but we're not telling.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'x.length',
        'line': 6,
        'column': 3,
        'jsModules': {},
        'jsScope': {'x': 'x', 'z': 'z'},
        'libraryUri': driver.config.getModule('testModule5').libraryUris.last,
        'moduleName': driver.config.getModule('testModule5').moduleName,
      });

      // We're really in the part file - but we're not telling.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'y + 1',
        'line': 6,
        'column': 3,
        'jsModules': {},
        'jsScope': {'y': 'y', 'z': 'z'},
        'libraryUri': driver.config.getModule('testModule5').libraryUris.last,
        'moduleName': driver.config.getModule('testModule5').moduleName,
      });

      // We're really in the main file - but we're not telling.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'z.length',
        'line': 6,
        'column': 3,
        'jsModules': {},
        'jsScope': {'x': 'x', 'z': 'z'},
        'libraryUri': driver.config.getModule('testModule5').libraryUris.last,
        'moduleName': driver.config.getModule('testModule5').moduleName,
      });

      // We're really in the part file - but we're not telling.
      driver.requestController.add({
        'command': 'CompileExpression',
        'expression': 'z + 1',
        'line': 6,
        'column': 3,
        'jsModules': {},
        'jsScope': {'y': 'y', 'z': 'z'},
        'libraryUri': driver.config.getModule('testModule5').libraryUris.last,
        'moduleName': driver.config.getModule('testModule5').moduleName,
      });

      expect(
        driver.responseController.stream,
        emitsInOrder([
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return x.length;'),
          }),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return y + 1;'),
          }),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return z.length;'),
          }),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return z + 1;'),
          }),
        ]),
      );
    });

    test(
      'can compile expressions in part file with script uri as package uri',
      () {
        driver.requestController.add({
          'command': 'UpdateDeps',
          'inputs': driver.inputs,
        });

        // We're really in the main file - and we're telling as package uri.
        driver.requestController.add({
          'command': 'CompileExpression',
          'expression': 'x.length',
          'line': 5,
          'column': 3,
          'jsModules': {},
          'jsScope': {'x': 'x'},
          'libraryUri': driver.config.getModule('testModule6').libraryUris.last,
          'scriptUri': driver.config.getModule('testModule6').libraryUris.last,
          'moduleName': driver.config.getModule('testModule6').moduleName,
        });

        // We're really in the main file - and we're telling as file uri.
        driver.requestController.add({
          'command': 'CompileExpression',
          'expression': 'x.length',
          'line': 5,
          'column': 3,
          'jsModules': {},
          'jsScope': {'x': 'x'},
          'libraryUri': driver.config.getModule('testModule6').libraryUris.last,
          'scriptUri': driver.config
              .getModule('testModule6')
              .libraryUrisAsFileUri
              .last,
          'moduleName': driver.config.getModule('testModule6').moduleName,
        });

        // We're really in the part file - and we're telling as package uri.
        driver.requestController.add({
          'command': 'CompileExpression',
          'expression': 'x + 1',
          'line': 5,
          'column': 3,
          'jsModules': {},
          'jsScope': {'x': 'x'},
          'libraryUri': driver.config.getModule('testModule6').libraryUris.last,
          'scriptUri': driver.config
              .getModule('testModule6')
              .partUrisAsPackageUri
              .last,
          'moduleName': driver.config.getModule('testModule6').moduleName,
        });

        // We're really in the part file - and we're telling as file uri.
        driver.requestController.add({
          'command': 'CompileExpression',
          'expression': 'x + 1',
          'line': 5,
          'column': 3,
          'jsModules': {},
          'jsScope': {'x': 'x'},
          'libraryUri': driver.config.getModule('testModule6').libraryUris.last,
          'scriptUri': driver.config
              .getModule('testModule6')
              .partUrisAsFileUri
              .last,
          'moduleName': driver.config.getModule('testModule6').moduleName,
        });

        expect(
          driver.responseController.stream,
          emitsInOrder([
            equals({'succeeded': true}),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('return x.length;'),
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('return x.length;'),
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('return x + 1;'),
            }),
            equals({
              'succeeded': true,
              'errors': isEmpty,
              'warnings': isEmpty,
              'infos': isEmpty,
              'compiledProcedure': contains('return x + 1;'),
            }),
          ]),
        );
      },
    );

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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': matches(
              r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)',
            ),
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
            'compiledProcedure': matches(
              r'test_library[\$]?\.B\.new\(\)\.printNumber\(\)',
            ),
          }),
        ]),
      );
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
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': matches(
              r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)',
            ),
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
            'compiledProcedure': matches(
              r'test_library[\$]?\.B\.new\(\)\.printNumber\(\)',
            ),
          }),
          equals({'succeeded': true}),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': matches(
              r'new test_library[\$]?\.B\.new\(\)\.c\(\)\.getNumber\(\)',
            ),
          }),
          equals({
            'succeeded': true,
            'errors': isEmpty,
            'warnings': isEmpty,
            'infos': isEmpty,
            'compiledProcedure': contains('return formal;'),
          }),
        ]),
      );
    });
  });
}

class ModuleConfiguration {
  final Uri root;
  final String outputDir;
  final List<String> libraryUris;
  final List<String> libraryUrisAsFileUri;
  final List<String> partUrisAsPackageUri;
  final List<String> partUrisAsFileUri;
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
    this.libraryUrisAsFileUri = const [],
    this.partUrisAsPackageUri = const [],
    this.partUrisAsFileUri = const [],
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
  final ModuleFormat moduleFormat;
  late final Map<String, ModuleConfiguration> modules;

  TestProjectConfiguration(this.rootDirectory, this.moduleFormat);

  void initialize() {
    final testModule6 = ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library6',
      libraryUris: ['package:_testPackage/test_library9.dart'],
      libraryUrisAsFileUri: [root.resolve('lib/test_library9.dart').toString()],
      partUrisAsPackageUri: ['package:_testPackage/test_library9_part.dart'],
      partUrisAsFileUri: [
        root.resolve('lib/test_library9_part.dart').toString(),
      ],
      dependencies: [],
      jsFileName: 'test_library6.js',
      fullDillFileName: 'test_library6.full.dill',
      summaryDillFileName: 'test_library6.dill',
    );

    final testModule5 = ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library5',
      libraryUris: ['package:_testPackage/test_library8.dart'],
      dependencies: [],
      jsFileName: 'test_library5.js',
      fullDillFileName: 'test_library5.full.dill',
      summaryDillFileName: 'test_library5.dill',
    );

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
      summaryDillFileName: 'test_library4.dill',
    );

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
      summaryDillFileName: 'test_library3.dill',
    );

    final testModule2 = ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library2',
      libraryUris: ['package:_testPackage/test_library2.dart'],
      dependencies: [],
      jsFileName: 'test_library2.js',
      fullDillFileName: 'test_library2.full.dill',
      summaryDillFileName: 'test_library2.dill',
    );

    final testModule = ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/test_library',
      libraryUris: ['package:_testPackage/test_library.dart'],
      dependencies: [testModule2],
      jsFileName: 'test_library.js',
      fullDillFileName: 'test_library.full.dill',
      summaryDillFileName: 'test_library.dill',
    );

    final mainModule = ModuleConfiguration(
      root: root,
      outputDir: outputDir,
      moduleName: 'packages/_testPackage/main',
      libraryUris: ['org-dartlang-app:/lib/main.dart'],
      dependencies: [testModule3, testModule2, testModule],
      jsFileName: 'main.js',
      fullDillFileName: 'main.full.dill',
      summaryDillFileName: 'main.dill',
    );

    modules = {
      'testModule6': testModule6,
      'testModule5': testModule5,
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
  Uri get sdkSummaryPath => sdkRoot.resolve('ddc_outline.dill');
  Uri get librariesPath => sdkRoot.resolve('lib/libraries.json');

  List get inputUris => [
    for (var module in modules.values) ...[
      {
        'path': '${module.multiRootFullDillUri}',
        'summaryPath': '${module.multiRootSummaryUri}',
        'moduleName': module.moduleName,
      },
    ],
  ];

  List get inputRelativeUris => [
    for (var module in modules.values) ...[
      {
        'path': '${module.multiRootFullDillUri}',
        'summaryPath': '${module.multiRootSummaryUri}',
        'moduleName': module.moduleName,
      },
    ],
  ];

  List get inputPaths => [
    for (var module in modules.values) ...[
      {
        'path': module.fullDillPath,
        'summaryPath': module.summaryDillPath,
        'moduleName': module.moduleName,
      },
    ],
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
  print('Global is: \${++global}'); // line 9
  print('Count is: \${++count}');

  B b = new B();
}

extension NumberParsing on String {
  int parseInt() {
    var ret = int.parse(this);
    return ret; // line 18
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

    var testLibrary8 = root.resolve('lib/test_library8.dart');
    var testLibrary8Part = root.resolve('lib/test_library8_part.dart');
    File.fromUri(testLibrary8)
      ..createSync()
      ..writeAsStringSync('''
part 'test_library8_part.dart';
void main() {
  String x = "foo";
  String z = "foo";
  // padding
  foo(); // line 6 column 3 offset 101
  print(x);
}
''');
    File.fromUri(testLibrary8Part)
      ..createSync()
      ..writeAsStringSync('''
part of 'test_library8.dart';
void foo() {
  int y = 42;
  int z = 42;
  // padding...............
  print(y); // line 6 column 3 offset 101
}
''');

    var testLibrary9 = root.resolve('lib/test_library9.dart');
    var testLibrary9Part = root.resolve('lib/test_library9_part.dart');
    File.fromUri(testLibrary9)
      ..createSync()
      ..writeAsStringSync('''
part 'test_library9_part.dart';
void main() {
  String x = "foo";
  // padding
  foo(); // line 5 column 3 offset 81
  print(x);
}
''');
    File.fromUri(testLibrary9Part)
      ..createSync()
      ..writeAsStringSync('''
part of 'test_library9.dart';
void foo() {
  int x = 42;
  // padding.........
  print(x); // line 5 column 3 offset 81
}
''');
  }
}

abstract class ExpressionCompilerWorkerTestDriver {
  SetupCompilerOptions setup;
  bool verbose;
  late FileSystem assetFileSystem;

  late Directory tempDir;
  late TestProjectConfiguration config;
  late List inputs;

  late StreamController<Map<String, dynamic>> requestController;
  late StreamController<Map<String, dynamic>> responseController;
  ExpressionCompilerWorker? worker;
  Future<void>? workerDone;

  ExpressionCompilerWorkerTestDriver(this.setup, this.verbose);

  /// Initialize file systems, inputs, and start servers if needed.
  Future<void> start();

  Future<void>? stop() => workerDone;

  Future<void> setUpAll() async {
    tempDir = Directory.systemTemp.createTempSync('foo bar');
    config = TestProjectConfiguration(tempDir, setup.moduleFormat)
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
      moduleFormat: setup.moduleFormat,
      canaryFeatures: setup.canaryFeatures,
      enableAsserts: setup.enableAsserts,
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

class StandardFileSystemTestDriver extends ExpressionCompilerWorkerTestDriver {
  StandardFileSystemTestDriver(super.setup, super.verbose);

  @override
  Future<void> start() async {
    inputs = config.inputPaths;
    assetFileSystem = StandardFileSystem.instance;
  }
}

class MultiRootFileSystemTestDriver extends ExpressionCompilerWorkerTestDriver {
  MultiRootFileSystemTestDriver(super.setup, super.verbose);

  @override
  Future<void> start() async {
    inputs = config.inputUris;
    var fileSystem = MultiRootFileSystem('org-dartlang-app', [
      tempDir.uri,
    ], StandardFileSystem.instance);
    assetFileSystem = fileSystem;
  }
}

class AssetFileSystemTestDriver extends ExpressionCompilerWorkerTestDriver {
  late TestAssetServer server;
  late int port;

  AssetFileSystemTestDriver(super.setup, super.verbose);

  @override
  Future<void> start() async {
    inputs = config.inputRelativeUris;
    var fileSystem = MultiRootFileSystem('org-dartlang-app', [
      tempDir.uri,
    ], StandardFileSystem.instance);
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
          return Response.ok(
            request.method == 'GET' ? contents : null,
            headers: headers,
          );
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
  static final sdkPath = computePlatformBinariesLocation(
    forceBuildDir: true,
  ).toFilePath();
  static var dartExecutable = p.join(
    sdkPath,
    'dart-sdk',
    'bin',
    Platform.isWindows ? 'dartaotruntime.exe' : 'dartaotruntime',
  );
  static var dartdevc = p.join(
    sdkPath,
    'dart-sdk',
    'bin',
    'snapshots',
    'dartdevc_aot.dart.snapshot',
  );
  static var kernelWorker = p.join(
    sdkPath,
    'dart-sdk',
    'bin',
    'snapshots',
    'kernel_worker_aot.dart.snapshot',
  );

  DDCKernelGenerator(this.config, this.verbose);

  Future<int> generate() async {
    var exitCode = 0;
    if (!File(dartdevc).existsSync()) {
      exitCode = 1;
      expect(
        exitCode,
        0,
        reason: 'Unable to locate snapshot for compiler $dartdevc',
      );
    }
    Directory.fromUri(config.outputPath).createSync();

    // generate summaries
    for (var module in config.modules.values) {
      exitCode = await _generateSummary(module);
      expect(
        exitCode,
        0,
        reason: 'Failed to generate summary dill for ${module.moduleName}',
      );
    }

    // generate full dill
    for (var module in config.modules.values) {
      exitCode = await _generateFullDill(module);
      expect(
        exitCode,
        0,
        reason: 'Failed to generate full dill for ${module.moduleName}',
      );
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
      // TODO(nshahan): Remove when kernel worker defaults to sound null safety.
      '--sound-null-safety',
    ];

    return runProcess(dartExecutable, args, config.rootPath, verbose);
  }

  Future<int> _generateFullDill(ModuleConfiguration module) async {
    final args = [
      dartdevc,
      ...module.libraryUris,
      for (var dependency in module.dependencies) ...[
        '--summary',
        '${dependency.multiRootSummaryUri}=${dependency.moduleName}',
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
      '--modules',
      config.moduleFormat.name,
      '--no-summarize',
    ];

    return await runProcess(dartExecutable, args, config.rootPath, verbose);
  }
}

Future<int> runProcess(
  String command,
  List<String> args,
  String workingDirectory,
  bool verbose,
) async {
  if (verbose) {
    print(
      'Running command in $workingDirectory:'
      '\n\t $command ${args.join(' ')}, ',
    );
  }
  var process =
      await Process.start(
        command,
        args,
        workingDirectory: workingDirectory,
      ).then((Process process) {
        process
          ..stdout.transform(utf8.decoder).listen(stdout.write)
          ..stderr.transform(utf8.decoder).listen(stderr.write);
        return process;
      });

  return await process.exitCode;
}

/// A matcher that checks if a string contains all of the expected substrings in
/// any order.
class StringContainsUnordered extends Matcher {
  final List<String> _expected;

  StringContainsUnordered(this._expected);

  @override
  bool matches(item, Map matchState) {
    if (item is! String) return false;
    for (var expected in _expected) {
      if (!item.contains(expected)) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('contains all of ').addDescriptionOf(_expected);

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! String) {
      return mismatchDescription.add('is not a string');
    }
    var missing = _expected.where((e) => !item.contains(e)).toList();
    return mismatchDescription.add('is missing ').addDescriptionOf(missing);
  }
}
