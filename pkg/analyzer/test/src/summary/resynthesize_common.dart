// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/element_type_matchers.dart';
import 'element_text.dart';
import 'test_strategies.dart';

/**
 * Abstract base class for resynthesizing and comparing elements.
 *
 * The return type separator: →
 */
abstract class AbstractResynthesizeTest with ResourceProviderMixin {
  DeclaredVariables declaredVariables = new DeclaredVariables();
  SourceFactory sourceFactory;
  MockSdk sdk;

  String testFile;
  Source testSource;
  Set<Source> otherLibrarySources = new Set<Source>();

  /**
   * Tests may set this to `true` to indicate that a missing file at the time of
   * summary resynthesis shouldn't trigger an error.
   */
  bool allowMissingFiles = false;

  AbstractResynthesizeTest() {
    sdk = new MockSdk(resourceProvider: resourceProvider);

    sourceFactory = SourceFactory(
      [
        DartUriResolver(sdk),
        ResourceUriResolver(resourceProvider),
      ],
      null,
      resourceProvider,
    );

    testFile = convertPath('/test.dart');
  }

  void addLibrary(String uri) {
    var source = sourceFactory.forUri(uri);
    otherLibrarySources.add(source);
  }

  Source addLibrarySource(String filePath, String contents) {
    var source = addSource(filePath, contents);
    otherLibrarySources.add(source);
    return source;
  }

  Source addSource(String path, String contents) {
    var file = newFile(path, content: contents);
    var source = file.createSource();
    return source;
  }

  Source addTestSource(String code, [Uri uri]) {
    testSource = addSource(testFile, code);
    return testSource;
  }

  /**
   * Verify that the [resynthesizer] didn't do any unnecessary work when
   * resynthesizing the library with the [expectedLibraryUri].
   */
  void checkMinimalResynthesisWork(TestSummaryResynthesizer resynthesizer,
      Uri expectedLibraryUri, List<Uri> expectedUnitUriList) {
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 3);
    // Check that the only linked summary consulted was that for [uri].
    expect(resynthesizer.linkedSummariesRequested, hasLength(1));
    expect(resynthesizer.linkedSummariesRequested.first,
        expectedLibraryUri.toString());
    // Check that the only unlinked summaries consulted were those for the
    // library in question.
    var expectedUnitUriStrSet =
        expectedUnitUriList.map((uri) => uri.toString()).toSet();
    for (String requestedUri in resynthesizer.unlinkedSummariesRequested) {
      expect(expectedUnitUriStrSet, contains(requestedUri));
    }
  }
}

/// Mixin containing test cases exercising summary resynthesis.  Intended to be
/// applied to a class implementing [ResynthesizeTestStrategy], along with the
/// mixin [ResynthesizeTestHelpers].
mixin GetElementTestCases implements ResynthesizeTestHelpers {
  test_getElement_class() async {
    var resynthesized = _validateGetElement(
      'class C { m() {} }',
      ['C'],
    );
    expect(resynthesized, isClassElement);
  }

  test_getElement_constructor_named() async {
    var resynthesized = _validateGetElement(
      'class C { C.named(); }',
      ['C', 'named'],
    );
    expect(resynthesized, isConstructorElement);
  }

  test_getElement_constructor_unnamed() async {
    var resynthesized = _validateGetElement(
      'class C { C(); }',
      ['C', ''],
    );
    expect(resynthesized, isConstructorElement);
  }

  test_getElement_field() async {
    var resynthesized = _validateGetElement(
      'class C { var f; }',
      ['C', 'f'],
    );
    expect(resynthesized, isFieldElement);
  }

  test_getElement_getter() async {
    var resynthesized = _validateGetElement(
      'class C { get f => null; }',
      ['C', 'f?'],
    );
    expect(resynthesized, isPropertyAccessorElement);
  }

  test_getElement_method() async {
    var resynthesized = _validateGetElement(
      'class C { m() {} }',
      ['C', 'm'],
    );
    expect(resynthesized, isMethodElement);
  }

  test_getElement_operator() async {
    var resynthesized = _validateGetElement(
      'class C { operator+(x) => null; }',
      ['C', '+'],
    );
    expect(resynthesized, isMethodElement);
  }

  test_getElement_setter() async {
    var resynthesized = _validateGetElement(
      'class C { void set f(value) {} }',
      ['C', 'f='],
    );
    expect(resynthesized, isPropertyAccessorElement);
  }

  test_getElement_unit() async {
    var resynthesized = _validateGetElement('class C {}', []);
    expect(resynthesized, isCompilationUnitElement);
  }

  /**
   * Encode the library [text] into a summary and then use
   * [TestSummaryResynthesizer.getElement] to retrieve just the element with
   * the specified [names] from the resynthesized summary.
   */
  Element _validateGetElement(String text, List<String> names) {
    Source source = addTestSource(text);
    SummaryResynthesizer resynthesizer = encodeLibrary(source);

    var locationComponents = [
      source.uri.toString(),
      source.uri.toString(),
    ]..addAll(names);
    var location = ElementLocationImpl.con3(locationComponents);

    Element result = resynthesizer.getElement(location);
    checkMinimalResynthesisWork(resynthesizer, source.uri, [source.uri]);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 3);
    expect(result.location, location);
    return result;
  }
}

