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
  testIfThen();
  testIfThenElse();
  testTopLevelInvoke();
  testTopLevelInvokeTyped();
  testTopLevelField();
  testTopLevelFieldTyped();
  testDynamicInvoke(null);
  testDynamicGet(null);
  testDynamicSet(null);
  testLocalWithInitializer();
  testLocalFunction();
  testLocalFunctionInvoke();
  testLocalFunctionGet();
  testInvokeIndex(null);
  testInvokeIndexSet(null);
  testAssert();
  testAssertWithMessage();
  testFactoryInvoke();
  testFactoryInvokeGeneric();
  testFactoryInvokeGenericRaw();
  testFactoryInvokeGenericDynamic();
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
var topLevelField;
testTopLevelField() => topLevelField;
int topLevelFieldTyped;
testTopLevelFieldTyped() => topLevelFieldTyped;
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
testLocalWithInitializer() {
  var l = 42;
}
testLocalFunction() {
  localFunction() {}
}
testLocalFunctionInvoke() {
  localFunction() {}
  localFunction();
}
testLocalFunctionGet() {
  localFunction() {}
  localFunction;
}
testInvokeIndex(o) => o[42];
testInvokeIndexSet(o) => o[42] = null;
testAssert() {
  assert(true);
}
testAssertWithMessage() {
  assert(true, 'ok');
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
''',
  'helper.dart': '''
class Class {
  factory Class.fact() => null;
}
class GenericClass<X, Y> {
  factory GenericClass.fact() => null;
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
    } else {
      checkElement(compiler, element);
    }
  });
}

void checkElement(Compiler compiler, AstElement element) {
  ResolutionImpact astImpact = compiler.resolution.getResolutionImpact(element);
  astImpact = laxImpact(element, astImpact);
  ResolutionImpact kernelImpact = build(compiler, element.resolvedAst);
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