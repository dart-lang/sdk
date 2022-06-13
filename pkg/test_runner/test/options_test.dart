// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

import 'package:test_runner/src/configuration.dart';
import 'package:test_runner/src/options.dart';

void main() {
  testDefaults();
  testOptions();
  testValidation();
}

void testDefaults() {
  // TODO(rnystrom): Test other options.
  var configuration = parseConfiguration([]);
  Expect.equals(Progress.compact, configuration.progress);
  Expect.equals(NnbdMode.legacy, configuration.nnbdMode);
}

void testOptions() {
  // TODO(rnystrom): Test other options.
  var configurations = parseConfigurations(['--mode=debug,release']);
  Expect.equals(2, configurations.length);
  Expect.equals(Mode.debug, configurations[0].mode);
  Expect.equals(Mode.release, configurations[1].mode);

  var configuration = parseConfiguration(['--nnbd=weak']);
  Expect.equals(NnbdMode.weak, configuration.nnbdMode);

  // Filter invalid configurations when not passing a named configuration.
  configurations = parseConfigurations(['--arch=simarm', '--system=android']);
  Expect.isEmpty(configurations);

  // Special handling for *-options.
  configuration = parseConfiguration([
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
}

void testValidation() {
  // TODO(rnystrom): Test other options.
  expectValidationError(
      ['--timeout=notint'], 'Integer value expected for option "--timeout".');
  expectValidationError(
      ['--timeout=1,2'], 'Integer value expected for option "--timeout".');

  expectValidationError(['--progress=unknown'],
      '"unknown" is not an allowed value for option "progress".');
  // Don't allow multiple.
  expectValidationError(['--progress=compact,silent'],
      '"compact,silent" is not an allowed value for option "progress".');

  expectValidationError(['--nnbd=unknown'],
      '"unknown" is not an allowed value for option "nnbd".');
  // Don't allow multiple.
  expectValidationError(['--nnbd=weak,strong'],
      '"weak,strong" is not an allowed value for option "nnbd".');

  // Don't allow invalid named configurations.
  expectValidationError(['-ninvalid-vm-android-simarm'],
      'The named configuration "invalid-vm-android-simarm" is invalid.');
}

TestConfiguration parseConfiguration(List<String> arguments) {
  var configurations = parseConfigurations(arguments);
  Expect.equals(1, configurations.length);
  return configurations.first;
}

List<TestConfiguration> parseConfigurations(List<String> arguments) {
  var parser = OptionsParser('pkg/test_runner/test/test_matrix.json');
  var configurations = parser.parse(arguments);

  // By default, without an explicit selector, you get two configurations, one
  // for observatory_ui, and one for all the other selectors. Discard the
  // observatory one to keep things simpler.
  configurations
      .removeWhere((config) => config.selectors.containsKey('observatory_ui'));
  return configurations;
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
