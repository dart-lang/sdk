// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorTest1);
    defineReflectiveTests(ConstructorTest2);
  });
}

@reflectiveTest
class ConstructorTest1 extends AbstractCompletionDriverTest
    with ConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ConstructorTest2 extends AbstractCompletionDriverTest
    with ConstructorTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ConstructorTestCases on AbstractCompletionDriverTest {
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
    kind: constructorInvocation
  f0
    kind: constructorInvocation
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

    if (isProtocolVersion1) {
      assertResponse(r'''
suggestions
  S0
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
suggestions
''');
    }
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
