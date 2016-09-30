// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.impact_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/ssa/kernel_impact.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/use.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';
import '../serialization/test_helper.dart';

const Map<String, String> SOURCE = const <String, String>{
  'main.dart': r'''
import 'helper.dart';

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
  testIs(null);
  testIsGeneric(null);
  testIsGenericRaw(null);
  testIsGenericDynamic(null);
  testIsNot(null);
  testIsNotGeneric(null);
  testIsNotGenericRaw(null);
  testIsNotGenericDynamic(null);
  testAs(null);
  testAsGeneric(null);
  testAsGenericRaw(null);
  testAsGenericDynamic(null);
  testThrow();
  testSyncStar();
  testAsync();
  testAsyncStar();
  testIfThen();
  testIfThenElse();
  testForIn(null);
  testForInTyped(null);
  testAsyncForIn(null);
  testAsyncForInTyped(null);
  testTopLevelInvoke();
  testTopLevelInvokeTyped();
  testTopLevelFunctionTyped();
  testTopLevelFunctionGet();
  testTopLevelField();
  testTopLevelFieldLazy();
  testTopLevelFieldConst();
  testTopLevelFieldFinal();
  testTopLevelFieldTyped();
  testTopLevelFieldGeneric1();
  testTopLevelFieldGeneric2();
  testTopLevelFieldGeneric3();
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

testIs(o) => o is Class;
testIsGeneric(o) => o is GenericClass<int, String>;
testIsGenericRaw(o) => o is GenericClass;
testIsGenericDynamic(o) => o is GenericClass<dynamic, dynamic>;
testIsNot(o) => o is! Class;
testIsNotGeneric(o) => o is! GenericClass<int, String>;
testIsNotGenericRaw(o) => o is! GenericClass;
testIsNotGenericDynamic(o) => o is! GenericClass<dynamic, dynamic>;
testAs(o) => o as Class;
testAsGeneric(o) => o as GenericClass<int, String>;
testAsGenericRaw(o) => o as GenericClass;
testAsGenericDynamic(o) => o as GenericClass<dynamic, dynamic>;
testThrow() => throw '';

testSyncStar() sync* {}
testAsync() async {}
testAsyncStar() async* {}
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
''',
  'helper.dart': '''
class Class {
  Class.generative();
  factory Class.fact() => null;
  factory Class.redirect() = Class.generative;
}
class GenericClass<X, Y> {
  GenericClass.generative();
  factory GenericClass.fact() => null;
  factory GenericClass.redirect() = GenericClass.generative;
}
''',
};

main(List<String> args) {
  asyncTest(() async {
    enableDebugMode();
    Uri entryPoint = Uri.parse('memory:main.dart');
    Compiler compiler = compilerFor(
        entryPoint: entryPoint,
        memorySourceFiles: SOURCE,
        options: [
          Flags.analyzeAll,
          Flags.useKernel,
          Flags.enableAssertMessage
        ]);
    compiler.resolution.retainCachesForTesting = true;
    await compiler.run(entryPoint);
    checkLibrary(compiler, compiler.mainApp);
  });
}

void checkLibrary(Compiler compiler, LibraryElement library) {
  library.forEachLocalMember((AstElement element) {
    if (element.isClass) {
      // TODO(johnniwinther): Handle class members.
    } else if (element.isTypedef) {
      // Skip typedefs.
    } else {
      checkElement(compiler, element);
    }
  });
}

void checkElement(Compiler compiler, AstElement element) {
  ResolutionImpact astImpact = compiler.resolution.getResolutionImpact(element);
  astImpact = laxImpact(element, astImpact);
  ResolutionImpact kernelImpact = build(compiler, element.resolvedAst);
  Expect.isNotNull(kernelImpact, 'No impact computed for $element');
  testResolutionImpactEquivalence(
      astImpact, kernelImpact, const CheckStrategy());
}

/// Lax the precision of [impact] to meet expectancy of the corresponding impact
/// generated from kernel.
ResolutionImpact laxImpact(AstElement element, ResolutionImpact impact) {
  ResolutionWorldImpactBuilder builder =
      new ResolutionWorldImpactBuilder('Lax impact of ${element}');
  impact.staticUses.forEach(builder.registerStaticUse);
  impact.dynamicUses.forEach(builder.registerDynamicUse);
  impact.typeUses.forEach(builder.registerTypeUse);
  impact.constantLiterals.forEach(builder.registerConstantLiteral);
  impact.constSymbolNames.forEach(builder.registerConstSymbolName);
  impact.listLiterals.forEach(builder.registerListLiteral);
  impact.mapLiterals.forEach(builder.registerMapLiteral);
  for (Feature feature in impact.features) {
    builder.registerFeature(feature);
    switch (feature) {
      case Feature.STRING_INTERPOLATION:
      case Feature.STRING_JUXTAPOSITION:
        // These are both converted into a string concatenation in kernel so
        // we cannot tell the diferrence.
        builder.registerFeature(Feature.STRING_INTERPOLATION);
        builder.registerFeature(Feature.STRING_JUXTAPOSITION);
        break;
      default:
    }
  }
  impact.nativeData.forEach(builder.registerNativeData);
  return builder;
}
