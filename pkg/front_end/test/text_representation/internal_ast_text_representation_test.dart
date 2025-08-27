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
import 'package:front_end/src/kernel/collections.dart';
import 'package:front_end/src/kernel/forest.dart';
import 'package:front_end/src/kernel/internal_ast.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
import 'package:package_config/package_config.dart';

import 'text_representation_test.dart';

void testStatement(Statement node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

void testExpression(Expression node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

void testPattern(Pattern node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

void testInitializer(Initializer node, String normal,
    {String? verbose, String? limited}) {
  Expect.stringEquals(normal, node.toText(normalStrategy),
      "Unexpected normal strategy text for ${node.runtimeType}");
  Expect.stringEquals(verbose ?? normal, node.toText(verboseStrategy),
      "Unexpected verbose strategy text for ${node.runtimeType}");
  Expect.stringEquals(limited ?? normal, node.toText(limitedStrategy),
      "Unexpected limited strategy text for ${node.runtimeType}");
}

final Uri dummyUri = Uri.parse('test:dummy');

void main() {
  CompilerContext.runWithOptions(new ProcessedOptions(inputs: [dummyUri]),
      (CompilerContext c) async {
    _testVariableDeclarations();
    _testTryStatement();
    _testForInStatementWithSynthesizedVariable();
    _testSwitchCaseImpl();
    _testBreakStatementImpl();
    _testCascade();
    _testDeferredCheck();
    _testFactoryConstructorInvocationJudgment();
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
    _testLocalPostIncDec();
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
    _testIfNullExtensionIndexSet();
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
        new SwitchCaseImpl([0], [case0], [0], emptyBlock, hasLabel: false)
      ]),
      '''
switch (null) {
  case 0:
}''',
      limited: '''
switch (null) { case 0: }''');

  testStatement(
      new SwitchStatement(expression, [
        new SwitchCaseImpl([], [], [0], emptyBlock,
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
        new SwitchCaseImpl([0, 1], [case0, case1], [0, 1], returnBlock1,
            hasLabel: false),
        new SwitchCaseImpl([0], [case2], [0], returnBlock2,
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

void _testPatternSwitchStatement() {
  Expression expression = new NullLiteral();
  PatternGuard case0 = new PatternGuard(new ConstantPattern(new IntLiteral(0)));
  PatternGuard case1 = new PatternGuard(new ConstantPattern(new IntLiteral(1)));
  PatternGuard case2 = new PatternGuard(
      new ConstantPattern(new IntLiteral(2)), new IntLiteral(3));
  Block emptyBlock = new Block([]);
  Block returnBlock1 = new Block([new ReturnStatement()]);
  Block returnBlock2 = new Block([new ReturnStatement()]);

  testStatement(
      new PatternSwitchStatement(expression, [
        new PatternSwitchCase([0], [case0], emptyBlock,
            isDefault: false,
            hasLabel: false,
            jointVariables: [],
            jointVariableFirstUseOffsets: null)
      ]),
      '''
switch (null) {
  case 0:
}''',
      limited: '''
switch (null) { case 0: }''');

  testStatement(
      new PatternSwitchStatement(expression, [
        new PatternSwitchCase([], [], emptyBlock,
            hasLabel: false,
            isDefault: true,
            jointVariables: [],
            jointVariableFirstUseOffsets: null)
      ]),
      '''
switch (null) {
  default:
}''',
      limited: '''
switch (null) { default: }''');

  testStatement(
      new PatternSwitchStatement(expression, [
        new PatternSwitchCase([0, 1], [case0, case1], returnBlock1,
            hasLabel: false,
            isDefault: false,
            jointVariables: [],
            jointVariableFirstUseOffsets: null),
        new PatternSwitchCase([2], [case2], returnBlock2,
            hasLabel: true,
            isDefault: true,
            jointVariables: [],
            jointVariableFirstUseOffsets: null)
      ]),
      '''
switch (null) {
  case 0:
  case 1:
    return;
  case 2 when 3:
  default:
    return;
}''',
      limited: '''
switch (null) { case 0: case 1: return; case 2 when 3: default: return; }''');
}

void _testSwitchExpression() {
  Expression expression = new NullLiteral();
  PatternGuard case0 = new PatternGuard(new ConstantPattern(new IntLiteral(0)));
  PatternGuard case1 = new PatternGuard(new ConstantPattern(new IntLiteral(1)));
  PatternGuard case2 = new PatternGuard(
      new ConstantPattern(new IntLiteral(2)), new IntLiteral(3));
  Expression body0 = new IntLiteral(4);
  Expression body1 = new IntLiteral(5);
  Expression body2 = new IntLiteral(6);

  testExpression(
      new SwitchExpression(
          expression, [new SwitchExpressionCase(case0, body0)]),
      '''
switch (null) { case 0 => 4 }''',
      limited: '''
switch (null) { case 0 => 4 }''');

  testExpression(
      new SwitchExpression(expression, [
        new SwitchExpressionCase(case0, body0),
        new SwitchExpressionCase(case1, body1),
      ]),
      '''
switch (null) { case 0 => 4, case 1 => 5 }''',
      limited: '''
switch (null) { case 0 => 4, case 1 => 5 }''');

  testExpression(
      new SwitchExpression(expression, [
        new SwitchExpressionCase(case0, body0),
        new SwitchExpressionCase(case1, body1),
        new SwitchExpressionCase(case2, body2),
      ]),
      '''
switch (null) { case 0 => 4, case 1 => 5, case 2 when 3 => 6 }''',
      limited: '''
switch (null) { case 0 => 4, case 1 => 5, case 2 when 3 => 6 }''');
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

  cascade.addCascadeExpression(new DynamicSet(DynamicAccessKind.Dynamic,
      new VariableGet(variable), new Name('foo'), new IntLiteral(1)));
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
} => #0''', limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; } => #0''');

  cascade.addCascadeExpression(new DynamicSet(DynamicAccessKind.Dynamic,
      new VariableGet(variable), new Name('bar'), new IntLiteral(2)));
  testExpression(cascade, '''
let final dynamic #0 = 0 in cascade {
  #0.foo = 1;
  #0.bar = 2;
} => #0''', limited: '''
let final dynamic #0 = 0 in cascade { #0.foo = 1; #0.bar = 2; } => #0''');
}

void _testDeferredCheck() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  LibraryDependency dependency =
      LibraryDependency.deferredImport(library, 'pre');
  VariableDeclaration check =
      new VariableDeclaration.forValue(new CheckLibraryIsLoaded(dependency));
  testExpression(new DeferredCheck(check, new IntLiteral(0)), '''
let final dynamic #0 = pre.checkLibraryIsLoaded() in 0''');
}

void _testFactoryConstructorInvocationJudgment() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Procedure factoryConstructor = new Procedure(
      new Name(''), ProcedureKind.Factory, new FunctionNode(null),
      fileUri: dummyUri);
  cls.addProcedure(factoryConstructor);

  testExpression(
      new FactoryConstructorInvocation(
          factoryConstructor, new ArgumentsImpl([])),
      '''
new Class()''',
      verbose: '''
new library test:dummy::Class()''');

  testExpression(
      new FactoryConstructorInvocation(
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
      new FactoryConstructorInvocation(
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Class<void>.foo(0, bar: 1)''',
      verbose: '''
new library test:dummy::Class<void>.foo(0, bar: 1)''');
}

void _testTypeAliasedConstructorInvocation(CompilerContext c) {
  DillTarget dillTarget = new DillTarget(
      c,
      new Ticker(),
      new UriTranslator(c.options, new TargetLibrariesSpecification('dummy'),
          new PackageConfig([])),
      new NoneTarget(new TargetFlags()));
  DillLoader dillLoader = new DillLoader(dillTarget);
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Constructor constructor = new Constructor(new FunctionNode(null),
      name: new Name(''), fileUri: dummyUri);
  cls.addConstructor(constructor);
  DillLibraryBuilder libraryBuilder =
      new DillLibraryBuilder(library, dillLoader);
  Typedef typedef = new Typedef(
      'Typedef', new InterfaceType(cls, Nullability.nonNullable),
      fileUri: dummyUri);
  library.addTypedef(typedef);
  TypeAliasBuilder typeAliasBuilder =
      new DillTypeAliasBuilder(typedef, null, libraryBuilder);

  testExpression(
      new TypeAliasedConstructorInvocation(
          typeAliasBuilder, constructor, new ArgumentsImpl([])),
      '''
new Typedef()''',
      verbose: '''
new library test:dummy::Typedef()''');

  testExpression(
      new TypeAliasedConstructorInvocation(
          typeAliasBuilder,
          constructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Typedef<void>(0, bar: 1)''',
      verbose: '''
new library test:dummy::Typedef<void>(0, bar: 1)''');

  constructor.name = new Name('foo');
  testExpression(
      new TypeAliasedConstructorInvocation(
          typeAliasBuilder,
          constructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Typedef<void>.foo(0, bar: 1)''',
      verbose: '''
new library test:dummy::Typedef<void>.foo(0, bar: 1)''');

  constructor.name = new Name('foo');
  testExpression(
      new TypeAliasedConstructorInvocation(
          typeAliasBuilder,
          constructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))]),
          isConst: true),
      '''
const Typedef<void>.foo(0, bar: 1)''',
      verbose: '''
const library test:dummy::Typedef<void>.foo(0, bar: 1)''');
}

void _testTypeAliasedFactoryInvocation(CompilerContext c) {
  DillTarget dillTarget = new DillTarget(
      c,
      new Ticker(),
      new UriTranslator(c.options, new TargetLibrariesSpecification('dummy'),
          new PackageConfig([])),
      new NoneTarget(new TargetFlags()));
  DillLoader dillLoader = new DillLoader(dillTarget);
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Class cls = new Class(name: 'Class', fileUri: dummyUri);
  library.addClass(cls);
  Procedure factoryConstructor = new Procedure(
      new Name(''), ProcedureKind.Factory, new FunctionNode(null),
      fileUri: dummyUri);
  cls.addProcedure(factoryConstructor);
  DillLibraryBuilder libraryBuilder =
      new DillLibraryBuilder(library, dillLoader);
  Typedef typedef = new Typedef(
      'Typedef', new InterfaceType(cls, Nullability.nonNullable),
      fileUri: dummyUri);
  library.addTypedef(typedef);
  TypeAliasBuilder typeAliasBuilder =
      new DillTypeAliasBuilder(typedef, null, libraryBuilder);

  testExpression(
      new TypeAliasedFactoryInvocation(
          typeAliasBuilder, factoryConstructor, new ArgumentsImpl([])),
      '''
new Typedef()''',
      verbose: '''
new library test:dummy::Typedef()''');

  testExpression(
      new TypeAliasedFactoryInvocation(
          typeAliasBuilder,
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Typedef<void>(0, bar: 1)''',
      verbose: '''
new library test:dummy::Typedef<void>(0, bar: 1)''');

  factoryConstructor.name = new Name('foo');
  testExpression(
      new TypeAliasedFactoryInvocation(
          typeAliasBuilder,
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))])),
      '''
new Typedef<void>.foo(0, bar: 1)''',
      verbose: '''
new library test:dummy::Typedef<void>.foo(0, bar: 1)''');

  factoryConstructor.name = new Name('foo');
  testExpression(
      new TypeAliasedFactoryInvocation(
          typeAliasBuilder,
          factoryConstructor,
          new ArgumentsImpl([new IntLiteral(0)],
              types: [const VoidType()],
              named: [new NamedExpression('bar', new IntLiteral(1))]),
          isConst: true),
      '''
const Typedef<void>.foo(0, bar: 1)''',
      verbose: '''
const library test:dummy::Typedef<void>.foo(0, bar: 1)''');
}

void _testFunctionDeclarationImpl() {
  testStatement(
      new FunctionDeclarationImpl(
          new VariableDeclarationImpl('foo'), new FunctionNode(new Block([]))),
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
  testExpression(
      new ShadowLargeIntLiteral('bar', 'bar', TreeNode.noOffset), 'bar');
}

void _testInternalMethodInvocation() {
  testExpression(
      new MethodInvocation(
          new IntLiteral(0), new Name('boz'), new ArgumentsImpl([]),
          isNullAware: false),
      '''
0.boz()''');
  testExpression(
      new MethodInvocation(
          new IntLiteral(0),
          new Name('boz'),
          new ArgumentsImpl([
            new IntLiteral(1)
          ], types: [
            const VoidType(),
            const DynamicType()
          ], named: [
            new NamedExpression('foo', new IntLiteral(2)),
            new NamedExpression('bar', new IntLiteral(3))
          ]),
          isNullAware: false),
      '''
0.boz<void, dynamic>(1, foo: 2, bar: 3)''');
  testExpression(
      new MethodInvocation(
          new IntLiteral(0), new Name('boz'), new ArgumentsImpl([]),
          isNullAware: true),
      '''
0?.boz()''');
  testExpression(
      new MethodInvocation(
          new IntLiteral(0),
          new Name('boz'),
          new ArgumentsImpl([
            new IntLiteral(1)
          ], types: [
            const VoidType(),
            const DynamicType()
          ], named: [
            new NamedExpression('foo', new IntLiteral(2)),
            new NamedExpression('bar', new IntLiteral(3))
          ]),
          isNullAware: true),
      '''
0?.boz<void, dynamic>(1, foo: 2, bar: 3)''');
}

void _testPropertyGet() {
  testExpression(
      new PropertyGet(new IntLiteral(0), new Name('boz'), isNullAware: false),
      '''
0.boz''');

  testExpression(
      new PropertyGet(new IntLiteral(0), new Name('boz'), isNullAware: true),
      '''
0?.boz''');
}

void _testPropertySet() {
  testExpression(
      new PropertySet(new IntLiteral(0), new Name('boz'), new IntLiteral(1),
          forEffect: false, readOnlyReceiver: false, isNullAware: false),
      '''
0.boz = 1''');

  testExpression(
      new PropertySet(new IntLiteral(0), new Name('boz'), new IntLiteral(1),
          forEffect: false, readOnlyReceiver: false, isNullAware: true),
      '''
0?.boz = 1''');
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

void _testMethodInvocation() {
  testExpression(
      new MethodInvocation(
          new IntLiteral(0), new Name('foo'), new ArgumentsImpl([]),
          isNullAware: false),
      '''
0.foo()''');

  testExpression(
      new MethodInvocation(
          new IntLiteral(0), new Name('foo'), new ArgumentsImpl([]),
          isNullAware: true),
      '''
0?.foo()''');
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
  testStatement(new VariableDeclarationImpl('foo'), '''
dynamic foo;''');
  testStatement(
      new VariableDeclarationImpl('foo', initializer: new IntLiteral(0)), '''
dynamic foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo',
          type: const VoidType(),
          initializer: new IntLiteral(0),
          isFinal: true,
          isRequired: true),
      '''
required final void foo;''');
  testStatement(
      new VariableDeclarationImpl('foo',
          type: const VoidType(), initializer: new IntLiteral(0), isLate: true),
      '''
late void foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo',
          type: const VoidType(), initializer: new IntLiteral(0))
        ..lateGetter = new VariableDeclarationImpl('foo#getter'),
      '''
late void foo = 0;''');
  testStatement(
      new VariableDeclarationImpl('foo',
          type: const VoidType(), initializer: new IntLiteral(0))
        ..lateGetter = new VariableDeclarationImpl('foo#getter')
        ..lateType = const DynamicType(),
      '''
late dynamic foo = 0;''');
}

void _testLoadLibraryImpl() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
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
  Library library = new Library(dummyUri, fileUri: dummyUri);
  LibraryDependency dependency =
      LibraryDependency.deferredImport(library, 'pre');
  Procedure procedure = new Procedure(new Name('get#loadLibrary'),
      ProcedureKind.Getter, new FunctionNode(new Block([])),
      fileUri: dummyUri);
  testExpression(new LoadLibraryTearOff(dependency, procedure), '''
pre.loadLibrary''');
}

void _testIfNullPropertySet() {
  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          readOffset: -1,
          writeOffset: -1,
          forEffect: false,
          isNullAware: false),
      '0.foo ??= 1');

  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          readOffset: -1, writeOffset: -1, forEffect: true, isNullAware: false),
      '0.foo ??= 1');

  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          readOffset: -1, writeOffset: -1, forEffect: false, isNullAware: true),
      '0?.foo ??= 1');

  testExpression(
      new IfNullPropertySet(
          new IntLiteral(0), new Name('foo'), new IntLiteral(1),
          readOffset: -1, writeOffset: -1, forEffect: true, isNullAware: true),
      '0?.foo ??= 1');
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

