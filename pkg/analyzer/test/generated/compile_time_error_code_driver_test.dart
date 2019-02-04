// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest_Driver);
    defineReflectiveTests(ConstSetElementTypeImplementsEqualsTest);
    defineReflectiveTests(InvalidTypeArgumentInConstSetTest);
    defineReflectiveTests(NonConstSetElementFromDeferredLibraryTest);
    defineReflectiveTests(NonConstSetElementTest);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest_Driver extends CompileTimeErrorCodeTestBase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_awaitInWrongContext_sync() {
    return super.test_awaitInWrongContext_sync();
  }

  @override
  @failingTest
  test_constEvalThrowsException() {
    return super.test_constEvalThrowsException();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_async() {
    return super.test_invalidIdentifierInAsync_async();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_await() {
    return super.test_invalidIdentifierInAsync_await();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_yield() {
    return super.test_invalidIdentifierInAsync_yield();
  }

  @override
  @failingTest
  test_mixinOfNonClass() {
    return super.test_mixinOfNonClass();
  }

  @override
  @failingTest
  test_objectCannotExtendAnotherClass() {
    return super.test_objectCannotExtendAnotherClass();
  }

  @override
  @failingTest
  test_superInitializerInObject() {
    return super.test_superInitializerInObject();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_async() {
    return super.test_yieldEachInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_sync() {
    return super.test_yieldEachInNonGenerator_sync();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_async() {
    return super.test_yieldInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_sync() {
    return super.test_yieldInNonGenerator_sync();
  }
}

@reflectiveTest
class ConstSetElementTypeImplementsEqualsTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_constField() async {
    Source source = addSource(r'''
class A {
  static const a = const A();
  const A();
  operator ==(other) => false;
}
main() {
  const {A.a};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_direct() async {
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
main() {
  const {const A()};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_dynamic() async {
    // Note: static type of B.a is "dynamic", but actual type of the const
    // object is A.  We need to make sure we examine the actual type when
    // deciding whether there is a problem with operator==.
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B {
  static const a = const A();
}
main() {
  const {B.a};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_factory() async {
    Source source = addSource(r'''
class A { const factory A() = B; }

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  var m = const {const A()};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_super() async {
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B extends A {
  const B();
}
main() {
  const {const B()};
}
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_SET_ELEMENT_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }
}

@reflectiveTest
class InvalidTypeArgumentInConstSetTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_class() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET]);
    verify([source]);
  }
}

@reflectiveTest
class NonConstSetElementFromDeferredLibraryTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_topLevelVariable_immediate() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c};
}'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_topLevelVariable_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c + 1};
}'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }
}

@reflectiveTest
class NonConstSetElementTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments => [EnableString.set_literals];

  @override
  bool get enableNewAnalysisDriver => true;

  test_parameter() async {
    Source source = addSource(r'''
f(a) {
  return const {a};
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
    verify([source]);
  }
}
