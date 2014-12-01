// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.computer.element;

import 'dart:mirrors';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart' as engine;
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import 'abstract_context.dart';
import 'mocks.dart';
import 'reflective_tests.dart';



main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisErrorTest);
  runReflectiveTests(ElementTest);
  runReflectiveTests(ElementKindTest);
  runReflectiveTests(EnumTest);
}


class AnalysisErrorMock extends TypedMock implements engine.AnalysisError {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


@ReflectiveTestCase()
class AnalysisErrorTest {
  engine.Source source = new MockSource();
  engine.LineInfo lineInfo;
  engine.AnalysisError engineError = new AnalysisErrorMock();

  void setUp() {
    // prepare Source
    when(source.fullName).thenReturn('foo.dart');
    // prepare LineInfo
    lineInfo = new engine.LineInfo([0, 5, 9, 20]);
    // prepare AnalysisError
    when(engineError.source).thenReturn(source);
    when(
        engineError.errorCode).thenReturn(engine.CompileTimeErrorCode.AMBIGUOUS_EXPORT);
    when(engineError.message).thenReturn('my message');
    when(engineError.offset).thenReturn(10);
    when(engineError.length).thenReturn(20);
  }

  void tearDown() {
    source = null;
    engineError = null;
  }

  void test_fromEngine_hasCorrection() {
    when(engineError.correction).thenReturn('my correction');
    AnalysisError error = newAnalysisError_fromEngine(lineInfo, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message',
      CORRECTION: 'my correction'
    });
  }

  void test_fromEngine_noCorrection() {
    when(engineError.correction).thenReturn(null);
    AnalysisError error = newAnalysisError_fromEngine(lineInfo, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: 3,
        START_COLUMN: 2
      },
      MESSAGE: 'my message'
    });
  }

  void test_fromEngine_noLineInfo() {
    when(engineError.correction).thenReturn(null);
    AnalysisError error = newAnalysisError_fromEngine(null, engineError);
    expect(error.toJson(), {
      SEVERITY: 'ERROR',
      TYPE: 'COMPILE_TIME_ERROR',
      LOCATION: {
        FILE: 'foo.dart',
        OFFSET: 10,
        LENGTH: 20,
        START_LINE: -1,
        START_COLUMN: -1
      },
      MESSAGE: 'my message'
    });
  }
}


class ElementKindTest {
  void test_fromEngine() {
    expect(
        newElementKind_fromEngine(engine.ElementKind.CLASS),
        ElementKind.CLASS);
    expect(
        newElementKind_fromEngine(engine.ElementKind.COMPILATION_UNIT),
        ElementKind.COMPILATION_UNIT);
    expect(
        newElementKind_fromEngine(engine.ElementKind.CONSTRUCTOR),
        ElementKind.CONSTRUCTOR);
    expect(
        newElementKind_fromEngine(engine.ElementKind.FIELD),
        ElementKind.FIELD);
    expect(
        newElementKind_fromEngine(engine.ElementKind.FUNCTION),
        ElementKind.FUNCTION);
    expect(
        newElementKind_fromEngine(engine.ElementKind.FUNCTION_TYPE_ALIAS),
        ElementKind.FUNCTION_TYPE_ALIAS);
    expect(
        newElementKind_fromEngine(engine.ElementKind.GETTER),
        ElementKind.GETTER);
    expect(
        newElementKind_fromEngine(engine.ElementKind.LABEL),
        ElementKind.LABEL);
    expect(
        newElementKind_fromEngine(engine.ElementKind.LIBRARY),
        ElementKind.LIBRARY);
    expect(
        newElementKind_fromEngine(engine.ElementKind.LOCAL_VARIABLE),
        ElementKind.LOCAL_VARIABLE);
    expect(
        newElementKind_fromEngine(engine.ElementKind.METHOD),
        ElementKind.METHOD);
    expect(
        newElementKind_fromEngine(engine.ElementKind.PARAMETER),
        ElementKind.PARAMETER);
    expect(
        newElementKind_fromEngine(engine.ElementKind.SETTER),
        ElementKind.SETTER);
    expect(
        newElementKind_fromEngine(engine.ElementKind.TOP_LEVEL_VARIABLE),
        ElementKind.TOP_LEVEL_VARIABLE);
    expect(
        newElementKind_fromEngine(engine.ElementKind.TYPE_PARAMETER),
        ElementKind.TYPE_PARAMETER);
    expect(
        newElementKind_fromEngine(engine.ElementKind.ANGULAR_COMPONENT),
        ElementKind.UNKNOWN);
  }

