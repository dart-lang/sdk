// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.element;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import '../index/store/typed_mocks.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  group('Element', () {
    runReflectiveTests(_ElementTest);
  });
  group('ElementKind', () {
    test('toString', test_ElementKind_toString);
    test('valueOf', test_ElementKind_valueOf);
    test('valueOfEngine', test_ElementKind_valueOfEngine);
  });
}


void test_ElementKind_toString() {
  expect(ElementKind.CLASS.toString(), 'CLASS');
  expect(ElementKind.COMPILATION_UNIT.toString(), 'COMPILATION_UNIT');
}


void test_ElementKind_valueOf() {
  expect(ElementKind.valueOf(ElementKind.CLASS.name), ElementKind.CLASS);
  expect(ElementKind.valueOf(ElementKind.CLASS_TYPE_ALIAS.name),
      ElementKind.CLASS_TYPE_ALIAS);
  expect(ElementKind.valueOf(ElementKind.COMPILATION_UNIT.name),
      ElementKind.COMPILATION_UNIT);
  expect(ElementKind.valueOf(ElementKind.CONSTRUCTOR.name),
      ElementKind.CONSTRUCTOR);
  expect(ElementKind.valueOf(ElementKind.FIELD.name), ElementKind.FIELD);
  expect(ElementKind.valueOf(ElementKind.FUNCTION.name), ElementKind.FUNCTION);
  expect(ElementKind.valueOf(ElementKind.FUNCTION_TYPE_ALIAS.name),
      ElementKind.FUNCTION_TYPE_ALIAS);
  expect(ElementKind.valueOf(ElementKind.GETTER.name), ElementKind.GETTER);
  expect(ElementKind.valueOf(ElementKind.LIBRARY.name), ElementKind.LIBRARY);
  expect(ElementKind.valueOf(ElementKind.METHOD.name), ElementKind.METHOD);
  expect(ElementKind.valueOf(ElementKind.SETTER.name), ElementKind.SETTER);
  expect(ElementKind.valueOf(ElementKind.TOP_LEVEL_VARIABLE.name),
      ElementKind.TOP_LEVEL_VARIABLE);
  expect(ElementKind.valueOf(ElementKind.UNIT_TEST_CASE.name),
      ElementKind.UNIT_TEST_CASE);
  expect(ElementKind.valueOf(ElementKind.UNIT_TEST_GROUP.name),
      ElementKind.UNIT_TEST_GROUP);
  expect(ElementKind.valueOf(ElementKind.UNKNOWN.name), ElementKind.UNKNOWN);
  expect(() {
    ElementKind.valueOf('no-such-kind');
  }, throws);
}


void test_ElementKind_valueOfEngine() {
  expect(ElementKind.valueOfEngine(engine.ElementKind.CLASS),
      ElementKind.CLASS);
  expect(ElementKind.valueOfEngine(engine.ElementKind.COMPILATION_UNIT),
      ElementKind.COMPILATION_UNIT);
  expect(ElementKind.valueOfEngine(engine.ElementKind.CONSTRUCTOR),
      ElementKind.CONSTRUCTOR);
  expect(ElementKind.valueOfEngine(engine.ElementKind.FIELD),
      ElementKind.FIELD);
  expect(ElementKind.valueOfEngine(engine.ElementKind.FUNCTION),
      ElementKind.FUNCTION);
  expect(ElementKind.valueOfEngine(engine.ElementKind.FUNCTION_TYPE_ALIAS),
      ElementKind.FUNCTION_TYPE_ALIAS);
  expect(ElementKind.valueOfEngine(engine.ElementKind.GETTER),
      ElementKind.GETTER);
  expect(ElementKind.valueOfEngine(engine.ElementKind.LIBRARY),
      ElementKind.LIBRARY);
  expect(ElementKind.valueOfEngine(engine.ElementKind.METHOD),
      ElementKind.METHOD);
  expect(ElementKind.valueOfEngine(engine.ElementKind.SETTER),
      ElementKind.SETTER);
  expect(ElementKind.valueOfEngine(engine.ElementKind.TOP_LEVEL_VARIABLE),
      ElementKind.TOP_LEVEL_VARIABLE);
  expect(ElementKind.valueOfEngine(engine.ElementKind.ANGULAR_COMPONENT),
      ElementKind.UNKNOWN);
}


