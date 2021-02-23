// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../experiment_util.dart';
import '../utils.dart';

Future<void> main() async {
  final experiments = await experimentsWithValidation();
  group('test', () => defineTest(experiments), timeout: longTimeout);
}

void defineTest(List<Experiment> experiments) {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();

    final result = p.runSync(['test', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, startsWith('''
Runs tests in this package.

Usage: pub run test [files or directories...]
'''));
    expect(result.stderr, isEmpty);
  });

  test('dart help test', () {
    p = project();

    final result = p.runSync(['help', 'test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests in this package'));
    expect(result.stderr, isEmpty);
  });

  test('no pubspec.yaml', () {
    p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    var result = p.runSync(['test']);

    expect(result.stderr, isEmpty);
    expect(result.stdout, '''
No pubspec.yaml file found - run this command in your project folder.
''');
    expect(result.exitCode, 65);

    var resultHelp = p.runSync(['test', '--help']);

    expect(resultHelp.stderr, isEmpty);
    expect(resultHelp.stdout, '''
No pubspec.yaml file found - run this command in your project folder.

Run tests in this package.

Usage: dart test [arguments]


Run "dart help" to see global options.
''');
    expect(resultHelp.exitCode, 65);
  });

  test('runs test', () {
    p = project();
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    expect(1,1);
  });
}
''');

    // An implicit `pub get` will happen.
    final result = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.exitCode, 0);
  });

  test('no package:test dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('pubspec.yaml', '''
name: ${p.name}
environment:
  sdk: '>=2.10.0 <3.0.0'
''');
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    expect(1,1);
  });
}
''');

    final result = p.runSync(['test']);
    expect(result.exitCode, 65);
    expect(
      result.stdout,
      contains('You need to add a dev_dependency on package:test'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 65);

    final resultPubAdd = p.runSync(['pub', 'add', 'test']);

    expect(resultPubAdd.exitCode, 0);
    final result2 = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result2.stderr, isEmpty);
    expect(result2.stdout, contains('All tests passed!'));
    expect(result2.exitCode, 0);
  });

  test('has package:test dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('test/foo_test.dart', '''
$dartVersionFilePrefix2_9

import 'package:test/test.dart';

void main() {
  test('', () {
    print('hello world');
  });
}
''');

    final result = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.stderr, isEmpty);
  });

  group('--enable-experiment', () {
    ProcessResult runTestWithExperimentFlag(String flag) {
      return p.runSync([
        if (flag != null) flag,
        'test',
        '--no-color',
        '--reporter',
        'expanded',
      ]);
    }

    void expectSuccess(String flag) {
      final result = runTestWithExperimentFlag(flag);
      expect(result.stdout, contains('feature enabled'),
          reason: 'stderr: ${result.stderr}');
      expect(result.exitCode, 0,
          reason: 'stdout: ${result.stdout} stderr: ${result.stderr}');
    }

    void expectFailure(String flag) {
      final result = runTestWithExperimentFlag(flag);
      expect(result.exitCode, isNot(0));
    }

    for (final experiment in experiments) {
      test(experiment.name, () {
        final currentSdk = Version.parse(Platform.version.split(' ').first);
        p = project(
            mainSrc: experiment.validation,
            sdkConstraint: VersionConstraint.compatibleWith(currentSdk));
        p.file('test/experiment_test.dart', '''
import 'package:dartdev_temp/main.dart' as imported;
import 'package:test/test.dart';

void main() {
  test('testing feature', () {
    imported.main();
  });
}
''');
        if (experiment.enabledIn != null) {
          // The experiment has been released - enabling it should have no effect.
          expectSuccess(null);
          expectSuccess('--enable-experiment=${experiment.name}');
        } else {
          expectFailure(null);
          expectFailure('--enable-experiment=no-${experiment.name}');
          expectSuccess('--enable-experiment=${experiment.name}');
        }
      });
    }
  });
}
