// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/src/dart/element/element.dart' as engine;
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../abstract_single_unit.dart';
import '../utils/test_code_extensions.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertElementTest);
    defineReflectiveTests(ElementKindTest);
  });
}

@reflectiveTest
class ConvertElementTest extends AbstractSingleUnitTest {
  Future<void> test_CLASS() async {
    await resolveTestCode('''
@deprecated
abstract class [!_A!] {}
class B<K, V> {}''');
    {
      var engineElement = findElement2.class_('_A');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, '_A');
      expect(element.typeParameters, isNull);
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.length, '_A'.length);
        _expectLocation(location, parsedTestCode.range);
      }
      expect(element.parameters, isNull);
      expect(
        element.flags,
        Element.FLAG_ABSTRACT | Element.FLAG_DEPRECATED | Element.FLAG_PRIVATE,
      );
    }
    {
      var engineElement = findElement2.class_('B');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.CLASS);
      expect(element.name, 'B');
      expect(element.typeParameters, '<K, V>');
      expect(element.flags, 0);
    }
  }

  Future<void> test_CONSTRUCTOR() async {
    await resolveTestCode('''
class A {
  const A.[!myConstructor!](int a, [String? b]);
}''');
    var engineElement = findElement2.constructor('myConstructor');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.CONSTRUCTOR);
    expect(element.name, 'A.myConstructor');
    expect(element.typeParameters, isNull);
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'myConstructor'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, '(int a, [String? b])');
    expect(element.returnType, 'A');
    expect(element.flags, Element.FLAG_CONST);
  }

  Future<void> test_CONSTRUCTOR_required_parameters_1() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
