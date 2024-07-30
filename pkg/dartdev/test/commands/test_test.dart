// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import '../experiment_util.dart';
import '../utils.dart';

void main() {
  ensureRunFromSdkBinDart();

  final experiments = experimentsWithValidation();
  group('test', () => defineTest(experiments), timeout: longTimeout);
}

void defineTest(List<Experiment> experiments) {
  test('--help', () async {
    final p = project(pubspecExtras: {
      'dev_dependencies': {'test': 'any'}
    });

    final result = await p.run(['test', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, startsWith('''
Runs tests in this package.

Usage: dart test [files or directories...]
'''));
    expect(result.stderr, isEmpty);
  });

  test('dart help test', () async {
    final p = project(pubspecExtras: {
      'dev_dependencies': {'test': 'any'}
    });

    final result = await p.run(['help', 'test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: dart test [arguments]'));
    expect(result.stderr, isEmpty);
  });

  test('no pubspec.yaml', () async {
    final p = project(pubspecExtras: {
      'dev_dependencies': {'test': 'any'}
    });
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
    expect(resultHelp.stdout, contains('No pubspec.yaml file found'));
    expect(resultHelp.stdout, contains('Usage: dart test [arguments]'));
    expect(resultHelp.exitCode, 65);
  });

  test('runs test', () async {
    final p = project(pubspecExtras: {
      'dev_dependencies': {'test': 'any'}
    });
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
    final p = project(
      mainSrc: 'int get foo => 1;\n',
      pubspecExtras: {
        'dev_dependencies': {'test': 'any'}
      },
    );
    p.file('pubspec.yaml', '''
name: ${p.name}
environment:
  sdk: '>=2.12.0 <4.0.0'
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
    final p = project(
      mainSrc: 'int get foo => 1;\n',
      pubspecExtras: {
        'dev_dependencies': {'test': 'any'}
      },
    );
    p.file('test/foo_test.dart', '''
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

  test('implicitly passes --mark-main-isolate-as-system-isolate', () async {
    // --mark-main-isolate-as-system-isolate is necessary for DevTools to be
    // able to identify the correct root library.
    //
    // See https://github.com/flutter/flutter/issues/143170 for details.
    final p = project(
      mainSrc: 'int get foo => 1;\n',
      pubspecExtras: {
        'dev_dependencies': {'test': 'any'}
      },
    );
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    print('hello world');
  });
}
''');

    final vmServiceUriRegExp =
        RegExp(r'(http:\/\/127.0.0.1:\d*\/[\da-zA-Z-_]*=\/)');
    final process = await p.start(['test', '--pause-after-load']);
    final completer = Completer<Uri>();
    late StreamSubscription sub;
    sub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) async {
      if (line.contains(vmServiceUriRegExp)) {
        await sub.cancel();
        final httpUri = Uri.parse(
          vmServiceUriRegExp.firstMatch(line)!.group(0)!,
        );
        completer.complete(
          httpUri.replace(scheme: 'ws', path: '${httpUri.path}ws'),
        );
      }
    });

    final vmServiceUri = await completer.future;
    final vmService = await vmServiceConnectUri(vmServiceUri.toString());
    final vm = await vmService.getVM();
    expect(vm.systemIsolates!.where((e) => e.name == 'main'), isNotEmpty);
  });

  group('--enable-experiment', () {
    late TestProject p;
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
          sdkConstraint: VersionConstraint.compatibleWith(currentSdk),
          pubspecExtras: {
            'dev_dependencies': {'test': 'any'}
          },
        );
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

  test('workspace', () async {
    final p = project(
        sdkConstraint: VersionConstraint.parse('^3.5.0-0'),
        pubspecExtras: {
          'workspace': ['pkgs/a', 'pkgs/b']
        });
    p.file('pkgs/a/pubspec.yaml', '''
name: a
environment:
  sdk: ^3.5.0-0
resolution: workspace
dependencies:
  b:
  test: any
''');
    p.file('pkgs/b/pubspec.yaml', '''
name: b
environment:
  sdk: ^3.5.0-0
resolution: workspace
''');
    p.file('pkgs/a/test/a_test.dart', '''
import 'package:test/test.dart';
main() {
  test('works', () {
    print('testing package a');
  });
} 
''');
    p.file('pkgs/b/test/b_test.dart', '''
main() => throw('Test failure');
''');
    expect(
        await p.run(['test'], workingDir: path.join(p.dirPath, 'pkgs', 'a')),
        isA<ProcessResult>()
            .having((r) => r.stdout, 'stdout', contains('testing package a\n'))
            .having((r) => r.stderr, 'stderr', isEmpty)
            .having((r) => r.exitCode, 'exitCode', 0));
  });
}
