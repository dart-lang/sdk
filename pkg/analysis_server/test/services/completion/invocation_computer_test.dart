// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;


import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import '../../reflective_tests.dart';
import 'package:unittest/unittest.dart';

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

  test_field() {
    addTestSource('class A {var b; var _c;} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestField('b');
      assertSuggestField('_c');
    });
  }

  test_field_imported() {
    addSource('/testB.dart', 'lib B; class X {var y; var _z;}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestField('y');
      assertNotSuggested('_z');
    });
  }

  test_field_superclass() {
    addTestSource(
        'class A {var b; var _c;} class B extends A {} main() {B b; b.^}');
    return computeFull().then((_) {
      assertSuggestField('b');
      assertSuggestField('_c');
    });
  }

  test_getter() {
    addTestSource(
        'class A {A get b => new A();A get _c => new A();} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestGetter('b');
      assertSuggestGetter('_c');
    });
  }

  test_getter_imported() {
    addSource(
        '/testB.dart',
        'lib B; class X {X get y => new X(); X get _z => new X();}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestGetter('y');
      assertNotSuggested('_z');
    });
  }

  test_getter_interface() {
    addTestSource(
        '''class A {A get b => new A();A get _c => new A();}
           class B implements A {A get b => new A();}
           main() {B b; b.^}''');
    return computeFull().then((_) {
      assertSuggestGetter('b');
      assertSuggestGetter('_c');
    });
  }

  test_library_prefix() {
    addSource('/testB.dart', 'lib B; class X { }');
    addTestSource('import "/testB.dart" as b; main() {b.^}');
    return computeFull().then((_) {
      assertSuggestClass('X');
    });
  }

  test_method() {
    addTestSource('class A {b(X x) {} _c(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestMethod('b');
      assertSuggestMethod('_c');
    });
  }

  test_method_imported() {
    addSource('/testB.dart', 'lib B; class X {y(X x) {} _z(X x) {}}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestMethod('y');
      assertNotSuggested('_z');
    });
  }

  test_method_imported_mixin() {
    addSource('/testB.dart', 'lib B; class X {y(X x) {} _z(X x) {}}');
    addTestSource('''import "/testB.dart";
      class A extends Object with X {}
      main() {A a; a.^}''');
    return computeFull().then((_) {
      assertSuggestMethod('y');
      assertNotSuggested('_z');
    });
  }

  test_setter() {
    addTestSource('class A {set b(X x) {} set _c(X x) {}} main() {A a; a.^}');
    return computeFull().then((_) {
      assertSuggestSetter('b');
      assertSuggestSetter('_c');
    });
  }

  test_setter_imported() {
    addSource('/testB.dart', 'lib B; class X {set y(X x) {} set _z(X x) {}}');
    addTestSource('import "/testB.dart"; main() {X x; x.^}');
    return computeFull().then((_) {
      assertSuggestSetter('y');
      assertNotSuggested('_z');
    });
  }
}