void _testExtensionCompoundSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(
      new Name('E|get#foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  Procedure setter = new Procedure(
      new Name('E|set#foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(setter);

  testExpression(
      new ExtensionCompoundSet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          propertyName: name,
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          rhs: new IntLiteral(1),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1),
      '''
Extension(0).foo -= 1''');

  testExpression(
      new ExtensionCompoundSet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          propertyName: name,
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          rhs: new IntLiteral(1),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1),
      '''
Extension(0)?.foo += 1''');

  testExpression(
      new ExtensionCompoundSet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          propertyName: name,
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          rhs: new IntLiteral(1),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1),
      '''
Extension<void>(0).foo += 1''');

  testExpression(
      new ExtensionCompoundSet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          propertyName: name,
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          rhs: new IntLiteral(1),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1),
      '''
Extension<void>(0)?.foo -= 1''');

  testExpression(
      new ExtensionCompoundSet.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          propertyName: name,
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          rhs: new IntLiteral(1),
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1),
      '''
0.foo += 1''');
}

void _testCompoundPropertySet() {
  testExpression(
      new CompoundPropertySet(
          new IntLiteral(0), new Name('foo'), new Name('+'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          binaryOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forEffect: false,
          isNullAware: false),
      '''
0.foo += 1''');

  testExpression(
      new CompoundPropertySet(
          new IntLiteral(0), new Name('foo'), new Name('+'), new IntLiteral(1),
          readOffset: TreeNode.noOffset,
          binaryOffset: TreeNode.noOffset,
          writeOffset: TreeNode.noOffset,
          forEffect: false,
          isNullAware: true),
      '''
0?.foo += 1''');
}

void _testPropertyIncDec() {
  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: false,
          forEffect: false,
          isInc: true,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
0.foo++''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: false,
          forEffect: false,
          isInc: false,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
0.foo--''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: true,
          forEffect: false,
          isInc: true,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
0?.foo++''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: true,
          forEffect: false,
          isInc: false,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
0?.foo--''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: false,
          forEffect: false,
          isInc: true,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
++0.foo''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: false,
          forEffect: false,
          isInc: false,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
--0.foo''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: true,
          forEffect: false,
          isInc: true,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
++0?.foo''');

  testExpression(
      new PropertyIncDec(new IntLiteral(0), new Name('foo'),
          isNullAware: true,
          forEffect: false,
          isInc: false,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
--0?.foo''');
}

