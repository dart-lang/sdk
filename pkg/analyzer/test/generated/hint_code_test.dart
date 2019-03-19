// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/util/yaml_test.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HintCodeTest);
  });
}

/// The contents of the 'meta' package. Code that uses this variable should be
/// converted to use PackageMixin.addMetaPackage.
final _metaLibraryStub = r'''
library meta;

const _AlwaysThrows alwaysThrows = const _AlwaysThrows();
const _Factory factory = const _Factory();
const Immutable immutable = const Immutable();
const _Literal literal = const _Literal();
const _MustCallSuper mustCallSuper = const _MustCallSuper();
const _Protected protected = const _Protected();
const Required required = const Required();
const _Sealed sealed = const _Sealed();
const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

class Immutable {
  final String reason;
  const Immutable([this.reason]);
}
class _AlwaysThrows {
  const _AlwaysThrows();
}
class _Factory {
  const _Factory();
}
class _Literal {
  const _Literal();
}
class _MustCallSuper {
  const _MustCallSuper();
}
class _Protected {
  const _Protected();
}
class Required {
  final String reason;
  const Required([this.reason]);
}
class _Sealed {
  const _Sealed();
}
class _VisibleForTesting {
  const _VisibleForTesting();
}
''';

@reflectiveTest
class HintCodeTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  void reset() {
    super.resetWith(packages: [
      ['meta', _metaLibraryStub],
      [
        'js',
        r'''
library js;
class JS {
  const JS([String js]);
}
'''
      ],
      [
        'angular_meta',
        r'''
library angular.meta;

const _VisibleForTemplate visibleForTemplate = const _VisibleForTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}
'''
      ],
    ]);
  }

  test_deprecatedFunction_class() async {
    Source source = addSource(r'''
class Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION]);
    verify([source]);
  }

  test_deprecatedFunction_extends() async {
    Source source = addSource(r'''
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_EXTENDS_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_extends2() async {
    Source source = addSource(r'''
class Function {}
class A extends Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_EXTENDS_FUNCTION
    ]);
    verify([source]);
  }

  test_deprecatedFunction_mixin() async {
    Source source = addSource(r'''
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEPRECATED_MIXIN_FUNCTION]);
    verify([source]);
  }

  test_deprecatedFunction_mixin2() async {
    Source source = addSource(r'''
class Function {}
class A extends Object with Function {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION,
      HintCode.DEPRECATED_MIXIN_FUNCTION
    ]);
    verify([source]);
  }

  test_duplicateImport() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateImport2() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [HintCode.DUPLICATE_IMPORT, HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateImport3() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  test_duplicateShownHiddenName_hidden() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' hide A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_HIDDEN_NAME]);
    verify([source]);
  }

  test_duplicateShownHiddenName_shown() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart' show A, B, A;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DUPLICATE_SHOWN_NAME]);
    verify([source]);
  }

  test_factory__expr_return_null_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => null;
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_abstract_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_bad_return() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  State _s = new State();

  @factory
  State createState() => _s;
}

class State { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_IMPL]);
    verify([source]);
  }

  test_factory_block_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return new State();
  }
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_block_return_null_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() {
    return null;
  }
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_expr_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  State createState() => new State();
}

class State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_misplaced_annotation() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

@factory
class X {
  @factory
  int x;
}

@factory
main() { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION,
      HintCode.INVALID_FACTORY_ANNOTATION
    ]);
    verify([source]);
  }

  test_factory_no_return_type_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  createState() {
    return new Stateful();
  }
}
''');
    // Null return types will get flagged elsewhere, no need to pile-on here.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_subclass_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

abstract class Stateful {
  @factory
  State createState();
}

class MyThing extends Stateful {
  @override
  State createState() {
    print('my state');
    return new MyState();
  }
}

class State { }
class MyState extends State { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_factory_void_return() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class Stateful {
  @factory
  void createState() {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.INVALID_FACTORY_METHOD_DECL]);
    verify([source]);
  }

  test_importDeferredLibraryWithLoadFunction() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
loadLibrary() {}
f() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''
    ], <ErrorCode>[
      HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION
    ]);
  }

  test_invalidUseOfProtectedMember_closure() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int a() => 42;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  var leak = new A().a;
  print(leak);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_field() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

abstract class B {
  int b() => new A().a;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_field_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a;
}
abstract class B implements A {
  int b() => a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_fromSuperclassConstraint() async {
    Source sourceA = addNamedSource('/a.dart', r'''
import 'package:meta/meta.dart';

abstract class A {
  @protected
  void foo() {}
}
''');
    Source sourceM = addNamedSource('/m.dart', r'''
import 'a.dart';

mixin M on A {
  @override
  void foo() {
    super.foo();
  }
}
''');

    await computeAnalysisResult(sourceA);
    await computeAnalysisResult(sourceM);
    assertNoErrors(sourceA);
    assertNoErrors(sourceM);
    verify([sourceA, sourceM]);
  }