/// Mixin containing test cases exercising summary resynthesis.  Intended to be
/// applied to a class implementing [ResynthesizeTestStrategy], along with the
/// mixin [ResynthesizeTestHelpers].
mixin ResynthesizeTestCases implements ResynthesizeTestHelpers {
  test_class_abstract() async {
    var library = await checkLibrary('abstract class C {}');
    checkElementText(library, r'''
abstract class C {
}
''');
  }

  test_class_alias() async {
    var library = await checkLibrary('''
class C = D with E, F, G;
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
class alias C extends D with E, F, G {
  synthetic C() = D;
}
class D {
}
class E {
}
class F {
}
class G {
}
''');
  }

  test_class_alias_abstract() async {
    var library = await checkLibrary('''
abstract class C = D with E;
class D {}
class E {}
''');
    checkElementText(library, r'''
abstract class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
/**
 * Docs
 */
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// b
/// cc
class C = D with E;

class D {}
class E {}
''');
    checkElementText(library, r'''
/// aaa
/// b
/// cc
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_documented_withLeadingNonDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C = D with E;

class D {}
class E {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
''');
  }

  test_class_alias_generic() async {
    var library = await checkLibrary('''
class Z = A with B<int>, C<double>;
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
class alias Z extends A with B<int>, C<double> {
  synthetic Z() = A;
}
class A {
}
class B<B1> {
}
class C<C1> {
}
''');
  }

  test_class_alias_with_forwarding_constructors() async {
    addLibrarySource('/a.dart', '''
class Base {
  Base._priv();
  Base();
  Base.noArgs();
  Base.requiredArg(x);
  Base.positionalArg([bool x = true]);
  Base.namedArg({int x = 42});
  factory Base.fact() => null;
  factory Base.fact2() = Base.noArgs;
}
''');
    var library = await checkLibrary('''
import "a.dart";
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
import 'a.dart';
class M {
}
class alias MixinApp extends Base with M {
  synthetic MixinApp() = Base;
  synthetic MixinApp.noArgs() = Base.noArgs;
  synthetic MixinApp.requiredArg(dynamic x) = Base.requiredArg;
  synthetic MixinApp.positionalArg([bool x = true]) = Base.positionalArg;
  synthetic MixinApp.namedArg({int x: 42}) = Base.namedArg;
  synthetic MixinApp.fact() = Base.fact;
  synthetic MixinApp.fact2() = Base.fact2;
}
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp = Base with M;
''');
    checkElementText(library, r'''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {
}
class alias MixinApp extends Base<dynamic> with M {
  synthetic MixinApp.ctor(dynamic t, List<dynamic> l) = Base<T>.ctor;
}
''');
  }

  test_class_alias_with_forwarding_constructors_type_substitution_complex() async {
    var library = await checkLibrary('''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {}
class MixinApp<U> = Base<List<U>> with M;
''');
    checkElementText(library, r'''
class Base<T> {
  Base.ctor(T t, List<T> l);
}
class M {
}
class alias MixinApp<U> extends Base<List<U>> with M {
  synthetic MixinApp.ctor(List<U> t, List<List<U>> l) = Base<T>.ctor;
}
''');
  }

  test_class_alias_with_mixin_members() async {
    var library = await checkLibrary('''
class C = D with E;
class D {}
class E {
  int get a => null;
  void set b(int i) {}
  void f() {}
  int x;
}''');
    checkElementText(library, r'''
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
  int x;
  int get a {}
  void set b(int i) {}
  void f() {}
}
''');
  }

  test_class_constructor_const() async {
    var library = await checkLibrary('class C { const C(); }');
    checkElementText(library, r'''
class C {
  const C();
}
''');
  }

  test_class_constructor_const_external() async {
    var library = await checkLibrary('class C { external const C(); }');
    checkElementText(library, r'''
class C {
  external const C();
}
''');
  }

  test_class_constructor_explicit_named() async {
    var library = await checkLibrary('class C { C.foo(); }');
    checkElementText(library, r'''
class C {
  C.foo();
}
''');
  }

  test_class_constructor_explicit_type_params() async {
    var library = await checkLibrary('class C<T, U> { C(); }');
    checkElementText(library, r'''
class C<T, U> {
  C();
}
''');
  }

  test_class_constructor_explicit_unnamed() async {
    var library = await checkLibrary('class C { C(); }');
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_class_constructor_external() async {
    var library = await checkLibrary('class C { external C(); }');
    checkElementText(library, r'''
class C {
  external C();
}
''');
  }

  test_class_constructor_factory() async {
    var library = await checkLibrary('class C { factory C() => null; }');
    checkElementText(library, r'''
class C {
  factory C();
}
''');
  }

  test_class_constructor_field_formal_dynamic_dynamic() async {
    var library =
        await checkLibrary('class C { dynamic x; C(dynamic this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_dynamic_typed() async {
    var library = await checkLibrary('class C { dynamic x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_dynamic_untyped() async {
    var library = await checkLibrary('class C { dynamic x; C(this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_functionTyped_noReturnType() async {
    var library = await checkLibrary(r'''
class C {
  var x;
  C(this.x(double b));
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C((double) → dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_functionTyped_withReturnType() async {
    var library = await checkLibrary(r'''
class C {
  var x;
  C(int this.x(double b));
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C((double) → int this.x);
}
''');
  }

  test_class_constructor_field_formal_multiple_matching_fields() async {
    // This is a compile-time error but it should still analyze consistently.
    var library = await checkLibrary('class C { C(this.x); int x; String x; }',
        allowErrors: true);
    checkElementText(library, r'''
class C {
  int x;
  String x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_no_matching_field() async {
    // This is a compile-time error but it should still analyze consistently.
    var library =
        await checkLibrary('class C { C(this.x); }', allowErrors: true);
    checkElementText(library, r'''
class C {
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_dynamic() async {
    var library = await checkLibrary('class C { num x; C(dynamic this.x); }',
        allowErrors: true);
    checkElementText(library, r'''
class C {
  num x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_typed() async {
    var library = await checkLibrary('class C { num x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  num x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_typed_untyped() async {
    var library = await checkLibrary('class C { num x; C(this.x); }');
    checkElementText(library, r'''
class C {
  num x;
  C(num this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_dynamic() async {
    var library = await checkLibrary('class C { var x; C(dynamic this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_typed() async {
    var library = await checkLibrary('class C { var x; C(int this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(int this.x);
}
''');
  }

  test_class_constructor_field_formal_untyped_untyped() async {
    var library = await checkLibrary('class C { var x; C(this.x); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(dynamic this.x);
}
''');
  }

  test_class_constructor_fieldFormal_named_noDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x}); }');
    checkElementText(library, r'''
class C {
  int x;
  C({int this.x});
}
''');
  }

  test_class_constructor_fieldFormal_named_withDefault() async {
    var library = await checkLibrary('class C { int x; C({this.x: 42}); }');
    checkElementText(library, r'''
class C {
  int x;
  C({int this.x: 42});
}
''');
  }

  test_class_constructor_fieldFormal_optional_noDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x]); }');
    checkElementText(library, r'''
class C {
  int x;
  C([int this.x]);
}
''');
  }

  test_class_constructor_fieldFormal_optional_withDefault() async {
    var library = await checkLibrary('class C { int x; C([this.x = 42]); }');
    checkElementText(library, r'''
class C {
  int x;
  C([int this.x = 42]);
}
''');
  }

  test_class_constructor_implicit() async {
    var library = await checkLibrary('class C {}');
    checkElementText(library, r'''
class C {
}
''');
  }

  test_class_constructor_implicit_type_params() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
class C<T, U> {
}
''');
  }

  test_class_constructor_params() async {
    var library = await checkLibrary('class C { C(x, int y); }');
    checkElementText(library, r'''
class C {
  C(dynamic x, int y);
}
''');
  }

  test_class_constructors() async {
    var library = await checkLibrary('class C { C.foo(); C.bar(); }');
    checkElementText(library, r'''
class C {
  C.foo();
  C.bar();
}
''');
  }

  test_class_documented() async {
    var library = await checkLibrary('''
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_documented_mix() async {
    var library = await checkLibrary('''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}

/**
 * aaa
 */
/// bbb
/// ccc
class B {}

/// aaa
/// bbb
/**
 * ccc
 */
class C {}

/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}

/**
 * aaa
 */
// bbb
class E {}
''');
    checkElementText(library, r'''
/**
 * bbb
 */
class A {
}
/// bbb
/// ccc
class B {
}
/**
 * ccc
 */
class C {
}
/// ddd
class D {
}
/**
 * aaa
 */
class E {
}
''');
  }

  test_class_documented_tripleSlash() async {
    var library = await checkLibrary('''
/// aaa
/// bbbb
/// cc
class C {}''');
    checkElementText(library, r'''
/// aaa
/// bbbb
/// cc
class C {
}
''');
  }

  test_class_documented_with_references() async {
    var library = await checkLibrary('''
/**
 * Docs referring to [D] and [E]
 */
class C {}

class D {}
class E {}''');
    checkElementText(library, r'''
/**
 * Docs referring to [D] and [E]
 */
class C {
}
class D {
}
class E {
}
''');
  }

  test_class_documented_with_windows_line_endings() async {
    var library = await checkLibrary('/**\r\n * Docs\r\n */\r\nclass C {}');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_documented_withLeadingNotDocumentation() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
class C {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
class C {
}
''');
  }

  test_class_documented_withMetadata() async {
    var library = await checkLibrary('''
/// Comment 1
/// Comment 2
@Annotation()
class BeforeMeta {}

/// Comment 1
/// Comment 2
@Annotation.named()
class BeforeMetaNamed {}

@Annotation()
/// Comment 1
/// Comment 2
class AfterMeta {}

/// Comment 1
@Annotation()
/// Comment 2
class AroundMeta {}

/// Doc comment.
@Annotation()
// Not doc comment.
class DocBeforeMetaNotDocAfter {}

class Annotation {
  const Annotation();
  const Annotation.named();
}
''');
    checkElementText(
        library,
        r'''
/// Comment 1
/// Comment 2
@Annotation()
class BeforeMeta {
}
/// Comment 1
/// Comment 2
@Annotation.named()
class BeforeMetaNamed {
}
/// Comment 1
/// Comment 2
@Annotation()
class AfterMeta {
}
/// Comment 2
@Annotation()
class AroundMeta {
}
/// Doc comment.
@Annotation()
class DocBeforeMetaNotDocAfter {
}
class Annotation {
  const Annotation();
  const Annotation.named();
}
''',
        withConstElements: false);
  }

  test_class_field_const() async {
    var library = await checkLibrary('class C { static const int i = 0; }');
    checkElementText(library, r'''
class C {
  static const int i = 0;
}
''');
  }

  test_class_field_implicit_type() async {
    var library = await checkLibrary('class C { var x; }');
    checkElementText(library, r'''
class C {
  dynamic x;
}
''');
  }

  test_class_field_static() async {
    var library = await checkLibrary('class C { static int i; }');
    checkElementText(library, r'''
class C {
  static int i;
}
''');
  }

  test_class_fields() async {
    var library = await checkLibrary('class C { int i; int j; }');
    checkElementText(library, r'''
class C {
  int i;
  int j;
}
''');
  }

  test_class_getter_abstract() async {
    var library = await checkLibrary('abstract class C { int get x; }');
    checkElementText(library, r'''
abstract class C {
  int get x;
}
''');
  }

  test_class_getter_external() async {
    var library = await checkLibrary('class C { external int get x; }');
    checkElementText(library, r'''
class C {
  external int get x;
}
''');
  }

  test_class_getter_implicit_return_type() async {
    var library = await checkLibrary('class C { get x => null; }');
    checkElementText(library, r'''
class C {
  dynamic get x {}
}
''');
  }

  test_class_getter_static() async {
    var library = await checkLibrary('class C { static int get x => null; }');
    checkElementText(library, r'''
class C {
  static int get x {}
}
''');
  }

  test_class_getters() async {
    var library =
        await checkLibrary('class C { int get x => null; get y => null; }');
    checkElementText(library, r'''
class C {
  int get x {}
  dynamic get y {}
}
''');
  }

  test_class_implicitField_getterFirst() async {
    var library = await checkLibrary('''
class C {
  int get x => 0;
  void set x(int value) {} 
}
''');
    checkElementText(library, r'''
class C {
  int get x {}
  void set x(int value) {}
}
''');
  }

  test_class_implicitField_setterFirst() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  int get x => 0;
}
''');
    checkElementText(library, r'''
class C {
  void set x(int value) {}
  int get x {}
}
''');
  }

  test_class_interfaces() async {
    var library = await checkLibrary('''
class C implements D, E {}
class D {}
class E {}
''');
    checkElementText(library, r'''
class C implements D, E {
}
class D {
}
class E {
}
''');
  }

  test_class_interfaces_unresolved() async {
    var library = await checkLibrary(
        'class C implements X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
class C implements X, Z {
}
class X {
}
class Z {
}
''');
  }

  test_class_method_abstract() async {
    var library = await checkLibrary('abstract class C { f(); }');
    checkElementText(library, r'''
abstract class C {
  dynamic f();
}
''');
  }

  test_class_method_external() async {
    var library = await checkLibrary('class C { external f(); }');
    checkElementText(library, r'''
class C {
  external dynamic f() {}
}
''');
  }

  test_class_method_params() async {
    var library = await checkLibrary('class C { f(x, y) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(dynamic x, dynamic y) {}
}
''');
  }

  test_class_method_static() async {
    var library = await checkLibrary('class C { static f() {} }');
    checkElementText(library, r'''
class C {
  static dynamic f() {}
}
''');
  }

  test_class_methods() async {
    var library = await checkLibrary('class C { f() {} g() {} }');
    checkElementText(library, r'''
class C {
  dynamic f() {}
  dynamic g() {}
}
''');
  }

  test_class_mixins() async {
    var library = await checkLibrary('''
class C extends D with E, F, G {}
class D {}
class E {}
class F {}
class G {}
''');
    checkElementText(library, r'''
class C extends D with E, F, G {
  synthetic C();
}
class D {
}
class E {
}
class F {
}
class G {
}
''');
  }

  test_class_mixins_generic() async {
    var library = await checkLibrary('''
class Z extends A with B<int>, C<double> {}
class A {}
class B<B1> {}
class C<C1> {}
''');
    checkElementText(library, r'''
class Z extends A with B<int>, C<double> {
  synthetic Z();
}
class A {
}
class B<B1> {
}
class C<C1> {
}
''');
  }

  test_class_mixins_unresolved() async {
    var library = await checkLibrary(
        'class C extends Object with X, Y, Z {} class X {} class Z {}',
        allowErrors: true);
    checkElementText(library, r'''
class C extends Object with X, Z {
  synthetic C();
}
class X {
}
class Z {
}
''');
  }

  test_class_setter_abstract() async {
    var library =
        await checkLibrary('abstract class C { void set x(int value); }');
    checkElementText(library, r'''
abstract class C {
  void set x(int value);
}
''');
  }

  test_class_setter_external() async {
    var library =
        await checkLibrary('class C { external void set x(int value); }');
    checkElementText(library, r'''
class C {
  external void set x(int value);
}
''');
  }

  test_class_setter_implicit_param_type() async {
    var library = await checkLibrary('class C { void set x(value) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic value) {}
}
''');
  }

  test_class_setter_implicit_return_type() async {
    var library = await checkLibrary('class C { set x(int value) {} }');
    checkElementText(library, r'''
class C {
  void set x(int value) {}
}
''');
  }

  test_class_setter_invalid_named_parameter() async {
    var library = await checkLibrary('class C { void set x({a}) {} }');
    checkElementText(library, r'''
class C {
  void set x({dynamic a}) {}
}
''');
  }

  test_class_setter_invalid_no_parameter() async {
    var library = await checkLibrary('class C { void set x() {} }');
    checkElementText(library, r'''
class C {
  void set x() {}
}
''');
  }

  test_class_setter_invalid_optional_parameter() async {
    var library = await checkLibrary('class C { void set x([a]) {} }');
    checkElementText(library, r'''
class C {
  void set x([dynamic a]) {}
}
''');
  }

  test_class_setter_invalid_too_many_parameters() async {
    var library = await checkLibrary('class C { void set x(a, b) {} }');
    checkElementText(library, r'''
class C {
  void set x(dynamic a, dynamic b) {}
}
''');
  }

  test_class_setter_static() async {
    var library =
        await checkLibrary('class C { static void set x(int value) {} }');
    checkElementText(library, r'''
class C {
  static void set x(int value) {}
}
''');
  }

  test_class_setters() async {
    var library = await checkLibrary('''
class C {
  void set x(int value) {}
  set y(value) {}
}
''');
    checkElementText(library, r'''
class C {
  void set x(int value) {}
  void set y(dynamic value) {}
}
''');
  }

  test_class_supertype() async {
    var library = await checkLibrary('''
class C extends D {}
class D {}
''');
    checkElementText(library, r'''
class C extends D {
}
class D {
}
''');
  }

  test_class_supertype_typeArguments() async {
    var library = await checkLibrary('''
class C extends D<int, double> {}
class D<T1, T2> {}
''');
    checkElementText(library, r'''
class C extends D<int, double> {
}
class D<T1, T2> {
}
''');
  }

  test_class_supertype_unresolved() async {
    var library = await checkLibrary('class C extends D {}', allowErrors: true);
    checkElementText(library, r'''
class C {
}
''');
  }

  test_class_type_parameters() async {
    var library = await checkLibrary('class C<T, U> {}');
    checkElementText(library, r'''
class C<T, U> {
}
''');
  }

  test_class_type_parameters_bound() async {
    var library = await checkLibrary('''
class C<T extends Object, U extends D> {}
class D {}
''');
    checkElementText(library, r'''
class C<T, U extends D> {
}
class D {
}
''');
  }

  test_class_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('class C<T extends List<U>, U> {}');
    checkElementText(library, r'''
notSimplyBounded class C<T extends List<U>, U> {
}
''');
  }

  test_class_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('class C<T extends U, U> {}');
    checkElementText(library, r'''
notSimplyBounded class C<T extends U, U> {
}
''');
  }

  test_classes() async {
    var library = await checkLibrary('class C {} class D {}');
    checkElementText(library, r'''
class C {
}
class D {
}
''');
  }

  test_closure_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('''
f() {
  print(() {});
  print(() => () => 0);
}
''');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_closure_generic() async {
    var library = await checkLibrary(r'''
final f = <U, V>(U x, V y) => y;
''');
    checkElementText(library, r'''
final <U,V>(U, V) → V f;
''');
  }

  test_closure_in_variable_declaration_in_part() async {
    addSource('/a.dart', 'part of lib; final f = (int i) => i.toDouble();');
    var library = await checkLibrary('''
library lib;
part "a.dart";
''');
    checkElementText(library, r'''
library lib;
part 'a.dart';
--------------------
unit: a.dart

final (int) → double f;
''');
  }

  test_codeRange_class() async {
    var library = await checkLibrary('''
class Raw {}

/// Comment 1.
/// Comment 2.
class HasDocComment {}

@Object()
class HasAnnotation {}

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment {}

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation {}

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation {}
''');
    checkElementText(
        library,
        r'''
class Raw/*codeOffset=0, codeLength=12*/ {
}
/// Comment 1.
/// Comment 2.
class HasDocComment/*codeOffset=14, codeLength=52*/ {
}
@Object()
class HasAnnotation/*codeOffset=68, codeLength=32*/ {
}
/// Comment 1.
/// Comment 2.
@Object()
class AnnotationThenComment/*codeOffset=102, codeLength=70*/ {
}
/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation/*codeOffset=174, codeLength=70*/ {
}
/// Comment 2.
@Object()
class CommentAroundAnnotation/*codeOffset=261, codeLength=57*/ {
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_class_namedMixin() async {
    var library = await checkLibrary('''
class A {}

class B {}
    
class Raw = Object with A, B;

/// Comment 1.
/// Comment 2.
class HasDocComment = Object with A, B;

@Object()
class HasAnnotation = Object with A, B;

@Object()
/// Comment 1.
/// Comment 2.
class AnnotationThenComment = Object with A, B;

/// Comment 1.
/// Comment 2.
@Object()
class CommentThenAnnotation = Object with A, B;

/// Comment 1.
@Object()
/// Comment 2.
class CommentAroundAnnotation = Object with A, B;
''');
    checkElementText(
        library,
        r'''
class A/*codeOffset=0, codeLength=10*/ {
}
class B/*codeOffset=12, codeLength=10*/ {
}
class alias Raw/*codeOffset=28, codeLength=29*/ extends Object with A, B {
  synthetic Raw() = Object;
}
/// Comment 1.
/// Comment 2.
class alias HasDocComment/*codeOffset=59, codeLength=69*/ extends Object with A, B {
  synthetic HasDocComment() = Object;
}
@Object()
class alias HasAnnotation/*codeOffset=130, codeLength=49*/ extends Object with A, B {
  synthetic HasAnnotation() = Object;
}
/// Comment 1.
/// Comment 2.
@Object()
class alias AnnotationThenComment/*codeOffset=181, codeLength=87*/ extends Object with A, B {
  synthetic AnnotationThenComment() = Object;
}
/// Comment 1.
/// Comment 2.
@Object()
class alias CommentThenAnnotation/*codeOffset=270, codeLength=87*/ extends Object with A, B {
  synthetic CommentThenAnnotation() = Object;
}
/// Comment 2.
@Object()
class alias CommentAroundAnnotation/*codeOffset=374, codeLength=74*/ extends Object with A, B {
  synthetic CommentAroundAnnotation() = Object;
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_constructor() async {
    var library = await checkLibrary('''
class C {
  C();

  C.raw() {}

  /// Comment 1.
  /// Comment 2.
  C.hasDocComment() {}

  @Object()
  C.hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  C.annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  C.commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  C.commentAroundAnnotation() {}
}
''');
    checkElementText(
        library,
        r'''
class C/*codeOffset=0, codeLength=362*/ {
  C/*codeOffset=12, codeLength=4*/();
  C.raw/*codeOffset=20, codeLength=10*/();
  /// Comment 1.
  /// Comment 2.
  C.hasDocComment/*codeOffset=34, codeLength=54*/();
  @Object()
  C.hasAnnotation/*codeOffset=92, codeLength=32*/();
  /// Comment 1.
  /// Comment 2.
  @Object()
  C.annotationThenComment/*codeOffset=128, codeLength=74*/();
  /// Comment 1.
  /// Comment 2.
  @Object()
  C.commentThenAnnotation/*codeOffset=206, codeLength=74*/();
  /// Comment 2.
  @Object()
  C.commentAroundAnnotation/*codeOffset=301, codeLength=59*/();
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_constructor_factory() async {
    var library = await checkLibrary('''
class C {
  factory C() => null;

  factory C.raw() => null;

  /// Comment 1.
  /// Comment 2.
  factory C.hasDocComment() => null;

  @Object()
  factory C.hasAnnotation() => null;

  @Object()
  /// Comment 1.
  /// Comment 2.
  factory C.annotationThenComment() => null;

  /// Comment 1.
  /// Comment 2.
  @Object()
  factory C.commentThenAnnotation() => null;

  /// Comment 1.
  @Object()
  /// Comment 2.
  factory C.commentAroundAnnotation() => null;
}
''');
    checkElementText(
        library,
        r'''
class C/*codeOffset=0, codeLength=462*/ {
  factory C/*codeOffset=12, codeLength=20*/();
  factory C.raw/*codeOffset=36, codeLength=24*/();
  /// Comment 1.
  /// Comment 2.
  factory C.hasDocComment/*codeOffset=64, codeLength=68*/();
  @Object()
  factory C.hasAnnotation/*codeOffset=136, codeLength=46*/();
  /// Comment 1.
  /// Comment 2.
  @Object()
  factory C.annotationThenComment/*codeOffset=186, codeLength=88*/();
  /// Comment 1.
  /// Comment 2.
  @Object()
  factory C.commentThenAnnotation/*codeOffset=278, codeLength=88*/();
  /// Comment 2.
  @Object()
  factory C.commentAroundAnnotation/*codeOffset=387, codeLength=73*/();
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_field() async {
    var library = await checkLibrary('''
class C {
  int withInit = 1;

  int withoutInit;

  int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3; 
}
''');
    checkElementText(
        library,
        r'''
class C/*codeOffset=0, codeLength=116*/ {
  int withInit/*codeOffset=12, codeLength=16*/;
  int withoutInit/*codeOffset=33, codeLength=15*/;
  int multiWithInit/*codeOffset=53, codeLength=21*/;
  int multiWithoutInit/*codeOffset=76, codeLength=16*/;
  int multiWithInit2/*codeOffset=94, codeLength=18*/;
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_field_annotations() async {
    var library = await checkLibrary('''
class C {
  /// Comment 1.
  /// Comment 2.
  int hasDocComment, hasDocComment2;

  @Object()
  int hasAnnotation, hasAnnotation2;

  @Object()
  /// Comment 1.
  /// Comment 2.
  int annotationThenComment, annotationThenComment2;

  /// Comment 1.
  /// Comment 2.
  @Object()
  int commentThenAnnotation, commentThenAnnotation2;

  /// Comment 1.
  @Object()
  /// Comment 2.
  int commentAroundAnnotation, commentAroundAnnotation2;
}
''');
    checkElementText(
        library,
        r'''
class C/*codeOffset=0, codeLength=436*/ {
  /// Comment 1.
  /// Comment 2.
  int hasDocComment/*codeOffset=12, codeLength=51*/;
  /// Comment 1.
  /// Comment 2.
  int hasDocComment2/*codeOffset=65, codeLength=14*/;
  @Object()
  int hasAnnotation/*codeOffset=84, codeLength=29*/;
  @Object()
  int hasAnnotation2/*codeOffset=115, codeLength=14*/;
  /// Comment 1.
  /// Comment 2.
  @Object()
  int annotationThenComment/*codeOffset=134, codeLength=71*/;
  /// Comment 1.
  /// Comment 2.
  @Object()
  int annotationThenComment2/*codeOffset=207, codeLength=22*/;
  /// Comment 1.
  /// Comment 2.
  @Object()
  int commentThenAnnotation/*codeOffset=234, codeLength=71*/;
  /// Comment 1.
  /// Comment 2.
  @Object()
  int commentThenAnnotation2/*codeOffset=307, codeLength=22*/;
  /// Comment 2.
  @Object()
  int commentAroundAnnotation/*codeOffset=351, codeLength=56*/;
  /// Comment 2.
  @Object()
  int commentAroundAnnotation2/*codeOffset=409, codeLength=24*/;
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_function() async {
    var library = await checkLibrary('''
void raw() {}

/// Comment 1.
/// Comment 2.
void hasDocComment() {}

@Object()
void hasAnnotation() {}

@Object()
/// Comment 1.
/// Comment 2.
void annotationThenComment() {}

/// Comment 1.
/// Comment 2.
@Object()
void commentThenAnnotation() {}

/// Comment 1.
@Object()
/// Comment 2.
void commentAroundAnnotation() {}
''');
    checkElementText(
        library,
        r'''
void raw/*codeOffset=0, codeLength=13*/() {}
/// Comment 1.
/// Comment 2.
void hasDocComment/*codeOffset=15, codeLength=53*/() {}
@Object()
void hasAnnotation/*codeOffset=70, codeLength=33*/() {}
/// Comment 1.
/// Comment 2.
@Object()
void annotationThenComment/*codeOffset=105, codeLength=71*/() {}
/// Comment 1.
/// Comment 2.
@Object()
void commentThenAnnotation/*codeOffset=178, codeLength=71*/() {}
/// Comment 2.
@Object()
void commentAroundAnnotation/*codeOffset=266, codeLength=58*/() {}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_method() async {
    var library = await checkLibrary('''
class C {
  void raw() {}

  /// Comment 1.
  /// Comment 2.
  void hasDocComment() {}

  @Object()
  void hasAnnotation() {}

  @Object()
  /// Comment 1.
  /// Comment 2.
  void annotationThenComment() {}

  /// Comment 1.
  /// Comment 2.
  @Object()
  void commentThenAnnotation() {}

  /// Comment 1.
  @Object()
  /// Comment 2.
  void commentAroundAnnotation() {}
}
''');
    checkElementText(
        library,
        r'''
class C/*codeOffset=0, codeLength=372*/ {
  void raw/*codeOffset=12, codeLength=13*/() {}
  /// Comment 1.
  /// Comment 2.
  void hasDocComment/*codeOffset=29, codeLength=57*/() {}
  @Object()
  void hasAnnotation/*codeOffset=90, codeLength=35*/() {}
  /// Comment 1.
  /// Comment 2.
  @Object()
  void annotationThenComment/*codeOffset=129, codeLength=77*/() {}
  /// Comment 1.
  /// Comment 2.
  @Object()
  void commentThenAnnotation/*codeOffset=210, codeLength=77*/() {}
  /// Comment 2.
  @Object()
  void commentAroundAnnotation/*codeOffset=308, codeLength=62*/() {}
}
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_parameter() async {
    var library = await checkLibrary('''
main({int a = 1, int b, int c = 2}) {}
''');
    checkElementText(
        library,
        'dynamic main/*codeOffset=0, codeLength=38*/('
        '{int a/*codeOffset=6, codeLength=9*/: 1}, '
        '{int b/*codeOffset=17, codeLength=5*/}, '
        '{int c/*codeOffset=24, codeLength=9*/: 2}) {}\n',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_parameter_annotations() async {
    var library = await checkLibrary('''
main(@Object() int a, int b, @Object() int c) {}
''');
    checkElementText(
        library,
        'dynamic main/*codeOffset=0, codeLength=48*/('
        '@Object() int a/*codeOffset=5, codeLength=15*/, '
        'int b/*codeOffset=22, codeLength=5*/, '
        '@Object() int c/*codeOffset=29, codeLength=15*/) {}\n',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_topLevelVariable() async {
    var library = await checkLibrary('''
int withInit = 1 + 2 * 3;

int withoutInit;

int multiWithInit = 2, multiWithoutInit, multiWithInit2 = 3; 
''');
    checkElementText(
        library,
        r'''
int withInit/*codeOffset=0, codeLength=24*/;
int withoutInit/*codeOffset=27, codeLength=15*/;
int multiWithInit/*codeOffset=45, codeLength=21*/;
int multiWithoutInit/*codeOffset=68, codeLength=16*/;
int multiWithInit2/*codeOffset=86, codeLength=18*/;
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_codeRange_topLevelVariable_annotations() async {
    var library = await checkLibrary('''
/// Comment 1.
/// Comment 2.
int hasDocComment, hasDocComment2;

@Object()
int hasAnnotation, hasAnnotation2;

@Object()
/// Comment 1.
/// Comment 2.
int annotationThenComment, annotationThenComment2;

/// Comment 1.
/// Comment 2.
@Object()
int commentThenAnnotation, commentThenAnnotation2;

/// Comment 1.
@Object()
/// Comment 2.
int commentAroundAnnotation, commentAroundAnnotation2;
''');
    checkElementText(
        library,
        r'''
/// Comment 1.
/// Comment 2.
int hasDocComment/*codeOffset=0, codeLength=47*/;
/// Comment 1.
/// Comment 2.
int hasDocComment2/*codeOffset=49, codeLength=14*/;
@Object()
int hasAnnotation/*codeOffset=66, codeLength=27*/;
@Object()
int hasAnnotation2/*codeOffset=95, codeLength=14*/;
/// Comment 1.
/// Comment 2.
@Object()
int annotationThenComment/*codeOffset=112, codeLength=65*/;
/// Comment 1.
/// Comment 2.
@Object()
int annotationThenComment2/*codeOffset=179, codeLength=22*/;
/// Comment 1.
/// Comment 2.
@Object()
int commentThenAnnotation/*codeOffset=204, codeLength=65*/;
/// Comment 1.
/// Comment 2.
@Object()
int commentThenAnnotation2/*codeOffset=271, codeLength=22*/;
/// Comment 2.
@Object()
int commentAroundAnnotation/*codeOffset=311, codeLength=52*/;
/// Comment 2.
@Object()
int commentAroundAnnotation2/*codeOffset=365, codeLength=24*/;
''',
        withCodeRanges: true,
        withConstElements: false);
  }

  test_const_constructor_inferred_args() async {
    var library = await checkLibrary('''
class C<T> {
  final T t;
  const C(this.t);
  const C.named(this.t);
}
const Object x = const C(0);
const Object y = const C.named(0);
''');
    checkElementText(library, '''
class C<T> {
  final T t;
  const C(T this.t);
  const C.named(T this.t);
}
const Object x = const
        C/*location: test.dart;C*/(0);
const Object y = const
        C/*location: test.dart;C*/.
        named/*location: test.dart;C;named*/(0);
''');
    TopLevelVariableElementImpl x =
        library.definingCompilationUnit.topLevelVariables[0];
    InstanceCreationExpression xExpr = x.constantInitializer;
    var xType = xExpr.constructorName.staticElement.returnType;
    expect(xType.toString(), 'C<int>');
    TopLevelVariableElementImpl y =
        library.definingCompilationUnit.topLevelVariables[0];
    InstanceCreationExpression yExpr = y.constantInitializer;
    var yType = yExpr.constructorName.staticElement.returnType;
    expect(yType.toString(), 'C<int>');
  }

  test_const_finalField_hasConstConstructor() async {
    var library = await checkLibrary(r'''
class C {
  final int f = 42;
  const C();
}
''');
    checkElementText(library, r'''
class C {
  final int f = 42;
  const C();
}
''');
  }

  test_const_invalid_field_const() async {
    var library = await checkLibrary(r'''
class C {
  static const f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  static const int f = 1 +
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
  }

  test_const_invalid_field_final() async {
    var library = await checkLibrary(r'''
class C {
  final f = 1 + foo();
}
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  final int f;
}
int foo() {}
''');
  }

  test_const_invalid_intLiteral() async {
    var library = await checkLibrary(r'''
const int x = 0x;
''', allowErrors: true);
    checkElementText(library, r'''
const int x = 0;
''');
  }

  test_const_invalid_topLevel() async {
    var library = await checkLibrary(r'''
const v = 1 + foo();
int foo() => 42;
''', allowErrors: true);
    checkElementText(library, r'''
const int v = 1 +
        foo/*location: test.dart;foo*/();
int foo() {}
''');
  }

  test_const_invalid_typeMismatch() async {
    var library = await checkLibrary(r'''
const int a = 0;
const bool b = a + 5;
''', allowErrors: true);
    checkElementText(library, r'''
const int a = 0;
const bool b =
        a/*location: test.dart;a?*/ + 5;
''');
  }

  test_const_invokeConstructor_generic_named() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C.named(K k, V v);
}
const V = const C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
class C<K, V> {
  const C.named(K k, V v);
}
const C<int, String> V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: test.dart;C;named*/(1, '222');
''');
  }

  test_const_invokeConstructor_generic_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
import 'a.dart';
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
  }

  test_const_invokeConstructor_generic_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C.named(K k, V v);
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>.named(1, '222');
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>.
        named/*location: a.dart;C;named*/(1, '222');
''');
  }

  test_const_invokeConstructor_generic_noTypeArguments() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C();
''');
    checkElementText(library, r'''
class C<K, V> {
  const C();
}
const C<dynamic, dynamic> V = const
        C/*location: test.dart;C*/();
''');
  }

  test_const_invokeConstructor_generic_unnamed() async {
    var library = await checkLibrary(r'''
class C<K, V> {
  const C();
}
const V = const C<int, String>();
''');
    checkElementText(library, r'''
class C<K, V> {
  const C();
}
const C<int, String> V = const
        C/*location: test.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C<int, String>();
''');
    checkElementText(library, r'''
import 'a.dart';
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
  }

  test_const_invokeConstructor_generic_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C<K, V> {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C<int, String>();
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const C<int, String> V = const
        C/*location: a.dart;C*/<
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>();
''');
  }

  test_const_invokeConstructor_named() async {
    var library = await checkLibrary(r'''
class C {
  const C.named(bool a, int b, int c, {String d, double e});
}
const V = const C.named(true, 1, 2, d: 'ccc', e: 3.4);
''');
    checkElementText(library, r'''
class C {
  const C.named(bool a, int b, int c, {String d}, {double e});
}
const C V = const
        C/*location: test.dart;C*/.
        named/*location: test.dart;C;named*/(true, 1, 2,
        d/*location: null*/: 'ccc',
        e/*location: null*/: 3.4);
''');
  }

  test_const_invokeConstructor_named_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C.named();
''');
    checkElementText(library, r'''
import 'a.dart';
const C V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
  }

  test_const_invokeConstructor_named_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const C V = const
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/();
''');
  }

  test_const_invokeConstructor_named_unresolved() async {
    var library = await checkLibrary(r'''
class C {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
class C {
}
const dynamic V = const
        C/*location: test.dart;C*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_named_unresolved2() async {
    var library = await checkLibrary(r'''
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = const
        C/*location: null*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_named_unresolved3() async {
    addLibrarySource('/a.dart', r'''
class C {
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_named_unresolved4() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        p/*location: test.dart;p*/.
        C/*location: null*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_named_unresolved5() async {
    var library = await checkLibrary(r'''
const V = const p.C.named();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = const
        p/*location: null*/.
        C/*location: null*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_named_unresolved6() async {
    var library = await checkLibrary(r'''
class C<T> {}
const V = const C.named();
''', allowErrors: true);
    checkElementText(library, r'''
class C<T> {
}
const dynamic V = const
        C/*location: test.dart;C*/.
        named/*location: null*/();
''');
  }

  test_const_invokeConstructor_unnamed() async {
    var library = await checkLibrary(r'''
class C {
  const C();
}
const V = const C();
''');
    checkElementText(library, r'''
class C {
  const C();
}
const C V = const
        C/*location: test.dart;C*/();
''');
  }

  test_const_invokeConstructor_unnamed_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = const C();
''');
    checkElementText(library, r'''
import 'a.dart';
const C V = const
        C/*location: a.dart;C*/();
''');
  }

  test_const_invokeConstructor_unnamed_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C();
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const C V = const
        C/*location: a.dart;C*/();
''');
  }

  test_const_invokeConstructor_unnamed_unresolved() async {
    var library = await checkLibrary(r'''
const V = const C();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = const
        C/*location: null*/();
''');
  }

  test_const_invokeConstructor_unnamed_unresolved2() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
import 'a.dart' as p;
const dynamic V = const
        p/*location: test.dart;p*/.
        C/*location: null*/();
''');
  }

  test_const_invokeConstructor_unnamed_unresolved3() async {
    var library = await checkLibrary(r'''
const V = const p.C();
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V = const
        p/*location: null*/.
        C/*location: null*/();
''');
  }

  test_const_length_ofClassConstField() async {
    var library = await checkLibrary(r'''
class C {
  static const String F = '';
}
const int v = C.F.length;
''');
    checkElementText(library, r'''
class C {
  static const String F = '';
}
const int v =
        C/*location: test.dart;C*/.
        F/*location: test.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofClassConstField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const int v = C.F.length;
''');
    checkElementText(library, r'''
import 'a.dart';
const int v =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofClassConstField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const String F = '';
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const int v = p.C.F.length;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofStringLiteral() async {
    var library = await checkLibrary(r'''
const v = 'abc'.length;
''');
    checkElementText(library, r'''
const int v = 'abc'.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofTopLevelVariable() async {
    var library = await checkLibrary(r'''
const String S = 'abc';
const v = S.length;
''');
    checkElementText(library, r'''
const String S = 'abc';
const int v =
        S/*location: test.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofTopLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = S.length;
''');
    checkElementText(library, r'''
import 'a.dart';
const int v =
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_ofTopLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const String S = 'abc';
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = p.S.length;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const int v =
        p/*location: test.dart;p*/.
        S/*location: a.dart;S?*/.
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_length_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int length() => 42;
}
const v = C.length;
''');
    checkElementText(library, r'''
class C {
  static int length() {}
}
const () → int v =
        C/*location: test.dart;C*/.
        length/*location: test.dart;C;length*/;
''');
  }

  test_const_list_if() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>[if (true) 1];
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/>[if (true) 1];
''',
        withTypes: true);
  }

  test_const_list_if_else() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>[if (true) 1 else 2];
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/>[if (true) 1 else 2];
''',
        withTypes: true);
  }

  test_const_list_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const [1];
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const /*typeArgs=int*/[1];
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>[1];
''');
    }
  }

  test_const_list_spread() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>[...<int>[1]];
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/>[...<
        int/*location: dart:core;int*/>[1]];
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>[...const <
        int/*location: dart:core;int*/>[1]];
''');
    }
  }

  test_const_list_spread_null_aware() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>[...?<int>[1]];
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/>[...?<
        int/*location: dart:core;int*/>[1]];
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>[...?const <
        int/*location: dart:core;int*/>[1]];
''');
    }
  }

  test_const_map_if() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int, int>{if (true) 1: 2};
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{if (true) 1: 2}/*isMap*/;
''',
        withTypes: true);
  }

  test_const_map_if_else() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int, int>{if (true) 1: 2 else 3: 4];
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{if (true) 1: 2 else 3: 4}/*isMap*/;
''',
        withTypes: true);
  }

  test_const_map_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const {1: 1.0};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const /*typeArgs=int,double*/{1: 1.0}/*isMap*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/,
        double/*location: dart:core;double*/>{1: 1.0}/*isMap*/;
''');
    }
  }

  test_const_map_spread() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int, int>{...<int, int>{1: 2}};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{...<
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{1: 2}/*isMap*/}/*isMap*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{...const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{1: 2}/*isMap*/}/*isMap*/;
''');
    }
  }

  test_const_map_spread_null_aware() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int, int>{...?<int, int>{1: 2}};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{...?<
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{1: 2}/*isMap*/}/*isMap*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{...?const <
        int/*location: dart:core;int*/,
        int/*location: dart:core;int*/>{1: 2}/*isMap*/}/*isMap*/;
''');
    }
  }

  test_const_parameterDefaultValue_initializingFormal_functionTyped() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: foo});
}
int foo() => 42;
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C({dynamic this.x:
        foo/*location: test.dart;foo*/});
}
int foo() {}
''');
  }

  test_const_parameterDefaultValue_initializingFormal_named() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C({this.x: 1 + 2});
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C({dynamic this.x: 1 + 2});
}
''');
  }

  test_const_parameterDefaultValue_initializingFormal_positional() async {
    var library = await checkLibrary(r'''
class C {
  final x;
  const C([this.x = 1 + 2]);
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C([dynamic this.x = 1 + 2]);
}
''');
  }

  test_const_parameterDefaultValue_normal() async {
    var library = await checkLibrary(r'''
class C {
  const C.positional([p = 1 + 2]);
  const C.named({p: 1 + 2});
  void methodPositional([p = 1 + 2]) {}
  void methodPositionalWithoutDefault([p]) {}
  void methodNamed({p: 1 + 2}) {}
  void methodNamedWithoutDefault({p}) {}
}
''');
    checkElementText(library, r'''
class C {
  const C.positional([dynamic p = 1 + 2]);
  const C.named({dynamic p: 1 + 2});
  void methodPositional([dynamic p = 1 + 2]) {}
  void methodPositionalWithoutDefault([dynamic p]) {}
  void methodNamed({dynamic p: 1 + 2}) {}
  void methodNamedWithoutDefault({dynamic p}) {}
}
''');
  }

  test_const_reference_staticField() async {
    var library = await checkLibrary(r'''
class C {
  static const int F = 42;
}
const V = C.F;
''');
    checkElementText(library, r'''
class C {
  static const int F = 42;
}
const int V =
        C/*location: test.dart;C*/.
        F/*location: test.dart;C;F?*/;
''');
  }

  test_const_reference_staticField_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.F;
