// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.impact_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:compiler/src/util/util.dart';
import 'package:expect/expect.dart';
import '../equivalence/check_helpers.dart';
import 'compiler_helper.dart';
import 'test_helpers.dart';

const Map<String, String> SOURCE = const <String, String>{
  // Pretend this is a dart2js_native test to allow use of 'native' keyword.
  'sdk/tests/compiler/dart2js_native/main.dart': r'''
import 'dart:_foreign_helper' as foreign show JS;
import 'dart:_foreign_helper' hide JS;
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_native_typed_data';
import 'dart:indexed_db';
import 'dart:html';
import 'dart:html_common';
import 'dart:math';
import 'dart:typed_data';
import 'dart:web_sql';
import 'helper.dart';
import 'jsinterop.dart';

main() {
  testEmpty();
  testNull();
  testTrue();
  testFalse();
  testInt();
  testDouble();
  testString();
  testStringInterpolation();
  testStringInterpolationConst();
  testStringJuxtaposition();
  testSymbol();
  testConstSymbol();
  testComplexConstSymbol();
  testIfNullConstSymbol();
  testTypeLiteral();
  testBoolFromEnvironment();
  testEmptyListLiteral();
  testEmptyListLiteralDynamic();
  testEmptyListLiteralTyped();
  testEmptyListLiteralConstant();
  testNonEmptyListLiteral();
  testEmptyMapLiteral();
  testEmptyMapLiteralDynamic();
  testEmptyMapLiteralTyped();
  testEmptyMapLiteralConstant();
  testNonEmptyMapLiteral();
  testNot();
  testUnaryMinus();
  testConditional();
  testPostInc(null);
  testPostDec(null);
  testPreInc(null);
  testPreDec(null);
  testIs();
  testIsGeneric();
  testIsGenericRaw();
  testIsGenericDynamic();
  testIsNot();
  testIsNotGeneric();
  testIsNotGenericRaw();
  testIsNotGenericDynamic();
  testIsTypedef();
  testIsTypedefGeneric();
  testIsTypedefGenericRaw();
  testIsTypedefGenericDynamic();
  testIsTypedefDeep();
  testAs();
  testAsGeneric();
  testAsGenericRaw();
  testAsGenericDynamic();
  testThrow();
  testIfNotNull(null);
  testIfNotNullSet(null);
  testIfNull(null);
  testSetIfNull(null);
  testSyncStar();
  testAsync();
  testAsyncStar();
  testLocalSyncStar();
  testLocalAsync();
  testLocalAsyncStar();
  testAnonymousSyncStar();
  testAnonymousAsync();
  testAnonymousAsyncStar();
  testIfThen();
  testIfThenElse();
  testForIn(null);
  testForInTyped(null);
  testAsyncForIn(null);
  testAsyncForInTyped(null);
  testTryCatch();
  testTryCatchOn();
  testTryCatchStackTrace();
  testTryFinally();
  testSwitchWithoutFallthrough(null);
  testSwitchWithFallthrough(null);
  testTopLevelInvoke();
  testTopLevelInvokeTyped();
  testTopLevelFunctionTyped();
  testTopLevelFunctionGet();
  testTopLevelGetterGet();
  testTopLevelGetterGetTyped();
  testTopLevelSetterSet();
  testTopLevelSetterSetTyped();
  testTopLevelField();
  testTopLevelFieldLazy();
  testTopLevelFieldConst();
  testTopLevelFieldFinal();
  testTopLevelFieldTyped();
  testTopLevelFieldGeneric1();
  testTopLevelFieldGeneric2();
  testTopLevelFieldGeneric3();
  testTopLevelFieldWrite();
  testStaticFunctionGet();
  testDynamicInvoke(null);
  testDynamicGet(null);
  testDynamicSet(null);
  testLocalWithoutInitializer();
  testLocalWithInitializer();
  testLocalWithInitializerTyped();
  testLocalFunction();
  testLocalFunctionTyped();
  testLocalFunctionInvoke();
  testLocalFunctionGet();
  testClosure();
  testClosureInvoke();
  testInvokeIndex(null);
  testInvokeIndexSet(null);
  testAssert();
  testAssertWithMessage();
  testConstructorInvoke();
  testConstructorInvokeGeneric();
  testConstructorInvokeGenericRaw();
  testConstructorInvokeGenericDynamic();
  testFactoryInvoke();
  testFactoryInvokeGeneric();
  testFactoryInvokeGenericRaw();
  testFactoryInvokeGenericDynamic();
  testRedirectingFactoryInvoke();
  testRedirectingFactoryInvokeGeneric();
  testRedirectingFactoryInvokeGenericRaw();
  testRedirectingFactoryInvokeGenericDynamic();
  testConstRedirectingFactoryInvoke();
  testConstRedirectingFactoryInvokeGeneric();
  testConstRedirectingFactoryInvokeGenericRaw();
  testConstRedirectingFactoryInvokeGenericDynamic();
  testImplicitConstructor();
  testFactoryConstructor();
  testDefaultValuesPositional();
  testDefaultValuesNamed();
  testFieldInitializer1();
  testFieldInitializer2();
  testFieldInitializer3();
  testInstanceFieldWithInitializer();
  testInstanceFieldTyped();
  testThisInitializer();
  testSuperInitializer();
  testGenericClass();
  testSuperCall();
  testSuperGet();
  testSuperFieldSet();
  testSuperSetterSet();
  testSuperClosurization();
  testForwardingConstructor();
  testForwardingConstructorTyped();
  testForwardingConstructorGeneric();
  testEnum();
  testStaticGenericMethod();
  testInstanceGenericMethod();
  testAbstractClassWithField();
  testDynamicPrivateMethodInvoke();
  testJSCall();
  testNativeMethod();
  testNativeMethodCreates();
  testNativeMethodReturns();
  testNativeField(null);
  testMixinInstantiation();
  testNamedMixinInstantiation();
  testGenericMixinInstantiation();
  testGenericNamedMixinInstantiation();
  testJsInteropMethod();
  testJsInteropClass();
}

testEmpty() {}
testNull() => null;
testTrue() => true;
testFalse() => false;
testInt() => 42;
testDouble() => 37.5;
testString() => 'foo';
testStringInterpolation() => '${0}';
testStringInterpolationConst() {
  const b = '${0}';
}
testStringJuxtaposition() => 'a' 'b';
testSymbol() => #main;
testConstSymbol() => const Symbol('main');

const complexSymbolField1 = "true".length == 4;
const complexSymbolField2 = "true" "false" "${4}${null}";
const complexSymbolField3 = const { 
  0.1: const bool.fromEnvironment('a', defaultValue: true),
  false: const int.fromEnvironment('b', defaultValue: 42),
  const <int>[]: const String.fromEnvironment('c'),
  testComplexConstSymbol: #testComplexConstSymbol,
  1 + 2: identical(0, -0), 
  true || false: false && true,
  override: const GenericClass<int, String>.generative(),
}; 
const complexSymbolField = 
    complexSymbolField1 ? complexSymbolField2 : complexSymbolField3;
testComplexConstSymbol() => const Symbol(complexSymbolField);

testIfNullConstSymbol() => const Symbol(null ?? 'foo');

testTypeLiteral() => Object;
testBoolFromEnvironment() => const bool.fromEnvironment('FOO');
testEmptyListLiteral() => [];
testEmptyListLiteralDynamic() => <dynamic>[];
testEmptyListLiteralTyped() => <String>[];
testEmptyListLiteralConstant() => const [];
testNonEmptyListLiteral() => [0];
testEmptyMapLiteral() => {};
testEmptyMapLiteralDynamic() => <dynamic, dynamic>{};
testEmptyMapLiteralTyped() => <String, int>{};
testEmptyMapLiteralConstant() => const {};
testNonEmptyMapLiteral() => {0: true};
testNot() => !false;
testUnaryMinus() => -1;
testConditional() => true ? 1 : '';
testPostInc(o) => o++;
testPostDec(o) => o--;
testPreInc(o) => ++o;
testPreDec(o) => --o;

testIs() => null is Class;
testIsGeneric() => null is GenericClass<int, String>;
testIsGenericRaw() => null is GenericClass;
testIsGenericDynamic() => null is GenericClass<dynamic, dynamic>;
testIsNot() => null is! Class;
testIsNotGeneric() => null is! GenericClass<int, String>;
testIsNotGenericRaw() => null is! GenericClass;
testIsNotGenericDynamic() => null is! GenericClass<dynamic, dynamic>;
testIsTypedef() => null is Typedef;
testIsTypedefGeneric() => null is GenericTypedef<int, String>;
testIsTypedefGenericRaw() => null is GenericTypedef;
testIsTypedefGenericDynamic() => null is GenericTypedef<dynamic, dynamic>;
testIsTypedefDeep() => null is List<GenericTypedef<int, GenericTypedef>>;
testAs() => null as Class;
testAsGeneric() => null as GenericClass<int, String>;
testAsGenericRaw() => null as GenericClass;
testAsGenericDynamic() => null as GenericClass<dynamic, dynamic>;
testThrow() => throw '';
testIfNotNull(o) => o?.foo;
testIfNotNullSet(o) => o?.foo = 42;
testIfNull(o) => o ?? 42;
testSetIfNull(o) => o ??= 42;

testSyncStar() sync* {}
testAsync() async {}
testAsyncStar() async* {}
testLocalSyncStar() {
  local() sync* {}
  return local;
}
testLocalAsync() {
  local() async {}
  return local;
}
testLocalAsyncStar() {
  local() async* {}
  return local;
}
testAnonymousSyncStar() {
  return () sync* {};
}
testAnonymousAsync() {
  return () async {};
}
testAnonymousAsyncStar() {
  return () async* {};
}

testIfThen() {
  if (false) return 42;
  return 1;
}
testIfThenElse() {
  if (true) {
    return 42;
  } else {
    return 1;
  }
}
testForIn(o) {
  for (var e in o) {}
}
testForInTyped(o) {
  for (int e in o) {}
}
testAsyncForIn(o) async {
  await for (var e in o) {}
}
testAsyncForInTyped(o) async {
  await for (int e in o) {}
}
testTryCatch() {
  try {} catch (e) {}
}
testTryCatchOn() {
  try {} on String catch (e) {}
}
testTryCatchStackTrace() {
  try {} catch (e, s) {}
}
testTryFinally() {
  try {} finally {}
}
testSwitchWithoutFallthrough(o) {
  switch (o) {
  case 0:
  case 1:
    o = 2;
    break;
  case 2:
    o = 3;
    return;
  case 3:
    throw '';
  case 4:
  default:
  }
}
testSwitchWithFallthrough(o) {
  switch (o) {
  case 0:
  case 1:
    o = 2;
  case 2:
    o = 3;
    return;
  case 3:
  default:
  }
}
topLevelFunction1(a) {}
topLevelFunction2(a, [b, c]) {}
topLevelFunction3(a, {b, c}) {}
testTopLevelInvoke() {
  topLevelFunction1(0);
  topLevelFunction2(1);
  topLevelFunction2(2, 3);
  topLevelFunction2(4, 5, 6);
  topLevelFunction3(7);
  topLevelFunction3(8, b: 9);
  topLevelFunction3(10, c: 11);
  topLevelFunction3(12, b: 13, c: 14);
  topLevelFunction3(15, c: 16, b: 17);
}
void topLevelFunction1Typed(int a) {}
int topLevelFunction2Typed(String a, [num b, double c]) => null;
double topLevelFunction3Typed(bool a, {List<int> b, Map<String, bool> c}) {
  return null;
}
testTopLevelInvokeTyped() {
  topLevelFunction1Typed(0);
  topLevelFunction2Typed('1');
  topLevelFunction2Typed('2', 3);
  topLevelFunction2Typed('3', 5, 6.0);
  topLevelFunction3Typed(true);
  topLevelFunction3Typed(false, b: []);
  topLevelFunction3Typed(null, c: {});
  topLevelFunction3Typed(true, b: [13], c: {'14': true});
  topLevelFunction3Typed(false, c: {'16': false}, b: [17]);
}

topLevelFunctionTyped1(void a(num b)) {}
topLevelFunctionTyped2(void a(num b, [String c])) {}
topLevelFunctionTyped3(void a(num b, {String c, int d})) {}
topLevelFunctionTyped4(void a(num b, {String d, int c})) {}
testTopLevelFunctionTyped() {
  topLevelFunctionTyped1(null);
  topLevelFunctionTyped2(null);
  topLevelFunctionTyped3(null);
  topLevelFunctionTyped4(null);
}
testTopLevelFunctionGet() => topLevelFunction1;
get topLevelGetter => 0;
testTopLevelGetterGet() => topLevelGetter;
int get topLevelGetterTyped => 0;
testTopLevelGetterGetTyped() => topLevelGetterTyped;
set topLevelSetter(_) {}
testTopLevelSetterSet() => topLevelSetter = 0;
void set topLevelSetterTyped(int value) {}
testTopLevelSetterSetTyped() => topLevelSetterTyped = 0;

var topLevelField;
testTopLevelField() => topLevelField;
var topLevelFieldLazy = topLevelFunction1(null);
testTopLevelFieldLazy() => topLevelFieldLazy;
const topLevelFieldConst = 0;
testTopLevelFieldConst() => topLevelFieldConst;
final topLevelFieldFinal = topLevelFunction1(null);
testTopLevelFieldFinal() => topLevelFieldFinal;
int topLevelFieldTyped;
testTopLevelFieldTyped() => topLevelFieldTyped;
GenericClass topLevelFieldGeneric1;
testTopLevelFieldGeneric1() => topLevelFieldGeneric1;
GenericClass<dynamic, dynamic> topLevelFieldGeneric2;
testTopLevelFieldGeneric2() => topLevelFieldGeneric2;
GenericClass<int, String> topLevelFieldGeneric3;
testTopLevelFieldGeneric3() => topLevelFieldGeneric3;
testTopLevelFieldWrite() => topLevelField = 3;
class StaticFunctionGetClass {
  static foo() {}
}
testStaticFunctionGet() => StaticFunctionGetClass.foo;

testDynamicInvoke(o) {
  o.f1(0);
  o.f2(1);
  o.f3(2, 3);
  o.f4(4, 5, 6);
  o.f5(7);
  o.f6(8, b: 9);
  o.f7(10, c: 11);
  o.f8(12, b: 13, c: 14);
  o.f9(15, c: 16, b: 17);
}
testDynamicGet(o) => o.foo;
testDynamicSet(o) => o.foo = 42;
testLocalWithoutInitializer() {
  var l;
}
testLocalWithInitializer() {
  var l = 42;
}
testLocalWithInitializerTyped() {
  int l = 42;
}
testLocalFunction() {
  localFunction() {}
}
testLocalFunctionTyped() {
  int localFunction(String a) => 42;
}
testLocalFunctionInvoke() {
  localFunction() {}
  localFunction();
}
testLocalFunctionGet() {
  localFunction() {}
  localFunction;
}
testClosure() {
  () {};
}
testClosureInvoke() {
  () {} ();
}
testInvokeIndex(o) => o[42];
testInvokeIndexSet(o) => o[42] = null;
testAssert() {
  assert(true);
}
testAssertWithMessage() {
  assert(true, 'ok');
}
testConstructorInvoke() {
  new Class.generative();
}
testConstructorInvokeGeneric() {
  new GenericClass<int, String>.generative();
}
testConstructorInvokeGenericRaw() {
  new GenericClass.generative();
}
testConstructorInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.generative();
}
testFactoryInvoke() {
  new Class.fact();
}
testFactoryInvokeGeneric() {
  new GenericClass<int, String>.fact();
}
testFactoryInvokeGenericRaw() {
  new GenericClass.fact();
}
testFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.fact();
}
testRedirectingFactoryInvoke() {
  new Class.redirect();
}
testRedirectingFactoryInvokeGeneric() {
  new GenericClass<int, String>.redirect();
}
testRedirectingFactoryInvokeGenericRaw() {
  new GenericClass.redirect();
}
testRedirectingFactoryInvokeGenericDynamic() {
  new GenericClass<dynamic, dynamic>.redirect();
}
testConstRedirectingFactoryInvoke() {
  const Class.redirect();
}
testConstRedirectingFactoryInvokeGeneric() {
  const GenericClass<int, String>.redirect();
}
testConstRedirectingFactoryInvokeGenericRaw() {
  const GenericClass.redirect();
}
testConstRedirectingFactoryInvokeGenericDynamic() {
  const GenericClass<dynamic, dynamic>.redirect();
}
class ClassImplicitConstructor {}
testImplicitConstructor() => new ClassImplicitConstructor();
class ClassFactoryConstructor {
  factory ClassFactoryConstructor() => null;
}
testFactoryConstructor() => new ClassFactoryConstructor();
testDefaultValuesPositional([bool value = false]) {}
testDefaultValuesNamed({bool value: false}) {}

class ClassFieldInitializer1 {
  var field;
  ClassFieldInitializer1(this.field);
}
testFieldInitializer1() => new ClassFieldInitializer1(42);
class ClassFieldInitializer2 {
  var field;
  ClassFieldInitializer2(value) : field = value;
}
testFieldInitializer2() => new ClassFieldInitializer2(42);
class ClassFieldInitializer3 {
  var field;
  ClassFieldInitializer3.a()
     // TODO(johnniwinther): Remove this when kernel has a more consistent
     // handling of uninitialized fields.
     : field = null;
  ClassFieldInitializer3.b(value) : field = value;
}
testFieldInitializer3() {
  new ClassFieldInitializer3.a();
  new ClassFieldInitializer3.b(42);
}
class ClassInstanceFieldWithInitializer {
  var field = false;
}
testInstanceFieldWithInitializer() => new ClassInstanceFieldWithInitializer();
class ClassInstanceFieldTyped {
  int field;
}
testInstanceFieldTyped() => new ClassInstanceFieldTyped();
class ClassGeneric<T> {
  ClassGeneric(T arg);
}
class ClassThisInitializer {
  ClassThisInitializer() : this.internal();
  ClassThisInitializer.internal();
}
testThisInitializer() => new ClassThisInitializer();
class ClassSuperInitializer extends ClassThisInitializer {
  ClassSuperInitializer() : super.internal();
}
testSuperInitializer() => new ClassSuperInitializer();
testGenericClass() => new ClassGeneric<int>(0);
class Super1 {
  foo() {}
}
class Sub1 extends Super1 {
  Sub1() {
    super.foo();
  }
}
testSuperCall() => new Sub1();
class Super2 {
  var foo;
}
class Sub2 extends Super2 {
  Sub2() {
    super.foo;
  }
}
testSuperGet() => new Sub2();
class Super3 {
  var foo;
}
class Sub3 extends Super3 {
  Sub3() {
    super.foo = 42;
  }
}
testSuperFieldSet() => new Sub3();
class Super4 {
  set foo(_) {}
}
class Sub4 extends Super4 {
  Sub4() {
    super.foo = 42;
  }
}
testSuperSetterSet() => new Sub4();
class Super5 {
  foo() {}
}
class Sub5 extends Super5 {
  Sub5() {
    super.foo;
  }
}
testSuperClosurization() => new Sub5();

class EmptyMixin {}
class ForwardingConstructorSuperClass {
  ForwardingConstructorSuperClass(arg);
}
class ForwardingConstructorClass =
    ForwardingConstructorSuperClass with EmptyMixin;
testForwardingConstructor() => new ForwardingConstructorClass(null);

class ForwardingConstructorTypedSuperClass {
  ForwardingConstructorTypedSuperClass(int arg);
}
class ForwardingConstructorTypedClass =
    ForwardingConstructorTypedSuperClass with EmptyMixin;
testForwardingConstructorTyped() => new ForwardingConstructorTypedClass(null);

class ForwardingConstructorGenericSuperClass<T> {
  ForwardingConstructorGenericSuperClass(T arg);
}
class ForwardingConstructorGenericClass<S> =
    ForwardingConstructorGenericSuperClass<S> with EmptyMixin;
testForwardingConstructorGeneric() {
  new ForwardingConstructorGenericClass<int>(null);
}

enum Enum { A }
testEnum() => Enum.A;

List<T> staticGenericMethod<T>(T arg) => [arg];
testStaticGenericMethod() {
  staticGenericMethod<int>(0);
}

testInstanceGenericMethod() {
  new GenericClass<int, String>.generative().genericMethod<bool>(false);
}

abstract class AbstractClass {
  final _field;

  factory AbstractClass() => null;
}
testAbstractClassWithField() => new AbstractClass();

testDynamicPrivateMethodInvoke([o]) => o._privateMethod();
testJSCall() => foreign.JS('int|bool|NativeUint8List|Rectangle|IdbFactory|'
    'SqlDatabase|TypedData|ContextAttributes', '#', null);
@JSName('foo')
@SupportedBrowser(SupportedBrowser.CHROME)
testNativeMethod() native;
@Creates('int|Null|JSArray')
testNativeMethodCreates() native;
@Returns('String|Null|JSArray')
testNativeMethodReturns() native;

@Native("NativeClass")
class NativeClass {
  @annotation_Creates_SerializedScriptValue
  final Object field;

  factory NativeClass._() { throw new UnsupportedError("Not supported"); }
}
testNativeField(NativeClass c) => c.field;
testMixinInstantiation() => new Sub();
testNamedMixinInstantiation() => new NamedMixin();
testGenericMixinInstantiation() => new GenericSub<int, String>();
testGenericNamedMixinInstantiation() => new GenericNamedMixin<int, String>();
''',
  'sdk/tests/compiler/dart2js_native/jsinterop.dart': '''
@JS()
library jsinterop;

import 'package:js/js.dart';

@JS()
external int testJsInteropMethod();

@JS()
class JsInteropClass {
  external JsInteropClass();

  @JS()
  external double method();
}

testJsInteropClass() => new JsInteropClass().method();
''',
  'sdk/tests/compiler/dart2js_native/helper.dart': '''
import 'dart:_js_helper';
class Class {
  const Class.generative();
  factory Class.fact() => null;
  const factory Class.redirect() = Class.generative;
}
class GenericClass<X, Y> {
  const GenericClass.generative();
  factory GenericClass.fact() => null;
  const factory GenericClass.redirect() = GenericClass<X, Y>.generative;

  Map<X, T> genericMethod<T>(T arg) => { null: arg };
}
typedef Typedef();
typedef X GenericTypedef<X, Y>(Y y);

class Super {}
class Mixin1 {}
class Mixin2 {}
class Sub extends Super with Mixin1, Mixin2 {}
class NamedMixin = Super with Mixin1, Mixin2;

class GenericSuper<X1, Y1> {}
class GenericMixin1<X2, Y2> {}
class GenericMixin2<X3, Y3> {}
class GenericSub<X4, Y4> extends GenericSuper<X4, Y4>
    with GenericMixin1<X4, Y4>, GenericMixin2<X4, Y4> {}
class GenericNamedMixin<X5, Y5> = GenericSuper<X5, Y5>
    with GenericMixin1<X5, Y5>, GenericMixin2<X5, Y5>;
''',
};

