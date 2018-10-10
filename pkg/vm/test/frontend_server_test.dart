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

Future<int> main() async {
  group('basic', () {
    final CompilerInterface compiler = new _MockedCompiler();

    test('train with mocked compiler completes', () async {
      await starter(<String>['--train'], compiler: compiler);
    });
  });

  group('batch compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();
    when(compiler.compile(any, any, generator: anyNamed('generator')))
        .thenAnswer((_) => new Future.value(true));

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
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
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
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
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
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      int counter = 1;
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0],
            equals('server${counter++}.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        compileCalled.sendPort.send(true);
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
    final CompilerInterface compiler = new _MockedCompiler();
    when(compiler.compile(any, any, generator: anyNamed('generator')))
        .thenAnswer((_) => new Future.value(true));

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental'
    ];

    test('recompile few files', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: null))
          .thenAnswer((Invocation invocation) {
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
        await compiler.recompileDelta(filename: null),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('recompile few files with new entrypoint', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: 'file2.dart'))
          .thenAnswer((Invocation invocation) {
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
        await compiler.recompileDelta(filename: 'file2.dart'),
      ]);
      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    test('accept', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort acceptCalled = new ReceivePort();
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
          new StreamController<List<int>>();
      final ReceivePort resetCalled = new ReceivePort();
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
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: null))
          .thenAnswer((Invocation invocation) {
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
        await compiler.recompileDelta(filename: null),
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

    test('compile then accept', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      ReceivePort receivedResult = new ReceivePort();

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

      final _MockedIncrementalCompiler generator =
          new _MockedIncrementalCompiler();
      when(generator.initialized).thenAnswer((_) => false);
      when(generator.compile())
          .thenAnswer((_) => new Future<Component>.value(new Component()));
      when(generator.compile(entryPoint: anyNamed("entryPoint")))
          .thenAnswer((_) => new Future<Component>.value(new Component()));
      final _MockedBinaryPrinterFactory printerFactory =
          new _MockedBinaryPrinterFactory();
      when(printerFactory.newBinaryPrinter(any))
          .thenReturn(new _MockedBinaryPrinter());
      Future<int> result = starter(
        args,
        compiler: null,
        input: inputStreamController.stream,
        output: ioSink,
        generator: generator,
        binaryPrinterFactory: printerFactory,
      );

      inputStreamController.add('compile file1.dart\n'.codeUnits);
      await receivedResult.first;
      inputStreamController.add('accept\n'.codeUnits);
      receivedResult = new ReceivePort();
      inputStreamController.add('recompile def\nfile1.dart\ndef\n'.codeUnits);
      await receivedResult.first;

      inputStreamController.add('quit\n'.codeUnits);
      expect(await result, 0);
      inputStreamController.close();
    });

    group('compile with output path', () {
      final CompilerInterface compiler = new _MockedCompiler();
      when(compiler.compile(any, any, generator: anyNamed('generator')))
          .thenAnswer((_) => new Future.value(true));

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
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      StreamController<String> receivedResults = new StreamController<String>();

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
            receivedResults.add(s.length > boundaryKey.length
                ? s.substring(boundaryKey.length + 1)
                : null);
            boundaryKey = null;
          }
        }
      });

      Future<int> result =
          starter(args, input: streamController.stream, output: ioSink);
      streamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);

          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          expect(result.errorsCount, equals(0));
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
          streamController.add(
              'compile-expression abc\n2+2\nabc\nabc\n${file.uri}\n\n\n'
                  .codeUnits);
          count += 1;
        } else if (count == 1) {
          // Previous request should have failed because isStatic was blank
          expect(outputFilenameAndErrorCount, isNull);

          streamController.add(
              'compile-expression abc\n2+2\nabc\nabc\n${file.uri}\n\nfalse\n'
                  .codeUnits);
          count += 1;
        } else if (count == 2) {
          // Second request is to 'compile-expression', which results in
          // kernel file with a function that wraps compiled expression.
          expect(outputFilenameAndErrorCount, isNotNull);
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);

          expect(result.errorsCount, equals(0));
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          streamController.add('compile foo.bar\n'.codeUnits);
          count += 1;
        } else {
          expect(count, 3);
          // Third request is to 'compile' non-existent file, that should fail.
          expect(outputFilenameAndErrorCount, isNotNull);
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);
          expect(result.errorsCount, greaterThan(0));

          streamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
    });

    test('compile expression when delta is rejected', () async {
      var fileLib = new File('${tempDir.path}/lib.dart')..createSync();
      fileLib.writeAsStringSync("foo() => 42;\n");
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("import 'lib.dart'; main1() => print(foo);\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      StreamController<String> receivedResults = new StreamController<String>();

      String boundaryKey;
      stdoutStreamController.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String s) {
        print(s);
        const String RESULT_OUTPUT_SPACE = 'result ';
        if (boundaryKey == null) {
          if (s.startsWith(RESULT_OUTPUT_SPACE)) {
            boundaryKey = s.substring(RESULT_OUTPUT_SPACE.length);
          }
        } else {
          if (s.startsWith(boundaryKey)) {
            receivedResults.add(s.length > boundaryKey.length
                ? s.substring(boundaryKey.length + 1)
                : null);
            boundaryKey = null;
          }
        }
      });

      final Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        if (count == 0) {
          // First request was to 'compile', which resulted in full kernel file.
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);

          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          expect(result.errorsCount, equals(0));
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
          expect(outputFilenameAndErrorCount, isNotNull);
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);
          print(outputFilenameAndErrorCount);

          expect(result.errorsCount, equals(0));
          File outputFile = new File(result.filename);
          expect(outputFile.existsSync(), equals(true));
          expect(outputFile.lengthSync(), isPositive);

          file.writeAsStringSync("import 'lib.dart'; main() => foo();\n");
          inputStreamController.add('recompile ${file.path} abc\n'
              '${file.path}\n'
              'abc\n'
              .codeUnits);

          count += 1;
        } else if (count == 2) {
          // Third request was to recompile the script after renaming a function.
          expect(outputFilenameAndErrorCount, isNotNull);
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);
          expect(result.errorsCount, equals(0));

          inputStreamController.add('reject\n'.codeUnits);
          count += 1;
        } else if (count == 3) {
          // Fourth request was to reject the compilation results.
          inputStreamController.add(
              'compile-expression abc\nmain1\nabc\nabc\n${file.uri}\n\ntrue\n'
                  .codeUnits);
          count += 1;
        } else {
          expect(count, 4);
          // Fifth request was to 'compile-expression' that references original
          // function, which should still be successful.
          expect(outputFilenameAndErrorCount, isNotNull);
          CompilationResult result =
              new CompilationResult.parse(outputFilenameAndErrorCount);
          expect(result.errorsCount, equals(0));
          inputStreamController.add('quit\n'.codeUnits);
        }
      });

      expect(await result, 0);
      inputStreamController.close();
    }, timeout: Timeout.factor(100));

    test('recompile request keeps incremental output dill filename', () async {
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      StreamController<String> receivedResults = new StreamController<String>();

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
            receivedResults.add(s.substring(boundaryKey.length + 1));
            boundaryKey = null;
          }
        }
      });
      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        CompilationResult result =
            new CompilationResult.parse(outputFilenameAndErrorCount);
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(dillFile.existsSync(), equals(true));
          expect(result.filename, dillFile.path);
          expect(result.errorsCount, 0);
          count += 1;
          inputStreamController.add('accept\n'.codeUnits);
          var file2 = new File('${tempDir.path}/bar.dart')..createSync();
          file2.writeAsStringSync("main() {}\n");
          inputStreamController.add('recompile ${file2.path} abc\n'
              '${file2.path}\n'
              'abc\n'
              .codeUnits);
        } else {
          expect(count, 1);
          // Second request is to 'recompile', which results in incremental
          // kernel file.
          var dillIncFile = new File('${dillFile.path}.incremental.dill');
          expect(result.filename, dillIncFile.path);
          expect(result.errorsCount, 0);
          expect(dillIncFile.existsSync(), equals(true));
          inputStreamController.add('quit\n'.codeUnits);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('unsafe-package-serialization', () async {
      // Package A.
      var file = new File('${tempDir.path}/pkgA/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA() {}");

      // Package B.
      file = new File('${tempDir.path}/pkgB/.packages')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA: ../pkgA");
      file = new File('${tempDir.path}/pkgB/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgB_a() {}");
      file = new File('${tempDir.path}/pkgB/b.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgA/a.dart';"
          "pkgB_b() { pkgA(); }");

      // Application.
      file = new File('${tempDir.path}/app/.packages')
        ..createSync(recursive: true);
      file.writeAsStringSync("pkgA:../pkgA\n"
          "pkgB:../pkgB");

      // Entry point A uses both package A and B.
      file = new File('${tempDir.path}/app/a.dart')
        ..createSync(recursive: true);
      file.writeAsStringSync("import 'package:pkgB/b.dart';"
          "import 'package:pkgB/a.dart';"
          "appA() { pkgB_a(); pkgB_b(); }");

      // Entry point B uses only package B.
      var fileB = new File('${tempDir.path}/app/B.dart')
        ..createSync(recursive: true);
      fileB.writeAsStringSync("import 'package:pkgB/a.dart';"
          "appB() { pkgB_a(); }");

      // Other setup.
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));

      // First compile app entry point A.
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--unsafe-package-serialization',
      ];

      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      StreamController<String> receivedResults = new StreamController<String>();

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
            receivedResults.add(s.substring(boundaryKey.length + 1));
            boundaryKey = null;
          }
        }
      });
      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        CompilationResult result =
            new CompilationResult.parse(outputFilenameAndErrorCount);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 0);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            inputStreamController.add('reset\n'.codeUnits);

            inputStreamController.add('recompile ${fileB.path} abc\n'
                '${fileB.path}\n'
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
            component.libraries
                    .where((l) =>
                        l.importUri.toString() == "package:pkgB/a.dart" ||
                        l.fileUri.toString().contains(fileB.path))
                    .length ==
                2;

            // Verifiable (together with the platform file).
            component =
                loadComponentFromBinary(platformKernel.toFilePath(), component);
            verifyComponent(component);
        }
      });
      expect(await result, 0);
      inputStreamController.close();
    });

    test('compile and recompile report non-zero error count', () async {
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() { foo(); bar(); }\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}'
      ];

      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final StreamController<List<int>> stdoutStreamController =
          new StreamController<List<int>>();
      final IOSink ioSink = new IOSink(stdoutStreamController.sink);
      StreamController<String> receivedResults = new StreamController<String>();

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
            receivedResults.add(s.substring(boundaryKey.length + 1));
            boundaryKey = null;
          }
        }
      });
      Future<int> result =
          starter(args, input: inputStreamController.stream, output: ioSink);
      inputStreamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        CompilationResult result =
            new CompilationResult.parse(outputFilenameAndErrorCount);
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(result.filename, dillFile.path);
            expect(result.errorsCount, 2);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            var file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { baz(); }\n");
            inputStreamController.add('recompile ${file2.path} abc\n'
                '${file2.path}\n'
                'abc\n'
                .codeUnits);
            break;
          case 1:
            var dillIncFile = new File('${dillFile.path}.incremental.dill');
            expect(result.filename, dillIncFile.path);
            expect(result.errorsCount, 1);
            count += 1;
            inputStreamController.add('accept\n'.codeUnits);
            var file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { }\n");
            inputStreamController.add('recompile ${file2.path} abc\n'
                '${file2.path}\n'
                'abc\n'
                .codeUnits);
            break;
          case 2:
            var dillIncFile = new File('${dillFile.path}.incremental.dill');
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
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      new File('${tempDir.path}/.packages')
        ..createSync()
        ..writeAsStringSync("\n");
      var dillFile = new File('${tempDir.path}/app.dill');
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

    test('compile and produce deps file', () async {
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      var depFile = new File('${tempDir.path}/the depfile');
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
      var dillFile = new File('${tempDir.path}/full.dill');
      var incrementalDillFile = new File('${tempDir.path}/incremental.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--output-incremental-dill=${incrementalDillFile.path}'
      ];
      File dart2js = new File.fromUri(
          Platform.script.resolve("../../../pkg/compiler/bin/dart2js.dart"));
      expect(dart2js.existsSync(), equals(true));
      File dart2jsOtherFile = new File.fromUri(Platform.script
          .resolve("../../../pkg/compiler/lib/src/compiler.dart"));
      expect(dart2jsOtherFile.existsSync(), equals(true));

      int libraryCount = -1;
      int sourceCount = -1;

      List<List<int>> compiledKernels = <List<int>>[];
      for (int serverCloses = 0; serverCloses < 2; ++serverCloses) {
        print("Restart #$serverCloses");
        final StreamController<List<int>> inputStreamController =
            new StreamController<List<int>>();
        final StreamController<List<int>> stdoutStreamController =
            new StreamController<List<int>>();
        final IOSink ioSink = new IOSink(stdoutStreamController.sink);
        StreamController<String> receivedResults =
            new StreamController<String>();

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
              receivedResults.add(s.substring(boundaryKey.length + 1));
              boundaryKey = null;
            }
          }
        });

        Future<int> result =
            starter(args, input: inputStreamController.stream, output: ioSink);
        inputStreamController.add('compile ${dart2js.path}\n'.codeUnits);
        int count = 0;
        receivedResults.stream.listen((String outputFilenameAndErrorCount) {
          int delim = outputFilenameAndErrorCount.lastIndexOf(' ');
          expect(delim > 0, equals(true));
          String outputFilename =
              outputFilenameAndErrorCount.substring(0, delim);
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
    }, timeout: new Timeout.factor(8));
  });
  return 0;
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
  String filename;
  int errorsCount;

  CompilationResult.parse(String filenameAndErrorCount) {
    int delim = filenameAndErrorCount.lastIndexOf(' ');
    expect(delim > 0, equals(true));
    filename = filenameAndErrorCount.substring(0, delim);
    errorsCount = int.parse(filenameAndErrorCount.substring(delim + 1).trim());
  }
}
