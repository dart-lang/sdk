// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'package:front_end/src/fasta/kernel/type_labeler.dart';

import 'package:expect/expect.dart';

main() {
  void check(Map<Node, String> expectations, int bulletCount) {
    TypeLabeler labeler = new TypeLabeler(false);
    Map<Node, List<Object>> conversions = {};
    expectations.forEach((Node node, String expected) {
      if (node is DartType) {
        conversions[node] = labeler.labelType(node);
      } else if (node is Constant) {
        conversions[node] = labeler.labelConstant(node);
      } else {
        Expect.fail("Neither type nor constant");
      }
    });
    expectations.forEach((Node node, String expected) {
      Expect.stringEquals(expected, conversions[node].join());
    });
    int newlines = "\n".allMatches(labeler.originMessages).length;
    Expect.equals(bulletCount, newlines);
  }

  // Library mocks
  Library dartCoreLib = new Library(new Uri(scheme: 'dart', path: 'core'));
  Library myLib = new Library(Uri.parse("org-dartlang-testcase:///mylib.dart"));

  // Set up some classes
  Class objectClass = new Class(name: "Object")..parent = dartCoreLib;
  Supertype objectSuper = new Supertype(objectClass, []);
  Class boolClass = new Class(name: "bool", supertype: objectSuper)
    ..parent = dartCoreLib;
  Class numClass = new Class(name: "num", supertype: objectSuper)
    ..parent = dartCoreLib;
  Supertype numSuper = new Supertype(numClass, []);
  Class intClass = new Class(name: "int", supertype: numSuper)
    ..parent = dartCoreLib;
  Class fooClass = new Class(name: "Foo", supertype: objectSuper)
    ..parent = myLib;
  Class foo2Class = new Class(name: "Foo", supertype: objectSuper)
    ..parent = myLib;
  Class barClass = new Class(
      name: "Bar",
      supertype: objectSuper,
      typeParameters: [new TypeParameter("X")])
    ..parent = myLib;
  Class bazClass = new Class(
      name: "Baz",
      supertype: objectSuper,
      typeParameters: [new TypeParameter("X"), new TypeParameter("Y")])
    ..parent = myLib;

  // Test types
  DartType voidType = const VoidType();
  check({voidType: "void"}, 0);

  DartType dynamicType = const DynamicType();
  check({dynamicType: "dynamic"}, 0);

  DartType boolType = new InterfaceType(boolClass, Nullability.legacy);
  check({boolType: "bool"}, 0);

  DartType numType = new InterfaceType(numClass, Nullability.legacy);
  check({numType: "num"}, 0);

  DartType intType = new InterfaceType(intClass, Nullability.legacy);
  check({intType: "int"}, 0);

  DartType object = new InterfaceType(objectClass, Nullability.legacy);
  check({object: "Object"}, 1);

  DartType foo = new InterfaceType(fooClass, Nullability.legacy);
  check({foo: "Foo"}, 1);

  DartType foo2 = new InterfaceType(foo2Class, Nullability.legacy);
  check({foo2: "Foo"}, 1);
  check({foo: "Foo/*1*/", foo2: "Foo/*2*/"}, 2);

  DartType barVoid =
      new InterfaceType(barClass, Nullability.legacy, [voidType]);
  check({barVoid: "Bar<void>"}, 1);

  DartType barObject =
      new InterfaceType(barClass, Nullability.legacy, [object]);
  check({barObject: "Bar<Object>"}, 2);

  DartType barBarDynamic = new InterfaceType(barClass, Nullability.legacy, [
    new InterfaceType(barClass, Nullability.legacy, [dynamicType])
  ]);
  check({barBarDynamic: "Bar<Bar<dynamic>>"}, 1);

  DartType parameterY =
      new TypeParameterType(new TypeParameter("Y"), Nullability.legacy);
  DartType barY = new InterfaceType(barClass, Nullability.legacy, [parameterY]);
  check({parameterY: "Y", barY: "Bar<Y>"}, 1);

  DartType bazFooBarBazDynamicVoid =
      new InterfaceType(bazClass, Nullability.legacy, [
    foo,
    new InterfaceType(barClass, Nullability.legacy, [
      new InterfaceType(bazClass, Nullability.legacy, [dynamicType, voidType])
    ])
  ]);
  check({bazFooBarBazDynamicVoid: "Baz<Foo, Bar<Baz<dynamic, void>>>"}, 3);

  DartType bazFooFoo2 =
      new InterfaceType(bazClass, Nullability.legacy, [foo, foo2]);
  check({bazFooFoo2: "Baz<Foo/*1*/, Foo/*2*/>"}, 3);

  DartType funVoid = new FunctionType([], voidType, Nullability.legacy);
  check({funVoid: "void Function()"}, 0);

  DartType funFooBarVoid = new FunctionType([foo], barVoid, Nullability.legacy);
  check({funFooBarVoid: "Bar<void> Function(Foo)"}, 2);

  DartType funFooFoo2 = new FunctionType([foo], foo2, Nullability.legacy);
  check({funFooFoo2: "Foo/*1*/ Function(Foo/*2*/)"}, 2);

  DartType funOptFooVoid = new FunctionType([foo], voidType, Nullability.legacy,
      requiredParameterCount: 0);
  check({funOptFooVoid: "void Function([Foo])"}, 1);

  DartType funFooOptIntVoid = new FunctionType(
      [foo, intType], voidType, Nullability.legacy,
      requiredParameterCount: 1);
  check({funFooOptIntVoid: "void Function(Foo, [int])"}, 1);

  DartType funOptFooOptIntVoid = new FunctionType(
      [foo, intType], voidType, Nullability.legacy,
      requiredParameterCount: 0);
  check({funOptFooOptIntVoid: "void Function([Foo, int])"}, 1);

  DartType funNamedObjectVoid = new FunctionType(
      [], voidType, Nullability.legacy,
      namedParameters: [new NamedType("obj", object)]);
  check({funNamedObjectVoid: "void Function({Object obj})"}, 1);

  DartType funFooNamedObjectVoid = new FunctionType(
      [foo], voidType, Nullability.legacy,
      namedParameters: [new NamedType("obj", object)]);
  check({funFooNamedObjectVoid: "void Function(Foo, {Object obj})"}, 2);

  TypeParameter t = new TypeParameter("T", object, dynamicType);
  DartType funGeneric = new FunctionType(
      [new TypeParameterType(t, Nullability.legacy)],
      new TypeParameterType(t, Nullability.legacy),
      Nullability.legacy,
      typeParameters: [t]);
  check({funGeneric: "T Function<T>(T)"}, 0);

  TypeParameter tObject = new TypeParameter("T", object, object);
  DartType funGenericObject = new FunctionType(
      [new TypeParameterType(tObject, Nullability.legacy)],
      new TypeParameterType(tObject, Nullability.legacy),
      Nullability.legacy,
      typeParameters: [tObject]);
  check({funGenericObject: "T Function<T extends Object>(T)"}, 1);

  TypeParameter tFoo = new TypeParameter("T", foo, dynamicType);
  DartType funGenericFoo = new FunctionType(
      [new TypeParameterType(tFoo, Nullability.legacy)],
      new TypeParameterType(tFoo, Nullability.legacy),
      Nullability.legacy,
      typeParameters: [tFoo]);
  check({funGenericFoo: "T Function<T extends Foo>(T)"}, 1);

  TypeParameter tBar = new TypeParameter("T", dynamicType, dynamicType);
  tBar.bound = new InterfaceType(barClass, Nullability.legacy,
      [new TypeParameterType(tBar, Nullability.legacy)]);
  DartType funGenericBar = new FunctionType(
      [new TypeParameterType(tBar, Nullability.legacy)],
      new TypeParameterType(tBar, Nullability.legacy),
      Nullability.legacy,
      typeParameters: [tBar]);
  check({funGenericBar: "T Function<T extends Bar<T>>(T)"}, 1);

  // Add some members for testing instance constants
  Field booField = new Field(new Name("boo"), type: boolType);
  fooClass.fields.add(booField);
  Field valueField = new Field(new Name("value"), type: intType);
  foo2Class.fields.add(valueField);
  Field nextField = new Field(new Name("next"), type: foo2);
  foo2Class.fields.add(nextField);
  Field xField = new Field(new Name("x"),
      type: new TypeParameterType(
          bazClass.typeParameters[0], Nullability.legacy));
  bazClass.fields.add(xField);
  Field yField = new Field(new Name("y"),
      type: new TypeParameterType(
          bazClass.typeParameters[1], Nullability.legacy));
  bazClass.fields.add(yField);
  FunctionNode gooFunction = new FunctionNode(new EmptyStatement(),
      typeParameters: [new TypeParameter("V")]);
  Procedure gooMethod = new Procedure(
      new Name("goo"), ProcedureKind.Method, gooFunction,
      isStatic: true)
    ..parent = fooClass;

  // Test constants
  Constant nullConst = new NullConstant();
  check({nullConst: "null"}, 0);

  Constant trueConst = new BoolConstant(true);
  Constant falseConst = new BoolConstant(false);
  check({trueConst: "true", falseConst: "false"}, 0);

  Constant intConst = new IntConstant(2);
  Constant doubleConst = new DoubleConstant(2.5);
  check({intConst: "2", doubleConst: "2.5"}, 0);

  Constant stringConst = new StringConstant("Don't \"quote\" me on that!");
  check({stringConst: "\"Don't \\\"quote\\\" me on that!\""}, 0);

  Constant symConst = new SymbolConstant("foo", null);
  Constant symLibConst = new SymbolConstant("bar", dartCoreLib.reference);
  check({symConst: "#foo", symLibConst: "#dart:core::bar"}, 0);

  Constant fooConst = new InstanceConstant(
      fooClass.reference, [], {booField.getterReference: trueConst});
  check({fooConst: "Foo {boo: true}"}, 1);

  Constant foo2Const = new InstanceConstant(foo2Class.reference, [], {
    nextField.getterReference: nullConst,
    valueField.getterReference: intConst
  });
  check({foo2Const: "Foo {value: 2, next: null}"}, 1);

  Constant foo2nConst = new InstanceConstant(foo2Class.reference, [], {
    valueField.getterReference: intConst,
    nextField.getterReference: new InstanceConstant(foo2Class.reference, [], {
      valueField.getterReference: intConst,
      nextField.getterReference: nullConst
    }),
  });
  check({foo2nConst: "Foo {value: 2, next: Foo {value: 2, next: null}}"}, 1);

  Constant bazFooFoo2Const = new InstanceConstant(
      bazClass.reference,
      [foo, foo2],
      {xField.getterReference: fooConst, yField.getterReference: foo2Const});
  check({
    bazFooFoo2Const: "Baz<Foo/*1*/, Foo/*2*/> "
        "{x: Foo/*1*/ {boo: true}, y: Foo/*2*/ {value: 2, next: null}}"
  }, 3);

  Constant listConst = new ListConstant(dynamicType, [intConst, doubleConst]);
  check({listConst: "<dynamic>[2, 2.5]"}, 0);

  Constant listBoolConst = new ListConstant(boolType, [falseConst, trueConst]);
  check({listBoolConst: "<bool>[false, true]"}, 0);

  Constant setConst = new SetConstant(dynamicType, [intConst, doubleConst]);
  check({setConst: "<dynamic>{2, 2.5}"}, 0);

  Constant setBoolConst = new SetConstant(boolType, [falseConst, trueConst]);
  check({setBoolConst: "<bool>{false, true}"}, 0);

  Constant mapConst = new MapConstant(boolType, numType, [
    new ConstantMapEntry(trueConst, intConst),
    new ConstantMapEntry(falseConst, doubleConst)
  ]);
  check({mapConst: "<bool, num>{true: 2, false: 2.5}"}, 0);

  Constant tearOffConst = new TearOffConstant(gooMethod);
  check({tearOffConst: "Foo.goo"}, 1);

  Constant partialInstantiationConst =
      new PartialInstantiationConstant(tearOffConst, [intType]);
  check({partialInstantiationConst: "Foo.goo<int>"}, 1);

  Constant typeLiteralConst = new TypeLiteralConstant(foo);
  check({typeLiteralConst: "Foo"}, 1);
}
