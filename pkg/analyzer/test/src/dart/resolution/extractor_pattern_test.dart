// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractorPatternResolutionTest);
  });
}

@reflectiveTest
class ExtractorPatternResolutionTest extends PatternsResolutionTest {
  test_identifier_inside_castPattern() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0) as Object:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_identifier_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0)!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  operator: !
''');
  }

  test_identifier_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
class C {
  int? f;
}

void f(x) {
  switch (x) {
    case C(f: 0)?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  operator: ?
''');
  }

  test_identifier_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

void f(x) {
  switch (x) {
    case C<int>():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_identifier_withTypeArguments_inside_nullAssert() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

void f(x) {
  switch (x) {
    case C<int>()!:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: !
''');
  }

  test_identifier_withTypeArguments_inside_nullCheck() async {
    await assertNoErrorsInCode(r'''
class C<T> {}

void f(x) {
  switch (x) {
    case C<int>()?:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: SimpleIdentifier
        token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: ?
''');
  }

  test_prefixedIdentifier_inside_castPattern() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int? f;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C(f: 0) as Object:
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
CastPattern
  pattern: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: Object
''');
  }

  test_prefixedIdentifier_inside_nullAssert() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int? f;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C(f: 0)!:
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  operator: !
''');
  }

  test_prefixedIdentifier_inside_nullCheck() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  int? f;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C(f: 0)?:
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: f
          colon: :
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
  operator: ?
''');
  }

  test_prefixedIdentifier_withTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<T> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C<int>():
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
      period: .
      identifier: SimpleIdentifier
        token: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      rightBracket: >
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_prefixedIdentifier_withTypeArguments_inside_nullAssert() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<T> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C<int>()!:
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: !
''');
  }

  test_prefixedIdentifier_withTypeArguments_inside_nullCheck() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C<T> {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C<int>()?:
      break;
  }
}
''');

    final node = findNode.switchPatternCase('case').pattern;
    assertParsedNodeText(node, r'''
PostfixPattern
  operand: ExtractorPattern
    type: NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: prefix
        period: .
        identifier: SimpleIdentifier
          token: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: SimpleIdentifier
              token: int
        rightBracket: >
    leftParenthesis: (
    rightParenthesis: )
  operator: ?
''');
  }
}
