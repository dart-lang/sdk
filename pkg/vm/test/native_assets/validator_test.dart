// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/vm.dart';
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart';
import 'package:vm/native_assets/diagnostic_message.dart';
import 'package:vm/native_assets/validator.dart';

main() {
  test('valid', () {
    final errorDetector = ErrorDetector();
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(result, {
      'format-version': [1, 0, 0],
      'native-assets': {
        'linux_x64': {
          'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
        }
      }
    });
    expect(errorDetector.hasCompilationErrors, false);
  });

  test('not yaml', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '&&&';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(errors.single.message, equals('File not formatted as yaml: &&&.'));
  });

  test('no format-version', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));

    final yamlString = '''
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(errors.single.message, startsWith('Expected format-version in'));
  });

  test('wrong format-version', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [9000, 0, 1]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(errors.single.message,
        startsWith('Unexpected format version: [9000, 0, 1].'));
  });

  test('no native-assets', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [1, 0, 0]
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(errors.single.message, startsWith('Expected native-assets in'));
  });

  test('invalid target warning', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  target_does_not_exist:
    'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, false);
    // Invalid targets only issue warnings.
    expect(errors.single.severity, Severity.warning);
    expect(errors.single.message,
        startsWith('Unexpected target: target_does_not_exist.'));
    // Filters out unsupported targets.
    expect(result, {
      'format-version': [1, 0, 0],
      'native-assets': {}
    });
  });

  test('invalid path', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['path_type_does_not_exist']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(errors.single.message,
        startsWith('Unexpected path type: path_type_does_not_exist.'));
  });

  test('invalid absolute path', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['absolute']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(
        errors.single.message,
        equals(
            'Unexpected asset path: [absolute]. Expected list with 2 elements.'));
  });

  test('invalid process path', () {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['process' , '/path/to/libfoo.so']
''';
    final result =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString);
    expect(errorDetector.hasCompilationErrors, true);
    expect(result, null);
    expect(
        errors.single.message,
        equals(
            'Unexpected asset path: [process, /path/to/libfoo.so]. Expected list with 1 elements.'));
  });
}
