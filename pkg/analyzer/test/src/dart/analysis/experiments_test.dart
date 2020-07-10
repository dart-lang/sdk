// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentsTest);
  });
}

@reflectiveTest
class ExperimentsTest {
  var knownFeatures = <String, ExperimentalFeature>{};

  ExperimentStatus fromStrings(List<String> flags) {
    return overrideKnownFeatures(
        knownFeatures, () => ExperimentStatus.fromStrings(flags));
  }

  List<bool> getFlags(ExperimentStatus status) {
    return getExperimentalFlags_forTesting(status);
  }

  List<ConflictingFlagLists> getValidateCombinationResult(
      List<String> flags1, List<String> flags2) {
    return overrideKnownFeatures(
        knownFeatures, () => validateFlagCombination(flags1, flags2).toList());
  }

  List<ValidationResult> getValidationResult(List<String> flags) {
    return overrideKnownFeatures(
        knownFeatures, () => validateFlags(flags).toList());
  }

  test_currentVersion() {
    // We don't care what the current version is, we just want to make sure that
    // it parses without error, and that it takes a simple 'major.minor' form.
    var currentVersion = ExperimentStatus.currentVersion;
    expect(currentVersion.patch, 0);
    expect(currentVersion.preRelease, isEmpty);
    expect(currentVersion.build, isEmpty);
  }

  test_fromStrings_conflicting_flags_disable_then_enable() {
    // Enable takes precedence because it's last
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['no-a', 'a'])), [true]);
  }

  test_fromStrings_conflicting_flags_enable_then_disable() {
    // Disable takes precedence because it's last
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['a', 'no-a'])), [false]);
  }

  test_fromStrings_default_values() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'b',
      firstSupportedVersion: '1.0.0',
    );
    expect(getFlags(fromStrings([])), [false, true]);
  }

  test_fromStrings_disable_disabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['no-a'])), [false]);
  }

  test_fromStrings_disable_enabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    expect(getFlags(fromStrings(['no-a'])), [false]);
  }

  test_fromStrings_enable_disabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['a'])), [true]);
  }

  test_fromStrings_enable_enabled_feature() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    expect(getFlags(fromStrings(['a'])), [true]);
  }

  test_fromStrings_illegal_use_of_expired_flag_disable() {
    // Expired flags are ignored even if they would fail validation.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    expect(getFlags(fromStrings(['no-a'])), [true]);
  }

  test_fromStrings_illegal_use_of_expired_flag_enable() {
    // Expired flags are ignored even if they would fail validation.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['a'])), [false]);
  }

  test_fromStrings_unnecessary_use_of_expired_flag_disable() {
    // Expired flags are ignored.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getFlags(fromStrings(['no-a'])), [false]);
  }

  test_fromStrings_unnecessary_use_of_expired_flag_enable() {
    // Expired flags are ignored.
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    expect(getFlags(fromStrings(['a'])), [true]);
  }

  test_fromStrings_unrecognized_flag() {
    // Unrecognized flags are ignored.
    expect(getFlags(fromStrings(['a'])), []);
  }

  test_validateFlagCombination_disable_then_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      firstSupportedVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      firstSupportedVersion: null,
    );
    var validationResult =
        getValidateCombinationResult(['a', 'no-c'], ['no-b', 'c']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0];
    expect(error.feature, knownFeatures['c']);
    expect(error.firstValue, false);
  }

  test_validateFlagCombination_enable_then_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      firstSupportedVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      firstSupportedVersion: null,
    );
    var validationResult =
        getValidateCombinationResult(['a', 'c'], ['no-b', 'no-c']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0];
    expect(error.feature, knownFeatures['c']);
    expect(error.firstValue, true);
  }

  test_validateFlagCombination_ok() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    knownFeatures['b'] = ExperimentalFeature(
      index: 1,
      enableString: 'b',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'b',
      firstSupportedVersion: null,
    );
    knownFeatures['c'] = ExperimentalFeature(
      index: 2,
      enableString: 'c',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'c',
      firstSupportedVersion: null,
    );
    expect(getValidateCombinationResult(['a', 'c'], ['no-b', 'c']), isEmpty);
  }

  test_validateFlags_conflicting_flags_disable_then_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    var validationResult = getValidationResult(['no-a', 'a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as ConflictingFlags;
    expect(error.stringIndex, 1);
    expect(error.flag, 'a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
    expect(error.previousStringIndex, 0);
    expect(error.requestedValue, true);
  }

  test_validateFlags_conflicting_flags_enable_then_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    var validationResult = getValidationResult(['a', 'no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as ConflictingFlags;
    expect(error.stringIndex, 1);
    expect(error.flag, 'no-a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
    expect(error.previousStringIndex, 0);
    expect(error.requestedValue, false);
  }

  test_validateFlags_ignore_redundant_disable_flags() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    expect(getValidationResult(['no-a', 'no-a']), isEmpty);
  }

  test_validateFlags_ignore_redundant_enable_flags() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: false,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    expect(getValidationResult(['a', 'a']), isEmpty);
  }

  test_validateFlags_illegal_use_of_expired_flag_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    var validationResult = getValidationResult(['no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as IllegalUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'no-a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_illegal_use_of_expired_flag_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as IllegalUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, true);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unnecessary_use_of_expired_flag_disable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: false,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: null,
    );
    var validationResult = getValidationResult(['no-a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnnecessaryUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'no-a');
    expect(error.isError, false);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unnecessary_use_of_expired_flag_enable() {
    knownFeatures['a'] = ExperimentalFeature(
      index: 0,
      enableString: 'a',
      isEnabledByDefault: true,
      isExpired: true,
      documentation: 'a',
      firstSupportedVersion: '1.0.0',
    );
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnnecessaryUseOfExpiredFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, false);
    expect(error.feature, knownFeatures['a']);
  }

  test_validateFlags_unrecognized_flag() {
    var validationResult = getValidationResult(['a']);
    expect(validationResult, hasLength(1));
    var error = validationResult[0] as UnrecognizedFlag;
    expect(error.stringIndex, 0);
    expect(error.flag, 'a');
    expect(error.isError, true);
  }
}
