// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:front_end/src/fasta/kernel/collections.dart';
import 'package:front_end/src/fasta/kernel/forest.dart';
import 'package:front_end/src/fasta/kernel/internal_ast.dart';
import 'package:kernel/ast.dart';
import 'text_representation_test.dart';

testStatement(Statement node, String normal, {String verbose, String limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

testExpression(Expression node, String normal,
    {String verbose, String limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

final Uri dummyUri = Uri.parse('test:dummy');

main() {
  _testVariableDeclarations();
  _testTryStatement();
  _testForInStatementWithSynthesizedVariable();
  _testSwitchCaseImpl();
  _testBreakStatementImpl();
  _testCascade();
  _testDeferredCheck();
  _testFactoryConstructorInvocationJudgment();
  _testFunctionDeclarationImpl();
  _testIfNullExpression();
  _testIntLiterals();
  _testExpressionInvocation();
  _testNamedFunctionExpressionJudgment();
  _testNullAwareMethodInvocation();
  _testNullAwarePropertyGet();
  _testNullAwarePropertySet();
  _testReturnStatementImpl();
  _testVariableDeclarationImpl();
  _testVariableGetImpl();
  _testLoadLibraryImpl();
  _testLoadLibraryTearOff();
  _testIfNullPropertySet();
  _testIfNullSet();
  _testCompoundExtensionSet();
  _testCompoundPropertySet();
  _testPropertyPostIncDec();
  _testLocalPostIncDec();
  _testStaticPostIncDec();
  _testSuperPostIncDec();
  _testIndexGet();
  _testIndexSet();
  _testSuperIndexSet();
  _testExtensionIndexSet();
  _testIfNullIndexSet();
  _testIfNullSuperIndexSet();
  _testIfNullExtensionIndexSet();
  _testCompoundIndexSet();
  _testNullAwareCompoundSet();
  _testNullAwareIfNullSet();
  _testCompoundSuperIndexSet();
  _testCompoundExtensionIndexSet();
  _testExtensionSet();
  _testNullAwareExtension();
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
}

void _testVariableDeclarations() {
  testStatement(
      const Forest().variablesDeclaration(
          [new VariableDeclaration('a'), new VariableDeclaration('b')],
          dummyUri),
      '''
dynamic a, b;''');
  testStatement(
      const Forest().variablesDeclaration([
        new VariableDeclaration('a', type: const VoidType()),
        new VariableDeclaration('b', initializer: new NullLiteral())
      ], dummyUri),
      '''
void a, b = null;''');
}

void _testTryStatement() {
  Block emptyBlock1 = new Block([]);
  Block emptyBlock2 = new Block([]);
  Block returnBlock1 = new Block([new ReturnStatement()]);
  Block returnBlock2 = new Block([new ReturnStatement()]);
  Catch emptyCatchBlock =
      new Catch(new VariableDeclaration('e'), new Block([]));
  Catch emptyCatchBlockOnVoid = new Catch(
      new VariableDeclaration('e'), new Block([]),
      guard: const VoidType());
  Catch returnCatchBlock = new Catch(
      new VariableDeclaration('e'), new Block([new ReturnStatement()]));
  Catch returnCatchBlockOnVoid = new Catch(
      new VariableDeclaration('e'), new Block([new ReturnStatement()]),
      guard: const VoidType());

  testStatement(new TryStatement(emptyBlock1, [], emptyBlock2), '''
try {} finally {}''');

  testStatement(new TryStatement(returnBlock1, [], returnBlock2), '''
try {
  return;
} finally {
  return;
}''', limited: '''
try { return; } finally { return; }''');

  testStatement(new TryStatement(emptyBlock1, [emptyCatchBlock], null), '''
try {} catch (e) {}''');

  testStatement(
      new TryStatement(emptyBlock1, [emptyCatchBlockOnVoid], null), '''
try {} on void catch (e) {}''');

  testStatement(
      new TryStatement(
          emptyBlock1, [emptyCatchBlockOnVoid, emptyCatchBlock], null),
      '''
try {} on void catch (e) {} catch (e) {}''');

  testStatement(
      new TryStatement(
          emptyBlock1, [emptyCatchBlockOnVoid, emptyCatchBlock], emptyBlock2),
      '''
try {} on void catch (e) {} catch (e) {} finally {}''');

  testStatement(new TryStatement(returnBlock1, [returnCatchBlock], null), '''
try {
  return;
} catch (e) {
  return;
}''', limited: '''
try { return; } catch (e) { return; }''');

  testStatement(
      new TryStatement(returnBlock1, [returnCatchBlockOnVoid], null), '''
try {
  return;
} on void catch (e) {
  return;
}''',
      limited: '''
try { return; } on void catch (e) { return; }''');

  testStatement(
      new TryStatement(
          returnBlock1, [returnCatchBlockOnVoid, returnCatchBlock], null),
      '''
try {
  return;
} on void catch (e) {
  return;
} catch (e) {
  return;
}''',
      limited: '''
try { return; } on void catch (e) { return; } catch (e) { return; }''');

  testStatement(
      new TryStatement(returnBlock1, [returnCatchBlockOnVoid, returnCatchBlock],
          returnBlock2),
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
try { return; } on void catch (e) { return; } catch (e) { return; } finally { return; }''');
}

void _testForInStatementWithSynthesizedVariable() {
  // TODO(johnniwinther): Test ForInStatementWithSynthesizedVariable
}

void _testSwitchCaseImpl() {
  Expression expression = new NullLiteral();
  Expression case0 = new IntLiteral(0);
  Expression case1 = new IntLiteral(1);
  Expression case2 = new IntLiteral(2);
  Block emptyBlock = new Block([]);
  Block returnBlock1 = new Block([new ReturnStatement()]);
  Block returnBlock2 = new Block([new ReturnStatement()]);

  testStatement(
      new SwitchStatement(expression, [
        new SwitchCaseImpl([case0], [0], emptyBlock, hasLabel: false)
      ]),
      '''
switch (null) {
  case 0:
}''',
      limited: '''
switch (null) { case 0: }''');

  testStatement(
      new SwitchStatement(expression, [
        new SwitchCaseImpl([], [0], emptyBlock,
            hasLabel: false, isDefault: true)
      ]),
      '''
switch (null) {
  default:
}''',
      limited: '''
switch (null) { default: }''');

  testStatement(
      new SwitchStatement(expression, [
        new SwitchCaseImpl([case0, case1], [0, 1], returnBlock1,
            hasLabel: false),
        new SwitchCaseImpl([case2], [0], returnBlock2,
            hasLabel: true, isDefault: true)
      ]),
      '''
switch (null) {
  case 0:
  case 1:
    return;
  case 2:
  default:
    return;
}''',
      limited: '''
switch (null) { case 0: case 1: return; case 2: default: return; }''');
}

void _testBreakStatementImpl() {
  WhileStatement whileStatement =
      new WhileStatement(new BoolLiteral(true), new Block([]));
  LabeledStatement labeledStatement = new LabeledStatement(whileStatement);
  testStatement(
      new BreakStatementImpl(isContinue: false)
        ..target = labeledStatement
        ..targetStatement = whileStatement,
      '''
break label0;''');
  testStatement(
      new BreakStatementImpl(isContinue: true)
        ..target = labeledStatement
        ..targetStatement = whileStatement,
      '''
continue label0;''');
}

void _testCascade() {
  VariableDeclaration variable =
      new VariableDeclaration.forValue(new IntLiteral(0));
  Cascade cascade = new Cascade(variable, isNullAware: false);
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {} => #0''');

  cascade.addCascadeExpression(new PropertySet(
      new VariableGet(variable), new Name('foo'), new IntLiteral(1)));
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
} => #0''', limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; } => #0''');

  cascade.addCascadeExpression(new PropertySet(
      new VariableGet(variable), new Name('bar'), new IntLiteral(2)));
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
  #0.bar = 2;
} => #0''', limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; #0.bar = 2; } => #0''');
}

void _testDeferredCheck() {
  Library library = new Library(dummyUri);
  LibraryDependency dependency =
      LibraryDependency.deferredImport(library, 'pre');
  VariableDeclaration check =
      new VariableDeclaration.forValue(new CheckLibraryIsLoaded(dependency));
  testExpression(new DeferredCheck(check, new IntLiteral(0)), '''
let final dynamic #0 = pre.checkLibraryIsLoaded() in 0''');
}

void _testFactoryConstructorInvocationJudgment() {
  Library library = new Library(dummyUri);
  Class cls = new Class(name: 'Class');
  library.addClass(cls);
  Procedure factoryConstructor = new Procedure(
      new Name(''), ProcedureKind.Factory, new FunctionNode(null));
  cls.addProcedure(factoryConstructor);

  testExpression(
      new FactoryConstructorInvocationJudgment(
          factoryConstructor, new ArgumentsImpl([])),
      '''
new Class()''',
      verbose: '''
new library test:dummy::Class()''');

  testExpression(
      new FactoryConstructorInvocationJudgment(
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Class<void>(0, bar: 1)''',
      verbose: '''
new library test:dummy::Class<void>(0, bar: 1)''');

  factoryConstructor.name = new Name('foo');
  testExpression(
      new FactoryConstructorInvocationJudgment(
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Class<void>.foo(0, bar: 1)''',
      verbose: '''
new library test:dummy::Class<void>.foo(0, bar: 1)''');
}

void _testFunctionDeclarationImpl() {
  testStatement(
      new FunctionDeclarationImpl(new VariableDeclarationImpl('foo', 0),
          new FunctionNode(new Block([]))),
      '''
dynamic foo() {}''');
}

void _testIfNullExpression() {
  testExpression(new IfNullExpression(new IntLiteral(0), new IntLiteral(1)), '''
0 ?? 1''');
}

void _testIntLiterals() {
  testExpression(new IntJudgment(0, null), '0');
  testExpression(new IntJudgment(0, 'foo'), 'foo');
  testExpression(new ShadowLargeIntLiteral('bar', TreeNode.noOffset), 'bar');
}

void _testExpressionInvocation() {
  testExpression(
      new ExpressionInvocation(new IntLiteral(0), new ArgumentsImpl([])), '''
0()''');
  testExpression(
      new ExpressionInvocation(
          new IntLiteral(0),
          new ArgumentsImpl([
            new IntLiteral(1)
          ], types: [
            const VoidType(),
            const DynamicType()
          ], named: [
            new NamedExpression('foo', new IntLiteral(2)),
            new NamedExpression('bar', new IntLiteral(3))
          ])),
      '''
0<void, dynamic>(1, foo: 2, bar: 3)''');
}

void _testNamedFunctionExpressionJudgment() {
  testExpression(
      new NamedFunctionExpressionJudgment(new VariableDeclarationImpl('foo', 0,
          initializer:
              new FunctionExpression(new FunctionNode(new Block([]))))),
      '''
let dynamic foo = dynamic () {} in foo''');
}

void _testNullAwareMethodInvocation() {
  VariableDeclaration variable =
      new VariableDeclaration.forValue(new IntLiteral(0));

  // The usual use of this node.
  testExpression(
      new NullAwareMethodInvocation(
          variable,
          new MethodInvocation(new VariableGet(variable), new Name('foo'),
              new ArgumentsImpl([]))),
      '''
0?.foo()''');

  // An unusual use of this node.
  testExpression(
      new NullAwareMethodInvocation(variable,
          new PropertyGet(new VariableGet(variable), new Name('foo'))),
      '''
let final dynamic #0 = 0 in null-aware #0.foo''');
}

void _testNullAwarePropertyGet() {
  VariableDeclaration variable =
      new VariableDeclaration.forValue(new IntLiteral(0));

  // The usual use of this node.
  testExpression(
      new NullAwarePropertyGet(variable,
          new PropertyGet(new VariableGet(variable), new Name('foo'))),
      '''
0?.foo''');

  // An unusual use of this node.
  testExpression(
      new NullAwarePropertyGet(
          variable,
          new MethodInvocation(new VariableGet(variable), new Name('foo'),
              new ArgumentsImpl([]))),
      '''
let final dynamic #0 = 0 in null-aware #0.foo()''');
}

void _testNullAwarePropertySet() {
  VariableDeclaration variable =
      new VariableDeclaration.forValue(new IntLiteral(0));

  testExpression(
      new NullAwarePropertySet(
          variable,
          new PropertySet(
              new VariableGet(variable), new Name('foo'), new IntLiteral(1))),
      '''
0?.foo = 1''');

  testExpression(
      new NullAwarePropertySet(
          variable,
          new MethodInvocation(new VariableGet(variable), new Name('foo'),
              new ArgumentsImpl([]))),
      '''
let final dynamic #0 = 0 in null-aware #0.foo()''');
}

void _testReturnStatementImpl() {
  testStatement(new ReturnStatementImpl(false), '''
return;''');
  testStatement(new ReturnStatementImpl(true), '''
=>;''');
  testStatement(new ReturnStatementImpl(false, new IntLiteral(0)), '''
return 0;''');
  testStatement(new ReturnStatementImpl(true, new IntLiteral(0)), '''
=> 0;''');
}

void _testVariableDeclarationImpl() {
  testStatement(new VariableDeclarationImpl('foo', 0), '''
dynamic foo;''');
  testStatement(
      new VariableDeclarationImpl('foo', 0, initializer: new IntLiteral(0)), '''
dynamic foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo', 0,
          type: const VoidType(),
          initializer: new IntLiteral(0),
          isFinal: true,
          isRequired: true),
      '''
required final void foo;''');
  testStatement(
      new VariableDeclarationImpl('foo', 0,
          type: const VoidType(), initializer: new IntLiteral(0), isLate: true),
      '''
late void foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo', 0,
          type: const VoidType(), initializer: new IntLiteral(0))
        ..lateGetter = new VariableDeclarationImpl('foo#getter', 0),
      '''
late void foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo', 0,
          type: const VoidType(), initializer: new IntLiteral(0))
        ..lateGetter = new VariableDeclarationImpl('foo#getter', 0)
        ..lateType = const DynamicType(),
      '''
late dynamic foo = 0;''');
}

void _testVariableGetImpl() {
  VariableDeclaration variable = new VariableDeclaration('foo');
  testExpression(
      new VariableGetImpl(variable, null, null, forNullGuardedAccess: false),
      '''
foo''');
  testExpression(
      new VariableGetImpl(variable, null, null, forNullGuardedAccess: true), '''
foo''');
  testExpression(
      new VariableGetImpl(variable, null, null, forNullGuardedAccess: false)
        ..promotedType = const VoidType(),
      '''
foo{void}''');
}

void _testLoadLibraryImpl() {
  Library library = new Library(dummyUri);
  LibraryDependency dependency =
      LibraryDependency.deferredImport(library, 'pre');
  testExpression(new LoadLibraryImpl(dependency, new ArgumentsImpl([])), '''
pre.loadLibrary()''');
  testExpression(
      new LoadLibraryImpl(dependency, new ArgumentsImpl([new IntLiteral(0)])),
      '''
pre.loadLibrary(0)''');
}

void _testLoadLibraryTearOff() {
  Library library = new Library(dummyUri);
  LibraryDependency dependency =
      LibraryDependency.deferredImport(library, 'pre');

  testExpression(new LoadLibraryTearOff(dependency, null), ''' 
pre.loadLibrary''');

  Procedure procedure = new Procedure(new Name('get#loadLibrary'),
      ProcedureKind.Getter, new FunctionNode(new Block([])));
  testExpression(new LoadLibraryTearOff(dependency, procedure), ''' 
pre.loadLibrary''');
}

void _testIfNullPropertySet() {
  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          forEffect: false),
      '0.foo ??= 1');

  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          forEffect: true),
      '0.foo ??= 1');
}

void _testIfNullSet() {
  VariableDeclaration variable = new VariableDeclaration('foo');
  testExpression(
      new IfNullSet(new VariableGet(variable),
          new VariableSet(variable, new IntLiteral(1)),
          forEffect: false),
      '''
foo ?? foo = 1''');

  testExpression(
      new IfNullSet(new VariableGet(variable),
          new VariableSet(variable, new IntLiteral(1)),
          forEffect: true),
      '''
foo ?? foo = 1''');
}

void _testCompoundExtensionSet() {}

void _testCompoundPropertySet() {
  testExpression(
      new CompoundPropertySet(
          new IntLiteral(0), new Name('foo'), new Name('+'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          binaryOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forEffect: false),
      '''
0.foo += 1''');
}

void _testPropertyPostIncDec() {}

void _testLocalPostIncDec() {}

void _testStaticPostIncDec() {}

void _testSuperPostIncDec() {}

void _testIndexGet() {}

void _testIndexSet() {}

void _testSuperIndexSet() {}

void _testExtensionIndexSet() {
  Library library = new Library(dummyUri);
  Extension extension = new Extension(
      name: 'Extension', typeParameters: [new TypeParameter('T')]);
  library.addExtension(extension);
  Procedure setter =
      new Procedure(new Name(''), ProcedureKind.Method, new FunctionNode(null));
  library.addProcedure(setter);

  testExpression(
      new ExtensionIndexSet(extension, null, new IntLiteral(0), setter,
          new IntLiteral(1), new IntLiteral(2)),
      '''
Extension(0)[1] = 2''');

  testExpression(
      new ExtensionIndexSet(extension, [const VoidType()], new IntLiteral(0),
          setter, new IntLiteral(1), new IntLiteral(2)),
      '''
Extension<void>(0)[1] = 2''');
}

void _testIfNullIndexSet() {}

void _testIfNullSuperIndexSet() {}

void _testIfNullExtensionIndexSet() {}

void _testCompoundIndexSet() {
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(2),
          forEffect: false, forPostIncDec: false),
      '''
0[1] += 2''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(1),
          forEffect: false, forPostIncDec: true),
      '''
0[1]++''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('-'),
          new IntLiteral(1),
          forEffect: false, forPostIncDec: true),
      '''
0[1]--''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('*'),
          new IntLiteral(1),
          forEffect: false, forPostIncDec: true),
      '''
0[1] *= 1''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(2),
          forEffect: false, forPostIncDec: true),
      '''
0[1] += 2''');
}

void _testNullAwareCompoundSet() {
  testExpression(
      new NullAwareCompoundSet(
          new IntLiteral(0), new Name('foo'), new Name('+'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          binaryOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forPostIncDec: false,
          forEffect: false),
      '''
0?.foo += 1''');
  testExpression(
      new NullAwareCompoundSet(
          new IntLiteral(0), new Name('foo'), new Name('+'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          binaryOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forPostIncDec: true,
          forEffect: false),
      '''
0?.foo++''');
}

void _testNullAwareIfNullSet() {
  testExpression(
      new NullAwareIfNullSet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          testOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forEffect: false),
      '''
0?.foo ??= 1''');
}

void _testCompoundSuperIndexSet() {}

void _testCompoundExtensionIndexSet() {}

void _testExtensionSet() {}

void _testNullAwareExtension() {}

void _testPropertySetImpl() {}

void _testExtensionTearOff() {}

void _testEqualsExpression() {
  testExpression(
      new EqualsExpression(new IntLiteral(0), new IntLiteral(1), isNot: false),
      '''
0 == 1''');
  testExpression(
      new EqualsExpression(new IntLiteral(0), new IntLiteral(1), isNot: true),
      '''
0 != 1''');
}

void _testBinaryExpression() {
  testExpression(
      new BinaryExpression(new IntLiteral(0), new Name('+'), new IntLiteral(1)),
      '''
0 + 1''');
  testExpression(
      new BinaryExpression(
          new BinaryExpression(
              new IntLiteral(0), new Name('-'), new IntLiteral(1)),
          new Name('+'),
          new BinaryExpression(
              new IntLiteral(2), new Name('-'), new IntLiteral(3))),
      '''
0 - 1 + 2 - 3''');
  testExpression(
      new BinaryExpression(
          new BinaryExpression(
              new IntLiteral(0), new Name('*'), new IntLiteral(1)),
          new Name('+'),
          new BinaryExpression(
              new IntLiteral(2), new Name('/'), new IntLiteral(3))),
      '''
0 * 1 + 2 / 3''');
  testExpression(
      new BinaryExpression(
          new BinaryExpression(
              new IntLiteral(0), new Name('+'), new IntLiteral(1)),
          new Name('*'),
          new BinaryExpression(
              new IntLiteral(2), new Name('-'), new IntLiteral(3))),
      '''
(0 + 1) * (2 - 3)''');
}

void _testUnaryExpression() {
  testExpression(new UnaryExpression(new Name('unary-'), new IntLiteral(0)), '''
-0''');
  testExpression(new UnaryExpression(new Name('~'), new IntLiteral(0)), '''
~0''');

  testExpression(
      new UnaryExpression(
          new Name('unary-'),
          new BinaryExpression(
              new IntLiteral(0), new Name('+'), new IntLiteral(1))),
      '''
-(0 + 1)''');
}

void _testParenthesizedExpression() {
  testExpression(new ParenthesizedExpression(new IntLiteral(0)), '''
(0)''');
}

void _testSpreadElement() {
  testExpression(new SpreadElement(new IntLiteral(0), false), '''
...0''');
  testExpression(new SpreadElement(new IntLiteral(0), true), '''
...?0''');
}

void _testIfElement() {
  testExpression(new IfElement(new IntLiteral(0), new IntLiteral(1), null), '''
if (0) 1''');
  testExpression(
      new IfElement(new IntLiteral(0), new IntLiteral(1), new IntLiteral(2)),
      '''
if (0) 1 else 2''');
}

void _testForElement() {}

void _testForInElement() {}

void _testSpreadMapEntry() {}

void _testIfMapEntry() {}

void _testForMapEntry() {}

void _testForInMapEntry() {}