void _testLocalPostIncDec() {}

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
          operatorOffset: -1),
      '''
foo++''');

  testExpression(
      new StaticIncDec(
          getter: field,
          setter: field,
          name: name,
          forEffect: false,
          isInc: false,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
foo--''');

  testExpression(
      new StaticIncDec(
          getter: field,
          setter: field,
          name: name,
          forEffect: false,
          isInc: true,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
++foo''');

  testExpression(
      new StaticIncDec(
          getter: field,
          name: name,
          setter: field,
          forEffect: false,
          isInc: false,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
--foo''');
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
          getter: field,
          setter: field,
          name: name,
          forEffect: false,
          isInc: true,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
super.foo++''');

  testExpression(
      new SuperIncDec(
          getter: field,
          setter: field,
          name: name,
          forEffect: false,
          isInc: false,
          isPost: true,
          nameOffset: -1,
          operatorOffset: -1),
      '''
super.foo--''');

  testExpression(
      new SuperIncDec(
          getter: field,
          setter: field,
          name: name,
          forEffect: false,
          isInc: true,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
++super.foo''');

  testExpression(
      new SuperIncDec(
          getter: field,
          name: name,
          setter: field,
          forEffect: false,
          isInc: false,
          isPost: false,
          nameOffset: -1,
          operatorOffset: -1),
      '''
--super.foo''');
}

void _testIndexGet() {
  testExpression(
      new IndexGet(new IntLiteral(0), new IntLiteral(1), isNullAware: false),
      '''
0[1]''');

  testExpression(
      new IndexGet(new IntLiteral(0), new IntLiteral(1), isNullAware: true), '''
0?[1]''');
}

void _testIndexSet() {
  testExpression(
      new IndexSet(new IntLiteral(0), new IntLiteral(1), new IntLiteral(2),
          forEffect: false, isNullAware: false),
      '''
0[1] = 2''');

  testExpression(
      new IndexSet(new IntLiteral(0), new IntLiteral(1), new IntLiteral(2),
          forEffect: false, isNullAware: true),
      '''
0?[1] = 2''');
}

void _testSuperIndexSet() {}

void _testExtensionIndexGet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Procedure getter = new Procedure(
      new Name(''), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(getter);

  testExpression(
      new ExtensionIndexGet(
          extension, null, new IntLiteral(0), getter, new IntLiteral(1),
          isNullAware: false),
      '''
Extension(0)[1]''');

  testExpression(
      new ExtensionIndexGet(
          extension, null, new IntLiteral(0), getter, new IntLiteral(1),
          isNullAware: true),
      '''
Extension(0)?[1]''');

  testExpression(
      new ExtensionIndexGet(extension, [const VoidType()], new IntLiteral(0),
          getter, new IntLiteral(1),
          isNullAware: false),
      '''
Extension<void>(0)[1]''');

  testExpression(
      new ExtensionIndexGet(extension, [const VoidType()], new IntLiteral(0),
          getter, new IntLiteral(1),
          isNullAware: true),
      '''
Extension<void>(0)?[1]''');
}

void _testExtensionIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Procedure setter = new Procedure(
      new Name(''), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(setter);

  testExpression(
      new ExtensionIndexSet(extension, null, new IntLiteral(0), setter,
          new IntLiteral(1), new IntLiteral(2),
          isNullAware: false, forEffect: true),
      '''
Extension(0)[1] = 2''');

  testExpression(
      new ExtensionIndexSet(extension, null, new IntLiteral(0), setter,
          new IntLiteral(1), new IntLiteral(2),
          isNullAware: true, forEffect: false),
      '''
Extension(0)?[1] = 2''');

  testExpression(
      new ExtensionIndexSet(extension, [const VoidType()], new IntLiteral(0),
          setter, new IntLiteral(1), new IntLiteral(2),
          isNullAware: false, forEffect: false),
      '''
Extension<void>(0)[1] = 2''');

  testExpression(
      new ExtensionIndexSet(extension, [const VoidType()], new IntLiteral(0),
          setter, new IntLiteral(1), new IntLiteral(2),
          isNullAware: true, forEffect: true),
      '''
Extension<void>(0)?[1] = 2''');
}

void _testIfNullIndexSet() {}

void _testIfNullSuperIndexSet() {}

void _testIfNullExtensionIndexSet() {}

void _testCompoundIndexSet() {
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(2),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: false,
          isNullAware: false),
      '''
0[1] += 2''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(1),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: false),
      '''
0[1]++''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('-'),
          new IntLiteral(1),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: false),
      '''
0[1]--''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('*'),
          new IntLiteral(1),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: false),
      '''
0[1] *= 1''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(2),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: false),
      '''
0[1] += 2''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(2),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: false,
          isNullAware: true),
      '''
0?[1] += 2''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('+'),
          new IntLiteral(1),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: true),
      '''
0?[1]++''');
  testExpression(
      new CompoundIndexSet(new IntLiteral(0), new IntLiteral(1), new Name('-'),
          new IntLiteral(1),
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forEffect: false,
          forPostIncDec: true,
          isNullAware: true),
      '''
0?[1]--''');
}

void _testCompoundSuperIndexSet() {}

void _testExtensionCompoundIndexSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Procedure getter = new Procedure(
      new Name('[]'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  Procedure setter = new Procedure(
      new Name('[]='), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(setter);

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(2),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: false),
      '''
Extension(0)[1] -= 2''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(2),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: false),
      '''
Extension(0)?[1] += 2''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(1),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: true),
      '''
