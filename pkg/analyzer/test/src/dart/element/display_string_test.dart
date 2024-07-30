// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementDisplayStringTest);
  });
}

@reflectiveTest
class ElementDisplayStringTest extends AbstractTypeSystemTest {
  void test_class() {
    var classA = class_(
      name: 'A',
      isAbstract: true,
      superType: stringNone,
      typeParameters: [typeParameter('T')],
    );

    var displayString = classA.getDisplayString();
    expect(displayString, 'abstract class A<T> extends String');
  }

  void test_extension_named() {
    var element = extension(
      name: 'StringExtension',
      extendedType: stringNone,
    );

    var displayString = element.getDisplayString();
    expect(displayString, 'extension StringExtension on String');
  }

  void test_extension_unnamed() {
    var element = extension(
      extendedType: stringNone,
    );

    var displayString = element.getDisplayString();
    expect(displayString, 'extension on String');
  }

  void test_extensionType() {
    var element = extensionType(
      'MyString',
      representationType: stringNone,
      interfaces: [stringNone],
      typeParameters: [typeParameter('T')],
    );

    var displayString = element.getDisplayString();
    expect(
      displayString,
      'extension type MyString<T>(String it) implements String',
    );
  }

  void test_longMethod() {
    var methodA = method(
      'longMethodName',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'aaa', type: stringQuestion),
        positionalParameter(
            name: 'bbb', type: stringQuestion, defaultValueCode: "'a'"),
        positionalParameter(name: 'ccc', type: stringQuestion),
      ],
    );

    var singleLine = methodA.getDisplayString();
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc])''');

    var multiLine = methodA.getDisplayString(
      multiline: true,
    );
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? bbb = 'a',
  String? ccc,
])''');
  }

  void test_longMethod_functionType() {
    // Function types are always kept on one line, even nested within multiline
    // signatures.
    var methodA = method(
      'longMethodName',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'aaa', type: stringQuestion),
        positionalParameter(
            name: 'bbb',
            type: functionTypeNone(
              parameters: [
                requiredParameter(name: 'xxx', type: stringQuestion),
                requiredParameter(name: 'yyy', type: stringQuestion),
                requiredParameter(name: 'zzz', type: stringQuestion),
              ],
              returnType: stringQuestion,
            )),
        positionalParameter(name: 'ccc', type: stringQuestion),
      ],
    );

    var singleLine = methodA.getDisplayString();
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? Function(String?, String?, String?) bbb, String? ccc])''');

    var multiLine = methodA.getDisplayString(
      multiline: true,
    );
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? Function(String?, String?, String?) bbb,
  String? ccc,
])''');
  }

  void test_property_getter() {
    var getterA = PropertyAccessorElementImpl.forVariable(
        TopLevelVariableElementImpl('a', 0))
      ..isGetter = true
      ..returnType = stringNone;

    expect(getterA.getDisplayString(), 'String get a');
  }

  void test_property_setter() {
    var setterA = PropertyAccessorElementImpl.forVariable(
        TopLevelVariableElementImpl('a', 0))
      ..isSetter = true
      ..returnType = voidNone
      ..parameters = [
        requiredParameter(name: 'value', type: stringNone),
      ];

    expect(
      setterA.getDisplayString(),
      'set a(String value)',
    );
  }

  void test_shortMethod() {
    var methodA = method(
      'm',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'a', type: stringQuestion),
        positionalParameter(name: 'b', type: stringQuestion),
      ],
    );

    var singleLine = methodA.getDisplayString();
    expect(singleLine, 'String? m(String? a, [String? b])');

    var multiLine = methodA.getDisplayString(
      multiline: true,
    );
    // The signature is short enough that it remains on one line even for
    // multiline: true.
    expect(multiLine, 'String? m(String? a, [String? b])');
  }
}
