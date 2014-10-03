// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;


import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(InvocationComputerTest);
}

@ReflectiveTestCase()
class InvocationComputerTest extends AbstractCompletionTest {

  @override
  void setUp() {
    super.setUp();
    computer = new InvocationComputer();
  }

  test_PrefixedIdentifier_field() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      class A {var b; X _c;}
      class X{}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b', null);
      assertSuggestGetter('_c', 'X');
    });
  }

  test_PrefixedIdentifier_field_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class X{}
      class A {var b; X _c;}''');
    addTestSource('''
      import "/testB.dart";
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b', null);
      assertNotSuggested('_c');
    });
  }

  // TODO (danrubel) implement
  test_PrefixedIdentifier_getter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      class A {X get b => new A();get _c => new A();}
      class X{}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b', 'X');
      assertSuggestGetter('_c', null);
    });
  }

  test_PrefixedIdentifier_getter_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class S{}
      class X {S get y => new X(); X get _z => new X();}''');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestGetter('y', 'S');
      assertNotSuggested('_z');
    });
  }

  test_PrefixedIdentifier_getter_interface() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      class A {S get b => new A();A get _c => new A();}
      class B implements A {S get b => new A();} class S{}
      main() {B b; b.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b', 'S');
      assertSuggestGetter('_c', 'A');
    });
  }

  test_PrefixedIdentifier_library() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class X { }
      class Y { }''');
    addTestSource('''
      import "/testB.dart" as b;
      main() {b.^}''');
    return computeFull().then((_) {
      assertSuggestClass('X');
      assertSuggestClass('Y');
    });
  }

  test_PrefixedIdentifier_method() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      class S{}
      class A {b(X x) {} S _c(X x) {}}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestMethod('b', 'A', null);
      assertSuggestMethod('_c', 'A', 'S');
    });
  }

  test_PrefixedIdentifier_method_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class X {T y(X x) {} _z(X x) {}}
      class T{}''');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestMethod('y', 'X', 'T');
      assertNotSuggested('_z');
    });
  }

  test_PrefixedIdentifier_method_imported_mixin() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class X {T y(X x) {} _z(X x) {}}
      class T{}''');
    addTestSource('''
      import "/testB.dart";
      class A extends Object with X {}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestMethod('y', 'X', 'T');
      assertNotSuggested('_z');
    });
  }

  test_PrefixedIdentifier_parameter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class _W {M y; var _z;}
      class X extends _W {}
      class M{}''');
    addTestSource('''
      import "/testB.dart";
      foo(X x) {x.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('y', 'M');
      assertNotSuggested('_z');
    });
  }

  test_PrefixedIdentifier_setter() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
      class A {set b(X x) {} set _c(X x) {}}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestSetter('b');
      assertSuggestSetter('_c');
    });
  }

  test_PrefixedIdentifier_setter_imported() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/testB.dart', '''
      lib B;
      class X {set y(X x) {} set _z(X x) {}}''');
    addTestSource('''
      import "/testB.dart";
      main() {X x; x.^}''');
    return computeFull().then((_) {
      assertSuggestSetter('y');
      assertNotSuggested('_z');
    });
  }

  xtest_ConstructorName() {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/testB.dart', '''
      lib B;
      class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
      import "/testB.dart";
      main() {new X.^}''');
    return computeFull().then((_) {
      assertSuggest(CompletionSuggestionKind.CONSTRUCTOR, 'c');
      assertNotSuggested('_d');
      assertNotSuggested('z');
    });
  }
}
