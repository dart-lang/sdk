// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementResolutionTest);
  });
}

@reflectiveTest
class TryStatementResolutionTest extends PubPackageResolutionTest {
  test_catch_parameters_0() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} catch () {}
}
''',
      [error(ParserErrorCode.catchSyntax, 27, 1)],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: <empty> <synthetic>
        declaredFragment: isFinal isPublic @null
          element: hasImplicitType isFinal isPrivate
            type: Object
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_catch_parameters_3() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} catch (x, y, z) {}
}
''',
      [
        error(WarningCode.unusedCatchStack, 30, 1),
        error(ParserErrorCode.catchSyntaxExtraParameters, 31, 1),
      ],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: x
        declaredFragment: isFinal isPublic x@27
          element: hasImplicitType isFinal isPublic
            type: Object
      comma: ,
      stackTraceParameter: CatchClauseParameter
        name: y
        declaredFragment: isFinal isPublic y@30
          element: hasImplicitType isFinal isPublic
            type: StackTrace
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_catch_parameters_stackTrace_named() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} catch (x, {st}) {}
}
''',
      [
        error(ParserErrorCode.catchSyntax, 30, 1),
        error(WarningCode.unusedCatchStack, 31, 2),
      ],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: x
        declaredFragment: isFinal isPublic x@27
          element: hasImplicitType isFinal isPublic
            type: Object
      comma: ,
      stackTraceParameter: CatchClauseParameter
        name: st
        declaredFragment: isFinal isPublic st@31
          element: hasImplicitType isFinal isPublic
            type: StackTrace
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_catch_parameters_stackTrace_optionalPositional() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} catch (x, [st]) {}
}
''',
      [
        error(ParserErrorCode.catchSyntax, 30, 1),
        error(WarningCode.unusedCatchStack, 31, 2),
      ],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: x
        declaredFragment: isFinal isPublic x@27
          element: hasImplicitType isFinal isPublic
            type: Object
      comma: ,
      stackTraceParameter: CatchClauseParameter
        name: st
        declaredFragment: isFinal isPublic st@31
          element: hasImplicitType isFinal isPublic
            type: StackTrace
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_catch_withoutType() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} catch (e, st) {}
}
''',
      [error(WarningCode.unusedCatchStack, 30, 2)],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: e
        declaredFragment: isFinal isPublic e@27
          element: hasImplicitType isFinal isPublic
            type: Object
      comma: ,
      stackTraceParameter: CatchClauseParameter
        name: st
        declaredFragment: isFinal isPublic st@30
          element: hasImplicitType isFinal isPublic
            type: StackTrace
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_catch_withType() async {
    await assertErrorsInCode(
      r'''
void f() {
  try {} on int catch (e, st) {}
}
''',
      [error(WarningCode.unusedCatchStack, 37, 2)],
    );

    var node = findNode.singleTryStatement;
    assertResolvedNodeText(node, r'''
TryStatement
  tryKeyword: try
  body: Block
    leftBracket: {
    rightBracket: }
  catchClauses
    CatchClause
      onKeyword: on
      exceptionType: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      catchKeyword: catch
      leftParenthesis: (
      exceptionParameter: CatchClauseParameter
        name: e
        declaredFragment: isFinal isPublic e@34
          element: isFinal isPublic
            type: int
      comma: ,
      stackTraceParameter: CatchClauseParameter
        name: st
        declaredFragment: isFinal isPublic st@37
          element: hasImplicitType isFinal isPublic
            type: StackTrace
      rightParenthesis: )
      body: Block
        leftBracket: {
        rightBracket: }
''');
  }
}
