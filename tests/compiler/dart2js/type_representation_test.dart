// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/implementation/dart_types.dart';
import 'package:compiler/implementation/js/js.dart';
import 'package:compiler/implementation/elements/elements.dart'
       show Element, ClassElement;
import 'package:compiler/implementation/js_backend/js_backend.dart'
       show JavaScriptBackend, TypeRepresentationGenerator;

void main() {
  testTypeRepresentations();
}

void testTypeRepresentations() {
  asyncTest(() => TypeEnvironment.create(r"""
      typedef void Typedef();

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

    void expect(String expectedRepresentation, DartType type) {
      Expression expression =
          typeRepresentation.getTypeRepresentation(type, onVariable);
      Expect.stringEquals(expectedRepresentation, stringify(expression));
    }

    String getJsName(ClassElement cls) {
      Expression name = typeRepresentation.getJavaScriptClassName(cls);
      return stringify(name);
    }

    JavaScriptBackend backend = env.compiler.backend;
    String func = backend.namer.functionTypeTag();
    String retvoid = backend.namer.functionTypeVoidReturnTag();
    String ret = backend.namer.functionTypeReturnTypeTag();
    String args = backend.namer.functionTypeRequiredParametersTag();
    String opt = backend.namer.functionTypeOptionalParametersTag();
    String named = backend.namer.functionTypeNamedParametersTag();

    ClassElement List_ = env.getElement('List');
    TypeVariableType List_E = List_.typeVariables.head;
    ClassElement Map_ = env.getElement('Map');
    TypeVariableType Map_K = Map_.typeVariables.head;
    TypeVariableType Map_V = Map_.typeVariables.tail.head;

    DartType Object_ = env['Object'];
    DartType int_ = env['int'];
    DartType String_ = env['String'];
    DartType dynamic_ = env['dynamic'];
    DartType Typedef_ = env['Typedef'];

    String List_rep = getJsName(List_);
    String List_E_rep = stringify(onVariable(List_E));
    String Map_rep = getJsName(Map_);
    String Map_K_rep = stringify(onVariable(Map_K));
    String Map_V_rep = stringify(onVariable(Map_V));

    String Object_rep = getJsName(Object_.element);
    String int_rep = getJsName(int_.element);
    String String_rep = getJsName(String_.element);

    expect('$int_rep', int_);
    expect('$String_rep', String_);
    expect('null', dynamic_);

    // List<E>
    expect('[$List_rep, $List_E_rep]', List_.computeType(env.compiler));
    // List
    expect('$List_rep', List_.rawType);
    // List<dynamic>
    expect('$List_rep', instantiate(List_, [dynamic_]));
    // List<int>
    expect('[$List_rep, $int_rep]', instantiate(List_, [int_]));
    // List<Typedef>
    expect('[$List_rep, {$func: "void_", $retvoid: true}]',
        instantiate(List_, [Typedef_]));

    // Map<K,V>
    expect('[$Map_rep, $Map_K_rep, $Map_V_rep]',
           Map_.computeType(env.compiler));
    // Map
    expect('$Map_rep', Map_.rawType);
    // Map<dynamic,dynamic>
    expect('$Map_rep', instantiate(Map_, [dynamic_, dynamic_]));
    // Map<int,String>
    expect('[$Map_rep, $int_rep, $String_rep]',
        instantiate(Map_, [int_, String_]));

    // void m1() {}
    expect('{$func: "void_", $retvoid: true}',
        env.getElement('m1').computeType(env.compiler));

    // int m2() => 0;
    expect('{$func: "int_", $ret: $int_rep}',
        env.getElement('m2').computeType(env.compiler));

    // List<int> m3() => null;
    expect('{$func: "List_", $ret: [$List_rep, $int_rep]}',
        env.getElement('m3').computeType(env.compiler));

    // m4() {}
    expect('{$func: "args0"}',
        env.getElement('m4').computeType(env.compiler));

    // m5(int a, String b) {}
    expect('{$func: "dynamic__int_String", $args: [$int_rep, $String_rep]}',
        env.getElement('m5').computeType(env.compiler));

    // m6(int a, [String b]) {}
    expect('{$func: "dynamic__int__String", $args: [$int_rep],'
           ' $opt: [$String_rep]}',
        env.getElement('m6').computeType(env.compiler));

    // m7(int a, String b, [List<int> c, d]) {}
    expect('{$func: "dynamic__int_String__List_dynamic",'
           ' $args: [$int_rep, $String_rep],'
           ' $opt: [[$List_rep, $int_rep], null]}',
        env.getElement('m7').computeType(env.compiler));

    // m8(int a, {String b}) {}
    expect('{$func: "dynamic__int__String0",'
           ' $args: [$int_rep], $named: {b: $String_rep}}',
        env.getElement('m8').computeType(env.compiler));

    // m9(int a, String b, {List<int> c, d}) {}
    expect('{$func: "dynamic__int_String__List_dynamic0",'
           ' $args: [$int_rep, $String_rep],'
           ' $named: {c: [$List_rep, $int_rep], d: null}}',
        env.getElement('m9').computeType(env.compiler));

    // m10(void f(int a, [b])) {}
    expect('{$func: "dynamic__void__int__dynamic", $args:'
           ' [{$func: "void__int__dynamic",'
           ' $retvoid: true, $args: [$int_rep], $opt: [null]}]}',
        env.getElement('m10').computeType(env.compiler));
  }));
}


