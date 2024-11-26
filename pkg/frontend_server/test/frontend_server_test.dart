// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: empty_catches

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/compiler/request_channel.dart';
import 'package:args/args.dart';
import 'package:front_end/src/api_unstable/vm.dart';
import 'package:frontend_server/frontend_server.dart';
import 'package:frontend_server/starter.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/kernel.dart' show loadComponentFromBinary;
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart' show VerificationStage, verifyComponent;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm/incremental_compiler.dart';
import 'package:vm/kernel_front_end.dart';

bool useJsonForCommunication = false;
bool useJsonLineBreaks = false;

class _MockedBinaryPrinter implements BinaryPrinter {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _MockedBinaryPrinterFactory implements BinaryPrinterFactory {
  @override
  BinaryPrinter newBinaryPrinter(Sink<List<int>> targetSink) {
    return new _MockedBinaryPrinter();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

typedef VerifyCompile = void Function(String entryPoint, ArgResults opts);
typedef VerifyInvalidate = void Function(Uri uri);
typedef VerifyRecompileDelta = void Function(String? entryPoint);
typedef Verify = void Function();

void nopVerifyCompile(String entryPoint, ArgResults opts) {}
void nopVerifyInvalidate(Uri uri) {}
void nopVerifyRecompileDelta(String? entryPoint) {}
void nopVerify() {}

class _MockedCompiler implements CompilerInterface {
  _MockedCompiler(
      {this.verifyCompile = nopVerifyCompile,
      this.verifyRecompileDelta = nopVerifyRecompileDelta,
      this.verifyInvalidate = nopVerifyInvalidate,
      this.verifyAcceptLastDelta = nopVerify,
      this.verifyResetIncrementalCompiler = nopVerify});

  @override
  void acceptLastDelta() {
    verifyAcceptLastDelta();
  }

  @override
  Future<void> recompileDelta({String? entryPoint}) async {
    verifyRecompileDelta(entryPoint);
  }

  @override
  void resetIncrementalCompiler() {
    verifyResetIncrementalCompiler();
  }

  @override
  void invalidate(Uri uri) {
    verifyInvalidate(uri);
  }

  @override
  Future<bool> compile(
    String entryPoint,
    ArgResults opts, {
    IncrementalCompiler? generator,
  }) async {
    verifyCompile(entryPoint, opts);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}

  final VerifyCompile verifyCompile;
  final VerifyRecompileDelta verifyRecompileDelta;
  final VerifyInvalidate verifyInvalidate;
  final Verify verifyAcceptLastDelta;
  final Verify verifyResetIncrementalCompiler;
}

class _MockedIncrementalCompiler implements IncrementalCompiler {
  @override
  void accept() {}

  @override
  bool get initialized => false;

  @override
  Future<IncrementalCompilerResult> compile({List<Uri>? entryPoints}) async {
    return new Future<IncrementalCompilerResult>.value(
        new IncrementalCompilerResult(new Component()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

Future<void> main() async {
  group('basic', () {
    final _MockedCompiler compiler = new _MockedCompiler();

    test('train with mocked compiler completes', () async {
      await starter(<String>['--train', 'foo.dart'], compiler: compiler);
    });
  });

  group('batch compile with mocked compiler', () {
    test('compile from command line', () async {
      void verify(String entryPoint, ArgResults opts) {
        expect(entryPoint, equals('server.dart'));
        expect(opts['sdk-root'], equals('sdkroot'));
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
      ];
      await starter(args, compiler: compiler);
    });

    test('compile from command line with link platform', () async {
      void verify(String entryPoint, ArgResults opts) {
        expect(entryPoint, equals('server.dart'));
        expect(opts['sdk-root'], equals('sdkroot'));
        expect(opts['link-platform'], equals(true));
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--link-platform',
      ];
      await starter(args, compiler: compiler);
    });
  });

  group('interactive compile with mocked compiler', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final ReceivePort compileCalled = new ReceivePort();
      void verify(String entryPoint, ArgResults opts) {
        expect(entryPoint, equals('server.dart'));
        expect(opts['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    group('compile one file to JavaScript', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        final ReceivePort compileCalled = new ReceivePort();
        void verify(String entryPoint, ArgResults opts) {
          expect(entryPoint, equals('server.dart'));
          expect(opts['sdk-root'], equals('sdkroot'));
          compileCalled.sendPort.send(true);
        }

        final _MockedCompiler compiler =
            new _MockedCompiler(verifyCompile: verify);
        final StreamController<List<int>> inputStreamController =
            new StreamController<List<int>>();

        Future<int> result = starter(
          [
            '--target=dartdevc',
            '--dartdevc-module-format=$moduleFormat',
            if (canary) '--dartdevc-canary',
            ...args
          ],
          compiler: compiler,
          input: inputStreamController.stream,
        );
        inputStreamController.add('compile server.dart\n'.codeUnits);
        await compileCalled.first;
        inputStreamController.add('quit\n'.codeUnits);
        expect(await result, 0);
        await inputStreamController.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });
  });

  group('interactive compile with mocked compiler', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final ReceivePort compileCalled = new ReceivePort();
      void verify(String entryPoint, ArgResults opts) {
        expect(entryPoint, equals('server.dart'));
        expect(opts['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    test('compile few files', () async {
      final ReceivePort compileCalled = new ReceivePort();
      int counter = 1;
      void verify(String entryPoint, ArgResults opts) {
        expect(entryPoint, equals('server${counter++}.dart'));
        expect(opts['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server1.dart\n'.codeUnits);
      inputStreamController.add('compile server2.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });
  });

  group('interactive incremental compile with mocked compiler', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental'
    ];

    test('recompile few files', () async {
      final ReceivePort recompileDeltaCalled = new ReceivePort();
      int invalidated = 0;
      int counter = 1;
      void verifyI(Uri uri) {
        expect(uri.path, contains('file${counter++}.dart'));
        invalidated += 1;
      }

      void verifyR(String? entryPoint) {
        expect(invalidated, equals(2));
        expect(entryPoint, equals(null));
        recompileDeltaCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler = new _MockedCompiler(
          verifyInvalidate: verifyI, verifyRecompileDelta: verifyR);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();

      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController
          .add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileDeltaCalled.first;

      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    test('recompile few files with new entrypoint', () async {
      int invalidated = 0;
      final ReceivePort recompileDeltaCalled = new ReceivePort();
      int counter = 1;
      void verifyI(Uri uri) {
        expect(uri.path, contains('file${counter++}.dart'));
        invalidated += 1;
      }

      void verifyR(String? entryPoint) {
        expect(invalidated, equals(2));
        expect(entryPoint, equals('file2.dart'));
        recompileDeltaCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler = new _MockedCompiler(
          verifyRecompileDelta: verifyR, verifyInvalidate: verifyI);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();

      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add(
          'recompile file2.dart abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileDeltaCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    test('accept', () async {
      final ReceivePort acceptCalled = new ReceivePort();
      void verify() {
        acceptCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyAcceptLastDelta: verify);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('accept\n'.codeUnits);
      await acceptCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    test('reset', () async {
      final ReceivePort resetCalled = new ReceivePort();
      void verify() {
        resetCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyResetIncrementalCompiler: verify);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('reset\n'.codeUnits);
      await resetCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    test('compile then recompile', () async {
      final ReceivePort recompileDeltaCalled = new ReceivePort();
      bool compile = false;
      int invalidate = 0;
      bool acceptDelta = false;
      void verifyC(String entryPoint, ArgResults opts) {
        compile = true;
        expect(entryPoint, equals('file1.dart'));
      }

      void verifyA() {
        expect(compile, equals(true));
        acceptDelta = true;
      }

      int counter = 2;
      void verifyI(Uri uri) {
        expect(compile, equals(true));
        expect(acceptDelta, equals(true));
        expect(uri.path, contains('file${counter++}.dart'));
        invalidate += 1;
      }

      void verifyR(String? entryPoint) {
        expect(compile, equals(true));
        expect(invalidate, equals(2));
        expect(acceptDelta, equals(true));
        expect(entryPoint, equals(null));
        recompileDeltaCalled.sendPort.send(true);
      }

      final _MockedCompiler compiler = new _MockedCompiler(
          verifyCompile: verifyC,
          verifyRecompileDelta: verifyR,
          verifyInvalidate: verifyI,
          verifyAcceptLastDelta: verifyA);
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();

      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile file1.dart\n'.codeUnits);
      inputStreamController.add('accept\n'.codeUnits);
      inputStreamController
          .add('recompile def\nfile2.dart\nfile3.dart\ndef\n'.codeUnits);
      await recompileDeltaCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });
  });

  group('interactive incremental compile with mocked IKG', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental',
    ];

    late Directory tempDir;
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });
    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('compile then accept', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      ReceivePort receivedResult = new ReceivePort();

      String? boundaryKey;
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String s) {
        const String resultOutputSpace = 'result ';
        if (boundaryKey == null) {
          if (s.startsWith(resultOutputSpace)) {
            boundaryKey = s.substring(resultOutputSpace.length);
          }
        } else {
          if (s.startsWith(boundaryKey!)) {
            boundaryKey = null;
            receivedResult.sendPort.send(true);
          }
        }
      });

      final _MockedIncrementalCompiler generator =
          new _MockedIncrementalCompiler();
      final _MockedBinaryPrinterFactory printerFactory =
          new _MockedBinaryPrinterFactory();
      Future<int> result = starter(
        args,
        compiler: null,
        input: inputStreamController.stream,
        output: ioSink,
        generator: generator,
        binaryPrinterFactory: printerFactory,
      );

      final File source = new File('${tempDir.path}/file1.dart');
      inputStreamController.add('compile ${source.path}\n'.codeUnits);
      await receivedResult.first;
      inputStreamController.add('accept\n'.codeUnits);
      receivedResult = new ReceivePort();
      inputStreamController
          .add('recompile def\n${source.path}\ndef\n'.codeUnits);
      await receivedResult.first;

      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      await inputStreamController.close();
    });

    group('compile with output path', () {
      void verify(String entryPoint, ArgResults opts) {
        expect(opts['sdk-root'], equals('sdkroot'));
      }

      final _MockedCompiler compiler =
          new _MockedCompiler(verifyCompile: verify);
      test('compile from command line', () async {
        final List<String> args = <String>[
          'server.dart',
          '--sdk-root',
          'sdkroot',
          '--output-dill',
          '/foo/bar/server.dart.dill',
          '--output-incremental-dill',
          '/foo/bar/server.incremental.dart.dill',
        ];
        expect(await starter(args, compiler: compiler), 0);
      });
    });
  });

  group('full compiler tests', () {
    final Uri platformKernel =
        computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
    final Uri ddcPlatformKernel =
        computePlatformBinariesLocation().resolve('ddc_outline.dill');
    final Uri ddcPlatformKernelWeak =
        computePlatformBinariesLocation().resolve('ddc_outline_unsound.dill');
    final Uri sdkRoot = computePlatformBinariesLocation();

    late Directory tempDir;
    setUp(() {
      Directory systemTempDir = Directory.systemTemp;
      tempDir = systemTempDir.createTempSync('frontendServerTest');
      new Directory('${tempDir.path}/.dart_tool').createSync();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('compile expression', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n}\n");
      File dillFile = new File('${tempDir.path}/app.dill');

      File packageConfig =
          new File('${tempDir.path}/.dart_tool/package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=${packageConfig.path}',
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(result.errorsCount, equals(0));
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();
          frontendServer.compileExpression('2+2', file.uri, isStatic: null);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, equals(0));
          // Previous request should have failed because isStatic was blank
          expect(compiledResult.status, isNull);

          frontendServer.compileExpression('2+2', file.uri, isStatic: false);
          count += 1;
        } else if (count == 2) {
          expect(result.errorsCount, equals(0));
          // Second request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          frontendServer.compile('foo.bar');
          count += 1;
        } else {
          expect(count, 3);
          // Third request is to 'compile' nonexistent file, that should fail.
          expect(result.errorsCount, greaterThan(0));

          frontendServer.quit();
        }
      });

      expect(await result, 0);
      expect(count, 3);
      frontendServer.close();
    });

    test('compile expression extension types', skip: !useJsonForCommunication,
        () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      String data = r"""
//@dart=3.3
void main() {
  Foo f = new Foo(42);
  print(f);
  print(f.value);
  f.printValue();
  f.printThis();
}
extension type Foo(int value) {
  void printValue() {
    print("This foos value is '$value'");
  }
  void printThis() {
    print("This foos this value is '$this'");
  }
}""";
      file.writeAsStringSync(data);
      File dillFile = new File('${tempDir.path}/app.dill');

      File packageConfig =
          new File('${tempDir.path}/.dart_tool/package_config.json')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
      Uri fileImportUri = Uri.parse("package:hello/foo.dart");

      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=${packageConfig.path}',
      ];

      final FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(result.errorsCount, equals(0));
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();

          frontendServer.compileExpression('f.value', fileImportUri,
              // actually file.uri but check we accept this too.
              scriptUri: fileImportUri,
              definitions: ["f"],
              // int.
              definitionTypes: ["dart:core", "int", "1", "0"],
              methodName: "main",
              offset: 63,
              isStatic: true);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, equals(0));
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          frontendServer.compileExpression('this.value', fileImportUri,
              scriptUri: file.uri,
              definitions: ["#this"],
              // int.
              definitionTypes: ["dart:core", "int", "1", "0"],
              methodName: "Foo.printValue",
              offset: 174,
              isStatic: true);
          count += 1;
        } else if (count == 2) {
          expect(result.errorsCount, equals(0));
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          frontendServer.quit();
        }
      });

      expect(await result, 0);
      expect(count, 2);
      frontendServer.close();
    });

    group('compile expression extension types to JavaScript', () {
      // TODO(jensj): This is the javascript version of the above.
      // It should share code.
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        String data = r"""
//@dart=3.3
void main() {
  Foo f = new Foo(42);
  print(f);
  print(f.value);
  f.printValue();
  f.printThis();
}
extension type Foo(int value) {
  void printValue() {
    print("This foos value is '$value'");
  }
  void printThis() {
    print("This foos this value is '$this'");
  }
}""";
        file.writeAsStringSync(data);

        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/foo.dart.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');

        expect(dillFile.existsSync(), equals(false));
        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];

        final FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(file.path);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          if (count == 0) {
            // First request is to 'compile', which results in full JavaScript
            expect(result.errorsCount, equals(0));
            expect(sourceFile.existsSync(), equals(true));
            expect(manifestFile.existsSync(), equals(true));
            expect(sourceMapsFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            frontendServer.accept();

            frontendServer.compileExpressionToJs(
                expression: 'f.value',
                libraryUri: library,
                line: 5,
                column: 3,
                scriptUri: file.uri,
                jsFrameValues: {"f": "42"});
            count += 1;
          } else if (count == 1) {
            expect(result.errorsCount, equals(0));
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.compileExpressionToJs(
                expression: 'this.value',
                libraryUri: library,
                line: 11,
                column: 5,
                scriptUri: file.uri,
                jsFrameValues: {r"$this": "42"});
            count += 1;
          } else if (count == 2) {
            expect(result.errorsCount, equals(0));
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.quit();
          }
        });

        expect(await result, 0);
        expect(count, 2);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    }, skip: !useJsonForCommunication);

    test('mixed compile expression commands with non-web target', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      String library = 'package:hello/foo.dart';

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(result.errorsCount, equals(0));
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();

          frontendServer.compileExpression('2+2', file.uri, isStatic: false);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, equals(0));
          // Second request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          frontendServer.compileExpressionToJs(
              expression: '', libraryUri: library, line: 1, column: 1);
          count += 1;
        } else if (count == 2) {
          // Third request is to 'compile-expression-to-js' that fails
          // due to non-web target
          expect(result.errorsCount, equals(0));
          expect(compiledResult.status, isNull);

          frontendServer.compileExpression('2+2', file.uri, isStatic: false);
          count += 1;
        } else if (count == 3) {
          expect(result.errorsCount, equals(0));
          // Fourth request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          frontendServer.quit();
        }
      });

      expect(await result, 0);
      expect(count, 3);
      frontendServer.close();
    });

    test('compiler reports correct sources added', () async {
      File libFile = new File('${tempDir.path}/lib.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("var foo = 42;");
      File mainFile = new File('${tempDir.path}/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("main() => print('foo');\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      final Future<int> result = frontendServer.open(args);
      frontendServer.compile(mainFile.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        compiledResult.expectNoErrors();
        if (count == 0) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('+${mainFile.uri}'));

          frontendServer.accept();
          mainFile
              .writeAsStringSync("import 'lib.dart';  main() => print(foo);\n");
          frontendServer.recompile(mainFile.uri, entryPoint: mainFile.path);
          count += 1;
        } else if (count == 1) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('+${libFile.uri}'));
          frontendServer.accept();
          frontendServer.quit();
        }
      });

      expect(await result, 0);
      frontendServer.close();
    }, timeout: new Timeout.factor(100));

    test('compiler reports correct sources removed', () async {
      File libFile = new File('${tempDir.path}/lib.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("var foo = 42;");
      File mainFile = new File('${tempDir.path}/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("import 'lib.dart'; main() => print(foo);\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      final Future<int> result = frontendServer.open(args);
      frontendServer.compile(mainFile.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        compiledResult.expectNoErrors();
        if (count == 0) {
          expect(compiledResult.sources.length, equals(2));
          expect(compiledResult.sources,
              allOf(contains('+${mainFile.uri}'), contains('+${libFile.uri}')));

          frontendServer.accept();
          mainFile.writeAsStringSync("main() => print('foo');\n");
          frontendServer.recompile(mainFile.uri, entryPoint: mainFile.path);
          count += 1;
        } else if (count == 1) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('-${libFile.uri}'));
          frontendServer.accept();
          frontendServer.quit();
        }
      });

      expect(await result, 0);
      frontendServer.close();
    }, timeout: new Timeout.factor(100));

    test('compile expression when delta is rejected', () async {
      File fileLib = new File('${tempDir.path}/lib.dart')..createSync();
      fileLib.writeAsStringSync("foo() => 42;\n");
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'lib.dart'; main1() => print(foo);\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      final Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request was to 'compile', which resulted in full kernel file.
          expect(result.errorsCount, 0);
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();

          frontendServer.compileExpression('main1', file.uri, isStatic: true);
          count += 1;
        } else if (count == 1) {
          // Second request was to 'compile-expression', which resulted in
          // kernel file with a function that wraps compiled expression.
          expect(result.errorsCount, 0);
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          file.writeAsStringSync("import 'lib.dart'; main() => foo();\n");
          frontendServer.recompile(file.uri, entryPoint: file.path);

          count += 1;
        } else if (count == 2) {
          // Third request was to recompile the script after renaming a
          // function.
          expect(result.errorsCount, 0);
          frontendServer.reject();
          count += 1;
        } else if (count == 3) {
          // Fourth request was to reject the compilation results.
          frontendServer.compileExpression('main1', file.uri, isStatic: true);
          count += 1;
        } else {
          expect(count, 4);
          // Fifth request was to 'compile-expression' that references original
          // function, which should still be successful.
          expect(result.errorsCount, 0);
          frontendServer.quit();
        }
      });

      expect(await result, 0);
      frontendServer.close();
    }, timeout: new Timeout.factor(100));

    test('reject - recreate issue 55357', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync(
          "extension on String { int get fooValue => 42; }\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      final Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request was to 'compile', which resulted in full kernel file.
          expect(result.errorsCount, 0);
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();
          frontendServer.recompile(file.uri, entryPoint: file.path);
          count += 1;
        } else if (count == 1) {
          // Second request was to recompile after an accept.
          expect(result.errorsCount, 0);
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);
          frontendServer.reject();
          count += 1;
        } else if (count == 2) {
          // Third request was to reject. Now ask to compile again.
          frontendServer.recompile(file.uri, entryPoint: file.path);
          count += 1;
        } else if (count == 3) {
          // Fourth request was to recompile the script after a reject.
          expect(result.errorsCount, 0);
          expect(result.errorsCount, 0);
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);
          frontendServer.quit();
        }
      });

      expect(await result, 0);
      frontendServer.close();
    }, timeout: new Timeout.factor(100));

    test('recompile request keeps incremental output dill filename', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(dillFile.existsSync(), equals(true));
          compiledResult.expectNoErrors(filename: dillFile.path);
          count += 1;
          frontendServer.accept();
          File file2 = new File('${tempDir.path}/bar.dart')..createSync();
          file2.writeAsStringSync("main() {}\n");
          frontendServer.recompile(file2.uri, entryPoint: file2.path);
        } else {
          expect(count, 1);
          // Second request is to 'recompile', which results in incremental
          // kernel file.
          File dillIncFile = new File('${dillFile.path}.incremental.dill');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          frontendServer.accept();
          frontendServer.quit();
        }
      });
      expect(await result, 0);
      frontendServer.close();
    });

    test('unsafe-package-serialization', () async {
      // Package A.
      File file = new File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      // Package B.
      file = new File('${tempDir.path}/pkgB/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgB_a() {}");
      file = new File('${tempDir.path}/pkgB/b.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgA/a.dart';"
          "pkgB_b() { pkgA(); }");

      // Application.
      new File('${tempDir.path}/app/.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "pkgA",
        "rootUri": "${tempDir.uri.resolve('pkgA')}",
        "packageUri": "./"
      },
      {
        "name": "pkgB",
        "rootUri": "${tempDir.uri.resolve('pkgB')}",
        "packageUri": "./"
      }
    ]
  }
''');
      // Entry point A uses both package A and B.
      file = new File('${tempDir.path}/app/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgB/b.dart';"
          "import 'package:pkgB/a.dart';"
          "appA() { pkgB_a(); pkgB_b(); }");

      // Entry point B uses only package B.
      File fileB = new File('${tempDir.path}/app/B.dart')
        ..createSync(recursive: true);
      fileB.writeAsStringSync("import 'package:pkgB/a.dart';"
          "appB() { pkgB_a(); }");

      // Other setup.
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      // First compile app entry point A.
      final String targetName = 'vm';
      final Target target = createFrontEndTarget(targetName)!;
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--unsafe-package-serialization',
        '--no-incremental-serialization',
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            count += 1;
            frontendServer.accept();
            frontendServer.reset();

            frontendServer.recompile(fileB.uri, entryPoint: fileB.path);
            break;
          case 1:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            frontendServer.accept();
            frontendServer.quit();

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contains (at least) the 2 files we want.
            expect(
                component.libraries
                    .where((l) =>
                        l.importUri.toString() == "package:pkgB/a.dart" ||
                        l.fileUri == fileB.uri)
                    .length,
                2);

            // Verifiable (together with the platform file).
            component =
                loadComponentFromBinary(platformKernel.toFilePath(), component);
            verifyComponent(target,
                VerificationStage.afterModularTransformations, component);
        }
      });
      expect(await result, 0);
      frontendServer.close();
    });

    test('incremental-serialization', () async {
      // Package A.
      File file = new File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      // Package B.
      file = new File('${tempDir.path}/pkgB/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgB_a() {}");
      file = new File('${tempDir.path}/pkgB/b.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgA/a.dart';"
          "pkgB_b() { pkgA(); }");

      // Application.
      new File('${tempDir.path}/app/.dart_tool/package_config.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "pkgA",
        "rootUri": "${tempDir.uri.resolve('pkgA')}",
        "packageUri": "./"
      },
      {
        "name": "pkgB",
        "rootUri": "${tempDir.uri.resolve('pkgB')}",
        "packageUri": "./"
      }
    ]
  }
''');
      file = new File('${tempDir.path}/app/.dart_tool/package_config.json')
        ..createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({
        "configVersion": 2,
        "packages": [
          {
            "name": "pkgA",
            "rootUri": "../../pkgA",
          },
          {
            "name": "pkgB",
            "rootUri": "../../pkgB",
          },
        ],
      }));

      // Entry point A uses both package A and B.
      file = new File('${tempDir.path}/app/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgB/b.dart';"
          "import 'package:pkgB/a.dart';"
          "appA() { pkgB_a(); pkgB_b(); }");

      // Entry point B uses only package B.
      File fileB = new File('${tempDir.path}/app/B.dart')
        ..createSync(recursive: true);
      fileB.writeAsStringSync("import 'package:pkgB/a.dart';"
          "appB() { pkgB_a(); }");

      // Other setup.
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      // First compile app entry point A.
      final String targetName = 'vm';
      final Target target = createFrontEndTarget(targetName)!;
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--incremental-serialization',
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            count += 1;
            frontendServer.accept();
            frontendServer.reset();

            frontendServer.recompile(fileB.uri, entryPoint: fileB.path);
            break;
          case 1:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            frontendServer.accept();
            frontendServer.quit();

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contains (at least) the 2 files we want.
            expect(
                component.libraries
                    .where((l) =>
                        l.importUri.toString() == "package:pkgB/a.dart" ||
                        l.fileUri == fileB.uri)
                    .length,
                2);

            // Verifiable (together with the platform file).
            component =
                loadComponentFromBinary(platformKernel.toFilePath(), component);
            verifyComponent(target,
                VerificationStage.afterModularTransformations, component);
        }
      });
      expect(await result, 0);
      frontendServer.close();
    });

    test('incremental-serialization with reject', () async {
      // Basically a reproduction of
      // https://github.com/flutter/flutter/issues/44384.
      File file =
          new File('${tempDir.path}/pkgA/.dart_tool/package_config.json')
            ..createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({
        "configVersion": 2,
        "packages": [
          {
            "name": "pkgA",
            "rootUri": "..",
          },
        ],
      }));
      file = new File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--incremental-serialization',
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.path);
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            Iterable<Library> libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 1 procedure.
            expect(libs.first.procedures.length, 1);

            file.writeAsStringSync("pkgA() {} pkgA_2() {}");

            count += 1;
            frontendServer.reject();
            break;
          case 1:
            count += 1;
            frontendServer.reset();
            frontendServer.recompile(file.uri, entryPoint: file.path);
            break;
          case 2:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            Iterable<Library> libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 2 procedure.
            expect(libs.first.procedures.length, 2);

            file.writeAsStringSync("pkgA() {} pkgA_2() {} pkgA_3() {}");

            count += 1;
            frontendServer.accept();
            frontendServer.reset();
            frontendServer.recompile(file.uri, entryPoint: file.path);
            break;
          case 3:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            frontendServer.accept();
            frontendServer.quit();

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            Iterable<Library> libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 3 procedures.
            expect(libs.first.procedures.length, 3);
        }
      });
      expect(await result, 0);
      frontendServer.close();
    });

    test('compile and recompile report non-zero error count', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() { foo(); bar(); }\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(file.uri.toString());
      int count = 0;
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 2);
            count += 1;
            frontendServer.accept();
            File file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { baz(); }\n");
            frontendServer.recompile(file2.uri,
                entryPoint: file2.uri.toString());
            break;
          case 1:
            File dillIncFile = new File('${dillFile.path}.incremental.dill');
            expect(result.filename, dillIncFile.path);
            expect(result.errorsCount, 1);
            count += 1;
            frontendServer.accept();
            File file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { }\n");
            frontendServer.recompile(file2.uri,
                entryPoint: file2.uri.toString());
            break;
          case 2:
            File dillIncFile = new File('${dillFile.path}.incremental.dill');
            expect(result.filename, dillIncFile.path);
            expect(result.errorsCount, 0);
            expect(dillIncFile.existsSync(), equals(true));
            frontendServer.quit();
        }
      });
      expect(await result, 0);
      frontendServer.close();
    });

    test('compile and recompile with MultiRootFileSystem', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      new File('${tempDir.path}/.dart_tool/package_config.json')
        ..createSync()
        ..writeAsStringSync('{"configVersion": 2, "packages": []}');
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=test-scheme:///.dart_tool/package_config.json',
        '--filesystem-root=${tempDir.path}',
        '--filesystem-scheme=test-scheme',
        'test-scheme:///foo.dart'
      ];
      expect(await starter(args), 0);
    });

    test('compile multiple sources', () async {
      final File src1 = new File('${tempDir.path}/src1.dart')
        ..createSync()
        ..writeAsStringSync("main() {}\n");
      final File src2 = new File('${tempDir.path}/src2.dart')
        ..createSync()
        ..writeAsStringSync("entryPoint2() {}\n");
      final File src3 = new File('${tempDir.path}/src3.dart')
        ..createSync()
        ..writeAsStringSync("entryPoint3() {}\n");
      final File packagesFile =
          new File('${tempDir.path}/.dart_tool/package_config.json')
            ..createSync()
            ..writeAsStringSync('{"configVersion": 2, "packages": []}');
      final File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--packages=${packagesFile.path}',
        '--source=${src2.path}',
        '--source=${src3.path}',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      FrontendServer frontendServer = new FrontendServer();
      Future<int> result = frontendServer.open(args);
      frontendServer.compile(src1.uri.toString());
      frontendServer.listen((Result compiledResult) {
        CompilationResult result =
            new CompilationResult.parse(compiledResult.status);
        expect(dillFile.existsSync(), equals(true));
        expect(result.filename, dillFile.path);
        expect(result.errorsCount, 0);

        final Component component = loadComponentFromBinary(dillFile.path);
        // Contains (at least) the 3 files we want.
        final Set<Uri> srcUris = {src1.uri, src2.uri, src3.uri};
        expect(
            component.libraries
                .where((lib) => srcUris.contains(lib.fileUri))
                .length,
            srcUris.length);
        frontendServer.quit();
      });
      expect(await result, 0);
      frontendServer.close();
    });

    group('http uris', () {
      String host = 'localhost';
      late File dillFile;
      late int port;
      late HttpServer server;

      setUp(() async {
        dillFile = new File('${tempDir.path}/app.dill');
        server = await HttpServer.bind(host, 0);
        port = server.port;
        server.listen((request) {
          String path = request.uri.path;
          File file = new File('${tempDir.path}$path');
          HttpResponse response = request.response;
          if (!file.existsSync()) {
            response.statusCode = 404;
          } else {
            response.statusCode = 200;
            response.add(file.readAsBytesSync());
          }
          response.close();
        });
        File main = new File('${tempDir.path}/foo.dart')..createSync();
        main.writeAsStringSync(
            "import 'package:foo/foo.dart'; main() {print(foo);}\n");
        new File('${tempDir.path}/.dart_tool/package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "foo",
        "rootUri": "http://$host:$port/packages/foo",
        "packageUri": "./"
      }
    ]
  }
''');
        new File('${tempDir.path}/packages/foo/foo.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync("var foo = 'hello';");
      });

      tearDown(() async {
        await server.close();
        print('closed');
      });

      test('compile with http uris', () async {
        expect(dillFile.existsSync(), equals(false));
        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${platformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--enable-http-uris',
          '--packages=http://$host:$port/.dart_tool/package_config.json',
          'http://$host:$port/foo.dart',
        ];
        expect(await starter(args), 0);
        expect(dillFile.existsSync(), equals(true));
      });

      test('compile with an http file system root', () async {
        expect(dillFile.existsSync(), equals(false));
        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${platformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--enable-http-uris',
          '--packages=test-app:///.dart_tool/package_config.json',
          '--filesystem-root=http://$host:$port/',
          '--filesystem-scheme=test-app',
          'test-app:///foo.dart',
        ];
        expect(await starter(args), 0);
        expect(dillFile.existsSync(), equals(true));
      });
    });

    group('binary protocol', () {
      Map<Uri, String> fileContentMap = <Uri, String>{};

      setUp(() {
        fileContentMap = {};
      });

      void addFileCallbacks(RequestChannel requestChannel) {
        requestChannel.add('file.exists', (uriStr) async {
          final Uri uri = Uri.parse(uriStr as String);
          return fileContentMap.containsKey(uri);
        });
        requestChannel.add('file.readAsBytes', (uriStr) async {
          final Uri uri = Uri.parse(uriStr as String);
          final String? content = fileContentMap[uri];
          return content != null ? utf8.encode(content) : new Uint8List(0);
        });
        requestChannel.add('file.readAsStringSync', (uriStr) async {
          final Uri uri = Uri.parse(uriStr as String);
          return fileContentMap[uri] ?? '';
        });
      }

      Future<ServerSocket> loopbackServerSocket() async {
        try {
          return await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
        } on SocketException catch (_) {
          return await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        }
      }

      Uri registerKernelBlob(Uint8List bytes) {
        bytes = new Uint8List.fromList(bytes);
        return (Isolate.current as dynamic).createUriForKernelBlob(bytes);
      }

      Future<void> runWithServer(
        Future<void> Function(RequestChannel) f,
      ) async {
        final Completer<void> testFinished = new Completer<void>();
        final ServerSocket serverSocket = await loopbackServerSocket();

        serverSocket.listen((socket) async {
          final RequestChannel requestChannel = new RequestChannel(socket);

          try {
            await f(requestChannel);
          } finally {
            unawaited(requestChannel.sendRequest('stop', {}));
            socket.destroy();
            await serverSocket.close();
            testFinished.complete();
          }
        });

        final String host = serverSocket.address.address;
        final String addressStr = '$host:${serverSocket.port}';
        expect(await starter(['--binary-protocol-address=$addressStr']), 0);

        await testFinished.future;
      }

      group('dill.put', () {
        test('not Map argument', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('dill.put', 42);
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('no field: uri', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('dill.put', {});
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('no field: bytes', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('dill.put', {
                'uri': 'vm:dill',
              });
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('OK', () async {
          await runWithServer((requestChannel) async {
            await requestChannel.sendRequest<Uint8List?>('dill.put', {
              'uri': 'vm:dill',
              'bytes': new Uint8List(256),
            });
          });
        });
      });

      group('dill.remove', () {
        test('not Map argument', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('dill.remove', 42);
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('no field: uri', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('dill.remove', {});
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('OK', () async {
          await runWithServer((requestChannel) async {
            await requestChannel.sendRequest<Uint8List?>('dill.remove', {
              'uri': 'vm:dill',
            });
          });
        });
      });

      group('kernelForProgram', () {
        test('not Map argument', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>(
                'kernelForProgram',
                42,
              );
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('no field: sdkSummary', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>(
                'kernelForProgram',
                {},
              );
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('no field: uri', () async {
          await runWithServer((requestChannel) async {
            try {
              await requestChannel.sendRequest<Uint8List>('kernelForProgram', {
                'sdkSummary': 'dill:vm',
              });
              fail('Expected RequestChannelException');
            } on RequestChannelException {}
          });
        });

        test('compiles', () async {
          await runWithServer((requestChannel) async {
            addFileCallbacks(requestChannel);

            await requestChannel.sendRequest<void>('dill.put', {
              'uri': 'dill:vm',
              'bytes': new File(
                path.join(
                  path.dirname(path.dirname(Platform.resolvedExecutable)),
                  'lib',
                  '_internal',
                  'vm_platform_strong.dill',
                ),
              ).readAsBytesSync(),
            });

            fileContentMap[Uri.parse('file:///home/test/lib/test.dart')] = r'''
import 'dart:isolate';
void main(List<String> arguments, SendPort sendPort) {
  sendPort.send(42);
}
''';

            final Uint8List kernelBytes =
                await requestChannel.sendRequest<Uint8List>(
              'kernelForProgram',
              {
                'sdkSummary': 'dill:vm',
                'uri': 'file:///home/test/lib/test.dart',
              },
            );

            expect(kernelBytes, hasLength(greaterThan(200)));
            final Uri kernelUri = registerKernelBlob(kernelBytes);

            final ReceivePort receivePort = new ReceivePort();
            await Isolate.spawnUri(kernelUri, [], receivePort.sendPort);
            expect(await receivePort.first, 42);
          });
        });
      });
    });

    group('compile to JavaScript', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
        File dillFile = new File('${tempDir.path}/app.dill');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--packages=${packageConfig.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          file.path,
        ];

        expect(await starter(args), 0);

        expect(dillFile.existsSync(), true);
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('compile to JavaScript with canary features enabled', () {
      Future<void> runTests({required String moduleFormat}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
        File dillFile = new File('${tempDir.path}/app.dill');
        File sourcesFile = new File('${tempDir.path}/app.dill.sources');

        expect(dillFile.existsSync(), false);
        expect(sourcesFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--packages=${packageConfig.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          '--dartdevc-canary',
          file.path,
        ];

        expect(await starter(args), 0);

        expect(dillFile.existsSync(), true);
        expect(sourcesFile.existsSync(), true);
        String ddcFlags = utf8
            .decode(sourcesFile.readAsBytesSync())
            .split('\n')
            .singleWhere((l) => l.startsWith('// Flags: '));
        expect(ddcFlags, contains('canary'));
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format', () async {
        await runTests(moduleFormat: 'ddc');
      });
    });

    group('compile to JavaScript with package scheme', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packages =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync()
              ..writeAsStringSync(jsonEncode({
                "configVersion": 2,
                "packages": [
                  {
                    "name": "hello",
                    "rootUri": "${tempDir.uri}",
                  },
                ],
              }));
        File dillFile = new File('${tempDir.path}/app.dill');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernelWeak.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packages.path}',
          'package:hello/foo.dart'
        ];

        expect(await starter(args), 0);
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    group('compile to JavaScript weak null safety', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packages =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync()
              ..writeAsStringSync(jsonEncode({
                "configVersion": 2,
                "packages": [
                  {
                    "name": "hello",
                    "rootUri": "${tempDir.uri}",
                  },
                ],
              }));
        File dillFile = new File('${tempDir.path}/app.dill');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernelWeak.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packages.path}',
          'package:hello/foo.dart'
        ];

        expect(await starter(args), 0);
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    group('compile to JavaScript weak null safety then nonexistent file', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packages =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync()
              ..writeAsStringSync(jsonEncode({
                "configVersion": 2,
                "packages": [
                  {
                    "name": "hello",
                    "rootUri": "${tempDir.uri}",
                  },
                ],
              }));
        File dillFile = new File('${tempDir.path}/app.dill');

        expect(dillFile.existsSync(), false);

        String library = 'package:hello/foo.dart';

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernelWeak.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packages.path}',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          count++;
          if (count == 1) {
            // First request is to 'compile', which results in full JavaScript
            expect(result.errorsCount, equals(0));
            expect(result.filename, dillFile.path);
            frontendServer.accept();
            frontendServer.compile('foo.bar');
          } else {
            expect(count, 2);
            // Second request is to 'compile' nonexistent file, that should
            // fail.
            expect(result.errorsCount, greaterThan(0));
            frontendServer.quit();
          }
        });

        expect(await result, 0);
        expect(count, 2);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    group('compile to JavaScript with no metadata', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n\n}\n");

        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/app.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');
        File metadataFile = new File('${dillFile.path}.metadata');

        expect(dillFile.existsSync(), false);
        expect(sourceFile.existsSync(), false);
        expect(manifestFile.existsSync(), false);
        expect(sourceMapsFile.existsSync(), false);
        expect(metadataFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          count++;
          // Request to 'compile', which results in full JavaScript and no
          // metadata.
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(manifestFile.existsSync(), equals(true));
          expect(sourceMapsFile.existsSync(), equals(true));
          expect(metadataFile.existsSync(), equals(false));
          expect(result.filename, dillFile.path);
          frontendServer.accept();
          frontendServer.quit();
        });

        expect(await result, 0);
        expect(count, 1);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('compile to JavaScript with metadata', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n\n}\n");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/app.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');
        File metadataFile = new File('${dillFile.path}.metadata');
        File symbolsFile = new File('${dillFile.path}.symbols');

        expect(dillFile.existsSync(), false);
        expect(sourceFile.existsSync(), false);
        expect(manifestFile.existsSync(), false);
        expect(sourceMapsFile.existsSync(), false);
        expect(metadataFile.existsSync(), false);
        expect(symbolsFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
          '--experimental-emit-debug-metadata',
          '--emit-debug-symbols',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          count++;
          // Request to 'compile', which results in full JavaScript and
          // metadata.
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(manifestFile.existsSync(), equals(true));
          expect(sourceMapsFile.existsSync(), equals(true));
          expect(metadataFile.existsSync(), equals(true));
          expect(symbolsFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          frontendServer.accept();
          frontendServer.quit();
        });

        expect(await result, 0);
        expect(count, 1);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    // This test exercises what happens when a change occurs with a single
    // module of a multi-module compilation.
    group('recompile to JavaScript with in-body change', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        // Five libraries, a to e, in two modules, {a, b} and {c, d, e}:
        //    (a <-> b) -> (c <-> d <-> e)
        // In body changes are performed on d and e. With advanced invalidation,
        // not currently enabled, only the module {c, d, e} will be recompiled.
        new File('${tempDir.path}/a.dart')
          ..createSync()
          ..writeAsStringSync("""
import 'b.dart';
main() {
  b();
}
a() => "<<a>>";
""");
        new File('${tempDir.path}/b.dart')
          ..createSync()
          ..writeAsStringSync("""
import 'a.dart';
import 'c.dart';
b() {
  a();
  "<<b>>";
  c();
}
""");
        new File('${tempDir.path}/c.dart')
          ..createSync()
          ..writeAsStringSync("""
import 'd.dart';
c() {
  "<<c>>";
  d();
}
""");
        File fileD = new File('${tempDir.path}/d.dart')
          ..createSync()
          ..writeAsStringSync("""
import 'e.dart';
d() {
  "<<d>>";
  e();
}
""");
        File fileE = new File('${tempDir.path}/e.dart')
          ..createSync()
          ..writeAsStringSync("""
import 'c.dart';
e() {
  c();
  "<<e>>";
}
""");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "a",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

        String entryPoint = 'package:a/a.dart';

        File dillFile = new File('${tempDir.path}/app.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');
        File metadataFile = new File('${dillFile.path}.metadata');
        File symbolsFile = new File('${dillFile.path}.symbols');

        expect(dillFile.existsSync(), false);
        expect(sourceFile.existsSync(), false);
        expect(manifestFile.existsSync(), false);
        expect(sourceMapsFile.existsSync(), false);
        expect(metadataFile.existsSync(), false);
        expect(symbolsFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
          '--emit-debug-symbols',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(entryPoint);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          switch (count) {
            case 0:
              CompilationResult result =
                  new CompilationResult.parse(compiledResult.status);
              expect(result.errorsCount, equals(0));
              expect(result.filename, dillFile.path);
              expect(sourceFile.existsSync(), equals(true));

              String source = sourceFile.readAsStringSync();
              // Split on the comment at the end of each module.
              List<String> jsModules =
                  source.split(new RegExp("//# sourceMappingURL=.*.map"));

              expect(jsModules[0], contains('<<a>>'));
              expect(jsModules[0], contains('<<b>>'));
              expect(jsModules[0], not(contains('<<c>>')));
              expect(jsModules[0], not(contains('<<d>>')));
              expect(jsModules[0], not(contains('<<e>>')));

              expect(jsModules[1], not(contains('<<a>>')));
              expect(jsModules[1], not(contains('<<b>>')));
              expect(jsModules[1], contains('<<c>>'));
              expect(jsModules[1], contains('<<d>>'));
              expect(jsModules[1], contains('<<e>>'));

              frontendServer.accept();

              fileD.writeAsStringSync("""
import 'e.dart';
d() {
  "<<d1>>";
  "<<d2>>";
  e();
}
""");
              // Trigger a recompile that invalidates 'd.dart'. The entry point
              // uri (a.dart) is passed explicitly.
              frontendServer.recompile(fileD.uri, entryPoint: entryPoint);
              break;
            case 1:
              CompilationResult result =
                  new CompilationResult.parse(compiledResult.status);
              expect(result.errorsCount, equals(0));
              expect(result.filename, '${dillFile.path}.incremental.dill');
              File incrementalSourceFile =
                  new File('${dillFile.path}.incremental.dill.sources');
              expect(incrementalSourceFile.existsSync(), equals(true));

              String source = incrementalSourceFile.readAsStringSync();
              // Split on the comment at the end of each module.
              List<String> jsModules =
                  source.split(new RegExp("//# sourceMappingURL=.*.map"));

              expect(jsModules[0], not(contains('<<a>>')));
              expect(jsModules[0], not(contains('<<b>>')));
              expect(jsModules[0], contains('<<c>>'));
              expect(jsModules[0], not(contains('<<d>>')));
              expect(jsModules[0], contains('<<d1>>'));
              expect(jsModules[0], contains('<<d2>>'));
              expect(jsModules[0], contains('<<e>>'));

              frontendServer.accept();

              fileE.writeAsStringSync("""
import 'c.dart';
e() {
  c();
  "<<e1>>";
  "<<e2>>";
}
""");
              // Trigger a recompile that invalidates 'd.dart'. The entry point
              // uri (a.dart) is omitted.
              frontendServer.recompile(fileE.uri);
              break;
            case 2:
              CompilationResult result =
                  new CompilationResult.parse(compiledResult.status);
              expect(result.errorsCount, equals(0));
              expect(result.filename, '${dillFile.path}.incremental.dill');
              File incrementalSourceFile =
                  new File('${dillFile.path}.incremental.dill.sources');
              expect(incrementalSourceFile.existsSync(), equals(true));

              String source = incrementalSourceFile.readAsStringSync();
              // Split on the comment at the end of each module.
              List<String> jsModules =
                  source.split(new RegExp("//# sourceMappingURL=.*.map"));

              expect(jsModules[0], not(contains('<<a>>')));
              expect(jsModules[0], not(contains('<<b>>')));
              expect(jsModules[0], contains('<<c>>'));
              expect(jsModules[0], not(contains('<<d>>')));
              expect(jsModules[0], contains('<<d1>>'));
              expect(jsModules[0], contains('<<d2>>'));
              expect(jsModules[0], not(contains('<<e>>')));
              expect(jsModules[0], contains('<<e1>>'));
              expect(jsModules[0], contains('<<e2>>'));

              frontendServer.accept();
              frontendServer.quit();
              break;
            default:
              break;
          }
          count++;
        });

        expect(await result, 0);
        expect(count, 3);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('compile to JavaScript all modules with unsound null safety', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("import 'bar.dart'; "
            "typedef myType = void Function(int); main() { fn is myType; }\n");
        file = new File('${tempDir.path}/bar.dart')..createSync();
        file.writeAsStringSync("void Function(int) fn = (int i) => null;\n");
        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/app.dill');
        File sourceFile = new File('${dillFile.path}.sources');

        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
    {
      "configVersion": 2,
      "packages": [
        {
          "name": "hello",
          "rootUri": "../",
          "packageUri": "./",
          "languageVersion": "2.9"
        }
      ]
    }
    ''');

        final List<String> args = <String>[
          '--verbose',
          '--no-sound-null-safety',
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernelWeak.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}'
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        Completer<bool> expectationCompleter = new Completer<bool>();
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          count++;
          // Request to 'compile', which results in full JavaScript and no
          // metadata.
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);

          String source = sourceFile.readAsStringSync();
          // Split on the comment at the end of each module.
          List<String> jsModules =
              source.split(new RegExp("//# sourceMappingURL=.*.map"));

          // Both modules should include the unsound null safety check.
          expect(jsModules[0],
              contains('dart._checkModuleNullSafetyMode(false);'));
          expect(jsModules[1],
              contains('dart._checkModuleNullSafetyMode(false);'));
          frontendServer.accept();
          frontendServer.quit();
          expectationCompleter.complete(true);
        });

        await expectationCompleter.future;
        expect(await result, 0);
        expect(count, 1);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    },
        timeout: Timeout.none,
        skip: 'https://github.com/dart-lang/sdk/issues/52775');

    group('compile to JavaScript, all modules with sound null safety', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync(
            "import 'bar.dart'; typedef myType = void Function(int); "
            "main() { fn is myType; }\n");
        file = new File('${tempDir.path}/bar.dart')..createSync();
        file.writeAsStringSync("void Function(int) fn = (int i) => null;\n");

        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
    {
      "configVersion": 2,
      "packages": [
        {
          "name": "hello",
          "rootUri": "../",
          "packageUri": "./"
        }
      ]
    }
    ''');

        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/app.dill');
        File sourceFile = new File('${dillFile.path}.sources');

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        Completer<bool> expectationCompleter = new Completer<bool>();
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          count++;
          // Request to 'compile', which results in full JavaScript and no
          // metadata.
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);

          String source = sourceFile.readAsStringSync();
          // Split on the comment at the end of each module.
          List<String> jsModules =
              source.split(new RegExp("//# sourceMappingURL=.*.map"));

          // Both modules should include the sound null safety validation.
          expect(
              jsModules[0], contains('dart._checkModuleNullSafetyMode(true);'));
          expect(
              jsModules[1], contains('dart._checkModuleNullSafetyMode(true);'));
          frontendServer.accept();
          frontendServer.quit();
          expectationCompleter.complete(true);
        });

        await expectationCompleter.future;
        expect(await result, 0);
        expect(count, 1);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('compile expression to JavaScript', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n}\n");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/foo.dart.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];
        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          if (count == 0) {
            // First request is to 'compile', which results in full JavaScript
            expect(result.errorsCount, equals(0));
            expect(sourceFile.existsSync(), equals(true));
            expect(manifestFile.existsSync(), equals(true));
            expect(sourceMapsFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            frontendServer.accept();

            frontendServer.compileExpressionToJs(
                expression: '', libraryUri: library, line: 2, column: 1);
            count += 1;
          } else if (count == 1) {
            // Second request is to 'compile-expression-to-js' that fails
            // due to incorrect input - empty expression
            expect(result.errorsCount, 1);
            expect(compiledResult.status, (String status) {
              return status.endsWith(' 1');
            });

            frontendServer.compileExpressionToJs(
                expression: '2+2', libraryUri: library, line: 2, column: 1);
            count += 1;
          } else if (count == 2) {
            expect(result.errorsCount, equals(0));
            // Third request is to 'compile-expression-to-js', which results in
            // js file with a function that wraps compiled expression.
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.compile('foo.bar');
            count += 1;
          } else {
            expect(count, 3);
            // Fourth request is to 'compile' nonexistent file, that should
            // fail.
            expect(result.errorsCount, greaterThan(0));

            frontendServer.quit();
          }
        });

        expect(await result, 0);
        expect(count, 3);
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('compiled JavaScript includes web library environment defines', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync('''
            main() {
              print(const bool.fromEnvironment('dart.library.html'));
            }\n''');
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');

        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/foo.dart.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          if (count == 0) {
            // Request to 'compile', which results in full JavaScript.
            expect(result.errorsCount, equals(0));
            expect(sourceFile.existsSync(), equals(true));
            expect(manifestFile.existsSync(), equals(true));
            expect(sourceMapsFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);

            String compiledOutput = sourceFile.readAsStringSync();
            // The constant environment variable should be inlined as a boolean
            // literal.
            expect(compiledOutput, contains('print(true);'));

            frontendServer.accept();

            frontendServer.compileExpressionToJs(
                expression: 'const bool.fromEnvironment("dart.library.html")',
                libraryUri: library,
                line: 2,
                column: 1);
            count += 1;
          } else {
            expect(count, 1);
            // Second request is to 'compile-expression-to-js' that should
            // result in a literal `true` .
            expect(result.errorsCount, 0);
            File resultFile = new File(result.filename);
            // The constant environment variable should be inlined as a boolean
            // literal.
            expect(resultFile.readAsStringSync(), contains('return true;'));
            count += 1;
            frontendServer.quit();
          }
        });
        expect(await result, 0);
        expect(count, 2);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    group('mixed compile expression commands with web target', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        File file = new File('${tempDir.path}/foo.dart')..createSync();
        file.writeAsStringSync("main() {\n\n}\n");
        File packageConfig =
            new File('${tempDir.path}/.dart_tool/package_config.json')
              ..createSync(recursive: true)
              ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
        String library = 'package:hello/foo.dart';

        File dillFile = new File('${tempDir.path}/foo.dart.dill');
        File sourceFile = new File('${dillFile.path}.sources');
        File manifestFile = new File('${dillFile.path}.json');
        File sourceMapsFile = new File('${dillFile.path}.map');

        expect(dillFile.existsSync(), false);

        final List<String> args = <String>[
          '--sdk-root=${sdkRoot.toFilePath()}',
          '--incremental',
          '--platform=${ddcPlatformKernel.path}',
          '--output-dill=${dillFile.path}',
          '--target=dartdevc',
          '--dartdevc-module-format=$moduleFormat',
          if (canary) '--dartdevc-canary',
          '--packages=${packageConfig.path}',
        ];

        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(library);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          if (count == 0) {
            // First request is to 'compile', which results in full JavaScript
            expect(result.errorsCount, equals(0));
            expect(sourceFile.existsSync(), equals(true));
            expect(manifestFile.existsSync(), equals(true));
            expect(sourceMapsFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            frontendServer.accept();

            frontendServer.compileExpressionToJs(
                expression: '2+2', libraryUri: library, line: 2, column: 1);
            count += 1;
          } else if (count == 1) {
            expect(result.errorsCount, equals(0));
            // Second request is to 'compile-expression-to-js', which results in
            // js file with a function that wraps compiled expression.
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.compileExpression('2+2', file.uri, isStatic: false);
            count += 1;
          } else if (count == 2) {
            expect(result.errorsCount, equals(0));
            // Third request is to 'compile-expression', which results in
            // kernel file with a function that wraps compiled expression.
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.compileExpressionToJs(
                expression: '2+2', libraryUri: library, line: 2, column: 1);
            count += 1;
          } else if (count == 3) {
            expect(result.errorsCount, equals(0));
            // Fourth request is to 'compile-expression-to-js', which results in
            // js file with a function that wraps compiled expression.
            File outputFile = new File(result.filename);
            expect(outputFile.existsSync(), equals(true));
            expect(outputFile.lengthSync(), isPositive);

            frontendServer.quit();
          }
        });

        expect(await result, 0);
        expect(count, 3);
        frontendServer.close();
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });

    test('compile "package:"-file', () async {
      Directory lib = new Directory('${tempDir.path}/lib')..createSync();
      new File('${lib.path}/foo.dart')
        ..createSync()
        ..writeAsStringSync("main() {}\n");
      File packages = new File('${tempDir.path}/.dart_tool/package_config.json')
        ..createSync()
        ..writeAsStringSync(jsonEncode({
          "configVersion": 2,
          "packages": [
            {
              "name": "test",
              "rootUri": "../lib",
            },
          ],
        }));
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      File depFile = new File('${tempDir.path}/the depfile');
      expect(depFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--depfile=${depFile.path}',
        '--packages=${packages.path}',
        'package:test/foo.dart'
      ];
      expect(await starter(args), 0);
      expect(depFile.existsSync(), true);
      String depContents = depFile.readAsStringSync();
      List<String> depContentsParsed = depContents.split(': ');
      expect(path.basename(depContentsParsed[0]), path.basename(dillFile.path));
      expect(depContentsParsed[1], isNotEmpty);
    });

    test('compile and produce deps file', () async {
      File file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      File dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      File depFile = new File('${tempDir.path}/the depfile');
      expect(depFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--depfile=${depFile.path}',
        file.path
      ];
      expect(await starter(args), 0);
      expect(depFile.existsSync(), true);
      String depContents = depFile.readAsStringSync();
      List<String> depContentsParsed = depContents.split(': ');
      expect(path.basename(depContentsParsed[0]), path.basename(dillFile.path));
      expect(depContentsParsed[1], isNotEmpty);
    });

    void checkIsEqual(List<int> a, List<int> b) {
      int length = a.length;
      if (b.length < length) {
        length = b.length;
      }
      for (int i = 0; i < length; ++i) {
        if (a[i] != b[i]) {
          fail("Data differs at byte ${i + 1}.");
        }
      }
      expect(a.length, equals(b.length));
    }

    test('mimic flutter benchmark', () async {
      // This is based on what flutters "hot_mode_dev_cycle__benchmark" does.
      File dillFile = new File('${tempDir.path}/full.dill');
      File incrementalDillFile = new File('${tempDir.path}/incremental.dill');
      expect(dillFile.existsSync(), equals(false));
      final String targetName = 'vm';
      final Target target = createFrontEndTarget(targetName)!;
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--output-incremental-dill=${incrementalDillFile.path}'
      ];
      File dart2js = new File.fromUri(Platform.script
          .resolve("../../../pkg/compiler/lib/src/dart2js.dart"));
      expect(dart2js.existsSync(), equals(true));
      File dart2jsOtherFile = new File.fromUri(Platform.script
          .resolve("../../../pkg/compiler/lib/src/compiler.dart"));
      expect(dart2jsOtherFile.existsSync(), equals(true));

      int libraryCount = -1;
      int sourceCount = -1;

      List<List<int>> compiledKernels = <List<int>>[];
      for (int serverCloses = 0; serverCloses < 2; ++serverCloses) {
        print("Restart #$serverCloses");
        FrontendServer frontendServer = new FrontendServer();
        Future<int> result = frontendServer.open(args);
        frontendServer.compile(dart2js.path);
        int count = 0;
        frontendServer.listen((Result compiledResult) {
          CompilationResult result =
              new CompilationResult.parse(compiledResult.status);
          String outputFilename = result.filename;
          print("$outputFilename -- count $count");

          // Ensure that kernel file produced when compiler was initialized
          // from compiled kernel files matches kernel file produced when
          // compiler was initialized from sources on the first run.
          if (serverCloses == 0) {
            compiledKernels.add(new File(dillFile.path).readAsBytesSync());
          } else {
            checkIsEqual(compiledKernels[count],
                new File(dillFile.path).readAsBytesSync());
          }
          if (count == 0) {
            // First request is to 'compile', which results in full kernel file.
            expect(dillFile.existsSync(), equals(true));
            expect(outputFilename, dillFile.path);

            // Dill file can be loaded and includes data.
            Component component = loadComponentFromBinary(dillFile.path);
            if (serverCloses == 0) {
              libraryCount = component.libraries.length;
              sourceCount = component.uriToSource.length;
              expect(libraryCount > 100, equals(true));
              expect(sourceCount >= libraryCount, equals(true),
                  reason: "Expects >= source entries than libraries.");
            } else {
              expect(component.libraries.length, equals(libraryCount),
                  reason: "Expects the same number of libraries "
                      "when compiling after a restart");
              expect(component.uriToSource.length, equals(sourceCount),
                  reason: "Expects the same number of sources "
                      "when compiling after a restart");
            }

            // Include platform and verify.
            component =
                loadComponentFromBinary(platformKernel.toFilePath(), component);
            expect(component.mainMethod, isNotNull);
            verifyComponent(target,
                VerificationStage.afterModularTransformations, component);

            count += 1;

            // Restart with no changes
            frontendServer.accept();
            frontendServer.reset();
            frontendServer.recompile(null,
                entryPoint: dart2js.path, boundaryKey: 'x$count');
          } else if (count == 1) {
            // Restart. Expect full kernel file.
            expect(dillFile.existsSync(), equals(true));
            expect(outputFilename, dillFile.path);

            // Dill file can be loaded and includes data.
            Component component = loadComponentFromBinary(dillFile.path);
            expect(component.libraries.length, equals(libraryCount),
                reason: "Expect the same number of libraries after a reset.");
            expect(component.uriToSource.length, equals(sourceCount),
                reason: "Expect the same number of sources after a reset.");

            // Include platform and verify.
            component =
                loadComponentFromBinary(platformKernel.toFilePath(), component);
            expect(component.mainMethod, isNotNull);
            verifyComponent(target,
                VerificationStage.afterModularTransformations, component);

            count += 1;

            // Reload with no changes
            frontendServer.accept();
            frontendServer.recompile(null,
                entryPoint: dart2js.path, boundaryKey: 'x$count');
          } else if (count == 2) {
            // Partial file. Expect to be empty.
            expect(incrementalDillFile.existsSync(), equals(true));
            expect(outputFilename, incrementalDillFile.path);

            // Dill file can be loaded and includes no data.
            Component component =
                loadComponentFromBinary(incrementalDillFile.path);
            expect(component.libraries.length, equals(0));

            count += 1;

            // Reload with 1 change
            frontendServer.accept();
            frontendServer.recompile(dart2jsOtherFile.uri,
                entryPoint: dart2js.path, boundaryKey: 'x$count');
          } else if (count == 3) {
            // Partial file. Expect to not be empty.
            expect(incrementalDillFile.existsSync(), equals(true));
            expect(outputFilename, incrementalDillFile.path);

            // Dill file can be loaded and includes some data.
            Component component =
                loadComponentFromBinary(incrementalDillFile.path);
            expect(component.libraries, isNotEmpty);
            expect(component.uriToSource.length >= component.libraries.length,
                equals(true),
                reason: "Expects >= source entries than libraries.");

            count += 1;

            frontendServer.quit();
          }
        });
        expect(await result, 0);
        frontendServer.close();
      }
    }, timeout: new Timeout.factor(8));

    group('compile with(out) warning', () {
      Future<void> runTests(
          {required String moduleFormat, bool canary = false}) async {
        Future runTest({bool hideWarnings = true}) async {
          File file = new File('${tempDir.path}/foo.dart')..createSync();
          file.writeAsStringSync("""
import 'dart:js_interop';
main() {}
@JSExport('Foo')
class Class {
  void method() {}
}
""");
          File packageConfig =
              new File('${tempDir.path}/.dart_tool/package_config.json')
                ..createSync(recursive: true)
                ..writeAsStringSync('''
  {
    "configVersion": 2,
    "packages": [
      {
        "name": "hello",
        "rootUri": "../",
        "packageUri": "./"
      }
    ]
  }
  ''');
          File dillFile = new File('${tempDir.path}/app.dill');

          expect(dillFile.existsSync(), false);

          final List<String> args = <String>[
            '--sdk-root=${sdkRoot.toFilePath()}',
            '--incremental',
            '--platform=${ddcPlatformKernel.path}',
            '--output-dill=${dillFile.path}',
            '--packages=${packageConfig.path}',
            '--target=dartdevc',
            '--dartdevc-module-format=$moduleFormat',
            if (canary) '--dartdevc-canary',
            if (hideWarnings) '--verbosity=error',
            file.path,
          ];
          StringBuffer output = new StringBuffer();
          int exitCode = await starter(args, output: output);
          String result = output.toString();
          expect(exitCode, 0);
          Matcher matcher = contains(
              "Warning: The value in the `@JSExport` annotation on the "
              "class or mixin 'Class' will be ignored.");
          if (hideWarnings) {
            matcher = isNot(matcher);
          }
          expect(result, matcher);

          file.deleteSync();
          dillFile.deleteSync();
        }

        await runTest(hideWarnings: false);
        await runTest(hideWarnings: true);
      }

      test('AMD module format', () async {
        await runTests(moduleFormat: 'amd');
      });

      test('DDC module format and canary', () async {
        await runTests(moduleFormat: 'ddc', canary: true);
      });
    });
  });
}

/// Computes the location of platform binaries, that is, compiled `.dill` files
/// of the platform libraries that are used to avoid recompiling those
/// libraries.
Uri computePlatformBinariesLocation() {
  // The directory of the Dart VM executable.
  Uri vmDirectory = Uri.base
      .resolveUri(new Uri.file(Platform.resolvedExecutable))
      .resolve(".");
  if (vmDirectory.path.endsWith("/bin/")) {
    // Looks like the VM is in a `/bin/` directory, so this is running from a
    // built SDK.
    return vmDirectory.resolve("../lib/_internal/");
  } else {
    // We assume this is running from a build directory (for example,
    // `out/ReleaseX64` or `xcodebuild/ReleaseX64`).
    return vmDirectory;
  }
}

class CompilationResult {
  late String filename;
  int errorsCount = 0;

  CompilationResult.parse(String? filenameAndErrorCount) {
    if (filenameAndErrorCount == null) {
      return;
    }
    int delim = filenameAndErrorCount.lastIndexOf(' ');
    expect(delim > 0, equals(true));
    filename = filenameAndErrorCount.substring(0, delim);
    errorsCount = int.parse(filenameAndErrorCount.substring(delim + 1).trim());
  }
}

class OutputParser {
  bool expectSources = true;
  final StreamController<Result> _receivedResults;

  List<String>? _receivedSources;
  String? _boundaryKey;

  bool _readingSources = false;
  OutputParser(this._receivedResults);

  void listener(String s) {
    if (_boundaryKey == null) {
      const String resultOutputSpace = 'result ';
      if (s.startsWith(resultOutputSpace)) {
        _boundaryKey = s.substring(resultOutputSpace.length);
      }
      _readingSources = false;
      _receivedSources?.clear();
      return;
    }

    String bKey = _boundaryKey!;
    if (s.startsWith(bKey)) {
      // First boundaryKey separates compiler output from list of sources
      // (if we expect list of sources, which is indicated by receivedSources
      // being not null)
      if (expectSources && !_readingSources) {
        _readingSources = true;
        return;
      }
      // Second boundaryKey indicates end of frontend server response
      expectSources = true;
      _receivedResults.add(new Result(
          s.length > bKey.length ? s.substring(bKey.length + 1) : null,
          _receivedSources!));
      _boundaryKey = null;
    } else {
      if (_readingSources) {
        _receivedSources ??= <String>[];
        _receivedSources!.add(s);
      } else {
        print("> $s");
      }
    }
  }
}

class Result {
  String? status;
  List<String> sources;

  Result(this.status, this.sources);

  void expectNoErrors({String? filename}) {
    CompilationResult result = new CompilationResult.parse(status);
    expect(result.errorsCount, equals(0));
    if (filename != null) {
      expect(result.filename, equals(filename));
    }
  }
}

/// Creates a matcher for the negation of [matcher].
Matcher not(Matcher matcher) => new NotMatcher(matcher);

class NotMatcher extends Matcher {
  final Matcher matcher;

  const NotMatcher(this.matcher);

  @override
  Description describe(Description description) =>
      matcher.describe(description.add('not '));

  @override
  bool matches(item, Map matchState) {
    return !matcher.matches(item, matchState);
  }
}

/// Wrapper for the frontend server communication.
class FrontendServer {
  final StreamController<List<int>> inputStreamController;
  final StreamController<List<int>> stdoutStreamController;
  final IOSink ioSink;
  final StreamController<Result> receivedResults;
  final OutputParser outputParser;

  factory FrontendServer() {
    final StreamController<List<int>> inputStreamController =
        new StreamController<List<int>>();
    final StreamController<List<int>> stdoutStreamController =
        new StreamController<List<int>>();
    final IOSink ioSink = new IOSink(stdoutStreamController.sink);
    StreamController<Result> receivedResults = new StreamController<Result>();
    final OutputParser outputParser = new OutputParser(receivedResults);
    stdoutStreamController.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(outputParser.listener);
    return new FrontendServer._internal(inputStreamController,
        stdoutStreamController, ioSink, receivedResults, outputParser);
  }

  FrontendServer._internal(
      this.inputStreamController,
      this.stdoutStreamController,
      this.ioSink,
      this.receivedResults,
      this.outputParser);

  /// Sets up the front end server using the provided commandline arguments
  /// [args].
  Future<int> open(List<String> args) =>
      starter(args, input: inputStreamController.stream, output: ioSink);

  /// Closes the listener stream.
  void close() => inputStreamController.close();

  /// Sets up [f] to be called for each [Result] received from the frontend
  /// server.
  void listen(void Function(Result) f) => receivedResults.stream.listen(f);

  /// Accepts the last compilation delta.
  void accept() {
    outputParser.expectSources = false;
    inputStreamController.add('accept\n'.codeUnits);
  }

  /// Rejects the last compilation delta.
  void reject() {
    outputParser.expectSources = false;
    inputStreamController.add('reject\n'.codeUnits);
  }

  /// Resets the incremental compiler.
  void reset() {
    outputParser.expectSources = false;
    inputStreamController.add('reset\n'.codeUnits);
  }

  /// Terminates the frontend server.
  void quit() {
    outputParser.expectSources = false;
    inputStreamController.add('quit\n'.codeUnits);
  }

  /// Compiles the program from entry point [path].
  // TODO(johnniwinther): Use (required) named arguments.
  void compile(String path) {
    outputParser.expectSources = true;
    inputStreamController.add('compile $path\n'.codeUnits);
  }

  /// Recompiles the program.
  ///
  /// [invalidatedUri] and [invalidatedUris] define which libraries that
  /// need recompilation.
  ///
  /// [entryPoint] defines the program entry-point. If not provided, the
  /// original entry point is used.
  ///
  /// [boundaryKey] is used as the boundary-key in the communication with the
  /// frontend server.
  // TODO(johnniwinther): Use (required) named arguments.
  void recompile(Uri? invalidatedUri,
      {String boundaryKey = 'abc',
      List<Uri>? invalidatedUris,
      String? entryPoint}) {
    invalidatedUris ??= [if (invalidatedUri != null) invalidatedUri];
    outputParser.expectSources = true;
    inputStreamController.add('recompile '
            '${entryPoint != null ? '$entryPoint ' : ''}'
            '$boundaryKey\n'
            '${invalidatedUris.map((uri) => '$uri\n').join()}'
            '$boundaryKey\n'
        .codeUnits);
  }

  /// Compiles the native assets in isolation.
  void compileNativeAssetsOnly() {
    outputParser.expectSources = true;
    inputStreamController.add('native-assets-only\n'.codeUnits);
  }

  /// Sets the native assets yaml [uri].
  void setNativeAssets({required Uri uri}) {
    outputParser.expectSources = true;
    inputStreamController.add('native-assets $uri\n'.codeUnits);
  }

  /// Compiles the [expression] as if it occurs in [library] in "script"
  /// [scriptUri] at offset [offset].
  /// If no [scriptUri] is provided it defaults to the same as [library].
  /// If no [offset] is provided it defaults to -1 (i.e. "no offset").
  /// [scriptUri] (if different, e.g. if in a part) and [offset] is needed for
  /// finding static types which is needed for expression evaluation on
  /// extension types.
  ///
  /// If [className] is provided, [expression] is compiled as if it occurs in
  /// the class of that name.
  ///
  /// If [isStatic] is `true`, the expression is compiled in the static scope
  /// of [className]. If [className] is `null`, this must be `false`.
  ///
  /// [boundaryKey] is used as the boundary-key in the communication with the
  /// frontend server.
  // TODO(johnniwinther): Use (required) named arguments.
  void compileExpression(String expression, Uri library,
      {String boundaryKey = 'abc',
      List<String> definitions = const [],
      List<String> definitionTypes = const [],
      String? className,
      String? methodName,
      bool? isStatic,
      Uri? scriptUri,
      int? offset}) {
    if (useJsonForCommunication) {
      outputParser.expectSources = false;
      inputStreamController.add('JSON_INPUT\n'.codeUnits);
      String jsonData = json.encode({
        "type": "COMPILE_EXPRESSION",
        "data": {
          "expression": expression,
          "libraryUri": library.toString(),
          "definitions": definitions,
          "definitionTypes": definitionTypes,
          if (className != null) "class": className,
          if (methodName != null) "method": methodName,
          if (scriptUri != null) "scriptUri": scriptUri.toString(),
          if (offset != null) "offset": offset,
          if (isStatic != null) "static": isStatic,
        }
      });
      if (useJsonLineBreaks) {
        jsonData = jsonData.replaceAll(",", ",\n");
      }
      inputStreamController.add(jsonData.codeUnits);
      inputStreamController.add('\n'.codeUnits);
    } else {
      // 'compile-expression <boundarykey>
      // expression
      // definitions (one per line)
      // ...
      // <boundarykey>
      // definitionTypes (one per line)
      // ...
      // <boundarykey>
      // type-definitions (one per line)
      // ...
      // <boundarykey>
      // type-bounds (one per line)
      // ...
      // <boundarykey>
      // type-defaults (one per line)
      // ...
      // <boundarykey>
      // <libraryUri: String>
      // <klass: String>
      // <method: String>
      // <isStatic: true|false>
      outputParser.expectSources = false;
      inputStreamController.add('compile-expression $boundaryKey\n'
              '$expression\n'
              '$boundaryKey\n'
              '$boundaryKey\n'
              '$boundaryKey\n'
              '$boundaryKey\n'
              '$boundaryKey\n'
              '$library\n'
              '${className ?? ''}\n'
              '\n'
              '${isStatic != null ? '$isStatic' : ''}\n'
          .codeUnits);
    }
  }

  /// Compiles the [expression] to JavaScript as if it occurs in [line] and
  /// [column] of [libraryUri].
  ///
  /// [boundaryKey] is used as the boundary-key in the communication with the
  /// frontend server.
  void compileExpressionToJs(
      {required String expression,
      required String libraryUri,
      required int line,
      required int column,
      Uri? scriptUri,
      Map<String, String>? jsFrameValues,
      String boundaryKey = 'abc'}) {
    // TODO(https://github.com/dart-lang/sdk/issues/58265): `moduleName` is
    // soft-deprecated, so even though it's unused, the request should still
    // contain it so it can be parsed correctly.
    final String moduleName = 'unused';
    if (useJsonForCommunication) {
      outputParser.expectSources = false;
      inputStreamController.add('JSON_INPUT\n'.codeUnits);
      String jsonData = json.encode({
        "type": "COMPILE_EXPRESSION_JS",
        "data": {
          "expression": expression,
          "libraryUri": libraryUri,
          if (scriptUri != null) "scriptUri": scriptUri.toString(),
          if (jsFrameValues != null) "jsFrameValues": jsFrameValues,
          "line": line,
          "column": column,
          "moduleName": moduleName,
        }
      });
      if (useJsonLineBreaks) {
        jsonData = jsonData.replaceAll(",", ",\n");
      }
      inputStreamController.add(jsonData.codeUnits);
      inputStreamController.add('\n'.codeUnits);
    } else {
      // 'compile-expression-to-js <boundarykey>
      // libraryUri
      // line
      // column
      // jsModules (one k-v pair per line)
      // ...
      // <boundarykey>
      // jsFrameValues (one k-v pair per line)
      // ...
      // <boundarykey>
      // moduleName
      // expression
      outputParser.expectSources = false;
      inputStreamController.add('compile-expression-to-js $boundaryKey\n'
              '$libraryUri\n'
              '$line\n'
              '$column\n'
              '$boundaryKey\n'
              '$boundaryKey\n'
              '$moduleName\n'
              '$expression\n'
          .codeUnits);
    }
  }
}
