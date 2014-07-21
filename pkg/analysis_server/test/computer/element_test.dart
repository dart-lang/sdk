// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.element;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_testing/abstract_context.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart' as engine;
import 'package:unittest/unittest.dart';



main() {
  groupSep = ' | ';
  group('Element', () {
    runReflectiveTests(ElementTest);
  });
  group('ElementKind', () {
    runReflectiveTests(ElementKindTest);
  });
}


class ElementKindTest {
  void test_toString() {
    expect(ElementKind.CLASS.toString(), 'CLASS');
    expect(ElementKind.COMPILATION_UNIT.toString(), 'COMPILATION_UNIT');
  }

  void test_valueOf() {
    expect(ElementKind.valueOf(ElementKind.CLASS.name), ElementKind.CLASS);
    expect(
        ElementKind.valueOf(ElementKind.CLASS_TYPE_ALIAS.name),
        ElementKind.CLASS_TYPE_ALIAS);
    expect(
        ElementKind.valueOf(ElementKind.COMPILATION_UNIT.name),
        ElementKind.COMPILATION_UNIT);
    expect(
        ElementKind.valueOf(ElementKind.CONSTRUCTOR.name),
        ElementKind.CONSTRUCTOR);
    expect(ElementKind.valueOf(ElementKind.FIELD.name), ElementKind.FIELD);
    expect(
        ElementKind.valueOf(ElementKind.FUNCTION.name),
        ElementKind.FUNCTION);
    expect(
        ElementKind.valueOf(ElementKind.FUNCTION_TYPE_ALIAS.name),
        ElementKind.FUNCTION_TYPE_ALIAS);
    expect(ElementKind.valueOf(ElementKind.GETTER.name), ElementKind.GETTER);
    expect(ElementKind.valueOf(ElementKind.LIBRARY.name), ElementKind.LIBRARY);
    expect(
        ElementKind.valueOf(ElementKind.LOCAL_VARIABLE.name),
        ElementKind.LOCAL_VARIABLE);
    expect(ElementKind.valueOf(ElementKind.METHOD.name), ElementKind.METHOD);
    expect(
        ElementKind.valueOf(ElementKind.PARAMETER.name),
        ElementKind.PARAMETER);
    expect(ElementKind.valueOf(ElementKind.SETTER.name), ElementKind.SETTER);
    expect(
        ElementKind.valueOf(ElementKind.TOP_LEVEL_VARIABLE.name),
        ElementKind.TOP_LEVEL_VARIABLE);
    expect(
        ElementKind.valueOf(ElementKind.TYPE_PARAMETER.name),
        ElementKind.TYPE_PARAMETER);
    expect(
        ElementKind.valueOf(ElementKind.UNIT_TEST_CASE.name),
        ElementKind.UNIT_TEST_CASE);
    expect(
        ElementKind.valueOf(ElementKind.UNIT_TEST_GROUP.name),
        ElementKind.UNIT_TEST_GROUP);
    expect(ElementKind.valueOf(ElementKind.UNKNOWN.name), ElementKind.UNKNOWN);
    expect(() {
      ElementKind.valueOf('no-such-kind');
    }, throws);
  }

  void test_valueOfEngine() {
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.CLASS),
        ElementKind.CLASS);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.COMPILATION_UNIT),
        ElementKind.COMPILATION_UNIT);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.CONSTRUCTOR),
        ElementKind.CONSTRUCTOR);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.FIELD),
        ElementKind.FIELD);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.FUNCTION),
        ElementKind.FUNCTION);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.FUNCTION_TYPE_ALIAS),
        ElementKind.FUNCTION_TYPE_ALIAS);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.GETTER),
        ElementKind.GETTER);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.LIBRARY),
        ElementKind.LIBRARY);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.LOCAL_VARIABLE),
        ElementKind.LOCAL_VARIABLE);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.METHOD),
        ElementKind.METHOD);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.PARAMETER),
        ElementKind.PARAMETER);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.SETTER),
        ElementKind.SETTER);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.TOP_LEVEL_VARIABLE),
        ElementKind.TOP_LEVEL_VARIABLE);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.TYPE_PARAMETER),
        ElementKind.TYPE_PARAMETER);
    expect(
        ElementKind.valueOfEngine(engine.ElementKind.ANGULAR_COMPONENT),
        ElementKind.UNKNOWN);
  }
}