import 'package:meta/meta.dart';
class A {
  const A.myConstructor(int a, {int? b, required int c});
}''');

    var engineElement = findElement2.constructor('myConstructor');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.parameters, '(int a, {required int c, int? b})');
  }

  /// Verify parameter re-ordering for required params
  Future<void> test_CONSTRUCTOR_required_parameters_2() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
import 'package:meta/meta.dart';
class A {
  const A.myConstructor(int a, {int? b, required int d, required int c});
}''');

    var engineElement = findElement2.constructor('myConstructor');
    // create notification Element
    var element = convertElement(engineElement);
    expect(
      element.parameters,
      '(int a, {required int d, required int c, int? b})',
    );
  }

  /// Verify parameter re-ordering for required params
  Future<void> test_CONSTRUCTOR_required_parameters_3() async {
    writeTestPackageConfig(meta: true);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:meta/meta.dart';
class A {
  const A.myConstructor(int a, {int b, required int d, required int c, int a});
}''');

    var engineElement = findElement2.constructor('myConstructor');
    // create notification Element
    var element = convertElement(engineElement);
    expect(
      element.parameters,
      '(int a, {required int d, required int c, int b, int a})',
    );
  }

  void test_dynamic() {
    var engineElement = engine.DynamicElementImpl2.instance;
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.UNKNOWN);
    expect(element.name, 'dynamic');
    expect(element.location, isNull);
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  Future<void> test_ENUM() async {
    await resolveTestCode('''
@deprecated
enum [!_E1!] { one, two }
enum E2 { three, four }''');
    {
      var engineElement = findElement2.enum_('_E1');
      expect(engineElement.metadata.hasDeprecated, isTrue);
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.ENUM);
      expect(element.name, '_E1');
      expect(element.typeParameters, isNull);
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.length, '_E1'.length);
        _expectLocation(location, parsedTestCode.range);
      }
      expect(element.parameters, isNull);
      expect(
        element.flags,
        (engineElement.metadata.hasDeprecated ? Element.FLAG_DEPRECATED : 0) |
            Element.FLAG_PRIVATE,
      );
    }
    {
      var engineElement = findElement2.enum_('E2');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.ENUM);
      expect(element.name, 'E2');
      expect(element.typeParameters, isNull);
      expect(element.flags, 0);
    }
  }

  Future<void> test_ENUM_CONSTANT() async {
    await resolveTestCode('''
@deprecated
enum _E1 { /*[0*/one/*0]*/, two }
enum E2 { /*[1*/three/*1]*/, four }''');
    {
      var engineElement = findElement2.field('one');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.ENUM_CONSTANT);
      expect(element.name, 'one');
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.length, 'one'.length);
        _expectLocation(location, parsedTestCode.ranges[0]);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, '_E1');
      var classElement = engineElement.enclosingElement;
      expect(classElement.metadata.hasDeprecated, isTrue);
      expect(
        element.flags,
        // Element.FLAG_DEPRECATED |
        Element.FLAG_CONST | Element.FLAG_STATIC,
      );
    }
    {
      var engineElement = findElement2.field('three');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.ENUM_CONSTANT);
      expect(element.name, 'three');
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.length, 'three'.length);
        _expectLocation(location, parsedTestCode.ranges[1]);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, 'E2');
      expect(element.flags, Element.FLAG_CONST | Element.FLAG_STATIC);
    }
    {
      var engineElement = findElement2.field('values', of: 'E2');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.FIELD);
      expect(element.name, 'values');
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.offset, 0);
        expect(location.length, 'values'.length);
        expect(location.startLine, 1);
        expect(location.startColumn, 1);
      }
      expect(element.parameters, isNull);
      expect(element.returnType, 'List<E2>');
      expect(element.flags, Element.FLAG_CONST | Element.FLAG_STATIC);
    }
  }

  Future<void> test_FIELD() async {
    await resolveTestCode('''
class A {
  static const [!myField!] = 42;
}''');
    var engineElement = findElement2.field('myField');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.FIELD);
    expect(element.name, 'myField');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'myField'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, 'int');
    expect(element.flags, Element.FLAG_CONST | Element.FLAG_STATIC);
  }

  Future<void> test_FUNCTION_TYPE_ALIAS_functionType() async {
    await resolveTestCode('''
typedef F<T> = int Function(String x);
''');
    var engineElement = findElement2.typeAlias('F');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<T>');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.offset, 8);
      expect(location.length, 'F'.length);
      expect(location.startLine, 1);
      expect(location.startColumn, 9);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, 'int');
    expect(element.flags, 0);
  }

  Future<void> test_FUNCTION_TYPE_ALIAS_interfaceType() async {
    await resolveTestCode('''
typedef F<T> = Map<int, T>;
''');
    var engineElement = findElement2.typeAlias('F');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<out T>');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.offset, 8);
      expect(location.length, 'F'.length);
      expect(location.startLine, 1);
      expect(location.startColumn, 9);
    }
    expect(element.aliasedType, 'Map<int, T>');
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  Future<void> test_FUNCTION_TYPE_ALIAS_legacy() async {
    await resolveTestCode('''
typedef int F<T>(String x);
''');
    var engineElement = findElement2.typeAlias('F');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.TYPE_ALIAS);
    expect(element.name, 'F');
    expect(element.typeParameters, '<T>');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.offset, 12);
      expect(location.length, 'F'.length);
      expect(location.startLine, 1);
      expect(location.startColumn, 13);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, 'int');
    expect(element.flags, 0);
  }

  Future<void> test_GETTER() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  String get [!myGetter!] => 42;
}''');
    var engineElement = findElement2.getter('myGetter');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.GETTER);
    expect(element.name, 'myGetter');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'myGetter'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, 'String');
    expect(element.flags, 0);
  }

  Future<void> test_LABEL() async {
    await resolveTestCode('''
void f() {
[!myLabel!]:
  while (true) {
    break myLabel;
  }
}''');
    var engineElement = findElement2.label('myLabel');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.LABEL);
    expect(element.name, 'myLabel');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'myLabel'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  Future<void> test_METHOD() async {
    await resolveTestCode('''
class A {
  static List<String> [!myMethod!](int a, {String? b, int? c}) {
    return [];
  }
}''');
    var engineElement = findElement2.method('myMethod');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.METHOD);
    expect(element.name, 'myMethod');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'myGetter'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, '(int a, {String? b, int? c})');
    expect(element.returnType, 'List<String>');
    expect(element.flags, Element.FLAG_STATIC);
  }

  Future<void> test_MIXIN() async {
    await resolveTestCode('''
mixin A {}
''');
    {
      var engineElement = findElement2.mixin('A');
      // create notification Element
      var element = convertElement(engineElement);
      expect(element.kind, ElementKind.MIXIN);
      expect(element.name, 'A');
      expect(element.typeParameters, isNull);
      {
        var location = element.location!;
        expect(location.file, testFile.path);
        expect(location.offset, 6);
        expect(location.length, 'A'.length);
        expect(location.startLine, 1);
        expect(location.startColumn, 7);
      }
      expect(element.parameters, isNull);
      expect(element.flags, Element.FLAG_ABSTRACT);
    }
  }

  Future<void> test_SETTER() async {
    await resolveTestCode('''
class A {
  set [!mySetter!](String x) {}
}''');
    var engineElement = findElement2.setter('mySetter');
    // create notification Element
    var element = convertElement(engineElement);
    expect(element.kind, ElementKind.SETTER);
    expect(element.name, 'mySetter');
    {
      var location = element.location!;
      expect(location.file, testFile.path);
      expect(location.length, 'mySetter'.length);
      _expectLocation(location, parsedTestCode.range);
    }
    expect(element.parameters, '(String x)');
    expect(element.returnType, isNull);
    expect(element.flags, 0);
  }

  void _expectLocation(Location actual, TestCodeRange expected) {
    expect(actual.offset, expected.sourceRange.offset);
    // LSP uses zero-based line/col, but server does uses one-based.
    expect(actual.startLine, expected.range.start.line + 1);
    expect(actual.startColumn, expected.range.start.character + 1);
  }
}

