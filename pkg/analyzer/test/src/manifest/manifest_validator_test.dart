// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/manifest/manifest_values.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/diff.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ManifestValidatorTest);
    defineReflectiveTests(ManifestParserTest);
  });
}

@reflectiveTest
class ManifestParserTest with ResourceProviderMixin {
  static final _manifestUri = Uri.parse('file:///sample/Manifest.xml');

  void test_attribute_endsAfterEquals_isError() {
    var parser = ManifestParser('<tag a= />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_attribute_missingValue_isError() {
    var parser = ManifestParser('<tag a />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_attribute_valueMissingQuotes_isError() {
    var parser = ManifestParser('<tag a=b />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_commentTag_isParsed() {
    var parser = ManifestParser('''
<!-- comment tag -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.element);
    expect(result.element, isNull);

    result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_emptyFileDoesNotCrash() {
    var parser = ManifestParser('', _manifestUri);
    parser.parseXmlTag();
  }

  void test_endTagWithAttributes_isError() {
    var parser = ManifestParser('<tag></tag aaa="bbb">', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_endTagWithWhitespace_isOk() {
    var parser = ManifestParser('<tag></tag >', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.element);
  }

  void test_eofAfterAttributeEqual_isError() {
    var parser = ManifestParser('<manifest xml=', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofAfterAttributeEqual_whitespace_isError() {
    var parser = ManifestParser('<manifest xml= ', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofAfterOpeningTag() {
    var parser = ManifestParser('<manifest>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.eof);
  }

  void test_eofAfterOpeningTag_nested_inside() {
    var parser = ManifestParser('<manifest><application>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.eof);
  }

  void test_eofAfterOpeningTag_nested_outside() {
    var parser = ManifestParser(
      '<manifest><application></application>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.eof);
  }

  void test_eofAfterOpeningTag_whitespace() {
    var parser = ManifestParser('<tag> ', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.eof);
  }

  void test_eofDuringAttributeName_isError() {
    var parser = ManifestParser('<tag xml ', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofDuringAttributeName_whitespace_isError() {
    var parser = ManifestParser('<tag xml', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofDuringAttributeValue_isError() {
    var parser = ManifestParser('<tag a="b"', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofDuringAttributeValue_whitespace_isError() {
    var parser = ManifestParser('<tag aaa="bbb" ', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofDuringTagName_isError() {
    var parser = ManifestParser('<tag', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_eofDuringTagName_whitespace_isError() {
    var parser = ManifestParser('<tag ', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }

  void test_manifestTag_attributeWithEmptyValue_emptyElement_isParsed() {
    var parser = ManifestParser('<manifest xmlns:android=""/>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_emptyElement_isParsed() {
    var parser = ManifestParser('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"/>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_emptyElement_noAttributes_isParsed() {
    var parser = ManifestParser('<manifest/>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_emptyElement_noAttributes_whitespace_isParsed() {
    var parser = ManifestParser('<manifest />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_emptyElement_whitespace_isParsed() {
    var parser = ManifestParser('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android" />
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_isParsed() {
    var parser = ManifestParser('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_uppercase_isParsed() {
    var parser = ManifestParser('''
<MANIFEST xmlns:android="http://schemas.android.com/apk/res/android">
</MANIFEST>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_withDoctype_isParsed() {
    var parser = ManifestParser('''
<!DOCTYPE greeting SYSTEM "hello.dtd">
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.element);
    expect(result.element, isNull);

    result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_withFeatures_isParsed() {
    var parser = ManifestParser('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen"
      android:required="false" />
  <uses-feature android:name="android.software.home_screen" />
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    var children = result.element!.children;
    expect(children, hasLength(2));

    expect(children[0].name, equals(usesFeatureTag));
    var touchscreenAttributes = children[0].attributes;
    expect(touchscreenAttributes, hasLength(2));
    expect(
      touchscreenAttributes[androidName]!.value,
      equals(hardwareFeatureTouchscreen),
    );
    expect(touchscreenAttributes[androidRequired]!.value, equals('false'));

    expect(children[1].name, equals(usesFeatureTag));
    var homeScreenAttributes = children[1].attributes;
    expect(homeScreenAttributes, hasLength(1));
    expect(
      homeScreenAttributes[androidName]!.value,
      equals('android.software.home_screen'),
    );
  }

  void test_manifestTag_withInnerText_isParsed() {
    var parser = ManifestParser('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
Text
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_withSurroundingText_isParsed() {
    var parser = ManifestParser('''
Text
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
Text
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_manifestTag_withXmlTag_isParsed() {
    var parser = ManifestParser('''
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.element);
    expect(result.element, isNull);

    result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.relevantElement);
    expect(result.element!.name, manifestTag);
  }

  void test_outsideTagClosedBeforeInside() {
    var parser = ManifestParser(
      '<manifest><application></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.eof);
  }

  void test_relevantTag_attributeIsParsed() {
    var parser = ManifestParser(
      '<manifest aaa="bbb"></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['aaa']!;
    expect(attribute.name, equals('aaa'));
    expect(attribute.value, equals('bbb'));
    var sourceSpan = attribute.sourceSpan;
    expect(sourceSpan.start.offset, equals(10));
    expect(sourceSpan.end.offset, equals(18));
  }

  void test_relevantTag_attributeIsParsed_containsSingleQuotes() {
    var parser = ManifestParser(
      '<manifest aaa="b\'b\'b"></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['aaa']!;
    expect(attribute.name, equals('aaa'));
    expect(attribute.value, equals("b'b'b"));
    var sourceSpan = attribute.sourceSpan;
    expect(sourceSpan.start.offset, equals(10));
    expect(sourceSpan.end.offset, equals(20));
  }

  void test_relevantTag_attributeIsParsed_emptyValue() {
    var parser = ManifestParser('<manifest aaa=""></manifest>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['aaa']!;
    expect(attribute.name, equals('aaa'));
    expect(attribute.value, equals(''));
    var sourceSpan = attribute.sourceSpan;
    expect(sourceSpan.start.offset, equals(10));
    expect(sourceSpan.end.offset, equals(15));
  }

  void test_relevantTag_attributeIsParsed_singleQuotes() {
    var parser = ManifestParser(
      "<manifest aaa='bbb'></manifest>",
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['aaa']!;
    expect(attribute.name, equals('aaa'));
    expect(attribute.value, equals('bbb'));
    var sourceSpan = attribute.sourceSpan;
    expect(sourceSpan.start.offset, equals(10));
    expect(sourceSpan.end.offset, equals(18));
  }

  void test_relevantTag_attributeIsParsed_uppercase() {
    var parser = ManifestParser(
      '<manifest AAA="bbb"></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['aaa']!;
    expect(attribute.name, equals('aaa'));
    expect(attribute.value, equals('bbb'));
  }

  void test_relevantTag_attributeWithEmptyValueIsParsed() {
    var parser = ManifestParser(
      '<manifest xmlns:android=""></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    expect(result.element!.attributes, hasLength(1));
    var attribute = result.element!.attributes['xmlns:android']!;
    expect(attribute.value, equals(''));
  }

  void test_relevantTag_emptyElement_nameIsParsed() {
    var parser = ManifestParser('<manifest/>', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    var sourceSpan = result.element!.sourceSpan!;
    expect(sourceSpan.start.offset, equals(0));
    expect(sourceSpan.end.offset, equals(11));
  }

  void test_relevantTag_emptyElement_whitespace_nameIsParsed() {
    var parser = ManifestParser('<manifest />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    var sourceSpan = result.element!.sourceSpan!;
    expect(sourceSpan.start.offset, equals(0));
    expect(sourceSpan.end.offset, equals(12));
  }

  void test_relevantTag_withAttributes_emptyElement_nameIsParsed() {
    var parser = ManifestParser('<manifest aaa="bbb" />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    var sourceSpan = result.element!.sourceSpan!;
    expect(sourceSpan.start.offset, equals(0));
    expect(sourceSpan.end.offset, equals(22));
  }

  void test_relevantTag_withAttributes_nameIsParsed() {
    var parser = ManifestParser(
      '<manifest aaa="bbb"></manifest>',
      _manifestUri,
    );
    var result = parser.parseXmlTag();
    expect(result.element!.name, manifestTag);
    var sourceSpan = result.element!.sourceSpan!;
    expect(sourceSpan.start.offset, equals(0));
    expect(sourceSpan.end.offset, equals(31));
  }

  void test_tagBeginningWithWhitespace_isError() {
    var parser = ManifestParser('< tag />', _manifestUri);
    var result = parser.parseXmlTag();
    expect(result.parseResult, ParseResult.error);
  }
}

@reflectiveTest
class ManifestValidatorTest with ResourceProviderMixin {
  /// Assert that validator diagnostics match the inline diagnostic markers in
  /// [content].
  void assertDiagnostics(String content) {
    var cleanContent = removeDiagnosticExpectations(content);

    var source = FileSource(getFile('/sample/Manifest.xml'));
    var validator = ManifestValidator(source);
    var diagnostics = validator.validate(cleanContent, true);
    var actual = updateExpectedDiagnostics(
      content: cleanContent,
      actualDiagnostics: diagnostics,
    );
    if (actual != content) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(content, actual);
      }
      fail('See the difference above.');
    }
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content) {
    assertDiagnostics(content);
  }

  test_cameraPermissions_error() {
    assertDiagnostics('''
<manifest
   xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <uses-permission android:name="android.permission.CAMERA" />
//                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.cameraPermissionsIncompatible] Camera permissions make app incompatible for Chrome OS, consider adding optional features "android.hardware.camera" and "android.hardware.camera.autofocus".
</manifest>
''');
  }

  test_cameraPermissions_ok() {
    assertNoErrors('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
''');
  }

  test_featureNotSupported_error() {
    assertDiagnostics('''
<manifest
  xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" />
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unsupportedChromeOsHardware] The feature android.hardware.touchscreen isn't supported on Chrome OS, consider making it optional.
</manifest>
''');
  }

  test_hardwareNotSupported_error() {
    assertDiagnostics('''
<manifest
  xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <uses-feature android:name="android.software.home_screen" />
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unsupportedChromeOsHardware] The feature android.software.home_screen isn't supported on Chrome OS, consider making it optional.
</manifest>
''');
  }

  test_no_errors() {
    assertDiagnostics('''
<manifest
     xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <activity android:name="testActivity"
    android:resizeableActivity="true"
    android:exported="false">
  </activity>
</manifest>
''');
  }

  test_noTouchScreen_error() {
    assertDiagnostics('''
<manifest
// [diag.noTouchscreenFeature][column 1][length 83] The default "android.hardware.touchscreen" needs to be optional for Chrome OS.
  xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
''');
  }

  test_resizeableactivity_error() {
    assertDiagnostics('''
<manifest
   xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <application android:label="@string/app_name">
    <activity android:name="testActivity"
      android:resizeableActivity="false"
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonResizableActivity] The `<activity>` element should be allowed to be resized to allow users to take advantage of the multi-window environment on Chrome OS
    android:exported="false">
  </activity>
</application>
</manifest>
''');
  }

  test_screenOrientation_error() {
    assertDiagnostics('''
<manifest
   xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
  <application android:label="@string/app_name">
    <activity android:name="testActivity"
      android:screenOrientation="landscape"
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.settingOrientationOnActivity] The `<activity>` element should not be locked to any orientation so that users can take advantage of the multi-window environments and larger screens on Chrome OS
    android:exported="false">
  </activity>
</application>
</manifest>
''');
  }

  test_touchScreenNotSupported_error() {
    assertDiagnostics('''
<manifest
  xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-feature android:name="android.hardware.touchscreen" android:required="true"/>
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unsupportedChromeOsFeature] The feature android.hardware.touchscreen isn't supported on Chrome OS, consider making it optional.
</manifest>
''');
  }
}
