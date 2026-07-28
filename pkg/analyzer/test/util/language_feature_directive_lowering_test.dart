// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'language_feature_directive_lowering.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LanguageFeatureDirectiveLoweringTest);
  });
}

@reflectiveTest
class LanguageFeatureDirectiveLoweringTest {
  void test_before_experimentalFeature() {
    var featureDirectiveLowering = LanguageFeatureDirectiveLowering(r'''
// %before-language-feature: augmentations
void f() {}
''');

    expect(featureDirectiveLowering.loweredCode, r'''
// @dart = 3.5
void f() {}
''');
    expect(
      featureDirectiveLowering.restoreDirective(
        featureDirectiveLowering.loweredCode,
      ),
      r'''
// %before-language-feature: augmentations
void f() {}
''',
    );
  }

  void test_before_featureReleasedAtMajorVersionBoundary() {
    var featureDirectiveLowering = LanguageFeatureDirectiveLowering(r'''
// %before-language-feature: patterns
void f() {}
''');

    expect(featureDirectiveLowering.loweredCode, r'''
// @dart = 2.19
void f() {}
''');
  }

  void test_before_releasedFeature() {
    var featureDirectiveLowering = LanguageFeatureDirectiveLowering(r'''
// %before-language-feature: dot-shorthands
void f() {}
''');

    expect(featureDirectiveLowering.loweredCode, r'''
// @dart = 3.9
void f() {}
''');
  }

  void test_existingLanguageVersionOverride() {
    expect(
      () => LanguageFeatureDirectiveLowering(r'''
// @dart = 3.5
// %before-language-feature: augmentations
void f() {}
'''),
      throwsArgumentError,
    );
  }

  void test_multipleDirectives() {
    expect(
      () => LanguageFeatureDirectiveLowering(r'''
// %before-language-feature: augmentations
// %before-language-feature: enhanced-parts
void f() {}
'''),
      throwsArgumentError,
    );
  }

  void test_noDirective() {
    var code = 'void f() {}';
    var featureDirectiveLowering = LanguageFeatureDirectiveLowering(code);

    expect(featureDirectiveLowering.loweredCode, code);
    expect(featureDirectiveLowering.restoreDirective(code), code);
  }

  void test_unknownFeature() {
    expect(
      () => LanguageFeatureDirectiveLowering(r'''
// %before-language-feature: does-not-exist
void f() {}
'''),
      throwsArgumentError,
    );
  }
}