Extension(0)[1]--''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(1),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: true),
      '''
Extension(0)?[1]++''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(2),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: false),
      '''
Extension<void>(0)[1] += 2''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(2),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: false),
      '''
Extension<void>(0)?[1] -= 2''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('+'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(1),
          isNullAware: false,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: true),
      '''
Extension<void>(0)[1]++''');

  testExpression(
      new ExtensionCompoundIndexSet(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          getter: getter,
          setter: setter,
          binaryName: new Name('-'),
          index: new IntLiteral(1),
          rhs: new IntLiteral(1),
          isNullAware: true,
          forEffect: false,
          readOffset: -1,
          binaryOffset: -1,
          writeOffset: -1,
          forPostIncDec: true),
      '''
Extension<void>(0)?[1]--''');
}

void _testExtensionGet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(new Name('Extension|get#foo'),
      ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(getter);

  testExpression(
      new ExtensionGet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          isNullAware: false),
      '''
Extension(0).foo''');

  testExpression(
      new ExtensionGet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          isNullAware: true),
      '''
Extension(0)?.foo''');

  testExpression(
      new ExtensionGet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          isNullAware: false),
      '''
Extension<void>(0).foo''');

  testExpression(
      new ExtensionGet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          isNullAware: true),
      '''
Extension<void>(0)?.foo''');

  testExpression(
      new ExtensionGet.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          getter: getter),
      '''