  void test_string_constructor() {
    expect(new ElementKind(ElementKind.CLASS.name), ElementKind.CLASS);
    expect(
        new ElementKind(ElementKind.CLASS_TYPE_ALIAS.name),
        ElementKind.CLASS_TYPE_ALIAS);
    expect(
        new ElementKind(ElementKind.COMPILATION_UNIT.name),
        ElementKind.COMPILATION_UNIT);
    expect(
        new ElementKind(ElementKind.CONSTRUCTOR.name),
        ElementKind.CONSTRUCTOR);
    expect(new ElementKind(ElementKind.FIELD.name), ElementKind.FIELD);
    expect(new ElementKind(ElementKind.FUNCTION.name), ElementKind.FUNCTION);
    expect(
        new ElementKind(ElementKind.FUNCTION_TYPE_ALIAS.name),
        ElementKind.FUNCTION_TYPE_ALIAS);
    expect(new ElementKind(ElementKind.GETTER.name), ElementKind.GETTER);
    expect(new ElementKind(ElementKind.LIBRARY.name), ElementKind.LIBRARY);
    expect(
        new ElementKind(ElementKind.LOCAL_VARIABLE.name),
        ElementKind.LOCAL_VARIABLE);
    expect(new ElementKind(ElementKind.METHOD.name), ElementKind.METHOD);
    expect(new ElementKind(ElementKind.PARAMETER.name), ElementKind.PARAMETER);
    expect(new ElementKind(ElementKind.SETTER.name), ElementKind.SETTER);
    expect(
        new ElementKind(ElementKind.TOP_LEVEL_VARIABLE.name),
        ElementKind.TOP_LEVEL_VARIABLE);
    expect(
        new ElementKind(ElementKind.TYPE_PARAMETER.name),
        ElementKind.TYPE_PARAMETER);
    expect(
        new ElementKind(ElementKind.UNIT_TEST_TEST.name),
        ElementKind.UNIT_TEST_TEST);
    expect(
        new ElementKind(ElementKind.UNIT_TEST_GROUP.name),
        ElementKind.UNIT_TEST_GROUP);
    expect(new ElementKind(ElementKind.UNKNOWN.name), ElementKind.UNKNOWN);
    expect(() {
      new ElementKind('no-such-kind');
    }, throws);
  }

  void test_toString() {
    expect(ElementKind.CLASS.toString(), 'ElementKind.CLASS');
    expect(
        ElementKind.COMPILATION_UNIT.toString(),
        'ElementKind.COMPILATION_UNIT');
  }
}


@ReflectiveTestCase()
class ElementTest extends AbstractContextTest {
  engine.Element findElementInUnit(engine.CompilationUnit unit, String name,
      [engine.ElementKind kind]) {
    return findChildElement(unit.element, name, kind);
  }

