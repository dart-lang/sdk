// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subtype_test;

import 'package:expect/expect.dart';
import 'type_test_helper.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart_types.dart';
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart'
       show Element, ClassElement;
import '../../../sdk/lib/_internal/compiler/implementation/js_backend/js_backend.dart'
       show TypeRepresentationGenerator;

void main() {
  testTypeRepresentations();
}

void testTypeRepresentations() {
  var env = new TypeEnvironment(r"""
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
      """);

  TypeRepresentationGenerator typeRepresentation =
      new TypeRepresentationGenerator(env.compiler);
  String onVariable(TypeVariableType type) => type.name.slowToString();

  void expect(String expectedRepresentation, DartType type) {
    String foundRepresentation =
        typeRepresentation.getTypeRepresentation(type, onVariable);
    Expect.stringEquals(expectedRepresentation, foundRepresentation);
  }

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

  String List_rep = typeRepresentation.getJsName(List_);
  String List_E_rep = onVariable(List_E);
  String Map_rep = typeRepresentation.getJsName(Map_);
  String Map_K_rep = onVariable(Map_K);
  String Map_V_rep = onVariable(Map_V);

  String Object_rep = typeRepresentation.getJsName(Object_.element);
  String int_rep = typeRepresentation.getJsName(int_.element);
  String String_rep = typeRepresentation.getJsName(String_.element);

  expect('$int_rep', int_);
  expect('$String_rep', String_);
  expect('null', dynamic_);

  // List<E>
  expect('[$List_rep, $List_E_rep]', List_.computeType(env.compiler));
  // List
  expect('$List_rep', List_.rawType);
  // List<dynamic>
  expect('[$List_rep, null]', instantiate(List_, [dynamic_]));
  // List<int>
  expect('[$List_rep, $int_rep]', instantiate(List_, [int_]));
  // List<Typedef>
  expect('[$List_rep, {func: true, retvoid: true}]',
      instantiate(List_, [Typedef_]));

  // Map<K,V>
  expect('[$Map_rep, $Map_K_rep, $Map_V_rep]', Map_.computeType(env.compiler));
  // Map
  expect('$Map_rep', Map_.rawType);
  // Map<dynamic,dynamic>
  expect('[$Map_rep, null, null]', instantiate(Map_, [dynamic_, dynamic_]));
  // Map<int,String>
  expect('[$Map_rep, $int_rep, $String_rep]',
      instantiate(Map_, [int_, String_]));

  // void m1() {}
  expect("{func: true, retvoid: true}",
      env.getElement('m1').computeType(env.compiler));

  // int m2() => 0;
  expect("{func: true, ret: $int_rep}",
      env.getElement('m2').computeType(env.compiler));

  // List<int> m3() => null;
  expect("{func: true, ret: [$List_rep, $int_rep]}",
      env.getElement('m3').computeType(env.compiler));

  // m4() {}
  expect("{func: true}",
      env.getElement('m4').computeType(env.compiler));

  // m5(int a, String b) {}
  expect("{func: true, args: [$int_rep, $String_rep]}",
      env.getElement('m5').computeType(env.compiler));

  // m6(int a, [String b]) {}
  expect("{func: true, args: [$int_rep], opt: [$String_rep]}",
      env.getElement('m6').computeType(env.compiler));

  // m7(int a, String b, [List<int> c, d]) {}
  expect("{func: true, args: [$int_rep, $String_rep],"
         " opt: [[$List_rep, $int_rep], null]}",
      env.getElement('m7').computeType(env.compiler));

  // m8(int a, {String b}) {}
  expect("{func: true, args: [$int_rep], named: {b: $String_rep}}",
      env.getElement('m8').computeType(env.compiler));

  // m9(int a, String b, {List<int> c, d}) {}
  expect("{func: true, args: [$int_rep, $String_rep],"
         " named: {c: [$List_rep, $int_rep], d: null}}",
      env.getElement('m9').computeType(env.compiler));

  // m10(void f(int a, [b])) {}
  expect("{func: true, args:"
         " [{func: true, retvoid: true, args: [$int_rep], opt: [null]}]}",
      env.getElement('m10').computeType(env.compiler));
}