@ReflectiveTestCase()
class _ElementTest {
  void test_fromElement_CLASS() {
    engine.ClassElement engineElement = new MockClassElement();
    when(engineElement.kind).thenReturn(engine.ElementKind.CLASS);
    when(engineElement.nameOffset).thenReturn(1);
    when(engineElement.displayName).thenReturn('MyClass');
    when(engineElement.isAbstract).thenReturn(true);
    when(engineElement.isDeprecated).thenReturn(true);
    when(engineElement.isPrivate).thenReturn(true);
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.CLASS);
    expect(element.name, 'MyClass');
    expect(element.offset, 1);
    expect(element.length, 'MyClass'.length);
    expect(element.flags, Element.FLAG_ABSTRACT | Element.FLAG_DEPRECATED |
        Element.FLAG_PRIVATE);
  }

  void test_fromElement_CONSTRUCTOR() {
    engine.ConstructorElement engineElement = new MockConstructorElement();
    when(engineElement.kind).thenReturn(engine.ElementKind.CONSTRUCTOR);
    when(engineElement.nameOffset).thenReturn(1);
    when(engineElement.displayName).thenReturn('myConstructor');
    when(engineElement.isConst).thenReturn(true);
    when(engineElement.isDeprecated).thenReturn(false);
    when(engineElement.isPrivate).thenReturn(false);
    when(engineElement.isStatic).thenReturn(false);
    when(engineElement.parameters).thenReturn([]);
    {
      engine.ParameterElement a = new MockParameterElement('int a');
      engine.ParameterElement b = new MockParameterElement('String b');
      when(b.kind).thenReturn(engine.ParameterKind.POSITIONAL);
      when(engineElement.parameters).thenReturn([a, b]);
    }
    {
      engine.DartType returnType = new MockDartType('Map<int, String>');
      when(engineElement.returnType).thenReturn(returnType);
    }
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.CONSTRUCTOR);
    expect(element.name, 'myConstructor');
    expect(element.offset, 1);
    expect(element.length, 'myConstructor'.length);
    expect(element.parameters, '(int a, [String b])');
    expect(element.returnType, 'Map<int, String>');
    expect(element.flags, Element.FLAG_CONST);
  }

  void test_fromElement_FIELD() {
    engine.FieldElement engineElement = new MockFieldElement();
    when(engineElement.kind).thenReturn(engine.ElementKind.FIELD);
    when(engineElement.nameOffset).thenReturn(1);
    when(engineElement.displayName).thenReturn('myField');
    when(engineElement.isConst).thenReturn(true);
    when(engineElement.isFinal).thenReturn(true);
    when(engineElement.isDeprecated).thenReturn(false);
    when(engineElement.isPrivate).thenReturn(false);
    when(engineElement.isStatic).thenReturn(true);
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.FIELD);
    expect(element.name, 'myField');
    expect(element.offset, 1);
    expect(element.length, 'myField'.length);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, Element.FLAG_CONST | Element.FLAG_FINAL |
        Element.FLAG_STATIC);
  }

  void test_fromElement_GETTER() {
    engine.PropertyAccessorElement engineElement =
        new MockPropertyAccessorElement();
    when(engineElement.kind).thenReturn(engine.ElementKind.GETTER);
    when(engineElement.nameOffset).thenReturn(1);
    when(engineElement.displayName).thenReturn('myGetter');
    when(engineElement.isAbstract).thenReturn(false);
    when(engineElement.isDeprecated).thenReturn(true);
    when(engineElement.isPrivate).thenReturn(false);
    when(engineElement.isStatic).thenReturn(false);
    when(engineElement.parameters).thenReturn([]);
    {
      engine.DartType returnType = new MockDartType('String');
      when(engineElement.returnType).thenReturn(returnType);
    }
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.GETTER);
    expect(element.name, 'myGetter');
    expect(element.offset, 1);
    expect(element.length, 'myGetter'.length);
    expect(element.parameters, '()');
    expect(element.returnType, 'String');
    expect(element.flags, Element.FLAG_DEPRECATED);
  }

  void test_fromElement_METHOD() {
    engine.MethodElement engineElement = new MockMethodElement();
    when(engineElement.kind).thenReturn(engine.ElementKind.METHOD);
    when(engineElement.nameOffset).thenReturn(1);
    when(engineElement.displayName).thenReturn('myMethod');
    when(engineElement.isAbstract).thenReturn(false);
    when(engineElement.isDeprecated).thenReturn(false);
    when(engineElement.isPrivate).thenReturn(false);
    when(engineElement.isStatic).thenReturn(true);
    {
      engine.ParameterElement a = new MockParameterElement('int a');
      engine.ParameterElement b = new MockParameterElement('String b');
      when(b.kind).thenReturn(engine.ParameterKind.NAMED);
      when(engineElement.parameters).thenReturn([a, b]);
    }
    {
      engine.DartType returnType = new MockDartType('List<String>');
      when(engineElement.returnType).thenReturn(returnType);
    }
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'myMethod');
    expect(element.offset, 1);
    expect(element.length, 'myMethod'.length);
    expect(element.parameters, '(int a, {String b})');
    expect(element.returnType, 'List<String>');
    expect(element.flags, Element.FLAG_STATIC);
  }

  void test_fromJson() {
    var flags = Element.FLAG_DEPRECATED | Element.FLAG_PRIVATE |
        Element.FLAG_STATIC;
    var json = {
      KIND: 'METHOD',
      NAME: 'my name',
      OFFSET: 1,
      LENGTH: 2,
      FLAGS: flags,
      PARAMETERS: '(int a, String b)',
      RETURN_TYPE: 'List<String>'
    };
    Element element = new Element.fromJson(json);
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'my name');
    expect(element.offset, 1);
    expect(element.length, 2);
    expect(element.flags, flags);
    expect(element.isAbstract, isFalse);
    expect(element.isConst, isFalse);
    expect(element.isDeprecated, isTrue);
    expect(element.isFinal, isFalse);
    expect(element.isPrivate, isTrue);
    expect(element.isStatic, isTrue);
  }

  void test_toJson() {
    var json = {
      KIND: 'METHOD',
      NAME: 'my name',
      OFFSET: 1,
      LENGTH: 2,
      FLAGS: Element.FLAG_DEPRECATED | Element.FLAG_PRIVATE |
          Element.FLAG_STATIC,
      PARAMETERS: '(int a, String b)',
      RETURN_TYPE: 'List<String>'
    };
    Element element = new Element.fromJson(json);
    expect(element.toJson(), equals(json));
  }
}