@reflectiveTest
class ElementKindTest {
  void test_fromEngine() {
    expect(convertElementKind(engine.ElementKind.CLASS), ElementKind.CLASS);
    expect(
      convertElementKind(engine.ElementKind.COMPILATION_UNIT),
      ElementKind.COMPILATION_UNIT,
    );
    expect(
      convertElementKind(engine.ElementKind.CONSTRUCTOR),
      ElementKind.CONSTRUCTOR,
    );
    expect(
      convertElementKind(engine.ElementKind.EXTENSION),
      ElementKind.EXTENSION,
    );
    expect(
      convertElementKind(engine.ElementKind.EXTENSION_TYPE),
      ElementKind.EXTENSION_TYPE,
    );
    expect(convertElementKind(engine.ElementKind.FIELD), ElementKind.FIELD);
    expect(
      convertElementKind(engine.ElementKind.FUNCTION),
      ElementKind.FUNCTION,
    );
    expect(
      convertElementKind(engine.ElementKind.FUNCTION_TYPE_ALIAS),
      ElementKind.FUNCTION_TYPE_ALIAS,
    );
    expect(
      convertElementKind(engine.ElementKind.GENERIC_FUNCTION_TYPE),
      ElementKind.FUNCTION_TYPE_ALIAS,
    );
    expect(convertElementKind(engine.ElementKind.GETTER), ElementKind.GETTER);
    expect(convertElementKind(engine.ElementKind.LABEL), ElementKind.LABEL);
    expect(convertElementKind(engine.ElementKind.LIBRARY), ElementKind.LIBRARY);
    expect(
      convertElementKind(engine.ElementKind.LOCAL_VARIABLE),
      ElementKind.LOCAL_VARIABLE,
    );
    expect(convertElementKind(engine.ElementKind.METHOD), ElementKind.METHOD);
    expect(
      convertElementKind(engine.ElementKind.PARAMETER),
      ElementKind.PARAMETER,
    );
    expect(convertElementKind(engine.ElementKind.SETTER), ElementKind.SETTER);
    expect(
      convertElementKind(engine.ElementKind.TOP_LEVEL_VARIABLE),
      ElementKind.TOP_LEVEL_VARIABLE,
    );
    expect(
      convertElementKind(engine.ElementKind.TYPE_ALIAS),
      ElementKind.TYPE_ALIAS,
    );
    expect(
      convertElementKind(engine.ElementKind.TYPE_PARAMETER),
      ElementKind.TYPE_PARAMETER,
    );
  }

  void test_toString() {
    expect(ElementKind.CLASS.toString(), 'ElementKind.CLASS');
    expect(
      ElementKind.COMPILATION_UNIT.toString(),
      'ElementKind.COMPILATION_UNIT',
    );
  }
}