0.foo''');
}

void _testExtensionGetterInvocation() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure method = new Procedure(
      new Name('Extension|foo'), ProcedureKind.Getter, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(method);

  testExpression(
      new ExtensionGetterInvocation.explicit(
          extension: extension,
          explicitTypeArguments: null,
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: false),
      '''
Extension(0).foo(1)''');

  testExpression(
      new ExtensionGetterInvocation.explicit(
          extension: extension,
          explicitTypeArguments: null,
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: true),
      '''
Extension(0)?.foo(1)''');

  testExpression(
      new ExtensionGetterInvocation.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: false),
      '''
Extension<void>(0).foo(1)''');

  testExpression(
      new ExtensionGetterInvocation.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: true),
      '''
Extension<void>(0)?.foo(1)''');

  testExpression(
      new ExtensionGetterInvocation.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)])),
      '''
0.foo(1)''');
}

void _testExtensionMethodInvocation() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure method = new Procedure(
      new Name('Extension|foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(method);

  testExpression(
      new ExtensionMethodInvocation.explicit(
          extension: extension,
          explicitTypeArguments: null,
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: false),
      '''
Extension(0).foo(1)''');

  testExpression(
      new ExtensionMethodInvocation.explicit(
          extension: extension,
          explicitTypeArguments: null,
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: true),
      '''