  test_invalidUseOfProtectedMember_function() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_function_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a() => 0;
}

abstract class B implements A {
  int b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_function_OK2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
main() {
  new A().a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_getter() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  A a;
  int b() => a.a;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_getter_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
abstract class B implements A {
  int b() => a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_in_docs_OK() async {
    addNamedSource('/a.dart', r'''
import 'package:meta/meta.dart';

class A {
  @protected
  int c = 0;

  @protected
  int get b => 0;

  @protected
  int a() => 0;
}
''');
    Source source = addSource(r'''
import 'a.dart';

/// OK: [A.a], [A.b], [A.c].
f() {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_message() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_method_1() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_method_OK() async {
    // https://github.com/dart-lang/linter/issues/257
    Source source = addSource(r'''
import 'package:meta/meta.dart';

typedef void VoidCallback();

class State<E> {
  @protected
  void setState(VoidCallback fn) {}
}

class Button extends State<Object> {
  void handleSomething() {
    setState(() {});
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_1() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends Object with A {
  void b() => a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_3() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected m1() {}
}
class B extends A {
  static m2(A a) => a.m1();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_4() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void a(){ }
}
class B extends A {
  void a() => a();
}
main() {
  new B().a();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_field() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int a = 42;
}
class B extends A {
  int b() => a;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_getter() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  int get a => 42;
}
class B extends A {
  int b() => a;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_setter() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
class B extends A {
  void b(int i) {
    a = i;
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_OK_setter_2() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  int _a;
  @protected
  void set a(int a) { _a = a; }
  A(int a) {
    this.a = a;
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_setter() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B{
  A a;
  b(int i) {
    a.a = i;
  }
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_PROTECTED_MEMBER]);
    assertNoErrors(source);
    verify([source, source2]);
  }

  test_invalidUseOfProtectedMember_setter_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  @protected
  void set a(int i) { }
}
abstract class B implements A {
  b(int i) {
    a = i;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfProtectedMember_topLevelVariable() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
@protected
int x = 0;
main() {
  print(x);
}''');
    // TODO(brianwilkerson) This should produce a hint because the annotation is
    // being applied to the wrong kind of declaration.
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidUseOfVisibleForTemplateMember_constructor() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A.forTemplate(0);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_export_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
export 'lib1.dart' show fn0;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_method() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_method_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib1.template.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_propertyAccess() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  int get a => 7;

  @visibleForTemplate
  set b(_) => 7;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER,
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER
    ]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTemplateMember_topLevelFunction() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  fn0();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(
        source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_constructor() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A.forTesting(this._x);
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A.forTesting(0);
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_export_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
export 'lib1.dart' show fn0;
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_method() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_method_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/test/test1.dart', r'''
import '../lib1.dart';

class B {
  void b() => new A().a();
}
''');
    Source source3 = addNamedSource('/testing/lib1.dart', r'''
import '../lib1.dart';

class C {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    await computeAnalysisResult(source3);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  test_invalidUseOfVisibleForTestingMember_propertyAccess() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;

  @visibleForTesting
  set b(_) => 7;
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER,
      HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER
    ]);
    verify([source, source2]);
  }

  test_invalidUseOfVisibleForTestingMember_topLevelFunction() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
int fn0() => 1;
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

void main() {
  fn0();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertErrors(source2, [HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER]);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTemplate_asProtected_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTemplate_asTemplate_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib1.template.dart', r'''
import 'lib1.dart';

void main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTesting_asProtected_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/lib2.dart', r'''
import 'lib1.dart';

class B extends A {
  void b() => new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_invalidUseProtectedAndForTesting_asTesting_OK() async {
    Source source = addNamedSource('/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    Source source2 = addNamedSource('/test/test1.dart', r'''
import '../lib1.dart';

void main() {
  new A().a();
}
''');
    await computeAnalysisResult(source);
    await computeAnalysisResult(source2);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  test_isDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isInt() async {
    Source source = addSource("var v = 1 is int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_INT]);
    verify([source]);
  }

  test_isNotDouble() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.dart2jsHint = true;
    resetWith(options: options);
    Source source = addSource("var v = 1 is! double;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_DOUBLE]);
    verify([source]);
  }

  @failingTest
  test_isNotInt() async {
    Source source = addSource("var v = 1 is! int;");
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.IS_NOT_INT]);
    verify([source]);
  }

  test_js_lib_OK() async {
    Source source = addSource(r'''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingJsLibAnnotation_class() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_externalField() async {
    // https://github.com/dart-lang/sdk/issues/26987
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
external dynamic exports;
''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [ParserErrorCode.EXTERNAL_FIELD, HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_function() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

@JS('acxZIndex')
set _currentZIndex(int value) { }
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_method() async {
    Source source = addSource(r'''
library foo;

import 'package:js/js.dart';

class A {
  @JS()
  void a() { }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_missingJsLibAnnotation_variable() async {
    Source source = addSource(r'''
import 'package:js/js.dart';

@JS()
dynamic variable;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_JS_LIB_ANNOTATION]);
    verify([source]);
  }

  test_nullAwareBeforeOperator_minus() async {
    Source source = addSource(r'''
m(x) {
  x?.a - '';
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_BEFORE_OPERATOR]);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_assignment() async {
    Source source = addSource(r'''
m(x) {
  x?.a = '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_equal_equal() async {
    Source source = addSource(r'''
m(x) {
  x?.a == '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_is() async {
    Source source = addSource(r'''
m(x) {
  x?.a is String;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_is_not() async {
    Source source = addSource(r'''
m(x) {
  x?.a is! String;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_not_equal() async {
    Source source = addSource(r'''
m(x) {
  x?.a != '';
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareBeforeOperator_ok_question_question() async {
    Source source = addSource(r'''
m(x) {
  x?.a ?? true;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nullAwareInCondition_assert() async {
    Source source = addSource(r'''
m(x) {
  assert (x?.a);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_conditionalExpression() async {
    Source source = addSource(r'''
m(x) {
  return x?.a ? 0 : 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_do() async {
    Source source = addSource(r'''
m(x) {
  do {} while (x?.a);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_for() async {
    Source source = addSource(r'''
m(x) {
  for (var v = x; v?.a; v = v.next) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_if() async {
    Source source = addSource(r'''
m(x) {
  if (x?.a) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_if_parenthesized() async {
    Source source = addSource(r'''
m(x) {
  if ((x?.a)) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInCondition_while() async {
    Source source = addSource(r'''
m(x) {
  while (x?.a) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_CONDITION]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_first() async {
    Source source = addSource(r'''
m(x) {
  x?.a && x.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_second() async {
    Source source = addSource(r'''
m(x) {
  x.a && x?.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalAnd_third() async {
    Source source = addSource(r'''
m(x) {
  x.a && x.b && x?.c;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_first() async {
    Source source = addSource(r'''
m(x) {
  x?.a || x.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_second() async {
    Source source = addSource(r'''
m(x) {
  x.a || x?.b;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_conditionalOr_third() async {
    Source source = addSource(r'''
m(x) {
  x.a || x.b || x?.c;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  test_nullAwareInLogicalOperator_not() async {
    Source source = addSource(r'''
m(x) {
  !x?.a;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR]);
    verify([source]);
  }

  @failingTest
  test_overrideEqualsButNotHashCode() async {
    Source source = addSource(r'''
class A {
  bool operator ==(x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE]);
    verify([source]);
  }

  test_overrideOnNonOverridingField_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  final int m = 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD]);
    verify([source]);
  }

  test_overrideOnNonOverridingGetter_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  int get m => 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER]);
    verify([source]);
  }

  test_overrideOnNonOverridingMethod_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  int m() => 1;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
    verify([source]);
  }

  test_overrideOnNonOverridingSetter_invalid() async {
    Source source = addSource(r'''
class A {
}
class B extends A {
  @override
  set m(int x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER]);
    verify([source]);
  }

  test_required_constructor_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_constructor_param_no_reason() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_null_reason() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required(null) int a}) {}
}

main() {
  new C();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_OK() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int a}) {}
}

main() {
  new C(a: 2);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_required_constructor_param_redirecting_cons_call() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@required int x});
  C.named() : this();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_required_constructor_param_super_call() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

class C {
  C({@Required('must specify an `a`') int a}) {}
}

class D extends C {
  D() : super();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_function_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

void f({@Required('must specify an `a`') int a}) {}

main() {
  f();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_method_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
f() {
  new A().m();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_method_param_in_other_lib() async {
    addNamedSource('/a_lib.dart', r'''
library a_lib;
import 'package:meta/meta.dart';
class A {
  void m({@Required('must specify an `a`') int a}) {}
}
''');

    Source source = addSource(r'''
import "a_lib.dart";
f() {
  new A().m();
}
''');

    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS]);
    verify([source]);
  }

  test_required_typedef_function_param() async {
    Source source = addSource(r'''
import 'package:meta/meta.dart';

String test(C c) => c.m()();

typedef String F({@required String x});

class C {
  F m() => ({@required String x}) => null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.MISSING_REQUIRED_PARAM]);
    verify([source]);
  }

  test_strongMode_downCastCompositeHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = true;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }

  test_strongMode_downCastCompositeNoHint() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_strongMode_downCastCompositeWarn() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    applyToAnalysisOptions(
        options,
        wrap({
          AnalyzerOptions.analyzer: {
            AnalyzerOptions.errors: {
              StrongModeCode.DOWN_CAST_COMPOSITE.name: 'warning'
            },
          }
        }));
    options.strongModeHints = false;
    resetWith(options: options);
    Source source = addSource(r'''
main() {
  List dynamicList = [ ];
  List<int> list = dynamicList;
  print(list);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StrongModeCode.DOWN_CAST_COMPOSITE]);
    verify([source]);
  }
}