''');
    checkElementText(library, r'''
import 'a.dart';
const int V =
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
  }

  test_const_reference_staticField_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static const int F = 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.F;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const int V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        F/*location: a.dart;C;F?*/;
''');
  }

  test_const_reference_staticMethod() async {
    var library = await checkLibrary(r'''
class C {
  static int m(int a, String b) => 42;
}
const V = C.m;
''');
    checkElementText(library, r'''
class C {
  static int m(int a, String b) {}
}
const (int, String) → int V =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
''');
  }

  test_const_reference_staticMethod_imported() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = C.m;
''');
    checkElementText(library, r'''
import 'a.dart';
const (int, String) → int V =
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
  }

  test_const_reference_staticMethod_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {
  static int m(int a, String b) => 42;
}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.C.m;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const (int, String) → int V =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/.
        m/*location: a.dart;C;m*/;
''');
  }

  test_const_reference_topLevelFunction() async {
    var library = await checkLibrary(r'''
foo() {}
const V = foo;
''');
    checkElementText(library, r'''
const () → dynamic V =
        foo/*location: test.dart;foo*/;
dynamic foo() {}
''');
  }

  test_const_reference_topLevelFunction_generic() async {
    var library = await checkLibrary(r'''
R foo<P, R>(P p) {}
const V = foo;
''');
    checkElementText(library, r'''
const <P,R>(P) → R V =
        foo/*location: test.dart;foo*/;
R foo<P, R>(P p) {}
''');
  }

  test_const_reference_topLevelFunction_imported() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const V = foo;
''');
    checkElementText(library, r'''
import 'a.dart';
const () → dynamic V =
        foo/*location: a.dart;foo*/;
''');
  }

  test_const_reference_topLevelFunction_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
foo() {}
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const V = p.foo;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const () → dynamic V =
        p/*location: test.dart;p*/.
        foo/*location: a.dart;foo*/;
''');
  }

  test_const_reference_topLevelVariable() async {
    var library = await checkLibrary(r'''
const A = 1;
const B = A + 2;
''');
    checkElementText(library, r'''
const int A = 1;
const int B =
        A/*location: test.dart;A?*/ + 2;
''');
  }

  test_const_reference_topLevelVariable_imported() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const B = A + 2;
''');
    checkElementText(library, r'''
import 'a.dart';
const int B =
        A/*location: a.dart;A?*/ + 2;
''');
  }

  test_const_reference_topLevelVariable_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
const A = 1;
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const B = p.A + 2;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const int B =
        p/*location: test.dart;p*/.
        A/*location: a.dart;A?*/ + 2;
''');
  }

  test_const_reference_type() async {
    var library = await checkLibrary(r'''
class C {}
class D<T> {}
enum E {a, b, c}
typedef F(int a, String b);
const vDynamic = dynamic;
const vNull = Null;
const vObject = Object;
const vClass = C;
const vGenericClass = D;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
    checkElementText(library, r'''
typedef F = dynamic Function(int a, String b);
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
class C {
}
class D<T> {
}
const Type vDynamic =
        dynamic/*location: dynamic*/;
const Type vNull =
        Null/*location: dart:core;Null*/;
const Type vObject =
        Object/*location: dart:core;Object*/;
const Type vClass =
        C/*location: test.dart;C*/;
const Type vGenericClass =
        D/*location: test.dart;D*/;
const Type vEnum =
        E/*location: test.dart;E*/;
const Type vFunctionTypeAlias =
        F/*location: test.dart;F*/;
''');
  }

  test_const_reference_type_functionType() async {
    var library = await checkLibrary(r'''
typedef F();
class C {
  final f = <F>[];
}
''');
    checkElementText(library, r'''
typedef F = dynamic Function();
class C {
  final List<() → dynamic> f;
}
''');
  }

  test_const_reference_type_imported() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart';
const vClass = C;
const vEnum = E;
const vFunctionTypeAlias = F;
''');
    checkElementText(library, r'''
import 'a.dart';
const Type vClass =
        C/*location: a.dart;C*/;
const Type vEnum =
        E/*location: a.dart;E*/;
const Type vFunctionTypeAlias =
        F/*location: a.dart;F*/;
''');
  }

  test_const_reference_type_imported_withPrefix() async {
    addLibrarySource('/a.dart', r'''
class C {}
enum E {a, b, c}
typedef F(int a, String b);
''');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const vClass = p.C;
const vEnum = p.E;
const vFunctionTypeAlias = p.F;
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const Type vClass =
        p/*location: test.dart;p*/.
        C/*location: a.dart;C*/;
const Type vEnum =
        p/*location: test.dart;p*/.
        E/*location: a.dart;E*/;
const Type vFunctionTypeAlias =
        p/*location: test.dart;p*/.
        F/*location: a.dart;F*/;
''');
  }

  test_const_reference_type_typeParameter() async {
    var library = await checkLibrary(r'''
class C<T> {
  final f = <T>[];
}
''');
    checkElementText(library, r'''
class C<T> {
  final List<T> f;
}
''');
  }

  test_const_reference_unresolved_prefix0() async {
    var library = await checkLibrary(r'''
const V = foo;
''', allowErrors: true);
    checkElementText(library, r'''
const dynamic V =
        foo/*location: null*/;
''');
  }

  test_const_reference_unresolved_prefix1() async {
    var library = await checkLibrary(r'''
class C {}
const V = C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
class C {
}
const dynamic V =
        C/*location: test.dart;C*/.
        foo/*location: null*/;
''');
  }

  test_const_reference_unresolved_prefix2() async {
    addLibrarySource('/foo.dart', '''
class C {}
''');
    var library = await checkLibrary(r'''
import 'foo.dart' as p;
const V = p.C.foo;
''', allowErrors: true);
    checkElementText(library, r'''
import 'foo.dart' as p;
const dynamic V =
        p/*location: test.dart;p*/.
        C/*location: foo.dart;C*/.
        foo/*location: null*/;
''');
  }

  test_const_set_if() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>{if (true) 1};
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/>{if (true) 1}/*isSet*/;
''',
        withTypes: true);
  }

  test_const_set_if_else() async {
    experimentStatus = ExperimentStatus(control_flow_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>{if (true) 1 else 2];
''');
    checkElementText(
        library,
        '''
const Object x = const <
        int/*location: dart:core;int*/>{if (true) 1 else 2}/*isSet*/;
''',
        withTypes: true);
  }

  test_const_set_inferredType() async {
    // The summary needs to contain enough information so that when the constant
    // is resynthesized, the constant value can get the type that was computed
    // by type inference.
    var library = await checkLibrary('''
const Object x = const {1};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const /*typeArgs=int*/{1}/*isSet*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>{1}/*isSet*/;
''');
    }
  }

  test_const_set_spread() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>{...<int>{1}};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/>{...<
        int/*location: dart:core;int*/>{1}/*isSet*/}/*isSet*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>{...const <
        int/*location: dart:core;int*/>{1}/*isSet*/}/*isSet*/;
''');
    }
  }

  test_const_set_spread_null_aware() async {
    experimentStatus = ExperimentStatus(spread_collections: true);
    var library = await checkLibrary('''
const Object x = const <int>{...?<int>{1}};
''');
    if (isAstBasedSummary) {
      checkElementText(
          library,
          '''
const Object x = const <
        int/*location: dart:core;int*/>{...?<
        int/*location: dart:core;int*/>{1}/*isSet*/}/*isSet*/;
''',
          withTypes: true);
    } else {
      checkElementText(library, '''
const Object x = const <
        int/*location: dart:core;int*/>{...?const <
        int/*location: dart:core;int*/>{1}/*isSet*/}/*isSet*/;
''');
    }
  }

  test_const_topLevel_binary() async {
    var library = await checkLibrary(r'''
const vEqual = 1 == 2;
const vAnd = true && false;
const vOr = false || true;
const vBitXor = 1 ^ 2;
const vBitAnd = 1 & 2;
const vBitOr = 1 | 2;
const vBitShiftLeft = 1 << 2;
const vBitShiftRight = 1 >> 2;
const vAdd = 1 + 2;
const vSubtract = 1 - 2;
const vMiltiply = 1 * 2;
const vDivide = 1 / 2;
const vFloorDivide = 1 ~/ 2;
const vModulo = 1 % 2;
const vGreater = 1 > 2;
const vGreaterEqual = 1 >= 2;
const vLess = 1 < 2;
const vLessEqual = 1 <= 2;
''');
    checkElementText(library, r'''
const bool vEqual = 1 == 2;
const bool vAnd = true && false;
const bool vOr = false || true;
const int vBitXor = 1 ^ 2;
const int vBitAnd = 1 & 2;
const int vBitOr = 1 | 2;
const int vBitShiftLeft = 1 << 2;
const int vBitShiftRight = 1 >> 2;
const int vAdd = 1 + 2;
const int vSubtract = 1 - 2;
const int vMiltiply = 1 * 2;
const double vDivide = 1 / 2;
const int vFloorDivide = 1 ~/ 2;
const int vModulo = 1 % 2;
const bool vGreater = 1 > 2;
const bool vGreaterEqual = 1 >= 2;
const bool vLess = 1 < 2;
const bool vLessEqual = 1 <= 2;
''');
  }

  test_const_topLevel_conditional() async {
    var library = await checkLibrary(r'''
const vConditional = (1 == 2) ? 11 : 22;
''');
    if (isAstBasedSummary) {
      checkElementText(library, r'''
const int vConditional = (1 == 2) ? 11 : 22;
''');
    } else {
      checkElementText(library, r'''
const int vConditional = 1 == 2 ? 11 : 22;
''');
    }
  }

  test_const_topLevel_identical() async {
    var library = await checkLibrary(r'''
const vIdentical = (1 == 2) ? 11 : 22;
''');
    if (isAstBasedSummary) {
      checkElementText(library, r'''
const int vIdentical = (1 == 2) ? 11 : 22;
''');
    } else {
      checkElementText(library, r'''
const int vIdentical = 1 == 2 ? 11 : 22;
''');
    }
  }

  test_const_topLevel_ifNull() async {
    var library = await checkLibrary(r'''
const vIfNull = 1 ?? 2.0;
''');
    checkElementText(library, r'''
const num vIfNull = 1 ?? 2.0;
''');
  }

  test_const_topLevel_literal() async {
    var library = await checkLibrary(r'''
const vNull = null;
const vBoolFalse = false;
const vBoolTrue = true;
const vInt = 1;
const vIntLong1 = 0x7FFFFFFFFFFFFFFF;
const vIntLong2 = 0xFFFFFFFFFFFFFFFF;
const vDouble = 2.3;
const vString = 'abc';
const vStringConcat = 'aaa' 'bbb';
const vStringInterpolation = 'aaa ${true} ${42} bbb';
const vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
const dynamic vNull = null;
const bool vBoolFalse = false;
const bool vBoolTrue = true;
const int vInt = 1;
const int vIntLong1 = 9223372036854775807;
const int vIntLong2 = -1;
const double vDouble = 2.3;
const String vString = 'abc';
const String vStringConcat = 'aaabbb';
const String vStringInterpolation = 'aaa ${true} ${42} bbb';
const Symbol vSymbol = #aaa.bbb.ccc;
''');
  }

  test_const_topLevel_parenthesis() async {
    var library = await checkLibrary(r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').length;
''');
    checkElementText(library, r'''
const int v1 = (1 + 2) * 3;
const int v2 = -(1 + 2);
const int v3 = ('aaa' + 'bbb').
        length/*location: dart:core;String;length?*/;
''');
  }

  test_const_topLevel_prefix() async {
    var library = await checkLibrary(r'''
const vNotEqual = 1 != 2;
const vNot = !true;
const vNegate = -1;
const vComplement = ~1;
''');
    checkElementText(library, r'''
const bool vNotEqual = 1 != 2;
const bool vNot = !true;
const int vNegate = -1;
const int vComplement = ~1;
''');
  }

  test_const_topLevel_super() async {
    var library = await checkLibrary(r'''
const vSuper = super;
''');
    checkElementText(library, r'''
const dynamic vSuper = super;
''');
  }

  test_const_topLevel_this() async {
    var library = await checkLibrary(r'''
const vThis = this;
''');
    checkElementText(library, r'''
const dynamic vThis = this;
''');
  }

  test_const_topLevel_throw() async {
    var library = await checkLibrary(r'''
const c = throw 42;
''');
    if (isAstBasedSummary) {
      checkElementText(library, r'''
const dynamic c = throw 42;
''');
    } else {
      // This is a bug.
      checkElementText(library, r'''
const dynamic c;
''');
    }
  }

  test_const_topLevel_typedList() async {
    var library = await checkLibrary(r'''
const vNull = const <Null>[];
const vDynamic = const <dynamic>[1, 2, 3];
const vInterfaceNoTypeParameters = const <int>[1, 2, 3];
const vInterfaceNoTypeArguments = const <List>[];
const vInterfaceWithTypeArguments = const <List<String>>[];
const vInterfaceWithTypeArguments2 = const <Map<int, List<String>>>[];
''');
    checkElementText(library, r'''
const List<Null> vNull = const <
        Null/*location: dart:core;Null*/>[];
const List<dynamic> vDynamic = const <
        dynamic/*location: dynamic*/>[1, 2, 3];
const List<int> vInterfaceNoTypeParameters = const <
        int/*location: dart:core;int*/>[1, 2, 3];
const List<List<dynamic>> vInterfaceNoTypeArguments = const <
        List/*location: dart:core;List*/>[];
const List<List<String>> vInterfaceWithTypeArguments = const <
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>[];
const List<Map<int, List<String>>> vInterfaceWithTypeArguments2 = const <
        Map/*location: dart:core;Map*/<
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>>[];
''');
  }

  test_const_topLevel_typedList_imported() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart';
const v = const <C>[];
''');
    checkElementText(library, r'''
import 'a.dart';
const List<C> v = const <
        C/*location: a.dart;C*/>[];
''');
  }

  test_const_topLevel_typedList_importedWithPrefix() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary(r'''
import 'a.dart' as p;
const v = const <p.C>[];
''');
    checkElementText(library, r'''
import 'a.dart' as p;
const List<C> v = const <
        C/*location: a.dart;C*/>[];
''');
  }

  test_const_topLevel_typedList_typedefArgument() async {
    var library = await checkLibrary(r'''
typedef int F(String id);
const v = const <F>[];
''');
    checkElementText(library, r'''
typedef F = int Function(String id);
const List<(String) → int> v = const <
        null/*location: test.dart;F;-*/>[];
''');
  }

  test_const_topLevel_typedMap() async {
    var library = await checkLibrary(r'''
const vDynamic1 = const <dynamic, int>{};
const vDynamic2 = const <int, dynamic>{};
const vInterface = const <int, String>{};
const vInterfaceWithTypeArguments = const <int, List<String>>{};
''');
    checkElementText(library, r'''
const Map<dynamic, int> vDynamic1 = const <
        dynamic/*location: dynamic*/,
        int/*location: dart:core;int*/>{}/*isMap*/;
const Map<int, dynamic> vDynamic2 = const <
        int/*location: dart:core;int*/,
        dynamic/*location: dynamic*/>{}/*isMap*/;
const Map<int, String> vInterface = const <
        int/*location: dart:core;int*/,
        String/*location: dart:core;String*/>{}/*isMap*/;
const Map<int, List<String>> vInterfaceWithTypeArguments = const <
        int/*location: dart:core;int*/,
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>{}/*isMap*/;
''');
  }

  test_const_topLevel_typedSet() async {
    var library = await checkLibrary(r'''
const vDynamic1 = const <dynamic>{};
const vInterface = const <int>{};
const vInterfaceWithTypeArguments = const <List<String>>{};
''');
    checkElementText(library, r'''
const Set<dynamic> vDynamic1 = const <
        dynamic/*location: dynamic*/>{}/*isSet*/;
const Set<int> vInterface = const <
        int/*location: dart:core;int*/>{}/*isSet*/;
const Set<List<String>> vInterfaceWithTypeArguments = const <
        List/*location: dart:core;List*/<
        String/*location: dart:core;String*/>>{}/*isSet*/;
''');
  }

  test_const_topLevel_untypedList() async {
    var library = await checkLibrary(r'''
const v = const [1, 2, 3];
''');
    checkElementText(library, r'''
const List<int> v = const [1, 2, 3];
''');
  }

  test_const_topLevel_untypedMap() async {
    var library = await checkLibrary(r'''
const v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'};
''');
    checkElementText(library, r'''
const Map<int, String> v = const {0: 'aaa', 1: 'bbb', 2: 'ccc'}/*isMap*/;
''');
  }

  test_const_topLevel_untypedSet() async {
    var library = await checkLibrary(r'''
const v = const {0, 1, 2};
''');
    checkElementText(library, r'''
const Set<int> v = const {0, 1, 2}/*isSet*/;
''');
  }

  test_constExpr_pushReference_enum_field() async {
    var library = await checkLibrary('''
enum E {a, b, c}
final vValue = E.a;
final vValues = E.values;
final vIndex = E.a.index;
''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
final E vValue;
final List<E> vValues;
final int vIndex;
''');
  }

  test_constExpr_pushReference_enum_method() async {
    var library = await checkLibrary('''
enum E {a}
final vToString = E.a.toString();
''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  String toString() {}
}
final String vToString;
''');
  }

  test_constExpr_pushReference_field_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = b;
  static const b = null;
}
''');
    checkElementText(library, r'''
