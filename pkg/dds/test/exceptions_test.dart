// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds/dds.dart';
import 'package:test/test.dart';

void main() {
  group('DartDevelopmentServiceException.fromJSON', () {
    test('parses existing DDS instance error', () {
      final DartDevelopmentServiceException actual =
          DartDevelopmentServiceException.fromJson(
        <String, Object>{
          'error_code':
              DartDevelopmentServiceException.existingDdsInstanceError,
          'message': 'Foo',
          'uri': 'http://localhost',
        },
      );
      final DartDevelopmentServiceException expected =
          DartDevelopmentServiceException.existingDdsInstance(
        'Foo',
        ddsUri: Uri.parse('http://localhost'),
      );
      expect(actual.errorCode, expected.errorCode);
      expect(actual.message, expected.message);
      expect(actual, isA<ExistingDartDevelopmentServiceException>());
      expect(
        (actual as ExistingDartDevelopmentServiceException).ddsUri,
        (expected as ExistingDartDevelopmentServiceException).ddsUri,
      );
    });

    test('parses connection issue error', () {
      final DartDevelopmentServiceException actual =
          DartDevelopmentServiceException.fromJson(
        <String, Object>{
          'error_code': DartDevelopmentServiceException.connectionError,
          'message': 'Foo',
        },
      );
      final DartDevelopmentServiceException expected =
          DartDevelopmentServiceException.connectionIssue('Foo');
      expect(actual.errorCode, expected.errorCode);
      expect(actual.message, expected.message);
    });

    test('parses failed to start error', () {
      final DartDevelopmentServiceException expected =
          DartDevelopmentServiceException.failedToStart();
      final DartDevelopmentServiceException actual =
          DartDevelopmentServiceException.fromJson(
        <String, Object>{
          'error_code': DartDevelopmentServiceException.failedToStartError,
          'message': expected.message,
        },
      );
      expect(actual.errorCode, expected.errorCode);
      expect(actual.message, expected.message);
    });
  });
}
