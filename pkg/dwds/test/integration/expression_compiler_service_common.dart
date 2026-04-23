// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/sdk_configuration.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/services/expression_compiler_service.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

ExpressionCompilerService get service => _service!;
late ExpressionCompilerService? _service;

HttpServer get server => _server!;
late HttpServer? _server;

StreamController<String> get output => _output!;
late StreamController<String>? _output;

void testAll({required CompilerOptions compilerOptions}) {
  group('expression compiler service with fake asset server', () {
    final logger = Logger('ExpressionCompilerServiceTest');
    late Directory outputDir;

    Future<void> stop() async {
      await _service?.stop();
      await _server?.close();
      await _output?.close();
      _service = null;
      _server = null;
      _output = null;
    }

    setUp(() async {
      final systemTempDir = Directory.systemTemp;
      outputDir = systemTempDir.createTempSync('foo bar');
      final source = outputDir.uri.resolve('try.dart');
      final packages = outputDir.uri.resolve('package_config.json');
      final kernel = outputDir.uri.resolve('try.full.dill');
      // Expression compiler service does not need any extra assets
      // generated in the SDK, so we use the current SDK layout and
      // configuration.
      final executable = Platform.resolvedExecutable;
      // redirect logs for testing
      _output = StreamController<String>.broadcast();
      output.stream.listen(printOnFailure);

      configureLogWriter(
        customLogWriter: (level, message, {error, loggerName, stackTrace}) {
          final e = error == null ? '' : ': $error';
          final s = stackTrace == null ? '' : ':\n$stackTrace';
          output.add('[$level] $loggerName: $message$e$s');
        },
      );

      // start asset server
      _server = await startHttpServer('localhost');
      final port = server.port;

      // start expression compilation service
      Response assetHandler(request) =>
          Response(200, body: File.fromUri(kernel).readAsBytesSync());
      _service = ExpressionCompilerService(
        'localhost',
        port,
        verbose: false,
        sdkConfigurationProvider: const DefaultSdkConfigurationProvider(),
      );

      await service.initialize(compilerOptions);

      // setup asset server
      serveHttpRequests(server, assetHandler, (e, s) {
        logger.warning('Error serving requests', e, s);
      });

      // generate full dill
      File.fromUri(source)
        ..createSync()
        ..writeAsStringSync('''void main() {
          // breakpoint line
        }''');

      File.fromUri(packages)
        ..createSync()
        ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "try",
            "rootUri": "./",
            "packageUri": "./"
          }
        ]
      }
      ''');

      final args = [
        'compile',
        'js-dev',
        'try.dart',
        '-o',
        'try.js',
        '--experimental-output-compiled-kernel',
        '--multi-root',
        '${outputDir.uri}',
        '--multi-root-scheme',
        'org-dartlang-app',
        '--packages',
        packages.path,
      ];
      final process =
          await Process.start(
            executable,
            args,
            workingDirectory: outputDir.path,
          ).then((p) {
            transformToLines(p.stdout).listen(output.add);
            transformToLines(p.stderr).listen(output.add);
            return p;
          });
      expect(
        await process.exitCode,
        0,
        reason: 'failed running $executable with args $args',
      );
      expect(
        File.fromUri(kernel).existsSync(),
        true,
        reason: 'failed to create full dill',
      );
    });

    tearDown(() async {
      await stop();
      outputDir.deleteSync(recursive: true);
    });

    test('works with no errors', () async {
      expect(output.stream, neverEmits(contains('[SEVERE]')));
      expect(
        output.stream,
        emitsThrough(
          contains(
            '[INFO] ExpressionCompilerService: Updating dependencies...',
          ),
        ),
      );
      expect(
        output.stream,
        emitsThrough(
          contains('[INFO] ExpressionCompilerService: Updated dependencies.'),
        ),
      );
      expect(
        output.stream,
        emitsThrough(
          contains('[FINEST] ExpressionCompilerService: Compiling "true" at'),
        ),
      );
      expect(
        output.stream,
        emitsThrough(
          contains('[FINEST] ExpressionCompilerService: Compiled "true" to:'),
        ),
      );
      expect(
        output.stream,
        emitsThrough(contains('[INFO] ExpressionCompilerService: Stopped.')),
      );
      final result = await service.updateDependencies({
        'try': ModuleInfo('try.full.dill', 'try.dill'),
      });
      expect(result, true, reason: 'failed to update dependencies');

      final compilationResult = await service.compileExpressionToJs(
        '0',
        'org-dartlang-app:/try.dart',
        'org-dartlang-app:/try.dart',
        2,
        1,
        {},
        {},
        'try',
        'true',
      );

      expect(
        compilationResult,
        isA<ExpressionCompilationResult>()
            .having((r) => r.result, 'result', contains('return true;'))
            .having((r) => r.isError, 'isError', false),
      );

      await stop();
    });

    test('can evaluate multiple expressions', () async {
      expect(output.stream, neverEmits(contains('[SEVERE]')));
      expect(
        output.stream,
        emitsThrough(
          contains(
            '[INFO] ExpressionCompilerService: Updating dependencies...',
          ),
        ),
      );
      expect(
        output.stream,
        emitsThrough(
          contains('[INFO] ExpressionCompilerService: Updated dependencies.'),
        ),
      );

      expect(
        output.stream,
        emitsThrough(contains('[INFO] ExpressionCompilerService: Stopped.')),
      );
      final result = await service.updateDependencies({
        'try': ModuleInfo('try.full.dill', 'try.dill'),
      });
      expect(result, true, reason: 'failed to update dependencies');

      final compilationResult1 = await service.compileExpressionToJs(
        '0',
        'org-dartlang-app:/try.dart',
        'org-dartlang-app:/try.dart',
        2,
        1,
        {},
        {},
        'try',
        'true',
      );
      final compilationResult2 = await service.compileExpressionToJs(
        '0',
        'org-dartlang-app:/try.dart',
        'org-dartlang-app:/try.dart',
        2,
        1,
        {},
        {},
        'try',
        'false',
      );

      expect(
        compilationResult1,
        isA<ExpressionCompilationResult>()
            .having((r) => r.result, 'result', contains('return true;'))
            .having((r) => r.isError, 'isError', false),
      );

      expect(
        compilationResult2,
        isA<ExpressionCompilationResult>()
            .having((r) => r.result, 'result', contains('return false;'))
            .having((r) => r.isError, 'isError', false),
      );

      await stop();
    });

    test('can compile multiple expressions in parallel', () async {
      expect(output.stream, neverEmits(contains('[SEVERE]')));
      expect(
        output.stream,
        emitsThrough(
          contains(
            '[INFO] ExpressionCompilerService: Updating dependencies...',
          ),
        ),
      );
      expect(
        output.stream,
        emitsThrough(
          contains('[INFO] ExpressionCompilerService: Updated dependencies.'),
        ),
      );

      expect(
        output.stream,
        emitsThrough(contains('[INFO] ExpressionCompilerService: Stopped.')),
      );
      final result = await service.updateDependencies({
        'try': ModuleInfo('try.full.dill', 'try.dill'),
      });
      expect(result, true, reason: 'failed to update dependencies');

      final compilationResult1 = service.compileExpressionToJs(
        '0',
        'org-dartlang-app:/try.dart',
        'org-dartlang-app:/try.dart',
        2,
        1,
        {},
        {},
        'try',
        'true',
      );
      final compilationResult2 = service.compileExpressionToJs(
        '0',
        'org-dartlang-app:/try.dart',
        'org-dartlang-app:/try.dart',
        2,
        1,
        {},
        {},
        'try',
        'false',
      );

      final results = await Future.wait([
        compilationResult1,
        compilationResult2,
      ]);

      expect(
        results[0],
        isA<ExpressionCompilationResult>()
            .having((r) => r.result, 'result', contains('return true;'))
            .having((r) => r.isError, 'isError', false),
      );

      expect(
        results[1],
        isA<ExpressionCompilationResult>()
            .having((r) => r.result, 'result', contains('return false;'))
            .having((r) => r.isError, 'isError', false),
      );

      await stop();
    });
  });
}

Stream<String> transformToLines(Stream<List<int>> byteStream) {
  return byteStream
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter());
}
