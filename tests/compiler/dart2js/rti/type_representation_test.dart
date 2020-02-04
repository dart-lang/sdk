// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Port this test to be frontend agnostic.

library type_representation_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js/js.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/runtime_types.dart'
    show RuntimeTypeTags, TypeRepresentationGenerator;
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';
import '../helpers/type_test_helper.dart';

void main() {
  asyncTest(() async {
    await testAll();
  });
}

testAll() async {
  await testTypeRepresentations();
}

List<FunctionTypeData> signatures = const <FunctionTypeData>[
  const FunctionTypeData("void", "1", "()"),
  const FunctionTypeData("int", "2", "()"),
  const FunctionTypeData("List<int>", "3", "()"),
  const FunctionTypeData("dynamic", "4", "()"),
  const FunctionTypeData("dynamic", "5", "(int a, String b)"),
  const FunctionTypeData("dynamic", "6", "(int a, [String b])"),
  const FunctionTypeData(
      "dynamic", "7", "(int a, String b, [List<int> c, dynamic d])"),
  const FunctionTypeData("dynamic", "8", "(int a, {String b})"),
  const FunctionTypeData(
      "dynamic", "9", "(int a, String b, {List<int> c, dynamic d})"),
  const FunctionTypeData(
      "dynamic", "10", "(void Function(int a, [dynamic b]) f)"),
  const FunctionTypeData("FutureOr<int>", "11",
      "<T extends num, S>(FutureOr<T> a, S b, List<void> c)"),
];

