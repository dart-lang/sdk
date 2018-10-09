// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_cli/src/fix/options.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import 'test_context.dart';

main() {
  group('Options', () {
    TestContext context;

    Options parse(List<String> args,
        {bool dryRun = false,
        String errorOut,
        int exitCode,
        bool verbose = false}) {
      Options options;
      int actualExitCode;
      try {
        options = Options.parse(args, context);
      } on TestExit catch (e) {
        actualExitCode = e.code;
      }
      expect(context.stderr.toString(),
          errorOut != null ? contains(errorOut) : isEmpty);
      expect(context.stdout.toString(), isEmpty);
      if (exitCode != null) {
        expect(actualExitCode, exitCode, reason: 'exit code');
        return null;
      } else {
        expect(actualExitCode, isNull, reason: 'exit code');
      }
      expect(options.dryRun, dryRun);
      expect(options.verbose, verbose);
      expect(pathos.isAbsolute(options.sdkPath), isTrue,
          reason: options.sdkPath);
      for (String target in options.targets) {
        expect(target, isNotNull);
        expect(pathos.isAbsolute(target), isTrue, reason: '$target');
      }
      for (String root in options.analysisRoots) {
        expect(root, isNotNull);
        expect(pathos.isAbsolute(root), isTrue);
      }
      return options;
    }

    setUp(() {
      context = new TestContext();
    });

    test('dryRun', () {
      final options = parse(['--dry-run', 'foo.dart'], dryRun: true);
      expectOneFileTarget(options, 'foo.dart');
    });

    test('invalid option', () {
      parse(['--foo'],
          errorOut: 'Could not find an option named "foo"', exitCode: 15);
    });

    test('simple', () {
      final options = parse(['foo.dart']);
      expectOneFileTarget(options, 'foo.dart');
    });

    test('two files in different directories', () {
      final options = parse([p('one/foo.dart'), p('two/bar.dart')]);
      expect(options.targets, hasLength(2));
      expectContains(options.targets, p('one/foo.dart'));
      expectContains(options.targets, p('two/bar.dart'));
      expect(options.analysisRoots, hasLength(2));
      expectContains(options.analysisRoots, 'one');
      expectContains(options.analysisRoots, 'two');
    });

    test('two files in overlapping directories', () {
      final options = parse([p('one/two/foo.dart'), p('one/bar.dart')]);
      expect(options.targets, hasLength(2));
      expectContains(options.targets, p('one/two/foo.dart'));
      expectContains(options.targets, p('one/bar.dart'));
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
  expect(pathos.context.isWithin(root, target), isTrue);
}

void expectContains(Iterable<String> collection, String suffix) {
  for (String elem in collection) {
    if (elem.endsWith(suffix)) {
      return;
    }
  }
  fail('Expected one of $collection\n  to end with "$suffix"');
}
