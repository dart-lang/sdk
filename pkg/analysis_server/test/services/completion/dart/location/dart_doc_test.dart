// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartDocTest);
  });
}

@reflectiveTest
class DartDocTest extends AbstractCompletionDriverTest {
  Future<void> test_class() async {
    allowedIdentifiers = const {'MyClass1'};
    await computeSuggestions('''
/// This doc should suggest the commented class name [MyC^].
class MyClass1 {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyClass1
    kind: class
''');
  }

  Future<void> test_constructorInvocation() async {
    allowedIdentifiers = const {'constructor1'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented constructor name [MyClass1.^].
  MyClass1.constructor1();
}
''');
    assertResponse(r'''
suggestions
  constructor1
    kind: constructor
''');
  }

  Future<void> test_constructorParameter() async {
    allowedIdentifiers = const {'param1'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented constructor parameter name [par^].
  MyClass1([int param1 = 0]);
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  param1
    kind: parameter
''');
  }

  Future<void> test_enum() async {
    allowedIdentifiers = const {'MyEnum'};
    await computeSuggestions('''
/// This doc should suggest the commented enum name [MyE^].
enum MyEnum { value1 }
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyEnum
    kind: enum
''');
  }

  Future<void> test_enumConstant() async {
    allowedIdentifiers = const {'value1'};
    await computeSuggestions('''
enum MyEnum {
  /// This doc should suggest the commented enum constant name [val^].
  value1
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  value1
    kind: enumConstant
''');
  }

  Future<void> test_extension() async {
    allowedIdentifiers = const {'MyExt'};
    await computeSuggestions('''
/// This doc should suggest the commented extension name [MyE^].
extension MyExt on int {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyExt
    kind: extension
''');
  }

  Future<void> test_extension2() async {
    allowedIdentifiers = const {'isEven'};
    await computeSuggestions('''
/// This doc should suggest other things like [int.isE^].
extension MyExt on int {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  isEven
    kind: getter
''');
  }

  Future<void> test_extensionType() async {
    allowedIdentifiers = const {'MyExtensionType'};
    await computeSuggestions('''
/// This doc should suggest the commented extension type name [MyE^].
extension type MyExtensionType(int i) {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyExtensionType
    kind: extensionType
''');
  }

  Future<void> test_field1() async {
    allowedIdentifiers = const {'myField'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented field name [myF^].
  int myField = 0;
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myField
    kind: field
''');
  }

  Future<void> test_field2() async {
    allowedIdentifiers = const {'myField'};
    await computeSuggestions('''
/// This is unrelated but should suggest name [MyClass1.myF^].
var myVariable = 0;

class MyClass1 {
  int myField = 0;
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myField
    kind: field
''');
  }

  Future<void> test_function() async {
    allowedIdentifiers = const {'myFunction'};
    await computeSuggestions('''
/// This doc should suggest the commented function name [myF^].
void myFunction() {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myFunction
    kind: function
''');
  }

  Future<void> test_getter() async {
    allowedIdentifiers = const {'myGetter'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented getter name [myG^].
  int get myGetter => 0;
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myGetter
    kind: getter
''');
  }

  Future<void> test_getter2() async {
    allowedIdentifiers = const {'myGetter'};
    await computeSuggestions('''
/// This is unrelated but should suggest name [MyExtension1.myG^].
var myVariable = 0;

extension MyExtension1 {
  int get myGetter => 0;
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myGetter
    kind: getter
''');
  }

  Future<void> test_getter3() async {
    allowedIdentifiers = const {'myGetter'};
    await computeSuggestions('''
/// This is unrelated but should suggest name [MyExtensionType1.myG^].
var myVariable = 0;

extension type MyExtensionType1(int i) {
  int get myGetter => 0;
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myGetter
    kind: getter
''');
  }

  Future<void> test_importPrefix() async {
    allowedIdentifiers = const {'async'};
    await computeSuggestions('''
/// This doc should suggest the commented import prefix name [asy^].
import 'dart:async' as async;
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  async
    kind: library
''');
  }

  Future<void> test_library() async {
    allowedIdentifiers = const {'MyClass1'};
    await computeSuggestions('''
/// This doc should suggest the class in the library [MyC^].
library;

class MyClass1 {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyClass1
    kind: class
''');
  }

  Future<void> test_method() async {
    allowedIdentifiers = const {'myMethod'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented method name [myM^].
  void myMethod() {}
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myMethod
    kind: method
''');
  }

  Future<void> test_mixin() async {
    allowedIdentifiers = const {'MyMixin'};
    await computeSuggestions('''
/// This doc should suggest the commented mixin name [MyM^].
mixin MyMixin {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyMixin
    kind: mixin
''');
  }

  Future<void> test_namedParameter() async {
    allowedIdentifiers = const {'param1'};
    await computeSuggestions('''
/// This doc should suggest the commented named parameter name [par^].
void myFunction({int param1}) {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  param1
    kind: parameter
''');
  }

  Future<void> test_notInSquareBraces() async {
    allowedIdentifiers = const {'MyClass1'};
    await computeSuggestions('''
/// This doc should not suggest the commented class name [] outside the braces ^
class MyClass1 {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_parameter() async {
    allowedIdentifiers = const {'param1'};
    await computeSuggestions('''
/// This doc should suggest the commented parameter name [par^].
void myFunction(int param1) {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  param1
    kind: parameter
''');
  }

  Future<void> test_setter() async {
    allowedIdentifiers = const {'mySetter'};
    await computeSuggestions('''
class MyClass1 {
  /// This doc should suggest the commented setter name [myS^].
  set mySetter(int value) {}
}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  mySetter
    kind: setter
''');
  }

  Future<void> test_start() async {
    // There was a crash because we tried to walk before the (only) token
    // of the documentation comment.
    await computeSuggestions('''
^/// hello
class A {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_topLevelGetter() async {
    allowedIdentifiers = const {'myTopLevelGetter'};
    await computeSuggestions('''
/// This doc should suggest the commented top-level getter name [myT^].
int get myTopLevelGetter => 0;
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myTopLevelGetter
    kind: getter
''');
  }

  Future<void> test_topLevelSetter() async {
    allowedIdentifiers = const {'myTopLevelSetter'};
    await computeSuggestions('''
/// This doc should suggest the commented top-level setter name [myT^].
set myTopLevelSetter(int value) {}
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myTopLevelSetter
    kind: setter
''');
  }

  Future<void> test_typedef() async {
    allowedIdentifiers = const {'MyTypedef'};
    await computeSuggestions('''
/// This doc should suggest the commented typedef name [MyT^].
typedef MyTypedef = int Function();
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  MyTypedef
    kind: typeAlias
''');
  }

  Future<void> test_typedef2() async {
    allowedIdentifiers = const {'delayed'};
    await computeSuggestions('''
/// This doc should suggest other things like [Future.de^].
typedef MyTypedef = int Function();
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  delayed
    kind: constructor
''');
  }

  Future<void> test_typeParameter() async {
    allowedIdentifiers = const {'TypeParam'};
    await computeSuggestions('''
/// This doc should suggest the commented type parameter name [T^].
void myFunction<TypeParam>() {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  TypeParam
    kind: typeParameter
''');
  }

  Future<void> test_variable() async {
    allowedIdentifiers = const {'myVar'};
    await computeSuggestions('''
/// This doc should suggest the commented variable name [myV^].
int myVar = 0;
''');
    assertResponse(r'''
replacement
  left: 3
suggestions
  myVar
    kind: topLevelVariable
''');
  }
}
