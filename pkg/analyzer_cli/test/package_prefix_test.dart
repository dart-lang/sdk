// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exitCode;

import 'package:analyzer_cli/src/driver.dart' show Driver, outSink, errorSink;
import 'package:analyzer_cli/src/options.dart' show ExitHandler, exitHandler;
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'utils.dart' show testDirectory;

void main() {
  group('--x-package-warnings-prefix', () {
    _Runner runner;

    setUp(() {
      runner = _Runner.setUp();
    });

    tearDown(() {
      runner.tearDown();
      runner = null;
    });

    test('shows only the hint whose package matches the prefix', () async {
      await runner.run2([
        '--packages',
        join(testDirectory, 'data', 'package_prefix', 'packagelist'),
        '--x-package-warnings-prefix=f',
        join(testDirectory, 'data', 'package_prefix', 'main.dart')
      ]);
      expect(runner.stdout, contains('1 hint found'));
      expect(runner.stdout, contains('Unused import'));
      expect(runner.stdout,
          contains(join('package_prefix', 'pkg', 'foo', 'foo.dart')));
      expect(runner.stdout, isNot(contains('bar.dart')));
    });
  });
}

class _Runner {
  final _stdout = StringBuffer();
  final _stderr = StringBuffer();

  final StringSink _savedOutSink;
  final StringSink _savedErrorSink;
  final int _savedExitCode;
  final ExitHandler _savedExitHandler;

  _Runner.setUp()
      : _savedOutSink = outSink,
        _savedErrorSink = errorSink,
        _savedExitHandler = exitHandler,
        _savedExitCode = exitCode {
    outSink = _stdout;
    errorSink = _stderr;
    exitHandler = (_) {};
  }

  String get stderr => _stderr.toString();

  String get stdout => _stdout.toString();

  Future<void> run2(List<String> args) async {
    await Driver().start(args);
    if (stderr.isNotEmpty) {
      fail('Unexpected output to stderr:\n$stderr');
    }
  }

  void tearDown() {
    outSink = _savedOutSink;
    errorSink = _savedErrorSink;
    exitCode = _savedExitCode;
    exitHandler = _savedExitHandler;
  }
}