class C {
  static const dynamic a =
        C/*location: test.dart;C*/.
        b/*location: test.dart;C;b?*/;
  static const dynamic b = null;
}
''');
  }

  test_constExpr_pushReference_staticMethod_simpleIdentifier() async {
    var library = await checkLibrary('''
class C {
  static const a = m;
  static m() {}
}
''');
    checkElementText(library, r'''
class C {
  static const () → dynamic a =
        C/*location: test.dart;C*/.
        m/*location: test.dart;C;m*/;
  static dynamic m() {}
}
''');
  }

  test_constructor_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  C();
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  C();
}
''');
  }

  test_constructor_initializers_assertInvocation() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42);
}
''');
    checkElementText(library, r'''
class C {
  const C(int x) : assert(
        x/*location: test.dart;C;;x*/ >= 42);
}
''');
  }

  test_constructor_initializers_assertInvocation_message() async {
    var library = await checkLibrary('''
class C {
  const C(int x) : assert(x >= 42, 'foo');
}
''');
    checkElementText(library, r'''
class C {
  const C(int x) : assert(
        x/*location: test.dart;C;;x*/ >= 42, 'foo');
}
''');
  }

  test_constructor_initializers_field() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = 42;
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ = 42;
}
''');
  }

  test_constructor_initializers_field_notConst() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = foo();
}
int foo() => 42;
''', allowErrors: true);
    // It is OK to keep non-constant initializers.
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ =
        foo/*location: test.dart;foo*/();
}
int foo() {}
''');
  }

  test_constructor_initializers_field_withParameter() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C(int p) : x = 1 + p;
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C(int p) :
        x/*location: test.dart;C;x*/ = 1 +
        p/*location: test.dart;C;;p*/;
}
''');
  }

  test_constructor_initializers_superInvocation_named() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.aaa(42);
}
''');
    checkElementText(library, r'''
class A {
  const A.aaa(int p);
}
class C extends A {
  const C() : super.
        aaa/*location: test.dart;A;aaa*/(42);
}
''');
  }

  test_constructor_initializers_superInvocation_named_underscore() async {
    var library = await checkLibrary('''
class A {
  const A._();
}
class B extends A {
  const B() : super._();
}
''');
    checkElementText(library, r'''
class A {
  const A._();
}
class B extends A {
  const B() : super.
        _/*location: test.dart;A;_*/();
}
''');
  }

  test_constructor_initializers_superInvocation_namedExpression() async {
    var library = await checkLibrary('''
class A {
  const A.aaa(a, {int b});
}
class C extends A {
  const C() : super.aaa(1, b: 2);
}
''');
    checkElementText(library, r'''
class A {
  const A.aaa(dynamic a, {int b});
}
class C extends A {
  const C() : super.
        aaa/*location: test.dart;A;aaa*/(1,
        b/*location: null*/: 2);
}
''');
  }

  test_constructor_initializers_superInvocation_unnamed() async {
    var library = await checkLibrary('''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
    checkElementText(library, r'''
class A {
  const A(int p);
}
class C extends A {
  const C.ccc() : super(42);
}
''');
  }

  test_constructor_initializers_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, 'bbb');
  const C.named(int a, String b);
}
''');
    checkElementText(library, r'''
class C {
  const C() = C.named : this.
        named/*location: test.dart;C;named*/(1, 'bbb');
  const C.named(int a, String b);
}
''');
  }

  test_constructor_initializers_thisInvocation_namedExpression() async {
    var library = await checkLibrary('''
class C {
  const C() : this.named(1, b: 2);
  const C.named(a, {int b});
}
''');
    checkElementText(library, r'''
class C {
  const C() = C.named : this.
        named/*location: test.dart;C;named*/(1,
        b/*location: null*/: 2);
  const C.named(dynamic a, {int b});
}
''');
  }

  test_constructor_initializers_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  const C.named() : this(1, 'bbb');
  const C(int a, String b);
}
''');
    checkElementText(library, r'''
class C {
  const C.named() = C : this(1, 'bbb');
  const C(int a, String b);
}
''');
  }

  test_constructor_redirected_factory_named() async {
    var library = await checkLibrary('''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
class C {
  factory C() = D.named;
  C._();
}
class D extends C {
  D.named();
}
''');
  }

  test_constructor_redirected_factory_named_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    checkElementText(library, r'''
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
class D<T, U> extends C<U, T> {
  D.named();
}
''');
  }

  test_constructor_redirected_factory_named_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C {
  factory C() = D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C {
  factory C() = D.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D.named() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>.named;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = D<U, T>.named;
  C._();
}
''');
  }

  test_constructor_redirected_factory_named_unresolved_class() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_factory_named_unresolved_constructor() async {
    var library = await checkLibrary('''
class D {}
class C<E> {
  factory C() = D.named<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class D {
}
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_factory_unnamed() async {
    var library = await checkLibrary('''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D() : super._();
}
''');
    checkElementText(library, r'''
class C {
  factory C() = D;
  C._();
}
class D extends C {
  D();
}
''');
  }

  test_constructor_redirected_factory_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    checkElementText(library, r'''
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
class D<T, U> extends C<U, T> {
  D();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C {
  factory C() = D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_imported_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart';
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D extends C {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C {
  factory C() = foo.D;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C {
  factory C() = D;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_prefixed_generic() async {
    addLibrarySource('/foo.dart', '''
import 'test.dart';
class D<T, U> extends C<U, T> {
  D() : super._();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = foo.D<U, T>;
  C._();
}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
class C<T, U> {
  factory C() = D<U, T>;
  C._();
}
''');
  }

  test_constructor_redirected_factory_unnamed_unresolved() async {
    var library = await checkLibrary('''
class C<E> {
  factory C() = D<E>;
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<E> {
  factory C();
}
''');
  }

  test_constructor_redirected_thisInvocation_named() async {
    var library = await checkLibrary('''
class C {
  C.named();
  C() : this.named();
}
''');
    checkElementText(library, r'''
class C {
  C.named();
  C() = C.named;
}
''');
  }

  test_constructor_redirected_thisInvocation_named_generic() async {
    var library = await checkLibrary('''
class C<T> {
  C.named();
  C() : this.named();
}
''');
    checkElementText(library, r'''
class C<T> {
  C.named();
  C() = C<T>.named;
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed() async {
    var library = await checkLibrary('''
class C {
  C();
  C.named() : this();
}
''');
    checkElementText(library, r'''
class C {
  C();
  C.named() = C;
}
''');
  }

  test_constructor_redirected_thisInvocation_unnamed_generic() async {
    var library = await checkLibrary('''
class C<T> {
  C();
  C.named() : this();
}
''');
    checkElementText(library, r'''
class C<T> {
  C();
  C.named() = C<T>;
}
''');
  }

  test_constructor_withCycles_const() async {
    var library = await checkLibrary('''
class C {
  final x;
  const C() : x = const D();
}
class D {
  final x;
  const D() : x = const C();
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  const C() :
        x/*location: test.dart;C;x*/ = const
        D/*location: test.dart;D*/();
}
class D {
  final dynamic x;
  const D() :
        x/*location: test.dart;D;x*/ = const
        C/*location: test.dart;C*/();
}
''');
  }

  test_constructor_withCycles_nonConst() async {
    var library = await checkLibrary('''
class C {
  final x;
  C() : x = new D();
}
class D {
  final x;
  D() : x = new C();
}
''');
    checkElementText(library, r'''
class C {
  final dynamic x;
  C();
}
class D {
  final dynamic x;
  D();
}
''');
  }

  test_defaultValue_genericFunction() async {
    var library = await checkLibrary('''
typedef void F<T>(T v);

void defaultF<T>(T v) {}

class X {
  final F f;
  const X({this.f: defaultF});
}
''');
    checkElementText(library, r'''
typedef F<T> = void Function(T v);
class X {
  final (dynamic) → void f;
  const X({(dynamic) → void this.f:
        defaultF/*location: test.dart;defaultF*/});
}
void defaultF<T>(T v) {}
''');
  }

  test_defaultValue_refersToGenericClass_constructor() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const B()]);
}
''');
    checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  const C([B<T> b = const
        B/*location: test.dart;B*/()]);
}
''');
  }

  test_defaultValue_refersToGenericClass_constructor2() async {
    var library = await checkLibrary('''
abstract class A<T> {}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const B()]);
}
''');
    checkElementText(library, r'''
abstract class A<T> {
}
class B<T> implements A<T> {
  const B();
}
class C<T> implements A<Iterable<T>> {
  const C([A<T> a = const
        B/*location: test.dart;B*/()]);
}
''');
  }

  test_defaultValue_refersToGenericClass_functionG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const B()]) {}
''');
    checkElementText(library, r'''
class B<T> {
  const B();
}
void foo<T>([B<T> b = const
        B/*location: test.dart;B*/()]) {}
''');
  }

  test_defaultValue_refersToGenericClass_methodG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
class B<T> {
  const B();
}
class C {
  void foo<T>([B<T> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
  }

  test_defaultValue_refersToGenericClass_methodG_classG() async {
    var library = await checkLibrary('''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const B()]) {}
}
''');
    checkElementText(library, r'''
class B<T1, T2> {
  const B();
}
class C<E1> {
  void foo<E2>([B<E1, E2> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
  }

  test_defaultValue_refersToGenericClass_methodNG() async {
    var library = await checkLibrary('''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const B()]) {}
}
''');
    checkElementText(library, r'''
class B<T> {
  const B();
}
class C<T> {
  void foo([B<T> b = const
        B/*location: test.dart;B*/()]) {}
}
''');
  }

  test_enum_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
enum E { v }''');
    checkElementText(library, r'''
/**
 * Docs
 */
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
''');
  }

  test_enum_value_documented() async {
    var library = await checkLibrary('''
enum E {
  /**
   * aaa
   */
  a,
  /// bbb
  b
}''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  /**
   * aaa
   */
  static const E a;
  /// bbb
  static const E b;
  String toString() {}
}
''');
  }

  test_enum_values() async {
    var library = await checkLibrary('enum E { v1, v2 }');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v1;
  static const E v2;
  String toString() {}
}
''');
  }

  test_enums() async {
    var library = await checkLibrary('enum E1 { v1 } enum E2 { v2 }');
    checkElementText(library, r'''
enum E1 {
  synthetic final int index;
  synthetic static const List<E1> values;
  static const E1 v1;
  String toString() {}
}
enum E2 {
  synthetic final int index;
  synthetic static const List<E2> values;
  static const E2 v2;
  String toString() {}
}
''');
  }

  test_error_extendsEnum() async {
    var library = await checkLibrary('''
enum E {a, b, c}

class M {}

class A extends E {
  foo() {}
}

class B implements E, M {
  foo() {}
}

class C extends Object with E, M {
  foo() {}
}

