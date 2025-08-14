// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidLanguageOverrideTest);
  });
}

@reflectiveTest
class InvalidLanguageOverrideTest extends PubPackageResolutionTest {
  test_correct_11_12() async {
    await assertErrorsInCode(
      r'''
// @dart = 11.12
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideGreater, 0, 16)],
    );
  }

  test_correct_3_190() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.190
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideGreater, 0, 16)],
    );
  }

  test_correct_withMultipleWhitespace() async {
    await assertNoErrorsInCode('''
//  @dart  =  2.19${"  "}
int i = 0;
''');
  }

  test_correct_withoutWhitespace() async {
    await assertNoErrorsInCode(r'''
//@dart=2.19
int i = 0;
''');
  }

  test_correct_withWhitespace() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
int i = 0;
''');
  }

  test_embeddedInBlockComment() async {
    await assertNoErrorsInCode(r'''
/**
 *  // @dart = 2.0
 */
int i = 0;
''');
  }

  test_embeddedInBlockComment_noLeadingAsterisk() async {
    await assertNoErrorsInCode(r'''
/* Big comment.
// @dart = 2.0
 */
int i = 0;
''');
  }

  test_invalidOverrideFollowsValidOverride() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
// comment.
// @dart >= 2.19
int i = 0;
''');
  }

  test_location_afterClass() async {
    await assertErrorsInCode(
      r'''
class A {
  // @dart = 3.0
  void test() {}
}
''',
      [error(WarningCode.invalidLanguageVersionOverrideLocation, 15, 11)],
    );
  }

  test_location_afterDeclaration() async {
    await assertErrorsInCode(
      r'''
class A {}
// @dart = 3.0
''',
      [error(WarningCode.invalidLanguageVersionOverrideLocation, 14, 11)],
    );
  }

  test_location_afterDeclaration_beforeEof() async {
    await assertErrorsInCode(
      r'''
class A {}
// @dart = 3.0
''',
      [error(WarningCode.invalidLanguageVersionOverrideLocation, 14, 11)],
    );
  }

  test_location_afterDirective() async {
    await assertErrorsInCode(
      r'''
import 'dart:core';
// @dart = 3.0
class A {}
''',
      [error(WarningCode.invalidLanguageVersionOverrideLocation, 23, 11)],
    );
  }

  test_location_beforeDeclaration() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
class A {}
''');
  }

  test_location_notLineStart() async {
    await assertNoErrorsInCode(r'''
class A {
  /**
   * For example '// @dart = 2.1'.
   */
  void test() {}
}
''');
  }

  test_missingAtSign() async {
    await assertErrorsInCode(
      r'''
// dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideAtSign, 0, 13)],
    );
  }

  test_missingSeparator() async {
    await assertErrorsInCode(
      r'''
// @dart 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideEquals, 0, 12)],
    );
  }

  test_nonVersionOverride_atDart2js() async {
    await assertNoErrorsInCode(r'''
/// @dart2js.
int i = 0;
''');
  }

  test_nonVersionOverride_dart2js() async {
    await assertNoErrorsInCode(r'''
/// dart2js.
int i = 0;
''');
  }

  test_nonVersionOverride_empty() async {
    await assertNoErrorsInCode(r'''
///
int i = 0;
''');
  }

  test_nonVersionOverride_noNumbers() async {
    await assertNoErrorsInCode(r'''
// @dart
int i = 0;
''');
  }

  test_nonVersionOverride_noSeparatorOrNumber() async {
    await assertNoErrorsInCode(r'''
/// dart is great.
int i = 0;
''');
  }

  test_nonVersionOverride_onlyWhitespace() async {
    await assertNoErrorsInCode('''
///${"  "}

int i = 0;
''');
  }

  test_nonVersionOverride_otherText() async {
    await assertNoErrorsInCode(r'''
// @dart is great
int i = 0;
''');
  }

  test_noWhitespace() async {
    await assertNoErrorsInCode(r'''
//@dart=2.19
int i = 0;
''');
  }

  test_separatorIsTooLong() async {
    await assertErrorsInCode(
      r'''
// @dart >= 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideEquals, 0, 15)],
    );
  }

  test_shebangLine() async {
    await assertNoErrorsInCode(r'''
#!/usr/bin/dart
// @dart = 2.19
int i = 0;
''');
  }

  test_shebangLine_wrongCase() async {
    await assertErrorsInCode(
      r'''
#!/usr/bin/dart
// @Dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideLowerCase, 16, 14)],
    );
  }

  test_tooManySlashes() async {
    await assertErrorsInCode(
      r'''
/// @dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideTwoSlashes, 0, 15)],
    );
  }

  test_wrongAtSignPosition() async {
    await assertErrorsInCode(
      r'''
// dart @ 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideAtSign, 0, 13)],
    );
  }

  test_wrongCase_firstComment() async {
    await assertErrorsInCode(
      r'''
// @Dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideLowerCase, 0, 14)],
    );
  }

  test_wrongCase_multilineComment() async {
    await assertErrorsInCode(
      r'''
// Copyright
// @Dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideLowerCase, 13, 14)],
    );
  }

  test_wrongCase_secondComment() async {
    await assertErrorsInCode(
      r'''
// Copyright

// @Dart = 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideLowerCase, 14, 14)],
    );
  }

  test_wrongSeparator_noSpace() async {
    await assertErrorsInCode(
      r'''
// @dart:2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideEquals, 0, 12)],
    );
  }

  test_wrongSeparator_withSpace() async {
    await assertErrorsInCode(
      r'''
// @dart : 2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideEquals, 0, 14)],
    );
  }

  test_wrongVersion_extraSpecificity() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.0.0
int i = 0;
''',
      [
        error(
          WarningCode.invalidLanguageVersionOverrideTrailingCharacters,
          0,
          16,
        ),
      ],
    );
  }

  test_wrongVersion_noMinorVersion() async {
    await assertErrorsInCode(
      r'''
// @dart = 2
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverrideNumber, 0, 12)],
    );
  }

  test_wrongVersion_prefixCharacter() async {
    await assertErrorsInCode(
      r'''
// @dart = v2.0
int i = 0;
''',
      [error(WarningCode.invalidLanguageVersionOverridePrefix, 0, 15)],
    );
  }
}
