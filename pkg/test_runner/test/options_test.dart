// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:expect/expect.dart';

import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';

void main() {
  testDefaults();
  testOptions();
  testValidation();
  testSelectors();
}

void testDefaults() {
  // TODO(rnystrom): Test other options.
  var configuration = parseConfiguration([]);
  Expect.equals(Progress.line, configuration.progress);
}

void testOptions() {
  // TODO(rnystrom): Test other options.
  var configurations = parseConfigurations(['--mode=debug,release']);
  Expect.equals(2, configurations.length);
  Expect.equals(Mode.debug, configurations[0].mode);
  Expect.equals(Mode.release, configurations[1].mode);

  // Filter invalid configurations when not passing a named configuration.
  configurations = parseConfigurations(['--arch=simarm', '--system=android']);
  Expect.isEmpty(configurations);

  // Special handling for *-options.
  var configuration = parseConfiguration([
    '--dart2js-options=a b c',
    '--vm-options=d e f',
    '--shared-options=g h i'
  ]);
  Expect.listEquals(configuration.dart2jsOptions, ['a', 'b', 'c']);
  Expect.listEquals(configuration.vmOptions, ['d', 'e', 'f']);
  Expect.listEquals(configuration.sharedOptions,
      ['g', 'h', 'i', '-Dtest_runner.configuration=custom-configuration-1']);

  // Reproduction arguments.
  configurations = parseConfigurations([
    '--progress=status',
    '--report',
    '--time',
    '--silent-failures',
    '--write-results',
    '--write-logs',
    '--clean-exit',
    '-nvalid-dart2js-chrome,valid-dart2js-safari',
    '--reset-browser-configuration',
    '--no-batch',
    'web',
    '--copy-coredumps',
    '--chrome=third_party/browsers/chrome/chrome/google-chrome',
    '--output-directory=/path/to/dir',
  ]);
  Expect.equals(2, configurations.length);
  for (var configuration in configurations) {
    Expect.listEquals(
        ['-n', 'valid-dart2js-chrome,valid-dart2js-safari', '--no-batch'],
        configuration.reproducingArguments);
  }

  // Allow vm-aot
  configurations = parseConfigurations(['-nvm-aot']);
  Expect.equals(1, configurations.length);
  Expect.equals("dart_precompiled", configurations.first.runtime.name);
  Expect.equals("dartkp", configurations.first.compiler.name);
}

void testValidation() {
  // TODO(rnystrom): Test other options.
  expectValidationError(
      ['--timeout=notint'], 'Integer value expected for option "--timeout".');
  expectValidationError(
      ['--timeout=1,2'], 'Integer value expected for option "--timeout".');

  expectValidationError(['--progress=unknown'],
      '"unknown" is not an allowed value for option "--progress".');
  // Don't allow multiple.
  expectValidationError(['--progress=compact,silent'],
      '"compact,silent" is not an allowed value for option "--progress".');

  // Don't allow invalid named configurations.
  expectValidationError(['-ninvalid-vm-android-simarm'],
      'The named configuration "invalid-vm-android-simarm" is invalid.');
}

void testSelectors() {
  // Default suites.
  {
    final configuration = parseConfiguration([]);
    Expect.setEquals({
      'samples',
      'standalone',
      'corelib',
      'language',
      'vm',
      'utils',
      'lib',
      'kernel',
      'ffi',
    }, configuration.selectors.keys, "default suites");
  }

  // The test runner can run individual tests by being given the
  // complete relative path to the test file, relative to the
  // root of the Dart source checkout. The test runner parses
  // these paths, if they match a known test suite location,
  // and turns them into a suite name followed by a test path and name.
  final testPath = ['tests', 'language', 'subdir', 'some_test.dart']
      .join(Platform.pathSeparator);
  final co19Path = [
    'tests',
    'co19',
    'src',
    'subdir_1',
    'subdir_src',
    'some_co19_test'
  ].join(Platform.pathSeparator);
  final configuration = parseConfiguration(
      // Test arguments that include two test file paths and two
      // suite selectors, one with a pattern ending in .dart.
      // The final .dart is removed both from file paths and selector
      // patterns.
      ['vm', 'lib/a_legacy_test.dart', testPath, co19Path]);
  Expect.equals(
      'subdir/some_test', configuration.selectors['language']?.pattern);
  Expect.equals('subdir_1/subdir_src/some_co19_test',
      configuration.selectors['co19']?.pattern);
  Expect.equals('.?', configuration.selectors['vm']?.pattern);
  Expect.equals('a_legacy_test', configuration.selectors['lib']?.pattern);
}

TestConfiguration parseConfiguration(List<String> arguments) {
  var configurations = parseConfigurations(arguments);
  Expect.equals(1, configurations.length);
  return configurations.first;
}

List<TestConfiguration> parseConfigurations(List<String> arguments) {
  var parser = OptionsParser('pkg/test_runner/test/test_matrix.json');
  return parser.parse(arguments);
}

void expectValidationError(List<String> arguments, String error) {
  try {
    OptionsParser('pkg/test_runner/test/test_matrix.json').parse(arguments);
    Expect.fail('Should have thrown an exception, but did not.');
  } on OptionParseException catch (exception) {
    Expect.equals(error, exception.message);
  } catch (exception) {
    Expect.fail('Wrong exception: $exception');
  }
}