class D = Object with M, E;
''');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E a;
  static const E b;
  static const E c;
  String toString() {}
}
class M {
}
class A {
  dynamic foo() {}
}
class B implements M {
  dynamic foo() {}
}
class C extends Object with M {
  synthetic C();
  dynamic foo() {}
}
class alias D extends Object with M {
  synthetic D() = Object;
}
''');
  }

  test_executable_parameter_type_typedef() async {
    var library = await checkLibrary(r'''
typedef F(int p);
main(F f) {}
''');
    checkElementText(library, r'''
typedef F = dynamic Function(int p);
dynamic main((int) → dynamic f) {}
''');
  }

  test_export_class() async {
    addLibrarySource('/a.dart', 'class C {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_class_type_alias() async {
    addLibrarySource('/a.dart', r'''
class C = _D with _E;
class _D {}
class _E {}
''');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_configurations_useDefault() async {
    declaredVariables =
        new DeclaredVariables.fromMap({'dart.library.io': 'false'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo.dart';
''');
    expect(library.exports[0].exportedLibrary.source.shortName, 'foo.dart');
  }

  test_export_configurations_useFirst() async {
    declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'true', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo_io.dart';
''');
    expect(library.exports[0].exportedLibrary.source.shortName, 'foo_io.dart');
  }

  test_export_configurations_useSecond() async {
    declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'false', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    checkElementText(library, r'''
export 'foo_html.dart';
''');
    ExportElement export = library.exports[0];
    expect(export.exportedLibrary.source.shortName, 'foo_html.dart');
  }

  test_export_function() async {
    addLibrarySource('/a.dart', 'f() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_getter() async {
    addLibrarySource('/a.dart', 'get f() => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_hide() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream, Future;');
    checkElementText(library, r'''
export 'dart:async' hide Stream, Future;
''');
  }

  test_export_multiple_combinators() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" hide Stream show Future;');
    checkElementText(library, r'''
export 'dart:async' hide Stream show Future;
''');
  }

  test_export_setter() async {
    addLibrarySource('/a.dart', 'void set f(value) {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_show() async {
    addLibrary('dart:async');
    var library =
        await checkLibrary('export "dart:async" show Future, Stream;');
    checkElementText(library, r'''
export 'dart:async' show Future, Stream;
''');
  }

  test_export_typedef() async {
    addLibrarySource('/a.dart', 'typedef F();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable() async {
    addLibrarySource('/a.dart', 'var x;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable_const() async {
    addLibrarySource('/a.dart', 'const x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_export_variable_final() async {
    addLibrarySource('/a.dart', 'final x = 0;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_exportImport_configurations_useDefault() async {
    declaredVariables =
        new DeclaredVariables.fromMap({'dart.library.io': 'false'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
import 'bar.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_exportImport_configurations_useFirst() async {
    declaredVariables = new DeclaredVariables.fromMap(
        {'dart.library.io': 'true', 'dart.library.html': 'true'});
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    addLibrarySource('/bar.dart', r'''
export 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    var library = await checkLibrary(r'''
import 'bar.dart';
class B extends A {}
''');
    checkElementText(library, r'''
import 'bar.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_exports() async {
    addLibrarySource('/a.dart', 'library a;');
    addLibrarySource('/b.dart', 'library b;');
    var library = await checkLibrary('export "a.dart"; export "b.dart";');
    checkElementText(library, r'''
export 'a.dart';
export 'b.dart';
''');
  }

  test_expr_invalid_typeParameter_asPrefix() async {
    var library = await checkLibrary('''
class C<T> {
  final f = T.k;
}
''');
    checkElementText(library, r'''
class C<T> {
  final dynamic f;
}
''');
  }

  test_field_covariant() async {
    var library = await checkLibrary('''
class C {
  covariant int x;
}''');
    checkElementText(library, r'''
class C {
  covariant int x;
}
''');
  }

  test_field_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  var x;
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  dynamic x;
}
''');
  }

  test_field_formal_param_inferred_type_implicit() async {
    var library = await checkLibrary('class C extends D { var v; C(this.v); }'
        ' abstract class D { int get v; }');
    checkElementText(library, r'''
class C extends D {
  int v;
  C(int this.v);
}
abstract class D {
  int get v;
}
''');
  }

  test_field_inferred_type_nonStatic_explicit_initialized() async {
    var library = await checkLibrary('class C { num v = 0; }');
    checkElementText(library, r'''
class C {
  num v;
}
''');
  }

  test_field_inferred_type_nonStatic_implicit_initialized() async {
    var library = await checkLibrary('class C { var v = 0; }');
    checkElementText(library, r'''
class C {
  int v;
}
''');
  }

  test_field_inferred_type_nonStatic_implicit_uninitialized() async {
    var library = await checkLibrary(
        'class C extends D { var v; } abstract class D { int get v; }');
    checkElementText(library, r'''
class C extends D {
  int v;
}
abstract class D {
  int get v;
}
''');
  }

  test_field_inferred_type_static_implicit_initialized() async {
    var library = await checkLibrary('class C { static var v = 0; }');
    checkElementText(library, r'''
class C {
  static int v;
}
''');
  }

  test_field_propagatedType_const_noDep() async {
    var library = await checkLibrary('''
class C {
  static const x = 0;
}''');
    checkElementText(library, r'''
class C {
  static const int x = 0;
}
''');
  }

  test_field_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('''
import "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
import 'a.dart';
class C {
  final double b;
}
''');
  }

  test_field_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library = await checkLibrary('''
library lib;
part "a.dart";
class C {
  final b = a / 2;
}''');
    checkElementText(library, r'''
library lib;
part 'a.dart';
class C {
  final double b;
}
--------------------
unit: a.dart

final int a;
''');
  }

  test_field_propagatedType_final_noDep_instance() async {
    var library = await checkLibrary('''
class C {
  final x = 0;
}''');
    checkElementText(library, r'''
class C {
  final int x;
}
''');
  }

  test_field_propagatedType_final_noDep_static() async {
    var library = await checkLibrary('''
class C {
  static final x = 0;
}''');
    checkElementText(library, r'''
class C {
  static final int x;
}
''');
  }

  test_field_static_final_untyped() async {
    var library = await checkLibrary('class C { static final x = 0; }');
    checkElementText(library, r'''
class C {
  static final int x;
}
''');
  }

  test_field_typed() async {
    var library = await checkLibrary('class C { int x = 0; }');
    checkElementText(library, r'''
class C {
  int x;
}
''');
  }

  test_field_untyped() async {
    var library = await checkLibrary('class C { var x = 0; }');
    checkElementText(library, r'''
class C {
  int x;
}
''');
  }

  test_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Future f() async {}
''');
    checkElementText(library, r'''
import 'dart:async';
Future<dynamic> f() async {}
''');
  }

  test_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
Stream f() async* {}
''');
    checkElementText(library, r'''
import 'dart:async';
Stream<dynamic> f() async* {}
''');
  }

  test_function_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
f() {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic f() {}
''');
  }

  test_function_entry_point() async {
    var library = await checkLibrary('main() {}');
    checkElementText(library, r'''
dynamic main() {}
''');
  }

  test_function_entry_point_in_export() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_function_entry_point_in_export_hidden() async {
    addLibrarySource('/a.dart', 'library a; main() {}');
    var library = await checkLibrary('export "a.dart" hide main;');
    checkElementText(library, r'''
export 'a.dart' hide main;
''');
  }

  test_function_entry_point_in_part() async {
    addSource('/a.dart', 'part of my.lib; main() {}');
    var library = await checkLibrary('library my.lib; part "a.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
--------------------
unit: a.dart

dynamic main() {}
''');
  }

  test_function_external() async {
    var library = await checkLibrary('external f();');
    checkElementText(library, r'''
external dynamic f() {}
''');
  }

  test_function_parameter_final() async {
    var library = await checkLibrary('f(final x) {}');
    checkElementText(library, r'''
dynamic f(final dynamic x) {}
''');
  }

  test_function_parameter_kind_named() async {
    var library = await checkLibrary('f({x}) {}');
    checkElementText(library, r'''
dynamic f({dynamic x}) {}
''');
  }

  test_function_parameter_kind_positional() async {
    var library = await checkLibrary('f([x]) {}');
    checkElementText(library, r'''
dynamic f([dynamic x]) {}
''');
  }

  test_function_parameter_kind_required() async {
    var library = await checkLibrary('f(x) {}');
    checkElementText(library, r'''
dynamic f(dynamic x) {}
''');
  }

  test_function_parameter_parameters() async {
    var library = await checkLibrary('f(g(x, y)) {}');
    checkElementText(library, r'''
dynamic f((dynamic, dynamic) → dynamic g) {}
''');
  }

  test_function_parameter_return_type() async {
    var library = await checkLibrary('f(int g()) {}');
    checkElementText(library, r'''
dynamic f(() → int g) {}
''');
  }

  test_function_parameter_return_type_void() async {
    var library = await checkLibrary('f(void g()) {}');
    checkElementText(library, r'''
dynamic f(() → void g) {}
''');
  }

  test_function_parameter_type() async {
    var library = await checkLibrary('f(int i) {}');
    checkElementText(library, r'''
dynamic f(int i) {}
''');
  }

  test_function_parameters() async {
    var library = await checkLibrary('f(x, y) {}');
    checkElementText(library, r'''
dynamic f(dynamic x, dynamic y) {}
''');
  }

  test_function_return_type() async {
    var library = await checkLibrary('int f() => null;');
    checkElementText(library, r'''
int f() {}
''');
  }

  test_function_return_type_implicit() async {
    var library = await checkLibrary('f() => null;');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_function_return_type_void() async {
    var library = await checkLibrary('void f() {}');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_function_type_parameter() async {
    var library = await checkLibrary('T f<T, U>(U u) => null;');
    checkElementText(library, r'''
T f<T, U>(U u) {}
''');
  }

  test_function_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('void f<T, U>(T x(U u)) {}');
    checkElementText(library, r'''
void f<T, U>((U) → T x) {}
''');
  }

  test_function_typed_parameter_implicit() async {
    var library = await checkLibrary('f(g()) => null;');
    expect(
        library
            .definingCompilationUnit.functions[0].parameters[0].hasImplicitType,
        isFalse);
  }

  test_functions() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
dynamic f() {}
dynamic g() {}
''');
  }

  test_futureOr() async {
    var library = await checkLibrary('import "dart:async"; FutureOr<int> x;');
    checkElementText(library, r'''
import 'dart:async';
FutureOr<int> x;
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    expect(variables[0].type.toString(), 'FutureOr<int>');
  }

  test_futureOr_const() async {
    var library =
        await checkLibrary('import "dart:async"; const x = FutureOr;');
    checkElementText(library, r'''
import 'dart:async';
const Type x =
        FutureOr/*location: dart:async;FutureOr*/;
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(1));
    var x = variables[0] as ConstTopLevelVariableElementImpl;
    expect(x.type.toString(), 'Type');
    expect(x.constantInitializer.toString(), 'FutureOr');
  }

  test_futureOr_inferred() async {
    var library = await checkLibrary('''
import "dart:async";
FutureOr<int> f() => null;
var x = f();
var y = x.then((z) => z.asDouble());
''');
    checkElementText(library, r'''
import 'dart:async';
FutureOr<int> x;
dynamic y;
FutureOr<int> f() {}
''');
    var variables = library.definingCompilationUnit.topLevelVariables;
    expect(variables, hasLength(2));
    var x = variables[0];
    expect(x.name, 'x');
    var y = variables[1];
    expect(y.name, 'y');
    expect(x.type.toString(), 'FutureOr<int>');
    expect(y.type.toString(), 'dynamic');
  }

  test_generic_gClass_gMethodStatic() async {
    var library = await checkLibrary('''
class C<T, U> {
  static void m<V, W>(V v, W w) {
    void f<X, Y>(V v, W w, X x, Y y) {
    }
  }
}
''');
    checkElementText(library, r'''
class C<T, U> {
  static void m<V, W>(V v, W w) {}
}
''');
  }

  test_genericFunction_asFunctionReturnType() async {
    var library = await checkLibrary(r'''
int Function(int a, String b) f() => null;
''');
    checkElementText(library, r'''
(int, String) → int f() {}
''');
  }

  test_genericFunction_asFunctionTypedParameterReturnType() async {
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p(num c)) => null;
''');
    checkElementText(library, r'''
void f((num) → (int, String) → int p) {}
''');
  }

  test_genericFunction_asGenericFunctionReturnType() async {
    var library = await checkLibrary(r'''
typedef F = void Function(String a) Function(int b);
''');
    checkElementText(library, r'''
typedef F = (String) → void Function(int b);
''');
  }

  test_genericFunction_asMethodReturnType() async {
    var library = await checkLibrary(r'''
class C {
  int Function(int a, String b) m() => null;
}
''');
    checkElementText(library, r'''
class C {
  (int, String) → int m() {}
}
''');
  }

  test_genericFunction_asParameterType() async {
    var library = await checkLibrary(r'''
void f(int Function(int a, String b) p) => null;
''');
    checkElementText(library, r'''
void f((int, String) → int p) {}
''');
  }

  test_genericFunction_asTopLevelVariableType() async {
    var library = await checkLibrary(r'''
int Function(int a, String b) v;
''');
    checkElementText(library, r'''
(int, String) → int v;
''');
  }

  test_getter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
get x => null;''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic get x {}
''');
  }

  test_getter_external() async {
    var library = await checkLibrary('external int get x;');
    checkElementText(library, r'''
external int get x;
''');
  }

  test_getter_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary(
        'class C extends D { get f => null; } abstract class D { int get f; }');
    checkElementText(library, r'''
class C extends D {
  int get f {}
}
abstract class D {
  int get f;
}
''');
  }

  test_getters() async {
    var library = await checkLibrary('int get x => null; get y => null;');
    checkElementText(library, r'''
int get x {}
dynamic get y {}
''');
  }

  @failingTest
  test_implicitConstructor_named_const() async {
    // TODO(paulberry, scheglov): get this to pass
    var library = await checkLibrary('''
class C {
  final Object x;
  const C.named(this.x);
}
const x = C.named(42);
''');
    checkElementText(library, 'TODO(paulberry, scheglov)');
  }

  test_implicitTopLevelVariable_getterFirst() async {
    var library =
        await checkLibrary('int get x => 0; void set x(int value) {}');
    checkElementText(library, r'''
int get x {}
void set x(int value) {}
''');
  }

  test_implicitTopLevelVariable_setterFirst() async {
    var library =
        await checkLibrary('void set x(int value) {} int get x => 0;');
    checkElementText(library, r'''
void set x(int value) {}
int get x {}
''');
  }

  test_import_configurations_useDefault() async {
    declaredVariables = new DeclaredVariables.fromMap({
      'dart.library.io': 'false',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
import 'foo.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo.dart');
  }

  test_import_configurations_useFirst() async {
    declaredVariables = new DeclaredVariables.fromMap({
      'dart.library.io': 'true',
      'dart.library.html': 'true',
    });
    addLibrarySource('/foo.dart', 'class A {}');
    addLibrarySource('/foo_io.dart', 'class A {}');
    addLibrarySource('/foo_html.dart', 'class A {}');
    var library = await checkLibrary(r'''
import 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';

class B extends A {}
''');
    checkElementText(library, r'''
import 'foo_io.dart';
class B extends A {
}
''');
    var typeA = library.definingCompilationUnit.getType('B').supertype;
    expect(typeA.element.source.shortName, 'foo_io.dart');
  }

  test_import_deferred() async {
    addLibrarySource('/a.dart', 'f() {}');
    var library = await checkLibrary('''
import 'a.dart' deferred as p;
main() {
  p.f();
  }
''');
    checkElementText(library, r'''
import 'a.dart' deferred as p;
dynamic main() {}
''');
  }

  test_import_export() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import 'dart:async' as i1;
export 'dart:math';
import 'dart:async' as i2;
export 'dart:math';
import 'dart:async' as i3;
export 'dart:math';
''');
    checkElementText(library, r'''
import 'dart:async' as i1;
import 'dart:async' as i2;
import 'dart:async' as i3;
export 'dart:math';
export 'dart:math';
export 'dart:math';
''');
  }

  test_import_hide() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import 'dart:async' hide Stream, Completer; Future f;
''');
    checkElementText(library, r'''
import 'dart:async' hide Stream, Completer;
Future<dynamic> f;
''');
  }

  test_import_invalidUri_metadata() async {
    allowMissingFiles = true;
    var library = await checkLibrary('''
@foo
import '';
''');
    checkElementText(library, r'''
@
        foo/*location: null*/
import '<unresolved>';
''');
  }

  test_import_multiple_combinators() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" hide Stream show Future;
Future f;
''');
    checkElementText(library, r'''
import 'dart:async' hide Stream show Future;
Future<dynamic> f;
''');
  }

  test_import_prefixed() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    var library = await checkLibrary('import "a.dart" as a; a.C c;');

    expect(library.imports[0].prefix.nameOffset, 19);
    expect(library.imports[0].prefix.nameLength, 1);

    checkElementText(library, r'''
import 'a.dart' as a;
C c;
''');
  }

  test_import_self() async {
    var library = await checkLibrary('''
import 'test.dart' as p;
class C {}
class D extends p.C {} // Prevent "unused import" warning
''');
    expect(library.imports, hasLength(2));
    expect(library.imports[0].importedLibrary.location, library.location);
    expect(library.imports[1].importedLibrary.isDartCore, true);
    checkElementText(library, r'''
import 'test.dart' as p;
class C {
}
class D extends C {
}
''');
  }

  test_import_short_absolute() async {
    testFile = '/my/project/bin/test.dart';
    // Note: "/a.dart" resolves differently on Windows vs. Posix.
    var destinationPath =
        resourceProvider.pathContext.fromUri(Uri.parse('/a.dart'));
    addLibrarySource(destinationPath, 'class C {}');
    var library = await checkLibrary('import "/a.dart"; C c;');
    checkElementText(library, r'''
import 'a.dart';
C c;
''');
  }

  test_import_show() async {
    addLibrary('dart:async');
    var library = await checkLibrary('''
import "dart:async" show Future, Stream;
Future f;
Stream s;
''');
    checkElementText(library, r'''
import 'dart:async' show Future, Stream;
Future<dynamic> f;
Stream<dynamic> s;
''');
  }

  test_imports() async {
    addLibrarySource('/a.dart', 'library a; class C {}');
    addLibrarySource('/b.dart', 'library b; class D {}');
    var library =
        await checkLibrary('import "a.dart"; import "b.dart"; C c; D d;');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
C c;
D d;
''');
  }

  @failingTest
  void test_infer_generic_typedef_complex() async {
    // TODO(paulberry, scheglov): get this test to pass.
    var library = await checkLibrary('''
typedef F<T> = D<T,U> Function<U>();
class C<V> {
  const C(F<V> f);
}
class D<T,U> {}
D<int,U> f<U>() => null;
const x = const C(f);
''');
    checkElementText(library, '''TODO(paulberry, scheglov)''');
  }

  void test_infer_generic_typedef_simple() async {
    var library = await checkLibrary('''
typedef F = D<T> Function<T>();
class C {
  const C(F f);
}
class D<T> {}
D<T> f<T>() => null;
const x = const C(f);
''');
    checkElementText(library, '''
typedef F = D<T> Function<T>();
class C {
  const C(<T>() → D<T> f);
}
class D<T> {
}
const C x = const
        C/*location: test.dart;C*/(
        f/*location: test.dart;f*/);
D<T> f<T>() {}
''');
  }

  test_infer_instanceCreation_fromArguments() async {
    var library = await checkLibrary('''
class A {}

class B extends A {}

class S<T extends A> {
  S(T _);
}

var s = new S(new B());
''');
    checkElementText(library, '''
class A {
}
class B extends A {
}
class S<T extends A> {
  S(T _);
}
S<B> s;
''');
  }

  test_infer_property_set() async {
    var library = await checkLibrary('''
class A {
  B b;
}
class B {
  C get c => null;
  void set c(C value) {}
}
class C {}
class D extends C {}
var a = new A();
var x = a.b.c ??= new D();
''');
    checkElementText(library, '''
class A {
  B b;
}
class B {
  C get c {}
  void set c(C value) {}
}
class C {
}
class D extends C {
}
A a;
C x;
''');
  }

  test_inference_issue_32394() async {
    // Test the type inference involed in dartbug.com/32394
    var library = await checkLibrary('''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();
''');
    checkElementText(library, '''
Iterable<String> x;
List<int> y;
List<String> z;
''');
  }

  test_inference_map() async {
    var library = await checkLibrary('''
class C {
  int p;
}
var x = <C>[];
var y = x.map((c) => c.p);
''');
    checkElementText(library, '''
class C {
  int p;
}
List<C> x;
Iterable<int> y;
''');
  }

  test_inferred_function_type_for_variable_in_generic_function() async {
    // In the code below, `x` has an inferred type of `() => int`, with 2
    // (unused) type parameters from the enclosing top level function.
    var library = await checkLibrary('''
f<U, V>() {
  var x = () => 0;
}
''');
    checkElementText(library, r'''
dynamic f<U, V>() {}
''');
  }

  test_inferred_function_type_in_generic_class_constructor() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  final x;
  C() : x = (() => () => 0);
}
''');
    checkElementText(library, r'''