main(List<String> args) {
  bool fullTest = args.contains('--full');
  asyncTest(() async {
    enableDebugMode();
    Uri entryPoint =
        Uri.parse('memory:sdk/tests/compiler/dart2js_native/main.dart');

    Pair<Compiler, Compiler> pair =
        await analyzeOnly(entryPoint, SOURCE, printSteps: true);
    Compiler compiler1 = pair.a;
    Compiler compiler2 = pair.b;
    ElementEnvironment elementEnvironment1 =
        compiler1.frontendStrategy.elementEnvironment;
    ElementEnvironment elementEnvironment2 =
        compiler2.frontendStrategy.elementEnvironment;
    KernelFrontEndStrategy kernelStrategy = compiler2.frontendStrategy;
    KernelToElementMapForImpactImpl elementMap = kernelStrategy.elementMap;
    KernelEquivalence equivalence = new KernelEquivalence(elementMap);

    ConstantExpression emptyString = new StringConstantExpression("");

    void checkMembers(MemberEntity member1, MemberEntity member2) {
      if (!fullTest && !compiler1.resolution.hasResolutionImpact(member1)) {
        print('Skipping member without impact: $member1');
        return;
      }
      compiler1.reporter.withCurrentElement(member1, () {
        ResolutionImpact astImpact =
            compiler1.resolution.getResolutionImpact(member1);
        ResolutionImpact laxAstImpact =
            laxImpact(compiler1, member1, astImpact);
        ResolutionImpact kernelImpact = elementMap.computeWorldImpact(member2);
        testResolutionImpactEquivalence(laxAstImpact, kernelImpact,
            strategy: new CheckStrategy(
                elementEquivalence: equivalence.entityEquivalence,
                typeEquivalence: equivalence.typeEquivalence),
            filterConstantLiterals: (Iterable<ConstantExpression> constants,
                {bool fromFirstImpact}) {
          if (!fromFirstImpact) {
            if (astImpact.features.contains(Feature.STRING_INTERPOLATION)) {
              if (laxAstImpact.constantLiterals.contains(emptyString)) {
                // The old frontend adds empty string around interpolations.
                constants = new Set<ConstantExpression>.from(constants)
                  ..add(emptyString);
              }
            }
            if (astImpact.features.contains(Feature.FALL_THROUGH_ERROR)) {
              // Remove the constant arguments passed to the
              // `new FallThroughError._create(<fileName>, <fileOffset>)` call
              // generated by fasta.
              Set<ConstantExpression> newConstants =
                  new Set<ConstantExpression>();
              bool fileNameRemoved = false;
              bool fileOffsetRemoved = false;
              for (ConstantExpression constant in constants) {
                if (constant.kind == ConstantExpressionKind.STRING) {
                  if (!fileNameRemoved &&
                      !laxAstImpact.constantLiterals.contains(constant)) {
                    fileNameRemoved = true;
                    continue;
                  }
                } else if (constant.kind == ConstantExpressionKind.INT) {
                  if (!fileOffsetRemoved &&
                      !laxAstImpact.constantLiterals.contains(constant)) {
                    fileOffsetRemoved = true;
                    continue;
                  }
                }
                newConstants.add(constant);
              }
              if (fileNameRemoved && fileOffsetRemoved) {
                constants = newConstants;
              }
            }
          }
          return constants;
        });
      });
    }

    void checkLibraries(LibraryEntity library1, LibraryEntity library2) {
      if (!fullTest && library1.canonicalUri.scheme == 'dart') {
        print('Skipping library: $library1');
        return;
      }
      elementEnvironment1.forEachClass(library1, (ClassEntity cls1) {
        ClassEntity cls2 = elementEnvironment2.lookupClass(library2, cls1.name);
        elementEnvironment1.forEachClassMember(cls1,
            (ClassEntity declarer, MemberEntity member1) {
          if (declarer != cls1) return;
          MemberEntity member2 = elementEnvironment2
              .lookupClassMember(cls2, member1.name, setter: member1.isSetter);
          Expect.isNotNull(
              member2, "Missing class member for '${member1.name}' in $cls2");
          checkMembers(member1, member2);
        });
        elementEnvironment1.forEachConstructor(cls1,
            (ConstructorEntity constructor1) {
          ConstructorEntity constructor2 =
              elementEnvironment2.lookupConstructor(cls2, constructor1.name);
          checkMembers(constructor1, constructor2);
        });
      });

      elementEnvironment1.forEachLibraryMember(library1,
          (MemberEntity member1) {
        MemberEntity member2 = elementEnvironment2.lookupLibraryMember(
            library2, member1.name,
            setter: member1.isSetter);
        checkMembers(member1, member2);
      });
    }

    checkLibraries(
        elementEnvironment1.mainLibrary, elementEnvironment2.mainLibrary);
    elementEnvironment1.libraries.forEach((LibraryEntity library1) {
      if (library1 == elementEnvironment1.mainLibrary) return;
      LibraryEntity library2 =
          elementEnvironment2.lookupLibrary(library1.canonicalUri);
      checkLibraries(library1, library2);
    });
  });
}

