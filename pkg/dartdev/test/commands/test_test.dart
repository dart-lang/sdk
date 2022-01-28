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
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('--help', () async {
    p = project();

    final result = await p.run(['test', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, startsWith('''
Runs tests in this package.

Usage: dart test [files or directories...]
'''));
    expect(result.stderr, isEmpty);
  });

  test('dart help test', () async {
    p = project();

    final result = await p.run(['help', 'test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests for a project'));
    expect(result.stderr, isEmpty);
  });

  test('no pubspec.yaml', () async {
    p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    var result = await p.run(['test']);

    expect(result.stderr, isEmpty);
    expect(result.stdout, '''
No pubspec.yaml file found - run this command in your project folder.
''');
    expect(result.exitCode, 65);

    var resultHelp = await p.run(['test', '--help']);

    expect(resultHelp.stderr, isEmpty);
    expect(resultHelp.stdout, '''
No pubspec.yaml file found - run this command in your project folder.

Run tests for a project.

Usage: dart test [arguments]


Run "dart help" to see global options.
''');
    expect(resultHelp.exitCode, 65);
  });

  test('runs test', () async {
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
    final result =
        await p.run(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.exitCode, 0);
  });

  test('no package:test dependency', () async {
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

    final result = await p.run(['test']);
    expect(result.exitCode, 65);
    expect(
      result.stdout,
      contains('You need to add a dev_dependency on package:test'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 65);

    final resultPubAdd = await p.run(['pub', 'add', 'test']);

    expect(resultPubAdd.exitCode, 0);
    final result2 =
        await p.run(['test', '--no-color', '--reporter', 'expanded']);
    expect(result2.stderr, isEmpty);
    expect(result2.stdout, contains('All tests passed!'));
    expect(result2.exitCode, 0);
  });

  test('has package:test dependency', () async {
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

    final result =
        await p.run(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.stderr, isEmpty);
  });

  group('--enable-experiment', () {
    Future<ProcessResult> runTestWithExperimentFlag(String? flag) async {
      return await p.run([
        if (flag != null) flag,
        'test',
        '--no-color',
        '--reporter',
        'expanded',
      ]);
    }

    Future<void> expectSuccess(String? flag) async {
      final result = await runTestWithExperimentFlag(flag);
      expect(result.stdout, contains('feature enabled'),
          reason: 'stderr: ${result.stderr}');
      expect(result.exitCode, 0,
          reason: 'stdout: ${result.stdout} stderr: ${result.stderr}');
    }

    Future<void> expectFailure(String? flag) async {
      final result = await runTestWithExperimentFlag(flag);
      expect(result.exitCode, isNot(0));
    }

    for (final experiment in experiments) {
      test(experiment.name, () async {
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
          await expectSuccess(null);
          await expectSuccess('--enable-experiment=${experiment.name}');
        } else {
          await expectFailure(null);
          await expectFailure('--enable-experiment=no-${experiment.name}');
          await expectSuccess('--enable-experiment=${experiment.name}');
        }
      });
    }
  });
}