Extension(0)?.foo(1)''');

  testExpression(
      new ExtensionMethodInvocation.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: false),
      '''
Extension<void>(0).foo(1)''');

  testExpression(
      new ExtensionMethodInvocation.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          extensionTypeArgumentOffset: -1,
          receiver: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)]),
          isNullAware: true),
      '''
Extension<void>(0)?.foo(1)''');

  testExpression(
      new ExtensionMethodInvocation.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          target: method,
          arguments: new ArgumentsImpl([new IntLiteral(1)])),
      '''
0.foo(1)''');
}

void _testExtensionPostIncDec() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure getter = new Procedure(
      new Name('Extension|foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  Procedure setter = new Procedure(
      new Name('Extension|foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(getter);
  library.addProcedure(setter);

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: true,
          isInc: true,
          isNullAware: false),
      '''
Extension(0).foo++''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: true,
          isInc: false,
          isNullAware: true),
      '''
Extension(0)?.foo--''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: true,
          isInc: false,
          isNullAware: false),
      '''
Extension<void>(0).foo--''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: true,
          isInc: true,
          isNullAware: true),
      '''
Extension<void>(0)?.foo++''');

  testExpression(
      new ExtensionIncDec.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: true,
          isInc: true),
      '''
0.foo++''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: false,
          isInc: true,
          isNullAware: false),
      '''
