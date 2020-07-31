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

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    List<AnalysisError> errors = validator.validate(content, true);
    GatheringErrorListener listener = GatheringErrorListener();
    listener.addAll(errors);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }

  void setUp() {
    File ManifestFile = getFile('/sample/Manifest.xml');
    Source source = ManifestFile.createSource();
    validator = ManifestValidator(source);
  }

  test_cameraPermissions_error() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
''', [ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE]);
  }

  test_featureNotSupported_error() {
    assertErrors('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" />
</manifest>
''', [ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE]);
  }

  test_hardwareNotSupported_error() {
    assertErrors('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.home_screen" />
</manifest>
''', [ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE]);
  }

  test_no_errors() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <activity android:name="testActivity"
    android:resizeableActivity="true"
    android:exported="false">
  </activity>
</manifest>
''', []);
  }

  test_noTouchScreen_error() {
    assertErrors('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', [ManifestWarningCode.NO_TOUCHSCREEN_FEATURE]);
  }

  test_resizeableactivity_error() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <application android:label="@string/app_name">
    <activity android:name="testActivity"
      android:resizeableActivity="false"
      android:exported="false">
    </activity>
  </application>
</manifest>
''', [ManifestWarningCode.NON_RESIZABLE_ACTIVITY]);
  }

  test_screenOrientation_error() {
    assertErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <application android:label="@string/app_name">
    <activity android:name="testActivity"
      android:screenOrientation="landscape"
      android:exported="false">
    </activity>
  </application>
</manifest>
''', [ManifestWarningCode.SETTING_ORIENTATION_ON_ACTIVITY]);
  }

  test_touchScreenNotSupported_error() {
    assertErrors('''
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="true"/>
</manifest>
''', [ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE]);
  }
}
