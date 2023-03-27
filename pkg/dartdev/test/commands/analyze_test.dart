// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/analysis_server.dart';
import 'package:dartdev/src/commands/analyze.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('analysisError', defineAnalysisError, timeout: longTimeout);
  group('analyze', defineAnalyze, timeout: longTimeout);
}

const String _analyzeDescriptionText = 'Analyze Dart code in a directory.';

const String _analyzeUsageText =
    'Usage: dart analyze [arguments] [<directory>]';

const String _analyzeVerboseUsageText =
    'Usage: dart [vm-options] analyze [arguments] [<directory>]';

const String _unusedImportAnalysisOptions = '''
analyzer:
  errors:
    # Increase the severity of several hints.
    unused_import: warning
''';

const String _unusedImportCodeSnippet = '''
import 'dart:convert';

void main() {
  print('hello world');
}
''';

const String _todoAsWarningAnalysisOptions = '''
analyzer:
  errors:
    # Increase the severity of TODOs.
    todo: warning
    fixme: warning
''';

const String _todoAsWarningCodeSnippet = '''
void main() {
  // TODO: Implement this
  // FIXME: Fix this
}
''';

/// The exit code of the analysis server when the highest severity issue is a
/// warning.
const int _warningExitCode = 2;

void defineAnalysisError() {
  group('contextMessages', () {
    test('none', () {
      var error = AnalysisError({});
      expect(error.contextMessages, isEmpty);
    });
    test('one', () {
      var error = AnalysisError({
        'contextMessages': [<String, dynamic>{}],
      });
      expect(error.contextMessages, hasLength(1));
    });
    test('two', () {
      var error = AnalysisError({
        'contextMessages': [<String, dynamic>{}, <String, dynamic>{}],
      });
      expect(error.contextMessages, hasLength(2));
    });
  });

  group('sorting', () {
    test('severity', () {
      var errors = <AnalysisError>[
        AnalysisError({
          'severity': 'INFO',
          'location': {
            'file': 'a.dart',
          }
        }),
        AnalysisError({
          'severity': 'WARNING',
          'location': {
            'file': 'a.dart',
          }
        }),
        AnalysisError({
          'severity': 'ERROR',
          'location': {
            'file': 'a.dart',
          }
        })
      ];

      errors.sort();

      expect(errors, hasLength(3));
      expect(errors[0].isError, isTrue);
      expect(errors[1].isWarning, isTrue);
      expect(errors[2].isInfo, isTrue);
    });

    test('file', () {
      var errors = <AnalysisError>[
        AnalysisError({
          'severity': 'INFO',
          'location': {
            'file': 'c.dart',
          }
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {
            'file': 'b.dart',
          }
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {
            'file': 'a.dart',
          }
        })
      ];

      errors.sort();

      expect(errors, hasLength(3));
      expect(errors[0].file, equals('a.dart'));
      expect(errors[1].file, equals('b.dart'));
      expect(errors[2].file, equals('c.dart'));
    });

    test('offset', () {
      var errors = <AnalysisError>[
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 8}
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 6}
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 4}
        })
      ];

      errors.sort();

      expect(errors, hasLength(3));
      expect(errors[0].offset, equals(4));
      expect(errors[1].offset, equals(6));
      expect(errors[2].offset, equals(8));
    });

    test('message', () {
      var errors = <AnalysisError>[
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 8},
          'message': 'C'
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 6},
          'message': 'B'
        }),
        AnalysisError({
          'severity': 'INFO',
          'location': {'file': 'a.dart', 'offset': 4},
          'message': 'A'
        })
      ];

      errors.sort();

      expect(errors, hasLength(3));
      expect(errors[0].message, equals('A'));
      expect(errors[1].message, equals('B'));
      expect(errors[2].message, equals('C'));
    });
  });
}

