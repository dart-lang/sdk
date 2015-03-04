// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(InvocationComputerTest);
}

@reflectiveTest
class InvocationComputerTest extends AbstractSelectorSuggestionTest {
  @override
  CompletionSuggestion assertSuggestInvocationField(String name, String type,
      {int relevance: DART_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    return assertSuggestField(name, type,
        relevance: relevance, isDeprecated: isDeprecated);
  }

  /**
   * Check whether a declaration of the form [shadower] in a derived class
   * shadows a declaration of the form [shadowee] in a base class, for the
   * purposes of what is shown during completion.  [shouldBeShadowed] indicates
   * whether shadowing is expected.
   */
  Future check_shadowing(
      String shadower, String shadowee, bool shouldBeShadowed) {
    addTestSource('''
class Base {
  $shadowee
}
class Derived extends Base {
  $shadower
}
void f(Derived d) {
  d.^
}
''');
    return computeFull((bool result) {
      List<CompletionSuggestion> suggestionsForX = request.suggestions
          .where((CompletionSuggestion s) => s.completion == 'x')
          .toList();
      if (shouldBeShadowed) {
        expect(suggestionsForX, hasLength(1));
        expect(suggestionsForX[0].declaringType, 'Derived');
      } else {
        expect(suggestionsForX, hasLength(2));
      }
    });
  }

  fail_test_PrefixedIdentifier_trailingStmt_const_untyped() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('const g = "hello"; f() {g.^ int y = 0;}');
    computeFast();
    return computeFull((bool result) {
      assertSuggestInvocationGetter('length', 'int');
    });
  }

  @override
  void setUpComputer() {
    computer = new InvocationComputer();
  }

  test_generic_field() {
    addTestSource('''
class C<T> {
  T t;
}
void f(C<int> c) {
  c.^
}
''');
    return computeFull((bool result) {
      assertSuggestField('t', 'int');
    });
  }

  test_generic_getter() {
    addTestSource('''
class C<T> {
  T get t => null;
}
void f(C<int> c) {
  c.^
}
''');
    return computeFull((bool result) {
      assertSuggestGetter('t', 'int');
    });
  }