testTypeRepresentations() async {
  String source = '''
import 'dart:async';

${createTypedefs(signatures, prefix: 'Typedef')}
${createMethods(signatures, prefix: 'm')}

main() {
  ${createUses(signatures, prefix: 'Typedef')}
  ${createUses(signatures, prefix: 'm')}
}
''';
  CompilationResult result =
      await runCompiler(memorySourceFiles: {'main.dart': source});
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  JsBackendStrategy backendStrategy = compiler.backendStrategy;

  RuntimeTypeTags rtiTags = const RuntimeTypeTags();
  TypeRepresentationGenerator typeRepresentation =
      new TypeRepresentationGenerator(
          compiler.frontendStrategy.commonElements.dartTypes,
          rtiTags,
          compiler.backendClosedWorldForTesting.nativeData);

  Expression onVariable(TypeVariableType _variable) {
    TypeVariableType variable = _variable;
    return new VariableUse(variable.element.name);
  }

  String stringify(Expression expression) {
    return prettyPrint(expression,
        enableMinification: compiler.options.enableMinification);
  }

  void expect(DartType type, String expectedRepresentation,
      [String expectedTypedefRepresentation]) {
    bool encodeTypedefName = false;
    Expression expression = typeRepresentation.getTypeRepresentation(
        backendStrategy.emitterTask.emitter,
        type,
        onVariable,
        (x) => encodeTypedefName);
    Expect.stringEquals(expectedRepresentation, stringify(expression));

    encodeTypedefName = true;
    expression = typeRepresentation.getTypeRepresentation(
        backendStrategy.emitterTask.emitter,
        type,
        onVariable,
        (x) => encodeTypedefName);
    if (expectedTypedefRepresentation == null) {
      expectedTypedefRepresentation = expectedRepresentation;
    }
    Expect.stringEquals(expectedTypedefRepresentation, stringify(expression));
  }

  String getJsName(Entity cls) {
    Expression name = typeRepresentation.getJavaScriptClassName(
        cls, backendStrategy.emitterTask.emitter);
    return stringify(name);
  }

  JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  String func = rtiTags.functionTypeTag;
  String ret = rtiTags.functionTypeReturnTypeTag;
  String retvoid = '$ret: -1';
  String args = rtiTags.functionTypeRequiredParametersTag;
  String opt = rtiTags.functionTypeOptionalParametersTag;
  String named = rtiTags.functionTypeNamedParametersTag;
  String bounds = rtiTags.functionTypeGenericBoundsTag;
  String futureOr = rtiTags.futureOrTag;
  String futureOrType = rtiTags.futureOrTypeTag;

  ClassEntity List_ = findClass(closedWorld, 'List');
  TypeVariableType List_E =
      elementEnvironment.getThisType(List_).typeArguments[0];
  ClassEntity Map_ = findClass(closedWorld, 'Map');
  TypeVariableType Map_K =
      elementEnvironment.getThisType(Map_).typeArguments[0];
  TypeVariableType Map_V =
      elementEnvironment.getThisType(Map_).typeArguments[1];

  InterfaceType Object_ = closedWorld.commonElements.objectType;
  InterfaceType num_ = closedWorld.commonElements.numType;
  InterfaceType int_ = closedWorld.commonElements.intType;
  InterfaceType String_ = closedWorld.commonElements.stringType;
  DartType dynamic_ = closedWorld.commonElements.dynamicType;
  DartType Typedef1_ = findFieldType(closedWorld, 'Typedef1');
  DartType Typedef2_ = findFieldType(closedWorld, 'Typedef2');
  DartType Typedef3_ = findFieldType(closedWorld, 'Typedef3');
  DartType Typedef4_ = findFieldType(closedWorld, 'Typedef4');
  DartType Typedef5_ = findFieldType(closedWorld, 'Typedef5');
  DartType Typedef6_ = findFieldType(closedWorld, 'Typedef6');
  DartType Typedef7_ = findFieldType(closedWorld, 'Typedef7');
  DartType Typedef8_ = findFieldType(closedWorld, 'Typedef8');
  DartType Typedef9_ = findFieldType(closedWorld, 'Typedef9');
  DartType Typedef10_ = findFieldType(closedWorld, 'Typedef10');
  DartType Typedef11_ = findFieldType(closedWorld, 'Typedef11');

  String List_rep = getJsName(List_);
  String List_E_rep = stringify(onVariable(List_E));
  String Map_rep = getJsName(Map_);
  String Map_K_rep = stringify(onVariable(Map_K));
  String Map_V_rep = stringify(onVariable(Map_V));

  String Object_rep = getJsName(Object_.element);
  String num_rep = getJsName(num_.element);
  String int_rep = getJsName(int_.element);
  String String_rep = getJsName(String_.element);

  String getTypedefTag(DartType type) {
    // TODO(johnniwinther): Should/can we preserve typedef names from kernel?
    //String typedefTag = backend.namer.typedefTag;
    //TypedefType typedef = type;
    //return ', $typedefTag: ${getJsName(typedef.element)}';
    return '';
  }

  String Typedef1_tag = getTypedefTag(Typedef1_);
  String Typedef2_tag = getTypedefTag(Typedef2_);
  String Typedef3_tag = getTypedefTag(Typedef3_);
  String Typedef4_tag = getTypedefTag(Typedef4_);
  String Typedef5_tag = getTypedefTag(Typedef5_);
  String Typedef6_tag = getTypedefTag(Typedef6_);
  String Typedef7_tag = getTypedefTag(Typedef7_);
  String Typedef8_tag = getTypedefTag(Typedef8_);
  String Typedef9_tag = getTypedefTag(Typedef9_);
  String Typedef10_tag = getTypedefTag(Typedef10_);

  expect(int_, '$int_rep');
  expect(String_, '$String_rep');
  expect(dynamic_, 'null');

  // List<E>
  expect(elementEnvironment.getThisType(List_), '[$List_rep, $List_E_rep]');
  // List
  expect(elementEnvironment.getRawType(List_), '[$List_rep,,]');
  // List<dynamic>
  expect(instantiate(List_, [dynamic_]), '[$List_rep,,]');
  // List<int>
  expect(instantiate(List_, [int_]), '[$List_rep, $int_rep]');
  // List<Typedef1>
  expect(instantiate(List_, [Typedef1_]), '[$List_rep, {$func: 1, $retvoid}]',
      '[$List_rep, {$func: 1, $retvoid$Typedef1_tag}]');
  expect(
      instantiate(List_, [Typedef2_]),
      '[$List_rep, {$func: 1, $ret: $int_rep}]',
      '[$List_rep, {$func: 1, $ret: $int_rep$Typedef2_tag}]');
  expect(
      instantiate(List_, [Typedef3_]),
      '[$List_rep, {$func: 1, $ret: [$List_rep, $int_rep]}]',
      '[$List_rep, {$func: 1, $ret: [$List_rep, $int_rep]$Typedef3_tag}]');
  expect(instantiate(List_, [Typedef4_]), '[$List_rep, {$func: 1}]',
      '[$List_rep, {$func: 1$Typedef4_tag}]');
  expect(
      instantiate(List_, [Typedef5_]),
      '[$List_rep, {$func: 1,'
          ' $args: [$int_rep, $String_rep]}]',
      '[$List_rep, {$func: 1,'
          ' $args: [$int_rep, $String_rep]$Typedef5_tag}]');
  expect(
      instantiate(List_, [Typedef6_]),
      '[$List_rep, {$func: 1,'
          ' $args: [$int_rep], $opt: [$String_rep]}]',
      '[$List_rep, {$func: 1,'
          ' $args: [$int_rep], $opt: [$String_rep]$Typedef6_tag}]');
  expect(
      instantiate(List_, [Typedef7_]),
      '[$List_rep, {$func: 1, $args: '
          '[$int_rep, $String_rep], $opt: [[$List_rep, $int_rep],,]}]',
      '[$List_rep, {$func: 1, $args: '
          '[$int_rep, $String_rep], $opt: [[$List_rep, $int_rep],,]'
          '$Typedef7_tag}]');
  expect(
      instantiate(List_, [Typedef8_]),
      '[$List_rep, {$func: 1, $args: [$int_rep],'
          ' $named: {b: $String_rep}}]',
      '[$List_rep, {$func: 1, $args: [$int_rep],'
          ' $named: {b: $String_rep}$Typedef8_tag}]');
  expect(
      instantiate(List_, [Typedef9_]),
      '[$List_rep, {$func: 1, '
          '$args: [$int_rep, $String_rep], $named: '
          '{c: [$List_rep, $int_rep], d: null}}]',
      '[$List_rep, {$func: 1, '
          '$args: [$int_rep, $String_rep], $named: {c: [$List_rep, $int_rep],'
          ' d: null}$Typedef9_tag}]');
  expect(
      instantiate(List_, [Typedef10_]),
      '[$List_rep, {$func: 1, '
          '$args: [{$func: 1, $retvoid, '
          '$args: [$int_rep], $opt: [,]}]}]',
      '[$List_rep, {$func: 1, '
          '$args: [{$func: 1, $retvoid, '
          '$args: [$int_rep], $opt: [,]}]$Typedef10_tag}]');

  expect(
      instantiate(List_, [Typedef11_]),
      '[$List_rep, {$func: 1, $bounds: [$num_rep, $Object_rep], '
      '$ret: {$futureOr: 1, $futureOrType: $int_rep}, '
      '$args: [{$futureOr: 1, $futureOrType: 0}, 1, [$List_rep, -1]]}]');

  // Map<K,V>
  expect(elementEnvironment.getThisType(Map_),
      '[$Map_rep, $Map_K_rep, $Map_V_rep]');
  // Map
  expect(elementEnvironment.getRawType(Map_), '[$Map_rep,,,]');
  // Map<dynamic,dynamic>
  expect(instantiate(Map_, [dynamic_, dynamic_]), '[$Map_rep,,,]');
  // Map<int,String>
  expect(
      instantiate(Map_, [int_, String_]), '[$Map_rep, $int_rep, $String_rep]');

  // void m1() {}
  expect(findFunctionType(closedWorld, 'm1'), '{$func: 1, $retvoid}');

  // int m2() => 0;
  expect(findFunctionType(closedWorld, 'm2'), '{$func: 1, $ret: $int_rep}');

  // List<int> m3() => null;
  expect(findFunctionType(closedWorld, 'm3'),
      '{$func: 1, $ret: [$List_rep, $int_rep]}');

  // m4() {}
  expect(findFunctionType(closedWorld, 'm4'), '{$func: 1}');

  // m5(int a, String b) {}
  expect(findFunctionType(closedWorld, 'm5'),
      '{$func: 1, $args: [$int_rep, $String_rep]}');

  // m6(int a, [String b]) {}
  expect(
      findFunctionType(closedWorld, 'm6'),
      '{$func: 1, $args: [$int_rep],'
      ' $opt: [$String_rep]}');

  // m7(int a, String b, [List<int> c, d]) {}
  expect(
      findFunctionType(closedWorld, 'm7'),
      '{$func: 1,'
      ' $args: [$int_rep, $String_rep],'
      ' $opt: [[$List_rep, $int_rep],,]}');

  // m8(int a, {String b}) {}
  expect(
      findFunctionType(closedWorld, 'm8'),
      '{$func: 1,'
      ' $args: [$int_rep], $named: {b: $String_rep}}');

  // m9(int a, String b, {List<int> c, d}) {}
  expect(
      findFunctionType(closedWorld, 'm9'),
      '{$func: 1,'
      ' $args: [$int_rep, $String_rep],'
      ' $named: {c: [$List_rep, $int_rep], d: null}}');

  // m10(void f(int a, [b])) {}
  expect(
      findFunctionType(closedWorld, 'm10'),
      '{$func: 1, $args:'
      ' [{$func: 1,'
      ' $retvoid, $args: [$int_rep], $opt: [,]}]}');

  // FutureOr<int> m11<T, S>(FutureOr<T> a, S b, List<void> c) {}
  expect(
      findFunctionType(closedWorld, 'm11'),
      '{$func: 1, $bounds: [$num_rep, $Object_rep], '
      '$ret: {$futureOr: 1, $futureOrType: $int_rep}, '
      '$args: [{$futureOr: 1, $futureOrType: 0}, 1, [$List_rep, -1]]}');
}
