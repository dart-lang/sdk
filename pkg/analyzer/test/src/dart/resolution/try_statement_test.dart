// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TryStatementResolutionTest extends PubPackageResolutionTest {
  test_catch_parameters_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch () {}
//              ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
}
''');

    var node = result.findNode.singleTryStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (x, y, z) {}
//                 ^
// [diag.unusedCatchStack] The stack trace variable 'y' isn't used and can be removed.
//                  ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
}
''');

    var node = result.findNode.singleTryStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (x, {st}) {}
//                 ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                  ^^
// [diag.unusedCatchStack] The stack trace variable 'st' isn't used and can be removed.
}
''');

    var node = result.findNode.singleTryStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (x, [st]) {}
//                 ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                  ^^
// [diag.unusedCatchStack] The stack trace variable 'st' isn't used and can be removed.
}
''');

    var node = result.findNode.singleTryStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (e, st) {}
//                 ^^
// [diag.unusedCatchStack] The stack trace variable 'st' isn't used and can be removed.
}
''');

    var node = result.findNode.singleTryStatement;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} on int catch (e, st) {}
//                        ^^
// [diag.unusedCatchStack] The stack trace variable 'st' isn't used and can be removed.
}
''');

    var node = result.findNode.singleTryStatement;
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
        element: dart:core::@class::int
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
