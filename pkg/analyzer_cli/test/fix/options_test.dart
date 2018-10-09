// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_cli/src/fix/options.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

main() {
  group('Options', () {
    int lastExitHandlerCode;
    StringBuffer outStringBuffer = new StringBuffer();
    StringBuffer errorStringBuffer = new StringBuffer();

    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;
    ExitHandler savedExitHandler;

    Options parse(List<String> args,
        {bool dryRun = false, bool verbose = false, bool checkExists = false}) {
      final options = Options.parse(args, checkExists: checkExists);
      expect(errorStringBuffer.toString(), isEmpty);
      expect(outStringBuffer.toString(), isEmpty);
      expect(lastExitHandlerCode, isNull);
      expect(options.dryRun, dryRun);
      expect(options.verbose, verbose);
      expect(isAbsolute(options.sdkPath), isTrue, reason: options.sdkPath);
      for (String target in options.targets) {
        expect(target, isNotNull);
        expect(isAbsolute(target), isTrue, reason: '$target');
      }
      for (String root in options.analysisRoots) {
        expect(root, isNotNull);
        expect(isAbsolute(root), isTrue);
      }
      return options;
    }

    setUp(() {
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitHandler = exitHandler;
      savedExitCode = exitCode;
      exitHandler = (int code) {
        lastExitHandlerCode = code;
      };
      outSink = outStringBuffer;
      errorSink = errorStringBuffer;
    });

    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
      exitHandler = savedExitHandler;
    });

    test('dryRun', () {
      final options = parse(['--dry-run', 'foo.dart'], dryRun: true);
      expectOneFileTarget(options, 'foo.dart');
    });

    test('simple', () {
      final options = parse(['foo.dart']);
      expectOneFileTarget(options, 'foo.dart');
    });

    test('two files in different directories', () {
      final options = parse(['one/foo.dart', 'two/bar.dart']);
      expect(options.targets, hasLength(2));
      expectContains(options.targets, 'one/foo.dart');
      expectContains(options.targets, 'two/bar.dart');
      expect(options.analysisRoots, hasLength(2));
      expectContains(options.analysisRoots, 'one');
      expectContains(options.analysisRoots, 'two');
    });

    test('two files in overlapping directories', () {
      final options = parse(['one/two/foo.dart', 'one/bar.dart']);
      expect(options.targets, hasLength(2));
      expectContains(options.targets, 'one/two/foo.dart');
      expectContains(options.targets, 'one/bar.dart');
      expect(options.analysisRoots, hasLength(1));
      expectContains(options.analysisRoots, 'one');
    });

    test('two files in same directory', () {
      final options = parse(['foo.dart', 'bar.dart']);
      expect(options.targets, hasLength(2));
      expectContains(options.targets, 'foo.dart');
      expectContains(options.targets, 'bar.dart');
      expect(options.analysisRoots, hasLength(1));
    });

    test('verbose', () {
      final options = parse(['--verbose', 'foo.dart'], verbose: true);
      expectOneFileTarget(options, 'foo.dart');
    });
  });
}

void expectOneFileTarget(Options options, String fileName) {
  expect(options.targets, hasLength(1));
  final target = options.targets[0];
  expect(target.endsWith(fileName), isTrue);
  expect(options.analysisRoots, hasLength(1));
  final root = options.analysisRoots[0];
  expect(root.endsWith(fileName), isFalse);
  expect(context.isWithin(root, target), isTrue);
}

void expectContains(Iterable<String> collection, String suffix) {
  for (String elem in collection) {
    if (elem.endsWith(suffix)) {
      return;
    }
  }
  fail('Expected one of $collection\n  to end with "$suffix"');
}