++Extension(0).foo''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: false,
          isInc: false,
          isNullAware: true),
      '''
--Extension(0)?.foo''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: false,
          isInc: false,
          isNullAware: false),
      '''
--Extension<void>(0).foo''');

  testExpression(
      new ExtensionIncDec.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: false,
          isInc: true,
          isNullAware: true),
      '''
++Extension<void>(0)?.foo''');

  testExpression(
      new ExtensionIncDec.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          getter: getter,
          setter: setter,
          forEffect: false,
          isPost: false,
          isInc: true),
      '''
++0.foo''');
}

void _testExtensionSet() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure setter = new Procedure(new Name('Extension|set#foo'),
      ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(setter);

  testExpression(
      new ExtensionSet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          setter: setter,
          value: new IntLiteral(1),
          isNullAware: false,
          forEffect: true),
      '''
Extension(0).foo = 1''');

  testExpression(
      new ExtensionSet.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          setter: setter,
          value: new IntLiteral(1),
          isNullAware: true,
          forEffect: false),
      '''
Extension(0)?.foo = 1''');

  testExpression(
      new ExtensionSet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          setter: setter,
          value: new IntLiteral(1),
          isNullAware: false,
          forEffect: false),
      '''
Extension<void>(0).foo = 1''');

  testExpression(
      new ExtensionSet.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          setter: setter,
          value: new IntLiteral(1),
          isNullAware: true,
          forEffect: true),
      '''
Extension<void>(0)?.foo = 1''');

  testExpression(
      new ExtensionSet.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          setter: setter,
          value: new IntLiteral(1),
          forEffect: true),
      '''
0.foo = 1''');
}

void _testPropertySetImpl() {}

void _testExtensionTearOff() {
  Library library = new Library(dummyUri, fileUri: dummyUri);
  Extension extension = new Extension(
      name: 'Extension',
      typeParameters: [new TypeParameter('T')],
      fileUri: dummyUri);
  library.addExtension(extension);
  Name name = new Name('foo');
  Procedure tearOff = new Procedure(new Name('Extension|get#foo'),
      ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);
  library.addProcedure(tearOff);

  testExpression(
      new ExtensionTearOff.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          tearOff: tearOff,
          isNullAware: false),
      '''
Extension(0).foo''');

  testExpression(
      new ExtensionTearOff.explicit(
          extension: extension,
          explicitTypeArguments: null,
          receiver: new IntLiteral(0),
          name: name,
          tearOff: tearOff,
          isNullAware: true),
      '''
Extension(0)?.foo''');

  testExpression(
      new ExtensionTearOff.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          tearOff: tearOff,
          isNullAware: false),
      '''
Extension<void>(0).foo''');

  testExpression(
      new ExtensionTearOff.explicit(
          extension: extension,
          explicitTypeArguments: [const VoidType()],
          receiver: new IntLiteral(0),
          name: name,
          tearOff: tearOff,
          isNullAware: true),
      '''
Extension<void>(0)?.foo''');

  testExpression(
      new ExtensionTearOff.implicit(
          extension: extension,
          thisTypeArguments: [
            new TypeParameterType(
                extension.typeParameters.single, Nullability.undetermined)
          ],
          thisAccess: new IntLiteral(0),
          name: name,
          tearOff: tearOff),
      '''
0.foo''');
}

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
  testExpression(new SpreadElement(new IntLiteral(0), isNullAware: false), '''
...0''');
  testExpression(new SpreadElement(new IntLiteral(0), isNullAware: true), '''
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

void _testExpressionMatcher() {
  testPattern(new ConstantPattern(new IntLiteral(0)), '''
0''');

  testPattern(new ConstantPattern(new BoolLiteral(true)), '''
true''');
}

