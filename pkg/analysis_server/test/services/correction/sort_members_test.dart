// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.sort_members;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersTest);
  });
}

@reflectiveTest
class SortMembersTest extends AbstractSingleUnitTest {
  void test_classMembers_accessor() {
    _parseTestUnit(r'''
class A {
  set c(x) {}
  set a(x) {}
  get a => null;
  get b => null;
  set b(x) {}
  get c => null;
}
''');
    // validate change
    _assertSort(r'''
class A {
  get a => null;
  set a(x) {}
  get b => null;
  set b(x) {}
  get c => null;
  set c(x) {}
}
''');
  }

  void test_classMembers_accessor_static() {
    _parseTestUnit(r'''
class A {
  get a => null;
  set a(x) {}
  static get b => null;
  static set b(x) {}
}
''');
    // validate change
    _assertSort(r'''
class A {
  static get b => null;
  static set b(x) {}
  get a => null;
  set a(x) {}
}
''');
  }

  void test_classMembers_constructor() {
    _parseTestUnit(r'''
class A {
  A.c() {   }
  A.a() { }
  A() {}
  A.b();
}
''');
    // validate change
    _assertSort(r'''
class A {
  A() {}
  A.a() { }
  A.b();
  A.c() {   }
}
''');
  }

  void test_classMembers_external_constructorMethod() {
    _parseTestUnit(r'''
class Chart {
  external Pie();
  external Chart();
}
''');
    // validate change
    _assertSort(r'''
class Chart {
  external Chart();
  external Pie();
}
''');
  }

  void test_classMembers_field() {
    _parseTestUnit(r'''
class A {
  String c;
  int a;
  void toString() => null;
  double b;
}
''');
    // validate change
    _assertSort(r'''
class A {
  String c;
  int a;
  double b;
  void toString() => null;
}
''');
  }

  void test_classMembers_field_static() {
    _parseTestUnit(r'''
class A {
  int b;
  int a;
  static int d;
  static int c;
}
''');
    // validate change
    _assertSort(r'''
class A {
  static int d;
  static int c;
  int b;
  int a;
}
''');
  }

