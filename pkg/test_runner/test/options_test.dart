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
}

void testValidation() {
  // TODO(rnystrom): Test other options.
  expectValidationError(
      ['--timeout=notint'], 'Integer value expected for option "--timeout".');
  expectValidationError(
      ['--timeout=1,2'], 'Integer value expected for option "--timeout".');

  expectValidationError(['--progress=unknown'],
      'Unknown value "unknown" for option "--progress".');
  // Don't allow multiple.
  expectValidationError(['--progress=compact,silent'],
      'Only a single value is allowed for option "--progress".');

  expectValidationError(
      ['--nnbd=unknown'], 'Unknown value "unknown" for option "--nnbd".');
  // Don't allow multiple.
  expectValidationError(['--nnbd=weak,strong'],
      'Only a single value is allowed for option "--nnbd".');
}

TestConfiguration parseConfiguration(List<String> arguments) {
  var configurations = parseConfigurations(arguments);
  Expect.equals(1, configurations.length);
  return configurations.first;
}

List<TestConfiguration> parseConfigurations(List<String> arguments) {
  var parser = OptionsParser();
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
    OptionsParser().parse(arguments);
    Expect.fail('Should have thrown an exception, but did not.');
  } on OptionParseException catch (exception) {
    Expect.equals(error, exception.message);
  } catch (exception) {
    Expect.fail('Wrong exception: $exception');
  }
}