/// Lax the precision of [impact] to meet expectancy of the corresponding impact
/// generated from kernel.
ResolutionImpact laxImpact(
    Compiler compiler, MemberElement element, ResolutionImpact impact) {
  ResolutionWorldImpactBuilder builder =
      new ResolutionWorldImpactBuilder('Lax impact of ${element}');
  for (StaticUse staticUse in impact.staticUses) {
    switch (staticUse.kind) {
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        ConstructorElement constructor = staticUse.element;
        ConstructorElement effectiveTarget = constructor.effectiveTarget;
        ResolutionInterfaceType effectiveTargetType =
            constructor.computeEffectiveTargetType(staticUse.type);
        ConstructorElement effectiveTargetDeclaration =
            effectiveTarget.declaration;
        builder.registerStaticUse(
            staticUse.kind == StaticUseKind.CONST_CONSTRUCTOR_INVOKE
                ? new StaticUse.constConstructorInvoke(
                    effectiveTargetDeclaration, null, effectiveTargetType)
                : new StaticUse.typedConstructorInvoke(
                    effectiveTargetDeclaration, null, effectiveTargetType));
        break;
      default:
        builder.registerStaticUse(staticUse);
        break;
    }
  }
  impact.dynamicUses.forEach(builder.registerDynamicUse);
  for (TypeUse typeUse in impact.typeUses) {
    builder.registerTypeUse(
        new TypeUse.internal(unalias(typeUse.type), typeUse.kind));
  }
  impact.constantLiterals.forEach(builder.registerConstantLiteral);
  impact.constSymbolNames.forEach(builder.registerConstSymbolName);
  for (ListLiteralUse listLiteralUse in impact.listLiterals) {
    if (element.enclosingClass != null &&
        element.enclosingClass.isEnumClass &&
        element.name == 'values') {
      // The type argument is not added to the generated list constant.
      ResolutionInterfaceType enumType = element.enclosingClass.thisType;
      listLiteralUse = new ListLiteralUse(
          compiler.frontendStrategy.commonElements.listType(enumType),
          isConstant: listLiteralUse.isConstant,
          isEmpty: listLiteralUse.isEmpty);
      builder.registerTypeUse(new TypeUse.checkedModeCheck(enumType));
    }
    builder.registerListLiteral(listLiteralUse);
  }
  for (MapLiteralUse mapLiteralUse in impact.mapLiterals) {
    if (element.enclosingClass != null &&
        element.enclosingClass.isEnumClass &&
        element.name == 'toString') {
      // The type argument is not added to the generated map constant.
      ResolutionInterfaceType keyType =
          compiler.frontendStrategy.commonElements.intType;
      ResolutionInterfaceType valueType =
          compiler.frontendStrategy.commonElements.stringType;
      mapLiteralUse = new MapLiteralUse(
          compiler.frontendStrategy.commonElements.mapType(keyType, valueType),
          isConstant: mapLiteralUse.isConstant,
          isEmpty: mapLiteralUse.isEmpty);
      builder.registerTypeUse(new TypeUse.checkedModeCheck(keyType));
      builder.registerTypeUse(new TypeUse.checkedModeCheck(valueType));
    }
    builder.registerMapLiteral(mapLiteralUse);
  }

  for (Feature feature in impact.features) {
    switch (feature) {
      case Feature.FIELD_WITHOUT_INITIALIZER:
        builder.registerConstantLiteral(new NullConstantExpression());
        break;
      case Feature.STRING_INTERPOLATION:
      case Feature.STRING_JUXTAPOSITION:
        // These are both converted into a string concatenation in kernel so
        // we cannot tell the difference.
        builder.registerFeature(Feature.STRING_INTERPOLATION);
        builder.registerFeature(Feature.STRING_JUXTAPOSITION);
        break;
      case Feature.FALL_THROUGH_ERROR:
        LibraryElement library =
            compiler.libraryLoader.lookupLibrary(Uris.dart_core);
        ClassElement cls =
            library.implementation.localLookup('FallThroughError');
        ConstructorElement constructor =
            cls.lookupConstructor('_create').declaration;
        builder.registerStaticUse(new StaticUse.typedConstructorInvoke(
            constructor, CallStructure.NO_ARGS, cls.thisType));
        builder.registerFeature(Feature.THROW_EXPRESSION);
        break;
      default:
        builder.registerFeature(feature);
        break;
    }
  }
  impact.nativeData.forEach(builder.registerNativeData);
  return builder;
}
