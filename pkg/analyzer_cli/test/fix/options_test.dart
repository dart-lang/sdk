// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_cli/src/fix/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_context.dart';

main() {
  group('Options', () {
    TestContext context;

    String p(String filePath) => context.convertPath(filePath);

    Options parse(List<String> args,
        {bool dryRun = false,
        String errorOut,
        int exitCode,
        bool force = false,
        String normalOut,
        List<String> targetSuffixes,
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
      expect(context.stdout.toString(),
          normalOut != null ? contains(normalOut) : isEmpty);
      if (exitCode != null) {
        expect(actualExitCode, exitCode, reason: 'exit code');
        return null;
      } else {
        expect(actualExitCode, isNull, reason: 'exit code');
      }
      expect(options.dryRun, dryRun);
      expect(options.force, force);
      expect(options.verbose, verbose);
      expect(path.isAbsolute(options.sdkPath), isTrue, reason: options.sdkPath);
      for (String target in options.targets) {
        expect(target, isNotNull);
        expect(path.isAbsolute(target), isTrue, reason: '$target');
      }
      if (targetSuffixes != null) {
        for (String suffix in targetSuffixes) {
          expectContains(options.targets, suffix);
        }
      }
      return options;
    }

    setUp(() {
      context = new TestContext();
    });

    test('dryRun', () {
      parse(['--dry-run', 'foo'], dryRun: true, targetSuffixes: ['foo']);
    });

    test('force', () {
      parse(['--force', 'foo'], force: true, targetSuffixes: ['foo']);
    });

    test('invalid option', () {
      parse(['--foo'],
          errorOut: 'Could not find an option named "foo"', exitCode: 15);
    });

    test('invalid target', () {
      parse(['foo.dart'],
          errorOut: 'Expected directory, but found', exitCode: 15);
    });

    test('simple', () {
      parse(['foo'], targetSuffixes: ['foo']);
    });

    test('two targets', () {
      parse([p('one/foo'), p('two/bar')],
          targetSuffixes: [p('one/foo'), p('two/bar')]);
    });

    test('verbose', () {
      parse(['--verbose', 'foo'], verbose: true, normalOut: 'Targets:');
    });
  });
}

void expectOneFileTarget(Options options, String fileName) {
  expect(options.targets, hasLength(1));
  final target = options.targets[0];
  expect(target.endsWith(fileName), isTrue);
}

void expectContains(Iterable<String> collection, String suffix) {
  for (String elem in collection) {
    if (elem.endsWith(suffix)) {
      return;
    }
  }
  fail('Expected one of $collection\n  to end with "$suffix"');
}
