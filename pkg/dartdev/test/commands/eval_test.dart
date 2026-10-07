// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:dartdev/dartdev.dart';
import 'package:dartdev/src/commands/run.dart';
import 'package:dartdev/src/eval_packages.dart';
import 'package:dartdev/src/utils.dart';
import 'package:dartdev/src/vm_interop_handler.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('eval option parsing', () {
    test(
      'globalDartdevOptionsParser does not include -e, -P / --package-constraint, or --offline',
      () {
        final parser = globalDartdevOptionsParser();
        expect(parser.options.containsKey(evalOption), isFalse);
        expect(parser.options.containsKey(packageConstraintOption), isFalse);
        expect(parser.options.containsKey(offlineOption), isFalse);
        expect(parser.options.containsKey('package'), isFalse);
        expect(parser.options.containsKey('with'), isFalse);
      },
    );

    test(
      'RunCommand argParser includes -e, -P / --package-constraint, --offline',
      () {
        final runCmd = RunCommand();
        expect(runCmd.argParser.options.containsKey(evalOption), isTrue);
        expect(runCmd.argParser.options[evalOption]?.abbr, equals('e'));
        expect(
          runCmd.argParser.options.containsKey(packageConstraintOption),
          isTrue,
        );
        expect(
          runCmd.argParser.options[packageConstraintOption]?.abbr,
          equals('P'),
        );
        expect(runCmd.argParser.options.containsKey(offlineOption), isTrue);
        expect(runCmd.argParser.options.containsKey('package'), isFalse);
        expect(runCmd.argParser.options.containsKey('with'), isFalse);
      },
    );

    test(
      'RunCommand argParser accepts VM options after -P and -e while preserving script args',
      () {
        final runCmd = RunCommand();
        final parsed = runCmd.argParser.parse(const [
          '-P',
          'path',
          '--enable-asserts',
          '-e',
          'void main(List<String> args) { assert(args.isNotEmpty); }',
          '--define=foo=bar',
          'script_arg',
          '--script-flag',
        ]);
        expect(parsed.multiOption(packageConstraintOption), equals(['path']));
        expect(parsed.flag('enable-asserts'), isTrue);
        expect(parsed.multiOption('define'), equals(['foo=bar']));
        expect(
          parsed.option(evalOption),
          equals('void main(List<String> args) { assert(args.isNotEmpty); }'),
        );
        expect(parsed.rest, equals(['script_arg', '--script-flag']));
      },
    );

    test('RunCommand argParser parses -e, -P, --offline, and arguments', () {
      final runCmd = RunCommand();
      final results = runCmd.argParser.parse(const [
        '-P',
        'http',
        '--offline',
        '-e',
        'void main() {}',
        'arg1',
        'arg2',
      ]);
      expect(results.wasParsed(evalOption), isTrue);
      expect(results.option(evalOption), equals('void main() {}'));
      expect(results.wasParsed(packageConstraintOption), isTrue);
      expect(
        results.multiOption(packageConstraintOption),
        equals(const ['http']),
      );
      expect(results.wasParsed(offlineOption), isTrue);
      expect(results.flag(offlineOption), isTrue);
      expect(results.rest, equals(const ['arg1', 'arg2']));
    });
  });

  group('PackageUriExtension', () {
    test('isPackage correctly identifies valid package URIs', () {
      expect(Uri.parse('package:http/http.dart').isPackage, isTrue);
      expect(Uri.parse('package:path').isPackage, isTrue);
      expect(Uri.parse('package:').isPackage, isFalse);
      expect(Uri.parse('package:/').isPackage, isFalse);
      expect(Uri.parse('dart:io').isPackage, isFalse);
      expect(Uri.parse('file:///foo/bar.dart').isPackage, isFalse);
      expect(Uri.parse('https://example.com').isPackage, isFalse);
    });

    test('packageName extracts package name from package URIs', () {
      expect(
        Uri.parse('package:http/http.dart').packageName,
        equals('http'),
      );
      expect(
        Uri.parse('package:path').packageName,
        equals('path'),
      );
      expect(Uri.parse('package:').packageName, isNull);
      expect(Uri.parse('package:/').packageName, isNull);
      expect(Uri.parse('dart:io').packageName, isNull);
      expect(Uri.parse('file:///foo/bar.dart').packageName, isNull);
    });
  });

  group('EvalPackageResolver AST import extraction', () {
    test('extracts package imports using Dart AST parser', () {
      const code = '''
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show join;

// import 'package:commented_out/commented_out.dart';
/*
import 'package:block_commented/block.dart';
*/

void main() {
  const fakeImport = "import 'package:in_string/in_string.dart'";
  print(fakeImport);
}
''';
      final imports = EvalPackageResolver.extractPackageImports(code);
      expect(imports, equals(const {'http', 'path'}));
    });
  });

  group('EvalPackageResolver package config resolution', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dartdev_eval_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws StateError when localPackageConfig does not exist', () async {
      final nonexistent = path.join(tempDir.path, 'missing_config.json');
      await expectLater(
        EvalPackageResolver.resolvePackageConfig(
          'import "package:foo/foo.dart"; void main() {}',
          localPackageConfig: nonexistent,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Specified package configuration file does not exist'),
          ),
        ),
      );
    });

    test(
      'throws StateError when localPackageConfig has invalid JSON',
      () async {
        final invalidFile = File(path.join(tempDir.path, 'bad_config.json'))
          ..writeAsStringSync('{ malformed json');
        await expectLater(
          EvalPackageResolver.resolvePackageConfig(
            'import "package:foo/foo.dart"; void main() {}',
            localPackageConfig: invalidFile.path,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse package configuration file'),
            ),
          ),
        );
      },
    );

    test(
      'reuses localPackageConfig when no explicit constraints and packages present',
      () async {
        final configFile = File(path.join(tempDir.path, 'valid_config.json'))
          ..writeAsStringSync(
            jsonEncode({
              'configVersion': 2,
              'packages': [
                {'name': 'http', 'rootUri': 'file:///mock/http'},
              ],
            }),
          );

        final result = await EvalPackageResolver.resolvePackageConfig(
          'import "package:http/http.dart"; void main() {}',
          localPackageConfig: configFile.path,
        );

        expect(result, equals(configFile.path));
      },
    );

    test(
      'resolves ephemeral pub get on pre-release SDKs using -0 version suffix',
      () async {
        final mockPkgDir = Directory(path.join(tempDir.path, 'mock_pkg'))
          ..createSync(recursive: true);
        File(path.join(mockPkgDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: mock_pkg
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
''');
        Directory(path.join(mockPkgDir.path, 'lib')).createSync();
        File(
          path.join(mockPkgDir.path, 'lib', 'mock_pkg.dart'),
        ).writeAsStringSync('final int meaning = 42;\n');

        final result = await EvalPackageResolver.resolvePackageConfig(
          'import "package:mock_pkg/mock_pkg.dart"; void main() {}',
          packageConstraints: [
            'mock_pkg: {path: "${mockPkgDir.path.replaceAll(r'\', '/')}"}',
          ],
          offline: true,
        );

        expect(result, isNotNull);
        expect(File(result!).existsSync(), isTrue);
        final generatedPubspec = File(
          path.join(File(result).parent.parent.path, 'pubspec.yaml'),
        ).readAsStringSync();
        expect(generatedPubspec, contains(RegExp(r'sdk: "\^\d+\.\d+\.\d+-0"')));
      },
    );
  });

  group('RunCommand.runEval execution', () {
    late ReceivePort receivePort;
    late StreamController<List<Object?>> vmInteropEvents;

    setUp(() {
      vmInteropEvents = StreamController<List<Object?>>();
      receivePort = ReceivePort()
        ..listen((msg) {
          if (msg is List) {
            vmInteropEvents.add(msg);
          }
        });
      VmInteropHandler.initialize(receivePort.sendPort);
    });

    tearDown(() {
      receivePort.close();
      vmInteropEvents.close();
      VmInteropHandler.initialize(null);
    });

    test(
      'runEval invokes VmInteropHandler with data URI and useExecProcess',
      () async {
        const code = 'void main(List<String> args) { print("hello"); }';
        final runCmd = RunCommand();
        final args = runCmd.argParser.parse(
          const ['-e', code, 'arg1', 'arg2'],
        );

        final exitCode = await runCmd.runEval(args);
        expect(exitCode, equals(0));

        final message = await vmInteropEvents.stream.first;
        expect(message[0], equals(2));
        final scriptUri = Uri.parse(message[1] as String);
        expect(scriptUri.scheme, equals('data'));
        expect(scriptUri.data?.mimeType, equals(dartMimeType));
        expect(scriptUri.data?.contentAsString(encoding: utf8), equals(code));
        expect(message[5], equals(const ['arg1', 'arg2']));
      },
    );

    test(
      'runEval preserves multiline code verbatim without modification',
      () async {
        const multilineCode = '''
import 'dart:math';

class Calculator {
  int add(int a, int b) => a + b;
}

void main(List<String> args) {
  final calc = Calculator();
  print(calc.add(2, 3));
}
''';
        final runCmd = RunCommand();
        final args = runCmd.argParser.parse(const ['-e', multilineCode]);

        final exitCode = await runCmd.runEval(args);
        expect(exitCode, equals(0));

        final message = await vmInteropEvents.stream.first;
        expect(message[0], equals(2));
        final scriptUri = Uri.parse(message[1] as String);
        expect(scriptUri.scheme, equals('data'));
        expect(
          scriptUri.data?.contentAsString(encoding: utf8),
          equals(multilineCode),
        );
      },
    );

    test('runEval respects explicit --packages option', () async {
      const code = 'void main() {}';
      final runCmd = RunCommand();
      final args = runCmd.argParser.parse(const [
        '--packages=/custom/path/package_config.json',
        '-e',
        code,
      ]);

      final exitCode = await runCmd.runEval(args);
      expect(exitCode, equals(0));

      final message = await vmInteropEvents.stream.first;
      expect(message[0], equals(2));
      expect(message[3], equals('/custom/path/package_config.json'));
    });

    test('runEval returns errorExitCode when code is empty', () async {
      final runCmd = RunCommand();
      final args = runCmd.argParser.parse(const ['-e', '']);

      final exitCode = await runCmd.runEval(args);
      expect(exitCode, equals(RunCommand.errorExitCode));
    });
  });

  group('DartdevRunner top-level eval option rejection', () {
    test('raw dart -e throws UsageException', () async {
      const args = ['--suppress-analytics', '-e', 'void main() { print(1); }'];
      final runner = DartdevRunner(args);
      await expectLater(
        runner.run(args),
        throwsA(isA<UsageException>()),
      );
    });

    test('raw dart -P <pkg> throws UsageException', () async {
      const args = ['--suppress-analytics', '-P', 'path'];
      final runner = DartdevRunner(args);
      await expectLater(
        runner.run(args),
        throwsA(isA<UsageException>()),
      );
    });

    test('raw dart --eval throws UsageException', () async {
      const args = [
        '--suppress-analytics',
        '--eval',
        'void main() { print(1); }',
      ];
      final runner = DartdevRunner(args);
      await expectLater(
        runner.run(args),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('end-to-end process execution', () {
    test('dart -e exits with usage exit code 64', () async {
      final p = project();
      final result = await p.run(['-e', 'void main() {}']);
      expect(result.exitCode, equals(DartdevRunner.usageExitCode));
    });

    test(
      'dart run -e succeeds from a directory with no pubspec.yaml or package_config.json',
      () async {
        final emptyDir = Directory.systemTemp.createTempSync('eval_no_pkg_');
        addTearDown(() {
          if (emptyDir.existsSync()) {
            emptyDir.deleteSync(recursive: true);
          }
        });
        final p = project();
        final result = await p.run(
          ['run', '-e', 'void main() { print("hello_outside_package"); }'],
          workingDir: emptyDir.path,
        );
        expect(result.exitCode, equals(0), reason: 'stderr: ${result.stderr}');
        expect(result.stdout, contains('hello_outside_package'));
      },
    );

    test(
      'dart run enables assertions when --enable-asserts follows -e',
      () async {
        final p = project();
        final resultAfterE = await p.run([
          'run',
          '-e',
          'void main() { assert(false, "boom_after_e"); }',
          '--enable-asserts',
        ]);
        expect(resultAfterE.exitCode, isNot(equals(0)));
        expect(resultAfterE.stderr, contains('boom_after_e'));
      },
    );

    test(
      'dart run -e passes flags after -- separator to script args instead of VM',
      () async {
        final p = project();
        final result = await p.run([
          'run',
          '-e',
          r'void main(List<String> args) { assert(false); print("args=$args"); }',
          '--',
          '--enable-asserts',
        ]);
        expect(result.exitCode, equals(0), reason: 'stderr: ${result.stderr}');
        expect(result.stdout, contains('args=[--enable-asserts]'));
      },
    );
  }, timeout: longTimeout);
}
