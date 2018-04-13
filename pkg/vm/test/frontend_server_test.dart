import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/src/arg_results.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/ast.dart' show Component;
import 'package:mockito/mockito.dart';
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
      expect(await starter(<String>['--train'], compiler: compiler), equals(0));
    });
  });

  group('batch compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();
    when(compiler.compile(any, any, generator: any)).thenReturn(true);

    test('compile from command line', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
      ];
      final int exitcode = await starter(args, compiler: compiler);
      expect(exitcode, equals(0));
      final List<ArgResults> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: any,
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['strong'], equals(false));
    });

    test('compile from command line (strong mode)', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--strong',
      ];
      final int exitcode = await starter(args, compiler: compiler);
      expect(exitcode, equals(0));
      final List<ArgResults> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: any,
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['strong'], equals(true));
      expect(capturedArgs.single['sync-async'], equals(false));
    });

    test('compile from command line (sync-async)', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--strong',
        '--sync-async',
      ];
      final int exitcode = await starter(args, compiler: compiler);
      expect(exitcode, equals(0));
      final List<ArgResults> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: any,
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['strong'], equals(true));
      expect(capturedArgs.single['sync-async'], equals(true));
    });

    test('compile from command line with link platform', () async {
      final List<String> args = <String>[
        'server.dart',
        '--sdk-root',
        'sdkroot',
        '--link-platform',
      ];
      final int exitcode = await starter(args, compiler: compiler);
      expect(exitcode, equals(0));
      final List<ArgResults> capturedArgs = verify(compiler.compile(
        argThat(equals('server.dart')),
        captureAny,
        generator: any,
      )).captured;
      expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
      expect(capturedArgs.single['link-platform'], equals(true));
      expect(capturedArgs.single['strong'], equals(false));
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
      when(compiler.compile(any, any, generator: any))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        expect(invocation.positionalArguments[1]['strong'], equals(false));
        compileCalled.sendPort.send(true);
      });

      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.close();
    });
  });

  group('interactive compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
    ];
    final List<String> strongArgs = <String>[
      '--sdk-root',
      'sdkroot',
      '--strong',
    ];

    test('compile one file', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      when(compiler.compile(any, any, generator: any))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        expect(invocation.positionalArguments[1]['strong'], equals(false));
        compileCalled.sendPort.send(true);
      });

      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.close();
    });

    test('compile one file (strong mode)', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      when(compiler.compile(any, any, generator: any))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0], equals('server.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        expect(invocation.positionalArguments[1]['strong'], equals(true));
        compileCalled.sendPort.send(true);
      });

      final int exitcode = await starter(
        strongArgs,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('compile server.dart\n'.codeUnits);
      await compileCalled.first;
      inputStreamController.close();
    });

    test('compile few files', () async {
      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final ReceivePort compileCalled = new ReceivePort();
      int counter = 1;
      when(compiler.compile(any, any, generator: any))
          .thenAnswer((Invocation invocation) {
        expect(invocation.positionalArguments[0],
            equals('server${counter++}.dart'));
        expect(
            invocation.positionalArguments[1]['sdk-root'], equals('sdkroot'));
        expect(invocation.positionalArguments[1]['strong'], equals(false));
        compileCalled.sendPort.send(true);
      });

      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('compile server1.dart\n'.codeUnits);
      streamController.add('compile server2.dart\n'.codeUnits);
      await compileCalled.first;
      streamController.close();
    });
  });

  group('interactive incremental compile with mocked compiler', () {
    final CompilerInterface compiler = new _MockedCompiler();
    when(compiler.compile(any, any, generator: any)).thenReturn(true);

    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental'
    ];

    test('recompile few files', () async {
      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: null))
          .thenAnswer((Invocation invocation) {
        recompileCalled.sendPort.send(true);
      });
      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController
          .add('recompile abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        compiler.invalidate(Uri.base.resolve('file1.dart')),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        await compiler.recompileDelta(filename: null),
      ]);
      streamController.close();
    });

    test('recompile few files with new entrypoint', () async {
      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: 'file2.dart'))
          .thenAnswer((Invocation invocation) {
        recompileCalled.sendPort.send(true);
      });
      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add(
          'recompile file2.dart abc\nfile1.dart\nfile2.dart\nabc\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        compiler.invalidate(Uri.base.resolve('file1.dart')),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        await compiler.recompileDelta(filename: 'file2.dart'),
      ]);
      streamController.close();
    });

    test('accept', () async {
      final StreamController<List<int>> inputStreamController =
          new StreamController<List<int>>();
      final ReceivePort acceptCalled = new ReceivePort();
      when(compiler.acceptLastDelta()).thenAnswer((Invocation invocation) {
        acceptCalled.sendPort.send(true);
      });
      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('accept\n'.codeUnits);
      await acceptCalled.first;
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
      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: inputStreamController.stream,
      );
      expect(exitcode, equals(0));
      inputStreamController.add('reset\n'.codeUnits);
      await resetCalled.first;
      inputStreamController.close();
    });

    test('compile then recompile', () async {
      final StreamController<List<int>> streamController =
          new StreamController<List<int>>();
      final ReceivePort recompileCalled = new ReceivePort();

      when(compiler.recompileDelta(filename: null))
          .thenAnswer((Invocation invocation) {
        recompileCalled.sendPort.send(true);
      });
      final int exitcode = await starter(
        args,
        compiler: compiler,
        input: streamController.stream,
      );
      expect(exitcode, equals(0));
      streamController.add('compile file1.dart\n'.codeUnits);
      streamController.add('accept\n'.codeUnits);
      streamController
          .add('recompile def\nfile2.dart\nfile3.dart\ndef\n'.codeUnits);
      await recompileCalled.first;

      verifyInOrder(<void>[
        await compiler.compile('file1.dart', any, generator: any),
        compiler.acceptLastDelta(),
        compiler.invalidate(Uri.base.resolve('file2.dart')),
        compiler.invalidate(Uri.base.resolve('file3.dart')),
        await compiler.recompileDelta(filename: null),
      ]);
      streamController.close();
    });
  });

  group('interactive incremental compile with mocked IKG', () {
    final List<String> args = <String>[
      '--sdk-root',
      'sdkroot',
      '--incremental',
    ];

    test('compile then accept', () async {
      final StreamController<List<int>> streamController =
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
      final _MockedBinaryPrinterFactory printerFactory =
          new _MockedBinaryPrinterFactory();
      when(printerFactory.newBinaryPrinter(any))
          .thenReturn(new _MockedBinaryPrinter());
      final int exitcode = await starter(
        args,
        compiler: null,
        input: streamController.stream,
        output: ioSink,
        generator: generator,
        binaryPrinterFactory: printerFactory,
      );
      expect(exitcode, equals(0));

      streamController.add('compile file1.dart\n'.codeUnits);
      await receivedResult.first;
      streamController.add('accept\n'.codeUnits);
      receivedResult = new ReceivePort();
      streamController.add('recompile def\nfile1.dart\ndef\n'.codeUnits);
      await receivedResult.first;

      streamController.close();
    });

    group('compile with output path', () {
      final CompilerInterface compiler = new _MockedCompiler();
      when(compiler.compile(any, any, generator: any)).thenReturn(true);

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
        final int exitcode = await starter(args, compiler: compiler);
        expect(exitcode, equals(0));
        final List<ArgResults> capturedArgs = verify(compiler.compile(
          argThat(equals('server.dart')),
          captureAny,
          generator: any,
        )).captured;
        expect(capturedArgs.single['sdk-root'], equals('sdkroot'));
        expect(capturedArgs.single['strong'], equals(false));
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
      tempDir = systemTempDir.createTempSync('foo');
    });

    tearDown(() {
      tempDir.delete(recursive: true);
    });

    test('recompile request keeps incremental output dill filename', () async {
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() {}\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--strong',
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
            receivedResults.add(s.substring(boundaryKey.length + 1));
            boundaryKey = null;
          }
        }
      });
      int exitcode =
          await starter(args, input: streamController.stream, output: ioSink);
      expect(exitcode, equals(0));
      streamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      Completer<bool> allDone = new Completer<bool>();
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        int delim = outputFilenameAndErrorCount.lastIndexOf(' ');
        expect(delim > 0, equals(true));
        String outputFilename = outputFilenameAndErrorCount.substring(0, delim);
        int errorsCount =
            int.parse(outputFilenameAndErrorCount.substring(delim + 1).trim());
        if (count == 0) {
          // First request is to 'compile', which results in full kernel file.
          expect(dillFile.existsSync(), equals(true));
          expect(outputFilename, dillFile.path);
          expect(errorsCount, 0);
          count += 1;
          streamController.add('accept\n'.codeUnits);
          var file2 = new File('${tempDir.path}/bar.dart')..createSync();
          file2.writeAsStringSync("main() {}\n");
          streamController.add('recompile ${file2.path} abc\n'
              '${file2.path}\n'
              'abc\n'
              .codeUnits);
        } else {
          expect(count, 1);
          // Second request is to 'recompile', which results in incremental
          // kernel file.
          var dillIncFile = new File('${dillFile.path}.incremental.dill');
          expect(outputFilename, dillIncFile.path);
          expect(errorsCount, 0);
          expect(dillIncFile.existsSync(), equals(true));
          allDone.complete(true);
        }
      });
      expect(await allDone.future, true);
    });

    test('compile and recompile report non-zero error count', () async {
      var file = new File('${tempDir.path}/foo.dart')..createSync();
      file.writeAsStringSync("main() { foo(); bar(); }\n");
      var dillFile = new File('${tempDir.path}/app.dill');
      expect(dillFile.existsSync(), equals(false));
      final List<String> args = <String>[
        '--sdk-root=${sdkRoot.toFilePath()}',
        '--strong',
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
            receivedResults.add(s.substring(boundaryKey.length + 1));
            boundaryKey = null;
          }
        }
      });
      int exitcode =
          await starter(args, input: streamController.stream, output: ioSink);
      expect(exitcode, equals(0));
      streamController.add('compile ${file.path}\n'.codeUnits);
      int count = 0;
      Completer<bool> allDone = new Completer<bool>();
      receivedResults.stream.listen((String outputFilenameAndErrorCount) {
        int delim = outputFilenameAndErrorCount.lastIndexOf(' ');
        expect(delim > 0, equals(true));
        String outputFilename = outputFilenameAndErrorCount.substring(0, delim);
        int errorsCount =
            int.parse(outputFilenameAndErrorCount.substring(delim + 1).trim());
        switch (count) {
          case 0:
            expect(dillFile.existsSync(), equals(true));
            expect(outputFilename, dillFile.path);
            expect(errorsCount, 2);
            count += 1;
            streamController.add('accept\n'.codeUnits);
            var file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { baz(); }\n");
            streamController.add('recompile ${file2.path} abc\n'
                '${file2.path}\n'
                'abc\n'
                .codeUnits);
            break;
          case 1:
            var dillIncFile = new File('${dillFile.path}.incremental.dill');
            expect(outputFilename, dillIncFile.path);
            expect(errorsCount, 1);
            count += 1;
            streamController.add('accept\n'.codeUnits);
            var file2 = new File('${tempDir.path}/bar.dart')..createSync();
            file2.writeAsStringSync("main() { }\n");
            streamController.add('recompile ${file2.path} abc\n'
                '${file2.path}\n'
                'abc\n'
                .codeUnits);
            break;
          case 2:
            var dillIncFile = new File('${dillFile.path}.incremental.dill');
            expect(outputFilename, dillIncFile.path);
            expect(errorsCount, 0);
            expect(dillIncFile.existsSync(), equals(true));
            allDone.complete(true);
        }
      });
      expect(await allDone.future, true);
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
        '--strong',
        '--incremental',
        '--platform=${platformKernel.path}',
        '--output-dill=${dillFile.path}',
        '--packages=test-scheme:///.packages',
        '--filesystem-root=${tempDir.path}',
        '--filesystem-scheme=test-scheme',
        'test-scheme:///foo.dart'
      ];
      int exitcode = await starter(args);
      expect(exitcode, equals(0));
    });
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
