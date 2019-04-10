// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/manifest/manifest_warning_code.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ManifestValidatorTest);
  });
}

@reflectiveTest
class ManifestValidatorTest with ResourceProviderMixin {
  ManifestValidator validator;

  /**
   * Assert that when the validator is used on the given [content] the
   * [expectedErrorCodes] are produced.
   */
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    List<AnalysisError> errors = validator.validate(content, true);
    GatheringErrorListener listener = new GatheringErrorListener();
    listener.addAll(errors);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /**
   * Assert that when the validator is used on the given [content] no errors are
   * produced.
   */
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }

  void setUp() {
    File ManifestFile = getFile('/sample/Manifest.xml');
    Source source = ManifestFile.createSource();
    validator = new ManifestValidator(source);
  }

  test_hardwareNotSupported_error() {
    assertErrors('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''', [ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE]);
  }

  test_cameraPermissions_error() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
''', [ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE]);
  }

  test_no_errors() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', []);
  }
}