@ReflectiveTestCase()
class ElementTest extends AbstractContextTest {
  engine.Element findElementInUnit(CompilationUnit unit, String name,
      [engine.ElementKind kind]) {
    return findChildElement(unit.element, name, kind);
  }

  void test_fromElement_CLASS() {
    Source source = addSource('/test.dart', '''
@deprecated
abstract class _MyClass {}''');
    CompilationUnit unit = resolveLibraryUnit(source);
    engine.ClassElement engineElement = findElementInUnit(unit, '_MyClass');
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.CLASS);
    expect(element.name, '_MyClass');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 27);
      expect(location.length, '_MyClass'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 16);
    }
    expect(
        element.flags,
        Element.FLAG_ABSTRACT | Element.FLAG_DEPRECATED | Element.FLAG_PRIVATE);
  }

  void test_fromElement_CONSTRUCTOR() {
    Source source = addSource('/test.dart', '''
class A {
  const A.myConstructor(int a, [String b]);
}''');
    CompilationUnit unit = resolveLibraryUnit(source);
    engine.ConstructorElement engineElement =
        findElementInUnit(unit, 'myConstructor');
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.CONSTRUCTOR);
    expect(element.name, 'myConstructor');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 20);
      expect(location.length, 'myConstructor'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 11);
    }
    expect(element.parameters, '(int a, [String b])');
    expect(element.returnType, 'A');
    expect(element.flags, Element.FLAG_CONST);
  }

  void test_fromElement_FIELD() {
    Source source = addSource('/test.dart', '''
class A {
  static const myField = 42;
}''');
    CompilationUnit unit = resolveLibraryUnit(source);
    engine.FieldElement engineElement = findElementInUnit(unit, 'myField');
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.FIELD);
    expect(element.name, 'myField');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 25);
      expect(location.length, 'myField'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 16);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, Element.FLAG_CONST | Element.FLAG_STATIC);
  }

  void test_fromElement_GETTER() {
    Source source = addSource('/test.dart', '''
class A {
  String myGetter => 42;
}''');
    CompilationUnit unit = resolveLibraryUnit(source);
    engine.PropertyAccessorElement engineElement =
        findElementInUnit(unit, 'myGetter', engine.ElementKind.GETTER);
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.GETTER);
    expect(element.name, 'myGetter');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 19);
      expect(location.length, 'myGetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 10);
    }
    expect(element.parameters, '()');
    expect(element.returnType, 'String');
    expect(element.flags, 0);
  }

  void test_fromElement_METHOD() {
    Source source = addSource('/test.dart', '''
class A {
  static List<String> myMethod(int a, {String b}) {
    return null;
  }
}''');
    CompilationUnit unit = resolveLibraryUnit(source);
    engine.MethodElement engineElement = findElementInUnit(unit, 'myMethod');
    // create notification Element
    Element element = new Element.fromEngine(engineElement);
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'myMethod');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 32);
      expect(location.length, 'myGetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 23);
    }
    expect(element.parameters, '(int a, {String b})');
    expect(element.returnType, 'List<String>');
    expect(element.flags, Element.FLAG_STATIC);
  }

  void test_fromJson() {
    var flags =
        Element.FLAG_DEPRECATED |
        Element.FLAG_PRIVATE |
        Element.FLAG_STATIC;
    var json = {
      KIND: 'METHOD',
      NAME: 'my name',
      LOCATION: {
        FILE: '/project/file.dart',
        OFFSET: 1,
        LENGTH: 2,
        START_LINE: 3,
        START_COLUMN: 4,
      },
      FLAGS: flags,
      PARAMETERS: '(int a, String b)',
      RETURN_TYPE: 'List<String>'
    };
    Element element = new Element.fromJson(json);
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'my name');
    {
      Location location = element.location;
      expect(location.file, '/project/file.dart');
      expect(location.offset, 1);
      expect(location.length, 2);
      expect(location.startLine, 3);
      expect(location.startColumn, 4);
    }
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
      LOCATION: {
        FILE: '/project/file.dart',
        OFFSET: 1,
        LENGTH: 2,
        START_LINE: 3,
        START_COLUMN: 4,
      },
      FLAGS: Element.FLAG_DEPRECATED |
          Element.FLAG_PRIVATE |
          Element.FLAG_STATIC,
      PARAMETERS: '(int a, String b)',
      RETURN_TYPE: 'List<String>'
    };
    Element element = new Element.fromJson(json);
    expect(element.toJson(), equals(json));
  }
}
