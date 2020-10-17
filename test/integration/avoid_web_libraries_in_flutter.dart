// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('avoid_web_libraries_in_flutter', () {
    final currentOut = outSink;
    final collectingOut = CollectingSink();
    setUp(() {
      exitCode = 0;
      outSink = collectingOut;
    });
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    test('no pubspec', () async {
      await cli.runLinter([
        'test/_data/avoid_web_libraries_in_flutter/no_pubspec',
        '--rules=avoid_web_libraries_in_flutter',
      ], LinterOptions());
      expect(collectingOut.trim(),
          contains('1 file analyzed, 0 issues found, in'));
      expect(exitCode, 0);
    });

    test('non flutter app', () async {
      await cli.runLinter([
        'test/_data/avoid_web_libraries_in_flutter/non_flutter_app',
        '--rules=avoid_web_libraries_in_flutter',
      ], LinterOptions());
      expect(collectingOut.trim(),
          contains('2 files analyzed, 0 issues found, in'));
      expect(exitCode, 0);
    });

    test('non web app', () async {
      await cli.runLinter([
        'test/_data/avoid_web_libraries_in_flutter/non_web_app',
        '--rules=avoid_web_libraries_in_flutter',
      ], LinterOptions());
      expect(collectingOut.trim(),
          contains('3 files analyzed, 3 issues found, in'));
      expect(exitCode, 1);
    });

    test('web app', () async {
      await cli.runLinter([
        'test/_data/avoid_web_libraries_in_flutter/web_app',
        '--rules=avoid_web_libraries_in_flutter',
      ], LinterOptions());
      expect(collectingOut.trim(),
          contains('2 files analyzed, 3 issues found, in'));
      expect(exitCode, 1);
    });

    test('web plugin', () async {
      await cli.runLinter([
        'test/_data/avoid_web_libraries_in_flutter/web_plugin',
        '--rules=avoid_web_libraries_in_flutter',
      ], LinterOptions());
      expect(collectingOut.trim(),
          contains('2 files analyzed, 0 issues found, in'));
      expect(exitCode, 0);
    });
  });
}
