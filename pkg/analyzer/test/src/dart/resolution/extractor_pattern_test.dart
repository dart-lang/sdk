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
  test_identifier_noTypeArguments() async {
    await assertNoErrorsInCode(r'''
class C {}

void f(x) {
  switch (x) {
    case C():
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
  leftParenthesis: (
  rightParenthesis: )
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

  test_prefixedIdentifier_noTypeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f(x) {
  switch (x) {
    case prefix.C():
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
  leftParenthesis: (
  rightParenthesis: )
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
}
