// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveResolutionTest);
  });
}

@reflectiveTest
class PartDirectiveResolutionTest extends PubPackageResolutionTest {
  test_withoutString() async {
    await assertErrorsInCode(r'''
part '${'foo'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 5, 15),
    ]);

    assertResolvedNodeText(findNode.part('.dart'), r'''
PartDirective
  partKeyword: part
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: String
    stringValue: null
  semicolon: ;
  element: PartElement
  uriContent: null
  uriElement: notUnitElement
  uriSource: <null>
''');
  }

  test_withPart_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await assertNoErrorsInCode(r'''
library my.lib;
part 'a.dart';
''');

    assertResolvedNodeText(findNode.part('a.dart'), r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: PartElementWithPart
    part: package:test/a.dart
  uriContent: null
  uriElement: unitElement package:test/a.dart
  uriSource: package:test/a.dart
''');
  }

  test_withPart_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';
''');

    assertResolvedNodeText(findNode.part('a.dart'), r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: PartElementWithPart
    part: package:test/a.dart
  uriContent: null
  uriElement: unitElement package:test/a.dart
  uriSource: package:test/a.dart
''');
  }

  test_withSource_notPart_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertErrorsInCode(r'''
part 'a.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 5, 8),
    ]);

    assertResolvedNodeText(findNode.part('a.dart'), r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: PartElementWithSource
    source: package:test/a.dart
  uriContent: null
  uriElement: notUnitElement
  uriSource: package:test/a.dart
''');
  }

  test_withSource_notPart_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode(r'''
part 'a.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 5, 8),
    ]);

    assertResolvedNodeText(findNode.part('a.dart'), r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: PartElementWithSource
    source: package:test/a.dart
  uriContent: null
  uriElement: notUnitElement
  uriSource: package:test/a.dart
''');
  }
}