void defineAnalyze() {
  late TestProject p;

  test('--help', () async {
    p = project();
    var result = await p.runAnalyze(['--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(_analyzeDescriptionText));
    expect(result.stdout, contains(_analyzeUsageText));
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.runAnalyze(['--help', '--verbose']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains(_analyzeDescriptionText));
    expect(result.stdout, contains(_analyzeVerboseUsageText));
  });

  group('multiple items', () {
    late TestProject secondProject;

    test('folder and file', () async {
      p = project(mainSrc: "int get foo => 'str';\n");
      secondProject = project(mainSrc: "int get foo => 'str';\n");
      var result = await p.runAnalyze([p.dirPath, secondProject.mainPath]);

      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('A value of type '));
      expect(result.stdout, contains('lib${path.separator}main.dart:1:16 '));
      expect(result.stdout, contains('return_of_invalid_type'));
      expect(result.stdout, contains('2 issues found.'));
    });

    test('two folders', () async {
      p = project(mainSrc: "int get foo => 'str';\n");
      secondProject = project(mainSrc: "int get foo => 'str';\n");
      var result = await p.runAnalyze([p.dirPath, secondProject.dirPath]);

      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('A value of type '));
      expect(result.stdout, contains('main.dart:1:16 '));
      expect(result.stdout, contains('return_of_invalid_type'));
      expect(result.stdout, contains('2 issues found.'));
    });
  });

  test('no such directory', () async {
    p = project();
    var result = await p.runAnalyze(['/no/such/dir1/']);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr,
        contains("Directory or file doesn't exist: /no/such/dir1/"));
    expect(result.stderr, contains(_analyzeUsageText));
  });

  test('current working directory', () async {
    p = project(mainSrc: 'int get foo => 1;\n');

    var result = await p.runAnalyze([], workingDir: p.dirPath);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No issues found!'));
  });

  group('single directory', () {
    test('no errors', () async {
      p = project(mainSrc: 'int get foo => 1;\n');
      var result = await p.runAnalyze([p.dirPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('No issues found!'));
    });

    test('one error', () async {
      p = project(mainSrc: "int get foo => 'str';\n");
      var result = await p.runAnalyze([p.dirPath]);

      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('A value of type '));
      expect(result.stdout, contains('lib${path.separator}main.dart:1:16 '));
      expect(result.stdout, contains('return_of_invalid_type'));
      expect(result.stdout, contains('1 issue found.'));
    });

    test('two errors', () async {
      p = project(mainSrc: "int get foo => 'str';\nint get bar => 'str';\n");
      var result = await p.runAnalyze([p.dirPath]);

      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('2 issues found.'));
    });
  });

  group('single file', () {
    test('no errors', () async {
      p = project(mainSrc: 'int get foo => 1;\n');
      var result = await p.runAnalyze([p.mainPath]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('No issues found!'));
    });

    test('one error', () async {
      p = project(mainSrc: "int get foo => 'str';\n");
      var result = await p.runAnalyze([p.mainPath]);

      expect(result.exitCode, 3);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('A value of type '));
      expect(result.stdout, contains('main.dart:1:16 '));
      expect(result.stdout, contains('return_of_invalid_type'));
      expect(result.stdout, contains('1 issue found.'));
    });
  });

  test('warning --fatal-warnings', () async {
    p = project(
        mainSrc: _unusedImportCodeSnippet,
        analysisOptions: _unusedImportAnalysisOptions);
    var result = await p.runAnalyze(['--fatal-warnings', p.dirPath]);

    expect(result.exitCode, equals(2));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('warning implicit --fatal-warnings', () async {
    p = project(
        mainSrc: _unusedImportCodeSnippet,
        analysisOptions: _unusedImportAnalysisOptions);
    var result = await p.runAnalyze([p.dirPath]);

    expect(result.exitCode, equals(2));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('warning --no-fatal-warnings', () async {
    p = project(
        mainSrc: _unusedImportCodeSnippet,
        analysisOptions: _unusedImportAnalysisOptions);
    var result = await p.runAnalyze(['--no-fatal-warnings', p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('info implicit no --fatal-infos', () async {
    p = project(
      mainSrc: 'var x = 1; var y = x?.isEven;',
      analysisOptions: r'''
analyzer:
  errors:
    INVALID_NULL_AWARE_OPERATOR: info
''',
    );
    var result = await p.runAnalyze([p.dirPath]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('info --fatal-infos', () async {
    p = project(
      mainSrc: 'var x = 1; var y = x?.isEven;',
      analysisOptions: r'''
analyzer:
  errors:
    INVALID_NULL_AWARE_OPERATOR: info
''',
    );
    var result = await p.runAnalyze(['--fatal-infos', p.dirPath]);

    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('1 issue found.'));
  });

  test('TODOs hidden by default', () async {
    p = project(
      mainSrc: _todoAsWarningCodeSnippet,
    );
    var result = await p.runAnalyze([p.dirPath]);

    expect(result.exitCode, equals(0));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No issues found!'));
  });

  test('TODOs shown if > INFO', () async {
    p = project(
      mainSrc: _todoAsWarningCodeSnippet,
      analysisOptions: _todoAsWarningAnalysisOptions,
    );
    var result = await p.runAnalyze([p.dirPath]);

    expect(result.exitCode, equals(_warningExitCode));
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('lib${path.separator}main.dart:2:6 '));
    expect(result.stdout, contains('TODO: Implement this - todo'));
    expect(result.stdout, contains('lib${path.separator}main.dart:3:6 '));
    expect(result.stdout, contains('FIXME: Fix this - fixme'));
    expect(result.stdout, contains('2 issues found.'));
  });

  test('--sdk-path value does not exist', () async {
    p = project();
    var result = await p.runAnalyze(['--sdk-path=bad']);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('Invalid Dart SDK path: bad'));
    expect(result.stderr, contains(_analyzeUsageText));
  });

  test('--sdk-path', () async {
    var sdkPath = sdk.sdkPath;
    p = project();
    var result = await p.runAnalyze(['--sdk-path=$sdkPath']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('No issues found!'));
    expect(result.stderr, isEmpty);
  });

  test('--enable-experiment with a bad experiment', () async {
    p = project();
    var result = await p.runAnalyze(['--enable-experiment=bad']);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains("Unknown experiment(s): 'bad'"));
  });

  test('--enable-experiment with a non-experimental feature', () async {
    p = project();
    var result = await p.runAnalyze(['--enable-experiment=records']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('No issues found!'));
    expect(result.stderr, contains("'records' is now enabled by default"));
  });

  test('--verbose', () async {
    p = project(mainSrc: '''
int f() {
  var result = one + 2;
  var one = 1;
  return result;
}''');
    var result = await p.runAnalyze(['--verbose', p.dirPath]);

    expect(result.exitCode, 3);
    expect(result.stderr, isEmpty);
    var stdout = result.stdout;
    expect(stdout, contains("The declaration of 'one' is here"));
    expect(
        stdout, contains('Try moving the declaration to before the first use'));
    expect(stdout, contains('https://dart.dev'));
    expect(stdout, contains('referenced_before_declaration'));
  });

  group('--packages', () {
    test('existing', () async {
      final foo = project(name: 'foo');
      foo.file('lib${path.separator}foo.dart', 'var my_foo = 0;');

      p = project(mainSrc: '''
import 'package:foo/foo.dart';
void f() {
  my_foo;
}''');
      p.file('my_packages.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "foo",
      "rootUri": "file://${foo.dirPath}",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''');
      var result = await p.runAnalyze([
        '--packages=${p.findFile('my_packages.json')!.path}',
        p.dirPath,
      ]);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('No issues found!'));
    });

    test('not existing', () async {
      p = project();
      var result = await p.runAnalyze([
        '--packages=no.such.file',
        p.dirPath,
      ]);

      expect(result.exitCode, 64);
      expect(result.stderr, contains("The file doesn't exist: no.such.file"));
      expect(result.stderr, contains(_analyzeUsageText));
    });
  });

  test('--cache', () async {
    var cache = project(name: 'cache');

    p = project(mainSrc: 'var v = 0;');
    var result = await p.runAnalyze([
      '--cache=${cache.dirPath}',
      p.mainPath,
    ]);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No issues found!'));
    expect(cache.findDirectory('.analysis-driver'), isNotNull);
  });

  group('display mode', () {
    final sampleInfoJson = {
      'severity': 'INFO',
      'type': 'TODO',
      'code': 'dead_code',
      'location': {
        'endLine': 16,
        'endColumn': 12,
        'file': 'lib/test.dart',
        'offset': 362,
        'length': 72,
        'startLine': 15,
        'startColumn': 4
      },
      'message': 'Foo bar baz.',
      'hasFix': false,
    };
    final fullDiagnosticJson = {
      'severity': 'ERROR',
      'type': 'COMPILE_TIME_ERROR',
      'location': {
        'file': 'lib/test.dart',
        'offset': 19,
        'length': 1,
        'startLine': 2,
        'startColumn': 9
      },
      'message':
          "Local variable 's' can't be referenced before it is declared.",
      'correction':
          "Try moving the declaration to before the first use, or renaming the local variable so that it doesn't hide a name from an enclosing scope.",
      'code': 'referenced_before_declaration',
      'url': 'https:://dart.dev/diagnostics/referenced_before_declaration',
      'contextMessages': [
        {
          'message': "The declaration of 's' is on line 3.",
          'location': {
            'file': 'lib/test.dart',
            'offset': 29,
            'length': 1,
            'startLine': 3,
            'startColumn': 7
          }
        }
      ],
      'hasFix': false
    };

    test('default', () {
      final logger = TestLogger(false);
      final errors = [AnalysisError(sampleInfoJson)];

      AnalyzeCommand.emitDefaultFormat(logger, errors);

      expect(logger.stderrBuffer, isEmpty);
      final stdout = logger.stdoutBuffer.toString().trim();
      expect(stdout, contains('info'));
      expect(stdout, contains('lib${path.separator}test.dart:15:4'));
      expect(stdout, contains('Foo bar baz.'));
      expect(stdout, contains('dead_code'));
    });

    group('json', () {
      test('short', () {
        final logger = TestLogger(false);
        final errors = [AnalysisError(sampleInfoJson)];

        AnalyzeCommand.emitJsonFormat(logger, errors, null);

        expect(logger.stderrBuffer, isEmpty);
        final stdout = logger.stdoutBuffer.toString().trim();
        expect(
            stdout,
            '{"version":1,"diagnostics":[{"code":"dead_code","severity":"INFO",'
            '"type":"TODO","location":{"file":"lib/test.dart","range":{'
            '"start":{"offset":362,"line":15,"column":4},"end":{"offset":434,'
            '"line":16,"column":12}}},"problemMessage":"Foo bar baz."}]}');
      });
      test('full', () {
        final logger = TestLogger(false);
        final errors = [AnalysisError(fullDiagnosticJson)];

        AnalyzeCommand.emitJsonFormat(logger, errors, null);

        expect(logger.stderrBuffer, isEmpty);
        final stdout = logger.stdoutBuffer.toString().trim();
        expect(
            stdout,
            '{"version":1,"diagnostics":[{'
            '"code":"referenced_before_declaration","severity":"ERROR",'
            '"type":"COMPILE_TIME_ERROR","location":{"file":"lib/test.dart",'
            '"range":{"start":{"offset":19,"line":2,"column":9},"end":{'
            '"offset":20,"line":null,"column":null}}},"problemMessage":'
            '"Local variable \'s\' can\'t be referenced before it is declared.",'
            '"correctionMessage":"Try moving the declaration to before the'
            ' first use, or renaming the local variable so that it doesn\'t hide'
            ' a name from an enclosing scope.","contextMessages":[{"location":{'
            '"file":"lib/test.dart","range":{"start":{"offset":29,"line":3,'
            '"column":7},"end":{"offset":30,"line":null,"column":null}}},'
            '"message":"The declaration of \'s\' is on line 3."}],'
            '"documentation":'
            '"https:://dart.dev/diagnostics/referenced_before_declaration"}]}');
      });
    });

    test('machine', () {
      final logger = TestLogger(false);
      final errors = [AnalysisError(sampleInfoJson)];

      AnalyzeCommand.emitMachineFormat(logger, errors);

      expect(logger.stderrBuffer, isEmpty);
      expect(
        logger.stdoutBuffer.toString().trim(),
        'INFO|TODO|DEAD_CODE|lib/test.dart|15|4|72|Foo bar baz.',
      );
    });
  });
}

class TestLogger implements Logger {
  final stdoutBuffer = StringBuffer();

  final stderrBuffer = StringBuffer();

  @override
  final bool isVerbose;

  TestLogger(this.isVerbose);

  @override
  Ansi get ansi => Ansi(false);

  @override
  void flush() {}

  @override
  Progress progress(String message) {
    return SimpleProgress(this, message);
  }

  @override
  void stderr(String message) {
    stderrBuffer.writeln(message);
  }

  @override
  void stdout(String message) {
    stdoutBuffer.writeln(message);
  }

  @override
  void trace(String message) {
    if (isVerbose) {
      stdoutBuffer.writeln(message);
    }
  }

  @override
  void write(String message) {
    stdoutBuffer.write(message);
  }

  @override
  void writeCharCode(int charCode) {
    stdoutBuffer.writeCharCode(charCode);
  }
}
