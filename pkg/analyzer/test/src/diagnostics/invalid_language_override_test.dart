// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 11.12
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 16] The language version override can't specify a version greater than the latest known language version: 3.14.
int i = 0;
''');
  }

  test_correct_3_190() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.190
// [diag.invalidLanguageVersionOverrideGreater][column 1][length 16] The language version override can't specify a version greater than the latest known language version: 3.14.
int i = 0;
''');
  }

  test_correct_withMultipleWhitespace() async {
    await resolveTestCodeWithDiagnostics('''
//  @dart  =  2.19${"  "}
int i = 0;
''');
  }

  test_correct_withoutWhitespace() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
int i = 0;
''');
  }

  test_correct_withWhitespace() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
int i = 0;
''');
  }

  test_embeddedInBlockComment() async {
    await resolveTestCodeWithDiagnostics(r'''
/**
 *  // @dart = 2.0
 */
int i = 0;
''');
  }

  test_embeddedInBlockComment_noLeadingAsterisk() async {
    await resolveTestCodeWithDiagnostics(r'''
/* Big comment.
// @dart = 2.0
 */
int i = 0;
''');
  }

  test_invalidOverrideFollowsValidOverride() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
// comment.
// @dart >= 2.19
int i = 0;
''');
  }

  test_location_afterClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  // @dart = 3.0
//   ^^^^^^^^^^^
// [diag.invalidLanguageVersionOverrideLocation] The language version override must be specified before any declaration or directive.
  void test() {}
}
''');
  }

  test_location_afterDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
// @dart = 3.0
// ^^^^^^^^^^^
// [diag.invalidLanguageVersionOverrideLocation] The language version override must be specified before any declaration or directive.
''');
  }

  test_location_afterDeclaration_beforeEof() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
// @dart = 3.0
// ^^^^^^^^^^^
// [diag.invalidLanguageVersionOverrideLocation] The language version override must be specified before any declaration or directive.
''');
  }

  test_location_afterDirective() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core';
// @dart = 3.0
// ^^^^^^^^^^^
// [diag.invalidLanguageVersionOverrideLocation] The language version override must be specified before any declaration or directive.
class A {}
''');
  }

  test_location_beforeDeclaration() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A {}
''');
  }

  test_location_notLineStart() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  /**
   * For example '// @dart = 2.1'.
   */
  void test() {}
}
''');
  }

  test_missingAtSign() async {
    await resolveTestCodeWithDiagnostics(r'''
// dart = 2.0
// [diag.invalidLanguageVersionOverrideAtSign][column 1][length 13] The Dart language version override number must begin with '@dart'.
int i = 0;
''');
  }

  test_missingSeparator() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart 2.0
// [diag.invalidLanguageVersionOverrideEquals][column 1][length 12] The Dart language version override comment must be specified with an '=' character.
int i = 0;
''');
  }

  test_nonVersionOverride_atDart2js() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @dart2js.
int i = 0;
''');
  }

  test_nonVersionOverride_dart2js() async {
    await resolveTestCodeWithDiagnostics(r'''
/// dart2js.
int i = 0;
''');
  }

  test_nonVersionOverride_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
///
int i = 0;
''');
  }

  test_nonVersionOverride_noNumbers() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart
int i = 0;
''');
  }

  test_nonVersionOverride_noSeparatorOrNumber() async {
    await resolveTestCodeWithDiagnostics(r'''
/// dart is great.
int i = 0;
''');
  }

  test_nonVersionOverride_onlyWhitespace() async {
    await resolveTestCodeWithDiagnostics('''
///${"  "}

int i = 0;
''');
  }

  test_nonVersionOverride_otherText() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart is great
int i = 0;
''');
  }

  test_noWhitespace() async {
    await resolveTestCodeWithDiagnostics(r'''
//@dart=2.19
int i = 0;
''');
  }

  test_separatorIsTooLong() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart >= 2.0
// [diag.invalidLanguageVersionOverrideEquals][column 1][length 15] The Dart language version override comment must be specified with an '=' character.
int i = 0;
''');
  }

  test_shebangLine() async {
    await resolveTestCodeWithDiagnostics(r'''
#!/usr/bin/dart
// @dart = 2.19
int i = 0;
''');
  }

  test_shebangLine_wrongCase() async {
    await resolveTestCodeWithDiagnostics(r'''
#!/usr/bin/dart
// @Dart = 2.0
// [diag.invalidLanguageVersionOverrideLowerCase][column 1][length 14] The Dart language version override comment must be specified with the word 'dart' in all lower case.
int i = 0;
''');
  }

  test_tooManySlashes() async {
    await resolveTestCodeWithDiagnostics(r'''
/// @dart = 2.0
// [diag.invalidLanguageVersionOverrideTwoSlashes][column 1][length 15] The Dart language version override comment must be specified with exactly two slashes.
int i = 0;
''');
  }

  test_wrongAtSignPosition() async {
    await resolveTestCodeWithDiagnostics(r'''
// dart @ 2.0
// [diag.invalidLanguageVersionOverrideAtSign][column 1][length 13] The Dart language version override number must begin with '@dart'.
int i = 0;
''');
  }

  test_wrongCase_firstComment() async {
    await resolveTestCodeWithDiagnostics(r'''
// @Dart = 2.0
// [diag.invalidLanguageVersionOverrideLowerCase][column 1][length 14] The Dart language version override comment must be specified with the word 'dart' in all lower case.
int i = 0;
''');
  }

  test_wrongCase_multilineComment() async {
    await resolveTestCodeWithDiagnostics(r'''
// Copyright
// @Dart = 2.0
// [diag.invalidLanguageVersionOverrideLowerCase][column 1][length 14] The Dart language version override comment must be specified with the word 'dart' in all lower case.
int i = 0;
''');
  }

  test_wrongCase_secondComment() async {
    await resolveTestCodeWithDiagnostics(r'''
// Copyright

// @Dart = 2.0
// [diag.invalidLanguageVersionOverrideLowerCase][column 1][length 14] The Dart language version override comment must be specified with the word 'dart' in all lower case.
int i = 0;
''');
  }

  test_wrongSeparator_noSpace() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart:2.0
// [diag.invalidLanguageVersionOverrideEquals][column 1][length 12] The Dart language version override comment must be specified with an '=' character.
int i = 0;
''');
  }

  test_wrongSeparator_withSpace() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart : 2.0
// [diag.invalidLanguageVersionOverrideEquals][column 1][length 14] The Dart language version override comment must be specified with an '=' character.
int i = 0;
''');
  }

  test_wrongVersion_extraSpecificity() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.0.0
// [diag.invalidLanguageVersionOverrideTrailingCharacters][column 1][length 16] The Dart language version override comment can't be followed by any non-whitespace characters.
int i = 0;
''');
  }

  test_wrongVersion_noMinorVersion() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2
// [diag.invalidLanguageVersionOverrideNumber][column 1][length 12] The Dart language version override comment must be specified with a version number, like '2.0', after the '=' character.
int i = 0;
''');
  }

  test_wrongVersion_prefixCharacter() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = v2.0
// [diag.invalidLanguageVersionOverridePrefix][column 1][length 15] The Dart language version override number can't be prefixed with a letter.
int i = 0;
''');
  }
}