void _testBinaryMatcher() {
  testPattern(
      new AndPattern(new ConstantPattern(new IntLiteral(0)),
          new ConstantPattern(new IntLiteral(1))),
      '''
0 && 1''');

  testPattern(
      new OrPattern(new ConstantPattern(new IntLiteral(0)),
          new ConstantPattern(new IntLiteral(1)),
          orPatternJointVariables: []),
      '''
0 || 1''');
}

void _testCastMatcher() {
  testPattern(
      new CastPattern(
          new ConstantPattern(new IntLiteral(0)), const DynamicType()),
      '''
0 as dynamic''');
}

void _testNullAssertMatcher() {
  testPattern(new NullAssertPattern(new ConstantPattern(new IntLiteral(0))), '''
0!''');
}

void _testNullCheckMatcher() {
  testPattern(new NullCheckPattern(new ConstantPattern(new IntLiteral(0))), '''
0?''');
}

void _testListMatcher() {
  testPattern(
      new ListPattern(const DynamicType(), [
        new ConstantPattern(new IntLiteral(0)),
        new ConstantPattern(new IntLiteral(1)),
      ]),
      '''
<dynamic>[0, 1]''');
}

void _testRelationalMatcher() {
  testPattern(
      new RelationalPattern(RelationalPatternKind.equals, new IntLiteral(0)),
      '''
== 0''');
  testPattern(
      new RelationalPattern(RelationalPatternKind.notEquals, new IntLiteral(1)),
      '''
!= 1''');
  testPattern(
      new RelationalPattern(RelationalPatternKind.lessThan, new IntLiteral(2)),
      '''
< 2''');
}

void _testMapMatcher() {
  testPattern(new MapPattern(null, null, []), '''
{}''');
  testPattern(new MapPattern(const DynamicType(), const DynamicType(), []), '''
<dynamic, dynamic>{}''');
  testPattern(
      new MapPattern(null, null, [
        new MapPatternEntry(
            new IntLiteral(0), new ConstantPattern(new IntLiteral(1))),
      ]),
      '''
{0: 1}''');
  testPattern(
      new MapPattern(null, null, [
        new MapPatternEntry(
            new IntLiteral(0), new ConstantPattern(new IntLiteral(1))),
        new MapPatternEntry(
            new IntLiteral(2), new ConstantPattern(new IntLiteral(3))),
      ]),
      '''
{0: 1, 2: 3}''');
}

void _testIfCaseStatement() {
  testStatement(
      new IfCaseStatement(
          new IntLiteral(0),
          new PatternGuard(new ConstantPattern(new IntLiteral(1))),
          new ReturnStatement()),
      '''
if (0 case 1) return;''');

  testStatement(
      new IfCaseStatement(
          new IntLiteral(0),
          new PatternGuard(new ConstantPattern(new IntLiteral(1))),
          new ReturnStatement(new IntLiteral(2)),
          new ReturnStatement(new IntLiteral(3))),
      '''
if (0 case 1) return 2; else return 3;''');

  testStatement(
      new IfCaseStatement(
          new IntLiteral(0),
          new PatternGuard(
              new ConstantPattern(new IntLiteral(1)), new IntLiteral(2)),
          new ReturnStatement()),
      '''
if (0 case 1 when 2) return;''');

  testStatement(
      new IfCaseStatement(
          new IntLiteral(0),
          new PatternGuard(
              new ConstantPattern(new IntLiteral(1)), new IntLiteral(2)),
          new ReturnStatement(new IntLiteral(3)),
          new ReturnStatement(new IntLiteral(4))),
      '''
if (0 case 1 when 2) return 3; else return 4;''');
}

void _testPatternVariableDeclaration() {
  testStatement(
      new PatternVariableDeclaration(
          new ConstantPattern(new IntLiteral(0)), new IntLiteral(1),
          isFinal: false),
      '''
var 0 = 1;''');

  testStatement(
      new PatternVariableDeclaration(
          new ConstantPattern(new IntLiteral(0)), new IntLiteral(1),
          isFinal: true),
      '''
final 0 = 1;''');
}

void _testExtensionTypeRedirectingInitializer() {
  Procedure unnamedTarget = new Procedure(
      new Name(""), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);

  Procedure namedTarget = new Procedure(
      new Name("named"), ProcedureKind.Method, new FunctionNode(null),
      fileUri: dummyUri);

  testInitializer(
      new ExtensionTypeRedirectingInitializer(unnamedTarget, new Arguments([])),
      '''
this()''');

  testInitializer(
      new ExtensionTypeRedirectingInitializer(
          namedTarget, new Arguments([new IntLiteral(0)])),
      '''
this.named(0)''');
}
