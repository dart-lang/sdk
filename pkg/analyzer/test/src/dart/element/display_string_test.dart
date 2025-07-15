// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementDisplayStringTest);
  });
}

@reflectiveTest
class ElementDisplayStringTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}
abstract class B<T> extends A {}
''');

    var B = findElement2.class_('B');
    var displayString = B.displayString();
    expect(displayString, 'abstract class B<T> extends A');
  }

  test_extension_named() async {
    await assertNoErrorsInCode(r'''
extension StringExtension on String {}
''');

    var element = findElement2.extension_('StringExtension');
    var displayString = element.displayString();
    expect(displayString, 'extension StringExtension on String');
  }

  test_extension_unnamed() async {
    await assertNoErrorsInCode(r'''
extension on String {}
''');

    var element = result.libraryElement2.extensions.single;
    var displayString = element.displayString();
    expect(displayString, 'extension on String');
  }

  test_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type MyString<T>(String it) implements String {}
''');

    var element = findElement2.extensionType('MyString');
    var displayString = element.displayString();
    expect(
      displayString,
      'extension type MyString<T>(String it) implements String',
    );
  }

  test_longMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc]);
}
''');

    var methodElement = findElement2.method('longMethodName');
    var singleLine = methodElement.displayString();
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc])''');

    var multiLine = methodElement.displayString(multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? bbb = 'a',
  String? ccc,
])''');
  }

  test_longMethod_functionType() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String? longMethodName(
    String? aaa, 
    [String? Function(String?, String?, String?) bbb,
    String? ccc]
  );
}
''');

    var methodElement = findElement2.method('longMethodName');
    var singleLine = methodElement.displayString();
    expect(
      singleLine,
      '''
String? longMethodName(String? aaa, [String? Function(String?, String?, String?) bbb, String? ccc])''',
    );

    var multiLine = methodElement.displayString(multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? Function(String?, String?, String?) bbb,
  String? ccc,
])''');
  }

  test_property_getter() async {
    await assertNoErrorsInCode(r'''
String get a => '';
''');

    var element = findElement2.topGet('a');
    expect(element.displayString(), 'String get a');
  }

  test_property_setter() async {
    await assertNoErrorsInCode(r'''
set a(String value) {}
''');

    var element = findElement2.topSet('a');
    expect(element.displayString(), 'set a(String value)');
  }

  test_shortMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String? m(String? a, [String? b]);
}
''');

    var element = findElement2.method('m');
    var singleLine = element.displayString();
    expect(singleLine, 'String? m(String? a, [String? b])');

    var multiLine = element.displayString(multiline: true);
    // The signature is short enough that it remains on one line even for
    // multiline: true.
    expect(multiLine, 'String? m(String? a, [String? b])');
  }
}