  void test_classMembers_method() {
    _parseTestUnit(r'''
class A {
  c() {}
  a() {}
  b() {}
}
''');
    // validate change
    _assertSort(r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  void test_classMembers_method_emptyLine() {
    _parseTestUnit(r'''
class A {
  b() {}

  a() {}
}
''');
    // validate change
    _assertSort(r'''
class A {
  a() {}

  b() {}
}
''');
  }

  void test_classMembers_method_ignoreCase() {
    _parseTestUnit(r'''
class A {
  m_C() {}
  m_a() {}
  m_B() {}
}
''');
    // validate change
    _assertSort(r'''
class A {
  m_a() {}
  m_B() {}
  m_C() {}
}
''');
  }

  void test_classMembers_method_static() {
    _parseTestUnit(r'''
class A {
  static a() {}
  b() {}
}
''');
    // validate change
    _assertSort(r'''
class A {
  b() {}
  static a() {}
}
''');
  }

  void test_classMembers_mix() {
    _parseTestUnit(r'''
class A {
  /// static field public
  static int nnn;
  /// static field private
  static int _nnn;
  /// instance getter public
  int get nnn => null;
  /// instance setter public
  set nnn(x) {}
  /// instance getter private
  int get _nnn => null;
  /// instance setter private
  set _nnn(x) {}
  /// instance method public
  nnn() {}
  /// instance method private
  _nnn() {}
  /// static method public
  static nnn() {}
  /// static method private
  static _nnn() {}
  /// static getter public
  static int get nnn => null;
  /// static setter public
  static set nnn(x) {}
  /// static getter private
  static int get _nnn => null;
  /// static setter private
  static set _nnn(x) {}
  /// instance field public
  int nnn;
  /// instance field private
  int _nnn;
  /// constructor generative unnamed
  A();
  /// constructor factory unnamed
  factory A() => null;
  /// constructor generative public
  A.nnn();
  /// constructor factory public
  factory A.ooo() => null;
  /// constructor generative private
  A._nnn();
  /// constructor factory private
  factory A._ooo() => null;
}
''');
    // validate change
    _assertSort(r'''
class A {
  /// static field public
  static int nnn;
  /// static field private
  static int _nnn;
  /// static getter public
  static int get nnn => null;
  /// static setter public
  static set nnn(x) {}
  /// static getter private
  static int get _nnn => null;
  /// static setter private
  static set _nnn(x) {}
  /// instance field public
  int nnn;
  /// instance field private
  int _nnn;
  /// constructor generative unnamed
  A();
  /// constructor factory unnamed
  factory A() => null;
  /// constructor generative public
  A.nnn();
  /// constructor factory public
  factory A.ooo() => null;
  /// constructor generative private
  A._nnn();
  /// constructor factory private
  factory A._ooo() => null;
  /// instance getter public
  int get nnn => null;
  /// instance setter public
  set nnn(x) {}
  /// instance getter private
  int get _nnn => null;
  /// instance setter private
  set _nnn(x) {}
  /// instance method public
  nnn() {}
  /// instance method private
  _nnn() {}
  /// static method public
  static nnn() {}
  /// static method private
  static _nnn() {}
}
''');
  }

  void test_directives() {
    _parseTestUnit(r'''
library lib;

export 'dart:bbb';
import 'dart:bbb';
export 'package:bbb/bbb.dart';
export 'http://bbb.com';
import 'bbb/bbb.dart';
export 'http://aaa.com';
import 'http://bbb.com';
export 'dart:aaa';
export 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
export 'aaa/aaa.dart';
export 'bbb/bbb.dart';
import 'dart:aaa';
import 'package:aaa/aaa.dart';
import 'aaa/aaa.dart';
import 'http://aaa.com';
part 'bbb/bbb.dart';
part 'aaa/aaa.dart';

main() {
}
''');
    // validate change
    _assertSort(r'''
library lib;

import 'dart:aaa';
import 'dart:bbb';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';

import 'http://aaa.com';
import 'http://bbb.com';

import 'aaa/aaa.dart';
import 'bbb/bbb.dart';

export 'dart:aaa';
export 'dart:bbb';

export 'package:aaa/aaa.dart';
export 'package:bbb/bbb.dart';

export 'http://aaa.com';
export 'http://bbb.com';

export 'aaa/aaa.dart';
export 'bbb/bbb.dart';

part 'aaa/aaa.dart';
part 'bbb/bbb.dart';

main() {
}
''');
  }

  void test_directives_docComment_hasLibrary_lines() {
    _parseTestUnit(r'''
/// Library documentation comment A.
/// Library documentation comment B.
library foo.bar;

/// bbb1
/// bbb2
/// bbb3
import 'b.dart';
/// aaa1
/// aaa2
import 'a.dart';
''');
    // validate change
    _assertSort(r'''
/// Library documentation comment A.
/// Library documentation comment B.
library foo.bar;

/// aaa1
/// aaa2
import 'a.dart';
/// bbb1
/// bbb2
/// bbb3
import 'b.dart';
''');
  }

  void test_directives_docComment_hasLibrary_stars() {
    _parseTestUnit(r'''
/**
 * Library documentation comment A.
 * Library documentation comment B.
 */
library foo.bar;

/**
 * bbb
 */
import 'b.dart';
/**
 * aaa
 * aaa
 */
import 'a.dart';
''');
    // validate change
    _assertSort(r'''
/**
 * Library documentation comment A.
 * Library documentation comment B.
 */
library foo.bar;

/**
 * aaa
 * aaa
 */
import 'a.dart';
/**
 * bbb
 */
import 'b.dart';
''');
  }

  void test_directives_docComment_noLibrary_lines() {
    _parseTestUnit(r'''
/// Library documentation comment A
/// Library documentation comment B
import 'b.dart';
/// aaa1
/// aaa2
import 'a.dart';
''');
    // validate change
    _assertSort(r'''
/// aaa1
/// aaa2
/// Library documentation comment A
/// Library documentation comment B
import 'a.dart';
import 'b.dart';
''');
  }

  void test_directives_docComment_noLibrary_stars() {
    _parseTestUnit(r'''
/**
 * Library documentation comment A.
 * Library documentation comment B.
 */
import 'b.dart';
/**
 * aaa
 * aaa
 */
import 'a.dart';
''');
    // validate change
    _assertSort(r'''
/**
 * aaa
 * aaa
 */
/**
 * Library documentation comment A.
 * Library documentation comment B.
 */
import 'a.dart';
import 'b.dart';
''');
  }

  void test_directives_imports_packageAndPath() {
    _parseTestUnit(r'''
library lib;

import 'package:product.ui.api.bbb/manager1.dart';
import 'package:product.ui.api/entity2.dart';
import 'package:product.ui/entity.dart';
import 'package:product.ui.api.aaa/manager2.dart';
import 'package:product.ui.api/entity1.dart';
import 'package:product2.client/entity.dart';
''');
    // validate change
    _assertSort(r'''
library lib;

import 'package:product.ui/entity.dart';
import 'package:product.ui.api/entity1.dart';
import 'package:product.ui.api/entity2.dart';
import 'package:product.ui.api.aaa/manager2.dart';
import 'package:product.ui.api.bbb/manager1.dart';
import 'package:product2.client/entity.dart';
''');
  }

  void test_unitMembers_class() {
    _parseTestUnit(r'''
class C {}
class A {}
class B {}
''');
    // validate change
    _assertSort(r'''
class A {}
class B {}
class C {}
''');
  }

  void test_unitMembers_class_ignoreCase() {
    _parseTestUnit(r'''
class C {}
class a {}
class B {}
''');
    // validate change
    _assertSort(r'''
class a {}
class B {}
class C {}
''');
  }

  void test_unitMembers_classTypeAlias() {
    _parseTestUnit(r'''
class M {}
class C = Object with M;
class A = Object with M;
class B = Object with M;
''');
    // validate change
    _assertSort(r'''
class A = Object with M;
class B = Object with M;
class C = Object with M;
class M {}
''');
  }

  void test_unitMembers_directive_hasDirective() {
    _parseTestUnit(r'''
library lib;
class C {}
class A {}
class B {}
''');
    // validate change
    _assertSort(r'''
library lib;
class A {}
class B {}
class C {}
''');
  }

  void test_unitMembers_directive_noDirective_hasComment_line() {
    _parseTestUnit(r'''
// Some comment

class B {}

class A {}
''');
    // validate change
    _assertSort(r'''
// Some comment

class A {}

class B {}
''');
  }

  void test_unitMembers_directive_noDirective_noComment() {
    _parseTestUnit(r'''

class B {}

class A {}
''');
    // validate change
    _assertSort(r'''

class A {}

class B {}
''');
  }

  void test_unitMembers_enum() {
    _parseTestUnit(r'''
enum C {x, y}
enum A {x, y}
enum B {x, y}
''');
    // validate change
    _assertSort(r'''
enum A {x, y}
enum B {x, y}
enum C {x, y}
''');
  }

  void test_unitMembers_enumClass() {
    _parseTestUnit(r'''
enum C {x, y}
class A {}
class D {}
enum B {x, y}
''');
    // validate change
    _assertSort(r'''
class A {}
enum B {x, y}
enum C {x, y}
class D {}
''');
  }

  void test_unitMembers_function() {
    _parseTestUnit(r'''
fc() {}
fa() {}
fb() {}
''');
    // validate change
    _assertSort(r'''
fa() {}
fb() {}
fc() {}
''');
  }

  void test_unitMembers_functionTypeAlias() {
    _parseTestUnit(r'''
typedef FC();
typedef FA();
typedef FB();
''');
    // validate change
    _assertSort(r'''
typedef FA();
typedef FB();
typedef FC();
''');
  }

  void test_unitMembers_importsAndDeclarations() {
    _parseTestUnit(r'''
import 'dart:a';
import 'package:b';

foo() {
}

f() => null;
''');
    // validate change
    _assertSort(r'''
import 'dart:a';

import 'package:b';

f() => null;

foo() {
}
''');
  }

  void test_unitMembers_mainFirst() {
    _parseTestUnit(r'''
class C {}
aaa() {}
get bbb() {}
class A {}
main() {}
class B {}
''');
    // validate change
    _assertSort(r'''
main() {}
get bbb() {}
aaa() {}
class A {}
class B {}
class C {}
''');
  }

  void test_unitMembers_mix() {
    _parseTestUnit(r'''
_mmm() {}
typedef nnn();
_nnn() {}
typedef mmm();
typedef _nnn();
typedef _mmm();
class mmm {}
get _nnn => null;
class nnn {}
class _mmm {}
class _nnn {}
var mmm;
var nnn;
var _mmm;
var _nnn;
set nnn(x) {}
get mmm => null;
set mmm(x) {}
get nnn => null;
get _mmm => null;
set _mmm(x) {}
set _nnn(x) {}
mmm() {}
nnn() {}
''');
    // validate change
    _assertSort(r'''
var mmm;
var nnn;
var _mmm;
var _nnn;
get mmm => null;
set mmm(x) {}
get nnn => null;
set nnn(x) {}
get _mmm => null;
set _mmm(x) {}
get _nnn => null;
set _nnn(x) {}
mmm() {}
nnn() {}
_mmm() {}
_nnn() {}
typedef mmm();
typedef nnn();
typedef _mmm();
typedef _nnn();
class mmm {}
class nnn {}
class _mmm {}
class _nnn {}
''');
  }

  void test_unitMembers_topLevelVariable() {
    _parseTestUnit(r'''
int c;
int a;
int b;
''');
    // validate change
    _assertSort(r'''
int a;
int b;
int c;
''');
  }

  void test_unitMembers_topLevelVariable_withConst() {
    _parseTestUnit(r'''
int c;
int a;
const B = 2;
int b;
const A = 1;
''');
    // validate change
    _assertSort(r'''
const A = 1;
const B = 2;
int a;
int b;
int c;
''');
  }

  void _assertSort(String expectedCode) {
    MemberSorter sorter = new MemberSorter(testCode, testUnit);
    List<SourceEdit> edits = sorter.sort();
    String result = SourceEdit.applySequence(testCode, edits);
    expect(result, expectedCode);
  }

  void _parseTestUnit(String code) {
    addTestSource(code);
    testUnit = context.parseCompilationUnit(testSource);
  }
}
