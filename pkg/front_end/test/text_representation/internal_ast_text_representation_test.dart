// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/ticker.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/builder/declaration_builders.dart';
import 'package:front_end/src/dill/dill_library_builder.dart';
import 'package:front_end/src/dill/dill_loader.dart';
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/dill/dill_type_alias_builder.dart';
import 'package:front_end/src/kernel/body_builder.dart';
import 'package:front_end/src/kernel/internal_ast.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/target/targets.dart';
import 'package:package_config/package_config.dart';

import 'text_representation_test.dart';

void testStatement(
  InternalStatement node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testVariable(
  InternalVariable node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testVariableDeclaration(
  InternalVariableDeclaration node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testElement(
  InternalElement node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testExpression(
  InternalExpression node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testPattern(
  InternalPattern node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

void testInitializer(
  InternalInitializer node,
  String normal, {
  String? verbose,
  String? limited,
}) {
  Expect.stringEquals(
    normal,
    node.toText(normalStrategy),
    "Unexpected normal strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    verbose ?? normal,
    node.toText(verboseStrategy),
    "Unexpected verbose strategy text for ${node.runtimeType}",
  );
  Expect.stringEquals(
    limited ?? normal,
    node.toText(limitedStrategy),
    "Unexpected limited strategy text for ${node.runtimeType}",
  );
}

final Uri dummyUri = Uri.parse('test:dummy');

void main() {
  CompilerContext.runWithOptions(new ProcessedOptions(inputs: [dummyUri]), (
    CompilerContext c,
  ) async {
    _testVariableDeclarations();
    _testTryStatement();
    _testInternalForInStatement();
    _testSwitchCaseImpl();
    _testBreakStatement();
    _testContinueStatement();
    _testCascade();
    _testDeferredCheck();
    _testFactoryConstructorInvocation();
    _testTypeAliasedConstructorInvocation(c);
    _testTypeAliasedFactoryInvocation(c);
    _testFunctionDeclarationImpl();
    _testIfNullExpression();
    _testIntLiterals();
    _testInternalMethodInvocation();
    _testExpressionInvocation();
    _testMethodInvocation();
    _testPropertyGet();
    _testPropertySet();
    _testReturnStatementImpl();
    _testVariableDeclarationImpl();
    _testLoadLibraryImpl();
    _testLoadLibraryTearOff();
    _testIfNullPropertySet();
    _testIfNullSet();
    _testExtensionCompoundSet();
    _testCompoundPropertySet();
    _testPropertyIncDec();
    _testLocalIncDec();
    _testStaticIncDec();
    _testSuperPostIncDec();
    _testIndexGet();
    _testIndexSet();
    _testSuperIndexSet();
    _testExtensionGet();
    _testExtensionSet();
    _testExtensionGetterInvocation();
    _testExtensionMethodInvocation();
    _testExtensionPostIncDec();
    _testExtensionIndexGet();
    _testExtensionIndexSet();
    _testIfNullIndexSet();
    _testIfNullSuperIndexSet();
    _testExtensionIfNullIndexSet();
    _testCompoundIndexSet();
    _testCompoundSuperIndexSet();
    _testExtensionCompoundIndexSet();
    _testExtensionSet();
    _testPropertySetImpl();
    _testExtensionTearOff();
    _testEqualsExpression();
    _testBinaryExpression();
    _testUnaryExpression();
    _testParenthesizedExpression();
    _testSpreadElement();
    _testIfElement();
    _testForElement();
    _testForInElement();
    _testSpreadMapEntry();
    _testIfMapEntry();
    _testForMapEntry();
    _testForInMapEntry();
    _testExpressionMatcher();
    _testBinaryMatcher();
    _testCastMatcher();
    _testNullAssertMatcher();
    _testNullCheckMatcher();
    _testListMatcher();
    _testRelationalMatcher();
    _testMapMatcher();
    _testIfCaseStatement();
    _testPatternSwitchStatement();
    _testSwitchExpression();
    _testPatternVariableDeclaration();
    _testExtensionTypeRedirectingInitializer();
  });
}

void _testVariableDeclarations() {
  testStatement(
    new MultiVariableDeclaration([
      new InternalVariableDeclaration(
        new InternalLocalVariable(
          name: 'a',
          type: null,
          isImplicitlyTyped: false,
          fileOffset: TreeNode.noOffset,
        ),
        nameOffset: TreeNode.noOffset,
      ),
      new InternalVariableDeclaration(
        new InternalLocalVariable(
          name: 'b',
          type: null,
          isImplicitlyTyped: false,
          fileOffset: TreeNode.noOffset,
        ),
        nameOffset: TreeNode.noOffset,
      ),
    ], fileOffset: TreeNode.noOffset),
    '''
dynamic a, b;''',
  );
  testStatement(
    new MultiVariableDeclaration([
      new InternalVariableDeclaration(
        new InternalLocalVariable(
          name: 'a',
          type: const VoidType(),
          isImplicitlyTyped: false,
          fileOffset: TreeNode.noOffset,
        ),
        nameOffset: TreeNode.noOffset,
      ),
      new InternalVariableDeclaration(
        new InternalLocalVariable(
          name: 'b',
          type: null,
          isImplicitlyTyped: true,
          fileOffset: TreeNode.noOffset,
        ),
        initializer: new InternalNullLiteral(fileOffset: TreeNode.noOffset),
        nameOffset: TreeNode.noOffset,
      ),
    ], fileOffset: TreeNode.noOffset),
    '''
void a, b = null;''',
  );
}

void _testTryStatement() {
  InternalBlock emptyBlock1 = new InternalBlock(
    [],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock emptyBlock2 = new InternalBlock(
    [],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock1 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock2 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalCatch emptyCatchBlock = new InternalCatch(
    exception: new InternalCatchVariable(
      name: 'e',
      isImplicitlyTyped: true,
      fileOffset: TreeNode.noOffset,
    ),
    body: new InternalBlock(
      [],
      fileOffset: TreeNode.noOffset,
      fileEndOffset: TreeNode.noOffset,
    ),
    fileOffset: TreeNode.noOffset,
  );
  InternalCatch emptyCatchBlockOnVoid = new InternalCatch(
    exception: new InternalCatchVariable(
      name: 'e',
      isImplicitlyTyped: true,
      fileOffset: TreeNode.noOffset,
    ),
    body: new InternalBlock(
      [],
      fileOffset: TreeNode.noOffset,
      fileEndOffset: TreeNode.noOffset,
    ),
    guard: const VoidType(),
    fileOffset: TreeNode.noOffset,
  );
  InternalCatch returnCatchBlock = new InternalCatch(
    exception: new InternalCatchVariable(
      name: 'e',
      isImplicitlyTyped: true,
      fileOffset: TreeNode.noOffset,
    ),
    body: new InternalBlock(
      [
        new InternalReturnStatement(
          isArrow: false,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
      fileEndOffset: TreeNode.noOffset,
    ),
    fileOffset: TreeNode.noOffset,
  );
  InternalCatch returnCatchBlockOnVoid = new InternalCatch(
    exception: new InternalCatchVariable(
      name: 'e',
      isImplicitlyTyped: true,
      fileOffset: TreeNode.noOffset,
    ),
    body: new InternalBlock(
      [
        new InternalReturnStatement(
          isArrow: false,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
      fileEndOffset: TreeNode.noOffset,
    ),
    guard: const VoidType(),
    fileOffset: TreeNode.noOffset,
  );

  testStatement(
    new TryStatement(
      emptyBlock1,
      [],
      emptyBlock2,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {} finally {}''',
  );

  testStatement(
    new TryStatement(
      returnBlock1,
      [],
      returnBlock2,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {
  return;
} finally {
  return;
}''',
    limited: '''
try { return; } finally { return; }''',
  );

  testStatement(
    new TryStatement(
      emptyBlock1,
      [emptyCatchBlock],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {} catch (e) {}''',
  );

  testStatement(
    new TryStatement(
      emptyBlock1,
      [emptyCatchBlockOnVoid],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {} on void catch (e) {}''',
  );

  testStatement(
    new TryStatement(
      emptyBlock1,
      [emptyCatchBlockOnVoid, emptyCatchBlock],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {} on void catch (e) {} catch (e) {}''',
  );

  testStatement(
    new TryStatement(
      emptyBlock1,
      [emptyCatchBlockOnVoid, emptyCatchBlock],
      emptyBlock2,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {} on void catch (e) {} catch (e) {} finally {}''',
  );

  testStatement(
    new TryStatement(
      returnBlock1,
      [returnCatchBlock],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {
  return;
} catch (e) {
  return;
}''',
    limited: '''
try { return; } catch (e) { return; }''',
  );

  testStatement(
    new TryStatement(
      returnBlock1,
      [returnCatchBlockOnVoid],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {
  return;
} on void catch (e) {
  return;
}''',
    limited: '''
try { return; } on void catch (e) { return; }''',
  );

  testStatement(
    new TryStatement(
      returnBlock1,
      [returnCatchBlockOnVoid, returnCatchBlock],
      null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {
  return;
} on void catch (e) {
  return;
} catch (e) {
  return;
}''',
    limited: '''
try { return; } on void catch (e) { return; } catch (e) { return; }''',
  );

  testStatement(
    new TryStatement(
      returnBlock1,
      [returnCatchBlockOnVoid, returnCatchBlock],
      returnBlock2,
      fileOffset: TreeNode.noOffset,
    ),
    '''
try {
  return;
} on void catch (e) {
  return;
} catch (e) {
  return;
} finally {
  return;
}''',
    limited: '''
try { return; } on void catch (e) { return; } catch (e) { return; } finally { return; }''',
  );
}

void _testInternalForInStatement() {
  testStatement(
    new InternalForInStatement(
      new SingleVariableDeclarationForInElement(
        variableDeclaration: new InternalVariableDeclaration(
          new InternalLocalVariable(
            name: 'e',
            type: null,
            isImplicitlyTyped: true,
            fileOffset: -1,
          ),
          nameOffset: TreeNode.noOffset,
        ),
        error: null,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (var e in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new SingleVariableDeclarationForInElement(
        variableDeclaration: new InternalVariableDeclaration(
          new InternalLocalVariable(
            name: 'e',
            type: const VoidType(),
            isImplicitlyTyped: false,
            fileOffset: -1,
          ),
          nameOffset: TreeNode.noOffset,
        ),
        error: null,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (void e in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new PatternForInElement(
        pattern: new InternalRecordPattern(
          patterns: [
            new InternalVariablePattern(
              type: const VoidType(),
              variable: new InternalLocalVariable(
                name: 'a',
                type: null,
                fileOffset: TreeNode.noOffset,
                isImplicitlyTyped: true,
              ),
              fileOffset: TreeNode.noOffset,
            ),
            new InternalVariablePattern(
              type: null,
              variable: new InternalLocalVariable(
                name: 'b',
                type: null,
                isImplicitlyTyped: true,
                fileOffset: TreeNode.noOffset,
              ),
              fileOffset: TreeNode.noOffset,
            ),
          ],
          fileOffset: TreeNode.noOffset,
        ),
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (var (void a, var b) in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new ExistingVariableForInElement(
        variable: new InternalLocalVariable(
          name: 'a',
          type: null,
          isImplicitlyTyped: true,
          fileOffset: -1,
        ),
        nameOffset: -1,
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (a in null) {}''',
  );

  // TODO(johnniwinther,cstefantsova): Test toTextInternal for
  //  [VariableInitializationForInElement].

  testStatement(
    new InternalForInStatement(
      new InvalidForInElement(
        error: new InternalInvalidExpression(
          'error',
          fileOffset: TreeNode.noOffset,
        ),
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (<invalid:error> in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new StaticForInElement(
        target: new Field.mutable(new Name('a'), fileUri: dummyUri),
        nameOffset: -1,
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (a in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new PropertyForInElement(
        receiver: new InternalThisExpression(fileOffset: TreeNode.noOffset),
        name: new Name('a'),
        nameOffset: -1,
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (a in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new UnassignableForInElement(
        expression: new InternalNullLiteral(fileOffset: TreeNode.noOffset),
        error: new InternalInvalidExpression(
          'error',
          fileOffset: TreeNode.noOffset,
        ),
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (null in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new MultiVariableDeclarationForInElement(
        variableDeclarations: [
          new InternalVariableDeclaration(
            new InternalLocalVariable(
              name: 'a',
              type: null,
              isImplicitlyTyped: true,
              fileOffset: -1,
            ),
            nameOffset: TreeNode.noOffset,
          ),
          new InternalVariableDeclaration(
            new InternalLocalVariable(
              name: 'b',
              type: null,
              isImplicitlyTyped: true,
              fileOffset: -1,
            ),
            nameOffset: TreeNode.noOffset,
          ),
        ],
        error: new InternalInvalidExpression(
          'error',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (var a, b in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new MultiVariableDeclarationForInElement(
        variableDeclarations: [
          new InternalVariableDeclaration(
            new InternalLocalVariable(
              name: 'a',
              type: const VoidType(),
              isImplicitlyTyped: false,
              fileOffset: -1,
            ),
            nameOffset: TreeNode.noOffset,
          ),
          new InternalVariableDeclaration(
            new InternalLocalVariable(
              name: 'b',
              type: null,
              isImplicitlyTyped: true,
              fileOffset: -1,
            ),
            nameOffset: TreeNode.noOffset,
          ),
        ],
        error: new InternalInvalidExpression(
          'error',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (void a, b in null) {}''',
  );

  testStatement(
    new InternalForInStatement(
      new ExtensionForInElement(
        extension: new Extension(name: 'Extension', fileUri: dummyUri),
        thisTypeArguments: null,
        thisAccess: new InternalThisExpression(fileOffset: TreeNode.noOffset),
        name: new Name('a'),
        setter: new Procedure(
          new Name('Extension|a'),
          ProcedureKind.Method,
          new FunctionNode(null),
          fileUri: dummyUri,
        ),
        nameOffset: -1,
        inOffset: -1,
      ),
      new InternalNullLiteral(fileOffset: TreeNode.noOffset),
      new InternalBlock(
        [],
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
      isAsync: false,
      fileOffset: -1,
      bodyOffset: -1,
    ),
    '''
for (a in null) {}''',
  );
}

void _testSwitchCaseImpl() {
  InternalExpression expression = new InternalNullLiteral(
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression case0 = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression case1 = new InternalIntLiteral(
    1,
    '1',
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression case2 = new InternalIntLiteral(
    2,
    '2',
    fileOffset: TreeNode.noOffset,
  );
  InternalBlock emptyBlock = new InternalBlock(
    [],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock1 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock2 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );

  testStatement(
    new InternalRegularSwitchStatement(
      expression: expression,
      cases: [
        new InternalSwitchStatementCase(
          caseOffsets: [0],
          expressions: [case0],
          expressionOffsets: [0],
          body: emptyBlock,
          isDefault: false,
          labels: null,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  case 0:
}''',
    limited: '''
switch (null) { case 0: }''',
  );

  testStatement(
    new InternalRegularSwitchStatement(
      expression: expression,
      cases: [
        new InternalSwitchStatementCase(
          caseOffsets: [],
          expressions: [],
          expressionOffsets: [0],
          body: emptyBlock,
          labels: null,
          isDefault: true,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  default:
}''',
    limited: '''
switch (null) { default: }''',
  );

  testStatement(
    new InternalRegularSwitchStatement(
      expression: expression,
      cases: [
        new InternalSwitchStatementCase(
          caseOffsets: [0, 1],
          expressions: [case0, case1],
          expressionOffsets: [0, 1],
          body: returnBlock1,
          isDefault: false,
          labels: null,
          fileOffset: TreeNode.noOffset,
        ),
        new InternalSwitchStatementCase(
          caseOffsets: [0],
          expressions: [case2],
          expressionOffsets: [0],
          body: returnBlock2,
          isDefault: true,
          labels: [new Label('foo', TreeNode.noOffset)],
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  case 0:
  case 1:
    return;
  foo:
  case 2:
  default:
    return;
}''',
    limited: '''
switch (null) { case 0: case 1: return; foo: case 2: default: return; }''',
  );
}

void _testPatternSwitchStatement() {
  InternalExpression expression = new InternalNullLiteral(
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case0 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: null,
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case1 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: null,
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case2 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );
  InternalBlock emptyBlock = new InternalBlock(
    [],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock1 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );
  InternalBlock returnBlock2 = new InternalBlock(
    [
      new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
    ],
    fileOffset: TreeNode.noOffset,
    fileEndOffset: TreeNode.noOffset,
  );

  testStatement(
    new InternalPatternSwitchStatement(
      expression: expression,
      cases: [
        new InternalPatternSwitchCase(
          caseOffsets: [0],
          patternGuards: [case0],
          body: emptyBlock,
          isDefault: false,
          labels: null,
          jointVariables: [],
          jointVariableFirstUseOffsets: null,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  case 0:
}''',
    limited: '''
switch (null) { case 0: }''',
  );

  testStatement(
    new InternalPatternSwitchStatement(
      expression: expression,
      cases: [
        new InternalPatternSwitchCase(
          caseOffsets: [],
          patternGuards: [],
          body: emptyBlock,
          labels: null,
          isDefault: true,
          jointVariables: [],
          jointVariableFirstUseOffsets: null,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  default:
}''',
    limited: '''
switch (null) { default: }''',
  );

  testStatement(
    new InternalPatternSwitchStatement(
      expression: expression,
      cases: [
        new InternalPatternSwitchCase(
          caseOffsets: [0, 1],
          patternGuards: [case0, case1],
          body: returnBlock1,
          labels: null,
          isDefault: false,
          jointVariables: [],
          jointVariableFirstUseOffsets: null,
          fileOffset: TreeNode.noOffset,
        ),
        new InternalPatternSwitchCase(
          caseOffsets: [2],
          patternGuards: [case2],
          body: returnBlock2,
          labels: [new Label('label', TreeNode.noOffset)],
          isDefault: true,
          jointVariables: [],
          jointVariableFirstUseOffsets: null,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) {
  case 0:
  case 1:
    return;
  label:
  case 2 when 3:
  default:
    return;
}''',
    limited: '''
switch (null) { case 0: case 1: return; label: case 2 when 3: default: return; }''',
  );
}

void _testSwitchExpression() {
  InternalExpression expression = new InternalNullLiteral(
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case0 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: null,
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case1 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: null,
    fileOffset: TreeNode.noOffset,
  );
  InternalPatternGuard case2 = new InternalPatternGuard(
    pattern: new InternalConstantPattern(
      expression: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    guard: new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression body0 = new InternalIntLiteral(
    4,
    '4',
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression body1 = new InternalIntLiteral(
    5,
    '5',
    fileOffset: TreeNode.noOffset,
  );
  InternalExpression body2 = new InternalIntLiteral(
    6,
    '6',
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new InternalSwitchExpression(
      expression: expression,
      cases: [
        new InternalSwitchExpressionCase(
          patternGuard: case0,
          expression: body0,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) { case 0 => 4 }''',
    limited: '''
switch (null) { case 0 => 4 }''',
  );

  testExpression(
    new InternalSwitchExpression(
      expression: expression,
      cases: [
        new InternalSwitchExpressionCase(
          patternGuard: case0,
          expression: body0,
          fileOffset: TreeNode.noOffset,
        ),
        new InternalSwitchExpressionCase(
          patternGuard: case1,
          expression: body1,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) { case 0 => 4, case 1 => 5 }''',
    limited: '''
switch (null) { case 0 => 4, case 1 => 5 }''',
  );

  testExpression(
    new InternalSwitchExpression(
      expression: expression,
      cases: [
        new InternalSwitchExpressionCase(
          patternGuard: case0,
          expression: body0,
          fileOffset: TreeNode.noOffset,
        ),
        new InternalSwitchExpressionCase(
          patternGuard: case1,
          expression: body1,
          fileOffset: TreeNode.noOffset,
        ),
        new InternalSwitchExpressionCase(
          patternGuard: case2,
          expression: body2,
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
switch (null) { case 0 => 4, case 1 => 5, case 2 when 3 => 6 }''',
    limited: '''
switch (null) { case 0 => 4, case 1 => 5, case 2 when 3 => 6 }''',
  );
}

void _testBreakStatement() {
  testStatement(
    new InternalBreakStatement(label: null, fileOffset: TreeNode.noOffset),
    '''
break;''',
  );
  testStatement(
    new InternalBreakStatement(label: 'label', fileOffset: TreeNode.noOffset),
    '''
break label;''',
  );
}

void _testContinueStatement() {
  testStatement(
    new InternalContinueStatement(label: null, fileOffset: TreeNode.noOffset),
    '''
continue;''',
  );
  testStatement(
    new InternalContinueStatement(
      label: 'label',
      fileOffset: TreeNode.noOffset,
    ),
    '''
continue label;''',
  );
}

void _testCascade() {
  // TODO(johnniwinther): Add better text representation support for internal
  //  synthetic variables.
  InternalSyntheticVariable variable = new InternalSyntheticVariable(
    name: '#0',
    isFinal: true,
    isImplicitlyTyped: false,
    fileOffset: TreeNode.noOffset,
  );
  Cascade cascade = new Cascade(
    variable: variable,
    receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
    isNullAware: false,
    fileOffset: TreeNode.noOffset,
  );
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {} => #0''');

  cascade.addCascadeExpression(
    new PropertySet(
      new InternalVariableGet(variable, fileOffset: TreeNode.noOffset),
      new Name('foo'),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      forEffect: false,
      readOnlyReceiver: false,
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
  );
  testExpression(
    cascade,
    '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
} => #0''',
    limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; } => #0''',
  );

  cascade.addCascadeExpression(
    new PropertySet(
      new InternalVariableGet(variable, fileOffset: TreeNode.noOffset),
      new Name('bar'),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      forEffect: false,
      readOnlyReceiver: false,
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
  );
  testExpression(
    cascade,
    '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
  #0.bar = 2;
} => #0''',
    limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; #0.bar = 2; } => #0''',
  );
}

void _testDeferredCheck() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  LibraryDependency dependency = LibraryDependency.deferredImport(
    library,
    'pre',
  );
  testExpression(
    new DeferredCheck(
      dependency: dependency,
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
let final dynamic # = pre.checkLibraryIsLoaded() in 0''',
  );
}

void _testFactoryConstructorInvocation() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Procedure factoryConstructor = new Procedure(
    new Name(''),
    ProcedureKind.Factory,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(factoryConstructor);

  testExpression(
    new FactoryConstructorInvocation(
      target: factoryConstructor,
      typeArguments: null,
      arguments: _emptyArguments,
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Class()''',
    verbose: '''
new library test:dummy::Class()''',
  );

  testExpression(
    new FactoryConstructorInvocation(
      target: factoryConstructor,
      typeArguments: null,
      arguments: _emptyArguments,
      isConst: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
const Class()''',
    verbose: '''
const library test:dummy::Class()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument = new InternalNamedExpression(
    name: 'bar',
    value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new FactoryConstructorInvocation(
      target: factoryConstructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Class<void>(0, bar: 1)''',
    verbose: '''
new library test:dummy::Class<void>(0, bar: 1)''',
  );

  factoryConstructor.name = new Name('foo');
  testExpression(
    new FactoryConstructorInvocation(
      target: factoryConstructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Class<void>.foo(0, bar: 1)''',
    verbose: '''
new library test:dummy::Class<void>.foo(0, bar: 1)''',
  );
}

void _testTypeAliasedConstructorInvocation(CompilerContext c) {
  DillTarget dillTarget = new DillTarget(
    c,
    new Ticker(),
    new UriTranslator(
      c.options,
      new TargetLibrariesSpecification('dummy'),
      new PackageConfig([]),
    ),
    new NoneTarget(new TargetFlags()),
  );
  DillLoader dillLoader = new DillLoader(dillTarget);
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Constructor constructor = new Constructor(
    new FunctionNode(null),
    name: new Name(''),
    fileUri: dummyUri,
  );
  cls.addConstructor(constructor);
  DillLibraryBuilder libraryBuilder = new DillLibraryBuilder(
    library,
    dillLoader,
  );
  Typedef typedef = new Typedef(
    'Typedef',
    new InterfaceType(cls, Nullability.nonNullable),
    fileUri: dummyUri,
  );
  library.addTypedef(typedef);
  TypeAliasBuilder typeAliasBuilder = new DillTypeAliasBuilder(
    typedef,
    null,
    libraryBuilder,
  );

  testExpression(
    new TypeAliasedConstructorInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: constructor,
      typeArguments: null,
      arguments: _emptyArguments,
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef()''',
    verbose: '''
new library test:dummy::Typedef()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument = new InternalNamedExpression(
    name: 'bar',
    value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new TypeAliasedConstructorInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: constructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef<void>(0, bar: 1)''',
    verbose: '''
new library test:dummy::Typedef<void>(0, bar: 1)''',
  );

  constructor.name = new Name('foo');
  testExpression(
    new TypeAliasedConstructorInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: constructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef<void>.foo(0, bar: 1)''',
    verbose: '''
new library test:dummy::Typedef<void>.foo(0, bar: 1)''',
  );

  constructor.name = new Name('foo');
  testExpression(
    new TypeAliasedConstructorInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: constructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
const Typedef<void>.foo(0, bar: 1)''',
    verbose: '''
const library test:dummy::Typedef<void>.foo(0, bar: 1)''',
  );
}

void _testTypeAliasedFactoryInvocation(CompilerContext c) {
  DillTarget dillTarget = new DillTarget(
    c,
    new Ticker(),
    new UriTranslator(
      c.options,
      new TargetLibrariesSpecification('dummy'),
      new PackageConfig([]),
    ),
    new NoneTarget(new TargetFlags()),
  );
  DillLoader dillLoader = new DillLoader(dillTarget);
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Procedure factoryConstructor = new Procedure(
    new Name(''),
    ProcedureKind.Factory,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(factoryConstructor);
  DillLibraryBuilder libraryBuilder = new DillLibraryBuilder(
    library,
    dillLoader,
  );
  Typedef typedef = new Typedef(
    'Typedef',
    new InterfaceType(cls, Nullability.nonNullable),
    fileUri: dummyUri,
  );
  library.addTypedef(typedef);
  TypeAliasBuilder typeAliasBuilder = new DillTypeAliasBuilder(
    typedef,
    null,
    libraryBuilder,
  );

  testExpression(
    new TypeAliasedFactoryInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: factoryConstructor,
      typeArguments: null,
      arguments: _emptyArguments,
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef()''',
    verbose: '''
new library test:dummy::Typedef()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument = new InternalNamedExpression(
    name: 'bar',
    value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new TypeAliasedFactoryInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: factoryConstructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef<void>(0, bar: 1)''',
    verbose: '''
new library test:dummy::Typedef<void>(0, bar: 1)''',
  );

  factoryConstructor.name = new Name('foo');
  testExpression(
    new TypeAliasedFactoryInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: factoryConstructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
new Typedef<void>.foo(0, bar: 1)''',
    verbose: '''
new library test:dummy::Typedef<void>.foo(0, bar: 1)''',
  );

  factoryConstructor.name = new Name('foo');
  testExpression(
    new TypeAliasedFactoryInvocation(
      typeAliasBuilder: typeAliasBuilder,
      target: factoryConstructor,
      typeArguments: new TypeArguments([const VoidType()]),
      arguments: new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isConst: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
const Typedef<void>.foo(0, bar: 1)''',
    verbose: '''
const library test:dummy::Typedef<void>.foo(0, bar: 1)''',
  );
}

void _testFunctionDeclarationImpl() {
  testStatement(
    new InternalFunctionDeclaration(
        variable: new InternalLocalFunctionVariable(
          name: 'foo',
          type: null,
          isImplicitlyTyped: true,
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      )
      ..function = new InternalFunctionNode(
        returnType: const DynamicType(),
        typeParameters: [],
        positionalParameters: [],
        namedParameters: [],
        requiredParameterCount: 0,
        asyncMarker: AsyncMarker.Sync,
        body: new InternalBlock(
          [],
          fileOffset: TreeNode.noOffset,
          fileEndOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
        fileEndOffset: TreeNode.noOffset,
      ),
    '''
dynamic foo() {}''',
  );
}

void _testIfNullExpression() {
  testExpression(
    new IfNullExpression(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 ?? 1''',
  );
}

void _testIntLiterals() {
  testExpression(
    new InternalIntLiteral(0, null, fileOffset: TreeNode.noOffset),
    '0',
  );
  testExpression(
    new InternalIntLiteral(0, 'foo', fileOffset: TreeNode.noOffset),
    'foo',
  );
  testExpression(
    new LargeIntLiteral('bar', 'bar', fileOffset: TreeNode.noOffset),
    'bar',
  );
}

void _testInternalMethodInvocation() {
  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      null,
      _emptyArguments,
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0.boz()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    1,
    '1',
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument1 = new InternalNamedExpression(
    name: 'foo',
    value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument2 = new InternalNamedExpression(
    name: 'bar',
    value: new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      new TypeArguments([const VoidType(), const DynamicType()]),
      new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument1),
          new NamedArgument(namedArgument2),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0.boz<void, dynamic>(1, foo: 2, bar: 3)''',
  );
  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      null,
      _emptyArguments,
      isNullAware: true,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0?.boz()''',
  );
  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      new TypeArguments([const VoidType(), const DynamicType()]),
      new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument1),
          new NamedArgument(namedArgument2),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: true,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0?.boz<void, dynamic>(1, foo: 2, bar: 3)''',
  );
}

void _testPropertyGet() {
  testExpression(
    new PropertyGet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0.boz''',
  );

  testExpression(
    new PropertyGet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      isNullAware: true,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0?.boz''',
  );
}

void _testPropertySet() {
  testExpression(
    new PropertySet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      forEffect: false,
      readOnlyReceiver: false,
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0.boz = 1''',
  );

  testExpression(
    new PropertySet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('boz'),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      forEffect: false,
      readOnlyReceiver: false,
      isNullAware: true,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0?.boz = 1''',
  );
}

void _testExpressionInvocation() {
  testExpression(
    new ExpressionInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      null,
      _emptyArguments,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    1,
    '1',
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument1 = new InternalNamedExpression(
    name: 'foo',
    value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );
  InternalNamedExpression namedArgument2 = new InternalNamedExpression(
    name: 'bar',
    value: new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new ExpressionInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new TypeArguments([const VoidType(), const DynamicType()]),
      new ActualArguments(
        argumentList: [
          new PositionalArgument(positionalArgument),
          new NamedArgument(namedArgument1),
          new NamedArgument(namedArgument2),
        ],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0<void, dynamic>(1, foo: 2, bar: 3)''',
  );
}

void _testMethodInvocation() {
  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('foo'),
      null,
      _emptyArguments,
      isNullAware: false,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0.foo()''',
  );

  testExpression(
    new MethodInvocation(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('foo'),
      null,
      _emptyArguments,
      isNullAware: true,
      isImplicitThis: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0?.foo()''',
  );
}

void _testReturnStatementImpl() {
  testStatement(
    new InternalReturnStatement(isArrow: false, fileOffset: TreeNode.noOffset),
    '''
return;''',
  );
  testStatement(
    new InternalReturnStatement(isArrow: true, fileOffset: TreeNode.noOffset),
    '''
=>;''',
  );
  testStatement(
    new InternalReturnStatement(
      isArrow: false,
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
return 0;''',
  );
  testStatement(
    new InternalReturnStatement(
      isArrow: true,
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
=> 0;''',
  );
}

void _testVariableDeclarationImpl() {
  testVariableDeclaration(
    new InternalVariableDeclaration(
      new InternalLocalVariable(
        name: 'foo',
        type: null,
        isImplicitlyTyped: false,
        fileOffset: TreeNode.noOffset,
      ),
      nameOffset: TreeNode.noOffset,
    ),
    '''
dynamic foo''',
  );
  testVariableDeclaration(
    new InternalVariableDeclaration(
      new InternalLocalVariable(
        name: 'foo',
        type: null,
        isImplicitlyTyped: false,
        fileOffset: TreeNode.noOffset,
      ),
      initializer: new InternalIntLiteral(
        0,
        '0',
        fileOffset: TreeNode.noOffset,
      ),
      nameOffset: TreeNode.noOffset,
    ),
    '''
dynamic foo = 0''',
  );
  testVariable(
    new InternalPositionalParameter(
      defaultValue: new InternalIntLiteral(
        0,
        '0',
        fileOffset: TreeNode.noOffset,
      ),
      astVariable: new PositionalParameter(
        cosmeticName: 'foo',
        type: const VoidType(),
        isFinal: true,
        isRequired: true,
      ),
      isImplicitlyTyped: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
required void foo''',
  );
  testVariableDeclaration(
    new InternalVariableDeclaration(
      new InternalLateVariable(
        name: 'foo',
        type: const VoidType(),
        isImplicitlyTyped: false,
        fileOffset: TreeNode.noOffset,
      ),
      initializer: new InternalIntLiteral(
        0,
        '0',
        fileOffset: TreeNode.noOffset,
      ),
      nameOffset: TreeNode.noOffset,
    ),
    '''
late void foo = 0''',
  );
  testVariableDeclaration(
    new InternalVariableDeclaration(
      new InternalLateVariable(
          name: 'foo',
          type: const VoidType(),
          isImplicitlyTyped: false,
          fileOffset: TreeNode.noOffset,
        )
        ..lateGetter = new LocalFunctionVariable(
          name: 'foo#getter',
          type: const VoidType(),
        ),
      initializer: new InternalIntLiteral(
        0,
        '0',
        fileOffset: TreeNode.noOffset,
      ),
      nameOffset: TreeNode.noOffset,
    ),

    '''
late void foo = 0''',
  );
  testVariableDeclaration(
    new InternalVariableDeclaration(
      new InternalLateVariable(
          name: 'foo',
          type: const DynamicType(),
          isImplicitlyTyped: false,
          fileOffset: TreeNode.noOffset,
        )
        ..lateGetter = new LocalFunctionVariable(
          name: 'foo#getter',
          type: const DynamicType(),
        )
        ..lateType = const DynamicType(),
      initializer: new InternalIntLiteral(
        0,
        '0',
        fileOffset: TreeNode.noOffset,
      ),
      nameOffset: TreeNode.noOffset,
    ),
    '''
late dynamic foo = 0''',
  );
}

void _testLoadLibraryImpl() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  LibraryDependency dependency = LibraryDependency.deferredImport(
    library,
    'pre',
  );
  testExpression(
    new InternalLoadLibrary(
      dependency,
      _emptyArguments,
      fileOffset: TreeNode.noOffset,
    ),
    '''
pre.loadLibrary()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new InternalLoadLibrary(
      dependency,
      new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
pre.loadLibrary(0)''',
  );
}

void _testLoadLibraryTearOff() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  LibraryDependency dependency = LibraryDependency.deferredImport(
    library,
    'pre',
  );
  Procedure procedure = new Procedure(
    new Name('get#loadLibrary'),
    ProcedureKind.Getter,
    new FunctionNode(new Block([])),
    fileUri: dummyUri,
  );
  testExpression(
    new LoadLibraryTearOff(
      dependency,
      procedure,
      fileOffset: TreeNode.noOffset,
    ),
    '''
pre.loadLibrary''',
  );
}

void _testIfNullPropertySet() {
  testExpression(
    new IfNullPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '0.foo ??= 1',
  );

  testExpression(
    new IfNullPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      writeOffset: -1,
      forEffect: true,
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '0.foo ??= 1',
  );

  testExpression(
    new IfNullPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '0?.foo ??= 1',
  );

  testExpression(
    new IfNullPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      writeOffset: -1,
      forEffect: true,
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '0?.foo ??= 1',
  );
}

void _testIfNullSet() {
  InternalVariable variable = new InternalLocalVariable(
    name: 'foo',
    type: const DynamicType(),
    isImplicitlyTyped: false,
    fileOffset: TreeNode.noOffset,
  );
  testExpression(
    new IfNullSet(
      read: new InternalVariableGet(variable, fileOffset: TreeNode.noOffset),
      write: new InternalVariableSet(
        variable,
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      forEffect: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
foo ?? foo = 1''',
  );

  testExpression(
    new IfNullSet(
      read: new InternalVariableGet(variable, fileOffset: TreeNode.noOffset),
      write: new InternalVariableSet(
        variable,
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      forEffect: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
foo ?? foo = 1''',
  );
}

void _testExtensionCompoundSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(
    new Name('E|get#foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  Procedure setter = new Procedure(
    new Name('E|set#foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(setter);

  testExpression(
    new ExtensionCompoundSet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: name,
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0).foo -= 1''',
  );

  testExpression(
    new ExtensionCompoundSet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: name,
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)?.foo += 1''',
  );

  testExpression(
    new ExtensionCompoundSet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: name,
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0).foo += 1''',
  );

  testExpression(
    new ExtensionCompoundSet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: name,
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)?.foo -= 1''',
  );

  testExpression(
    new ExtensionCompoundSet.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: name,
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
    ),
    '''
0.foo += 1''',
  );
}

void _testCompoundPropertySet() {
  testExpression(
    new CompoundPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: TreeNode.noOffset,
      binaryOffset: TreeNode.noOffset,
      writeOffset: TreeNode.noOffset,
      forEffect: false,
      isNullAware: false,
    ),
    '''
0.foo += 1''',
  );

  testExpression(
    new CompoundPropertySet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      propertyName: new Name('foo'),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: TreeNode.noOffset,
      binaryOffset: TreeNode.noOffset,
      writeOffset: TreeNode.noOffset,
      forEffect: false,
      isNullAware: true,
    ),
    '''
0?.foo += 1''',
  );
}

void _testPropertyIncDec() {
  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: false,
      forEffect: false,
      isInc: true,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
0.foo++''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: false,
      forEffect: false,
      isInc: false,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
0.foo--''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: true,
      forEffect: false,
      isInc: true,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
0?.foo++''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: true,
      forEffect: false,
      isInc: false,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
0?.foo--''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: false,
      forEffect: false,
      isInc: true,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
++0.foo''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: false,
      forEffect: false,
      isInc: false,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
--0.foo''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: true,
      forEffect: false,
      isInc: true,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
++0?.foo''',
  );

  testExpression(
    new PropertyIncDec(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: new Name('foo'),
      isNullAware: true,
      forEffect: false,
      isInc: false,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
      isImplicitThis: false,
    ),
    '''
--0?.foo''',
  );
}

void _testLocalIncDec() {
  InternalLocalVariable variable = new InternalLocalVariable(
    name: 'foo',
    type: null,
    isImplicitlyTyped: true,
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new LocalIncDec(
      variable: variable,
      forEffect: false,
      isInc: true,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
foo++''',
  );

  testExpression(
    new LocalIncDec(
      variable: variable,
      forEffect: false,
      isInc: false,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
foo--''',
  );

  testExpression(
    new LocalIncDec(
      variable: variable,
      forEffect: false,
      isInc: true,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
++foo''',
  );

  testExpression(
    new LocalIncDec(
      variable: variable,
      forEffect: false,
      isInc: false,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
--foo''',
  );
}

void _testStaticIncDec() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Name name = new Name('foo');
  Field field = new Field.mutable(name, fileUri: dummyUri);
  library.addField(field);

  testExpression(
    new StaticIncDec(
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: true,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
foo++''',
  );

  testExpression(
    new StaticIncDec(
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: false,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
foo--''',
  );

  testExpression(
    new StaticIncDec(
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: true,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
++foo''',
  );

  testExpression(
    new StaticIncDec(
      getter: field,
      name: name,
      setter: field,
      forEffect: false,
      isInc: false,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
--foo''',
  );
}

void _testSuperPostIncDec() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Name name = new Name('foo');
  Field field = new Field.mutable(name, fileUri: dummyUri);
  cls.addField(field);

  testExpression(
    new SuperIncDec(
      receiver: new InternalThisExpression(fileOffset: -1),
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: true,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
super.foo++''',
  );

  testExpression(
    new SuperIncDec(
      receiver: new InternalThisExpression(fileOffset: -1),
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: false,
      isPost: true,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
super.foo--''',
  );

  testExpression(
    new SuperIncDec(
      receiver: new InternalThisExpression(fileOffset: -1),
      getter: field,
      setter: field,
      name: name,
      forEffect: false,
      isInc: true,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
++super.foo''',
  );

  testExpression(
    new SuperIncDec(
      receiver: new InternalThisExpression(fileOffset: -1),
      getter: field,
      name: name,
      setter: field,
      forEffect: false,
      isInc: false,
      isPost: false,
      nameOffset: -1,
      operatorOffset: -1,
    ),
    '''
--super.foo''',
  );
}

void _testIndexGet() {
  testExpression(
    new IndexGet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0[1]''',
  );

  testExpression(
    new IndexGet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0?[1]''',
  );
}

void _testIndexSet() {
  testExpression(
    new IndexSet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      forEffect: false,
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0[1] = 2''',
  );

  testExpression(
    new IndexSet(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      forEffect: false,
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0?[1] = 2''',
  );
}

void _testSuperIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Super', fileUri: dummyUri);
  library.addClass(cls);
  Procedure setter = new Procedure(
    new Name('[]='),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(setter);

  testExpression(
    new SuperIndexSet(
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
super[0] = 1''',
  );
}

void _testExtensionIndexGet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Procedure getter = new Procedure(
    new Name(''),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(getter);

  testExpression(
    new ExtensionIndexGet(
      extension,
      null,
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)[1]''',
  );

  testExpression(
    new ExtensionIndexGet(
      extension,
      null,
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?[1]''',
  );

  testExpression(
    new ExtensionIndexGet(
      extension,
      new TypeArguments([const VoidType()]),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)[1]''',
  );

  testExpression(
    new ExtensionIndexGet(
      extension,
      new TypeArguments([const VoidType()]),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?[1]''',
  );
}

void _testExtensionIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Procedure setter = new Procedure(
    new Name(''),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(setter);

  testExpression(
    new ExtensionIndexSet(
      extension,
      null,
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      setter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)[1] = 2''',
  );

  testExpression(
    new ExtensionIndexSet(
      extension,
      null,
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      setter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?[1] = 2''',
  );

  testExpression(
    new ExtensionIndexSet(
      extension,
      new TypeArguments([const VoidType()]),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      setter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)[1] = 2''',
  );

  testExpression(
    new ExtensionIndexSet(
      extension,
      new TypeArguments([const VoidType()]),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      setter,
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?[1] = 2''',
  );
}

void _testIfNullIndexSet() {
  testExpression(
    new IfNullIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: false,
    ),
    '''
0[1] ??= 2''',
  );

  testExpression(
    new IfNullIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: true,
    ),
    '''
0?[1] ??= 2''',
  );
}

void _testIfNullSuperIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Super', fileUri: dummyUri);
  library.addClass(cls);
  Procedure getter = new Procedure(
    new Name('[]'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(getter);
  Procedure setter = new Procedure(
    new Name('[]='),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(setter);

  testExpression(
    new IfNullSuperIndexSet(
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
    ),
    '''
super[0] ??= 1''',
  );
}

void _testExtensionIfNullIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Procedure getter = new Procedure(
    new Name('Extension|[]'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  Procedure setter = new Procedure(
    new Name('Extension|[]='),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(getter);
  library.addProcedure(setter);

  testExpression(
    new ExtensionIfNullIndexSet(
      extension: extension,
      knownTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)[1] ??= 2''',
  );

  testExpression(
    new ExtensionIfNullIndexSet(
      extension: extension,
      knownTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)?[1] ??= 2''',
  );

  testExpression(
    new ExtensionIfNullIndexSet(
      extension: extension,
      knownTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)[1] ??= 2''',
  );

  testExpression(
    new ExtensionIfNullIndexSet(
      extension: extension,
      knownTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      testOffset: -1,
      writeOffset: -1,
      forEffect: false,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)?[1] ??= 2''',
  );
}

void _testCompoundIndexSet() {
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: false,
      isNullAware: false,
    ),
    '''
0[1] += 2''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: false,
    ),
    '''
0[1]++''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('-'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: false,
    ),
    '''
0[1]--''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('*'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: false,
    ),
    '''
0[1] *= 1''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: false,
    ),
    '''
0[1] += 2''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: false,
      isNullAware: true,
    ),
    '''
0?[1] += 2''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('+'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: true,
    ),
    '''
0?[1]++''',
  );
  testExpression(
    new CompoundIndexSet(
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: new Name('-'),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
      isNullAware: true,
    ),
    '''
0?[1]--''',
  );
}

void _testCompoundSuperIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Super', fileUri: dummyUri);
  library.addClass(cls);
  Procedure getter = new Procedure(
    new Name('[]'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(getter);
  Procedure setter = new Procedure(
    new Name('[]='),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  cls.addProcedure(setter);

  testExpression(
    new CompoundSuperIndexSet(
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: plusName,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: false,
    ),
    '''
super[0] += 1''',
  );
  testExpression(
    new CompoundSuperIndexSet(
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: minusName,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: false,
    ),
    '''
super[0] -= 1''',
  );

  testExpression(
    new CompoundSuperIndexSet(
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: plusName,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
    ),
    '''
super[0]++''',
  );
  testExpression(
    new CompoundSuperIndexSet(
      getter: getter,
      setter: setter,
      index: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      binaryName: minusName,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forEffect: false,
      forPostIncDec: true,
    ),
    '''
super[0]--''',
  );
}

void _testExtensionCompoundIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Procedure getter = new Procedure(
    new Name('[]'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  Procedure setter = new Procedure(
    new Name('[]='),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(setter);

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)[1] -= 2''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)?[1] += 2''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)[1]--''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension(0)?[1]++''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: new TypeArguments([const VoidType()]),
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)[1] += 2''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: new TypeArguments([const VoidType()]),
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: false,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)?[1] -= 2''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: new TypeArguments([const VoidType()]),
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('+'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)[1]++''',
  );

  testExpression(
    new ExtensionCompoundIndexSet(
      extension: extension,
      explicitTypeArguments: new TypeArguments([const VoidType()]),
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      getter: getter,
      setter: setter,
      binaryName: new Name('-'),
      index: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      rhs: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      readOffset: -1,
      binaryOffset: -1,
      writeOffset: -1,
      forPostIncDec: true,
      extensionTypeArgumentOffset: -1,
    ),
    '''
Extension<void>(0)?[1]--''',
  );
}

void _testExtensionGet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(
    new Name('Extension|get#foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(getter);

  testExpression(
    new ExtensionGet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo''',
  );

  testExpression(
    new ExtensionGet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo''',
  );

  testExpression(
    new ExtensionGet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo''',
  );

  testExpression(
    new ExtensionGet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo''',
  );

  testExpression(
    new ExtensionGet.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo''',
  );
}

void _testExtensionGetterInvocation() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure method = new Procedure(
    new Name('Extension|foo'),
    ProcedureKind.Getter,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(method);

  InternalExpression positionalArgument = new InternalIntLiteral(
    1,
    '1',
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new ExtensionGetterInvocation.explicit(
      extension: extension,
      explicitTypeArguments: null,
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo(1)''',
  );

  testExpression(
    new ExtensionGetterInvocation.explicit(
      extension: extension,
      explicitTypeArguments: null,
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo(1)''',
  );

  testExpression(
    new ExtensionGetterInvocation.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo(1)''',
  );

  testExpression(
    new ExtensionGetterInvocation.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo(1)''',
  );

  testExpression(
    new ExtensionGetterInvocation.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo(1)''',
  );
}

void _testExtensionMethodInvocation() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure method = new Procedure(
    new Name('Extension|foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(method);

  InternalExpression positionalArgument = new InternalIntLiteral(
    1,
    '1',
    fileOffset: TreeNode.noOffset,
  );

  testExpression(
    new ExtensionMethodInvocation.explicit(
      extension: extension,
      explicitTypeArguments: null,
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo(1)''',
  );

  testExpression(
    new ExtensionMethodInvocation.explicit(
      extension: extension,
      explicitTypeArguments: null,
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo(1)''',
  );

  testExpression(
    new ExtensionMethodInvocation.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo(1)''',
  );

  testExpression(
    new ExtensionMethodInvocation.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      extensionTypeArgumentOffset: -1,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo(1)''',
  );

  testExpression(
    new ExtensionMethodInvocation.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      target: method,
      typeArguments: null,
      arguments: new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo(1)''',
  );
}

void _testExtensionPostIncDec() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(
    new Name('Extension|foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  Procedure setter = new Procedure(
    new Name('Extension|foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(getter);
  library.addProcedure(setter);

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: true,
      isInc: true,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo++''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: true,
      isInc: false,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo--''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: true,
      isInc: false,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo--''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: true,
      isInc: true,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo++''',
  );

  testExpression(
    new ExtensionIncDec.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: true,
      isInc: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo++''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: false,
      isInc: true,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
++Extension(0).foo''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: false,
      isInc: false,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
--Extension(0)?.foo''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: false,
      isInc: false,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
--Extension<void>(0).foo''',
  );

  testExpression(
    new ExtensionIncDec.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: false,
      isInc: true,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
++Extension<void>(0)?.foo''',
  );

  testExpression(
    new ExtensionIncDec.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      getter: getter,
      setter: setter,
      forEffect: false,
      isPost: false,
      isInc: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
++0.foo''',
  );
}

void _testExtensionSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure setter = new Procedure(
    new Name('Extension|set#foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(setter);

  testExpression(
    new ExtensionSet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      setter: setter,
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo = 1''',
  );

  testExpression(
    new ExtensionSet.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      setter: setter,
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo = 1''',
  );

  testExpression(
    new ExtensionSet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      setter: setter,
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      forEffect: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo = 1''',
  );

  testExpression(
    new ExtensionSet.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      setter: setter,
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      forEffect: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo = 1''',
  );

  testExpression(
    new ExtensionSet.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      setter: setter,
      value: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      forEffect: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo = 1''',
  );
}

void _testPropertySetImpl() {}

void _testExtensionTearOff() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
    name: 'Extension',
    typeParameters: [new TypeParameter('T')],
    fileUri: dummyUri,
  );
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure tearOff = new Procedure(
    new Name('Extension|get#foo'),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );
  library.addProcedure(tearOff);

  testExpression(
    new ExtensionTearOff.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      tearOff: tearOff,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0).foo''',
  );

  testExpression(
    new ExtensionTearOff.explicit(
      extension: extension,
      explicitTypeArguments: null,
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      tearOff: tearOff,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension(0)?.foo''',
  );

  testExpression(
    new ExtensionTearOff.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      tearOff: tearOff,
      isNullAware: false,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0).foo''',
  );

  testExpression(
    new ExtensionTearOff.explicit(
      extension: extension,
      explicitTypeArguments: [const VoidType()],
      receiver: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      tearOff: tearOff,
      isNullAware: true,
      extensionTypeArgumentOffset: -1,
      fileOffset: TreeNode.noOffset,
    ),
    '''
Extension<void>(0)?.foo''',
  );

  testExpression(
    new ExtensionTearOff.implicit(
      extension: extension,
      thisTypeArguments: [
        new TypeParameterType(
          extension.typeParameters.single,
          Nullability.undetermined,
        ),
      ],
      thisAccess: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      name: name,
      tearOff: tearOff,
      fileOffset: TreeNode.noOffset,
    ),
    '''
0.foo''',
  );
}

void _testEqualsExpression() {
  testExpression(
    new EqualsExpression(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNot: false,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 == 1''',
  );
  testExpression(
    new EqualsExpression(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      isNot: true,
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 != 1''',
  );
}

void _testBinaryExpression() {
  testExpression(
    new BinaryExpression(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      new Name('+'),
      new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 + 1''',
  );
  testExpression(
    new BinaryExpression(
      new BinaryExpression(
        new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
        new Name('-'),
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      new Name('+'),
      new BinaryExpression(
        new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
        new Name('-'),
        new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 - 1 + 2 - 3''',
  );
  testExpression(
    new BinaryExpression(
      new BinaryExpression(
        new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
        new Name('*'),
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      new Name('+'),
      new BinaryExpression(
        new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
        new Name('/'),
        new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 * 1 + 2 / 3''',
  );
  testExpression(
    new BinaryExpression(
      new BinaryExpression(
        new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
        new Name('+'),
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      new Name('*'),
      new BinaryExpression(
        new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
        new Name('-'),
        new InternalIntLiteral(3, '3', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
0 + 1 * 2 - 3''',
  );
}

void _testUnaryExpression() {
  testExpression(
    new UnaryExpression(
      new Name('unary-'),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
-0''',
  );
  testExpression(
    new UnaryExpression(
      new Name('~'),
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
~0''',
  );

  testExpression(
    new UnaryExpression(
      new Name('unary-'),
      new BinaryExpression(
        new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
        new Name('+'),
        new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    // TODO(johnniwinther): Support precedence in internal expressions.
    '''
-0 + 1''',
  );
}

void _testParenthesizedExpression() {
  testExpression(
    new ParenthesizedExpression(
      new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
(0)''',
  );
}

void _testSpreadElement() {
  testElement(
    new SpreadElement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      isNullAware: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
...0''',
  );
  testElement(
    new SpreadElement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      isNullAware: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
...?0''',
  );
}

void _testIfElement() {
  testElement(
    new IfElement(
      condition: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      then: new ExpressionElement(
        expression: new InternalIntLiteral(
          1,
          '1',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0) 1''',
  );
  testElement(
    new IfElement(
      condition: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      then: new ExpressionElement(
        expression: new InternalIntLiteral(
          1,
          '1',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: new ExpressionElement(
        expression: new InternalIntLiteral(
          2,
          '2',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0) 1 else 2''',
  );
}

void _testForElement() {}

void _testForInElement() {}

void _testSpreadMapEntry() {}

void _testIfMapEntry() {}

void _testForMapEntry() {}

void _testForInMapEntry() {}

void _testExpressionMatcher() {
  testPattern(
    new InternalConstantPattern(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0''',
  );

  testPattern(
    new InternalConstantPattern(
      expression: new InternalBoolLiteral(true, fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
true''',
  );
}

void _testBinaryMatcher() {
  testPattern(
    new InternalAndPattern(
      new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      new InternalConstantPattern(
        expression: new InternalIntLiteral(
          1,
          '1',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0 && 1''',
  );

  testPattern(
    new InternalOrPattern(
      new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      new InternalConstantPattern(
        expression: new InternalIntLiteral(
          1,
          '1',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      orPatternJointVariables: [],
      fileOffset: TreeNode.noOffset,
    ),
    '''
0 || 1''',
  );
}

void _testCastMatcher() {
  testPattern(
    new InternalCastPattern(
      new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      const DynamicType(),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0 as dynamic''',
  );
}

void _testNullAssertMatcher() {
  testPattern(
    new InternalNullAssertPattern(
      pattern: new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0!''',
  );
}

void _testNullCheckMatcher() {
  testPattern(
    new InternalNullCheckPattern(
      pattern: new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
0?''',
  );
}

void _testListMatcher() {
  testPattern(
    new InternalListPattern(
      typeArgument: const DynamicType(),
      patterns: [
        new InternalConstantPattern(
          expression: new InternalIntLiteral(
            0,
            '0',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        new InternalConstantPattern(
          expression: new InternalIntLiteral(
            1,
            '1',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
<dynamic>[0, 1]''',
  );
}

void _testRelationalMatcher() {
  testPattern(
    new InternalRelationalPattern(
      kind: RelationalPatternKind.equals,
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
== 0''',
  );
  testPattern(
    new InternalRelationalPattern(
      kind: RelationalPatternKind.notEquals,
      expression: new InternalIntLiteral(1, '1', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
!= 1''',
  );
  testPattern(
    new InternalRelationalPattern(
      kind: RelationalPatternKind.lessThan,
      expression: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
      fileOffset: TreeNode.noOffset,
    ),
    '''
< 2''',
  );
}

void _testMapMatcher() {
  testPattern(
    new InternalMapPattern(
      keyType: null,
      valueType: null,
      entries: [],
      fileOffset: TreeNode.noOffset,
    ),
    '''
{}''',
  );
  testPattern(
    new InternalMapPattern(
      keyType: const DynamicType(),
      valueType: const DynamicType(),
      entries: [],
      fileOffset: TreeNode.noOffset,
    ),
    '''
<dynamic, dynamic>{}''',
  );
  testPattern(
    new InternalMapPattern(
      keyType: null,
      valueType: null,
      entries: [
        new InternalMapPatternEntry(
          key: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
          value: new InternalConstantPattern(
            expression: new InternalIntLiteral(
              1,
              '1',
              fileOffset: TreeNode.noOffset,
            ),
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
{0: 1}''',
  );
  testPattern(
    new InternalMapPattern(
      keyType: null,
      valueType: null,
      entries: [
        new InternalMapPatternEntry(
          key: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
          value: new InternalConstantPattern(
            expression: new InternalIntLiteral(
              1,
              '1',
              fileOffset: TreeNode.noOffset,
            ),
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        new InternalMapPatternEntry(
          key: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
          value: new InternalConstantPattern(
            expression: new InternalIntLiteral(
              3,
              '3',
              fileOffset: TreeNode.noOffset,
            ),
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
      ],
      fileOffset: TreeNode.noOffset,
    ),
    '''
{0: 1, 2: 3}''',
  );
}

void _testIfCaseStatement() {
  testStatement(
    new InternalIfCaseStatement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      patternGuard: new InternalPatternGuard(
        pattern: new InternalConstantPattern(
          expression: new InternalIntLiteral(
            1,
            '1',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        guard: null,
        fileOffset: TreeNode.noOffset,
      ),
      then: new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0 case 1) return;''',
  );

  testStatement(
    new InternalIfCaseStatement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      patternGuard: new InternalPatternGuard(
        pattern: new InternalConstantPattern(
          expression: new InternalIntLiteral(
            1,
            '1',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        guard: null,
        fileOffset: TreeNode.noOffset,
      ),
      then: new InternalReturnStatement(
        expression: new InternalIntLiteral(
          2,
          '2',
          fileOffset: TreeNode.noOffset,
        ),
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: new InternalReturnStatement(
        expression: new InternalIntLiteral(
          3,
          '3',
          fileOffset: TreeNode.noOffset,
        ),
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0 case 1) return 2; else return 3;''',
  );

  testStatement(
    new InternalIfCaseStatement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      patternGuard: new InternalPatternGuard(
        pattern: new InternalConstantPattern(
          expression: new InternalIntLiteral(
            1,
            '1',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        guard: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      then: new InternalReturnStatement(
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: null,
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0 case 1 when 2) return;''',
  );

  testStatement(
    new InternalIfCaseStatement(
      expression: new InternalIntLiteral(0, '0', fileOffset: TreeNode.noOffset),
      patternGuard: new InternalPatternGuard(
        pattern: new InternalConstantPattern(
          expression: new InternalIntLiteral(
            1,
            '1',
            fileOffset: TreeNode.noOffset,
          ),
          fileOffset: TreeNode.noOffset,
        ),
        guard: new InternalIntLiteral(2, '2', fileOffset: TreeNode.noOffset),
        fileOffset: TreeNode.noOffset,
      ),
      then: new InternalReturnStatement(
        expression: new InternalIntLiteral(
          3,
          '3',
          fileOffset: TreeNode.noOffset,
        ),
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      otherwise: new InternalReturnStatement(
        expression: new InternalIntLiteral(
          4,
          '4',
          fileOffset: TreeNode.noOffset,
        ),
        isArrow: false,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
if (0 case 1 when 2) return 3; else return 4;''',
  );
}

void _testPatternVariableDeclaration() {
  testStatement(
    new InternalPatternVariableDeclaration(
      pattern: new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      initializer: new InternalIntLiteral(
        1,
        '1',
        fileOffset: TreeNode.noOffset,
      ),
      isFinal: false,
      fileOffset: TreeNode.noOffset,
    ),
    '''
var 0 = 1;''',
  );

  testStatement(
    new InternalPatternVariableDeclaration(
      pattern: new InternalConstantPattern(
        expression: new InternalIntLiteral(
          0,
          '0',
          fileOffset: TreeNode.noOffset,
        ),
        fileOffset: TreeNode.noOffset,
      ),
      initializer: new InternalIntLiteral(
        1,
        '1',
        fileOffset: TreeNode.noOffset,
      ),
      isFinal: true,
      fileOffset: TreeNode.noOffset,
    ),
    '''
final 0 = 1;''',
  );
}

void _testExtensionTypeRedirectingInitializer() {
  Procedure unnamedTarget = new Procedure(
    new Name(""),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );

  Procedure namedTarget = new Procedure(
    new Name("named"),
    ProcedureKind.Method,
    new FunctionNode(null),
    fileUri: dummyUri,
  );

  testInitializer(
    new ExtensionTypeRedirectingInitializer(
      unnamedTarget,
      _emptyArguments,
      fileOffset: TreeNode.noOffset,
    ),
    '''
this()''',
  );

  InternalExpression positionalArgument = new InternalIntLiteral(
    0,
    '0',
    fileOffset: TreeNode.noOffset,
  );

  testInitializer(
    new ExtensionTypeRedirectingInitializer(
      namedTarget,
      new ActualArguments(
        argumentList: [new PositionalArgument(positionalArgument)],
        hasNamedBeforePositional: false,
        positionalCount: 1,
        fileOffset: TreeNode.noOffset,
      ),
      fileOffset: TreeNode.noOffset,
    ),
    '''
this.named(0)''',
  );
}

ActualArguments _emptyArguments = new ActualArguments(
  argumentList: [],
  hasNamedBeforePositional: false,
  positionalCount: 0,
  fileOffset: TreeNode.noOffset,
);
