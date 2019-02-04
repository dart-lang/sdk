// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartfix/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_context.dart';

main() {
  TestContext context;
  TestLogger logger;

  setUp(() {
    context = new TestContext();
    logger = new TestLogger();
  });

  String p(String filePath) => context.convertPath(filePath);

  Options parse(
    List<String> args, {
    String errorOut,
    int exitCode,
    bool force = false,
    List<String> includeFixes = const <String>[],
    List<String> excludeFixes = const <String>[],
    bool listFixes = false,
    String normalOut,
    bool requiredFixes = false,
    bool overwrite = false,
    List<String> targetSuffixes,
    bool verbose = false,
  }) {
    Options options;
    int actualExitCode;
    try {
      options = Options.parse(args, context: context, logger: logger);
    } on TestExit catch (e) {
      actualExitCode = e.code;
    }
    expect(logger.stderrBuffer.toString(),
        errorOut != null ? contains(errorOut) : isEmpty);
    expect(logger.stdoutBuffer.toString(),
        normalOut != null ? contains(normalOut) : isEmpty);
    if (exitCode != null) {
      expect(actualExitCode, exitCode, reason: 'exit code');
      return null;
    } else {
      expect(actualExitCode, isNull, reason: 'exit code');
    }
    expect(options.force, force);
    expect(options.requiredFixes, requiredFixes);
    expect(options.overwrite, overwrite);
    expect(options.listFixes, listFixes);
    expect(options.includeFixes, includeFixes);
    expect(options.excludeFixes, excludeFixes);
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

  test('exclude fix', () {
    parse(['--exclude', 'c', '--exclude', 'd', 'foo'],
        excludeFixes: ['c', 'd'], targetSuffixes: ['foo']);
  });

  test('force', () {
    parse(['--force', 'foo'], force: true, targetSuffixes: ['foo']);
  });

  test('help', () {
    parse(['--help'], errorOut: 'Display this help message', exitCode: 1);
  });

  test('include fix', () {
    parse(['--include', 'a', '--include', 'b', 'foo'],
        includeFixes: ['a', 'b'], targetSuffixes: ['foo']);
  });

  test('invalid option', () {
    parse(['--foo'],
        errorOut: 'Could not find an option named "foo"', exitCode: 15);
  });

  test('invalid option no logger', () {
    try {
      Options.parse(['--foo'], context: context);
      fail('Expected exception');
    } on TestExit catch (e) {
      expect(e.code, 15, reason: 'exit code');
    }
  });

  test('invalid target', () {
    parse(['foo.dart'],
        errorOut: 'Expected directory, but found', exitCode: 15);
  });

  test('list fixes', () {
    parse(['--list'], errorOut: 'Display this help message', listFixes: true);
  });

  test('overwrite', () {
    parse(['--overwrite', 'foo'], overwrite: true, targetSuffixes: ['foo']);
  });

  test('required fixes', () {
    parse(['--required', 'foo'], requiredFixes: true);
  });

  test('simple', () {
    parse(['foo'], targetSuffixes: ['foo']);
  });

  test('two targets', () {
    parse([p('one/foo'), p('two/bar')],
        targetSuffixes: [p('one/foo'), p('two/bar')]);
  });

  test('verbose', () {
    parse(['--verbose', 'foo'], verbose: true);
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