  void test_fromElement_CLASS() {
    engine.Source source = addSource('/test.dart', '''
@deprecated
abstract class _MyClass {}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.ClassElement engineElement = findElementInUnit(unit, '_MyClass');
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
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
    expect(element.parameters, isNull);
    expect(
        element.flags,
        Element.FLAG_ABSTRACT | Element.FLAG_DEPRECATED | Element.FLAG_PRIVATE);
  }

  void test_fromElement_CONSTRUCTOR() {
    engine.Source source = addSource('/test.dart', '''
class A {
  const A.myConstructor(int a, [String b]);
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.ConstructorElement engineElement =
        findElementInUnit(unit, 'myConstructor');
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
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

  void test_fromElement_dynamic() {
    var engineElement = engine.DynamicElementImpl.instance;
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
    expect(element.kind, ElementKind.UNKNOWN);
    expect(element.name, 'dynamic');
    expect(element.location, isNull);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  void test_fromElement_FIELD() {
    engine.Source source = addSource('/test.dart', '''
class A {
  static const myField = 42;
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.FieldElement engineElement = findElementInUnit(unit, 'myField');
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
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
    engine.Source source = addSource('/test.dart', '''
class A {
  String get myGetter => 42;
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.PropertyAccessorElement engineElement =
        findElementInUnit(unit, 'myGetter', engine.ElementKind.GETTER);
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
    expect(element.kind, ElementKind.GETTER);
    expect(element.name, 'myGetter');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 23);
      expect(location.length, 'myGetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 14);
    }
    expect(element.parameters, '()');
    expect(element.returnType, 'String');
    expect(element.flags, 0);
  }

  void test_fromElement_LABEL() {
    engine.Source source = addSource('/test.dart', '''
main() {
myLabel:
  while (true) {
    break myLabel;
  }
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.LabelElement engineElement = findElementInUnit(unit, 'myLabel');
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
    expect(element.kind, ElementKind.LABEL);
    expect(element.name, 'myLabel');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 9);
      expect(location.length, 'myLabel'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 1);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  void test_fromElement_METHOD() {
    engine.Source source = addSource('/test.dart', '''
class A {
  static List<String> myMethod(int a, {String b}) {
    return null;
  }
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.MethodElement engineElement = findElementInUnit(unit, 'myMethod');
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
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

  void test_fromElement_SETTER() {
    engine.Source source = addSource('/test.dart', '''
class A {
  set mySetter(String x) {}
}''');
    engine.CompilationUnit unit = resolveLibraryUnit(source);
    engine.FieldElement engineFieldElement =
        findElementInUnit(unit, 'mySetter', engine.ElementKind.FIELD);
    engine.PropertyAccessorElement engineElement = engineFieldElement.setter;
    // create notification Element
    Element element = newElement_fromEngine(engineElement);
    expect(element.kind, ElementKind.SETTER);
    expect(element.name, 'mySetter');
    {
      Location location = element.location;
      expect(location.file, '/test.dart');
      expect(location.offset, 16);
      expect(location.length, 'mySetter'.length);
      expect(location.startLine, 2);
      expect(location.startColumn, 7);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }
}

@ReflectiveTestCase()
class EnumTest {
  void test_AnalysisErrorSeverity() {
    new EnumTester<engine.ErrorSeverity, AnalysisErrorSeverity>().run(
        (engine.ErrorSeverity engineErrorSeverity) =>
            new AnalysisErrorSeverity(engineErrorSeverity.name),
        exceptions: {
      engine.ErrorSeverity.NONE: null
    });
  }

  void test_AnalysisErrorType() {
    new EnumTester<engine.ErrorType, AnalysisErrorType>().run(
        (engine.ErrorType engineErrorType) =>
            new AnalysisErrorType(engineErrorType.name));
  }

  void test_ElementKind() {
    new EnumTester<engine.ElementKind, ElementKind>().run(
        newElementKind_fromEngine,
        exceptions: {
      // TODO(paulberry): do any of the exceptions below constitute bugs?
      engine.ElementKind.ANGULAR_FORMATTER: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_COMPONENT: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_CONTROLLER: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_DIRECTIVE: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_PROPERTY: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_SCOPE_PROPERTY: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_SELECTOR: ElementKind.UNKNOWN,
      engine.ElementKind.ANGULAR_VIEW: ElementKind.UNKNOWN,
      engine.ElementKind.DYNAMIC: ElementKind.UNKNOWN,
      engine.ElementKind.EMBEDDED_HTML_SCRIPT: ElementKind.UNKNOWN,
      engine.ElementKind.ERROR: ElementKind.UNKNOWN,
      engine.ElementKind.EXPORT: ElementKind.UNKNOWN,
      engine.ElementKind.EXTERNAL_HTML_SCRIPT: ElementKind.UNKNOWN,
      engine.ElementKind.HTML: ElementKind.UNKNOWN,
      engine.ElementKind.IMPORT: ElementKind.UNKNOWN,
      engine.ElementKind.NAME: ElementKind.UNKNOWN,
      engine.ElementKind.POLYMER_ATTRIBUTE: ElementKind.UNKNOWN,
      engine.ElementKind.POLYMER_TAG_DART: ElementKind.UNKNOWN,
      engine.ElementKind.POLYMER_TAG_HTML: ElementKind.UNKNOWN,
      engine.ElementKind.UNIVERSE: ElementKind.UNKNOWN
    });
  }

  void test_SearchResultKind() {
    // TODO(paulberry): why does the MatchKind class exist at all?  Can't we
    // use SearchResultKind inside the analysis server?
    new EnumTester<MatchKind, SearchResultKind>().run(
        newSearchResultKind_fromEngine,
        exceptions: {
      // TODO(paulberry): do any of the exceptions below constitute bugs?
      MatchKind.ANGULAR_REFERENCE: SearchResultKind.UNKNOWN,
      MatchKind.ANGULAR_CLOSING_TAG_REFERENCE: SearchResultKind.UNKNOWN
    });
  }
}


/**
 * Helper class for testing the correspondence between an analysis engine enum
 * and an analysis server API enum.
 */
class EnumTester<EngineEnum, ApiEnum extends Enum> {
  /**
   * Test that the function [convert] properly converts all possible values of
   * [EngineEnum] to an [ApiEnum] with the same name, with the exceptions noted
   * in [exceptions].  For each key in [exceptions], if the corresponding value
   * is null, then we check that converting the given key results in an error.
   * If the corresponding value is an [ApiEnum], then we check that converting
   * the given key results in the given value.
   */
  void run(ApiEnum convert(EngineEnum value), {Map<EngineEnum,
      ApiEnum> exceptions: const {}}) {
    ClassMirror engineClass = reflectClass(EngineEnum);
    engineClass.staticMembers.forEach((Symbol symbol, MethodMirror method) {
      if (symbol == #values) {
        return;
      }
      if (!method.isGetter) {
        return;
      }
      String enumName = MirrorSystem.getName(symbol);
      EngineEnum engineValue = engineClass.getField(symbol).reflectee;
      expect(engineValue, new isInstanceOf<EngineEnum>());
      if (exceptions.containsKey(engineValue)) {
        ApiEnum expectedResult = exceptions[engineValue];
        if (expectedResult == null) {
          expect(() {
            convert(engineValue);
          }, throws);
        } else {
          ApiEnum apiValue = convert(engineValue);
          expect(apiValue, equals(expectedResult));
        }
      } else {
        ApiEnum apiValue = convert(engineValue);
        expect(apiValue.name, equals(enumName));
      }
    });
  }
}