class C<U, V> {
  final dynamic x;
  C();
}
''');
  }

  test_inferred_function_type_in_generic_class_getter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  get x => () => () => 0;
}
''');
    checkElementText(library, r'''
class C<U, V> {
  dynamic get x {}
}
''');
  }

  test_inferred_function_type_in_generic_class_in_generic_method() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters from the enclosing class
    // and method.
    var library = await checkLibrary('''
class C<T> {
  f<U, V>() {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
class C<T> {
  dynamic f<U, V>() {}
}
''');
  }

  test_inferred_function_type_in_generic_class_setter() async {
    // In the code below, `() => () => 0` has an inferred return type of
    // `() => int`, with 2 (unused) type parameters from the enclosing class.
    var library = await checkLibrary('''
class C<U, V> {
  void set x(value) {
    print(() => () => 0);
  }
}
''');
    checkElementText(library, r'''
class C<U, V> {
  void set x(dynamic value) {}
}
''');
  }

  test_inferred_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => () => 0` has an inferred return type of
    // `() => int`, with 3 (unused) type parameters.
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => () => 0);
}
''');
    checkElementText(library, r'''
dynamic f<T>() {}
''');
  }

  test_inferred_generic_function_type_in_generic_closure() async {
    // In the code below, `<U, V>() => <W, X, Y, Z>() => 0` has an inferred
    // return type of `() => int`, with 7 (unused) type parameters.
    var library = await checkLibrary('''
f<T>() {
  print(/*<U, V>*/() => /*<W, X, Y, Z>*/() => 0);
}
''');
    checkElementText(library, r'''
dynamic f<T>() {}
''');
  }

  test_inferred_type_is_typedef() async {
    var library = await checkLibrary('typedef int F(String s);'
        ' class C extends D { var v; }'
        ' abstract class D { F get v; }');
    checkElementText(library, r'''
typedef F = int Function(String s);
class C extends D {
  (String) → int v;
}
abstract class D {
  (String) → int get v;
}
''');
  }

  test_inferred_type_refers_to_bound_type_param() async {
    var library = await checkLibrary('''
class C<T> extends D<int, T> {
  var v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
    checkElementText(library, r'''
class C<T> extends D<int, T> {
  Map<T, int> v;
}
abstract class D<U, V> {
  Map<V, U> get v;
}
''');
  }

  test_inferred_type_refers_to_function_typed_param_of_typedef() async {
    var library = await checkLibrary('''
typedef void F(int g(String s));
h(F f) => null;
var v = h(/*info:INFERRED_TYPE_CLOSURE*/(y) {});
''');
    checkElementText(library, r'''
typedef F = void Function((String) → int g);
dynamic v;
dynamic h(((String) → int) → void f) {}
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> extends D<U, int> {
  void f(int x, g) {}
}
abstract class D<V, W> {
  void f(int x, W g(V s));
}''');
    checkElementText(library, r'''
class C<T, U> extends D<U, int> {
  void f(int x, (U) → int g) {}
}
abstract class D<V, W> {
  void f(int x, (V) → W g);
}
''');
  }

  test_inferred_type_refers_to_function_typed_parameter_type_other_lib() async {
    addLibrarySource('/a.dart', '''
import 'b.dart';
abstract class D extends E {}
''');
    addLibrarySource('/b.dart', '''
abstract class E {
  void f(int x, int g(String s));
}
''');
    var library = await checkLibrary('''
import 'a.dart';
class C extends D {
  void f(int x, g) {}
}
''');
    checkElementText(library, r'''
import 'a.dart';
class C extends D {
  void f(int x, (String) → int g) {}
}
''');
  }

  test_inferred_type_refers_to_method_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void f(int x, g) {} }'
        ' abstract class D { void f(int x, int g(String s)); }');
    checkElementText(library, r'''
class C extends D {
  void f(int x, (String) → int g) {}
}
abstract class D {
  void f(int x, (String) → int g);
}
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param() async {
    var library = await checkLibrary('''
f(void g(int x, void h())) => null;
var v = f((x, y) {});
''');
    checkElementText(library, r'''
dynamic v;
dynamic f((int, () → void) → void g) {}
''');
  }

  test_inferred_type_refers_to_nested_function_typed_param_named() async {
    var library = await checkLibrary('''
f({void g(int x, void h())}) => null;
var v = f(g: (x, y) {});
''');
    checkElementText(library, r'''
dynamic v;
dynamic f({(int, () → void) → void g}) {}
''');
  }

  test_inferred_type_refers_to_setter_function_typed_parameter_type() async {
    var library = await checkLibrary('class C extends D { void set f(g) {} }'
        ' abstract class D { void set f(int g(String s)); }');
    checkElementText(library, r'''
class C extends D {
  void set f((String) → int g) {}
}
abstract class D {
  void set f((String) → int g);
}
''');
  }

  test_inferredType_definedInSdkLibraryPart() async {
    addSource('/a.dart', r'''
import 'dart:async';
class A {
  m(Stream p) {}
}
''');
    LibraryElement library = await checkLibrary(r'''
import 'a.dart';
class B extends A {
  m(p) {}
}
  ''');
    checkElementText(library, r'''
import 'a.dart';
class B extends A {
  dynamic m(Stream<dynamic> p) {}
}
''');
    ClassElement b = library.definingCompilationUnit.types[0];
    ParameterElement p = b.methods[0].parameters[0];
    // This test should verify that we correctly record inferred types,
    // when the type is defined in a part of an SDK library. So, test that
    // the type is actually in a part.
    Element streamElement = p.type.element;
    if (streamElement is ClassElement) {
      expect(streamElement.source, isNot(streamElement.library.source));
    }
  }

  test_inferredType_implicitCreation() async {
    var library = await checkLibrary(r'''
class A {
  A();
  A.named();
}
var a1 = A();
var a2 = A.named();
''');
    checkElementText(library, r'''
class A {
  A();
  A.named();
}
A a1;
A a2;
''');
  }

  test_inferredType_implicitCreation_prefixed() async {
    addLibrarySource('/foo.dart', '''
class A {
  A();
  A.named();
}
''');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
var a1 = foo.A();
var a2 = foo.A.named();
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
A a1;
A a2;
''');
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    // AnalysisContext does not set the enclosing element for the synthetic
    // FunctionElement created for the [f, g] type argument.
    var library = await checkLibrary('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = [f, g];
''');
    checkElementText(library, r'''
List<((String) → int) → Object> v;
int f((String) → int x) {}
String g((String) → int x) {}
''');
  }

  test_inheritance_errors() async {
    var library = await checkLibrary('''
abstract class A {
  int m();
}

abstract class B {
  String m();
}

abstract class C implements A, B {}

abstract class D extends C {
  var f;
}
''');
    checkElementText(library, r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
abstract class C implements A, B {
}
abstract class D extends C {
  dynamic f;
}
''');
  }

  test_initializer_executable_with_return_type_from_closure() async {
    var library = await checkLibrary('var v = () => 0;');
    checkElementText(library, r'''
() → int v;
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_dynamic() async {
    var library = await checkLibrary('var v = (f) async => await f;');
    checkElementText(library, r'''
(dynamic) → Future<dynamic> v;
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future3_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<Future<Future<int>>> f) async => await f;
''');
    // The analyzer type system over-flattens - see dartbug.com/31887
    checkElementText(library, r'''
import 'dart:async';
(Future<Future<Future<int>>>) → Future<int> v;
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_int() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future<int> f) async => await f;
''');
    checkElementText(library, r'''
import 'dart:async';
(Future<int>) → Future<int> v;
''');
  }

  test_initializer_executable_with_return_type_from_closure_await_future_noArg() async {
    var library = await checkLibrary(r'''
import 'dart:async';
var v = (Future f) async => await f;
''');
    checkElementText(library, r'''
import 'dart:async';
(Future<dynamic>) → Future<dynamic> v;
''');
  }

  test_initializer_executable_with_return_type_from_closure_field() async {
    var library = await checkLibrary('''
class C {
  var v = () => 0;
}
''');
    checkElementText(library, r'''
class C {
  () → int v;
}
''');
  }

  test_initializer_executable_with_return_type_from_closure_local() async {
    var library = await checkLibrary('''
void f() {
  int u = 0;
  var v = () => 0;
}
''');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_instantiateToBounds_boundRefersToEarlierTypeArgument() async {
    var library = await checkLibrary('''
class C<S extends num, T extends C<S, T>> {}
C c;
''');
    checkElementText(library, r'''
notSimplyBounded class C<S extends num, T extends C<S, T>> {
}
C<num, C<num, dynamic>> c;
''');
  }

  test_instantiateToBounds_boundRefersToItself() async {
    var library = await checkLibrary('''
class C<T extends C<T>> {}
C c;
var c2 = new C();
class B {
  var c3 = new C();
}
''');
    checkElementText(library, r'''
notSimplyBounded class C<T extends C<T>> {
}
class B {
  C<C<dynamic>> c3;
}
C<C<dynamic>> c;
C<C<dynamic>> c2;
''');
  }

  test_instantiateToBounds_boundRefersToLaterTypeArgument() async {
    var library = await checkLibrary('''
class C<T extends C<T, U>, U extends num> {}
C c;
''');
    checkElementText(library, r'''
notSimplyBounded class C<T extends C<T, U>, U extends num> {
}
C<C<dynamic, num>, num> c;
''');
  }

  test_instantiateToBounds_functionTypeAlias_reexported() async {
    addLibrarySource('/a.dart', r'''
class O {}
typedef T F<T extends O>(T p);
''');
    addLibrarySource('/b.dart', r'''
export 'a.dart' show F;
''');
    var library = await checkLibrary('''
import 'b.dart';
class C {
  F f() => null;
}
''');
    checkElementText(library, r'''
import 'b.dart';
class C {
  (O) → O f() {}
}
''');
  }

  test_instantiateToBounds_functionTypeAlias_simple() async {
    var library = await checkLibrary('''
typedef F<T extends num>(T p);
F f;
''');
    checkElementText(library, r'''
typedef F<T extends num> = dynamic Function(T p);
(num) → dynamic f;
''');
  }

  test_instantiateToBounds_simple() async {
    var library = await checkLibrary('''
class C<T extends num> {}
C c;
''');
    checkElementText(library, r'''
class C<T extends num> {
}
C<num> c;
''');
  }

  test_invalid_annotation_prefixed_constructor() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary('''
import "a.dart" as a;
@a.C.named
class D {}
''');
    checkElementText(library, r'''
import 'a.dart' as a;
@
        a/*location: test.dart;a*/.
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/
class D {
}
''');
  }

  test_invalid_annotation_unprefixed_constructor() async {
    addLibrarySource('/a.dart', r'''
class C {
  const C.named();
}
''');
    var library = await checkLibrary('''
import "a.dart";
@C.named
class D {}
''');
    checkElementText(library, r'''
import 'a.dart';
@
        C/*location: a.dart;C*/.
        named/*location: a.dart;C;named*/
class D {
}
''');
  }

  test_invalid_importPrefix_asTypeArgument() async {
    var library = await checkLibrary('''
import 'dart:async' as ppp;
class C {
  List<ppp> v;
}
''');
    checkElementText(library, r'''
import 'dart:async' as ppp;
class C {
  List<dynamic> v;
}
''');
  }

  test_invalid_nameConflict_imported() async {
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
dynamic foo([dynamic p =
        V/*location: null*/]) {}
''');
  }

  test_invalid_nameConflict_imported_exported() async {
    addLibrarySource('/a.dart', 'V() {}');
    addLibrarySource('/b.dart', 'V() {}');
    addLibrarySource('/c.dart', r'''
export 'a.dart';
export 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
foo([p = V]) {}
''');
    checkElementText(library, r'''
import 'c.dart';
dynamic foo([dynamic p =
        V/*location: null*/]) {}
''');
  }

  test_invalid_nameConflict_local() async {
    var library = await checkLibrary('''
foo([p = V]) {}
V() {}
var V;
''');
    checkElementText(library, r'''
dynamic V;
dynamic foo([dynamic p =
        V/*location: null*/]) {}
dynamic V() {}
''');
  }

  test_invalid_setterParameter_fieldFormalParameter() async {
    var library = await checkLibrary('''
class C {
  int foo;
  void set bar(this.foo) {}
}
''');
    checkElementText(library, r'''
class C {
  int foo;
  void set bar(dynamic this.foo) {}
}
''');
  }

  test_invalid_setterParameter_fieldFormalParameter_self() async {
    var library = await checkLibrary('''
class C {
  set x(this.x) {}
}
''');
    checkElementText(library, r'''
class C {
  void set x(dynamic this.x) {}
}
''');
  }

  test_invalidUri_part_emptyUri() async {
    allowMissingFiles = true;
    var library = await checkLibrary(r'''
part '';
class B extends A {}
''');
    checkElementText(library, r'''
part '<unresolved>';
class B {
}
--------------------
unit: null

''');
  }

  test_invalidUris() async {
    allowMissingFiles = true;
    var library = await checkLibrary(r'''
import ':[invaliduri]';
import ':[invaliduri]:foo.dart';
import 'a1.dart';
import ':[invaliduri]';
import ':[invaliduri]:foo.dart';

export ':[invaliduri]';
export ':[invaliduri]:foo.dart';
export 'a2.dart';
export ':[invaliduri]';
export ':[invaliduri]:foo.dart';

part ':[invaliduri]';
part 'a3.dart';
part ':[invaliduri]';
''');
    checkElementText(library, r'''
import '<unresolved>';
import '<unresolved>';
import 'a1.dart';
import '<unresolved>';
import '<unresolved>';
export '<unresolved>';
export '<unresolved>';
export 'a2.dart';
export '<unresolved>';
export '<unresolved>';
part '<unresolved>';
part 'a3.dart';
part '<unresolved>';
--------------------
unit: null

--------------------
unit: a3.dart

--------------------
unit: null

''');
  }

  test_library() async {
    var library = await checkLibrary('');
    checkElementText(library, r'''
''');
  }

  test_library_documented_lines() async {
    var library = await checkLibrary('''
/// aaa
/// bbb
library test;
''');
    checkElementText(library, r'''
/// aaa
/// bbb
library test;
''');
  }

  test_library_documented_stars() async {
    var library = await checkLibrary('''
/**
 * aaa
 * bbb
 */
library test;''');
    checkElementText(library, r'''
/**
 * aaa
 * bbb
 */
library test;
''');
  }

  test_library_name_with_spaces() async {
    var library = await checkLibrary('library foo . bar ;');
    checkElementText(library, r'''
library foo.bar;
''');
  }

  test_library_named() async {
    var library = await checkLibrary('library foo.bar;');
    checkElementText(library, r'''
library foo.bar;
''');
  }

  test_localFunctions() async {
    var library = await checkLibrary(r'''
f() {
  f1() {}
  {
    f2() {}
  }
}
''');
    checkElementText(library, r'''
dynamic f() {}
''');
  }

  test_localFunctions_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_localFunctions_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    f() {}
  }
}
''');
    checkElementText(library, r'''
class C {
  dynamic m() {}
}
''');
  }

  test_localFunctions_inTopLevelGetter() async {
    var library = await checkLibrary(r'''
get g {
  f() {}
}
''');
    checkElementText(library, r'''
dynamic get g {}
''');
  }

  test_localLabels_inConstructor() async {
    var library = await checkLibrary(r'''
class C {
  C() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  C();
}
''');
  }

  test_localLabels_inMethod() async {
    var library = await checkLibrary(r'''
class C {
  m() {
    aaa: while (true) {}
    bbb: switch (42) {
      ccc: case 0:
        break;
    }
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
class C {
  dynamic m() {}
}
''');
  }

  test_localLabels_inTopLevelFunction() async {
    var library = await checkLibrary(r'''
main() {
  aaa: while (true) {}
  bbb: switch (42) {
    ccc: case 0:
      break;
  }
}
''', allowErrors: true);
    checkElementText(library, r'''
dynamic main() {}
''');
  }

  test_main_class() async {
    var library = await checkLibrary('class main {}');
    checkElementText(library, r'''
class main {
}
''');
  }

  test_main_class_alias() async {
    var library =
        await checkLibrary('class main = C with D; class C {} class D {}');
    checkElementText(library, r'''
class alias main extends C with D {
  synthetic main() = C;
}
class C {
}
class D {
}
''');
  }

  test_main_class_alias_via_export() async {
    addLibrarySource('/a.dart', 'class main = C with D; class C {} class D {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_class_via_export() async {
    addLibrarySource('/a.dart', 'class main {}');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_getter() async {
    var library = await checkLibrary('get main => null;');
    checkElementText(library, r'''
dynamic get main {}
''');
  }

  test_main_getter_via_export() async {
    addLibrarySource('/a.dart', 'get main => null;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_typedef() async {
    var library = await checkLibrary('typedef main();');
    checkElementText(library, r'''
typedef main = dynamic Function();
''');
  }

  test_main_typedef_via_export() async {
    addLibrarySource('/a.dart', 'typedef main();');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_main_variable() async {
    var library = await checkLibrary('var main;');
    checkElementText(library, r'''
dynamic main;
''');
  }

  test_main_variable_via_export() async {
    addLibrarySource('/a.dart', 'var main;');
    var library = await checkLibrary('export "a.dart";');
    checkElementText(library, r'''
export 'a.dart';
''');
  }

  test_member_function_async() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Future f() async {}
}
''');
    checkElementText(library, r'''
import 'dart:async';
class C {
  Future<dynamic> f() async {}
}
''');
  }

  test_member_function_asyncStar() async {
    var library = await checkLibrary(r'''
import 'dart:async';
class C {
  Stream f() async* {}
}
''');
    checkElementText(library, r'''
import 'dart:async';
class C {
  Stream<dynamic> f() async* {}
}
''');
  }

  test_member_function_syncStar() async {
    var library = await checkLibrary(r'''
class C {
  Iterable<int> f() sync* {
    yield 42;
  }
}
''');
    checkElementText(library, r'''
class C {
  Iterable<int> f() sync* {}
}
''');
  }

  test_metadata_classDeclaration() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
@a
@b
class C {}''');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
@
        b/*location: test.dart;b?*/
class C {
}
const dynamic a = null;
const dynamic b = null;
''');
  }

  test_metadata_classTypeAlias() async {
    var library = await checkLibrary(
        'const a = null; @a class C = D with E; class D {} class E {}');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
class alias C extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
const dynamic a = null;
''');
  }

  test_metadata_constructor_call_named() async {
    var library = await checkLibrary('''
class A {
  const A.named();
}
@A.named()
class C {}
''');
    checkElementText(library, r'''
class A {
  const A.named();
}
@
        A/*location: test.dart;A*/.
        named/*location: test.dart;A;named*/()
class C {
}
''');
  }

  test_metadata_constructor_call_named_prefixed() async {
    addLibrarySource('/foo.dart', 'class A { const A.named(); }');
    var library = await checkLibrary('''
import 'foo.dart' as foo;
@foo.A.named()
class C {}
''');
    checkElementText(library, r'''
import 'foo.dart' as foo;
@
        A/*location: foo.dart;A*/.
        named/*location: foo.dart;A;named*/()
class C {
}
''');
  }

  test_metadata_constructor_call_unnamed() async {
    var library = await checkLibrary('class A { const A(); } @A() class C {}');
    checkElementText(library, r'''
class A {
  const A();
}
@
        A/*location: test.dart;A*/()
class C {
}
''');
  }

  test_metadata_constructor_call_unnamed_prefixed() async {
    addLibrarySource('/foo.dart', 'class A { const A(); }');
    var library =
        await checkLibrary('import "foo.dart" as foo; @foo.A() class C {}');
    checkElementText(library, r'''
import 'foo.dart' as foo;
@
        A/*location: foo.dart;A*/()
class C {
}
''');
  }

  test_metadata_constructor_call_with_args() async {
    var library =
        await checkLibrary('class A { const A(x); } @A(null) class C {}');
    checkElementText(library, r'''
class A {
  const A(dynamic x);
}
@
        A/*location: test.dart;A*/(null)
class C {
}
''');
  }

  test_metadata_constructorDeclaration_named() async {
    var library =
        await checkLibrary('const a = null; class C { @a C.named(); }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  C.named();
}
const dynamic a = null;
''');
  }

  test_metadata_constructorDeclaration_unnamed() async {
    var library = await checkLibrary('const a = null; class C { @a C(); }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  C();
}
const dynamic a = null;
''');
  }

  test_metadata_enumConstantDeclaration() async {
    var library = await checkLibrary('const a = null; enum E { @a v }');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  @
        a/*location: test.dart;a?*/
  static const E v;
  String toString() {}
}
const dynamic a = null;
''');
  }

  test_metadata_enumDeclaration() async {
    var library = await checkLibrary('const a = null; @a enum E { v }');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
const dynamic a = null;
''');
  }

  test_metadata_exportDirective() async {
    addLibrarySource('/foo.dart', '');
    var library = await checkLibrary('@a export "foo.dart"; const a = null;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
export 'foo.dart';
const dynamic a = null;
''');
  }

  test_metadata_fieldDeclaration() async {
    var library = await checkLibrary('const a = null; class C { @a int x; }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  int x;
}
const dynamic a = null;
''');
  }

  test_metadata_fieldFormalParameter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  var x;
  C(@a this.x);
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C(@
        a/*location: test.dart;a?*/ dynamic this.x);
}
const dynamic a = null;
''');
  }

  test_metadata_fieldFormalParameter_withDefault() async {
    var library = await checkLibrary(
        'const a = null; class C { var x; C([@a this.x = null]); }');
    checkElementText(library, r'''
class C {
  dynamic x;
  C([@
        a/*location: test.dart;a?*/ dynamic this.x = null]);
}
const dynamic a = null;
''');
  }

  test_metadata_functionDeclaration_function() async {
    var library = await checkLibrary('''
const a = null;
@a
f() {}
''');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
dynamic f() {}
''');
  }

  test_metadata_functionDeclaration_getter() async {
    var library = await checkLibrary('const a = null; @a get f => null;');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
dynamic get f {}
''');
  }

  test_metadata_functionDeclaration_setter() async {
    var library = await checkLibrary('const a = null; @a set f(value) {}');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
void set f(dynamic value) {}
''');
  }

  test_metadata_functionTypeAlias() async {
    var library = await checkLibrary('const a = null; @a typedef F();');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
typedef F = dynamic Function();
const dynamic a = null;
''');
  }

  test_metadata_functionTypedFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a g()) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f(@
        a/*location: test.dart;a?*/ () → dynamic g) {}
''');
  }

  test_metadata_functionTypedFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a g() = null]) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f([@
        a/*location: test.dart;a?*/ () → dynamic g = null]) {}
''');
  }

  test_metadata_importDirective() async {
    addLibrarySource('/foo.dart', 'const b = null;');
    var library = await checkLibrary('@a import "foo.dart"; const a = b;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
import 'foo.dart';
const dynamic a =
        b/*location: foo.dart;b?*/;
''');
  }

  test_metadata_invalid_classDeclaration() async {
    var library = await checkLibrary('f(_) {} @f(42) class C {}');
    checkElementText(library, r'''
@
        __unresolved__/*location: null*/
class C {
}
dynamic f(dynamic _) {}
''');
  }

  test_metadata_libraryDirective() async {
    var library = await checkLibrary('@a library L; const a = null;');
    checkElementText(library, r'''
@
        a/*location: test.dart;a?*/
library L;
const dynamic a = null;
''');
  }

  test_metadata_methodDeclaration_getter() async {
    var library =
        await checkLibrary('const a = null; class C { @a get m => null; }');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  dynamic get m {}
}
const dynamic a = null;
''');
  }

  test_metadata_methodDeclaration_method() async {
    var library = await checkLibrary(r'''
const a = null;
const b = null;
class C {
  @a
  @b
  m() {}
}
''');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  @
        b/*location: test.dart;b?*/
  dynamic m() {}
}
const dynamic a = null;
const dynamic b = null;
''');
  }

  test_metadata_methodDeclaration_setter() async {
    var library = await checkLibrary('''
const a = null;
class C {
  @a
  set m(value) {}
}
''');
    checkElementText(library, r'''
class C {
  @
        a/*location: test.dart;a?*/
  void set m(dynamic value) {}
}
const dynamic a = null;
''');
  }

  test_metadata_partDirective() async {
    addSource('/foo.dart', 'part of L;');
    var library = await checkLibrary('''
library L;
@a
part 'foo.dart';
const a = null;''');
    checkElementText(library, r'''
library L;
@
        a/*location: test.dart;a?*/
part 'foo.dart';
const dynamic a = null;
--------------------
unit: foo.dart

''');
  }

  test_metadata_prefixed_variable() async {
    addLibrarySource('/a.dart', 'const b = null;');
    var library = await checkLibrary('import "a.dart" as a; @a.b class C {}');
    checkElementText(library, r'''
import 'a.dart' as a;
@
        a/*location: test.dart;a*/.
        b/*location: a.dart;b?*/
class C {
}
''');
  }

  test_metadata_simpleFormalParameter() async {
    var library = await checkLibrary('const a = null; f(@a x) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f(@
        a/*location: test.dart;a?*/ dynamic x) {}
''');
  }

  test_metadata_simpleFormalParameter_method() async {
    var library = await checkLibrary('''
const a = null;

class C {
  m(@a x) {}
}
''');
    checkElementText(library, r'''
class C {
  dynamic m(@
        a/*location: test.dart;a?*/ dynamic x) {}
}
const dynamic a = null;
''');
  }

  test_metadata_simpleFormalParameter_withDefault() async {
    var library = await checkLibrary('const a = null; f([@a x = null]) {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f([@
        a/*location: test.dart;a?*/ dynamic x = null]) {}
''');
  }

  test_metadata_topLevelVariableDeclaration() async {
    var library = await checkLibrary('const a = null; @a int v;');
    checkElementText(library, r'''
const dynamic a = null;
@
        a/*location: test.dart;a?*/
int v;
''');
  }

  test_metadata_typeParameter_ofClass() async {
    var library = await checkLibrary('const a = null; class C<@a T> {}');
    checkElementText(library, r'''
class C<T> {
}
const dynamic a = null;
''');
  }

  test_metadata_typeParameter_ofClassTypeAlias() async {
    var library = await checkLibrary('''
const a = null;
class C<@a T> = D with E;
class D {}
class E {}''');
    checkElementText(library, r'''
class alias C<T> extends D with E {
  synthetic C() = D;
}
class D {
}
class E {
}
const dynamic a = null;
''');
  }

  test_metadata_typeParameter_ofFunction() async {
    var library = await checkLibrary('const a = null; f<@a T>() {}');
    checkElementText(library, r'''
const dynamic a = null;
dynamic f<T>() {}
''');
  }

  test_metadata_typeParameter_ofTypedef() async {
    var library = await checkLibrary('const a = null; typedef F<@a T>();');
    checkElementText(library, r'''
typedef F<T> = dynamic Function();
const dynamic a = null;
''');
  }

  test_method_documented() async {
    var library = await checkLibrary('''
class C {
  /**
   * Docs
   */
  f() {}
}''');
    checkElementText(library, r'''
class C {
  /**
   * Docs
   */
  dynamic f() {}
}
''');
  }

  test_method_inferred_type_nonStatic_implicit_param() async {
    var library = await checkLibrary('class C extends D { void f(value) {} }'
        ' abstract class D { void f(int value); }');
    checkElementText(library, r'''
class C extends D {
  void f(int value) {}
}
abstract class D {
  void f(int value);
}
''');
  }

  test_method_inferred_type_nonStatic_implicit_return() async {
    var library = await checkLibrary('''
class C extends D {
  f() => null;
}
abstract class D {
  int f();
}
''');
    checkElementText(library, r'''
class C extends D {
  int f() {}
}
abstract class D {
  int f();
}
''');
  }

  test_method_type_parameter() async {
    var library = await checkLibrary('class C { T f<T, U>(U u) => null; }');
    checkElementText(library, r'''
class C {
  T f<T, U>(U u) {}
}
''');
  }

  test_method_type_parameter_in_generic_class() async {
    var library = await checkLibrary('''
class C<T, U> {
  V f<V, W>(T t, U u, W w) => null;
}
''');
    checkElementText(library, r'''
class C<T, U> {
  V f<V, W>(T t, U u, W w) {}
}
''');
  }

  test_method_type_parameter_with_function_typed_parameter() async {
    var library = await checkLibrary('class C { void f<T, U>(T x(U u)) {} }');
    checkElementText(library, r'''
class C {
  void f<T, U>((U) → T x) {}
}
''');
  }

  test_methodInvocation_implicitCall() async {
    var library = await checkLibrary(r'''
class A {
  double call() => 0.0;
}
class B {
  A a;
}
var c = new B().a();
''');
    checkElementText(library, r'''
class A {
  double call() {}
}
class B {
  A a;
}
double c;
''');
  }

  test_mixin() async {
    var library = await checkLibrary(r'''
class A {}
class B {}
class C {}
class D {}

mixin M<T extends num, U> on A, B implements C, D {
  T f;
  U get g => 0;
  set s(int v) {}
  int m(double v) => 0;
}
''');
    checkElementText(library, r'''
class A {
}
class B {
}
class C {
}
class D {
}
mixin M<T extends num, U> on A, B implements C, D {
  T f;
  U get g {}
  void set s(int v) {}
  int m(double v) {}
}
''');
  }

  test_mixin_implicitObjectSuperclassConstraint() async {
    var library = await checkLibrary(r'''
mixin M {}
''');
    checkElementText(library, r'''
mixin M on Object {
}
''');
  }

  test_nameConflict_exportedAndLocal() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'c.dart';
C v;
''');
  }

  test_nameConflict_exportedAndLocal_exported() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/c.dart', '''
export 'a.dart';
class C {}
''');
    addLibrarySource('/d.dart', 'export "c.dart";');
    var library = await checkLibrary('''
import 'd.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'd.dart';
C v;
''');
  }

  test_nameConflict_exportedAndParted() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', '''
part of lib;
class C {}
''');
    addLibrarySource('/c.dart', '''
library lib;
export 'a.dart';
part 'b.dart';
''');
    var library = await checkLibrary('''
import 'c.dart';
C v = null;
''');
    checkElementText(library, r'''
import 'c.dart';
C v;
''');
  }

  test_nameConflict_importWithRelativeUri_exportWithAbsolute() async {
    if (resourceProvider.pathContext.separator != '/') {
      return;
    }

    addLibrarySource('/a.dart', 'class A {}');
    addLibrarySource('/b.dart', 'export "/a.dart";');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
A v = null;
''');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
A v;
''');
  }

  test_nested_generic_functions_in_generic_class_with_function_typed_params() async {
    var library = await checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
class C<T, U> {
  void g<V, W>() {}
}
''');
  }

  test_nested_generic_functions_in_generic_class_with_local_variables() async {
    var library = await checkLibrary('''
class C<T, U> {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
    checkElementText(library, r'''
class C<T, U> {
  void g<V, W>() {}
}
''');
  }

  test_nested_generic_functions_with_function_typed_param() async {
    var library = await checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>(void p(T t, U u, V v, W w, X x, Y y)) {
    }
  }
}
''');
    checkElementText(library, r'''
void f<T, U>() {}
''');
  }

  test_nested_generic_functions_with_local_variables() async {
    var library = await checkLibrary('''
void f<T, U>() {
  void g<V, W>() {
    void h<X, Y>() {
      T t;
      U u;
      V v;
      W w;
      X x;
      Y y;
    }
  }
}
''');
    checkElementText(library, r'''
void f<T, U>() {}
''');
  }

  test_operator() async {
    var library =
        await checkLibrary('class C { C operator+(C other) => null; }');
    checkElementText(library, r'''
class C {
  C +(C other) {}
}
''');
  }

  test_operator_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator==(Object other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool ==(Object other) {}
}
''');
  }

  test_operator_external() async {
    var library =
        await checkLibrary('class C { external C operator+(C other); }');
    checkElementText(library, r'''
class C {
  external C +(C other) {}
}
''');
  }

  test_operator_greater_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator>=(C other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool >=(C other) {}
}
''');
  }

  test_operator_index() async {
    var library =
        await checkLibrary('class C { bool operator[](int i) => null; }');
    checkElementText(library, r'''
class C {
  bool [](int i) {}
}
''');
  }

  test_operator_index_set() async {
    var library = await checkLibrary('''
class C {
  void operator[]=(int i, bool v) {}
}
''');
    checkElementText(library, r'''
class C {
  void []=(int i, bool v) {}
}
''');
  }

  test_operator_less_equal() async {
    var library = await checkLibrary('''
class C {
  bool operator<=(C other) => false;
}
''');
    checkElementText(library, r'''
class C {
  bool <=(C other) {}
}
''');
  }

  test_parameter() async {
    var library = await checkLibrary('void main(int p) {}');
    checkElementText(
        library,
        r'''
void main@5(int p@14) {}
''',
        withOffsets: true);
  }

  test_parameter_covariant() async {
    var library = await checkLibrary('class C { void m(covariant C c) {} }');
    checkElementText(library, r'''
class C {
  void m(covariant C c) {}
}
''');
  }

  test_parameter_covariant_inherited() async {
    var library = await checkLibrary(r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(T t) {}
}
''');
    checkElementText(library, r'''
class A<T> {
  void f(covariant T t) {}
}
class B<T> extends A<T> {
  void f(covariant T t) {}
}
''');
  }

  test_parameter_parameters() async {
    var library = await checkLibrary('class C { f(g(x, y)) {} }');
    checkElementText(library, r'''
class C {
  dynamic f((dynamic, dynamic) → dynamic g) {}
}
''');
  }

  test_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('class C<A, B> { f(A g(B x)) {} }');
    checkElementText(library, r'''
class C<A, B> {
  dynamic f((B) → A g) {}
}
''');
  }

  test_parameter_return_type() async {
    var library = await checkLibrary('class C { f(int g()) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(() → int g) {}
}
''');
  }

  test_parameter_return_type_void() async {
    var library = await checkLibrary('class C { f(void g()) {} }');
    checkElementText(library, r'''
class C {
  dynamic f(() → void g) {}
}
''');
  }

  test_parameterTypeNotInferred_constructor() async {
    // Strong mode doesn't do type inference on constructor parameters, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  C.positional([x = 1]);
  C.named({x: 1});
}
''');
    checkElementText(library, r'''
class C {
  C.positional([dynamic x = 1]);
  C.named({dynamic x: 1});
}
''');
  }

  test_parameterTypeNotInferred_initializingFormal() async {
    // Strong mode doesn't do type inference on initializing formals, so it's
    // ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  var x;
  C.positional([this.x = 1]);
  C.named({this.x: 1});
}
''');
    checkElementText(library, r'''
class C {
  dynamic x;
  C.positional([dynamic this.x = 1]);
  C.named({dynamic this.x: 1});
}
''');
  }

  test_parameterTypeNotInferred_staticMethod() async {
    // Strong mode doesn't do type inference on parameters of static methods,
    // so it's ok that we don't store inferred type info for them in summaries.
    var library = await checkLibrary('''
class C {
  static void positional([x = 1]) {}
  static void named({x: 1}) {}
}
''');
    checkElementText(library, r'''
class C {
  static void positional([dynamic x = 1]) {}
  static void named({dynamic x: 1}) {}
}
''');
  }

  test_parameterTypeNotInferred_topLevelFunction() async {
    // Strong mode doesn't do type inference on parameters of top level
    // functions, so it's ok that we don't store inferred type info for them in
    // summaries.
    var library = await checkLibrary('''
void positional([x = 1]) {}
void named({x: 1}) {}
''');
    checkElementText(library, r'''
void positional([dynamic x = 1]) {}
void named({dynamic x: 1}) {}
''');
  }

  test_parts() async {
    addSource('/a.dart', 'part of my.lib;');
    addSource('/b.dart', 'part of my.lib;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

--------------------
unit: b.dart

''');
  }

  test_parts_invalidUri() async {
    allowMissingFiles = true;
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary('library my.lib; part "foo/";');
    checkElementText(library, r'''
library my.lib;
part '';
--------------------
unit: foo

''');
  }

  test_parts_invalidUri_nullStringValue() async {
    allowMissingFiles = true;
    addSource('/foo/bar.dart', 'part of my.lib;');
    var library = await checkLibrary(r'''
library my.lib;
part "${foo}/bar.dart";
''');
    checkElementText(library, r'''
library my.lib;
part '<unresolved>';
--------------------
unit: null

''');
  }

  test_propagated_type_refers_to_closure() async {
    var library = await checkLibrary('''
void f() {
  var x = () => 0;
  var y = x;
}
''');
    checkElementText(library, r'''
void f() {}
''');
  }

  test_setter_covariant() async {
    var library =
        await checkLibrary('class C { void set x(covariant int value); }');
    checkElementText(library, r'''
class C {
  void set x(covariant int value);
}
''');
  }

  test_setter_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
void set x(value) {}''');
    checkElementText(library, r'''
/**
 * Docs
 */
void set x(dynamic value) {}
''');
  }

  test_setter_external() async {
    var library = await checkLibrary('external void set x(int value);');
    checkElementText(library, r'''
external void set x(int value);
''');
  }

  test_setter_inferred_type_conflictingInheritance() async {
    var library = await checkLibrary('''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(p) {}
}
''');
    checkElementText(library, r'''
class A {
  int t;
}
class B extends A {
  double t;
}
class C extends A implements B {
}
class D extends C {
  void set t(dynamic p) {}
}
''');
  }

  test_setter_inferred_type_nonStatic_implicit_param() async {
    var library =
        await checkLibrary('class C extends D { void set f(value) {} }'
            ' abstract class D { void set f(int value); }');
    checkElementText(library, r'''
class C extends D {
  void set f(int value) {}
}
abstract class D {
  void set f(int value);
}
''');
  }

  test_setter_inferred_type_static_implicit_return() async {
    var library = await checkLibrary('''
class C {
  static set f(int value) {}
}
''');
    checkElementText(library, r'''
class C {
  static void set f(int value) {}
}
''');
  }

  test_setter_inferred_type_top_level_implicit_return() async {
    var library = await checkLibrary('set f(int value) {}');
    checkElementText(library, r'''
void set f(int value) {}
''');
  }

  test_setters() async {
    var library =
        await checkLibrary('void set x(int value) {} set y(value) {}');
    checkElementText(library, r'''
void set x(int value) {}
void set y(dynamic value) {}
''');
  }

  test_syntheticFunctionType_genericClosure() async {
    var library = await checkLibrary('''
final v = f() ? <T>(T t) => 0 : <T>(T t) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
final (<bottom>) → int v;
bool f() {}
''');
  }

  test_syntheticFunctionType_genericClosure_inGenericFunction() async {
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  final v = b ? <V>(T t, U u, V v) => 0 : <V>(T t, U u, V v) => 1;
}
''');
    checkElementText(library, r'''
void f<T, U>(bool b) {}
''');
  }

  test_syntheticFunctionType_inGenericClass() async {
    var library = await checkLibrary('''
class C<T, U> {
  var v = f() ? (T t, U u) => 0 : (T t, U u) => 1;
}
bool f() => false;
''');
    checkElementText(library, r'''
class C<T, U> {
  (T, U) → int v;
}
bool f() {}
''');
  }

  test_syntheticFunctionType_inGenericFunction() async {
    var library = await checkLibrary('''
void f<T, U>(bool b) {
  var v = b ? (T t, U u) => 0 : (T t, U u) => 1;
}
''');
    checkElementText(library, r'''
void f<T, U>(bool b) {}
''');
  }

  test_syntheticFunctionType_noArguments() async {
    var library = await checkLibrary('''
final v = f() ? () => 0 : () => 1;
bool f() => true;
''');
    checkElementText(library, r'''
final () → int v;
bool f() {}
''');
  }

  test_syntheticFunctionType_withArguments() async {
    var library = await checkLibrary('''
final v = f() ? (int x, String y) => 0 : (int x, String y) => 1;
bool f() => true;
''');
    checkElementText(library, r'''
final (int, String) → int v;
bool f() {}
''');
  }

  test_type_arguments_explicit_dynamic_dynamic() async {
    var library = await checkLibrary('Map<dynamic, dynamic> m;');
    checkElementText(library, r'''
Map<dynamic, dynamic> m;
''');
  }

  test_type_arguments_explicit_dynamic_int() async {
    var library = await checkLibrary('Map<dynamic, int> m;');
    checkElementText(library, r'''
Map<dynamic, int> m;
''');
  }

  test_type_arguments_explicit_String_dynamic() async {
    var library = await checkLibrary('Map<String, dynamic> m;');
    checkElementText(library, r'''
Map<String, dynamic> m;
''');
  }

  test_type_arguments_explicit_String_int() async {
    var library = await checkLibrary('Map<String, int> m;');
    checkElementText(library, r'''
Map<String, int> m;
''');
  }

  test_type_arguments_implicit() async {
    var library = await checkLibrary('Map m;');
    checkElementText(library, r'''
Map<dynamic, dynamic> m;
''');
  }

  test_type_dynamic() async {
    var library = await checkLibrary('dynamic d;');
    checkElementText(library, r'''
dynamic d;
''');
  }

  test_type_inference_based_on_loadLibrary() async {
    addLibrarySource('/a.dart', '');
    var library = await checkLibrary('''
import 'a.dart' deferred as a;
var x = a.loadLibrary;
''');
    checkElementText(library, '''
import 'a.dart' deferred as a;
() → Future<dynamic> x;
''');
  }

  test_type_inference_closure_with_function_typed_parameter() async {
    var library = await checkLibrary('''
var x = (int f(String x)) => 0;
''');
    checkElementText(library, '''
((String) → int) → int x;
''');
  }

  test_type_inference_closure_with_function_typed_parameter_new() async {
    var library = await checkLibrary('''
var x = (int Function(String) f) => 0;
''');
    checkElementText(library, '''
((String) → int) → int x;
''');
  }

  test_type_inference_depends_on_exported_variable() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'var x = 0;');
    var library = await checkLibrary('''
import 'a.dart';
var y = x;
''');
    checkElementText(library, '''
import 'a.dart';
int y;
''');
  }

  test_type_inference_multiplyDefinedElement() async {
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'class C {}');
    var library = await checkLibrary('''
import 'a.dart';
import 'b.dart';
var v = C;
''');
    checkElementText(library, r'''
import 'a.dart';
import 'b.dart';
dynamic v;
''');
  }

  test_type_inference_nested_function() async {
    var library = await checkLibrary('''
var x = (t) => (u) => t + u;
''');
    checkElementText(library, '''
(dynamic) → (dynamic) → dynamic x;
''');
  }

  test_type_inference_nested_function_with_parameter_types() async {
    var library = await checkLibrary('''
var x = (int t) => (int u) => t + u;
''');
    checkElementText(library, '''
(int) → (int) → int x;
''');
  }

  test_type_inference_of_closure_with_default_value() async {
    var library = await checkLibrary('''
var x = ([y: 0]) => y;
''');
    checkElementText(library, '''
([dynamic]) → dynamic x;
''');
  }

  test_type_invalid_topLevelVariableElement_asType() async {
    var library = await checkLibrary('''
class C<T extends V> {}
typedef V F(V p);
V f(V p) {}
V V2 = null;
int V = 0;
''', allowErrors: true);
    checkElementText(library, r'''
typedef F = dynamic Function(dynamic p);
class C<T extends dynamic> {
}
dynamic V2;
int V;
dynamic f(dynamic p) {}
''');
  }

  test_type_invalid_topLevelVariableElement_asTypeArgument() async {
    var library = await checkLibrary('''
var V;
static List<V> V2;
''', allowErrors: true);
    checkElementText(library, r'''
dynamic V;
List<dynamic> V2;
''');
  }

  test_type_invalid_typeParameter_asPrefix() async {
    var library = await checkLibrary('''
class C<T> {
  m(T.K p) {}
}
''', allowErrors: true);
    checkElementText(library, r'''
class C<T> {
  dynamic m(dynamic p) {}
}
''');
  }

  test_type_reference_lib_to_lib() async {
    var library = await checkLibrary('''
class C {}
enum E { v }
typedef F();
C c;
E e;
F f;''');
    checkElementText(library, r'''
typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_lib_to_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library =
        await checkLibrary('library l; part "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
library l;
part 'a.dart';
C c;
E e;
() → dynamic f;
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
''');
  }

  test_type_reference_part_to_lib() async {
    addSource('/a.dart', 'part of l; C c; E e; F f;');
    var library = await checkLibrary(
        'library l; part "a.dart"; class C {} enum E { v } typedef F();');
    checkElementText(library, r'''
library l;
part 'a.dart';
typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
--------------------
unit: a.dart

C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_part_to_other_part() async {
    addSource('/a.dart', 'part of l; class C {} enum E { v } typedef F();');
    addSource('/b.dart', 'part of l; C c; E e; F f;');
    var library =
        await checkLibrary('library l; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library l;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
--------------------
unit: b.dart

C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_part_to_part() async {
    addSource('/a.dart',
        'part of l; class C {} enum E { v } typedef F(); C c; E e; F f;');
    var library = await checkLibrary('library l; part "a.dart";');
    checkElementText(library, r'''
library l;
part 'a.dart';
--------------------
unit: a.dart

typedef F = dynamic Function();
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
class C {
}
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_class() async {
    var library = await checkLibrary('class C {} C c;');
    checkElementText(library, r'''
class C {
}
C c;
''');
  }

  test_type_reference_to_class_with_type_arguments() async {
    var library = await checkLibrary('class C<T, U> {} C<int, String> c;');
    checkElementText(library, r'''
class C<T, U> {
}
C<int, String> c;
''');
  }

  test_type_reference_to_class_with_type_arguments_implicit() async {
    var library = await checkLibrary('class C<T, U> {} C c;');
    checkElementText(library, r'''
class C<T, U> {
}
C<dynamic, dynamic> c;
''');
  }

  test_type_reference_to_enum() async {
    var library = await checkLibrary('enum E { v } E e;');
    checkElementText(library, r'''
enum E {
  synthetic final int index;
  synthetic static const List<E> values;
  static const E v;
  String toString() {}
}
E e;
''');
  }

  test_type_reference_to_import() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_export() async {
    addLibrarySource('/a.dart', 'export "b.dart";');
    addLibrarySource('/b.dart', 'export "c.dart";');
    addLibrarySource('/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'export "../c/c.dart";');
    addLibrarySource('/a/c/c.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_export_in_subdirs() async {
    addLibrarySource('/a/a.dart', 'export "b/b.dart";');
    addLibrarySource('/a/b/b.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_part() async {
    addLibrarySource('/a.dart', 'library l; part "b.dart";');
    addSource('/b.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_part2() async {
    addLibrarySource('/a.dart', 'library l; part "p1.dart"; part "p2.dart";');
    addSource('/p1.dart', 'part of l; class C1 {}');
    addSource('/p2.dart', 'part of l; class C2 {}');
    var library = await checkLibrary('import "a.dart"; C1 c1; C2 c2;');
    checkElementText(library, r'''
import 'a.dart';
C1 c1;
C2 c2;
''');
  }

  test_type_reference_to_import_part_in_subdir() async {
    addLibrarySource('/a/b.dart', 'library l; part "c.dart";');
    addSource('/a/c.dart', 'part of l; class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a/b.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'b.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_import_relative() async {
    addLibrarySource('/a.dart', 'class C {} enum E { v } typedef F();');
    var library = await checkLibrary('import "a.dart"; C c; E e; F f;');
    checkElementText(library, r'''
import 'a.dart';
C c;
E e;
() → dynamic f;
''');
  }

  test_type_reference_to_typedef() async {
    var library = await checkLibrary('typedef F(); F f;');
    checkElementText(library, r'''
typedef F = dynamic Function();
() → dynamic f;
''');
  }

  test_type_reference_to_typedef_with_type_arguments() async {
    var library =
        await checkLibrary('typedef U F<T, U>(T t); F<int, String> f;');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
(int) → String f;
''');
  }

  test_type_reference_to_typedef_with_type_arguments_implicit() async {
    var library = await checkLibrary('typedef U F<T, U>(T t); F f;');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
(dynamic) → dynamic f;
''');
  }

  test_type_unresolved() async {
    var library = await checkLibrary('C c;', allowErrors: true);
    checkElementText(library, r'''
dynamic c;
''');
  }

  test_type_unresolved_prefixed() async {
    var library = await checkLibrary('import "dart:core" as core; core.C c;',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:core' as core;
dynamic c;
''');
  }

  test_typedef_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
typedef F();''');
    checkElementText(library, r'''
/**
 * Docs
 */
typedef F = dynamic Function();
''');
  }

  test_typedef_generic() async {
    var library = await checkLibrary(
        'typedef F<T> = int Function<S>(List<S> list, num Function<A>(A), T);');
    checkElementText(library, r'''
typedef F<T> = int Function<S>(List<S> list, <A>(A) → num , T );
''');
  }

  test_typedef_generic_asFieldType() async {
    var library = await checkLibrary(r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  Foo<int> f;
}
''');
    checkElementText(library, r'''
typedef Foo<S> = S Function<T>(T x);
class A {
  <T>(T) → int f;
}
''');
  }

  test_typedef_parameter_parameters() async {
    var library = await checkLibrary('typedef F(g(x, y));');
    checkElementText(library, r'''
typedef F = dynamic Function((dynamic, dynamic) → dynamic g);
''');
  }

  test_typedef_parameter_parameters_in_generic_class() async {
    var library = await checkLibrary('typedef F<A, B>(A g(B x));');
    checkElementText(library, r'''
typedef F<A, B> = dynamic Function((B) → A g);
''');
  }

  test_typedef_parameter_return_type() async {
    var library = await checkLibrary('typedef F(int g());');
    checkElementText(library, r'''
typedef F = dynamic Function(() → int g);
''');
  }

  test_typedef_parameter_type() async {
    var library = await checkLibrary('typedef F(int i);');
    checkElementText(library, r'''
typedef F = dynamic Function(int i);
''');
  }

  test_typedef_parameter_type_generic() async {
    var library = await checkLibrary('typedef F<T>(T t);');
    checkElementText(library, r'''
typedef F<T> = dynamic Function(T t);
''');
  }

  test_typedef_parameters() async {
    var library = await checkLibrary('typedef F(x, y);');
    checkElementText(library, r'''
typedef F = dynamic Function(dynamic x, dynamic y);
''');
  }

  test_typedef_parameters_named() async {
    var library = await checkLibrary('typedef F({y, z, x});');
    checkElementText(library, r'''
typedef F = dynamic Function({dynamic y}, {dynamic z}, {dynamic x});
''');
  }

  test_typedef_return_type() async {
    var library = await checkLibrary('typedef int F();');
    checkElementText(library, r'''
typedef F = int Function();
''');
  }

  test_typedef_return_type_generic() async {
    var library = await checkLibrary('typedef T F<T>();');
    checkElementText(library, r'''
typedef F<T> = T Function();
''');
  }

  test_typedef_return_type_implicit() async {
    var library = await checkLibrary('typedef F();');
    checkElementText(library, r'''
typedef F = dynamic Function();
''');
  }

  test_typedef_return_type_void() async {
    var library = await checkLibrary('typedef void F();');
    checkElementText(library, r'''
typedef F = void Function();
''');
  }

  test_typedef_type_parameters() async {
    var library = await checkLibrary('typedef U F<T, U>(T t);');
    checkElementText(library, r'''
typedef F<T, U> = U Function(T t);
''');
  }

  test_typedef_type_parameters_bound() async {
    var library = await checkLibrary(
        'typedef U F<T extends Object, U extends D>(T t); class D {}');
    checkElementText(library, r'''
typedef F<T, U extends D> = U Function(T t);
class D {
}
''');
  }

  test_typedef_type_parameters_bound_recursive() async {
    var library = await checkLibrary('typedef void F<T extends F>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
notSimplyBounded typedef F<T extends () → void> = void Function();
''');
  }

  test_typedef_type_parameters_bound_recursive2() async {
    var library = await checkLibrary('typedef void F<T extends List<F>>();');
    // Typedefs cannot reference themselves.
    checkElementText(library, r'''
notSimplyBounded typedef F<T extends List<() → void>> = void Function();
''');
  }

  test_typedef_type_parameters_f_bound_complex() async {
    var library = await checkLibrary('typedef U F<T extends List<U>, U>(T t);');
    checkElementText(library, r'''
notSimplyBounded typedef F<T extends List<U>, U> = U Function(T t);
''');
  }

  test_typedef_type_parameters_f_bound_simple() async {
    var library = await checkLibrary('typedef U F<T extends U, U>(T t);');
    checkElementText(library, r'''
notSimplyBounded typedef F<T extends U, U> = U Function(T t);
''');
  }

  test_typedef_type_parameters_f_bound_simple_new_syntax() async {
    var library =
        await checkLibrary('typedef F<T extends U, U> = U Function(T t);');
    checkElementText(library, r'''
notSimplyBounded typedef F<T extends U, U> = U Function(T t);
''');
  }

  test_typedefs() async {
    var library = await checkLibrary('f() {} g() {}');
    checkElementText(library, r'''
dynamic f() {}
dynamic g() {}
''');
  }

  @failingTest
  test_unresolved_annotation_instanceCreation_argument_super() async {
    // TODO(scheglov) fix https://github.com/dart-lang/sdk/issues/28553
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(super)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
class A {
  A(_);
}

class C {
  synthetic C();
}
''');
  }

  test_unresolved_annotation_instanceCreation_argument_this() async {
    var library = await checkLibrary('''
class A {
  const A(_);
}

@A(this)
class C {}
''', allowErrors: true);
    checkElementText(library, r'''
class A {
  const A(dynamic _);
}
@
        A/*location: test.dart;A*/(this)
class C {
}
''');
  }

  test_unresolved_annotation_namedConstructorCall_noClass() async {
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/.
        bar/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_namedConstructorCall_noConstructor() async {
    var library =
        await checkLibrary('@String.foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        String/*location: dart:core;String*/.
        foo/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_prefixedIdentifier_badPrefix() async {
    var library = await checkLibrary('@foo.bar class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/.
        bar/*location: null*/
class C {
}
''');
  }

  test_unresolved_annotation_prefixedIdentifier_noDeclaration() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@
        foo/*location: test.dart;foo*/.
        bar/*location: null*/
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_badPrefix() async {
    var library =
        await checkLibrary('@foo.bar.baz() class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/.
        bar/*location: null*/.
        baz/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noClass() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar.baz() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@
        foo/*location: test.dart;foo*/.
        bar/*location: null*/.
        baz/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_prefixedNamedConstructorCall_noConstructor() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.Future.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@
        foo/*location: test.dart;foo*/.
        Future/*location: dart:async;Future*/.
        bar/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_badPrefix() async {
    var library =
        await checkLibrary('@foo.bar() class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/.
        bar/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_prefixedUnnamedConstructorCall_noClass() async {
    var library = await checkLibrary(
        'import "dart:async" as foo; @foo.bar() class C {}',
        allowErrors: true);
    checkElementText(library, r'''
import 'dart:async' as foo;
@
        foo/*location: test.dart;foo*/.
        bar/*location: null*/()
class C {
}
''');
  }

  test_unresolved_annotation_simpleIdentifier() async {
    var library = await checkLibrary('@foo class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/
class C {
}
''');
  }

  test_unresolved_annotation_unnamedConstructorCall_noClass() async {
    var library = await checkLibrary('@foo() class C {}', allowErrors: true);
    checkElementText(library, r'''
@
        foo/*location: null*/()
class C {
}
''');
  }

  test_unresolved_export() async {
    allowMissingFiles = true;
    var library = await checkLibrary("export 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
export 'foo.dart';
''');
  }

  test_unresolved_import() async {
    allowMissingFiles = true;
    var library = await checkLibrary("import 'foo.dart';", allowErrors: true);
    LibraryElement importedLibrary = library.imports[0].importedLibrary;
    expect(importedLibrary.loadLibraryFunction, isNotNull);
    expect(importedLibrary.publicNamespace, isNotNull);
    expect(importedLibrary.exportNamespace, isNotNull);
    checkElementText(library, r'''
import 'foo.dart';
''');
  }

  test_unresolved_part() async {
    allowMissingFiles = true;
    var library = await checkLibrary("part 'foo.dart';", allowErrors: true);
    checkElementText(library, r'''
part 'foo.dart';
--------------------
unit: foo.dart

''');
  }

  test_unused_type_parameter() async {
    var library = await checkLibrary('''
class C<T> {
  void f() {}
}
C<int> c;
var v = c.f;
''');
    checkElementText(library, r'''
class C<T> {
  void f() {}
}
C<int> c;
() → void v;
''');
  }

  test_variable() async {
    var library = await checkLibrary('int x = 0;');
    checkElementText(
        library,
        r'''
int x@4;
synthetic int get x@4 {}
synthetic void set x@4(int _x@4) {}
''',
        withOffsets: true,
        withSyntheticAccessors: true);
  }

  test_variable_const() async {
    var library = await checkLibrary('const int i = 0;');
    checkElementText(library, r'''
const int i = 0;
''');
  }

  test_variable_documented() async {
    var library = await checkLibrary('''
// Extra comment so doc comment offset != 0
/**
 * Docs
 */
var x;''');
    checkElementText(library, r'''
/**
 * Docs
 */
dynamic x;
''');
  }

  test_variable_final() async {
    var library = await checkLibrary('final int x = 0;');
    checkElementText(library, r'''
final int x;
''');
  }

  test_variable_getterInLib_setterInPart() async {
    addSource('/a.dart', '''
part of my.lib;
void set x(int _) {}
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
int get x => 42;''');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
int get x {}
--------------------
unit: a.dart

void set x(int _) {}
''');
  }

  test_variable_getterInPart_setterInLib() async {
    addSource('/a.dart', '''
part of my.lib;
int get x => 42;
''');
    var library = await checkLibrary('''
library my.lib;
part 'a.dart';
void set x(int _) {}
''');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
void set x(int _) {}
--------------------
unit: a.dart

int get x {}
''');
  }

  test_variable_getterInPart_setterInPart() async {
    addSource('/a.dart', 'part of my.lib; int get x => 42;');
    addSource('/b.dart', 'part of my.lib; void set x(int _) {}');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

int get x {}
--------------------
unit: b.dart

void set x(int _) {}
''');
  }

  test_variable_implicit_type() async {
    var library = await checkLibrary('var x;');
    checkElementText(library, r'''
dynamic x;
''');
  }

  test_variable_inferred_type_implicit_initialized() async {
    var library = await checkLibrary('var v = 0;');
    checkElementText(library, r'''
int v;
''');
  }

  test_variable_initializer() async {
    var library = await checkLibrary('int v = 0;');
    checkElementText(library, r'''
int v;
''');
  }

  test_variable_initializer_final() async {
    var library = await checkLibrary('final int v = 0;');
    checkElementText(library, r'''
final int v;
''');
  }

  test_variable_initializer_final_untyped() async {
    var library = await checkLibrary('final v = 0;');
    checkElementText(library, r'''
final int v;
''');
  }

  test_variable_initializer_untyped() async {
    var library = await checkLibrary('var v = 0;');
    checkElementText(library, r'''
int v;
''');
  }

  test_variable_propagatedType_const_noDep() async {
    var library = await checkLibrary('const i = 0;');
    checkElementText(library, r'''
const int i = 0;
''');
  }

  test_variable_propagatedType_final_dep_inLib() async {
    addLibrarySource('/a.dart', 'final a = 1;');
    var library = await checkLibrary('import "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
import 'a.dart';
final double b;
''');
  }

  test_variable_propagatedType_final_dep_inPart() async {
    addSource('/a.dart', 'part of lib; final a = 1;');
    var library =
        await checkLibrary('library lib; part "a.dart"; final b = a / 2;');
    checkElementText(library, r'''
library lib;
part 'a.dart';
final double b;
--------------------
unit: a.dart

final int a;
''');
  }

  test_variable_propagatedType_final_noDep() async {
    var library = await checkLibrary('final i = 0;');
    checkElementText(library, r'''
final int i;
''');
  }

  test_variable_propagatedType_implicit_dep() async {
    // The propagated type is defined in a library that is not imported.
    addLibrarySource('/a.dart', 'class C {}');
    addLibrarySource('/b.dart', 'import "a.dart"; C f() => null;');
    var library = await checkLibrary('import "b.dart"; final x = f();');
    checkElementText(library, r'''
import 'b.dart';
final C x;
''');
  }

  test_variable_setterInPart_getterInPart() async {
    addSource('/a.dart', 'part of my.lib; void set x(int _) {}');
    addSource('/b.dart', 'part of my.lib; int get x => 42;');
    var library =
        await checkLibrary('library my.lib; part "a.dart"; part "b.dart";');
    checkElementText(library, r'''
library my.lib;
part 'a.dart';
part 'b.dart';
--------------------
unit: a.dart

void set x(int _) {}
--------------------
unit: b.dart

int get x {}
''');
  }

  test_variables() async {
    var library = await checkLibrary('int i; int j;');
    checkElementText(library, r'''
int i;
int j;
''');
  }
}

/// Mixin containing helper methods for testing summary resynthesis.  Intended
/// to be applied to a class implementing [ResynthesizeTestStrategy].
mixin ResynthesizeTestHelpers implements ResynthesizeTestStrategy {
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) async {
    Source source = addTestSource(text);
    SummaryResynthesizer resynthesizer = encodeLibrary(source);
    return resynthesizer.getLibraryElement(source.uri.toString());
  }
}

class TestSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedSummaries;
  final Map<String, LinkedLibrary> linkedSummaries;
  final bool allowMissingFiles;

  /**
   * The set of uris for which unlinked summaries have been requested using
   * [getUnlinkedSummary].
   */
  final Set<String> unlinkedSummariesRequested = new Set<String>();

  /**
   * The set of uris for which linked summaries have been requested using
   * [getLinkedSummary].
   */
  final Set<String> linkedSummariesRequested = new Set<String>();

  TestSummaryResynthesizer(AnalysisContextImpl context, this.unlinkedSummaries,
      this.linkedSummaries, this.allowMissingFiles)
      : super(context, null, context.sourceFactory, true) {
    // Clear after resynthesizing TypeProvider in super().
    unlinkedSummariesRequested.clear();
    linkedSummariesRequested.clear();
    context.typeProvider = typeProvider;
  }

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    linkedSummariesRequested.add(uri);
    LinkedLibrary serializedLibrary = linkedSummaries[uri];
    if (serializedLibrary == null && !allowMissingFiles) {
      fail('Unexpectedly tried to get linked summary for $uri');
    }
    return serializedLibrary;
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    unlinkedSummariesRequested.add(uri);
    UnlinkedUnit serializedUnit = unlinkedSummaries[uri];
    if (serializedUnit == null && !allowMissingFiles) {
      fail('Unexpectedly tried to get unlinked summary for $uri');
    }
    return serializedUnit;
  }

  @override
  bool hasLibrarySummary(String uri) {
    return true;
  }
}