  test_generic_method() {
    addTestSource('''
class C<T> {
  T m(T t) {}
}
void f(C<int> c) {
  c.^
}
''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'int');
      expect(suggestion.parameterTypes[0], 'int');
      expect(suggestion.element.returnType, 'int');
      expect(suggestion.element.parameters, '(int t)');
    });
  }

  test_generic_setter() {
    addTestSource('''
class C<T> {
  set t(T value) {}
}
void f(C<int> c) {
  c.^
}
''');
    return computeFull((bool result) {
      // TODO(paulberry): modify assertSuggestSetter so that we can pass 'int'
      // as a parmeter to it, and it will check the appropriate field in
      // the suggestion object.
      CompletionSuggestion suggestion = assertSuggestSetter('t');
      expect(suggestion.element.parameters, '(int value)');
    });
  }

  test_local() {
    addTestSource('foo() {String x = "bar"; x.^}');
    return computeFull((bool result) {
      assertSuggestGetter('length', 'int');
    });
  }

  test_local_is() {
    addTestSource('foo() {var x; if (x is String) x.^}');
    return computeFull((bool result) {
      assertSuggestGetter('length', 'int');
    });
  }

  test_local_propogatedType() {
    addTestSource('foo() {var x = "bar"; x.^}');
    return computeFull((bool result) {
      assertSuggestGetter('length', 'int');
    });
  }

  test_method_parameters_mixed_required_and_named() {
    addTestSource('''
class C {
  void m(x, {int y}) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_mixed_required_and_positional() {
    addTestSource('''
class C {
  void m(x, [int y]) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_named() {
    addTestSource('''
class C {
  void m({x, int y}) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_none() {
    addTestSource('''
class C {
  void m() {}
}
void main() {new C().^}''');
    computeFast();
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, isEmpty);
      expect(suggestion.parameterTypes, isEmpty);
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_positional() {
    addTestSource('''
class C {
  void m([x, int y]) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_required() {
    addTestSource('''
class C {
  void m(x, int y) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 2);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_no_parameters_field() {
    addTestSource('''
class C {
  int x;
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestField('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_getter() {
    addTestSource('''
class C {
  int get x => null;
}
void main() {int y = new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestGetter('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_setter() {
    addTestSource('''
class C {
  set x(int value) {};
}
void main() {int y = new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestSetter('x');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_only_instance() {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addTestSource('''
class C {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      assertSuggestInvocationField('f1', 'int');
      assertNotSuggested('f2');
      assertSuggestMethod('m1', 'C', null);
      assertNotSuggested('m2');
    });
  }

  test_only_instance2() {
    // SimpleIdentifier  MethodInvocation  ExpressionStatement
    addTestSource('''
class C {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {new C().^ print("something");}''');
    return computeFull((bool result) {
      assertSuggestInvocationField('f1', 'int');
      assertNotSuggested('f2');
      assertSuggestMethod('m1', 'C', null);
      assertNotSuggested('m2');
    });
  }

  test_only_static() {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class C {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^}''');
    return computeFull((bool result) {
      assertNotSuggested('f1');
      assertSuggestInvocationField('f2', 'int');
      assertNotSuggested('m1');
      assertSuggestMethod('m2', 'C', null);
    });
  }

  test_only_static2() {
    // SimpleIdentifier  MethodInvocation  ExpressionStatement
    addTestSource('''
class C {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^ print("something");}''');
    return computeFull((bool result) {
      assertNotSuggested('f1');
      assertSuggestInvocationField('f2', 'int');
      assertNotSuggested('m1');
      assertSuggestMethod('m2', 'C', null);
    });
  }

  test_param() {
    addTestSource('foo(String x) {x.^}');
    return computeFull((bool result) {
      assertSuggestGetter('length', 'int');
    });
  }

  test_param_is() {
    addTestSource('foo(x) {if (x is String) x.^}');
    return computeFull((bool result) {
      assertSuggestGetter('length', 'int');
    });
  }

  test_shadowing_field_over_field() =>
      check_shadowing('int x;', 'int x;', true);

  test_shadowing_field_over_getter() =>
      check_shadowing('int x;', 'int get x => null;', true);

  test_shadowing_field_over_method() =>
      check_shadowing('int x;', 'void x() {}', true);

  test_shadowing_field_over_setter() =>
      check_shadowing('int x;', 'set x(int value) {}', true);

  test_shadowing_getter_over_field() =>
      check_shadowing('int get x => null;', 'int x;', false);

  test_shadowing_getter_over_getter() =>
      check_shadowing('int get x => null;', 'int get x => null;', true);

  test_shadowing_getter_over_method() =>
      check_shadowing('int get x => null;', 'void x() {}', true);

  test_shadowing_getter_over_setter() =>
      check_shadowing('int get x => null;', 'set x(int value) {}', false);

  test_shadowing_method_over_field() =>
      check_shadowing('void x() {}', 'int x;', true);

  test_shadowing_method_over_getter() =>
      check_shadowing('void x() {}', 'int get x => null;', true);

  test_shadowing_method_over_method() =>
      check_shadowing('void x() {}', 'void x() {}', true);

  test_shadowing_method_over_setter() =>
      check_shadowing('void x() {}', 'set x(int value) {}', true);

  test_shadowing_mixin_order() {
    addTestSource('''
class Base {
}
class Mixin1 {
  void f() {}
}
class Mixin2 {
  void f() {}
}
class Derived extends Base with Mixin1, Mixin2 {
}
void test(Derived d) {
  d.^
}
''');
    return computeFull((bool result) {
      // Note: due to dartbug.com/22069, analyzer currently analyzes mixins in
      // reverse order.  The correct order is that Derived inherits from
      // "Base with Mixin1, Mixin2", which inherits from "Base with Mixin1",
      // which inherits from "Base".  So the definition of f in Mixin2 should
      // shadow the definition in Mixin1.
      assertSuggestMethod('f', 'Mixin2', 'void');
    });
  }

  test_shadowing_mixin_over_superclass() {
    addTestSource('''
class Base {
  void f() {}
}
class Mixin {
  void f() {}
}
class Derived extends Base with Mixin {
}
void test(Derived d) {
  d.^
}
''');
    return computeFull((bool result) {
      assertSuggestMethod('f', 'Mixin', 'void');
    });
  }

  test_shadowing_setter_over_field() =>
      check_shadowing('set x(int value) {}', 'int x;', false);

  test_shadowing_setter_over_getter() =>
      check_shadowing('set x(int value) {}', 'int get x => null;', false);

  test_shadowing_setter_over_method() =>
      check_shadowing('set x(int value) {}', 'void x() {}', true);

  test_shadowing_setter_over_setter() =>
      check_shadowing('set x(int value) {}', 'set x(int value) {}', true);

  test_shadowing_superclass_over_interface() {
    addTestSource('''
class Base {
  void f() {}
}
class Interface {
  void f() {}
}
class Derived extends Base implements Interface {
}
void test(Derived d) {
  d.^
}
''');
    return computeFull((bool result) {
      assertSuggestMethod('f', 'Base', 'void');
    });
  }
}
