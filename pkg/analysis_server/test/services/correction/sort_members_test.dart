// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
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
  test_classMembers_accessor() async {
    await _parseTestUnit(r'''
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

  test_classMembers_accessor_static() async {
    await _parseTestUnit(r'''
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

  test_classMembers_constructor() async {
    await _parseTestUnit(r'''
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

  test_classMembers_external_constructorMethod() async {
    await _parseTestUnit(r'''
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

  test_classMembers_field() async {
    await _parseTestUnit(r'''
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

  test_classMembers_field_static() async {
    await _parseTestUnit(r'''
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

  test_classMembers_method() async {
    await _parseTestUnit(r'''
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

  test_classMembers_method_emptyLine() async {
    await _parseTestUnit(r'''
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

  test_classMembers_method_ignoreCase() async {
    await _parseTestUnit(r'''
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

  test_classMembers_method_static() async {
    await _parseTestUnit(r'''
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

  test_classMembers_mix() async {
    await _parseTestUnit(r'''
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

  test_directives() async {
    await _parseTestUnit(r'''
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

  test_directives_docComment_hasLibrary_lines() async {
    await _parseTestUnit(r'''
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

  test_directives_docComment_hasLibrary_stars() async {
    await _parseTestUnit(r'''
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

  test_directives_docComment_noLibrary_lines() async {
    await _parseTestUnit(r'''
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

  test_directives_docComment_noLibrary_stars() async {
    await _parseTestUnit(r'''
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

  test_directives_imports_packageAndPath() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_class() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_class_ignoreCase() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_classTypeAlias() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_directive_hasDirective() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_directive_noDirective_hasComment_line() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_directive_noDirective_noComment() async {
    await _parseTestUnit(r'''

class B {}

class A {}
''');
    // validate change
    _assertSort(r'''

class A {}

class B {}
''');
  }

  test_unitMembers_enum() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_enumClass() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_function() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_functionTypeAlias() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_importsAndDeclarations() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_mainFirst() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_mix() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_topLevelVariable() async {
    await _parseTestUnit(r'''
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

  test_unitMembers_topLevelVariable_withConst() async {
    await _parseTestUnit(r'''
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

  Future<Null> _parseTestUnit(String code) async {
    addTestSource(code);
    ParseResult result = await driver.parseFile(testSource.fullName);
    testUnit = result.unit;
  }
}
