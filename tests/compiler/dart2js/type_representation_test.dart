// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/js/js.dart';
import 'package:compiler/src/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/src/js_backend/js_backend.dart'
       show JavaScriptBackend, TypeRepresentationGenerator;

void main() {
  testTypeRepresentations();
}

void testTypeRepresentations() {
  asyncTest(() => TypeEnvironment.create(r"""
      typedef void Typedef();
      typedef int Typedef2();
      typedef List<int> Typedef3();
      typedef Typedef4();
      typedef Typedef5(int a, String b);
      typedef Typedef6(int a, [String b]);
      typedef Typedef7(int a, String b, [List<int> c, d]);
      typedef Typedef8(int a, {String b});
      typedef Typedef9(int a, String b, {List<int> c, d});
      typedef Typedef10(void f(int a, [b]));

      void m1() {}
      int m2() => 0;
      List<int> m3() => null;
      m4() {}
      m5(int a, String b) {}
      m6(int a, [String b]) {}
      m7(int a, String b, [List<int> c, d]) {}
      m8(int a, {String b}) {}
      m9(int a, String b, {List<int> c, d}) {}
      m10(void f(int a, [b])) {}
      """).then((env) {
    TypeRepresentationGenerator typeRepresentation =
        new TypeRepresentationGenerator(env.compiler);

    Expression onVariable(TypeVariableType variable) {
      return new VariableUse(variable.name);
    }

    String stringify(Expression expression) {
      return prettyPrint(expression, env.compiler).buffer.toString();
    }

    void expect(DartType type,
                String expectedRepresentation,
                [String expectedTypedefRepresentation]) {
      bool encodeTypedefName = false;
      Expression expression =
            typeRepresentation.getTypeRepresentation(type, onVariable,
                                                    (x) => encodeTypedefName);
      Expect.stringEquals(expectedRepresentation, stringify(expression));

      encodeTypedefName = true;
      expression =
            typeRepresentation.getTypeRepresentation(type, onVariable,
                                                    (x) => encodeTypedefName);
      if (expectedTypedefRepresentation == null) {
        expectedTypedefRepresentation = expectedRepresentation;
      }
      Expect.stringEquals(expectedTypedefRepresentation, stringify(expression));
    }

    String getJsName(Element cls) {
      Expression name = typeRepresentation.getJavaScriptClassName(cls);
      return stringify(name);
    }

    JavaScriptBackend backend = env.compiler.backend;
    String func = backend.namer.functionTypeTag;
    String retvoid = backend.namer.functionTypeVoidReturnTag;
    String ret = backend.namer.functionTypeReturnTypeTag;
    String args = backend.namer.functionTypeRequiredParametersTag;
    String opt = backend.namer.functionTypeOptionalParametersTag;
    String named = backend.namer.functionTypeNamedParametersTag;
    String typedefTag = backend.namer.typedefTag;

    ClassElement List_ = env.getElement('List');
    TypeVariableType List_E = List_.typeVariables[0];
    ClassElement Map_ = env.getElement('Map');
    TypeVariableType Map_K = Map_.typeVariables[0];
    TypeVariableType Map_V = Map_.typeVariables[1];

    DartType Object_ = env['Object'];
    DartType int_ = env['int'];
    DartType String_ = env['String'];
    DartType dynamic_ = env['dynamic'];
    DartType Typedef_ = env['Typedef'];
    DartType Typedef2_ = env['Typedef2'];
    DartType Typedef3_ = env['Typedef3'];
    DartType Typedef4_ = env['Typedef4'];
    DartType Typedef5_ = env['Typedef5'];
    DartType Typedef6_ = env['Typedef6'];
    DartType Typedef7_ = env['Typedef7'];
    DartType Typedef8_ = env['Typedef8'];
    DartType Typedef9_ = env['Typedef9'];
    DartType Typedef10_ = env['Typedef10'];

    String List_rep = getJsName(List_);
    String List_E_rep = stringify(onVariable(List_E));
    String Map_rep = getJsName(Map_);
    String Map_K_rep = stringify(onVariable(Map_K));
    String Map_V_rep = stringify(onVariable(Map_V));

    String Object_rep = getJsName(Object_.element);
    String int_rep = getJsName(int_.element);
    String String_rep = getJsName(String_.element);

    String Typedef_rep = getJsName(Typedef_.element);
    String Typedef2_rep = getJsName(Typedef2_.element);
    String Typedef3_rep = getJsName(Typedef3_.element);
    String Typedef4_rep = getJsName(Typedef4_.element);
    String Typedef5_rep = getJsName(Typedef5_.element);
    String Typedef6_rep = getJsName(Typedef6_.element);
    String Typedef7_rep = getJsName(Typedef7_.element);
    String Typedef8_rep = getJsName(Typedef8_.element);
    String Typedef9_rep = getJsName(Typedef9_.element);
    String Typedef10_rep = getJsName(Typedef10_.element);

    expect(int_, '$int_rep');
    expect(String_, '$String_rep');
    expect(dynamic_, 'null');

    // List<E>
    expect(List_.computeType(env.compiler), '[$List_rep, $List_E_rep]');
    // List
    expect(List_.rawType, '$List_rep');
    // List<dynamic>
    expect(instantiate(List_, [dynamic_]), '$List_rep');
    // List<int>
    expect(instantiate(List_, [int_]), '[$List_rep, $int_rep]');
    // List<Typedef>
    expect(instantiate(List_, [Typedef_]),
        '[$List_rep, {$func: "void_", $retvoid: true}]',
        '[$List_rep, {$func: "void_", $retvoid: true,'
          ' $typedefTag: $Typedef_rep}]');
    expect(instantiate(List_, [Typedef2_]),
        '[$List_rep, {$func: "int_", $ret: $int_rep}]',
        '[$List_rep, {$func: "int_", $ret: $int_rep,'
          ' $typedefTag: $Typedef2_rep}]');
    expect(instantiate(List_, [Typedef3_]),
        '[$List_rep, {$func: "List_", $ret: [$List_rep, $int_rep]}]',
        '[$List_rep, {$func: "List_", $ret: [$List_rep, $int_rep],'
          ' $typedefTag: $Typedef3_rep}]');
    expect(instantiate(List_, [Typedef4_]),
        '[$List_rep, {$func: "args0"}]',
        '[$List_rep, {$func: "args0", $typedefTag: $Typedef4_rep}]');
    expect(instantiate(List_, [Typedef5_]),
        '[$List_rep, {$func: "dynamic__int_String",'
          ' $args: [$int_rep, $String_rep]}]',
        '[$List_rep, {$func: "dynamic__int_String",'
          ' $args: [$int_rep, $String_rep], $typedefTag: $Typedef5_rep}]');
    expect(instantiate(List_, [Typedef6_]),
        '[$List_rep, {$func: "dynamic__int__String",'
          ' $args: [$int_rep], $opt: [$String_rep]}]',
        '[$List_rep, {$func: "dynamic__int__String",'
          ' $args: [$int_rep], $opt: [$String_rep],'
          ' $typedefTag: $Typedef6_rep}]');
    expect(instantiate(List_, [Typedef7_]),
        '[$List_rep, {$func: "dynamic__int_String__List_dynamic", $args: '
          '[$int_rep, $String_rep], $opt: [[$List_rep, $int_rep], null]}]',
        '[$List_rep, {$func: "dynamic__int_String__List_dynamic", $args: '
          '[$int_rep, $String_rep], $opt: [[$List_rep, $int_rep], null], '
          '$typedefTag: $Typedef7_rep}]');
    expect(instantiate(List_, [Typedef8_]),
        '[$List_rep, {$func: "dynamic__int__String0", $args: [$int_rep],'
          ' $named: {b: $String_rep}}]',
        '[$List_rep, {$func: "dynamic__int__String0", $args: [$int_rep],'
          ' $named: {b: $String_rep}, $typedefTag: $Typedef8_rep}]');
    expect(instantiate(List_, [Typedef9_]),
        '[$List_rep, {$func: "dynamic__int_String__List_dynamic0", '
          '$args: [$int_rep, $String_rep], $named: '
          '{c: [$List_rep, $int_rep], d: null}}]',
        '[$List_rep, {$func: "dynamic__int_String__List_dynamic0", '
          '$args: [$int_rep, $String_rep], $named: {c: [$List_rep, $int_rep],'
          ' d: null}, $typedefTag: $Typedef9_rep}]');
    expect(instantiate(List_, [Typedef10_]),
        '[$List_rep, {$func: "dynamic__void__int__dynamic", '
          '$args: [{$func: "void__int__dynamic", $retvoid: true, '
          '$args: [$int_rep], $opt: [null]}]}]',
        '[$List_rep, {$func: "dynamic__void__int__dynamic", '
          '$args: [{$func: "void__int__dynamic", $retvoid: true, '
          '$args: [$int_rep], $opt: [null]}], $typedefTag: $Typedef10_rep}]');

    // Map<K,V>
    expect(Map_.computeType(env.compiler),
           '[$Map_rep, $Map_K_rep, $Map_V_rep]');
    // Map
    expect(Map_.rawType, '$Map_rep');
    // Map<dynamic,dynamic>
    expect(instantiate(Map_, [dynamic_, dynamic_]), '$Map_rep');
    // Map<int,String>
    expect(instantiate(Map_, [int_, String_]),
           '[$Map_rep, $int_rep, $String_rep]');


    // void m1() {}
    expect(env.getElement('m1').computeType(env.compiler),
           '{$func: "void_", $retvoid: true}');

    // int m2() => 0;
    expect(env.getElement('m2').computeType(env.compiler),
           '{$func: "int_", $ret: $int_rep}');

    // List<int> m3() => null;
    expect(env.getElement('m3').computeType(env.compiler),
           '{$func: "List_", $ret: [$List_rep, $int_rep]}');

    // m4() {}
    expect(env.getElement('m4').computeType(env.compiler),
           '{$func: "args0"}');

    // m5(int a, String b) {}
    expect(env.getElement('m5').computeType(env.compiler),
           '{$func: "dynamic__int_String", $args: [$int_rep, $String_rep]}');

    // m6(int a, [String b]) {}
    expect(env.getElement('m6').computeType(env.compiler),
           '{$func: "dynamic__int__String", $args: [$int_rep],'
           ' $opt: [$String_rep]}');

    // m7(int a, String b, [List<int> c, d]) {}
    expect(env.getElement('m7').computeType(env.compiler),
           '{$func: "dynamic__int_String__List_dynamic",'
           ' $args: [$int_rep, $String_rep],'
           ' $opt: [[$List_rep, $int_rep], null]}');

    // m8(int a, {String b}) {}
    expect(env.getElement('m8').computeType(env.compiler),
           '{$func: "dynamic__int__String0",'
           ' $args: [$int_rep], $named: {b: $String_rep}}');

    // m9(int a, String b, {List<int> c, d}) {}
    expect(env.getElement('m9').computeType(env.compiler),
           '{$func: "dynamic__int_String__List_dynamic0",'
           ' $args: [$int_rep, $String_rep],'
           ' $named: {c: [$List_rep, $int_rep], d: null}}');

    // m10(void f(int a, [b])) {}
    expect(env.getElement('m10').computeType(env.compiler),
           '{$func: "dynamic__void__int__dynamic", $args:'
           ' [{$func: "void__int__dynamic",'
           ' $retvoid: true, $args: [$int_rep], $opt: [null]}]}');
  }));
}
