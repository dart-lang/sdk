// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.static_member;

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/static_member_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticMemberContributorTest);
    defineReflectiveTests(StaticMemberContributorTest_Driver);
  });
}

@reflectiveTest
class StaticMemberContributorTest extends DartCompletionContributorTest {
  @override
  DartCompletionContributor createContributor() {
    return new StaticMemberContributor();
  }

  fail_enumConst_deprecated() async {
    addTestSource('@deprecated enum E { one, two } main() {E.^}');
    await computeSuggestions();
    assertNotSuggested('E');
    // TODO(danrubel) Investigate why enum suggestion is not marked
    // as deprecated if enum ast element is deprecated
    assertSuggestEnumConst('one', isDeprecated: true);
    assertSuggestEnumConst('two', isDeprecated: true);
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>', isDeprecated: true);
  }

  test_enumConst() async {
    addTestSource('enum E { one, two } main() {E.^}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertSuggestEnumConst('one');
    assertSuggestEnumConst('two');
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>');
  }

  test_enumConst2() async {
    addTestSource('enum E { one, two } main() {E.o^}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertSuggestEnumConst('one');
    assertSuggestEnumConst('two');
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>');
  }

  test_enumConst3() async {
    addTestSource('enum E { one, two } main() {E.^ int g;}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertSuggestEnumConst('one');
    assertSuggestEnumConst('two');
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>');
  }

  test_enumConst_cascade1() async {
    addTestSource('enum E { one, two } main() {E..^}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_enumConst_cascade2() async {
    addTestSource('enum E { one, two } main() {E.^.}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertSuggestEnumConst('one');
    assertSuggestEnumConst('two');
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>');
  }

  test_enumConst_cascade3() async {
    addTestSource('enum E { one, two } main() {E..o^}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_enumConst_cascade4() async {
    addTestSource('enum E { one, two } main() {E.^.o}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertSuggestEnumConst('one');
    assertSuggestEnumConst('two');
    assertNotSuggested('index');
    assertSuggestField('values', 'List<E>');
  }

  test_keyword() async {
    addTestSource('class C { static C get instance => null; } main() {C.in^}');
    await computeSuggestions();
    assertSuggestGetter('instance', 'C');
  }

  test_only_static() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^}''');
    await computeSuggestions();
    assertNotSuggested('b1');
    assertNotSuggested('f1');
    assertSuggestField('f2', 'int');
    assertNotSuggested('m1');
    assertSuggestMethod('m2', 'C', null);
  }

  test_only_static2() async {
    // SimpleIdentifier  MethodInvocation  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^ print("something");}''');
    await computeSuggestions();
    assertNotSuggested('b1');
    assertNotSuggested('f1');
    assertSuggestField('f2', 'int');
    assertNotSuggested('m1');
    assertSuggestMethod('m2', 'C', null);
  }

  test_only_static_cascade1() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C..^}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_only_static_cascade2() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^.}''');
    await computeSuggestions();
    assertNotSuggested('b1');
    assertNotSuggested('f1');
    assertSuggestField('f2', 'int');
    assertNotSuggested('m1');
    assertSuggestMethod('m2', 'C', null);
  }

  test_only_static_cascade3() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C..m^()}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_only_static_cascade4() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
class B {
  static int b1;
}
class C extends B {
  int f1;
  static int f2;
  m1() {}
  static m2() {}
}
void main() {C.^.m()}''');
    await computeSuggestions();
    assertNotSuggested('b1');
    assertNotSuggested('f1');
    assertSuggestField('f2', 'int');
    assertNotSuggested('m1');
    assertSuggestMethod('m2', 'C', null);
  }

  test_only_static_cascade_prefixed1() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
import "dart:async" as async;
void main() {async.Future..w^()}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  test_only_static_cascade_prefixed2() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
import "dart:async" as async;
void main() {async.Future.^.w()}''');
    await computeSuggestions();
    assertSuggestMethod('wait', 'Future', 'Future<dynamic>');
  }

  test_PrefixedIdentifier_class_const() async {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addSource(
        '/testB.dart',
        '''
        lib B;
        class I {
          static const scI = 'boo';
          X get f => new A();
          get _g => new A();}
        class B implements I {
          static const int scB = 12;
          var b; X _c;
          X get d => new A();get _e => new A();
          set s1(I x) {} set _s2(I x) {}
          m(X x) {} I _n(X x) {}}
        class X{}''');
    addTestSource('''
        import "/testB.dart";
        class A extends B {
          static const String scA = 'foo';
          w() { }}
        main() {A.^}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('scA', 'String');
    assertNotSuggested('scB');
    assertNotSuggested('scI');
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('w');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }
}

@reflectiveTest
class StaticMemberContributorTest_Driver extends StaticMemberContributorTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
