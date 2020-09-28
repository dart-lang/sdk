// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearOffTest);
  });
}

@reflectiveTest
class TearOffTest extends PubPackageResolutionTest {
  test_empty_contextNotInstantiated() async {
    await assertErrorsInCode('''
T f<T>(T x) => x;

void test() {
  U Function<U>(U) context;
  context = f; // 1
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 7),
    ]);
    _assertTearOff(
      'f; // 1',
      findElement.topFunction('f'),
      'T Function<T>(T)',
      [],
    );
  }

  test_empty_notGeneric() async {
    await assertErrorsInCode('''
int f(int x) => x;

void test() {
  int Function(int) context;
  context = f; // 1
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 7),
    ]);
    _assertTearOff(
      'f; // 1',
      findElement.topFunction('f'),
      'int Function(int)',
      [],
    );
  }

  test_notEmpty() async {
    await assertErrorsInCode('''
T f<T>(T x) => x;

class C {
  T f<T>(T x) => x;
  static T g<T>(T x) => x;
}

class D extends C {
  void test() {
    int Function(int) func;
    func = super.f; // 1
  }
}

void test() {
  T h<T>(T x) => x;
  int Function(int) func;
  func = f; // 2
  func = new C().f; // 3
  func = C.g; // 4
  func = h; // 5
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 137, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 229, 4),
    ]);
    _assertTearOff(
      'f; // 1',
      findElement.method('f', of: 'C'),
      'int Function(int)',
      ['int'],
    );
    _assertTearOff(
      'f; // 2',
      findElement.topFunction('f'),
      'int Function(int)',
      ['int'],
    );
    _assertTearOff(
      'f; // 3',
      findElement.method('f', of: 'C'),
      'int Function(int)',
      ['int'],
    );
    _assertTearOff(
      'g; // 4',
      findElement.method('g', of: 'C'),
      'int Function(int)',
      ['int'],
    );
    _assertTearOff(
      'h; // 5',
      findElement.localFunction('h'),
      'int Function(int)',
      ['int'],
    );
  }

  test_null_notTearOff() async {
    await assertNoErrorsInCode('''
T f<T>(T x) => x;

void test() {
  f(0);
}
''');
    _assertTearOff(
      'f(0);',
      findElement.topFunction('f'),
      'T Function<T>(T)',
      null,
    );
    assertInvokeType(
      findNode.methodInvocation('f(0)'),
      'int Function(int)',
    );
  }

  void _assertTearOff(
    String search,
    ExecutableElement element,
    String type,
    List<String> typeArguments,
  ) {
    var id = findNode.simple(search);
    assertElement(id, element);
    assertType(id, type);
    if (typeArguments != null) {
      assertElementTypeStrings(id.tearOffTypeArgumentTypes, typeArguments);
    } else {
      expect(id.tearOffTypeArgumentTypes, isNull);
    }
  }
}
