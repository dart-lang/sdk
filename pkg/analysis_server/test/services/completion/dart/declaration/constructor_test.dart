// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorTest);
    defineReflectiveTests(NamedConstructorTest);
  });
}

@reflectiveTest
class ConstructorTest extends AbstractCompletionDriverTest
    with ConstructorTestCases {}

mixin ConstructorTestCases on AbstractCompletionDriverTest {
  Future<void> test_constContext_constructorTearOff() async {
    allowedIdentifiers = const {'NotAConst'};
    newFile('$testPackageLibPath/a.dart', '''
class A {
  const A(List<Object> any);
}

class NotAConst {}
''');
    await computeSuggestions('''
import 'a.dart';

 @A([
   N^
 ])
 class E {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  NotAConst.new
    kind: constructor
  null
    kind: keyword
''');
  }

  Future<void> test_noKeyword() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  A0.f0();
  A0.b0();
}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  A0.^;
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: constructorInvocation
  f0
    kind: constructorInvocation
''');
  }

  Future<void> test_noKeyword_matchForContextType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  A0.f0();
  A0.b0();
}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  A Function() v = A0.^;
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: constructor
  f0
    kind: constructor
''');
  }

  Future<void> test_noKeyword_notMatchForContextType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  A0.f0();
  A0.b0();
}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  int Function() v = A0.^;
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: constructorInvocation
  f0
    kind: constructorInvocation
''');
  }

  Future<void> test_sealed_library() async {
    newFile('$testPackageLibPath/a.dart', '''
sealed class S0 {}
''');
    await computeSuggestions('''
import 'a.dart';
void f() {
  var x = new ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_sealed_local() async {
    await computeSuggestions('''
sealed class S0 {}
void f() {
  var x = new ^
}
''');

    assertResponse(r'''
suggestions
''');
  }
}

@reflectiveTest
class NamedConstructorTest extends AbstractCompletionDriverTest
    with NamedConstructorTestCases {}

mixin NamedConstructorTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers = {'new', 'named', 'c', '_d', 'fromCharCodes'};
  }

  Future<void> test_functionTypeContext_matchingReturnType() async {
    await computeSuggestions('''
class A {
  A();
  A.named();
}

void f() {
  A Function() v = A.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
  new
    kind: constructor
''');
  }

  Future<void> test_functionTypeContext_matchingReturnType_partial() async {
    await computeSuggestions('''
class A {
  A();
  A.named();
}

void f() {
  A Function() v = A.na^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  named
    kind: constructor
''');
  }

  Future<void>
  test_functionTypeContext_matchingReturnType_withTypeArguments() async {
    await computeSuggestions('''
class A<T> {
  A.named();
  A.new();
}

void f() {
  A<int> Function() v = A<int>.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
  new
    kind: constructor
''');
  }

  Future<void>
  test_functionTypeContext_matchingReturnType_withTypeArguments2() async {
    await computeSuggestions('''
class A {}

class B<T> extends A {
  B.named();
  B.new();
}

void f() {
  A Function() v = B<int>.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
  new
    kind: constructor
''');
  }

  Future<void>
  test_functionTypeContext_matchingReturnType_withTypeArguments_partial() async {
    await computeSuggestions('''
class A<T> {
  A.named();
  A.new();
}

void f() {
  A<int> Function() v = A<int>.na^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  named
    kind: constructor
''');
  }

  Future<void>
  test_functionTypeContext_matchingReturnType_withTypeArguments_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A<T> {
  A.named();
  A.new();
}
''');
    await computeSuggestions('''
import 'a.dart' as prefix;

void f() {
  A<int> Function() v = prefix.A<int>.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
  new
    kind: constructor
''');
  }

  Future<void>
  test_functionTypeContext_notMatchingReturnType_withTypeArguments() async {
    await computeSuggestions('''
class A<T> {
  A.named();
}

void f() {
  List<int> Function() v = A<int>.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
''');
  }

  Future<void> test_importedClass() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {
    X._d0();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
var m0;
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_importedClass_unresolved() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {
    X._d0();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
var m0;
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_importedFactory() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  factory X.c() {
    return X._d0();
  }
  factory X._d0() {
    return X.c();
  }
  z0() {}
}
''');
    await computeSuggestions('''
import 'b.dart';
var m0;
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_importedFactory2() async {
    await computeSuggestions('''
void f() {
  new String.fr^omCharCodes([]);
}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 11
suggestions
  fromCharCodes
    kind: constructorInvocation
''');
  }

  Future<void> test_interfaceContextType_withTypeArguments() async {
    await computeSuggestions('''
class A<T> {
  A.named();
}

void f() {
  A<int> v = A<int>.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructor
''');
  }

  Future<void> test_interfaceTypeContext() async {
    await computeSuggestions('''
class A {
  A();
  A.named();
}

void f() {
  int v = A.^;
}
''');
    assertResponse(r'''
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_interfaceTypeContext_partial() async {
    await computeSuggestions('''
class A {
  A();
  A.named();
}

void f() {
  int v = A.na^;
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  named
    kind: constructorInvocation
''');
  }

  Future<void> test_localClass() async {
    await computeSuggestions('''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d();
  z0() {}
}
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  _d
    kind: constructorInvocation
  c
    kind: constructorInvocation
''');
  }

  Future<void> test_localFactory() async {
    await computeSuggestions('''
int T0;
F0() {}
class X {
  factory X.c();
  factory X._d();
  z0() {}
}
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  _d
    kind: constructorInvocation
  c
    kind: constructorInvocation
''');
  }
}
