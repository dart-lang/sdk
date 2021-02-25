import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/kernel.dart' show loadComponentFromBinary;
import 'package:kernel/verifier.dart' show verifyComponent;
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm/incremental_compiler.dart';

import '../lib/frontend_server.dart';

class _MockedCompiler extends Mock implements CompilerInterface {}

class _MockedIncrementalCompiler extends Mock implements IncrementalCompiler {}

class _MockedBinaryPrinterFactory extends Mock implements BinaryPrinterFactory {
}

class _MockedBinaryPrinter extends Mock implements BinaryPrinter {}

void main() async {
  group('basic', () {
    final CompilerInterface compiler = _MockedCompiler();

    test('train with mocked compiler completes', () async {
      await starter(<String>['--train', 'foo.dart'], compiler: compiler);
    });
  });

  group('batch compile with mocked compiler', () {
    final CompilerInterface compiler = _MockedCompiler();
    when(compiler.compile(any, any, generator: anyNamed('generator')))
        .thenAnswer((_) => Future.value(true));

    test('compile from command line', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
      ];
      await starter(args, compiler: compiler);
      final List<dynamic> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: anyNamed('generator'),
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
    });

    test('compile from command line with link platform', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--link-platform',
      ];
      await starter(args, compiler: compiler);
      final List<dynamic> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: anyNamed('generator'),
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['link-platform'], equals(true));
    });

    test('compile from command line with widget cache', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--flutter-widget-cache',
      ];
      await starter(args, compiler: compiler);
      final List<dynamic> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: anyNamed('generator'),
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['link-platform'], equals(true));
      expect(capturedArgs.single['flutter-widget-cache'], equals(true));
    });
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort compileCalled = ReceivePort();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) async {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
        return true;
      });

      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile one file to JavaScript', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort compileCalled = ReceivePort();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) async {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
        return true;
      });

      Future<int> result = starter(
        ['--target=dartdevc', ...args],
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort compileCalled = ReceivePort();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) async {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
        return true;
      });

      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile few files', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort compileCalled = ReceivePort();
      int counter = 1;
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) async {
        expect(invocation.positionalArguments[0],
            equals('server${counter++}.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
        return true;
      });

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
      inputStreamController.close();
    });
  });

  group('interactive incremental compile with mocked compiler', () {
    final CompilerInterface compiler = _MockedCompiler();
    when(compiler.compile(any, any, generator: anyNamed('generator')))
        .thenAnswer((_) => Future.value(true));

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental'
    ];

    test('recompile few files', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort recompileCalled = ReceivePort();

      when(compiler.recompileDelta(entryPoint: null))
          .thenAnswer((Invocation invocation) async {
        recompileCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController
          .add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        compiler.invalidate(Uri.base.resolve('file1.dart')),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        await compiler.recompileDelta(entryPoint: null),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('recompile one file with widget cache does not fail', () async {
      // The component will not contain the flutter framework sources so
      // this should no-op.
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort recompileCalled = ReceivePort();

      when(compiler.recompileDelta(entryPoint: null))
          .thenAnswer((Invocation invocation) async {
        recompileCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        <String>[...args, '--flutter-widget-cache'],
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('recompile abc\nfile1.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        compiler.invalidate(Uri.base.resolve('file1.dart')),
        await compiler.recompileDelta(entryPoint: null),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('recompile few files with new entrypoint', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort recompileCalled = ReceivePort();

      when(compiler.recompileDelta(entryPoint: 'file2.dart'))
          .thenAnswer((Invocation invocation) async {
        recompileCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add(
          'recompile file2.dart abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        compiler.invalidate(Uri.base.resolve('file1.dart')),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        await compiler.recompileDelta(entryPoint: 'file2.dart'),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('accept', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort acceptCalled = ReceivePort();
      when(compiler.acceptLastDelta()).thenAnswer((Invocation invocation) {
        acceptCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('accept\n'.codeUnits);
      await acceptCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('reset', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort resetCalled = ReceivePort();
      when(compiler.resetIncrementalCompiler())
          .thenAnswer((Invocation invocation) {
        resetCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('reset\n'.codeUnits);
      await resetCalled.first;
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile then recompile', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final ReceivePort recompileCalled = ReceivePort();

      when(compiler.recompileDelta(entryPoint: null))
          .thenAnswer((Invocation invocation) async {
        recompileCalled.sendPort.send(true);
      });
      Future<int> result = starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      inputStreamController.add('compile file1.dart\n'.codeUnits);
      inputStreamController.add('accept\n'.codeUnits);
      inputStreamController
          .add('recompile def\nfile2.dart\nfile3.dart\ndef\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        await compiler.compile('file1.dart', any,
            generator: anyNamed('generator')),
        compiler.acceptLastDelta(),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        compiler.invalidate(Uri.base.resolve('file3.dart')),
        await compiler.recompileDelta(entryPoint: null),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });
  });

  group('interactive incremental compile with mocked IKG', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental',
    ];

    Directory tempDir;
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });
    tearDown(() {
      tempDir.delete(recursive: true);
    });

    test('compile then accept', () async {
      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      ReceivePort receivedResult = ReceivePort();

      String boundaryKey;
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String s) {
        const String RESULT_OUTPUT_SPACE = 'result ';
        if (boundaryKey == null) {
          if (s.startsWith(RESULT_OUTPUT_SPACE)) {
            boundaryKey = s.substring(RESULT_OUTPUT_SPACE.length);
          }
        } else {
          if (s.startsWith(boundaryKey)) {
            boundaryKey = null;
            receivedResult.sendPort.send(true);
          }
        }
      });

      final _MockedIncrementalCompiler generator = _MockedIncrementalCompiler();
      when(generator.initialized).thenAnswer((_) => false);
      when(generator.compile())
          .thenAnswer((_) => Future<Component>.value(Component()));
      when(generator.compile(entryPoint: anyNamed("entryPoint")))
          .thenAnswer((_) => Future<Component>.value(Component()));
      final _MockedBinaryPrinterFactory printerFactory =
          _MockedBinaryPrinterFactory();
      when(printerFactory.newBinaryPrinter(any))
          .thenReturn(_MockedBinaryPrinter());
      Future<int> result = starter(
        args,
        compiler: null,
        input: inputStreamController.stream,
        output: ioSink,
        generator: generator,
        binaryPrinterFactory: printerFactory,
      );

      final source = File('${tempDir.path}/file1.dart');
      inputStreamController.add('compile ${source.path}\n'.codeUnits);
      await receivedResult.first;
      inputStreamController.add('accept\n'.codeUnits);
      receivedResult = ReceivePort();
      inputStreamController
          .add('recompile def\n${source.path}\ndef\n'.codeUnits);
      await receivedResult.first;

      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    group('compile with output path', () {
      final CompilerInterface compiler = _MockedCompiler();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((_) => Future.value(true));

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
        final List<dynamic> capturedArgs = verify(compiler.compile(
          argThat(equals('server.dart')),
          captureAny,
          generator: anyNamed('generator'),
        )).captured;
        expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      });
    });
  });

  group('full compiler tests', () {
    final platformKernel =
        computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
    final ddcPlatformKernel =
        computePlatformBinariesLocation().resolve('ddc_outline_sound.dill');
    final ddcPlatformKernelWeak =
        computePlatformBinariesLocation().resolve('ddc_sdk.dill');
    final sdkRoot = computePlatformBinariesLocation();

    Directory tempDir;
    setUp(() {
      var systemTempDir = Directory.systemTemp;
      tempDir = systemTempDir.createTempSync('foo bar');
    });

    tearDown(() {
      tempDir.delete(recursive: true);
    });

    test('compile expression', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n}\n");
      var dillFile = File('${tempDir.path}/app.dill');

      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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
        '--packages=${package_config.path}',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(result.errorsCount, equals(0));
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          streamController.add('accept\n'.codeUnits);

          // 'compile-expression <boundarykey>
          // expression
          // definitions (one per line)
          // ...
          // <boundarykey>
          // type-defintions (one per line)
          // ...
          // <boundarykey>
          // <libraryUri: String>
          // <klass: String>
          // <isStatic: true|false>
          outputParser.expectSources = false;
          streamController.add(
              'compile-expression abc\n2+2\nabc\nabc\n${file.uri}\n\n\n'
                  .codeUnits);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, isNull);
          // Previous request should have failed because isStatic was blank
          expect(compiledResult.status, isNull);

          outputParser.expectSources = false;
          streamController.add(
              'compile-expression abc\n2+2\nabc\nabc\n${file.uri}\n\nfalse\n'
                  .codeUnits);
          count += 1;
        } else if (count == 2) {
          expect(result.errorsCount, equals(0));
          // Second request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          streamController.add('compile foo.bar\n'.codeUnits);
          count += 1;
        } else {
          expect(count, 3);
          // Third request is to 'compile' non-existent file, that should fail.
          expect(result.errorsCount, greaterThan(0));

          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      expect(count, 3);
    });

    test('mixed compile expression commands with non-web target', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      var library = 'package:hello/foo.dart';
      var module = 'packages/hello/foo.dart';

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(result.errorsCount, equals(0));
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          streamController.add('accept\n'.codeUnits);

          // 'compile-expression <boundarykey>
          // expression
          // definitions (one per line)
          // ...
          // <boundarykey>
          // type-defintions (one per line)
          // ...
          // <boundarykey>
          // <libraryUri: String>
          // <klass: String>
          // <isStatic: true|false>
          outputParser.expectSources = false;
          streamController.add('compile-expression abc\n'
                  '2+2\nabc\nabc\n${file.uri}\n\nfalse\n'
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, equals(0));
          // Second request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

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
          streamController.add('compile-expression-to-js abc\n'
                  '$library\n1\n1\nabc\nabc\n$module\n\n'
              .codeUnits);
          count += 1;
        } else if (count == 2) {
          // Third request is to 'compile-expression-to-js' that fails
          // due to non-web target
          expect(result.errorsCount, isNull);
          expect(compiledResult.status, isNull);

          outputParser.expectSources = false;
          streamController.add('compile-expression abc\n'
                  '2+2\nabc\nabc\n${file.uri}\n\nfalse\n'
              .codeUnits);
          count += 1;
        } else if (count == 3) {
          expect(result.errorsCount, equals(0));
          // Fourth request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      expect(count, 3);
    });

    test('compiler reports correct sources added', () async {
      var libFile = File('${tempDir.path}/lib.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("var foo = 42;");
      var mainFile = File('${tempDir.path}/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("main() => print('foo');\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      final Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${mainFile.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        compiledResult.expectNoErrors();
        if (count == 0) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('+${mainFile.uri}'));

          inputStreamController.add('accept\n'.codeUnits);
          mainFile
              .writeAsStringSync("import 'lib.dart';  main() => print(foo);\n");
          inputStreamController.add('recompile ${mainFile.path} abc\n'
                  '${mainFile.uri}\n'
                  'abc\n'
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('+${libFile.uri}'));
          inputStreamController.add('accept\n'.codeUnits);
          inputStreamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      inputStreamController.close();
    }, timeout: Timeout.factor(100));

    test('compiler reports correct sources removed', () async {
      var libFile = File('${tempDir.path}/lib.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("var foo = 42;");
      var mainFile = File('${tempDir.path}/main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync("import 'lib.dart'; main() => print(foo);\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      final Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${mainFile.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        compiledResult.expectNoErrors();
        if (count == 0) {
          expect(compiledResult.sources.length, equals(2));
          expect(compiledResult.sources,
              allOf(contains('+${mainFile.uri}'), contains('+${libFile.uri}')));

          inputStreamController.add('accept\n'.codeUnits);
          mainFile.writeAsStringSync("main() => print('foo');\n");
          inputStreamController.add('recompile ${mainFile.path} abc\n'
                  '${mainFile.uri}\n'
                  'abc\n'
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          expect(compiledResult.sources.length, equals(1));
          expect(compiledResult.sources, contains('-${libFile.uri}'));
          inputStreamController.add('accept\n'.codeUnits);
          inputStreamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      inputStreamController.close();
    }, timeout: Timeout.factor(100));

    test('compile expression when delta is rejected', () async {
      var fileLib = File('${tempDir.path}/lib.dart')..createSync();
      fileLib.writeAsStringSync("foo() => 42;\n");
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'lib.dart'; main1() => print(foo);\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      final Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request was to 'compile', which resulted in full kernel file.
          expect(result.errorsCount, 0);
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          inputStreamController.add('accept\n'.codeUnits);

          // 'compile-expression <boundarykey>
          // expression
          // definitions (one per line)
          // ...
          // <boundarykey>
          // type-defintions (one per line)
          // ...
          // <boundarykey>
          // <libraryUri: String>
          // <klass: String>
          // <isStatic: true|false>
          outputParser.expectSources = false;
          inputStreamController.add('''
compile-expression abc
main1
abc
abc
${file.uri}

true
'''
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          // Second request was to 'compile-expression', which resulted in
          // kernel file with a function that wraps compiled expression.
          expect(result.errorsCount, 0);
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          file.writeAsStringSync("import 'lib.dart'; main() => foo();\n");
          inputStreamController.add('recompile ${file.path} abc\n'
                  '${file.uri}\n'
                  'abc\n'
              .codeUnits);

          count += 1;
        } else if (count == 2) {
          // Third request was to recompile the script after renaming a function.
          expect(result.errorsCount, 0);
          outputParser.expectSources = false;
          inputStreamController.add('reject\n'.codeUnits);
          count += 1;
        } else if (count == 3) {
          // Fourth request was to reject the compilation results.
          outputParser.expectSources = false;
          inputStreamController.add(
              'compile-expression abc\nmain1\nabc\nabc\n${file.uri}\n\ntrue\n'
                  .codeUnits);
          count += 1;
        } else {
          expect(count, 4);
          // Fifth request was to 'compile-expression' that references original
          // function, which should still be successful.
          expect(result.errorsCount, 0);
          inputStreamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      inputStreamController.close();
    }, timeout: Timeout.factor(100));

    test('recompile request keeps incremental output dill filename', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(dillFile.existsSync(), equals(true));
          compiledResult.expectNoErrors(filename: dillFile.path);
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);
          var file2 = File('${tempDir.path}/bar.dart')..createSync();
          file2.writeAsStringSync("main() {}\n");
          inputStreamController.add('recompile ${file2.path} abc\n'
                  '${file2.uri}\n'
                  'abc\n'
              .codeUnits);
        } else {
          expect(count, 1);
          // Second request is to 'recompile', which results in incremental
          // kernel file.
          var dillIncFile = File('${dillFile.path}.incremental.dill');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          inputStreamController.add('quit\n'.codeUnits);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test(
        'recompile request with flutter widget cache outputs change in class name',
        () async {
      var frameworkDirectory = Directory('${tempDir.path}/flutter');
      var flutterFramework =
          File('${frameworkDirectory.path}/lib/src/widgets/framework.dart')
            ..createSync(recursive: true);
      flutterFramework.writeAsStringSync('''
abstract class Widget {}
class StatelessWidget extends Widget {}
class StatefulWidget extends Widget {}
class State<T extends StatefulWidget> {}
''');

      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("""
import "package:flutter/src/widgets/framework.dart";

void main() {}

class FooWidget extends StatelessWidget {}

class FizzWidget extends StatefulWidget {}

class BarState extends State<FizzWidget> {}
""");
      var config = File('${tempDir.path}/package_config.json')..createSync();
      config.writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "flutter",
      "rootUri": "${frameworkDirectory.uri}",
      "packageUri": "lib/"
    }
  ]
}
''');

      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--flutter-widget-cache',
        '--packages=${config.path}',
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(dillFile.existsSync(), equals(true));
          compiledResult.expectNoErrors(filename: dillFile.path);
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);
          file.writeAsStringSync("""
import "package:flutter/src/widgets/framework.dart";

void main() {}

class FooWidget extends StatelessWidget {
  // Added.
}

class FizzWidget extends StatefulWidget {}

class BarState extends State<FizzWidget> {}
""");
          inputStreamController.add('recompile ${file.path} abc\n'
                  '${file.uri}\n'
                  'abc\n'
              .codeUnits);
        } else if (count == 1) {
          expect(count, 1);
          // Second request is to 'recompile', which results in incremental
          // kernel file and invalidation of StatelessWidget.
          var dillIncFile = File('${dillFile.path}.incremental.dill');
          var widgetCacheFile =
              File('${dillFile.path}.incremental.dill.widget_cache');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          expect(widgetCacheFile.existsSync(), equals(true));
          expect(widgetCacheFile.readAsStringSync(), 'FooWidget');
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);

          file.writeAsStringSync("""
import "package:flutter/src/widgets/framework.dart";

void main() {}

class FooWidget extends StatelessWidget {
  // Added.
}

class FizzWidget extends StatefulWidget {
  // Added.
}

class BarState extends State<FizzWidget> {}
""");
          inputStreamController.add('recompile ${file.path} abc\n'
                  '${file.uri}\n'
                  'abc\n'
              .codeUnits);
        } else if (count == 2) {
          // Second request is to 'recompile', which results in incremental
          // kernel file and invalidation of StatelessWidget.
          var dillIncFile = File('${dillFile.path}.incremental.dill');
          var widgetCacheFile =
              File('${dillFile.path}.incremental.dill.widget_cache');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          expect(widgetCacheFile.existsSync(), equals(true));
          expect(widgetCacheFile.readAsStringSync(), 'FizzWidget');
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);

          file.writeAsStringSync("""
import "package:flutter/src/widgets/framework.dart";

void main() {}

class FooWidget extends StatelessWidget {
  // Added.
}

class FizzWidget extends StatefulWidget {
  // Added.
}

class BarState extends State<FizzWidget> {
  // Added.
}
""");
          inputStreamController.add('recompile ${file.path} abc\n'
                  '${file.uri}\n'
                  'abc\n'
              .codeUnits);
        } else if (count == 3) {
          // Third request is to 'recompile', which results in incremental
          // kernel file and invalidation of State class.
          var dillIncFile = File('${dillFile.path}.incremental.dill');
          var widgetCacheFile =
              File('${dillFile.path}.incremental.dill.widget_cache');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          expect(widgetCacheFile.existsSync(), equals(true));
          expect(widgetCacheFile.readAsStringSync(), 'FizzWidget');
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);

          file.writeAsStringSync("""
import "package:flutter/src/widgets/framework.dart";

void main() {}

// Added

class FooWidget extends StatelessWidget {
  // Added.
}

class FizzWidget extends StatefulWidget {
  // Added.
}

class BarState extends State<FizzWidget> {
  // Added.
}
""");
          inputStreamController.add('recompile ${file.path} abc\n'
                  '${file.uri}\n'
                  'abc\n'
              .codeUnits);
        } else if (count == 4) {
          // Fourth request is to 'recompile', which results in incremental
          // kernel file and no widget cache
          var dillIncFile = File('${dillFile.path}.incremental.dill');
          var widgetCacheFile =
              File('${dillFile.path}.incremental.dill.widget_cache');
          compiledResult.expectNoErrors(filename: dillIncFile.path);
          expect(dillIncFile.existsSync(), equals(true));
          expect(widgetCacheFile.existsSync(), equals(false));
          inputStreamController.add('quit\n'.codeUnits);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('unsafe-package-serialization', () async {
      // Package A.
      var file = File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      // Package B.
      file = File('${tempDir.path}/pkgB/a.dart')..createSync(recursive: true);
      file.writeAsStringSync("pkgB_a() {}");
      file = File('${tempDir.path}/pkgB/b.dart')..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgA/a.dart';"
          "pkgB_b() { pkgA(); }");

      // Application.
      File('${tempDir.path}/app/.dart_tool/package_config.json')
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
      file = File('${tempDir.path}/app/a.dart')..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgB/b.dart';"
          "import 'package:pkgB/a.dart';"
          "appA() { pkgB_a(); pkgB_b(); }");

      // Entry point B uses only package B.
      var fileB = File('${tempDir.path}/app/B.dart')
        ..createSync(recursive: true);
      fileB.writeAsStringSync("import 'package:pkgB/a.dart';"
          "appB() { pkgB_a(); }");

      // Other setup.
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      // First compile app entry point A.
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--unsafe-package-serialization',
        '--no-incremental-serialization',
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('reset\n'.codeUnits);

            inputStreamController.add('recompile ${fileB.path} abc\n'
                    '${fileB.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 1:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            inputStreamController.add('quit\n'.codeUnits);

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
            verifyComponent(component);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('incremental-serialization', () async {
      // Package A.
      var file = File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      // Package B.
      file = File('${tempDir.path}/pkgB/a.dart')..createSync(recursive: true);
      file.writeAsStringSync("pkgB_a() {}");
      file = File('${tempDir.path}/pkgB/b.dart')..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgA/a.dart';"
          "pkgB_b() { pkgA(); }");

      // Application.
      File('${tempDir.path}/app/.dart_tool/package_config.json')
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
      file = File('${tempDir.path}/app/.packages')..createSync(recursive: true);
      file.writeAsStringSync("pkgA:../pkgA\n"
          "pkgB:../pkgB");

      // Entry point A uses both package A and B.
      file = File('${tempDir.path}/app/a.dart')..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgB/b.dart';"
          "import 'package:pkgB/a.dart';"
          "appA() { pkgB_a(); pkgB_b(); }");

      // Entry point B uses only package B.
      var fileB = File('${tempDir.path}/app/B.dart')
        ..createSync(recursive: true);
      fileB.writeAsStringSync("import 'package:pkgB/a.dart';"
          "appB() { pkgB_a(); }");

      // Other setup.
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      // First compile app entry point A.
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--incremental-serialization',
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('reset\n'.codeUnits);

            inputStreamController.add('recompile ${fileB.path} abc\n'
                    '${fileB.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 1:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            inputStreamController.add('quit\n'.codeUnits);

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
            verifyComponent(component);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('incremental-serialization with reject', () async {
      // Basically a reproduction of
      // https://github.com/flutter/flutter/issues/44384.
      var file = File('${tempDir.path}/pkgA/.packages')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA:.");
      file = File('${tempDir.path}/pkgA/a.dart')..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--incremental-serialization',
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            var libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 1 procedure.
            expect(libs.first.procedures.length, 1);

            file.writeAsStringSync("pkgA() {} pkgA_2() {}");

            count += 1;
            outputParser.expectSources = false;
            inputStreamController.add('reject\n'.codeUnits);
            break;
          case 1:
            count += 1;
            inputStreamController.add('reset\n'.codeUnits);
            inputStreamController.add('recompile ${file.path} abc\n'
                    '${file.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 2:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            var libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 2 procedure.
            expect(libs.first.procedures.length, 2);

            file.writeAsStringSync("pkgA() {} pkgA_2() {} pkgA_3() {}");

            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('reset\n'.codeUnits);
            inputStreamController.add('recompile ${file.path} abc\n'
                    '${file.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 3:
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            inputStreamController.add('quit\n'.codeUnits);

            // Loadable.
            Component component = loadComponentFromBinary(dillFile.path);

            // Contain the file we want.
            var libs = component.libraries
                .where((l) => l.importUri.toString() == "package:pkgA/a.dart");
            expect(libs.length, 1);

            // Has 3 procedures.
            expect(libs.first.procedures.length, 3);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile and recompile report non-zero error count', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() { foo(); bar(); }\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();

      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.uri}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 2);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            var file2 = File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { baz(); }\n");
            inputStreamController.add('recompile ${file2.uri} abc\n'
                    '${file2.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 1:
            var dillIncFile = File('${dillFile.path}.incremental.dill');
            expect(result.filename, dillIncFile.path);
            expect(result.errorsCount, 1);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            var file2 = File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { }\n");
            inputStreamController.add('recompile ${file2.uri} abc\n'
                    '${file2.uri}\n'
                    'abc\n'
                .codeUnits);
            break;
          case 2:
            var dillIncFile = File('${dillFile.path}.incremental.dill');
            expect(result.filename, dillIncFile.path);
            expect(result.errorsCount, 0);
            expect(dillIncFile.existsSync(), equals(true));
            inputStreamController.add('quit\n'.codeUnits);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile and recompile with MultiRootFileSystem', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync("\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=test-scheme:///.packages',
        '--filesystem-root=${tempDir.path}',
        '--filesystem-scheme=test-scheme',
        'test-scheme:///foo.dart'
      ];
      expect(await starter(args), 0);
    });

    group('http uris', () {
      var host = 'localhost';
      File dillFile;
      int port;
      HttpServer server;

      setUp(() async {
        dillFile = File('${tempDir.path}/app.dill');
        server = await HttpServer.bind(host, 0);
        port = server.port;
        server.listen((request) {
          var path = request.uri.path;
          var file = File('${tempDir.path}$path');
          var response = request.response;
          if (!file.existsSync()) {
            response.statusCode = 404;
          } else {
            response.statusCode = 200;
            response.add(file.readAsBytesSync());
          }
          response.close();
        });
        var main = File('${tempDir.path}/foo.dart')..createSync();
        main.writeAsStringSync(
            "import 'package:foo/foo.dart'; main() {print(foo);}\n");
        File('${tempDir.path}/.dart_tool/package_config.json')
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
        File('${tempDir.path}/packages/foo/foo.dart')
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
          '--packages=http://$host:$port/.packages',
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
          '--packages=test-app:///.packages',
          '--filesystem-root=http://$host:$port/',
          '--filesystem-scheme=test-app',
          'test-app:///foo.dart',
        ];
        expect(await starter(args), 0);
        expect(dillFile.existsSync(), equals(true));
      });
    });

    test('compile to JavaScript', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n}\n");
      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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
      var dillFile = File('${tempDir.path}/app.dill');

      expect(dillFile.existsSync(), false);

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=${package_config.path}',
        '--target=dartdevc',
        '--enable-experiment=non-nullable',
        file.path,
      ];

      expect(await starter(args), 0);
    });

    test('compile to JavaScript with package scheme', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n}\n");
      var packages = File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync("hello:${tempDir.uri}\n");
      var dillFile = File('${tempDir.path}/app.dill');

      expect(dillFile.existsSync(), false);

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernelWeak.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${packages.path}',
        'package:hello/foo.dart'
      ];

      expect(await starter(args), 0);
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    test('compile to JavaScript weak null safety', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("// @dart = 2.9\nmain() {\n}\n");
      var packages = File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync("hello:${tempDir.uri}\n");
      var dillFile = File('${tempDir.path}/app.dill');

      expect(dillFile.existsSync(), false);

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernelWeak.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${packages.path}',
        'package:hello/foo.dart'
      ];

      expect(await starter(args), 0);
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    test('compile to JavaScript weak null safety then non-existent file',
        () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("// @dart = 2.9\nmain() {\n}\n");
      var packages = File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync("hello:${tempDir.uri}\n");
      var dillFile = File('${tempDir.path}/app.dill');

      expect(dillFile.existsSync(), false);

      var library = 'package:hello/foo.dart';

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernelWeak.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${packages.path}',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      var count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        count++;
        if (count == 1) {
          // First request is to 'compile', which results in full JavaScript
          expect(result.errorsCount, equals(0));
          expect(result.filename, dillFile.path);
          streamController.add('accept\n'.codeUnits);
          streamController.add('compile foo.bar\n'.codeUnits);
        } else {
          expect(count, 2);
          // Second request is to 'compile' non-existent file, that should fail.
          expect(result.errorsCount, greaterThan(0));
          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      expect(count, 2);
    }, skip: 'https://github.com/dart-lang/sdk/issues/43959');

    test('compile to JavaScript with no metadata', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n\n}\n");

      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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

      var library = 'package:hello/foo.dart';

      var dillFile = File('${tempDir.path}/app.dill');
      var sourceFile = File('${dillFile.path}.sources');
      var manifestFile = File('${dillFile.path}.json');
      var sourceMapsFile = File('${dillFile.path}.map');
      var metadataFile = File('${dillFile.path}.metadata');

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
        '--packages=${package_config.path}',
        '--enable-experiment=non-nullable',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      var count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        count++;
        // Request to 'compile', which results in full JavaScript and no
        // metadata.
        expect(result.errorsCount, equals(0));
        expect(sourceFile.existsSync(), equals(true));
        expect(manifestFile.existsSync(), equals(true));
        expect(sourceMapsFile.existsSync(), equals(true));
        expect(metadataFile.existsSync(), equals(false));
        expect(result.filename, dillFile.path);
        streamController.add('accept\n'.codeUnits);
        outputParser.expectSources = false;
        streamController.add('quit\n'.codeUnits);
      });

      expect(await result, 0);
      expect(count, 1);
    });

    test('compile to JavaScript with metadata', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n\n}\n");
      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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

      var library = 'package:hello/foo.dart';

      var dillFile = File('${tempDir.path}/app.dill');
      var sourceFile = File('${dillFile.path}.sources');
      var manifestFile = File('${dillFile.path}.json');
      var sourceMapsFile = File('${dillFile.path}.map');
      var metadataFile = File('${dillFile.path}.metadata');

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
        '--packages=${package_config.path}',
        '--experimental-emit-debug-metadata',
        '--enable-experiment=non-nullable',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        count++;
        // Request to 'compile', which results in full JavaScript and metadata.
        expect(result.errorsCount, equals(0));
        expect(sourceFile.existsSync(), equals(true));
        expect(manifestFile.existsSync(), equals(true));
        expect(sourceMapsFile.existsSync(), equals(true));
        expect(metadataFile.existsSync(), equals(true));
        expect(result.filename, dillFile.path);
        streamController.add('accept\n'.codeUnits);
        outputParser.expectSources = false;
        streamController.add('quit\n'.codeUnits);
      });

      expect(await result, 0);
      expect(count, 1);
    });

    test('compile to JavaScript all modules with unsound null safety',
        () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'bar.dart'; "
          "typedef myType = void Function(int); main() { fn is myType; }\n");
      file = File('${tempDir.path}/bar.dart')..createSync();
      file.writeAsStringSync("void Function(int) fn = (int i) => null;\n");
      var library = 'package:hello/foo.dart';

      var dillFile = File('${tempDir.path}/app.dill');
      var sourceFile = File('${dillFile.path}.sources');

      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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
        '--packages=${package_config.path}'
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      var count = 0;
      var expectationCompleter = Completer<bool>();
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        count++;
        // Request to 'compile', which results in full JavaScript and no
        // metadata.
        expect(result.errorsCount, equals(0));
        expect(sourceFile.existsSync(), equals(true));
        expect(result.filename, dillFile.path);

        var source = sourceFile.readAsStringSync();
        // Split on the comment at the end of each module.
        var jsModules = source.split(RegExp("\/\/# sourceMappingURL=.*\.map"));

        // Both modules should include the unsound null safety check.
        expect(
            jsModules[0], contains('dart._checkModuleNullSafetyMode(false);'));
        expect(
            jsModules[1], contains('dart._checkModuleNullSafetyMode(false);'));
        streamController.add('accept\n'.codeUnits);
        outputParser.expectSources = false;
        streamController.add('quit\n'.codeUnits);
        expectationCompleter.complete(true);
      });

      await expectationCompleter.future;
      expect(await result, 0);
      expect(count, 1);
    }, timeout: Timeout.none);

    test('compile to JavaScript, all modules with sound null safety', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync(
          "import 'bar.dart'; typedef myType = void Function(int); "
          "main() { fn is myType; }\n");
      file = File('${tempDir.path}/bar.dart')..createSync();
      file.writeAsStringSync("void Function(int) fn = (int i) => null;\n");

      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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

      var library = 'package:hello/foo.dart';

      var dillFile = File('${tempDir.path}/app.dill');
      var sourceFile = File('${dillFile.path}.sources');

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${package_config.path}',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      var count = 0;
      var expectationCompleter = Completer<bool>();
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        count++;
        // Request to 'compile', which results in full JavaScript and no
        // metadata.
        expect(result.errorsCount, equals(0));
        expect(sourceFile.existsSync(), equals(true));
        expect(result.filename, dillFile.path);

        var source = sourceFile.readAsStringSync();
        // Split on the comment at the end of each module.
        var jsModules = source.split(RegExp("\/\/# sourceMappingURL=.*\.map"));

        // Both modules should include the sound null safety validation.
        expect(
            jsModules[0], contains('dart._checkModuleNullSafetyMode(true);'));
        expect(
            jsModules[1], contains('dart._checkModuleNullSafetyMode(true);'));
        streamController.add('accept\n'.codeUnits);
        outputParser.expectSources = false;
        streamController.add('quit\n'.codeUnits);
        expectationCompleter.complete(true);
      });

      await expectationCompleter.future;
      expect(await result, 0);
      expect(count, 1);
    });

    test('compile expression to Javascript', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n}\n");
      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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

      var library = 'package:hello/foo.dart';
      var module = 'packages/hello/foo.dart';

      var dillFile = File('${tempDir.path}/foo.dart.dill');
      var sourceFile = File('${dillFile.path}.sources');
      var manifestFile = File('${dillFile.path}.json');
      var sourceMapsFile = File('${dillFile.path}.map');

      expect(dillFile.existsSync(), false);

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${package_config.path}',
        '--enable-experiment=non-nullable',
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full JavaScript
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(manifestFile.existsSync(), equals(true));
          expect(sourceMapsFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          streamController.add('accept\n'.codeUnits);

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
          streamController.add('compile-expression-to-js abc\n'
                  '$library\n2\n1\nabc\nabc\n$module\n\n'
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          // Second request is to 'compile-expression-to-js' that fails
          // due to incorrect input - empty expression
          expect(result.errorsCount, 1);
          expect(compiledResult.status, (String status) {
            return status.endsWith(' 1');
          });

          outputParser.expectSources = false;
          streamController.add('compile-expression-to-js abc\n'
                  '$library\n2\n1\nabc\nabc\n$module\n2+2\n'
              .codeUnits);
          count += 1;
        } else if (count == 2) {
          expect(result.errorsCount, equals(0));
          // Third request is to 'compile-expression-to-js', which results in
          // js file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          streamController.add('compile foo.bar\n'.codeUnits);
          count += 1;
        } else {
          expect(count, 3);
          // Fourth request is to 'compile' non-existent file, that should fail.
          expect(result.errorsCount, greaterThan(0));

          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      expect(count, 3);
    });

    test('mixed compile expression commands with web target', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {\n\n}\n");
      var package_config =
          File('${tempDir.path}/.dart_tool/package_config.json')
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
      var library = 'package:hello/foo.dart';
      var module = 'packages/hello/foo.dart';

      var dillFile = File('${tempDir.path}/foo.dart.dill');
      var sourceFile = File('${dillFile.path}.sources');
      var manifestFile = File('${dillFile.path}.json');
      var sourceMapsFile = File('${dillFile.path}.map');

      expect(dillFile.existsSync(), false);

      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${ddcPlatformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--target=dartdevc',
        '--packages=${package_config.path}',
        '--enable-experiment=non-nullable'
      ];

      final StreamController<List<int>> streamController =
          StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          StreamController<List<int>>();
      final IOSink ioSink = IOSink(stdoutStreamController.sink);
      StreamController<Result> receivedResults = StreamController<Result>();
      final outputParser = OutputParser(receivedResults);
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(outputParser.listener);

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile $library\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((Result compiledResult) {
        CompilationResult result =
            CompilationResult.parse(compiledResult.status);
        if (count == 0) {
          // First request is to 'compile', which results in full JavaScript
          expect(result.errorsCount, equals(0));
          expect(sourceFile.existsSync(), equals(true));
          expect(manifestFile.existsSync(), equals(true));
          expect(sourceMapsFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          streamController.add('accept\n'.codeUnits);

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
          streamController.add('compile-expression-to-js abc\n'
                  '$library\n2\n1\nabc\nabc\n$module\n2+2\n'
              .codeUnits);
          count += 1;
        } else if (count == 1) {
          expect(result.errorsCount, equals(0));
          // Second request is to 'compile-expression-to-js', which results in
          // js file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          // 'compile-expression <boundarykey>
          // expression
          // definitions (one per line)
          // ...
          // <boundarykey>
          // type-defintions (one per line)
          // ...
          // <boundarykey>
          // <libraryUri: String>
          // <klass: String>
          // <isStatic: true|false>
          outputParser.expectSources = false;
          streamController.add('compile-expression abc\n'
                  '2+2\nabc\nabc\n${file.uri}\n\nfalse\n'
              .codeUnits);
          count += 1;
        } else if (count == 2) {
          expect(result.errorsCount, equals(0));
          // Third request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          outputParser.expectSources = false;
          streamController.add('compile-expression-to-js abc\n'
                  '$library\n2\n1\nabc\nabc\n$module\n2+2\n'
              .codeUnits);
          count += 1;
        } else if (count == 3) {
          expect(result.errorsCount, equals(0));
          // Fourth request is to 'compile-expression-to-js', which results in
          // js file with a function that wraps compiled expression.
          File outputFile = File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      expect(count, 3);
    });

    test('compile "package:"-file', () async {
      Directory lib = Directory('${tempDir.path}/lib')..createSync();
      File('${lib.path}/foo.dart')
        ..createSync()
        ..writeAsStringSync("main() {}\n");
      File packages = File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync('test:lib/\n');
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      var depFile = File('${tempDir.path}/the depfile');
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
      var depContents = depFile.readAsStringSync();
      var depContentsParsed = depContents.split(': ');
      expect(path.basename(depContentsParsed[0]), path.basename(dillFile.path));
      expect(depContentsParsed[1], isNotEmpty);
    });

    test('compile and produce deps file', () async {
      var file = File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      var depFile = File('${tempDir.path}/the depfile');
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
      var depContents = depFile.readAsStringSync();
      var depContentsParsed = depContents.split(': ');
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
      var dillFile = File('${tempDir.path}/full.dill');
      var incrementalDillFile = File('${tempDir.path}/incremental.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--output-incremental-dill=${incrementalDillFile.path}'
      ];
      File dart2js = File.fromUri(
          Platform.script.resolve("../../../pkg/compiler/bin/dart2js.dart"));
      expect(dart2js.existsSync(), equals(true));
      File dart2jsOtherFile = File.fromUri(Platform.script
          .resolve("../../../pkg/compiler/lib/src/compiler.dart"));
      expect(dart2jsOtherFile.existsSync(), equals(true));

      int libraryCount = -1;
      int sourceCount = -1;

      List<List<int>> compiledKernels = <List<int>>[];
      for (int serverCloses = 0; serverCloses < 2; ++serverCloses) {
        print("Restart #$serverCloses");
        final StreamController<List<int>> inputStreamController =
            StreamController<List<int>>();
        final StreamController<List<int>> stdoutStreamController =
            StreamController<List<int>>();
        final IOSink ioSink = IOSink(stdoutStreamController.sink);
        StreamController<Result> receivedResults = StreamController<Result>();

        final outputParser = OutputParser(receivedResults);
        stdoutStreamController.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(outputParser.listener);

        Future<int> result =
            starter(args, input: inputStreamController.stream, output: ioSink);
        inputStreamController.add('compile ${dart2js.path}\n'.codeUnits);
        int count = 0;
        receivedResults.stream.listen((Result compiledResult) {
          CompilationResult result =
              CompilationResult.parse(compiledResult.status);
          String outputFilename = result.filename;
          print("$outputFilename -- count $count");

          // Ensure that kernel file produced when compiler was initialized
          // from compiled kernel files matches kernel file produced when
          // compiler was initialized from sources on the first run.
          if (serverCloses == 0) {
            compiledKernels.add(File(dillFile.path).readAsBytesSync());
          } else {
            checkIsEqual(
                compiledKernels[count], File(dillFile.path).readAsBytesSync());
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
            verifyComponent(component);

            count += 1;

            // Restart with no changes
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('reset\n'.codeUnits);
            inputStreamController.add('recompile ${dart2js.path} x$count\n'
                    'x$count\n'
                .codeUnits);
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
            verifyComponent(component);

            count += 1;

            // Reload with no changes
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('recompile ${dart2js.path} x$count\n'
                    'x$count\n'
                .codeUnits);
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
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('recompile ${dart2js.path} x$count\n'
                    '${dart2jsOtherFile.uri}\n'
                    'x$count\n'
                .codeUnits);
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

            inputStreamController.add('quit\n'.codeUnits);
          }
        });
        expect(await result, 0);
        inputStreamController.close();
      }
    }, timeout: Timeout.factor(8));
  });
}

/// Computes the location of platform binaries, that is, compiled `.dill` files
/// of the platform libraries that are used to avoid recompiling those
/// libraries.
Uri computePlatformBinariesLocation() {
  // The directory of the Dart VM executable.
  Uri vmDirectory =
      Uri.base.resolveUri(Uri.file(Platform.resolvedExecutable)).resolve(".");
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
  String filename;
  int errorsCount;

  CompilationResult.parse(String filenameAndErrorCount) {
    if (filenameAndErrorCount == null) {
      return;
    }
    int delim = filenameAndErrorCount.lastIndexOf(' ');
    expect(delim > 0, equals(true));
    filename = filenameAndErrorCount.substring(0, delim);
    errorsCount = int.parse(filenameAndErrorCount.substring(delim + 1).trim());
  }
}

class Result {
  String status;
  List<String> sources;

  Result(this.status, this.sources);

  void expectNoErrors({String filename}) {
    var result = CompilationResult.parse(status);
    expect(result.errorsCount, equals(0));
    if (filename != null) {
      expect(result.filename, equals(filename));
    }
  }
}

class OutputParser {
  OutputParser(this._receivedResults);
  bool expectSources = true;

  StreamController<Result> _receivedResults;
  List<String> _receivedSources;

  String _boundaryKey;
  bool _readingSources;

  void listener(String s) {
    if (_boundaryKey == null) {
      const String RESULT_OUTPUT_SPACE = 'result ';
      if (s.startsWith(RESULT_OUTPUT_SPACE)) {
        _boundaryKey = s.substring(RESULT_OUTPUT_SPACE.length);
      }
      _readingSources = false;
      _receivedSources?.clear();
      return;
    }

    if (s.startsWith(_boundaryKey)) {
      // First boundaryKey separates compiler output from list of sources
      // (if we expect list of sources, which is indicated by receivedSources
      // being not null)
      if (expectSources && !_readingSources) {
        _readingSources = true;
        return;
      }
      // Second boundaryKey indicates end of frontend server response
      expectSources = true;
      _receivedResults.add(Result(
          s.length > _boundaryKey.length
              ? s.substring(_boundaryKey.length + 1)
              : null,
          _receivedSources));
      _boundaryKey = null;
    } else {
      if (_readingSources) {
        if (_receivedSources == null) {
          _receivedSources = <String>[];
        }
        _receivedSources.add(s);
      }
    }
  }
}
