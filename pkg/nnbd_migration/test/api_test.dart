// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_context.dart';
import 'api_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_ProvisionalApiTest);
    defineReflectiveTests(_ProvisionalApiTestPermissive);
    defineReflectiveTests(_ProvisionalApiTestWithReset);
  });
}

/// Tests of the provisional API.
@reflectiveTest
class _ProvisionalApiTest extends _ProvisionalApiTestBase
    with _ProvisionalApiTestCases {
  @override
  bool get _usePermissiveMode => false;
}

/// Base class for provisional API tests.
abstract class _ProvisionalApiTestBase extends AbstractContextTest {
  String? projectPath;

  bool get _usePermissiveMode;

  void setUp() {
    projectPath = convertPath(testsPath);
    super.setUp();
  }

  /// Hook invoked between stages of processing inputs.
  void _betweenStages() {}

  /// Verifies that migration of the files in [input] produces the output in
  /// [expectedOutput].
  ///
  /// Optional parameter [removeViaComments] indicates whether dead code should
  /// be removed in its entirety (the default) or removed by commenting it out.
  Future<void> _checkMultipleFileChanges(
      Map<String, String> input, Map<String, dynamic> expectedOutput,
      {Map<String, String> migratedInput = const {},
      bool removeViaComments = false,
      bool warnOnWeakCode = false,
      bool allowErrors = false}) async {
    for (var path in migratedInput.keys) {
      newFile(path, migratedInput[path]!);
    }
    for (var path in input.keys) {
      newFile(path, input[path]!);
    }
    var listener = TestMigrationListener();
    var migration = NullabilityMigration(listener,
        permissive: _usePermissiveMode,
        removeViaComments: removeViaComments,
        warnOnWeakCode: warnOnWeakCode);
    for (var path in input.keys) {
      var resolvedLibrary = await session.getResolvedLibrary(path);
      if (resolvedLibrary is ResolvedLibraryResult) {
        for (var unit in resolvedLibrary.units) {
          var errors =
              unit.errors.where((e) => e.severity == Severity.error).toList();
          if (!allowErrors && errors.isNotEmpty) {
            fail('Unexpected error(s): $errors');
          }
          migration.prepareInput(unit);
        }
      }
    }
    expect(migration.unmigratedDependencies, isEmpty);
    _betweenStages();
    for (var path in input.keys) {
      var resolvedLibrary = await session.getResolvedLibrary(path);
      if (resolvedLibrary is ResolvedLibraryResult) {
        for (var unit in resolvedLibrary.units) {
          migration.processInput(unit);
        }
      }
    }
    _betweenStages();
    for (var path in input.keys) {
      var resolvedLibrary = await session.getResolvedLibrary(path);
      if (resolvedLibrary is ResolvedLibraryResult) {
        for (var unit in resolvedLibrary.units) {
          migration.finalizeInput(unit);
        }
      }
    }
    migration.finish();
    var sourceEdits = <String, List<SourceEdit>>{};
    for (var entry in listener.edits.entries) {
      var path = entry.key.fullName;
      expect(expectedOutput.keys, contains(path));
      sourceEdits[path] = entry.value;
    }
    for (var path in expectedOutput.keys) {
      var sourceEditsForPath = sourceEdits[path] ?? [];
      sourceEditsForPath.sort((a, b) => b.offset.compareTo(a.offset));
      expect(SourceEdit.applySequence(input[path]!, sourceEditsForPath),
          expectedOutput[path]);
    }
  }

  /// Verifies that migration of the single file with the given [content]
  /// produces the [expected] output.
  ///
  /// Optional parameter [removeViaComments] indicates whether dead code should
  /// be removed in its entirety (the default) or removed by commenting it out.
  Future<void> _checkSingleFileChanges(String content, dynamic expected,
      {Map<String, String> migratedInput = const {},
      bool removeViaComments = false,
      bool warnOnWeakCode = false,
      bool allowErrors = false}) async {
    var sourcePath = convertPath('$testsPath/lib/test.dart');
    await _checkMultipleFileChanges(
        {sourcePath: content}, {sourcePath: expected},
        migratedInput: migratedInput,
        removeViaComments: removeViaComments,
        warnOnWeakCode: warnOnWeakCode,
        allowErrors: allowErrors);
  }
}

/// Mixin containing test cases for the provisional API.
mixin _ProvisionalApiTestCases on _ProvisionalApiTestBase {
  Future<void> test_accept_required_hint() async {
    var content = '''
f({/*required*/ int i}) {}
''';
    var expected = '''
f({required int i}) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_accept_required_hint_nullable() async {
    var content = '''
f({/*required*/ int i}) {}
g() {
  f(i: null);
}
''';
    var expected = '''
f({required int? i}) {}
g() {
  f(i: null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_add_explicit_parameter_type() async {
    var content = '''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => value + 1);
}
''';
    // Under the new NNBD rules, `value` gets an inferred type of `Object?`.  We
    // need to change this to `dynamic` to avoid an "undefined operator +"
    // error.
    var expected = '''
abstract class C {
  void m<T>(T Function(T)? callback);
}
void test(C c) {
  c.m((dynamic value) => value + 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40476')
  Future<void> test_add_explicit_parameter_type_interpolation() async {
    var content = r'''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => '$value';
}
''';
    // Under the new NNBD rules, `value` gets an inferred type of `Object?`,
    // whereas it previously had a type of `dynamic`.  But we don't need to fix
    // it because `Object?` supports `toString`.
    var expected = r'''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => '$value';
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40476')
  Future<void> test_add_explicit_parameter_type_object_method() async {
    var content = '''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => value.toString());
}
''';
    // Under the new NNBD rules, `value` gets an inferred type of `Object?`,
    // whereas it previously had a type of `dynamic`.  But we don't need to fix
    // it because `Object?` supports `toString`.
    var expected = '''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => value.toString());
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40476')
  Future<void> test_add_explicit_parameter_type_unused() async {
    var content = '''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => 0);
}
''';
    // Under the new NNBD rules, `value` gets an inferred type of `Object?`,
    // whereas it previously had a type of `dynamic`.  But we don't need to fix
    // it because it's unused.
    var expected = '''
abstract class C {
  void m<T>(T Function(T) callback);
}
void test(C c) {
  c.m((value) => 0);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_add_required() async {
    var content = '''
int f({String s}) => s.length;
''';
    var expected = '''
int f({required String s}) => s.length;
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39404')
  Future<void> test_add_type_parameter_bound() async {
    /// After a migration, a bound may be made nullable. Instantiate-to-bounds
    /// may need to be made explicit where the migration engine prefers a
    /// non-null type.
    var content = '''
class C<T extends num/*?*/> {}

void main() {
  C c = C();
}
''';
    var expected = '''
class C<T extends num?> {}

void main() {
  C<num> c = C();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ambiguous_bang_hint_after_as() async {
    var content = '''
T f<T>(Object/*?*/ x) => x as T/*!*/;
''';
    // The `/*!*/` is considered to apply to the type `T`, not to the expression
    // `x as T`, so we shouldn't produce `(x as T)!`.
    var expected = '''
T f<T>(Object? x) => x as T;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ambiguous_bang_hint_after_as_assigned() async {
    var content = '''
T f<T>(Object/*?*/ x, T/*!*/ y) => y = x as T/*!*/;
''';
    // The `/*!*/` is considered to apply to the type `T`, not to the expression
    // `y = x as T`, so we shouldn't produce `(y = x as T)!`.
    var expected = '''
T f<T>(Object? x, T y) => y = x as T;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ambiguous_bang_hint_after_is() async {
    var content = '''
bool f<T>(Object/*?*/ x) => x is T/*!*/;
''';
    // The `/*!*/` is considered to apply to the type `T`, not to the expression
    // `x is T`, so we shouldn't produce `(x is T)!`.
    var expected = '''
bool f<T>(Object? x) => x is T;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ambiguous_bang_hint_after_is_conditional() async {
    var content = '''
dynamic f<T>(Object/*?*/ x, dynamic y) => y ? y : x is T/*!*/;
''';
    // The `/*!*/` is considered to apply to the type `T`, not to the expression
    // `y ? y : x is T`, so we shouldn't produce `(y ? y : x is T)!`.
    var expected = '''
dynamic f<T>(Object? x, dynamic y) => y ? y : x is T;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ambiguous_closure_parameter_in_local_variable() async {
    var content = '''
Object _f<T>(Object Function(T) callback, Object obj) => 0;
g() {
  var y = _f<Map<String, int>>(
      (x) => x.keys,
      _f<List<bool>>(
          (x) => x.last, 0));
}
''';
    var expected = '''
Object _f<T>(Object Function(T) callback, Object obj) => 0;
g() {
  var y = _f<Map<String, int>>(
      (x) => x.keys,
      _f<List<bool>>(
          (x) => x.last, 0));
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_component_attribute() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'my-component'
)
class MyComponent {
  int foo;
  MyComponent(@Attribute('foo') this.foo);
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'my-component'
)
class MyComponent {
  int? foo;
  MyComponent(@Attribute('foo') this.foo);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_component_constructor() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'my-component'
)
class MyComponent {
  int foo;
  MyComponent(this.foo);
  void nullifyFoo() { foo = null; }
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'my-component'
)
class MyComponent {
  int? foo;
  MyComponent(int this.foo);
  void nullifyFoo() { foo = null; }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_contentChild_field() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ContentChild('foo')
  Element bar;
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ContentChild('foo')
  Element? bar;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_contentChild_field_not_late() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ContentChild('foo')
  Element bar;
  Element baz;

  f(Element /*!*/ e) {
    bar = e;
    baz = e;
  }
  g() => bar.id;
  h() => baz.id;
}
''';
    // `late` heuristics are disabled for `bar` since it's marked with
    // `ContentChild`.  But they do apply to `baz`.
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ContentChild('foo')
  Element? bar;
  late Element baz;

  f(Element e) {
    bar = e;
    baz = e;
  }
  g() => bar!.id;
  h() => baz.id;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_contentChildren_field_not_late() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class myComponent {
  @ContentChildren('foo')
  Element bar;
  Element baz;

  f(Element /*!*/ e) {
    bar = e;
    baz = e;
  }
  g() => bar.id;
  h() => baz.id;
}
''';
    // `late` heuristics are disabled for `bar` since it's marked with
    // `ContentChildren`.  But they do apply to `baz`.
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class myComponent {
  @ContentChildren('foo')
  Element? bar;
  late Element baz;

  f(Element e) {
    bar = e;
    baz = e;
  }
  g() => bar!.id;
  h() => baz.id;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_injectable_constructor() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Injectable()
class MyClass {
  int foo;
  MyClass(this.foo);
  void nullifyFoo() { foo = null; }
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

@Injectable()
class MyClass {
  int? foo;
  MyClass(int this.foo);
  void nullifyFoo() { foo = null; }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_injectable_function() async {
    addAngularPackage();
    var content = '''
import 'package:angular/angular.dart';

class C {}

@Injectable()
C createC(int n, @Optional() int x) => C();
''';
    var expected = '''
import 'package:angular/angular.dart';

class C {}

@Injectable()
C createC(int n, @Optional() int? x) => C();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_optional_constructor_param() async {
    addAngularPackage();
    var content = '''
import 'package:angular/angular.dart';

class MyComponent {
  MyComponent(@Optional() String foo);
}
''';
    var expected = '''
import 'package:angular/angular.dart';

class MyComponent {
  MyComponent(@Optional() String? foo);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_optional_constructor_param_field_formal() async {
    addAngularPackage();
    var content = '''
import 'package:angular/angular.dart';

class MyComponent {
  String foo;
  MyComponent(@Optional() this.foo);
}
''';
    var expected = '''
import 'package:angular/angular.dart';

class MyComponent {
  String? foo;
  MyComponent(@Optional() this.foo);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_optional_constructor_param_internal() async {
    addAngularPackage(internalUris: true);
    var content = '''
import 'package:angular/angular.dart';

class MyComponent {
  MyComponent(@Optional() String foo);
}
''';
    var expected = '''
import 'package:angular/angular.dart';

class MyComponent {
  MyComponent(@Optional() String? foo);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_viewChild_field() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ViewChild('foo')
  Element bar;
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ViewChild('foo')
  Element? bar;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_viewChild_field_internal() async {
    addAngularPackage(internalUris: true);
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ViewChild('foo')
  Element bar;
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  // Initialize this.bar in the constructor just so the migration tool doesn't
  // decide to make it nullable due to the lack of initializer.
  MyComponent(this.bar);

  @ViewChild('foo')
  Element? bar;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_viewChild_field_not_late() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ViewChild('foo')
  Element bar;
  Element baz;

  f(Element /*!*/ e) {
    bar = e;
    baz = e;
  }
  g() => bar.id;
  h() => baz.id;
}
''';
    // `late` heuristics are disabled for `bar` since it's marked with
    // `ViewChild`.  But they do apply to `baz`.
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ViewChild('foo')
  Element? bar;
  late Element baz;

  f(Element e) {
    bar = e;
    baz = e;
  }
  g() => bar!.id;
  h() => baz.id;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_viewChild_setter() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ViewChild('foo')
  set bar(Element element) {}
}
''';
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class MyComponent {
  @ViewChild('foo')
  set bar(Element? element) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_angular_viewChildren_field_not_late() async {
    addAngularPackage();
    var content = '''
import 'dart:html';
import 'package:angular/angular.dart';

class myComponent {
  @ViewChildren('foo')
  Element bar;
  Element baz;

  f(Element /*!*/ e) {
    bar = e;
    baz = e;
  }
  g() => bar.id;
  h() => baz.id;
}
''';
    // `late` heuristics are disabled for `bar` since it's marked with
    // `ViewChildren`.  But they do apply to `baz`.
    var expected = '''
import 'dart:html';
import 'package:angular/angular.dart';

class myComponent {
  @ViewChildren('foo')
  Element? bar;
  late Element baz;

  f(Element e) {
    bar = e;
    baz = e;
  }
  g() => bar!.id;
  h() => baz.id;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_annotation_named_constructor() async {
    var content = '''
class C {
  final List<Object> values;
  const factory C.ints(List<int> list) = C;
  const C(this.values);
}

@C.ints([1, 2, 3])
class D {}
''';
    var expected = '''
class C {
  final List<Object>? values;
  const factory C.ints(List<int>? list) = C;
  const C(this.values);
}

@C.ints([1, 2, 3])
class D {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_argumentError_checkNotNull_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  ArgumentError.checkNotNull(i);
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  ArgumentError.checkNotNull(i);
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_as_allows_null() async {
    var content = '''
int f(Object o) => (o as int)?.gcd(1);
main() {
  f(null);
}
''';
    var expected = '''
int? f(Object? o) => (o as int?)?.gcd(1);
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_assign_null_to_generic_type() async {
    var content = '''
main() {
  List<int> x = null;
}
''';
    var expected = '''
main() {
  List<int>? x = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_assignment_to_promoted_var_can_undo_promotion() async {
    var content = '''
abstract class C {
  void test() {
    var x = f();
    while (x != null) {
      x = f();
    }
  }
  int/*?*/ f();
}
''';
    var expected = '''
abstract class C {
  void test() {
    var x = f();
    while (x != null) {
      x = f();
    }
  }
  int? f();
}
''';
    // Prior to the fix for https://github.com/dart-lang/sdk/issues/41411,
    // migration would consider the LHS of `x = f()` to have context type
    // non-nullable `int`, so it would add a null check to the value returned
    // from `f`.
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_at_required_to_required_in_redirecting_factory() async {
    // Redirecting factory constructors have special logic to suppress some of
    // the usual heuristics for adding `required`, since it's allowed for a
    // redirecting factory constructor to have a non-required non-nullable
    // argument with no default.  But we need to make sure that we still convert
    // `@required` to `required`.
    addMetaPackage();
    var content = r'''
import 'package:meta/meta.dart';
abstract class A {
  int get v;
  A._();
  factory A({@required int v}) = B._;
}
class B extends A {
  @override
  final int v;
  B._({this.v}) : super._();
}
''';
    var expected = r'''
import 'package:meta/meta.dart';
abstract class A {
  int? get v;
  A._();
  factory A({required int v}) = B._;
}
class B extends A {
  @override
  final int? v;
  B._({this.v}) : super._();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_avoid_redundant_future_or() async {
    // FutureOr<int?> and FutureOr<int?>? are equivalent types; we never insert
    // the redundant second `?`.
    var content = '''
import 'dart:async';
abstract class C {
  FutureOr<int/*?*/> f();
  FutureOr<int>/*?*/ g();
  FutureOr<int> h(bool b) => b ? f() : g();
}
''';
    var expected = '''
import 'dart:async';
abstract class C {
  FutureOr<int?> f();
  FutureOr<int>? g();
  FutureOr<int?> h(bool b) => b ? f() : g();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_await_null() async {
    var content = '''
Future<int> test() async {
  return await null;
}
''';
    var expected = '''
Future<int?> test() async {
  return await null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_await_nullable_future_to_non_nullable() async {
    var content = '''
Future<String> foo() async => null;

Future<String/*!*/> bar() async {
  return await foo();
}
''';
    var expected = '''
Future<String?> foo() async => null;

Future<String> bar() async {
  return (await foo())!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_back_propagation_stops_at_implicitly_typed_variables() async {
    var content = '''
class C {
  int v;
  C(this.v);
}
f(C c) {
  var x = c.v;
  print(x + 1);
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  int? v;
  C(this.v);
}
f(C c) {
  var x = c.v!;
  print(x + 1);
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_built_value_non_nullable_getter() async {
    addBuiltValuePackage();
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/lib.dart');
    var file1 = r'''
import 'package:built_value/built_value.dart';

part 'lib.g.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  int get value;
  Foo._();
  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}
''';
    var expected1 = r'''
import 'package:built_value/built_value.dart';

part 'lib.g.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  int get value;
  Foo._();
  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}
''';
    // Note: in a real-world scenario the generated file would be in a different
    // directory but we don't need to simulate that detail for this test.  Also,
    // the generated file would have a lot more code in it, but we don't need to
    // simulate all the details of what is generated.
    var path2 = convertPath('$root/lib.g.dart');
    var file2 = r'''
part of 'lib.dart';

class _$Foo extends Foo {
  @override
  final int value;

  factory _$Foo([void Function(FooBuilder) updates]) => throw '';

  _$Foo._({this.value}) : super._() {
    BuiltValueNullFieldError.checkNotNull(value, 'Foo', 'value');
  }
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  int get value => throw '';
}
''';
    await _checkMultipleFileChanges(
        {path1: file1, path2: file2}, {path1: expected1, path2: anything});
  }

  Future<void> test_built_value_nullable_getter() async {
    addBuiltValuePackage();
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/lib.dart');
    var file1 = r'''
import 'package:built_value/built_value.dart';

part 'lib.g.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  @nullable
  int get value;
  Foo._();
  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}
''';
    var expected1 = r'''
import 'package:built_value/built_value.dart';

part 'lib.g.dart';

abstract class Foo implements Built<Foo, FooBuilder> {
  int? get value;
  Foo._();
  factory Foo([void Function(FooBuilder) updates]) = _$Foo;
}
''';
    // Note: in a real-world scenario the generated file would be in a different
    // directory but we don't need to simulate that detail for this test.  Also,
    // the generated file would have a lot more code in it, but we don't need to
    // simulate all the details of what is generated.
    var path2 = convertPath('$root/lib.g.dart');
    var file2 = r'''
part of 'lib.dart';

class _$Foo extends Foo {
  @override
  final int value;

  factory _$Foo([void Function(FooBuilder) updates]) => throw '';

  _$Foo._({this.value}) : super._();
}

class FooBuilder implements Builder<Foo, FooBuilder> {
  int get value => throw '';
}
''';
    await _checkMultipleFileChanges(
        {path1: file1, path2: file2}, {path1: expected1, path2: anything});
  }

  Future<void> test_built_value_nullable_getter_interface_only() async {
    addBuiltValuePackage();
    var content = '''
import 'package:built_value/built_value.dart';

abstract class Foo {
  @nullable
  int get value;
}
''';
    var expected = '''
import 'package:built_value/built_value.dart';

abstract class Foo {
  int? get value;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_already_migrated_extension() async {
    var content = '''
import 'already_migrated.dart';
void f() {
  <int>[].g();
}
''';
    var alreadyMigrated = '''
// @dart=2.12
extension Ext<T> on List<T> {
  g() {}
}
''';
    var expected = '''
import 'already_migrated.dart';
void f() {
  <int>[].g();
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void> test_call_already_migrated_extension_null_aware() async {
    var content = '''
import 'already_migrated.dart';
class C {
  X m(V v) => v?.toX();
}
''';
    var alreadyMigrated = '''
// @dart=2.12
class X {}
class V {}
extension Ext on V {
  X toX() => X();
}
''';
    var expected = '''
import 'already_migrated.dart';
class C {
  X? m(V? v) => v?.toX();
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void> test_call_generic_function_returns_generic_class() async {
    var content = '''
class B<E> implements List<E/*?*/> {
  final C c;
  B(this.c);
  B<T> cast<T>() => c._castFrom<E, T>(this);
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
abstract class C {
  B<T> _castFrom<S, T>(B<S> source);
}
''';
    var expected = '''
class B<E> implements List<E?> {
  final C c;
  B(this.c);
  B<T> cast<T>() => c._castFrom<E, T>(this);
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
abstract class C {
  B<T> _castFrom<S, T>(B<S> source);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_migrated_base_class_method_non_nullable() async {
    var content = '''
abstract class M<V> implements Map<String, V> {}
void _f(bool b, M<int> m, int i) {
  if (b) {
    m['x'] = i;
  }
}
void _g(bool b, M<int> m) {
  _f(b, m, null);
}
''';
    var expected = '''
abstract class M<V> implements Map<String, V> {}
void _f(bool b, M<int?> m, int? i) {
  if (b) {
    m['x'] = i;
  }
}
void _g(bool b, M<int?> m) {
  _f(b, m, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_migrated_base_class_method_nullable() async {
    var content = '''
abstract class M<V> implements Map<String, V> {}
int f(M<int> m) => m['x'];
''';
    var expected = '''
abstract class M<V> implements Map<String, V> {}
int? f(M<int> m) => m['x'];
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff() async {
    var content = '''
class C {
  void call() {}
}
void Function() f(C c) => c;
''';
    var expected = '''
class C {
  void call() {}
}
void Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff_already_migrated() async {
    var content = '''
import 'already_migrated.dart';
void Function() f(C c) => c;
''';
    var alreadyMigrated = '''
// @dart=2.12
class C {
  void call() {}
}
''';
    var expected = '''
import 'already_migrated.dart';
void Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void>
      test_call_tearoff_already_migrated_propagate_nullability() async {
    var content = '''
import 'already_migrated.dart';
Map<int, String> Function() f(C c) => c;
''';
    var alreadyMigrated = '''
// @dart=2.12
class C {
  Map<int, String?> call() => {};
}
''';
    var expected = '''
import 'already_migrated.dart';
Map<int, String?> Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void> test_call_tearoff_already_migrated_with_substitution() async {
    var content = '''
import 'already_migrated.dart';
Map<int, String> Function() f(C<String/*?*/> c) => c;
''';
    var alreadyMigrated = '''
// @dart=2.12
class C<T> {
  Map<int, T> call() => {};
}
''';
    var expected = '''
import 'already_migrated.dart';
Map<int, String?> Function() f(C<String?> c) => c;
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void> test_call_tearoff_futureOr() async {
    var content = '''
import 'dart:async';
class C {
  void call() {}
}
FutureOr<void Function()> f(C c) => c;
''';
    var expected = '''
import 'dart:async';
class C {
  void call() {}
}
FutureOr<void Function()> f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff_inherited() async {
    var content = '''
class B {
  void call() {}
}
class C extends B {}
void Function() f(C c) => c;
''';
    var expected = '''
class B {
  void call() {}
}
class C extends B {}
void Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff_inherited_propagate_nullability() async {
    var content = '''
class B {
  Map<int, String> call() => {1: null};
}
class C extends B {}
Map<int, String> Function() f(C c) => c;
''';
    var expected = '''
class B {
  Map<int, String?> call() => {1: null};
}
class C extends B {}
Map<int, String?> Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff_propagate_nullability() async {
    var content = '''
class C {
  Map<int, String> call() => {1: null};
}
Map<int, String> Function() f(C c) => c;
''';
    var expected = '''
class C {
  Map<int, String?> call() => {1: null};
}
Map<int, String?> Function() f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_call_tearoff_raw_function() async {
    var content = '''
class C {
  void call() {}
}
Function f(C c) => c;
''';
    var expected = '''
class C {
  void call() {}
}
Function f(C c) => c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_cascade_on_nullable() async {
    var content = '''
class C {
  int /*?*/ x;
  void f() {
    x..isEven;
  }
}
''';
    var expected = '''
class C {
  int? x;
  void f() {
    x!..isEven;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_catch_simple() async {
    var content = '''
void f() {
  try {} catch (ex, st) {}
}
''';
    var expected = '''
void f() {
  try {} catch (ex, st) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_catch_simple_with_modifications() async {
    var content = '''
void f(String x, StackTrace y) {
  try {} catch (ex, st) {
    ex = x;
    st = y;
  }
}
main() {
  f(null, null);
}
''';
    var expected = '''
void f(String? x, StackTrace? y) {
  try {} catch (ex, st) {
    ex = x;
    st = y!;
  }
}
main() {
  f(null, null);
}
''';
    // Note: using allowErrors=true because variables introduced by a catch
    // clause are final
    await _checkSingleFileChanges(content, expected, allowErrors: true);
  }

  Future<void> test_catch_with_on() async {
    var content = '''
void f() {
  try {} on String catch (ex, st) {}
}
''';
    var expected = '''
void f() {
  try {} on String catch (ex, st) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_catch_with_on_with_modifications() async {
    var content = '''
void f(String x, StackTrace y) {
  try {} on String catch (ex, st) {
    ex = x;
    st = y;
  }
}
main() {
  f(null, null);
}
''';
    var expected = '''
void f(String? x, StackTrace? y) {
  try {} on String? catch (ex, st) {
    ex = x;
    st = y!;
  }
}
main() {
  f(null, null);
}
''';
    // Note: using allowErrors=true because variables introduced by a catch
    // clause are final
    await _checkSingleFileChanges(content, expected, allowErrors: true);
  }

  Future<void> test_class_alias_synthetic_constructor_with_parameters() async {
    var content = '''
void main() {
  D d = D(null);
}
class C {
  C(int i);
}
mixin M {}
class D = C with M;
''';
    var expected = '''
void main() {
  D d = D(null);
}
class C {
  C(int? i);
}
mixin M {}
class D = C with M;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_class_alias_synthetic_constructor_with_parameters_and_subclass() async {
    var content = '''
void main() {
  E e = E(null);
}
class C {
  C(int i);
}
mixin M {}
class D = C with M;
class E extends D {
  E(int i) : super(i);
}
''';
    var expected = '''
void main() {
  E e = E(null);
}
class C {
  C(int? i);
}
mixin M {}
class D = C with M;
class E extends D {
  E(int? i) : super(i);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_class_type_param_bound_references_class() async {
    var content = '''
class Node<T extends Node<T>> {
  final List<T> nodes = <T>[];
}
class C extends Node<C> {}
main() {
  var x = C();
  x.nodes.add(x);
}
''';
    var expected = '''
class Node<T extends Node<T>> {
  final List<T> nodes = <T>[];
}
class C extends Node<C> {}
main() {
  var x = C();
  x.nodes.add(x);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_class_with_default_constructor() async {
    var content = '''
void main() => _f(Foo());
_f(Foo f) {}
class Foo {}
''';
    var expected = '''
void main() => _f(Foo());
_f(Foo f) {}
class Foo {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_code_inside_switch_does_not_imply_non_null_intent() async {
    var content = '''
int _f(int i, int j) {
  switch (i) {
    case 0:
      return j + 1;
    default:
      return 0;
  }
}
int _g(int i, int j) {
  if (i == 0) {
    return _f(i, j);
  } else {
    return 0;
  }
}
main() {
  _g(0, null);
}
''';
    var expected = '''
int _f(int i, int? j) {
  switch (i) {
    case 0:
      return j! + 1;
    default:
      return 0;
  }
}
int _g(int i, int? j) {
  if (i == 0) {
    return _f(i, j);
  } else {
    return 0;
  }
}
main() {
  _g(0, null);
}
''';
    // Note: prior to the fix for https://github.com/dart-lang/sdk/issues/41407,
    // we would consider the use of `j` in `f` to establish non-null intent, so
    // the null check would be erroneously placed in `g`'s call to `f`.
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_collection_literal_typed_list() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g(<int>[x, y]);
}
g(List<int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g(<int>[x!, y!]);
}
g(List<int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_collection_literal_typed_map() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g(<int, int>{x: y});
}
g(Map<int/*!*/, int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g(<int, int>{x!: y!});
}
g(Map<int, int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_collection_literal_typed_set() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g(<int>{x, y});
}
g(Set<int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g(<int>{x!, y!});
}
g(Set<int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_collection_literal_untyped_list() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g([x, y]);
}
g(List<int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g([x!, y!]);
}
g(List<int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_collection_literal_untyped_map() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g({x: y});
}
g(Map<int/*!*/, int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g({x!: y!});
}
g(Map<int, int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_collection_literal_untyped_set() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g({x, y});
}
g(Set<int/*!*/>/*!*/ z) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g({x!, y!});
}
g(Set<int> z) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_comment_bang_implies_non_null_intent() async {
    var content = '''
void f(int/*!*/ i) {}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_comment_question_implies_nullable() async {
    var content = '''
void _f() {
  int/*?*/ i = 0;
}
''';
    var expected = '''
void _f() {
  int? i = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_conditional_assert_statement_does_not_imply_non_null_intent() async {
    var content = '''
void f(bool b, int i) {
  if (b) return;
  assert(i != null);
}
void g(bool b, int i) {
  if (b) f(b, i);
}
main() {
  g(true, null);
}
''';
    var expected = '''
void f(bool b, int? i) {
  if (b) return;
  assert(i != null);
}
void g(bool b, int? i) {
  if (b) f(b, i);
}
main() {
  g(true, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_conditional_dereference_does_not_imply_non_null_intent() async {
    var content = '''
void f(bool b, int i) {
  if (b) i.abs();
}
void g(bool b, int i) {
  if (b) f(b, i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(bool b, int? i) {
  if (b) i!.abs();
}
void g(bool b, int? i) {
  if (b) f(b, i);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_conditional_expression_futureOr() async {
    var content = '''
import 'dart:async';
FutureOr<int> f(bool b, FutureOr<int>/*!*/ n) => b ? n : 0;
''';
    var expected = '''
import 'dart:async';
FutureOr<int> f(bool b, FutureOr<int> n) => b ? n : 0;
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_conditional_expression_guard_subexpression() async {
    var content = '''
void f(String s, int x, int/*?*/ n) {
  s == null ? (x = n) : (x = s.length);
}
''';
    var expected = '''
void f(String? s, int? x, int? n) {
  s == null ? (x = n) : (x = s.length);
}
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_conditional_expression_guard_value_ifFalse() async {
    var content = 'int f(String s, int/*?*/ n) => s != null ? s.length : n;';
    var expected = 'int? f(String? s, int? n) => s != null ? s.length : n;';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_conditional_expression_guard_value_ifTrue() async {
    var content = 'int f(String s, int/*?*/ n) => s == null ? n : s.length;';
    var expected = 'int? f(String? s, int? n) => s == null ? n : s.length;';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void>
      test_conditional_non_null_usage_does_not_imply_non_null_intent() async {
    var content = '''
void _f(bool b, int i, int j) {
  if (b) i.gcd(j);
}
void _g(bool b, int i, int j) {
  if (b) _f(b, i, j);
}
main() {
  _g(false, 0, null);
}
''';
    var expected = '''
void _f(bool b, int i, int? j) {
  if (b) i.gcd(j!);
}
void _g(bool b, int i, int? j) {
  if (b) _f(b, i, j);
}
main() {
  _g(false, 0, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_conditional_usage_does_not_propagate_non_null_intent() async {
    var content = '''
void _f(int i) {
  assert(i != null);
}
void _g(bool b, int i) {
  if (b) _f(i);
}
void _h(bool b1, bool b2, int i) {
  if (b1) _g(b2, i);
}
main() {
  _h(true, false, null);
}
''';
    var expected = '''
void _f(int i) {
  assert(i != null);
}
void _g(bool b, int? i) {
  if (b) _f(i!);
}
void _h(bool b1, bool b2, int? i) {
  if (b1) _g(b2, i);
}
main() {
  _h(true, false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_conditionalExpression_typeParameter_bound() async {
    var content = '''
num _f1<T extends num>(bool b, num x, T y) => b ? x : y;
num _f2<T extends num>(bool b, num x, T y) => b ? x : y;
num _f3<T extends num>(bool b, num x, T y) => b ? x : y;
num _f4<T extends num>(bool b, num x, T y) => b ? x : y;

void main() {
  int x1 = _f1<int/*?*/>(true, 0, null);
  int x2 = _f2<int/*!*/>(true, 0, null);
  int x3 = _f3<int>(true, null, 0);
  int x4 = _f4<int>(true, 0, 0);
}
''';
    var expected = '''
num? _f1<T extends num?>(bool b, num x, T y) => b ? x : y;
num? _f2<T extends num>(bool b, num x, T? y) => b ? x : y;
num? _f3<T extends num>(bool b, num? x, T y) => b ? x : y;
num _f4<T extends num>(bool b, num x, T y) => b ? x : y;

void main() {
  int? x1 = _f1<int?>(true, 0, null) as int?;
  int? x2 = _f2<int>(true, 0, null) as int?;
  int? x3 = _f3<int>(true, null, 0) as int?;
  int x4 = _f4<int>(true, 0, 0) as int;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructor_field_formal_resolves_to_getter() async {
    var content = '''
class C {
  int get i => 0;
  C(this.i);
}
''';
    // It doesn't matter what the migration produces; we just want to make sure
    // there isn't a crash.
    await _checkSingleFileChanges(content, anything, allowErrors: true);
  }

  Future<void> test_constructor_field_formal_resolves_to_setter() async {
    var content = '''
class C {
  set i(int value) {}
  C(this.i);
}
''';
    // It doesn't matter what the migration produces; we just want to make sure
    // there isn't a crash.
    await _checkSingleFileChanges(content, anything, allowErrors: true);
  }

  Future<void> test_constructor_field_formal_unresolved() async {
    var content = '''
class C {
  C(this.i);
}
''';
    // It doesn't matter what the migration produces; we just want to make sure
    // there isn't a crash.
    await _checkSingleFileChanges(content, anything, allowErrors: true);
  }

  Future<void> test_constructor_optional_param_factory() async {
    var content = '''
class C {
  factory C([int x]) => C._();
  C._([int x = 0]);
}
''';
    var expected = '''
class C {
  factory C([int? x]) => C._();
  C._([int x = 0]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_constructor_optional_param_factory_redirecting_named() async {
    var content = '''
class C {
  factory C({int x}) = C._;
  C._({int x = 0});
}
''';
    var expected = '''
class C {
  factory C({int x}) = C._;
  C._({int x = 0});
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_constructor_optional_param_factory_redirecting_unnamed() async {
    var content = '''
class C {
  factory C([int x]) = C._;
  C._([int x = 0]);
}
''';
    var expected = '''
class C {
  factory C([int x]) = C._;
  C._([int x = 0]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructor_optional_param_normal() async {
    var content = '''
class C {
  C([int x]);
}
''';
    var expected = '''
class C {
  C([int? x]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructor_optional_param_redirecting() async {
    var content = '''
class C {
  C([int x]) : this._();
  C._([int x = 0]);
}
''';
    var expected = '''
class C {
  C([int? x]) : this._();
  C._([int x = 0]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructorDeclaration_factory_non_null_return() async {
    var content = '''
class C {
  C._();
  factory C() {
    C c = f();
    return c;
  }
}
C f() => null;
''';
    var expected = '''
class C {
  C._();
  factory C() {
    C c = f()!;
    return c;
  }
}
C? f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructorDeclaration_factory_simple() async {
    var content = '''
class C {
  C._();
  factory C(int i) => C._();
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  C._();
  factory C(int? i) => C._();
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructorDeclaration_named() async {
    var content = '''
class C {
  C.named(int i);
}
main() {
  C.named(null);
}
''';
    var expected = '''
class C {
  C.named(int? i);
}
main() {
  C.named(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_constructorDeclaration_namedParameter() async {
    var content = '''
class C {
  C({Key key});
}
class Key {}
''';
    var expected = '''
class C {
  C({Key? key});
}
class Key {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_convert_required() async {
    addMetaPackage();
    var content = '''
import 'package:meta/meta.dart';
void f({@required String s}) {}
''';
    var expected = '''
import 'package:meta/meta.dart';
void f({required String s}) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_custom_future() async {
    var content = '''
class CustomFuture<T> implements Future<T> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

_f(CustomFuture<List<int>> x) async => (await x).first;
''';
    var expected = '''
class CustomFuture<T> implements Future<T> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

_f(CustomFuture<List<int>> x) async => (await x).first;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_assignment_field() async {
    var content = '''
class C {
  int x = 0;
}
void f(C c) {
  c.x = null;
}
''';
    var expected = '''
class C {
  int? x = 0;
}
void f(C c) {
  c.x = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_assignment_field_in_cascade() async {
    var content = '''
class C {
  int x = 0;
}
void f(C c) {
  c..x = null;
}
''';
    var expected = '''
class C {
  int? x = 0;
}
void f(C c) {
  c..x = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_assignment_local() async {
    var content = '''
void main() {
  int i = 0;
  i = null;
}
''';
    var expected = '''
void main() {
  int? i = 0;
  i = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_assignment_setter() async {
    var content = '''
class C {
  void set s(int value) {}
}
void f(C c) {
  c.s = null;
}
''';
    var expected = '''
class C {
  void set s(int? value) {}
}
void f(C c) {
  c.s = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_field_read() async {
    var content = '''
class C {
  int/*?*/ f = 0;
}
int f(C c) => c.f;
''';
    var expected = '''
class C {
  int? f = 0;
}
int? f(C c) => c.f;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_function_return_type() async {
    var content = '''
int Function() _f(int Function() x) => x;
int g() => null;
main() {
  _f(g);
}
''';
    var expected = '''
int? Function() _f(int? Function() x) => x;
int? g() => null;
main() {
  _f(g);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_generic_contravariant_inward() async {
    var content = '''
class C<T> {
  void f(T t) {}
}
void g(C<int> c, int i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''';

    // Default behavior is to add nullability at the call site.  Rationale: this
    // is correct in the common case where the generic parameter represents the
    // type of an item in a container.  Also, if there are many callers that are
    // largely independent, adding nullability to the callee would likely
    // propagate to a field in the class, and thence (via return values of other
    // methods) to most users of the class.  Whereas if we add nullability at
    // the call site it's possible that other call sites won't need it.
    var expected = '''
class C<T> {
  void f(T t) {}
}
void g(C<int?> c, int? i) {
  c.f(i);
}
void test(C<int?> c) {
  g(c, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_generic_contravariant_inward_function() async {
    var content = '''
T f<T>(T t) => t;
int g(int x) => f<int>(x);
void h() {
  g(null);
}
''';

    // As with the generic class case (see
    // [test_data_flow_generic_contravariant_inward_function]), we favor adding
    // nullability at the call site, so that other uses of `f` don't necessarily
    // see a nullable return value.
    var expected = '''
T f<T>(T t) => t;
int? g(int? x) => f<int?>(x);
void h() {
  g(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_data_flow_generic_contravariant_inward_using_core_class() async {
    var content = '''
void f(List<int> x, int i) {
  x.add(i);
}
void test(List<int> x) {
  f(x, null);
}
''';
    var expected = '''
void f(List<int?> x, int? i) {
  x.add(i);
}
void test(List<int?> x) {
  f(x, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_generic_covariant_outward() async {
    var content = '''
class C<T> {
  T getValue() => null;
}
int f(C<int> x) => x.getValue();
''';
    var expected = '''
class C<T> {
  T? getValue() => null;
}
int? f(C<int> x) => x.getValue();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_generic_covariant_substituted() async {
    var content = '''
abstract class C<T> {
  T getValue();
}
int f(C<int/*?*/> x) => x.getValue();
''';
    var expected = '''
abstract class C<T> {
  T getValue();
}
int? f(C<int?> x) => x.getValue();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_indexed_get_index_value() async {
    var content = '''
class C {
  int operator[](int i) => 1;
}
int f(C c) => c[null];
''';
    var expected = '''
class C {
  int operator[](int? i) => 1;
}
int f(C c) => c[null];
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_indexed_get_value() async {
    var content = '''
class C {
  int operator[](int i) => null;
}
int _f(C c) => c[0];
''';
    var expected = '''
class C {
  int? operator[](int? i) => null;
}
int? _f(C c) => c[0];
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): doesn't check anything, arguments are nullable by default.
  Future<void> test_data_flow_indexed_set_index_value() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void _f(C c) {
  c[null] = 0;
}
''';
    var expected = '''
class C {
  void operator[]=(int? i, int? j) {}
}
void _f(C c) {
  c[null] = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): doesn't check anything, arguments are nullable by default.
  Future<void> test_data_flow_indexed_set_index_value_in_cascade() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void _f(C c) {
  c..[null] = 0;
}
''';
    var expected = '''
class C {
  void operator[]=(int? i, int? j) {}
}
void _f(C c) {
  c..[null] = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): doesn't check anything, arguments are nullable by default.
  Future<void> test_data_flow_indexed_set_value() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void _f(C c) {
  c[0] = null;
}
''';
    var expected = '''
class C {
  void operator[]=(int? i, int? j) {}
}
void _f(C c) {
  c[0] = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_inward() async {
    var content = '''
int f(int i) => 0;
int g(int i) => f(i);
void test() {
  g(null);
}
''';

    var expected = '''
int f(int? i) => 0;
int g(int? i) => f(i);
void test() {
  g(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_inward_missing_type() async {
    var content = '''
int f(int i) => 0;
int g(i) => f(i); // TODO(danrubel): suggest type
void test() {
  g(null);
}
''';

    var expected = '''
int f(int? i) => 0;
int g(i) => f(i); // TODO(danrubel): suggest type
void test() {
  g(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_local_declaration() async {
    var content = '''
void f(int i) {
  int j = i;
}
main() {
  f(null);
}
''';
    var expected = '''
void f(int? i) {
  int? j = i;
}
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_local_reference() async {
    var content = '''
void f(int i) {}
void g(int i) {
  int j = i;
  f(i);
}
main() {
  g(null);
}
''';
    var expected = '''
void f(int? i) {}
void g(int? i) {
  int? j = i;
  f(i);
}
main() {
  g(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_method_call_in_cascade() async {
    var content = '''
class C {
  void m(int x) {}
}
void f(C c) {
  c..m(null);
}
''';
    var expected = '''
class C {
  void m(int? x) {}
}
void f(C c) {
  c..m(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_outward() async {
    var content = '''
int _f(int i) => null;
int _g(int i) => _f(i);
''';

    var expected = '''
int? _f(int i) => null;
int? _g(int i) => _f(i);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_data_flow_outward_missing_type() async {
    var content = '''
_f(int i) => null; // TODO(danrubel): suggest type
int _g(int i) => _f(i);
''';

    var expected = '''
_f(int i) => null; // TODO(danrubel): suggest type
int? _g(int i) => _f(i);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_definitely_assigned_value() async {
    var content = '''
String f(bool b) {
  String s;
  if (b) {
    s = 'true';
  } else {
    s = 'false';
  }
  return s;
}
''';
    var expected = '''
String f(bool b) {
  String s;
  if (b) {
    s = 'true';
  } else {
    s = 'false';
  }
  return s;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): we don't discard anymore, remove?
  Future<void> test_discard_simple_condition_keep_else() async {
    var content = '''
int f(int i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''';

    var expected = '''
int? f(int? i) {
  if (i == null) {
    return null;
  } else {
    return i + 1;
  }
}
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  // TODO(yanok): we don't discard anymore, remove?
  Future<void> test_discard_simple_condition_keep_then() async {
    var content = '''
int f(int i) {
  if (i != null) {
    return i + 1;
  } else {
    return null;
  }
}
''';

    var expected = '''
int? f(int? i) {
  if (i != null) {
    return i + 1;
  } else {
    return null;
  }
}
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_do_not_add_question_to_null_type() async {
    var content = '''
Null f() => null;
''';
    var expected = '''
Null f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_do_not_propagate_non_null_intent_into_callback() async {
    var content = '''
void f(int/*!*/ Function(int) callback) {
  callback(null);
}
int g(int x) => x;
void test() {
  f(g);
}
''';
    // Even though `g` is passed to `f`'s `callback` parameter, non-null intent
    // is not allowed to propagate backward from the return type of `callback`
    // to the return type of `g`, because `g` might be used elsewhere in a
    // context where it's important for its return type to be nullable.  So no
    // null check is added to `g`, and instead a cast (which is guaranteed to
    // fail) is added at the site of the call to `f`.
    //
    // Note: https://github.com/dart-lang/sdk/issues/40471 tracks the fact that
    // we ought to alert the user to the presence of such casts.
    var expected = '''
void f(int Function(int?) callback) {
  callback(null);
}
int? g(int? x) => x;
void test() {
  f(g as int Function(int?));
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_do_not_surround_named_expression() async {
    var content = '''
void f(int/*?*/ x, int/*?*/ y) {
  g(named: <int>[x, y]);
}
g({List<int/*!*/>/*!*/ named}) {}
''';
    var expected = '''
void f(int? x, int? y) {
  g(named: <int>[x!, y!]);
}
g({required List<int> named}) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_downcast_dynamic_function_to_functionType() async {
    var content = '''
void _f(Function a) {
  int Function<T>(String y) f1 = a;
  Function b = null;
  int Function<T>(String y) f2 = b;
}
''';
    // Don't assume any new nullabilities, but keep known nullabilities.
    var expected = '''
void _f(Function a) {
  int Function<T>(String y) f1 = a as int Function<T>(String);
  Function? b = null;
  int Function<T>(String y)? f2 = b as int Function<T>(String)?;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_downcast_dynamic_to_functionType() async {
    var content = '''
void _f(dynamic a) {
  int Function<T>(String y) f1 = a;
  dynamic b = null;
  int Function<T>(String y) f2 = b;
}
''';
    // Don't assume any new nullabilities, but keep known nullabilities.
    var expected = '''
void _f(dynamic a) {
  int Function<T>(String y) f1 = a;
  dynamic b = null;
  int Function<T>(String y)? f2 = b;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_downcast_dynamic_type_argument() async {
    // This pattern is common and seems to have this as a best migration. It is
    // less clear, but plausible, that this holds for other types of type
    // parameter downcasts.
    var content = '''
List<int> _f(List a) => a;
void main() {
  _f(<int>[null]);
}
''';

    var expected = '''
List<int?> _f(List a) => a as List<int?>;
void main() {
  _f(<int?>[null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @failingTest
  Future<void> test_downcast_not_widest_type_type_parameters() async {
    // Fails because a hard assignment from List<int/*1*/> to List<int/*2*/>
    // doesn't create a hard edge from 1 to 2. Perhaps this is correct. In this
    // example it seems incorrect.
    var content = '''
void f(dynamic a) {
  List<int> hardToNonNullNonNull = a;
  List<int> hardToNullNonNull = a;
  List<int> hardToNonNullNull = a;
  List<int/*!*/>/*!*/ nonNullNonNull;
  List<int/*?*/>/*!*/ nullNonNull;
  List<int/*!*/>/*?*/ nonNullNull;
  nonNullNonNull = hardToNonNullNonNull
  nonNullNull = hardToNonNullNull
  nullNonNull = hardToNullNonNull
}
''';
    var expected = '''
void f(dynamic a) {
  List<int> hardToNonNullNonNull = a;
  List<int?> hardToNullNonNull = a;
  List<int>? hardToNonNullNull = a;
  List<int> nonNullNonNull;
  List<int?> nullNonNull;
  List<int>? nonNullNull;
  nonNullNonNull = hardToNonNullNonNull
  nonNullNull = hardToNonNullNull
  nullNonNull = hardToNullNonNull
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_downcast_to_null() async {
    // This probably doesn't arise too often for real-world code, since it is
    // most likely a mistake.  Still, we want to make sure we don't crash and
    // fail at compile-time instead.
    var content = '''
test() {
  var x = List.filled(3, null);
  x[0] = 1;
}
''';
    var expected = '''
test() {
  var x = List.filled(3, null);
  x[0] = 1;
}
''';
    // Note: using allowErrors=true because passing `1` where `Null` is
    // expected is an error.
    await _checkSingleFileChanges(content, expected, allowErrors: true);
  }

  Future<void> test_downcast_type_argument_preserve_nullability() async {
    // There are no examples in front of us yet where anyone downcasts a type
    // with a nullable type parameter. This is maybe correct, maybe not, and it
    // unblocks us to find out which at a later point in time.
    var content = '''
List<int> _f(Iterable<num> a) => a;
void main() {
  _f(<num>[null]);
}
''';

    var expected = '''
List<int?> _f(Iterable<num?> a) => a as List<int?>;
void main() {
  _f(<num?>[null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @failingTest
  Future<void> test_downcast_widest_type_from_related_type_parameters() async {
    var content = '''
List<int> f(Iterable<int/*?*/> a) => a;
''';
    var expected = '''
List<int?> f(Iterable<int?> a) => a;
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39368')
  Future<void> test_downcast_widest_type_from_top_type_parameters() async {
    var content = '''
List<int> f1(dynamic a) => a;
List<int> f2(Object b) => b;
''';
    // Note: even though the type `dynamic` permits `null`, the migration engine
    // sees that there is no code path that could cause `f1` to be passed a null
    // value, so it leaves its return type as non-nullable.
    var expected = '''
List<int?> f1(dynamic a) => a;
List<int?> f2(Object b) => b;
''';
    await _checkSingleFileChanges(content, expected);
  }

  @failingTest
  Future<void>
      test_downcast_widest_type_from_unrelated_type_parameters() async {
    var content = '''
abstract class C<A, B> implements List<A> {}
C<int, num> f(List<int> a) => a;
''';
    var expected = '''
abstract class C<A, B> implements List<A> {}
C<int, num?> f(List<int> a) => a;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_dynamic_dispatch_to_object_method() async {
    var content = '''
String f(dynamic x) => x.toString();
''';
    var expected = '''
String f(dynamic x) => x.toString();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_dynamic_method_call() async {
    var content = '''
class C {
  int g(int i) => i;
}
int f(bool b, dynamic d) {
  if (b) return 0;
  return d.g(null);
}
main() {
  f(true, null);
  f(false, C());
}
''';
    // TODO(yanok): this part is not tested anymore, since now g's argument
    // is nullable by default.
    // `d.g(null)` is a dynamic call, so we can't tell that it will target `C.g`
    // at runtime.  So we can't figure out that we need to make g's argument and
    // return types nullable.
    //
    // We do, however, make f's return type nullable, since there is no way of
    // knowing whether a dynamic call will return `null`.
    var expected = '''
class C {
  int? g(int? i) => i;
}
int? f(bool b, dynamic d) {
  if (b) return 0;
  return d.g(null);
}
main() {
  f(true, null);
  f(false, C());
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_dynamic_property_access() async {
    var content = '''
class C {
  int get g => 0;
}
int f(bool b, dynamic d) {
  if (b) return 0;
  return d.g;
}
main() {
  f(true, null);
  f(false, C());
}
''';
    var expected = '''
class C {
  int get g => 0;
}
int? f(bool b, dynamic d) {
  if (b) return 0;
  return d.g;
}
main() {
  f(true, null);
  f(false, C());
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_dynamic_toString() async {
    var content = '''
String f(dynamic x) => x.toString();
''';
    var expected = '''
String f(dynamic x) => x.toString();
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40174')
  Future<void> test_eliminate_dead_if_inside_for_element() async {
    var content = '''
List<int> _f(List<int/*!*/> xs) => [for(var x in xs) if (x == null) 1];
''';
    var expected = '''
List<int> _f(List<int> xs) => [];
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_enum() async {
    var content = '''
enum E {
  value
}

E f() => E.value;
int g() => f().index;

void h() {
  for(var value in E.values) {}
  E.values.forEach((value) {});

  f().toString();
  f().runtimeType;
  f().hashCode;
  f().noSuchMethod(throw '');
  f() == f();
}
''';
    var expected = '''
enum E {
  value
}

E f() => E.value;
int g() => f().index;

void h() {
  for(var value in E.values) {}
  E.values.forEach((value) {});

  f().toString();
  f().runtimeType;
  f().hashCode;
  f().noSuchMethod(throw '');
  f() == f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_exact_nullability_counterexample() async {
    var content = '''
void f(List<int> x) {
  x.add(1);
}
void g() {
  f([null]);
}
void h(List<int> x) {
  f(x);
}
''';
    // The `null` in `g` causes `f`'s `x` argument to have type `List<int?>`.
    // Even though `f` calls a method that uses `List`'s type parameter
    // contravariantly (the `add` method), that is not sufficient to cause exact
    // nullability propagation, since value passed to `add` has a
    // non-nullable type.  So nullability is *not* propagated back to `h`.
    var expected = '''
void f(List<int?> x) {
  x.add(1);
}
void g() {
  f([null]);
}
void h(List<int> x) {
  f(x);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_exact_nullability_doesnt_affect_function_args() async {
    // Test attempting to create a bug from #40625. Currently passes, but if it
    // breaks, that bug may need to be reopened.
    var content = '''
class C<T> {
  int Function(T) f;
}
void main(dynamic d) {
  C<String> c = d;
  int Function(String) f1 = c.f; // should not have a nullable arg
  c.f(null); // exact nullability induced here
}
''';
    var expected = '''
class C<T> {
  int Function(T)? f;
}
void main(dynamic d) {
  C<String?> c = d;
  int Function(String)? f1 = c.f; // should not have a nullable arg
  c.f!(null); // exact nullability induced here
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_exact_nullability_doesnt_affect_function_returns() async {
    // Test attempting to create a bug from #40625. Currently passes, but if it
    // breaks, that bug may need to be reopened.
    var content = '''
class C<T> {
  T Function(String) f;
}
int Function(String) f1; // should not have a nullable return
void main(dynamic d) {
  C<int> c = d;
  c.f = f1;
  c.f = (_) => null; // exact nullability induced here
}
''';
    var expected = '''
class C<T> {
  T Function(String)? f;
}
int Function(String)? f1; // should not have a nullable return
void main(dynamic d) {
  C<int?> c = d;
  c.f = f1;
  c.f = (_) => null; // exact nullability induced here
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_exact_nullability_doesnt_affect_typedef_args() async {
    // Test attempting to create a bug from #40625. Currently passes, but if it
    // breaks, that bug may need to be reopened.
    var content = '''
typedef F<T> = int Function(T);
F<String> f1;

void main() {
  f1(null); // induce exact nullability
  int Function(String) f2 = f1; // shouldn't have a nullable arg
}
''';
    var expected = '''
typedef F<T> = int Function(T);
F<String?>? f1;

void main() {
  f1!(null); // induce exact nullability
  int Function(String)? f2 = f1; // shouldn't have a nullable arg
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_exact_nullability_doesnt_affect_typedef_returns() async {
    // Test attempting to create a bug from #40625. Currently passes, but if it
    // breaks, that bug may need to be reopened.
    var content = '''
typedef F<T> = T Function(String);
int Function(String) f1; // should not have a nullable return
void main() {
  F<int> f2 = f1;
  f2 = (_) => null; // exact nullability induced here
}
''';
    var expected = '''
typedef F<T> = T Function(String);
int Function(String)? f1; // should not have a nullable return
void main() {
  F<int?>? f2 = f1;
  f2 = (_) => null; // exact nullability induced here
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/41409')
  Future<void> test_exact_nullability_in_nested_list() async {
    var content = '''
f(List<int/*?*/> y) {
  var x = <List<int>>[];
  x.add(y);
}
''';
    var expected = '''
f(List<int?> y) {
  var x = <List<int?>>[];
  x.add(y);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_explicit_nullable_overrides_hard_edge() async {
    var content = '''
int f(int/*?*/ i) => i + 1;
''';
    var expected = '''
int f(int? i) => i! + 1;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_expression_bang_hint() async {
    var content = '''
int f(int/*?*/ i) => i/*!*/;
''';
    var expected = '''
int f(int? i) => i!;
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_expression_bang_hint_in_as() async {
    var content = '''
int f(num/*?*/ i) => i as int/*!*/;
''';
    var expected = '''
int f(num? i) => i as int;
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/41788')
  Future<void> test_expression_bang_hint_in_as_wrapped() async {
    var content = '''
int f(num/*?*/ i) => (i as int)/*!*/;
''';
    var expected = '''
int f(num? i) => (i as int?)!;
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_expression_bang_hint_unnecessary() async {
    var content = '''
int/*?*/ f(int/*?*/ i) => i/*!*/;
''';
    // The user requested a null check so we should add it even if it's not
    // required to avoid compile errors.
    var expected = '''
int? f(int? i) => i!;
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_expression_bang_hint_unnecessary_literal() async {
    var content = 'int/*?*/ f() => 1/*!*/;';
    // The user requested a null check so we should add it even if it's not
    // required to avoid compile errors.
    var expected = 'int? f() => 1!;';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_expression_bang_hint_with_cast() async {
    var content = 'int f(Object/*?*/ o) => o/*!*/;';
    var expected = 'int f(Object? o) => o! as int;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_expression_nullable_cast_then_checked() async {
    var content = '''
int/*!*/ f(num/*?*/ i) => (i as int);
''';
    var expected = '''
int f(num? i) => (i as int);
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/41788')
  Future<void> test_expression_wrapped_with_null_check_and_null_intent() async {
    var content = '''
int/*!*/ f(int/*?*/ i) => (i)/*!*/;
''';
    var expected = '''
int f(int? i) => i!;
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_extension_complex() async {
    var content = '''
import 'already_migrated.dart';
class D<V> extends C<V> {}
abstract class Foo {
  D<List<int>> get z;
  List<int> test() => z.x ?? [];
}
''';
    var alreadyMigrated = '''
// @dart=2.12
extension E<T> on C<T> {
  T? get x => y;
}
class C<U> {
  U? y;
}
''';
    var expected = '''
import 'already_migrated.dart';
class D<V> extends C<V> {}
abstract class Foo {
  D<List<int>> get z;
  List<int> test() => z.x ?? [];
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/already_migrated.dart': alreadyMigrated
    });
  }

  Future<void> test_extension_extended_type_nullability_intent() async {
    var content = '''
extension E on C {
  String foo() => this.bar();
}

class C {
  String bar() => null;
}

void test(C c, bool b) {
  if (b) {
    c.foo();
  }
}

main() {
  test(null, false);
}
''';
    // The call to `bar` from `foo` should be taken as a demonstration that the
    // extension E is not intended to apply to nullable types, so the call to
    // `foo` should be null checked.
    var expected = '''
extension E on C {
  String? foo() => this.bar();
}

class C {
  String? bar() => null;
}

void test(C? c, bool b) {
  if (b) {
    c!.foo();
  }
}

main() {
  test(null, false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_non_nullable_binary() async {
    var content = '''
class C {}
extension E on C/*!*/ {
  void operator+(int other) {}
}
void f(C c, bool b) {
  if (b) {
    c + 0;
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E on C {
  void operator+(int? other) {}
}
void f(C? c, bool b) {
  if (b) {
    c! + 0;
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_non_nullable_generic() async {
    var content = '''
class C {}
extension E<T extends Object/*!*/> on T/*!*/ {
  void m() {}
}
void f(C c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E<T extends Object> on T {
  void m() {}
}
void f(C? c, bool b) {
  if (b) {
    c!.m();
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_non_nullable_index() async {
    var content = '''
class C {}
extension E on C/*!*/ {
  void operator[](int index) {}
}
void f(C c, bool b) {
  if (b) {
    c[0];
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E on C {
  void operator[](int? index) {}
}
void f(C? c, bool b) {
  if (b) {
    c![0];
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_non_nullable_method() async {
    var content = '''
class C {}
extension E on C/*!*/ {
  void m() {}
}
void f(C c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E on C {
  void m() {}
}
void f(C? c, bool b) {
  if (b) {
    c!.m();
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_non_nullable_prefix() async {
    var content = '''
class C {}
extension E on C/*!*/ {
  void operator-() {}
}
void f(C c, bool b) {
  if (b) {
    -c;
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E on C {
  void operator-() {}
}
void f(C? c, bool b) {
  if (b) {
    -c!;
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_nullable() async {
    var content = '''
class C {}
extension E on C/*?*/ {
  void m() {}
}
void f(C c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E on C? {
  void m() {}
}
void f(C? c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_nullable_generic() async {
    var content = '''
class C {}
extension E<T extends Object/*?*/> on T/*!*/ {
  void m() {}
}
void f(C c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    var expected = '''
class C {}
extension E<T extends Object?> on T {
  void m() {}
}
void f(C? c, bool b) {
  if (b) {
    c.m();
  }
}
void g() => f(null, false);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_null_check_target() async {
    var content = '''
extension E on int/*!*/ {
  int get plusOne => this + 1;
}
int f(int/*?*/ x) => x.plusOne;
''';
    var expected = '''
extension E on int {
  int get plusOne => this + 1;
}
int f(int? x) => x!.plusOne;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_nullable_target() async {
    var content = '''
extension E on int {
  int get one => 1;
}
int f(int/*?*/ x) => x.one;
''';
    var expected = '''
extension E on int? {
  int get one => 1;
}
int f(int? x) => x.one;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_nullableOnType_addsNullCheckToThis() async {
    var content = '''
extension E on String /*?*/ {
  void m() => this.length;
}
''';
    var expected = '''
extension E on String? {
  void m() => this!.length;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_nullableOnType_typeArgument() async {
    var content = '''
extension E on List<String> {
  void m() {}
}
void _f(List<String> list) => list.m();
void g() => _f([null]);
''';
    var expected = '''
extension E on List<String?> {
  void m() {}
}
void _f(List<String?> list) => list.m();
void g() => _f([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40023')
  Future<void> test_extension_nullableOnType_typeVariable() async {
    var content = '''
extension E<T> on List<T> {
  void m() {}
}
void f<U>(List<U> list) => list.m();
void g() => f([null]);
''';
    var expected = '''
extension E<T> on List<T?> {
  void m() {}
}
void f<U>(List<U?> list) => list.m();
void g() => f([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_nullableOnType_viaExplicitInvocation() async {
    var content = '''
class C {}
extension E on C {
  void m() {}
}
void f() => E(null).m();
''';
    var expected = '''
class C {}
extension E on C? {
  void m() {}
}
void f() => E(null).m();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_nullableOnType_viaImplicitInvocation() async {
    var content = '''
class C {}
extension E on C {
  void m() {}
}
void f(C c) => c.m();
void g() => f(null);
''';
    var expected = '''
class C {}
extension E on C? {
  void m() {}
}
void f(C? c) => c.m();
void g() => f(null);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_on_generic_type() async {
    var content = '''
class C<T> {
  final T value;
  C(this.value);
}
extension E<T> on Future<C<T/*?*/>> {
  Future<T> get asyncValue async => (await this).value;
}
''';
    var expected = '''
class C<T> {
  final T value;
  C(this.value);
}
extension E<T> on Future<C<T?>> {
  Future<T?> get asyncValue async => (await this).value;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_on_type_param_implementation() async {
    var content = '''
abstract class C {
  C _clone();
}
extension Cloner<T extends C> on T {
  T clone() => _clone() as T;
}
''';
    var expected = '''
abstract class C {
  C _clone();
}
extension Cloner<T extends C> on T {
  T clone() => _clone() as T;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_on_type_param_usage() async {
    var content = '''
abstract class C {
  C _clone();
}
extension Cloner<T extends C> on T {
  T clone() => throw Exception();
}
C _f(C c) => c.clone();
''';
    var expected = '''
abstract class C {
  C _clone();
}
extension Cloner<T extends C> on T {
  T clone() => throw Exception();
}
C _f(C c) => c.clone();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_on_type_substitution() async {
    var content = '''
extension E<T> on T {
  T get foo => this;
}
List<int> _f(List<int/*?*/> x) => x.foo;
''';
    // To see that the return type of `f` must be `List<int?`, the migration
    // tool needs to substitute the actual type argument (`T=List<int?>`) into
    // the extension's "on" type.
    var expected = '''
extension E<T> on T {
  T get foo => this;
}
List<int?> _f(List<int?> x) => x.foo;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_override() async {
    var content = '''
extension E on int {
  int get plusOne => this + 1;
}
int _f(int x) => E(x).plusOne;
''';
    var expected = '''
extension E on int {
  int get plusOne => this + 1;
}
int _f(int x) => E(x).plusOne;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_override_null_check_target() async {
    var content = '''
extension E on int/*!*/ {
  int get plusOne => this + 1;
}
int f(int/*?*/ x) => E(x).plusOne;
''';
    var expected = '''
extension E on int {
  int get plusOne => this + 1;
}
int f(int? x) => E(x!).plusOne;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_override_nullable_result_type() async {
    var content = '''
extension E on int {
  int get nullValue => null;
}
int _f(int x) => E(x).nullValue;
''';
    var expected = '''
extension E on int {
  int? get nullValue => null;
}
int? _f(int x) => E(x).nullValue;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_override_nullable_target() async {
    var content = '''
extension E on int {
  int get one => 1;
}
int f(int/*?*/ x) => E(x).one;
''';
    var expected = '''
extension E on int? {
  int get one => 1;
}
int f(int? x) => E(x).one;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_extension_use_can_imply_non_null_intent() async {
    var content = '''
extension E<T extends Object/*!*/> on T/*!*/ {
  void foo() {}
}
f(int i) {
  i.foo();
}
g(bool b, int/*?*/ j) {
  if (b) {
    f(j);
  }
}
''';
    // Since the extension declaration says `T extends Object/*!*/`, `i` will
    // not be made nullable.
    var expected = '''
extension E<T extends Object> on T {
  void foo() {}
}
f(int i) {
  i.foo();
}
g(bool b, int? j) {
  if (b) {
    f(j!);
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_constructor() async {
    var content = '''
class C {
  external C(dynamic Function(dynamic) callback);
  static Object g(Object Function(Object) callback) => C(callback);
}
''';
    var expected = '''
class C {
  external C(dynamic Function(dynamic)? callback);
  static Object g(Object Function(Object?)? callback) => C(callback);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_function() async {
    var content = '''
external dynamic f();
Object g() => f();
''';
    var expected = '''
external dynamic f();
Object? g() => f();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_function_implicit_return() async {
    var content = '''
external f();
Object g() => f();
''';
    var expected = '''
external f();
Object? g() => f();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_function_implicit_variance() async {
    var content = '''
external void f(callback(x));
void g(Object Function(Object) callback) => f(callback);
''';
    var expected = '''
external void f(callback(x)?);
void g(Object Function(Object?)? callback) => f(callback);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_function_implicit_variance_complex() async {
    var content = '''
external void f(callback(x()));
void g(Object Function(Object Function()) callback) => f(callback);
''';
    var expected = '''
external void f(callback(x())?);
void g(Object Function(Object? Function())? callback) => f(callback);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_function_variance() async {
    var content = '''
external void f(dynamic Function(dynamic) callback);
void g(Object Function(Object) callback) => f(callback);
''';
    var expected = '''
external void f(dynamic Function(dynamic)? callback);
void g(Object Function(Object?)? callback) => f(callback);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_method() async {
    var content = '''
class C {
  external dynamic f();
  Object g() => f();
}
''';
    var expected = '''
class C {
  external dynamic f();
  Object? g() => f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_external_method_implicit() async {
    var content = '''
class C {
  external f();
  Object g() => f();
}
''';
    var expected = '''
class C {
  external f();
  Object? g() => f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_final_uninitialized_used() async {
    var content = '''
class C {
  final String s;

  f() {
    g(s);
  }
}
g(String /*!*/ s) {}
''';
    var expected = '''
class C {
  late final String s;

  f() {
    g(s);
  }
}
g(String s) {}
''';
    // Note: using allowErrors=true because an uninitialized field is an error
    await _checkSingleFileChanges(content, expected, allowErrors: true);
  }

  Future<void> test_field_formal_param_typed() async {
    var content = '''
class C {
  int i;
  C(int this.i);
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  int? i;
  C(int? this.i);
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_formal_param_typed_non_nullable() async {
    var content = '''
class C {
  int/*!*/ i;
  C(int this.i);
}
void f(int i, bool b) {
  if (b) {
    C(i);
  }
}
main() {
  f(null, false);
}
''';
    var expected = '''
class C {
  int i;
  C(int this.i);
}
void f(int? i, bool b) {
  if (b) {
    C(i!);
  }
}
main() {
  f(null, false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_formal_param_untyped() async {
    var content = '''
class C {
  int i;
  C(this.i);
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  int? i;
  C(this.i);
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_formal_parameters_do_not_promote() async {
    var content = '''
class A {}

class B extends A {}

class C extends A {}

abstract class D {
  final A x;
  D(this.x) {
    if (x is B) {
      visitB(x);
    } else {
      visitC(x as C);
    }
  }

  void visitB(B b);

  void visitC(C c);
}
''';
    var expected = '''
class A {}

class B extends A {}

class C extends A {}

abstract class D {
  final A x;
  D(this.x) {
    if (x is B) {
      visitB(x as B);
    } else {
      visitC(x as C);
    }
  }

  void visitB(B? b);

  void visitC(C? c);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initialized_at_declaration_site() async {
    var content = '''
class C {
  int i = 0;
  C();
}
''';
    var expected = '''
class C {
  int i = 0;
  C();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_field_initialized_at_declaration_site_no_constructor() async {
    var content = '''
class C {
  int i = 0;
}
''';
    var expected = '''
class C {
  int i = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initialized_in_constructor() async {
    var content = '''
class C {
  int i;
  C() : i = 0;
}
''';
    var expected = '''
class C {
  int i;
  C() : i = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_field_initialized_in_constructor_with_factories_and_redirects() async {
    var content = '''
class C {
  int i;
  C() : i = 0;
  factory C.factoryConstructor() => C();
  factory C.factoryRedirect() = D;
  C.redirect() : this();
}
class D extends C {}
''';
    var expected = '''
class C {
  int i;
  C() : i = 0;
  factory C.factoryConstructor() => C();
  factory C.factoryRedirect() = D;
  C.redirect() : this();
}
class D extends C {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initializer_simple() async {
    var content = '''
class C {
  int f;
  C(int i) : f = i;
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  int? f;
  C(int? i) : f = i;
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initializer_typed_list_literal() async {
    var content = '''
class C {
  List<int> f;
  C() : f = <int>[null];
}
''';
    var expected = '''
class C {
  List<int?> f;
  C() : f = <int?>[null];
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initializer_untyped_list_literal() async {
    var content = '''
class C {
  List<int> f;
  C() : f = [null];
}
''';
    var expected = '''
class C {
  List<int?> f;
  C() : f = [null];
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initializer_untyped_map_literal() async {
    var content = '''
class C {
  Map<String, int> f;
  C() : f = {"foo": null};
}
''';
    var expected = '''
class C {
  Map<String, int?> f;
  C() : f = {"foo": null};
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_initializer_untyped_set_literal() async {
    var content = '''
class C {
  Set<int> f;
  C() : f = {null};
}
''';
    var expected = '''
class C {
  Set<int?> f;
  C() : f = {null};
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_not_initialized() async {
    var content = '''
class C {
  int i;
  C();
}
''';
    var expected = '''
class C {
  int? i;
  C();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_not_initialized_no_constructor() async {
    var content = '''
class C {
  int i;
}
''';
    var expected = '''
class C {
  int? i;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_overrides_field_in_mixin() async {
    var content = '''
class C extends Object with M {
  int x;
}

mixin M {
  int x;
}
''';
    var expected = '''
class C extends Object with M {
  int? x;
}

mixin M {
  int? x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_overrides_getter() async {
    var content = '''
abstract class C {
  int get i;
}
class D implements C {
  @override
  final int i;
  D._() : i = computeI();
}
int computeI() => null;
''';
    var expected = '''
abstract class C {
  int? get i;
}
class D implements C {
  @override
  final int? i;
  D._() : i = computeI();
}
int? computeI() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_type_inferred() async {
    var content = '''
int f() => null;
class C {
  var x = 1;
  void g() {
    x = f();
  }
}
''';
    // The type of x is inferred as non-nullable from its initializer, but we
    // try to assign a nullable value to it.  So an explicit type must be added.
    var expected = '''
int? f() => null;
class C {
  int? x = 1;
  void g() {
    x = f();
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_uninitialized_used() async {
    var content = '''
class C {
  String s;

  f() {
    g(s);
  }
}
g(String /*!*/ s) {}
''';
    var expected = '''
class C {
  late String s;

  f() {
    g(s);
  }
}
g(String s) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_field_uninitialized_used_hint() async {
    var content = '''
class C {
  String /*?*/ s;

  f() {
    g(s);
  }
}
g(String /*!*/ s) {}
''';
    var expected = '''
class C {
  String? s;

  f() {
    g(s!);
  }
}
g(String s) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_complex_target() async {
    // See https://github.com/dart-lang/sdk/issues/43956
    var content = '''
Iterable<Match> allMatches(String str) => 'x'.allMatches(str);

Match matchAsPrefix(String str, [int start = 0]) {
  return allMatches(str)
      .firstWhere((match) => match.start == start, orElse: () => null);
}
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

Iterable<Match> allMatches(String str) => 'x'.allMatches(str);

Match? matchAsPrefix(String str, [int start = 0]) {
  return allMatches(str)
      .firstWhereOrNull((match) => match.start == start);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_non_nullable() async {
    var content = '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_non_nullable_with_cast() async {
    var content = '''
int firstNonZero(Iterable<num> x)
    => x.firstWhere((x) => x != 0, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstNonZero(Iterable<num> x)
    => x.firstWhereOrNull((x) => x != 0) as int?;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_non_nullable_with_non_null_assertion() async {
    var content = '''
int/*!*/ firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

int firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven)!;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_nullable() async {
    var content = '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
f() => firstEven([null]);
''';
    var expected = '''
int? firstEven(Iterable<int?> x)
    => x.firstWhere((x) => x!.isEven, orElse: () => null);
f() => firstEven([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_firstWhere_nullable_with_cast() async {
    var content = '''
int firstNonZero(Iterable<num> x)
    => x.firstWhere((x) => x != 0, orElse: () => null);
f() => firstNonZero([null]);
''';
    var expected = '''
int? firstNonZero(Iterable<num?> x)
    => x.firstWhere((x) => x != 0, orElse: () => null) as int?;
f() => firstNonZero([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_flow_analysis_complex() async {
    var content = '''
int f(int x) {
  while (x == null) {
    x = g(x);
  }
  return x;
}
int g(int x) => x == null ? 1 : null;
main() {
  f(null);
}
''';
    // Flow analysis can tell that the loop only exits if x is non-null, so the
    // return type of `f` can remain `int`, and no null check is needed.
    var expected = '''
int f(int? x) {
  while (x == null) {
    x = g(x);
  }
  return x;
}
int? g(int? x) => x == null ? 1 : null;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_flow_analysis_simple() async {
    var content = '''
int f(int x) {
  if (x == null) {
    return 0;
  } else {
    return x;
  }
}
main() {
  f(null);
}
''';
    var expected = '''
int f(int? x) {
  if (x == null) {
    return 0;
  } else {
    return x;
  }
}
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_for_each_basic() async {
    var content = '''
void f(List<int> l) {
  for (var x in l) {
    g(x);
  }
}
void g(int x) {}
main() {
  f([null]);
}
''';
    var expected = '''
void f(List<int?> l) {
  for (var x in l) {
    g(x);
  }
}
void g(int? x) {}
main() {
  f([null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_for_each_variable_initialized() async {
    var content = '''
int sum(List<int> list) {
  int total = 0;
  for (var i in list) {
    total = total + i;
  }
  return total;
}
''';
    var expected = '''
int sum(List<int> list) {
  int total = 0;
  for (var i in list) {
    total = total + i;
  }
  return total;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_expression() async {
    var content = '''
int f(int i) {
  var g = (int j) => i;
  return g(i);
}
main() {
  f(null);
}
''';
    var expected = '''
int? f(int? i) {
  var g = (int? j) => i;
  return g(i);
}
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_expression_invocation() async {
    var content = '''
abstract class C {
  void Function(int) f();
  int/*?*/ Function() g();
}
int test(C c) {
  c.f()(null);
  return c.g()();
}
''';
    var expected = '''
abstract class C {
  void Function(int?) f();
  int? Function() g();
}
int? test(C c) {
  c.f()(null);
  return c.g()();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_expression_invocation_via_getter() async {
    var content = '''
abstract class C {
  void Function(int) get f;
  int/*?*/ Function() get g;
}
int test(C c) {
  c.f(null);
  return c.g();
}
''';
    var expected = '''
abstract class C {
  void Function(int?) get f;
  int? Function() get g;
}
int? test(C c) {
  c.f(null);
  return c.g();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_expression_never() async {
    var content = '''
typedef CB = int Function(Object o);
abstract class C {
  void m(CB cb);
}
void f(C c) {
  c.m((_) => throw Exception());
}
''';
    var expected = '''
typedef CB = int Function(Object o);
abstract class C {
  void m(CB? cb);
}
void f(C c) {
  c.m((_) => throw Exception());
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_expression_return() async {
    var content = '''
void test({String foo}) async {
  var f = () {
    return "hello";
  };

  foo.length;
}
''';
    var expected = '''
void test({required String foo}) async {
  var f = () {
    return "hello";
  };

  foo.length;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_field_formal_param() async {
    var content = '''
class C {
  void Function(int) f;
  C(void this.f(int i));
}
main() {
  C(null);
}
''';
    var expected = '''
class C {
  void Function(int)? f;
  C(void this.f(int i)?);
}
main() {
  C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_field_formal_param_accepts_hint() async {
    var content = '''
class C {
  void Function(int) f;
  C(void this.f(int i) /*?*/);
}
''';
    var expected = '''
class C {
  void Function(int)? f;
  C(void this.f(int i)?);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_field_formal_param_inner_types() async {
    var content = '''
class C {
  int Function(int) f;
  C(int this.f(int i));
}
int g(int i) => i;
int test(int i) => C(g).f(i);
main() {
  test(null);
}
''';
    var expected = '''
class C {
  int? Function(int?) f;
  C(int? this.f(int? i));
}
int? g(int? i) => i;
int? test(int? i) => C(g).f(i);
main() {
  test(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_formal_param() async {
    var content = '''
void f(g()) {}
void main() {
  f(null);
}
''';
    var expected = '''
void f(g()?) {}
void main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_formal_param_accepts_hint() async {
    var content = '''
void f(g() /*?*/) {}
''';
    var expected = '''
void f(g()?) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_function_typed_formal_param_inner_types() async {
    var content = '''
int f(int callback(int i), int j) => callback(j);
int g(int i) => i;
int test(int i) => f(g, i);
main() {
  test(null);
}
''';
    var expected = '''
int? f(int? callback(int? i), int? j) => callback(j);
int? g(int? i) => i;
int? test(int? i) => f(g, i);
main() {
  test(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_future_nullability_mismatch() async {
    var content = '''
String foo;

Future<String> getNullableFoo() async {
  return foo;
}

Future<String/*!*/> getFoo() {
  return getNullableFoo();
}
''';
    var expected = '''
String? foo;

Future<String?> getNullableFoo() async {
  return foo;
}

Future<String> getFoo() {
  return getNullableFoo().then((value) => value!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): the cast of `foi2` looks wrong, I think it should be `int?`
  // instead, but `DOWN(int?, FutureOr<int?>)` is `int` according to the spec.
  Future<void> test_future_or_t_downcast_to_t() async {
    var content = '''
import 'dart:async';
void _f(
    FutureOr<int> foi1,
    FutureOr<int/*?*/> foi2,
    FutureOr<int>/*?*/ foi3,
    FutureOr<int/*?*/>/*?*/ foi4
) {
  int i1 = foi1;
  int i2 = foi2;
  int i3 = foi3;
  int i4 = foi4;
}
''';
    var expected = '''
import 'dart:async';
void _f(
    FutureOr<int> foi1,
    FutureOr<int?> foi2,
    FutureOr<int>? foi3,
    FutureOr<int?> foi4
) {
  int i1 = foi1 as int;
  int? i2 = foi2 as int;
  int? i3 = foi3 as int?;
  int? i4 = foi4 as int?;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_future_type_mismatch() async {
    var content = '''
Future<List<int>> getNullableInts() async {
  return [null];
}

Future<List<int/*!*/>> getInts() {
  return getNullableInts();
}
''';
    // TODO(paulberry): this is not a good migration.  Really we should produce
    // `getNullableInts().then((value) => value.cast());`.
    var expected = '''
Future<List<int?>> getNullableInts() async {
  return [null];
}

Future<List<int>> getInts() {
  return getNullableInts().then((value) => value as List<int>);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_generic_bound() async {
    var content = '''
abstract class C<T> {
  void f<U extends T>();
}
void f(C<String> s, C<List<int>> i) {
  s.f<String>();
  i.f<List<int>>();
}
''';
    var expected = '''
abstract class C<T> {
  void f<U extends T>();
}
void f(C<String> s, C<List<int>> i) {
  s.f<String>();
  i.f<List<int>>();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_generic_exact_propagation() async {
    var content = '''
class C<T> {
  List<T> values;
  C() : values = <T>[];
  void add(T t) => values.add(t);
  T operator[](int i) => values[i];
}
void f() {
  C<int> x = new C<int>();
  g(x);
}
void g(C<int> y) {
  y.add(null);
}
''';
    var expected = '''
class C<T> {
  List<T> values;
  C() : values = <T>[];
  void add(T t) => values.add(t);
  T operator[](int i) => values[i];
}
void f() {
  C<int?> x = new C<int?>();
  g(x);
}
void g(C<int?> y) {
  y.add(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_generic_exact_propagation_premigratedListClass() async {
    var content = '''
void f() {
  List<int> x = new List<int>.empty();
  g(x);
}
void g(List<int> y) {
  y.add(null);
}
''';
    var expected = '''
void f() {
  List<int?> x = new List<int?>.empty();
  g(x);
}
void g(List<int?> y) {
  y.add(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_generic_function_type_syntax_inferred_dynamic_return() async {
    var content = '''
abstract class C {
  Function() f();
}
Object g(C c) => c.f()();
''';
    // Note: even though the type `dynamic` permits `null`, the migration engine
    // sees that there is no code path that could cause `g` to return a null
    // value, so it leaves its return type as `Object`, and there is an implicit
    // downcast.
    var expected = '''
abstract class C {
  Function() f();
}
Object g(C c) => c.f()();
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): this is the case I don't like. One would hope that usage
  // in test would force comparison to be non-nullable.
  Future<void>
      test_generic_typedef_respects_explicit_nullability_of_type_arg() async {
    var content = '''
class C {
  final Comparator<int/*!*/> comparison;
  C(int Function(int, int) comparison) : comparison = comparison;
  void test() {
    comparison(f(), f());
  }
}
int f() => null;
''';
    var expected = '''
class C {
  final Comparator<int>? comparison;
  C(int Function(int, int)? comparison) : comparison = comparison;
  void test() {
    comparison!(f()!, f()!);
  }
}
int? f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_genericType_noTypeArguments() async {
    var content = '''
void _f(C c) {}
class C<E> {}
''';
    var expected = '''
void _f(C c) {}
class C<E> {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39404')
  Future<void> test_genericType_noTypeArguments_use_bound() async {
    var content = '''
abstract class C<T extends Object> { // (1)
  void put(T t);
  T get();
}
Object f(C c) => c.get();            // (2)
void g(C<int> c) {                   // (3)
  c.put(null);                       // (4)
}
''';
    // (4) forces `...C<int?>...` at (3), which means (1) must be
    // `...extends Object?`.  Therefore (2) is equivalent to
    // `...f(C<Object?> c)...`, so the return type of `f` is `Object?`.
    var expected = '''
abstract class C<T extends Object?> { // (1)
  void put(T t);
  T get();
}
Object? f(C c) => c.get();            // (2)
void g(C<int?> c) {                   // (3)
  c.put(null);                       // (4)
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_getter_implicit_returnType_overrides_implicit_getter() async {
    var content = '''
class A {
  final String s = "x";
}
class C implements A {
  get s => false ? "y" : null;
}
''';
    var expected = '''
class A {
  final String? s = "x";
}
class C implements A {
  get s => false ? "y" : null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_overrides_implicit_getter() async {
    var content = '''
class A {
  final String s = "x";
}
class C implements A {
  String get s => false ? "y" : null;
}
''';
    var expected = '''
class A {
  final String? s = "x";
}
class C implements A {
  String? get s => false ? "y" : null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_overrides_implicit_getter_with_generics() async {
    var content = '''
class A<T> {
  final T value;
  A(this.value);
}
class C implements A<String/*!*/> {
  String get value => false ? "y" : null;
}
''';
    var expected = '''
class A<T> {
  final T? value;
  A(this.value);
}
class C implements A<String> {
  String? get value => false ? "y" : null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_getter_in_interface() async {
    var content = '''
class B {
  int get x => null;
}
abstract class C implements B {
  void set x(int value) {}
}
''';
    var expected = '''
class B {
  int? get x => null;
}
abstract class C implements B {
  void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_getter_in_interface_field() async {
    var content = '''
class B {
  final int x = null;
}
abstract class C implements B {
  void set x(int value) {}
}
''';
    var expected = '''
class B {
  final int? x = null;
}
abstract class C implements B {
  void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_getter_in_interfaces() async {
    var content = '''
class B1 {
  int get x => null;
}
class B2 {
  int get x => null;
}
abstract class C implements B1, B2 {
  void set x(int value) {}
}
''';
    var expected = '''
class B1 {
  int? get x => null;
}
class B2 {
  int? get x => null;
}
abstract class C implements B1, B2 {
  void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_getter_in_superclass() async {
    var content = '''
class B {
  int get x => null;
}
class C extends B {
  void set x(int value) {}
}
''';
    var expected = '''
class B {
  int? get x => null;
}
class C extends B {
  void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_getter_in_superclass_substituted() async {
    var content = '''
class B<T> {
  T get x => throw '';
}
class C extends B<List<int/*?*/>> {
  void set x(List<int> value) {}
}
''';
    var expected = '''
class B<T> {
  T get x => throw '';
}
class C extends B<List<int?>> {
  void set x(List<int?> value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_setter_in_interface() async {
    var content = '''
class B {
  void set x(int value) {}
}
abstract class C implements B {
  int get x => null;
}
''';
    var expected = '''
class B {
  void set x(int? value) {}
}
abstract class C implements B {
  int? get x => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_setter_in_interface_field() async {
    var content = '''
class B {
  int x;
  B(this.x);
}
abstract class C implements B {
  int get x => null;
}
''';
    var expected = '''
class B {
  int? x;
  B(this.x);
}
abstract class C implements B {
  int? get x => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_setter_in_interfaces() async {
    var content = '''
class B1 {
  void set x(int value) {}
}
class B2 {
  void set x(int value) {}
}
abstract class C implements B1, B2 {
  int get x => null;
}
''';
    var expected = '''
class B1 {
  void set x(int? value) {}
}
class B2 {
  void set x(int? value) {}
}
abstract class C implements B1, B2 {
  int? get x => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_setter_in_superclass() async {
    var content = '''
class B {
  void set x(int value) {}
}
class C extends B {
  int get x => null;
}
''';
    var expected = '''
class B {
  void set x(int? value) {}
}
class C extends B {
  int? get x => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_setter_in_superclass_substituted() async {
    var content = '''
class B<T> {
  void set x(T value) {}
}
class C extends B<List<int>> {
  List<int> get x => [null];
}
''';
    var expected = '''
class B<T> {
  void set x(T value) {}
}
class C extends B<List<int?>> {
  List<int?> get x => [null];
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_single_class() async {
    var content = '''
class C {
  int get x => null;
  void set x(int value) {}
}
''';
    var expected = '''
class C {
  int? get x => null;
  void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_single_class_generic() async {
    var content = '''
class C<T extends Object/*!*/> {
  T get x => null;
  void set x(T value) {}
}
''';
    var expected = '''
class C<T extends Object> {
  T? get x => null;
  void set x(T? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_static() async {
    var content = '''
class C {
  static int get x => null;
  static void set x(int value) {}
}
''';
    var expected = '''
class C {
  static int? get x => null;
  static void set x(int? value) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_setter_top_level() async {
    var content = '''
int get x => null;
void set x(int value) {}
''';
    var expected = '''
int? get x => null;
void set x(int? value) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_getter_topLevel() async {
    var content = '''
int get g => 0;
''';
    var expected = '''
int get g => 0;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_hint_contradicts_exact_nullability() async {
    var content = '''
void f(List<int> x) {
  x.add(null);
}
void g() {
  f(<int/*!*/>[]);
}
''';
    // `f.x` needs to change to List<int?> to allow `null` to be added to the
    // list.  Ordinarily this would be propagated back to the explicit list in
    // `g`, but we don't override the hint `/*!*/`.
    //
    // TODO(paulberry): we should probably issue some sort of warning to the
    // user instead.
    var expected = '''
void f(List<int?> x) {
  x.add(null);
}
void g() {
  f(<int>[]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_ifStatement_nullCheck_noElse() async {
    var content = '''
int f(int x) {
  if (x == null) return 0;
  return x;
}
''';
    var expected = '''
int f(int? x) {
  if (x == null) return 0;
  return x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_implicit_parameter_type_override_does_not_union() async {
    var content = '''
abstract class A {
  void f(int/*?*/ i);
}
abstract class B {
  void f(int/*!*/ i);
}
class C implements A, B {
  void f(i) {}
}
''';
    // Even though the parameter type of C.f is implicit, its nullability
    // shouldn't be unioned with that of A and B, because that would
    // unnecessarily force B.f's parameter type to be nullable.
    var expected = '''
abstract class A {
  void f(int? i);
}
abstract class B {
  void f(int i);
}
class C implements A, B {
  void f(i) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_implicit_return_type_override_does_not_union() async {
    var content = '''
abstract class A {
  int/*?*/ f();
}
abstract class B {
  int f();
}
class C implements A, B {
  f() => 0;
}
''';
    // Even though the return type of C.f is implicit, its nullability shouldn't
    // be unioned with that of A and B, because that would unnecessarily force
    // B.f's return type to be nullable.
    var expected = '''
abstract class A {
  int? f();
}
abstract class B {
  int f();
}
class C implements A, B {
  f() => 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_implicit_tearoff_type_arguments() async {
    var content = '''
T f<T>(T t) => t;
int Function(int) g() => f;
''';
    var expected = '''
T f<T>(T t) => t;
int Function(int) g() => f;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_implicit_type_parameter_bound_nullable() async {
    var content = '''
class C<T> {
  f(T t) {
    Object o = t;
  }
}
''';
    var expected = '''
class C<T> {
  f(T t) {
    Object? o = t;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_infer_late_with_cascaded_usage() async {
    var content = '''
class A {
  B b;
}
class B {
  void f() {}
  void g() {}
}
foo(A a) {
  a.b..f()..g();
}
bar(A a) {
  a.b = B();
}
''';
    var expected = '''
class A {
  late B b;
}
class B {
  void f() {}
  void g() {}
}
foo(A a) {
  a.b..f()..g();
}
bar(A a) {
  a.b = B();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39376')
  Future<void> test_infer_required() async {
    var content = '''
void _f(bool b, {int x}) {
  if (b) {
    print(x + 1);
  }
}
main() {
  _f(true, x: 1);
}
''';
    var expected = '''
void _f(bool b, {required int x}) {
  if (b) {
    print(x + 1);
  }
}
main() {
  _f(true, x: 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_inferred_method_return_type_non_nullable() async {
    var content = '''
class B {
  int f() => 1;
}
class C extends B {
  f() => 1;
}
int g(C c) => c.f();
''';
    // B.f's return type is `int`.  Since C.f's return type is inferred from
    // B.f's, it has a return type of `int` too.  Therefore g's return type
    // must be `int`.
    var expected = '''
class B {
  int f() => 1;
}
class C extends B {
  f() => 1;
}
int g(C c) => c.f();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_insert_as_prefixed_type() async {
    var content = '''
import 'dart:async' as a;
Future<int> _f(Object o) => o;
''';
    var expected = '''
import 'dart:async' as a;
Future<int> _f(Object o) => o as a.Future<int>;
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40871')
  Future<void> test_insert_type_with_prefix() async {
    var content = '''
import 'dart:async' as a;
a.Future f(Object o) {
  return o;
}
''';
    var expected = '''
import 'dart:async' as a;
a.Future f(Object o) {
  return o as a.Future;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/38469')
  Future<void> test_inserted_nodes_properly_wrapped() async {
    addMetaPackage();
    var content = '''
class C {
  C operator+(C other) => null;
}
void f(C x, C y) {
  C z = x + y;
  assert(z != null);
}
''';
    var expected = '''
class C {
  C operator+(C other) => null;
}
void f(C x, C y) {
  C z = (x + y)!;
  assert(z != null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_instance_creation_generic() async {
    var content = '''
class C<T> {
  C(T t);
}
main() {
  C<int> c = C<int>(null);
}
''';
    var expected = '''
class C<T> {
  C(T t);
}
main() {
  C<int?> c = C<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_instance_creation_generic_explicit_nonNullable() async {
    var content = '''
class C<T extends Object/*!*/> {
  C(T/*!*/ t);
}
test(int/*?*/ n) {
  C<int> c = C<int>(n);
}
''';
    var expected = '''
class C<T extends Object> {
  C(T t);
}
test(int? n) {
  C<int> c = C<int>(n!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_instance_creation_generic_explicit_nonNullableParam() async {
    var content = '''
class C<T> {
  C(T/*!*/ t);
}
main() {
  C<int> c = C<int>(null);
}
''';
    var expected = '''
class C<T> {
  C(T t);
}
main() {
  C<int?> c = C<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_instance_creation_generic_implicit_nonNullable() async {
    var content = '''
class C<T extends Object/*!*/> {
  C(T/*!*/ t);
}
test(int/*?*/ n) {
  C<int> c = C(n);
}
''';
    var expected = '''
class C<T extends Object> {
  C(T t);
}
test(int? n) {
  C<int> c = C(n!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_instance_creation_generic_implicit_nonNullableParam() async {
    var content = '''
class C<T> {
  C(T/*!*/ t);
}
main() {
  C<int> c = C(null);
}
''';
    var expected = '''
class C<T> {
  C(T t);
}
main() {
  C<int?> c = C(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_instanceCreation_noTypeArguments_noParameters() async {
    var content = '''
void main() {
  C c = C();
  c.length;
}
class C {
  int get length => 0;
}
''';
    var expected = '''
void main() {
  C c = C();
  c.length;
}
class C {
  int get length => 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_int_double_coercion() async {
    var content = '''
double f() => 0;
''';
    var expected = '''
double f() => 0;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_is_promotion_implies_non_nullable() async {
    var content = '''
bool f(Object o) => o is int && o.isEven;
main() {
  f(null);
}
''';
    var expected = '''
bool f(Object? o) => o is int && o.isEven;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_is_promotion_implies_non_nullable_generic() async {
    var content = '''
int f<T>(T o) => o is List ? o.length : 0;
main() {
  f(null);
}
''';
    var expected = '''
int f<T>(T o) => o is List ? o.length : 0;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_isExpression_typeName_typeArguments() async {
    var content = '''
bool f(a) => a is List<int>;
''';
    var expected = '''
bool f(a) => a is List<int>;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_isExpression_with_function_type() async {
    var content = '''
void _test(Function f) {
  if (f is void Function()) {
    f();
  }
}
''';
    var expected = '''
void _test(Function f) {
  if (f is void Function()) {
    f();
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_issue_40181() async {
    // This contrived example created an "exact nullable" type parameter bound
    // which propagated back to *all* instantiations of that parameter.
    var content = '''
class B<T extends Object> {
  B([C<T> t]);
}

abstract class C<T extends Object> {
  void f(T t);
}

class E {
  final C<Object> _base;
  E([C base]) : _base = base;
  f(Object t) {
    _base.f(t);
  }
}

void main() {
  E e = E();
  e.f(null);
}
''';
    var expected = '''
class B<T extends Object> {
  B([C<T>? t]);
}

abstract class C<T extends Object?> {
  void f(T t);
}

class E {
  final C<Object?>? _base;
  E([C? base]) : _base = base;
  f(Object? t) {
    _base!.f(t);
  }
}

void main() {
  E e = E();
  e.f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_issue_41397() async {
    var content = '''
void repro(){
  List<dynamic> l = <dynamic>[];
  for(final dynamic e in l) {
    final List<String> a = (e['query'] as String).split('&');
  }
}
''';
    var expected = '''
void repro(){
  List<dynamic> l = <dynamic>[];
  for(final dynamic e in l) {
    final List<String> a = (e['query'] as String).split('&');
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_lastWhere_non_nullable() async {
    var content = '''
int lastEven(Iterable<int> x)
    => x.lastWhere((x) => x.isEven, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

int? lastEven(Iterable<int> x)
    => x.lastWhereOrNull((x) => x.isEven);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_lastWhere_nullable() async {
    var content = '''
int lastEven(Iterable<int> x)
    => x.lastWhere((x) => x.isEven, orElse: () => null);
f() => lastEven([null]);
''';
    var expected = '''
int? lastEven(Iterable<int?> x)
    => x.lastWhere((x) => x!.isEven, orElse: () => null);
f() => lastEven([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_final_hint_instance_field_without_constructor() async {
    var content = '''
class C {
  /*late final*/ int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    var expected = '''
class C {
  late final int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_final_hint_local_variable() async {
    var content = '''
int f(bool b1, bool b2) {
  /*late final*/ int x;
  if (b1) {
    x = 1;
  }
  if (b2) {
    return x;
  }
  return 0;
}
''';
    var expected = '''
int f(bool b1, bool b2) {
  late final int x;
  if (b1) {
    x = 1;
  }
  if (b2) {
    return x;
  }
  return 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_final_hint_top_level_var() async {
    var content = '''
/*late final*/ int x;
f() {
  x = 1;
}
int g() => x;
''';
    var expected = '''
late final int x;
f() {
  x = 1;
}
int g() => x;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_followed_by_underscore() async {
    var content = '''
class _C {}
/*late*/ _C c;
''';
    var expected = '''
class _C {}
late _C c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_instance_field_with_constructor() async {
    var content = '''
class C {
  C();
  /*late*/ int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    var expected = '''
class C {
  C();
  late int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_instance_field_without_constructor() async {
    var content = '''
class C {
  /*late*/ int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    var expected = '''
class C {
  late int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_local_variable() async {
    var content = '''
int f(bool b1, bool b2) {
  /*late*/ int x;
  if (b1) {
    x = 1;
  }
  if (b2) {
    return x;
  }
  return 0;
}
''';
    var expected = '''
int f(bool b1, bool b2) {
  late int x;
  if (b1) {
    x = 1;
  }
  if (b2) {
    return x;
  }
  return 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_static_field() async {
    var content = '''
class C {
  static /*late*/ int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    var expected = '''
class C {
  static late int x;
  f() {
    x = 1;
  }
  int g() => x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_late_hint_top_level_var() async {
    var content = '''
/*late*/ int x;
f() {
  x = 1;
}
int g() => x;
''';
    var expected = '''
late int x;
f() {
  x = 1;
}
int g() => x;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_leave_downcast_from_dynamic_implicit() async {
    var content = 'int _f(dynamic n) => n;';
    var expected = 'int _f(dynamic n) => n;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_libraryWithParts() async {
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/lib.dart');
    var file1 = '''
part 'src/foo/part.dart';
''';
    var expected1 = '''
part 'src/foo/part.dart';
''';
    var path2 = convertPath('$root/src/foo/part.dart');
    var file2 = '''
part of '../../lib.dart';
class C {
  static void m(C c) {}
}
''';
    var expected2 = '''
part of '../../lib.dart';
class C {
  static void m(C? c) {}
}
''';
    await _checkMultipleFileChanges(
        {path2: file2, path1: file1}, {path1: expected1, path2: expected2});
  }

  Future<void> test_libraryWithParts_add_questions() async {
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/lib.dart');
    var file1 = '''
part 'src/foo/part.dart';

int f() => null;
''';
    var expected1 = '''
part 'src/foo/part.dart';

int? f() => null;
''';
    var path2 = convertPath('$root/src/foo/part.dart');
    var file2 = '''
part of '../../lib.dart';

int g() => null;
''';
    var expected2 = '''
part of '../../lib.dart';

int? g() => null;
''';
    await _checkMultipleFileChanges(
        {path2: file2, path1: file1}, {path1: expected1, path2: expected2});
  }

  Future<void> test_list_conditional_element() async {
    var content = '''
void _bar(List<String> l) {}

void _test({String foo}) {
    _bar([if (foo != null) foo]);
}
''';
    var expected = '''
void _bar(List<String> l) {}

void _test({String? foo}) {
    _bar([if (foo != null) foo]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_literal_null_without_valid_migration() async {
    var content = '''
void f(int/*!*/ x) {}
void g() {
  f(null);
}
''';
    var expected = '''
void f(int x) {}
void g() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_literals_maintain_nullability() async {
    // See #40590. Without exact nullability, this would migrate to
    // `List<int?> list = <int>[1, 2]`. While the function of exact nullability
    // may change, this case should continue to work.
    var content = r'''
void f() {
  List<int> list = [1, 2];
  list.add(null);
  Set<int> set_ = {1, 2};
  set_.add(null);
  Map<int, int> map = {1: 2};
  map[null] = null;
}
''';
    var expected = r'''
void f() {
  List<int?> list = [1, 2];
  list.add(null);
  Set<int?> set_ = {1, 2};
  set_.add(null);
  Map<int?, int?> map = {1: 2};
  map[null] = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_loadLibrary_call() async {
    var testPath = convertPath('$testsPath/lib/test.dart');
    var otherPath = convertPath('$testsPath/lib/other.dart');
    var content = {
      testPath: '''
import 'other.dart' deferred as other;
Future<Object> f() => other.loadLibrary();
''',
      otherPath: ''
    };
    var expected = {
      testPath: '''
import 'other.dart' deferred as other;
Future<Object?> f() => other.loadLibrary();
''',
      otherPath: ''
    };
    await _checkMultipleFileChanges(content, expected);
  }

  Future<void> test_loadLibrary_tearOff() async {
    var testPath = convertPath('$testsPath/lib/test.dart');
    var otherPath = convertPath('$testsPath/lib/other.dart');
    var content = {
      testPath: '''
import 'other.dart' deferred as other;
Future<Object> Function() f() => other.loadLibrary;
''',
      otherPath: ''
    };
    var expected = {
      testPath: '''
import 'other.dart' deferred as other;
Future<Object?> Function() f() => other.loadLibrary;
''',
      otherPath: ''
    };
    await _checkMultipleFileChanges(content, expected);
  }

  Future<void> test_local_function() async {
    var content = '''
int f(int i) {
  int g(int j) => i;
  return g(i);
}
main() {
  f(null);
}
''';
    var expected = '''
int? f(int? i) {
  int? g(int? j) => i;
  return g(i);
}
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_local_function_doesnt_assign() async {
    var content = '''
int f() {
  int i;
  g(int j) {
    i = 1;
  };
  ((int j) {
    i = 1;
  });
  return i + 1;
}
''';
    var expected = '''
int f() {
  late int i;
  g(int j) {
    i = 1;
  };
  ((int j) {
    i = 1;
  });
  return i + 1;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_local_function_expression_inhibits_non_null_intent() async {
    var content = '''
void call(void Function() callback) {
  callback();
}
test(int i, int j) {
  call(() {
    i = j;
  });
  print(i + 1);
}
main() {
  test(null, 0);
}
''';
    // `print(i + 1)` does *not* demonstrate non-null intent for `i` because it
    // is write captured by the local function expression, so it's not
    // guaranteed that a null value of `i` on entry to the function will lead to
    // an exception.
    var expected = '''
void call(void Function() callback) {
  callback();
}
test(int? i, int? j) {
  call(() {
    i = j;
  });
  print(i! + 1);
}
main() {
  test(null, 0);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_local_function_inhibits_non_null_intent() async {
    var content = '''
void call(void Function() callback) {
  callback();
}
test(int i, int j) {
  void f() {
    i = j;
  }
  call(f);
  print(i + 1);
}
main() {
  test(null, 0);
}
''';
    // `print(i + 1)` does *not* demonstrate non-null intent for `i` because it
    // is write captured by the local function expression, so it's not
    // guaranteed that a null value of `i` on entry to the function will lead to
    // an exception.
    var expected = '''
void call(void Function() callback) {
  callback();
}
test(int? i, int? j) {
  void f() {
    i = j;
  }
  call(f);
  print(i! + 1);
}
main() {
  test(null, 0);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_local_function_return() async {
    var content = '''
void test({String foo}) async {
  String f() {
    return "hello";
  }

  foo.length;
}
''';
    var expected = '''
void test({required String foo}) async {
  String f() {
    return "hello";
  }

  foo.length;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_type_inferred() async {
    var content = '''
int f() => null;
void main() {
  var x = 1;
  x = f();
}
''';
    // The type of x is inferred as non-nullable from its initializer, but we
    // try to assign a nullable value to it.  So an explicit type must be added.
    var expected = '''
int? f() => null;
void main() {
  int? x = 1;
  x = f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_uninitialized_assigned_non_nullable() async {
    var content = '''
f() {
  String s;
  if (1 == 2) s = g();
  h(s);
}
String /*!*/ g() => "Hello";
h(String /*!*/ s) {}
''';
    var expected = '''
f() {
  late String s;
  if (1 == 2) s = g();
  h(s);
}
String g() => "Hello";
h(String s) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_uninitialized_used() async {
    var content = '''
f() {
  String s;
  if (1 == 2) s = "Hello";
  g(s);
}
g(String /*!*/ s) {}
''';
    var expected = '''
f() {
  late String s;
  if (1 == 2) s = "Hello";
  g(s);
}
g(String s) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_uninitialized_usedInComparison() async {
    var content = '''
f() {
  String s;
  if (s == null) {}
}
''';
    var expected = '''
f() {
  String? s;
  if (s == null) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_localVariable_uninitialized_usedInExpressionStatement() async {
    var content = '''
f() {
  String s;
  s;
}
''';
    var expected = '''
f() {
  String? s;
  s;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_uninitialized_usedInForUpdaters() async {
    var content = '''
f() {
  String s;
  for (s;;) {}
}
''';
    var expected = '''
f() {
  String? s;
  for (s;;) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_localVariable_uninitialized_usedInForVariable() async {
    var content = '''
f() {
  String s;
  for (;; s) {}
}
''';
    var expected = '''
f() {
  String? s;
  for (;; s) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_loop_var_is_field() async {
    var content = '''
class C {
  int x;
  C(this.x);
  f(List<int/*?*/> y) {
    for (x in y) {}
  }
}
''';
    var expected = '''
class C {
  int? x;
  C(this.x);
  f(List<int?> y) {
    for (x in y) {}
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_loop_var_is_inherited_field_with_substitution() async {
    var content = '''
class B<T> {
  T x;
  B(this.x);
}
abstract class C implements B<int> {
  f(List<int/*?*/> y) {
    for (x in y) {}
  }
}
''';
    var expected = '''
class B<T> {
  T x;
  B(this.x);
}
abstract class C implements B<int?> {
  f(List<int?> y) {
    for (x in y) {}
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_make_downcast_explicit() async {
    var content = 'int f(num/*!*/ n) => n;';
    var expected = 'int f(num n) => n as int;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_many_type_variables() async {
    try {
      assert(false);
    } catch (_) {
      // When assertions are enabled, this test fails, so skip it.
      // See https://github.com/dart-lang/sdk/issues/43945.
      return;
    }
    var content = '''
void test(C<int> x, double Function<S>(C<S>) y) {
  x.f<double>(y);
}
class C<T> {
  U f<U>(U Function<V>(C<V>) z) => throw 'foo';
}
''';
    var expected = '''
void test(C<int> x, double Function<S>(C<S>)? y) {
  x.f<double>(y);
}
class C<T> {
  U f<U>(U Function<V>(C<V>)? z) => throw 'foo';
}
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_map_nullable_input() async {
    var content = '''
Iterable<int> f(List<int> x) => x.map((y) => g(y));
int g(int x) => x + 1;
main() {
  f([null]);
}
''';
    var expected = '''
Iterable<int> f(List<int?> x) => x.map((y) => g(y!));
int g(int x) => x + 1;
main() {
  f([null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_map_nullable_input_tearoff() async {
    var content = '''
Iterable<int> f(List<int> x) => x.map(g);
int g(int x) => x + 1;
main() {
  f([null]);
}
''';
    var expected = '''
Iterable<int> f(List<int?> x) => x.map(g);
int g(int? x) => x! + 1;
main() {
  f([null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_map_nullable_output() async {
    var content = '''
Iterable<int> _f(List<int> x) => x.map((y) => _g(y));
int _g(int x) => null;
main() {
  _f([1]);
}
''';
    var expected = '''
Iterable<int?> _f(List<int> x) => x.map((y) => _g(y));
int? _g(int x) => null;
main() {
  _f([1]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_map_read_does_not_require_index_cast() async {
    var content = '''
int _f(Map<String, int> m, Object o) => m[o];
''';
    var expected = '''
int? _f(Map<String, int> m, Object o) => m[o];
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_map_write_requires_index_cast() async {
    var content = '''
void _f(Map<String, int> m, Object o, int i) => m[o] = i;
''';
    var expected = '''
void _f(Map<String, int> m, Object o, int i) => m[o as String] = i;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_methodInvocation_extension_invocation() async {
    var content = '''
extension on bool {
  void f() {}
}
bool g<T>(T x) => true;
void main() {
  g<int>(null).f();
}
''';
    var expected = '''
extension on bool {
  void f() {}
}
bool g<T>(T x) => true;
void main() {
  g<int?>(null).f();
}
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_methodInvocation_typeArguments_explicit() async {
    var content = '''
T f<T>(T t) => t;
void g() {
  int x = f<int>(null);
}
''';
    var expected = '''
T f<T>(T t) => t;
void g() {
  int? x = f<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_methodInvocation_typeArguments_explicit_nonNullable() async {
    var content = '''
T f<T extends Object/*!*/>(T/*!*/ t) => t;
void g(int/*?*/ n) {
  int x = f<int>(n);
}
''';
    var expected = '''
T f<T extends Object>(T t) => t;
void g(int? n) {
  int x = f<int>(n!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_methodInvocation_typeArguments_explicit_nonNullableParam() async {
    var content = '''
T f<T>(T/*!*/ t) => t;
void g() {
  int x = f<int>(null);
}
''';
    var expected = '''
T f<T>(T t) => t;
void g() {
  int? x = f<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_methodInvocation_typeArguments_inferred() async {
    var content = '''
T f<T>(T t) => t;
void g() {
  int x = f(null);
}
''';
    var expected = '''
T f<T>(T t) => t;
void g() {
  int? x = f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_methodInvocation_typeArguments_inferred_nonNullable() async {
    var content = '''
T f<T extends Object/*!*/>(T/*!*/ t) => t;
void g(int/*?*/ n) {
  int x = f(n);
}
''';
    var expected = '''
T f<T extends Object>(T t) => t;
void g(int? n) {
  int x = f(n!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_methodInvocation_typeArguments_inferred_nonNullableParam() async {
    var content = '''
T f<T>(T/*!*/ t) => t;
void g() {
  int x = f(null);
}
''';
    var expected = '''
T f<T>(T t) => t;
void g() {
  int? x = f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_migrate_reference_to_never() async {
    var content = '''
import 'dart:io';
int f() =>
  exit(1); // this returns `Never` which used to cause a crash.
''';
    var expected = '''
import 'dart:io';
int f() =>
  exit(1); // this returns `Never` which used to cause a crash.
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_migratedMethod_namedParameter() async {
    var content = '''
void f(Iterable<int> a) {
  a.toList(growable: false);
}
''';
    var expected = '''
void f(Iterable<int> a) {
  a.toList(growable: false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_multiDeclaration_innerUsage() async {
    var content = '''
void test() {
  // here non-null is OK.
  int i1 = 0, i2 = i1.gcd(2);
  // here non-null is not OK.
  int i3 = 0, i4 = i3.gcd(2), i5 = null;
}
''';
    var expected = '''
void test() {
  // here non-null is OK.
  int i1 = 0, i2 = i1.gcd(2);
  // here non-null is not OK.
  int? i3 = 0, i4 = i3.gcd(2), i5 = null;
}
''';

    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_multiDeclaration_softEdges() async {
    var content = '''
int _nullable(int i1, int i2) {
  int i3 = i1, i4 = i2;
  return i3;
}
int _nonNull(int i1, int i2) {
  int i3 = i1, i4 = i2;
  return i3;
}
int _both(int i1, int i2) {
  int i3 = i1, i4 = i2;
  return i3;
}
void main() {
  _nullable(null, null);
  _nonNull(0, 1);
  _both(0, null);
}
''';
    var expected = '''
int? _nullable(int? i1, int? i2) {
  int? i3 = i1, i4 = i2;
  return i3;
}
int _nonNull(int i1, int i2) {
  int i3 = i1, i4 = i2;
  return i3;
}
int? _both(int i1, int? i2) {
  int? i3 = i1, i4 = i2;
  return i3;
}
void main() {
  _nullable(null, null);
  _nonNull(0, 1);
  _both(0, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_add_required() async {
    var content = '''
void f({String s}) {
  assert(s != null);
}
''';
    var expected = '''
void f({required String s}) {
  assert(s != null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_add_required_function_typed() async {
    var content = '''
void f({void g(int i)}) {
  assert(g != null);
}
''';
    var expected = '''
void f({required void g(int i)}) {
  assert(g != null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_unused() async {
    var content = '''
void f({String s}) {}
main() {
  f();
}
''';
    var expected = '''
void f({String? s}) {}
main() {
  f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_unused_propagate() async {
    var content = '''
void f(String s) {}
void g({String s}) {
  f(s);
}
main() {
  g();
}
''';
    var expected = '''
void f(String? s) {}
void g({String? s}) {
  f(s);
}
main() {
  g();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_unused_required() async {
    // The `@required` annotation overrides the assumption of nullability.
    // The call at `f()` is presumed to be in error.
    addMetaPackage();
    var content = '''
import 'package:meta/meta.dart';
void f({@required String s}) {}
main() {
  f();
}
''';
    var expected = '''
import 'package:meta/meta.dart';
void f({required String s}) {}
main() {
  f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_used_non_null() async {
    var content = '''
void f({String s}) {}
main() {
  f(s: 'x');
}
''';
    var expected = '''
void f({String? s}) {}
main() {
  f(s: 'x');
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_used_non_null_propagate() async {
    var content = '''
void f(String s) {}
void g({String s}) {
  f(s);
}
main() {
  g(s: 'x');
}
''';
    var expected = '''
void f(String? s) {}
void g({String? s}) {
  f(s);
}
main() {
  g(s: 'x');
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_used_null_option2() async {
    var content = '''
void f({String s}) {}
main() {
  f(s: null);
}
''';
    var expected = '''
void f({String? s}) {}
main() {
  f(s: null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_no_default_used_null_required() async {
    // Explicitly passing `null` forces the parameter to be nullable even though
    // it is required.
    addMetaPackage();
    var content = '''
import 'package:meta/meta.dart';
void f({@required String s}) {}
main() {
  f(s: null);
}
''';
    var expected = '''
import 'package:meta/meta.dart';
void f({required String? s}) {}
main() {
  f(s: null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_named_parameter_with_non_null_default_unused_option2() async {
    var content = '''
void f({String s: 'foo'}) {}
main() {
  f();
}
''';
    var expected = '''
void f({String s: 'foo'}) {}
main() {
  f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_named_parameter_with_non_null_default_used_non_null_option2() async {
    var content = '''
void f({String s: 'foo'}) {}
main() {
  f(s: 'bar');
}
''';
    var expected = '''
void f({String s: 'foo'}) {}
main() {
  f(s: 'bar');
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_named_parameter_with_non_null_default_used_null_option2() async {
    var content = '''
void f({String s: 'foo'}) {}
main() {
  f(s: null);
}
''';
    var expected = '''
void f({String? s: 'foo'}) {}
main() {
  f(s: null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_named_parameter_with_null_default_unused_option2() async {
    var content = '''
void f({String s: null}) {}
main() {
  f();
}
''';
    var expected = '''
void f({String? s: null}) {}
main() {
  f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_non_null_assertion() async {
    var content = '''
int _f(int i, [int j]) {
  if (i == 0) return i;
  return i + j;
}
''';

    var expected = '''
int _f(int i, [int? j]) {
  if (i == 0) return i;
  return i + j!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_non_null_intent_field_formal_assert() async {
    var content = '''
class C {
  int i;
  C(this.i) {
    assert(i != null);
  }
}
f(int j, bool b) {
  if (b) {
    C(j);
  }
}
g() {
  f(null, false);
}
''';
    var expected = '''
class C {
  int i;
  C(this.i) {
    assert(i != null);
  }
}
f(int? j, bool b) {
  if (b) {
    C(j!);
  }
}
g() {
  f(null, false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_non_null_intent_field_formal_use() async {
    var content = '''
class C {
  int i;
  C(this.i) {
    f(i);
  }
}
f(int j) {
  assert(j != null);
}
g(int k, bool b) {
  if (b) {
    C(k);
  }
}
h() {
  g(null, false);
}
''';
    var expected = '''
class C {
  int i;
  C(this.i) {
    f(i);
  }
}
f(int j) {
  assert(j != null);
}
g(int? k, bool b) {
  if (b) {
    C(k!);
  }
}
h() {
  g(null, false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_non_null_intent_propagated_through_substitution_nodes() async {
    var content = '''
abstract class C {
  void f(List<int/*!*/> x, int y) {
    x.add(y);
  }
  int/*?*/ g();
  void test() {
    f(<int>[], g());
  }
}
''';
    var expected = '''
abstract class C {
  void f(List<int> x, int y) {
    x.add(y);
  }
  int? g();
  void test() {
    f(<int>[], g()!);
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_non_nullable_hint_comment_overrides_uncheckable_edge() async {
    var content = '''
Iterable<int> f(List<int> x) => x.map(g);
int g(int/*!*/ x) => x + 1;
main() {
  f([null]);
}
''';
    // TODO(paulberry): we should do something to flag the fact that g can't be
    // safely passed to f.
    var expected = '''
Iterable<int> f(List<int?> x) => x.map(g as int Function(int?));
int g(int x) => x + 1;
main() {
  f([null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_not_definitely_assigned_value() async {
    var content = '''
String f(bool b) {
  String s;
  if (b) {
    s = 'true';
  }
  return s;
}
''';
    var expected = '''
String? f(bool b) {
  String? s;
  if (b) {
    s = 'true';
  }
  return s;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_followed_by_if_null() async {
    var content = '''
typedef MapGetter = Map<String, String> Function();
void _f(Map<String, String> m) {}
void _g(MapGetter/*?*/ mapGetter) {
  _f(mapGetter?.call() ?? {});
}
''';
    var expected = '''
typedef MapGetter = Map<String, String> Function();
void _f(Map<String, String> m) {}
void _g(MapGetter? mapGetter) {
  _f(mapGetter?.call() ?? {});
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_on_closure_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of the closure, so it can tell whether it needs to be nullable or
    // not.
    //
    // (Note: this is not strictly true, because the closure could be called
    // from elsewhere.  But it's a heuristic that seems to be usually right in
    // the cases we've found so far.)
    var content = '''
main() {
  var x = (int i) => i?.abs();
}
''';
    var expected = '''
main() {
  var x = (int i) => i.abs();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_on_local_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of `f`, so it can tell whether it needs to be nullable or not.
    //
    // (Note: this is not strictly true, because the local function could be
    // torn off and called from elsewhere.  But it's a heuristic that seems to
    // be usually right in the cases we've found so far.)
    var content = '''
main() {
  int f(int i) => i?.abs();
}
''';
    var expected = '''
main() {
  int f(int i) => i.abs();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_on_migrated_get() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  int f2();
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.g?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.g.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_on_migrated_get_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  int f2();
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.g?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.g.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_on_migrated_method() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  int f2();
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.f()?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.f().f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_on_migrated_method_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  int f2();
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.f()?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.f().f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_on_nullable_get() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D? get g;
}
abstract class D {
  int f2();
}
''';
    // Since `.g` is a nullable getter in an already-migrated class, we don't
    // replace `?.` with `.`.
    var content = '''
import 'migrated.dart';
f(C c) => c.g?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.g?.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput});
  }

  Future<void> test_null_aware_call_on_nullable_method() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D? f();
}
abstract class D {
  int f2();
}
''';
    // Since `.f()` is a method with a nullable return type in an
    // already-migrated class, we don't replace `?.` with `.`.
    var content = '''
import 'migrated.dart';
f(C c) => c.f()?.f2();
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.f()?.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput});
  }

  Future<void> test_null_aware_call_on_private_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of `_f`, so it can tell whether it needs to be nullable or not.
    var content = 'int _f(int i) => i?.abs();';
    var expected = 'int _f(int i) => i.abs();';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_on_public_param_implies_nullable() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable.
    var content = 'int f(int i) => i?.abs();';
    var expected = 'int? f(int? i) => i?.abs();';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_null_aware_call_on_public_param_overridable_by_hint() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable, but an explicit `/*!*/` is a stronger signal.
    var content = 'int f(int/*!*/ i) => i?.abs();';
    var expected = 'int f(int i) => i.abs();';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_null_aware_call_on_public_param_overridable_by_intent() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable, but non-null intent is a stronger signal.
    var content = '''
int f(int i) {
  print(i + 1);
  return i?.abs();
}
''';
    var expected = '''
int f(int i) {
  print(i + 1);
  return i.abs();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_call_on_unmigrated_get() async {
    var migratedInput = '''
// @dart=2.12
abstract class D {
  int f2();
}
''';
    // Since `.g` is unmigrated, we don't replace `?.` with `.` in "warn on weak
    // code" mode.
    var content = '''
import 'migrated.dart';
abstract class C {
  D get g;
}
f(C c) => c.g?.f2();
''';
    var expected = '''
import 'migrated.dart';
abstract class C {
  D get g;
}
f(C c) => c.g?.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_on_unmigrated_method() async {
    var migratedInput = '''
// @dart=2.12
abstract class D {
  int f2();
}
''';
    // Since `.f()` is unmigrated, we don't replace `?.` with `.` in "warn on
    // weak code" mode.
    var content = '''
import 'migrated.dart';
abstract class C {
  D f();
}
f(C c) => c.f()?.f2();
''';
    var expected = '''
import 'migrated.dart';
abstract class C {
  D f();
}
f(C c) => c.f()?.f2();
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_call_tearoff() async {
    // Kind of a weird use case because `f?.call` is equivalent to `f`, but
    // let's make sure we analyze it correctly.
    var content =
        'int Function(int) g(int/*?*/ Function(int)/*?*/ f) => f?.call;';
    var expected = 'int? Function(int)? g(int? Function(int)? f) => f?.call;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_get_on_closure_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of the closure, so it can tell whether it needs to be nullable or
    // not.
    //
    // (Note: this is not strictly true, because the closure could be called
    // from elsewhere.  But it's a heuristic that seems to be usually right in
    // the cases we've found so far.)
    var content = '''
main() {
  var x = (int i) => i?.isEven;
}
''';
    var expected = '''
main() {
  var x = (int i) => i.isEven;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_get_on_local_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of `f`, so it can tell whether it needs to be nullable or not.
    //
    // (Note: this is not strictly true, because the local function could be
    // torn off and called from elsewhere.  But it's a heuristic that seems to
    // be usually right in the cases we've found so far.)
    var content = '''
main() {
  bool f(int i) => i?.isEven;
}
''';
    var expected = '''
main() {
  bool f(int i) => i.isEven;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_get_on_migrated_get() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  int get g2;
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.g?.g2;
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.g.g2;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_get_on_migrated_get_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  int get g2;
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.g?.g2;
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.g.g2;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_get_on_migrated_method() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  int get g2;
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.f()?.g2;
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.f().g2;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_get_on_migrated_method_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  int get g2;
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.f()?.g2;
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.f().g2;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_get_on_private_param_not_nullable() async {
    // The null-aware access on `i` is *not* considered a strong enough signal
    // that `i` is meant to be nullable, because the migration tool can see all
    // callers of `_f`, so it can tell whether it needs to be nullable or not.
    var content = 'bool _f(int i) => i?.isEven;';
    var expected = 'bool _f(int i) => i.isEven;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_get_on_public_param_implies_nullable() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable.
    var content = 'bool f(int i) => i?.isEven;';
    var expected = 'bool? f(int? i) => i?.isEven;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_get_on_public_param_overridable_by_hint() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable, but an explicit `/*!*/` is a stronger signal.
    var content = 'bool f(int/*!*/ i) => i?.isEven;';
    var expected = 'bool f(int i) => i.isEven;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_null_aware_get_on_public_param_overridable_by_intent() async {
    // The null-aware access on `i` is considered a strong signal that `i` is
    // meant to be nullable, but non-null intent is a stronger signal.
    var content = '''
bool f(int i) {
  print(i + 1);
  return i?.isEven;
}
''';
    var expected = '''
bool f(int i) {
  print(i + 1);
  return i.isEven;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_getter_invocation() async {
    var content = '''
bool f(int i) => i?.isEven;
main() {
  f(null);
}
''';
    var expected = '''
bool? f(int? i) => i?.isEven;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_method_invocation() async {
    var content = '''
int f(int i) => i?.abs();
main() {
  f(null);
}
''';
    var expected = '''
int? f(int? i) => i?.abs();
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_set_on_closure_param_not_nullable() async {
    // The null-aware access on `c` is *not* considered a strong enough signal
    // that `c` is meant to be nullable, because the migration tool can see all
    // callers of the closure, so it can tell whether it needs to be nullable or
    // not.
    //
    // (Note: this is not strictly true, because the closure could be called
    // from elsewhere.  But it's a heuristic that seems to be usually right in
    // the cases we've found so far.)
    var content = '''
class C {
  int i = 0;
}
main() {
  var x = (C c) { c?.i = 0; };
}
''';
    var expected = '''
class C {
  int i = 0;
}
main() {
  var x = (C c) { c.i = 0; };
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_set_on_local_param_not_nullable() async {
    // The null-aware access on `c` is *not* considered a strong enough signal
    // that `c` is meant to be nullable, because the migration tool can see all
    // callers of `f`, so it can tell whether it needs to be nullable or not.
    //
    // (Note: this is not strictly true, because the local function could be
    // torn off and called from elsewhere.  But it's a heuristic that seems to
    // be usually right in the cases we've found so far.)
    var content = '''
class C {
  int i = 0;
}
main() {
  void f(C c) { c?.i = 0; }
}
''';
    var expected = '''
class C {
  int i = 0;
}
main() {
  void f(C c) { c.i = 0; }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_set_on_migrated_get() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  set s(int i);
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.g?.s = 0;
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.g.s = 0;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_set_on_migrated_get_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D get g;
}
abstract class D {
  set s(int i);
}
''';
    // Since `.g` is a non-nullable getter in an already-migrated class, the
    // `?.` can safely be replaced with `.`.  We can safely make this change
    // even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.g?.s = 0;
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.g.s = 0;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_set_on_migrated_method() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  set s(int i);
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C c) => c.f()?.s = 0;
''';
    var expected = '''
import 'migrated.dart';
f(C c) => c.f().s = 0;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_set_on_migrated_method_null_shorting() async {
    var migratedInput = '''
// @dart=2.12
abstract class C {
  D f();
}
abstract class D {
  set s(int i);
}
''';
    // Since `.f()` is a method with a non-nullable return type in an
    // already-migrated class, the `?.` can safely be replaced with `.`.  We can
    // safely make this change even if we are in "warn on weak code" mode.
    var content = '''
import 'migrated.dart';
f(C/*?*/ c) => c?.f()?.s = 0;
''';
    var expected = '''
import 'migrated.dart';
f(C? c) => c?.f().s = 0;
''';
    await _checkSingleFileChanges(content, expected,
        migratedInput: {'$projectPath/lib/migrated.dart': migratedInput},
        warnOnWeakCode: true);
  }

  Future<void> test_null_aware_set_on_private_param_not_nullable() async {
    // The null-aware access on `c` is *not* considered a strong enough signal
    // that `c` is meant to be nullable, because the migration tool can see all
    // callers of `_f`, so it can tell whether it needs to be nullable or not.
    var content = '''
class C {
  int i = 0;
}
void _f(C c) { c?.i = 0; }
''';
    var expected = '''
class C {
  int i = 0;
}
void _f(C c) { c.i = 0; }
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_set_on_public_param_implies_nullable() async {
    // The null-aware access on `c` is considered a strong signal that `c` is
    // meant to be nullable.
    var content = '''
class C {
  int i = 0;
}
void f(C c) { c?.i = 0; }
''';
    var expected = '''
class C {
  int i = 0;
}
void f(C? c) { c?.i = 0; }
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_set_on_public_param_overridable_by_hint() async {
    // The null-aware access on `c` is considered a strong signal that `c` is
    // meant to be nullable, but an explicit `/*!*/` is a stronger signal.
    var content = '''
class C {
  int i = 0;
}
void f(C/*!*/ c) { c?.i = 0; }
''';
    var expected = '''
class C {
  int i = 0;
}
void f(C c) { c.i = 0; }
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_null_aware_set_on_public_param_overridable_by_intent() async {
    // The null-aware access on `c` is considered a strong signal that `c` is
    // meant to be nullable, but non-null intent is a stronger signal.
    var content = '''
class C {
  int i = 0;
}
void f(C c) {
  print(c.i);
  c?.i = 0;
}
''';
    var expected = '''
class C {
  int i = 0;
}
void f(C c) {
  print(c.i);
  c.i = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_setter_invocation_null_target() async {
    var content = '''
class C {
  void set x(int value) {}
}
int f(C c) => c?.x = 1;
main() {
  f(null);
}
''';
    var expected = '''
class C {
  void set x(int value) {}
}
int? f(C? c) => c?.x = 1;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_aware_setter_invocation_null_value() async {
    var content = '''
class C {
  void set x(int value) {}
}
int f(C c) => c?.x = 1;
main() {
  f(null);
}
''';
    var expected = '''
class C {
  void set x(int value) {}
}
int? f(C? c) => c?.x = 1;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_check_in_cascade_target() async {
    var content = '''
class _C {
  f() {}
}
_C g(int/*!*/ i) => _C();
test(int/*?*/ j) {
  g(j)..f();
}
''';
    var expected = '''
class _C {
  f() {}
}
_C g(int i) => _C();
test(int? j) {
  g(j!)..f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_check_type_parameter_type_with_nullable_bound() async {
    var content = '''
abstract class C<E, T extends Iterable<E>/*?*/> {
  void f(T iter) {
    for(var i in iter) {}
  }
}
''';
    var expected = '''
abstract class C<E, T extends Iterable<E>?> {
  void f(T iter) {
    for(var i in iter!) {}
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_in_conditional_expression() async {
    var content = '''
void f() {
  List<int> x = false ? [] : null;
}
''';
    var expected = '''
void f() {
  List<int>? x = false ? [] : null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_null_typed_expression_wiithout_valid_migration() async {
    var content = '''
void f(int/*!*/ x) {}
void g() {
  f(h());
}
Null h() => null;
''';
    var expected = '''
void f(int x) {}
void g() {
  f(h());
}
Null h() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_nullable_use_of_typedef() async {
    var content = '''
typedef F<T> = int Function(T);
F<String> f = null;
void main() {
  f('foo');
}
''';
    var expected = '''
typedef F<T> = int Function(T);
F<String>? f = null;
void main() {
  f!('foo');
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_nullTestOnGenericType_explicitBound() async {
    var content = '''
void f<T extends Object>(T x, T y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    var expected = '''
void f<T extends Object>(T? x, T? y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_nullTestOnGenericType_implicitBound() async {
    var content = '''
void f<T>(T x, T y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    var expected = '''
void f<T>(T? x, T? y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_nullTestOnGenericType_nonNullableBound() async {
    var content = '''
void f<T extends Object/*!*/>(T x, T y) {
  if (x == null) return;
  if (y == null) return;
}
''';
    var expected = '''
void f<T extends Object>(T? x, T? y) {
  if (x == null) return;
  if (y == null) return;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_nullTestOnGenericType_nullableBound() async {
    var content = '''
void f<T extends Object/*?*/>(T x, T y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    var expected = '''
void f<T extends Object?>(T? x, T? y) {
  if (x == null) return;
  if (y == null) return;
}
g() => f(1, null);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_operator_eq_with_inferred_parameter_type() async {
    var content = '''
class C {
  operator==(Object other) {
    return other is C;
  }
}
''';
    var expected = '''
class C {
  operator==(Object other) {
    return other is C;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_object_from_type_parameter() async {
    var content = '''
class C<T> {
  f(T t) {}
}
class D<T> extends C<T> {
  @override
  f(Object t) {}
}
''';
    var expected = '''
class C<T> {
  f(T t) {}
}
class D<T> extends C<T> {
  @override
  f(Object? t) {}
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_parameter_type_non_nullable() async {
    var content = '''
abstract class Base {
  void f(int i);
}
class Derived extends Base {
  void f(int i) {
    i + 1;
  }
}
void _g(int i, bool b, Base base) {
  if (b) {
    base.f(i);
  }
}
void _h(Base base) {
  _g(null, false, base);
}
''';
    var expected = '''
abstract class Base {
  void f(int? i);
}
class Derived extends Base {
  void f(int? i) {
    i! + 1;
  }
}
void _g(int? i, bool b, Base base) {
  if (b) {
    base.f(i);
  }
}
void _h(Base base) {
  _g(null, false, base);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_parameter_type_nullable() async {
    var content = '''
abstract class Base {
  void f(int i);
}
class Derived extends Base {
  void f(int i) {}
}
void _g(int i, Base base) {
  base.f(null);
}
''';
    var expected = '''
abstract class Base {
  void f(int? i);
}
class Derived extends Base {
  void f(int? i) {}
}
void _g(int i, Base base) {
  base.f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_parameter_type_unknown() async {
    var content = '''
abstract class Base {
  void f(int/*!*/ i, int/*!*/ j);
}
class Derived extends Base {
  void f(int i, int j) {
    i + 1;
  }
}
''';
    var expected = '''
abstract class Base {
  void f(int i, int j);
}
class Derived extends Base {
  void f(int i, int j) {
    i + 1;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_return_type_non_nullable() async {
    var content = '''
abstract class Base {
  int/*!*/ f();
}
class Derived extends Base {
  int f() => g();
}
int g() => null;
''';
    var expected = '''
abstract class Base {
  int f();
}
class Derived extends Base {
  int f() => g()!;
}
int? g() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_return_type_nullable() async {
    var content = '''
abstract class Base {
  int f();
}
class Derived extends Base {
  int f() => null;
}
''';
    var expected = '''
abstract class Base {
  int? f();
}
class Derived extends Base {
  int? f() => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_return_type_nullable_substitution_complex() async {
    var content = '''
abstract class Base<T> {
  T f();
}
class Derived extends Base<List<int>> {
  List<int> f() => <int>[null];
}
''';
    var expected = '''
abstract class Base<T> {
  T f();
}
class Derived extends Base<List<int?>> {
  List<int?> f() => <int?>[null];
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_override_return_type_nullable_substitution_simple() async {
    var content = '''
abstract class Base<T> {
  T f();
}
class Derived extends Base<int> {
  int f() => null;
}
''';
    var expected = '''
abstract class Base<T> {
  T f();
}
class Derived extends Base<int?> {
  int? f() => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_parameter_genericFunctionType() async {
    var content = '''
int _f(int x, int Function(int i) g) {
  return g(x);
}
''';
    var expected = '''
int _f(int x, int Function(int i) g) {
  return g(x);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): cfg is no longer altered here, remove?
  Future<void> test_postdominating_usage_after_cfg_altered() async {
    // By altering the control-flow graph, we can create new postdominators,
    // which are not recognized as such. This is not a problem as we only do
    // hard edges on a best-effort basis, and this case would be a lot of
    // additional complexity.
    var content = '''
int f(int a, int b, int c) {
  if (a != null) {
    b.toDouble();
  } else {
    return null;
  }
  c.toDouble;
}

void main() {
  f(1, null, null);
}
''';
    var expected = '''
int? f(int? a, int? b, int? c) {
  if (a != null) {
    b!.toDouble();
  } else {
    return null;
  }
  c!.toDouble;
}

void main() {
  f(1, null, null);
}
''';
    await _checkSingleFileChanges(content, expected, removeViaComments: true);
  }

  Future<void> test_prefix_minus() async {
    var content = '''
class C {
  D operator-() => null;
}
class D {}
D test(C c) => -c;
''';
    var expected = '''
class C {
  D? operator-() => null;
}
class D {}
D? test(C c) => -c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_prefix_minus_substitute() async {
    var content = '''
abstract class C<T> {
  D<T> operator-();
}
class D<U> {}
D<int> test(C<int/*?*/> c) => -c;
''';
    var expected = '''
abstract class C<T> {
  D<T> operator-();
}
class D<U> {}
D<int?> test(C<int?> c) => -c;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_prefixes() async {
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/file1.dart');
    var file1 = '''
import 'file2.dart';
int x;
int f() => null;
''';
    var expected1 = '''
import 'file2.dart';
int? x;
int? f() => null;
''';
    var path2 = convertPath('$root/file2.dart');
    var file2 = '''
import 'file1.dart' as f1;
void main() {
  f1.x = f1.f();
}
''';
    var expected2 = '''
import 'file1.dart' as f1;
void main() {
  f1.x = f1.f();
}
''';
    await _checkMultipleFileChanges(
        {path1: file1, path2: file2}, {path1: expected1, path2: expected2});
  }

  Future<void> test_prefixExpression_bang() async {
    var content = '''
bool f(bool b) => !b;
void g(bool b1, bool b2) {
  if (b1) {
    f(b2);
  }
}
main() {
  g(false, null);
}
''';
    var expected = '''
bool f(bool b) => !b;
void g(bool b1, bool? b2) {
  if (b1) {
    f(b2!);
  }
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_promotion_conditional_variableRead() async {
    var content = '''
_f({int i}) {
  i = i == null ? 0 : i;
  _g(i);
}

_g(int j) {}
''';
    var expected = '''
_f({int? i}) {
  i = i == null ? 0 : i;
  _g(i);
}

_g(int j) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_promotion_ifNull_variableRead() async {
    var content = '''
_f({int i}) {
  i ??= 3;
  _g(i);
}

_g(int j) {}
''';
    var expected = '''
_f({int? i}) {
  i ??= 3;
  _g(i);
}

_g(int j) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_promotion_ifNull_variableRead_alreadyPromoted() async {
    var content = '''
_f({num i}) {
  if (i is int /*?*/) {
    i ??= 3;
    _g(i);
  }
}

_g(int j) {}
''';
    var expected = '''
_f({num? i}) {
  if (i is int?) {
    i ??= 3;
    _g(i);
  }
}

_g(int j) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_promotion_ifNull_variableRead_subType() async {
    var content = '''
_f({num i}) {
  i ??= 3;
  _g(i);
}

_g(int j) {}
''';
    var expected = '''
_f({num? i}) {
  i ??= 3;
  _g(i as int);
}

_g(int j) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_promotion_preserves_complex_types() async {
    var content = '''
int/*!*/ f(List<int/*?*/>/*?*/ x) {
  x ??= [0];
  return x[0];
}
''';
    // `x ??= [0]` promotes x from List<int?>? to List<int?>.  Since there is
    // still a `?` on the `int`, `x[0]` must be null checked.
    var expected = '''
int f(List<int?>? x) {
  x ??= [0];
  return x[0]!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_propagate_non_null_intent_into_function_literal() async {
    var content = '''
void f(int/*!*/ Function(int) callback) {
  callback(null);
}
void test() {
  f((int x) => x);
}
''';
    // Since the function literal `(int x) => x` is created right here at the
    // point where it's passed to `f`'s `callback` parameter, non-null intent is
    // allowed to propagate backward from the return type of `callback` to the
    // return type of the function literal.  As a result, the reference to `x`
    // in the function literal is null checked.
    var expected = '''
void f(int Function(int?) callback) {
  callback(null);
}
void test() {
  f((int? x) => x!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_property_access_on_cascade_result() async {
    var content = '''
int f(List<int> l) {
  l..first.isEven
   ..firstWhere((_) => true).isEven
   ..[0].isEven;
}

void g() {
  f([null]);
}
''';
    var expected = '''
int f(List<int?> l) {
  l..first!.isEven
   ..firstWhere((_) => true)!.isEven
   ..[0]!.isEven;
}

void g() {
  f([null]);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_quiver_checkNotNull_field_formal_initializer() async {
    addQuiverPackage();
    var content = '''
import 'package:quiver/check.dart';
class C {
  final int i;
  C(this.i) {
    checkNotNull(i);
  }
}
void f(bool b, int i) {
  if (b) new C(i);
}
main() {
  f(false, null);
}
''';
    // Note: since the reference to `i` in `checkNotNull(i)` refers to the field
    // rather than the formal parameter, this isn't considered sufficient to
    // mark the field as non-nullable (even though that's the clear intention
    // in this case).  Changing the behavior to match user intent would require
    // more development work; for now we just want to make sure we provide a
    // fairly reasonable migration without crashing.
    var expected = '''
import 'package:quiver/check.dart';
class C {
  final int? i;
  C(this.i) {
    checkNotNull(i);
  }
}
void f(bool b, int? i) {
  if (b) new C(i);
}
main() {
  f(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_quiver_checkNotNull_implies_non_null_intent() async {
    addQuiverPackage();
    var content = '''
import 'package:quiver/check.dart';
void f(int i) {
  checkNotNull(i);
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
import 'package:quiver/check.dart';
void f(int i) {
  checkNotNull(i);
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_redirecting_constructor_factory() async {
    var content = '''
class C {
  factory C(int i, int j) = D;
}
class D implements C {
  D(int i, int j);
}
main() {
  C(null, 1);
}
''';
    var expected = '''
class C {
  factory C(int? i, int? j) = D;
}
class D implements C {
  D(int? i, int? j);
}
main() {
  C(null, 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_redirecting_constructor_ordinary() async {
    var content = '''
class C {
  C(int i, int j) : this.named(j, i);
  C.named(int j, int i);
}
main() {
  C(null, 1);
}
''';
    var expected = '''
class C {
  C(int? i, int? j) : this.named(j, i);
  C.named(int? j, int? i);
}
main() {
  C(null, 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_redirecting_constructor_ordinary_to_unnamed() async {
    var content = '''
class C {
  C.named(int i, int j) : this(j, i);
  C(int j, int i);
}
main() {
  C.named(null, 1);
}
''';
    var expected = '''
class C {
  C.named(int? i, int? j) : this(j, i);
  C(int? j, int? i);
}
main() {
  C.named(null, 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_reference_to_mixin_getter() async {
    var content = '''
mixin M {
  Object f() => this.x;

  Object get x => null;
}
''';
    var expected = '''
mixin M {
  Object? f() => this.x;

  Object? get x => null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_regression_40551() async {
    var content = '''
class B<T extends Object> { // bound should not be made nullable
  void f(T t) { // parameter should not be made nullable
    // Create an edge from the bound to some type
    List<dynamic> x = [t];
    // and make that type exact nullable
    x[0] = null;
  }
}
''';
    var expected = '''
class B<T extends Object> { // bound should not be made nullable
  void f(T t) { // parameter should not be made nullable
    // Create an edge from the bound to some type
    List<dynamic> x = [t];
    // and make that type exact nullable
    x[0] = null;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_regression_40552() async {
    var content = '''
void _f(Object o) { // parameter should not be made nullable
  // Create an edge from the bound to some type
  List<dynamic> x = [o];
  // and make that type exact nullable
  x[0] = null;
}
''';
    var expected = '''
void _f(Object o) { // parameter should not be made nullable
  // Create an edge from the bound to some type
  List<dynamic> x = [o];
  // and make that type exact nullable
  x[0] = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_regression_42374() async {
    var content = '''
class C<R> {
  R m(dynamic x) {
    assert(x is R);
    return x as R;
  }
}

void main() {
  C<int/*!*/>().m(null/*!*/);
}
''';
    var expected = '''
class C<R> {
  R m(dynamic x) {
    assert(x is R);
    return x as R;
  }
}

void main() {
  C<int>().m(null!);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_remove_question_from_question_dot() async {
    var content = '_f(int/*!*/ i) => i?.isEven;';
    var expected = '_f(int i) => i.isEven;';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_remove_question_from_question_dot_and_add_bang() async {
    var content = '''
class C {
  int/*?*/ i;
}
int/*!*/ f(C/*!*/ c) => c?.i;
''';
    var expected = '''
class C {
  int? i;
}
int f(C c) => c.i!;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_remove_question_from_question_dot_method() async {
    var content = '_f(int/*!*/ i) => i?.abs();';
    var expected = '_f(int i) => i.abs();';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_remove_question_from_question_dot_shortcut() async {
    var content = '''
class C {
  int/*!*/ i;
}
bool/*?*/ f(C/*?*/ c) => c?.i?.isEven;
''';
    var expected = '''
class C {
  int i;
}
bool? f(C? c) => c?.i.isEven;
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): element is not removed anymore, remove test?
  Future<void> test_removed_if_element_doesnt_introduce_nullability() async {
    // Failing because we don't yet remove the dead list element
    // `if (x == null) recover()`.
    var content = '''
f(int x) {
  <int>[if (x == null) recover(), 0];
}
int recover() {
  assert(false);
  return null;
}
''';
    var expected = '''
f(int? x) {
  <int?>[if (x == null) recover(), 0];
}
int? recover() {
  assert(false);
  return null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_requiredness_does_not_propagate_between_field_formal_params() async {
    addMetaPackage();
    var content = '''
import 'package:meta/meta.dart';
class C {
  final bool x;
  C.one({this.x});
  C.two({@required this.x}) : assert(x != null);
}
test() => C.one();
''';
    var expected = '''
import 'package:meta/meta.dart';
class C {
  final bool? x;
  C.one({this.x});
  C.two({required bool this.x}) : assert(x != null);
}
test() => C.one();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_return_future_or_null_from_async_method() async {
    var content = '''
import 'dart:async';
Future<Null> f() async => g();
FutureOr<Null> g() => null;
''';
    var expected = '''
import 'dart:async';
Future<Null> f() async => g();
FutureOr<Null> g() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_setter_overrides_implicit_setter() async {
    var content = '''
class A {
  String s = "x";
}
class C implements A {
  String get s => "x";
  void set s(String value) {}
}
f() => A().s = null;
''';
    var expected = '''
class A {
  String? s = "x";
}
class C implements A {
  String get s => "x";
  void set s(String? value) {}
}
f() => A().s = null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_single_file_multiple_changes() async {
    var content = '''
int f() => null;
int g() => null;
''';
    var expected = '''
int? f() => null;
int? g() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_single_file_single_change() async {
    var content = '''
int f() => null;
''';
    var expected = '''
int? f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_singleWhere_non_nullable() async {
    var content = '''
int singleEven(Iterable<int> x)
    => x.singleWhere((x) => x.isEven, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension;

int? singleEven(Iterable<int> x)
    => x.singleWhereOrNull((x) => x.isEven);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_singleWhere_nullable() async {
    var content = '''
int singleEven(Iterable<int> x)
    => x.singleWhere((x) => x.isEven, orElse: () => null);
f() => singleEven([null]);
''';
    var expected = '''
int? singleEven(Iterable<int?> x)
    => x.singleWhere((x) => x!.isEven, orElse: () => null);
f() => singleEven([null]);
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40728')
  Future<void> test_soft_edge_for_assigned_variable() async {
    var content = '''
void f(int i) {
  print(i + 1);
  i = null;
  print(i);
}
main() {
  f(0);
}
''';
    var expected = '''
void f(int? i) {
  print(i! + 1);
  i = null;
  print(i);
}
main() {
  f(0);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_tearoff_parameter_matching_named() async {
    var content = '''
void f(int x, void Function({int x}) callback) {
  callback(x: x);
}
void g({int x}) {
  assert(x != null);
}
void h() {
  f(null, g);
}
''';
    // Normally the assertion in g would cause g's `x` argument to be
    // non-nullable (and thus required).  However, since g is torn off and
    // passed to f, which requires a callback that accepts null, g's `x`
    // argument is nullable (and thus not required).
    var expected = '''
void f(int? x, void Function({int? x}) callback) {
  callback(x: x);
}
void g({int? x}) {
  assert(x != null);
}
void h() {
  f(null, g);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_assignedInjectorGet() async {
    addAngularPackage();
    addTestCorePackage();
    var content = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void main() {
  int i;
  setUp(() {
    var injector = Injector();
    i = injector.get(int);
  });
  test('a', () {
    i.isEven;
  });
}
''';
    var expected = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void main() {
  late int i;
  setUp(() {
    var injector = Injector();
    i = injector.get(int);
  });
  test('a', () {
    i.isEven;
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_assignedInjectorGet_inDeclaration() async {
    addAngularPackage();
    addTestCorePackage();
    var content = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void main() {
  setUp(() {
    var injector = Injector();
    int i = injector.get(int);
    i.isEven;
  });
}
''';
    var expected = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void main() {
  setUp(() {
    var injector = Injector();
    int i = injector.get(int);
    i.isEven;
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_assignedInjectorGet_nullableUse() async {
    addAngularPackage();
    addTestCorePackage();
    var content = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void f(int /*?*/ i) {}
void main() {
  int i;
  setUp(() {
    var injector = Injector();
    i = injector.get(int);
  });
  test('a', () {
    f(i);
  });
}
''';
    var expected = '''
import 'package:angular/angular.dart';
import 'package:test/test.dart';
void f(int? i) {}
void main() {
  late int i;
  setUp(() {
    var injector = Injector();
    i = injector.get(int);
  });
  test('a', () {
    f(i);
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_assignedInjectorGet_outsideSetup() async {
    addAngularPackage();
    addTestCorePackage();
    var content = '''
import 'package:angular/angular.dart';
void main() {
  int i;
  var injector = Injector();
  i = injector.get(int);
  i.isEven;
}
''';
    var expected = '''
import 'package:angular/angular.dart';
void main() {
  int? i;
  var injector = Injector();
  i = injector.get(int);
  i!.isEven;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_assignedNullableValue() async {
    addTestCorePackage();
    var content = '''
import 'package:test/test.dart';
void main() {
  int i;
  setUp(() {
    i = null;
  });
  test('a', () {
    i.isEven;
  });
}
''';
    var expected = '''
import 'package:test/test.dart';
void main() {
  int? i;
  setUp(() {
    i = null;
  });
  test('a', () {
    i!.isEven;
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_downstreamAllNonNull() async {
    addTestCorePackage();
    var content = '''
import 'package:test/test.dart';
void main() {
  int i;
  setUp(() {
    i = 1;
  });
  test('a', () {
    i.isEven;
  });
}
''';
    var expected = '''
import 'package:test/test.dart';
void main() {
  late int i;
  setUp(() {
    i = 1;
  });
  test('a', () {
    i.isEven;
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_hasInitializer() async {
    addTestCorePackage();
    var content = '''
import 'package:test/test.dart';
void main() {
  int i = 1;
  setUp(() {
    i = 1;
  });
}
''';
    var expected = '''
import 'package:test/test.dart';
void main() {
  int i = 1;
  setUp(() {
    i = 1;
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_testVariable_usedAsNullable() async {
    addTestCorePackage();
    var content = '''
import 'package:test/test.dart';
void main() {
  int i;
  setUp(() {
    i = 1;
  });
  f(int /*?*/ i) {}
  test('a', () {
    f(i);
  });
}
''';
    var expected = '''
import 'package:test/test.dart';
void main() {
  late int i;
  setUp(() {
    i = 1;
  });
  f(int? i) {}
  test('a', () {
    f(i);
  });
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_this_inside_extension() async {
    var content = '''
class C<T> {
  T field;
  C(this.field);
}
extension on C<int> {
  f() {
    this.field = null;
  }
}
extension on C<List<int>> {
  f() {
    this.field = [null];
  }
}
''';
    var expected = '''
class C<T> {
  T field;
  C(this.field);
}
extension on C<int?> {
  f() {
    this.field = null;
  }
}
extension on C<List<int?>> {
  f() {
    this.field = [null];
  }
}
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_topLevelFunction_parameterType_implicit_dynamic() async {
    var content = '''
Object _f(x) => x;
''';
    // Note: even though the type `dynamic` permits `null`, the migration engine
    // sees that there is no code path that passes a null value to `f`, so it
    // leaves its return type as `Object`, and there is an implicit downcast.
    var expected = '''
Object _f(x) => x;
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39369')
  Future<void> test_topLevelFunction_returnType_implicit_dynamic() async {
    var content = '''
f() {}
Object g() => f();
''';
    var expected = '''
f() {}
Object? g() => f();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_topLevelVariable_type_inferred() async {
    var content = '''
int f() => null;
var x = 1;
void main() {
  x = f();
}
''';
    // The type of x is inferred as non-nullable from its initializer, but we
    // try to assign a nullable value to it.  So an explicit type must be added.
    var expected = '''
int? f() => null;
int? x = 1;
void main() {
  x = f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_topLevelVariable_uninitialized_used() async {
    var content = '''
String s;
f() {
  g(s);
}
g(String /*!*/ s) {}
''';
    var expected = '''
late String s;
f() {
  g(s);
}
g(String s) {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_two_files() async {
    var root = '$projectPath/lib';
    var path1 = convertPath('$root/file1.dart');
    var file1 = '''
import 'file2.dart';
int f() => null;
int h() => g();
''';
    var expected1 = '''
import 'file2.dart';
int? f() => null;
int? h() => g();
''';
    var path2 = convertPath('$root/file2.dart');
    var file2 = '''
import 'file1.dart';
int g() => f();
''';
    var expected2 = '''
import 'file1.dart';
int? g() => f();
''';
    await _checkMultipleFileChanges(
        {path1: file1, path2: file2}, {path1: expected1, path2: expected2});
  }

  Future<void> test_type_argument_flows_to_bound() async {
    // The inference of C<int?> forces class C to be declared as
    // C<T extends Object?>.
    var content = '''
abstract class C<T extends Object> {
  void m(T t);
}
abstract class D<T extends Object> {
  void m(T t);
}
_f(C<int> c, D<int> d) {
  c.m(null);
}
''';
    var expected = '''
abstract class C<T extends Object?> {
  void m(T t);
}
abstract class D<T extends Object> {
  void m(T t);
}
_f(C<int?> c, D<int> d) {
  c.m(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_complex() async {
    var content = '''
typedef F<R> = Function(R);

class C<T> {
  F<T> _f;

  C(this._f) {
    f(null);
  }

  f(Object o) {
    _f(o as T);
  }
}
''';
    var expected = '''
typedef F<R> = Function(R);

class C<T> {
  F<T?> _f;

  C(this._f) {
    f(null);
  }

  f(Object? o) {
    _f(o as T?);
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_migrated_lhs_parameters() async {
    var content = '''
import 'migrated_typedef.dart';
void main(F<int> f) {
  f(null);
}
''';
    var expected = '''
import 'migrated_typedef.dart';
void main(F<int?> f) {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/migrated_typedef.dart': '''
// @dart=2.12
typedef F<R> = Function(R);
'''
    });
  }

  Future<void> test_typedef_assign_null_migrated_lhs_rhs_parameters() async {
    var content = '''
import 'migrated_typedef.dart';
void f1(F<int> f) {
  f<int>(null, null);
}
void f2(F<int> f) {
  f<int>(0, null);
}
void f3(F<int> f) {
  f<int>(null, 1);
}
void f4(F<int> f) {
  f<int>(0, 1);
}
''';
    var expected = '''
import 'migrated_typedef.dart';
void f1(F<int?> f) {
  f<int?>(null, null);
}
void f2(F<int> f) {
  f<int?>(0, null);
}
void f3(F<int?> f) {
  f<int>(null, 1);
}
void f4(F<int> f) {
  f<int>(0, 1);
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/migrated_typedef.dart': '''
// @dart=2.12
typedef F<T> = Function<R>(T, R);
'''
    });
  }

  Future<void> test_typedef_assign_null_migrated_rhs_parameters() async {
    var content = '''
import 'migrated_typedef.dart';
void main(F f) {
  f<int>(null);
}
''';
    var expected = '''
import 'migrated_typedef.dart';
void main(F f) {
  f<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected, migratedInput: {
      '$projectPath/lib/migrated_typedef.dart': '''
// @dart=2.12
typedef F = Function<R>(R);
'''
    });
  }

  Future<void> test_typedef_assign_null_parameter() async {
    var content = '''
typedef F = Function(int);

F/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F = Function(int?);

late F _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_return() async {
    var content = '''
typedef F = int Function();

F _f = () => null;
''';
    var expected = '''
typedef F = int? Function();

F _f = () => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

//  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/40388')
// TODO(yanok): the test stopped failing since we don't emit casts for
// unrelated types anymore, but the issue mentioned still exists.
  Future<void> test_typedef_assign_null_return_type_formal() async {
    var content = '''
typedef F = T Function<T>();

F _f = <T>() => null;
''';
    var expected = '''
typedef F = T? Function<T>();

F _f = <T>() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_return_type_parameter() async {
    var content = '''
typedef F<T> = T Function();

F<int> _f = () => null;
''';
    var expected = '''
typedef F<T> = T Function();

F<int?> _f = () => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_type_formal() async {
    var content = '''
typedef F = Function<T>(T);

F/*!*/ _f;

f() {
  _f<int>(null);
}
''';
    var expected = '''
typedef F = Function<T>(T);

late F _f;

f() {
  _f<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_type_formal_with_parameter() async {
    var content = '''
typedef F<R> = Function<T>(T);

F<Object>/*!*/ _f;

f() {
  _f<int>(null);
}
''';
    var expected = '''
typedef F<R> = Function<T>(T);

late F<Object> _f;

f() {
  _f<int?>(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_type_parameter() async {
    var content = '''
typedef F<T> = Function(T);

F<int>/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F<T> = Function(T);

late F<int?> _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_type_parameter_non_null() async {
    var content = '''
typedef F<T> = Function(T);

F<int>/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F<T> = Function(T);

late F<int?> _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_assign_null_type_return_value_nested() async {
    var content = '''
typedef F<T> = T Function();

F<F<int>> f = () => () => null;
''';
    var expected = '''
typedef F<T> = T Function();

F<F<int?>> f = () => () => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_old_assign_null_parameter() async {
    var content = '''
typedef F(int x);

F/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F(int? x);

late F _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_old_assign_null_return() async {
    var content = '''
typedef int F();

F _f = () => null;
''';
    var expected = '''
typedef int? F();

F _f = () => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_old_assign_null_return_type_parameter() async {
    var content = '''
typedef T F<T>();

F<int> _f = () => null;
''';
    var expected = '''
typedef T F<T>();

F<int?> _f = () => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_old_assign_null_type_parameter() async {
    var content = '''
typedef F<T>(T t);

F<int>/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F<T>(T t);

late F<int?> _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_typedef_old_assign_null_type_parameter_non_null() async {
    var content = '''
typedef F<T>(T t);

F<int>/*!*/ _f;

f() {
  _f(null);
}
''';
    var expected = '''
typedef F<T>(T t);

late F<int?> _f;

f() {
  _f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_assert_is_statement_implies_non_null_intent() async {
    var content = '''
void f(Object i) {
  assert(i is int);
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(Object i) {
  assert(i is int);
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_assert_statement_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  assert(i != null);
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  assert(i != null);
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_binary_expression_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  i + 1;
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  i + 1;
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_cascaded_indexed_set_implies_non_null_intent() async {
    var content = '''
class C {
  operator[]=(int i, int j) {}
}
void _f(C c) {
  c..[1] = 2;
}
void _g(bool b, C c) {
  if (b) _f(c);
}
main() {
  _g(false, null);
}
''';
    var expected = '''
class C {
  operator[]=(int? i, int? j) {}
}
void _f(C c) {
  c..[1] = 2;
}
void _g(bool b, C? c) {
  if (b) _f(c!);
}
main() {
  _g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_cascaded_method_call_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  i..abs();
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  i..abs();
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_cascaded_property_set_implies_non_null_intent() async {
    var content = '''
class C {
  int x = 0;
}
void f(C c) {
  c..x = 1;
}
void g(bool b, C c) {
  if (b) f(c);
}
main() {
  g(false, null);
}
''';
    var expected = '''
class C {
  int x = 0;
}
void f(C c) {
  c..x = 1;
}
void g(bool b, C? c) {
  if (b) f(c!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_unconditional_method_call_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  i.abs();
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  i.abs();
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_method_call_implies_non_null_intent_after_conditions() async {
    var content = '''
void g(bool b, int i1, int i2) {
  int i3 = i1;
  if (b) {
    b;
  }
  i3.toDouble();
  int i4 = i2;
  if (b) {
    b;
    return;
  }
  i4.toDouble();
}
test(int/*?*/ n) {
  g(false, n, null);
}
''';
    var expected = '''
void g(bool b, int i1, int? i2) {
  int i3 = i1;
  if (b) {
    b;
  }
  i3.toDouble();
  int? i4 = i2;
  if (b) {
    b;
    return;
  }
  i4!.toDouble();
}
test(int? n) {
  g(false, n!, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_method_call_implies_non_null_intent_in_condition() async {
    var content = '''
void g(bool b, int _i) {
  if (b) {
    int i = _i;
    i.toDouble();
  }
}
main() {
  g(false, null);
}
''';
    var expected = '''
void g(bool b, int? _i) {
  if (b) {
    int i = _i!;
    i.toDouble();
  }
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_non_null_usage_implies_non_null_intent() async {
    var content = '''
void _f(int i, int j) {
  i.gcd(j);
}
void _g(bool b, int i, int j) {
  if (b) _f(i, j);
}
main() {
  _g(false, 0, null);
}
''';
    var expected = '''
void _f(int i, int j) {
  i.gcd(j);
}
void _g(bool b, int i, int? j) {
  if (b) _f(i, j!);
}
main() {
  _g(false, 0, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_property_access_implies_non_null_intent() async {
    var content = '''
void f(int i) {
  i.isEven;
}
void g(bool b, int i) {
  if (b) f(i);
}
main() {
  g(false, null);
}
''';
    var expected = '''
void f(int i) {
  i.isEven;
}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_unconditional_usage_propagates_non_null_intent() async {
    var content = '''
void f(int i) {
  assert(i != null);
}
void g(int i) {
  f(i);
}
void h(bool b, int i) {
  if (b) g(i);
}
main() {
  h(false, null);
}
''';
    var expected = '''
void f(int i) {
  assert(i != null);
}
void g(int i) {
  f(i);
}
void h(bool b, int? i) {
  if (b) g(i!);
}
main() {
  h(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_use_of_field_formal_param_does_not_create_hard_edge() async {
    var content = '''
class C {
  int i;
  int j;
  C.one(this.i) : j = i + 1;
  C.two() : i = null, j = 0;
}
''';
    var expected = '''
class C {
  int? i;
  int j;
  C.one(int this.i) : j = i + 1;
  C.two() : i = null, j = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void>
      test_unconditional_use_of_field_formal_param_does_not_create_hard_edge_generic() async {
    var content = '''
class C {
  List<int/*?*/> i;
  int j;
  C.one(this.i) : j = i.length;
  C.two() : i = null, j = 0;
}
''';
    var expected = '''
class C {
  List<int?>? i;
  int j;
  C.one(List<int?> this.i) : j = i.length;
  C.two() : i = null, j = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_uninitialized_instance_field_is_nullable() async {
    var content = '''
class C {
  int i;
  f() {
    print(i == null);
  }
}
''';
    var expected = '''
class C {
  int? i;
  f() {
    print(i == null);
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_uninitialized_static_field_is_nullable() async {
    var content = '''
class C {
  static int i;
  f() {
    print(i == null);
  }
}
''';
    var expected = '''
class C {
  static int? i;
  f() {
    print(i == null);
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_uninitialized_toplevel_var_is_nullable() async {
    var content = '''
int i;
f() {
  print(i == null);
}
''';
    var expected = '''
int? i;
f() {
  print(i == null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_unnecessary_cast_remove() async {
    var content = '''
_f(Object x) {
  if (x is! int) return;
  print((x as int) + 1);
}
''';
    var expected = '''
_f(Object x) {
  if (x is! int) return;
  print(x + 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44012')
  Future<void> test_use_import_prefix_when_adding_re_exported_type() async {
    addPackageFile('http', 'http.dart', '''
export 'src/base_client.dart';
export 'src/client.dart';
''');
    addPackageFile('http', 'src/base_client.dart', '''
import 'client.dart';
abstract class BaseClient implements Client {}
''');
    addPackageFile('http', 'src/client.dart', '''
abstract class Client {}
''');
    var content = '''
import 'package:http/http.dart' as http;
http.BaseClient downcast(http.Client x) => x;
''';
    var expected = '''
import 'package:http/http.dart' as http;
http.BaseClient downcast(http.Client x) => x as http.BaseClient;
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_var_with_different_types() async {
    // Based on https://github.com/dart-lang/sdk/issues/47669
    var content = '''
class C<T> {
  T m() => throw 'foo';
}
f(bool b, List<C<int>> cs) {
  var x = !b,
      y = cs.first,
      z = y.m();
}
''';
    var expected = '''
class C<T> {
  T m() => throw 'foo';
}
f(bool b, List<C<int>> cs) {
  var x = !b,
      y = cs.first,
      z = y.m();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_var_with_different_types_becoming_explicit() async {
    // When types need to be added to some variables in a declaration but not
    // others, we handle it by introducing `as` casts.
    var content = '''
_f(int i, String s) {
  var x = i, y = s;
  x = null;
}
''';
    var expected = '''
_f(int i, String s) {
  var x = i as int?, y = s;
  x = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  // TODO(yanok): does it still make sense?
  Future<void> test_weak_if_visit_weak_subexpression() async {
    var content = '''
int f(int x, int/*?*/ y) {
  if (x == null) {
    print(y.toDouble());
  } else {
    print(y.toDouble());
  }
}
''';
    var expected = '''
int f(int? x, int? y) {
  if (x == null) {
    print(y!.toDouble());
  } else {
    print(y!.toDouble());
  }
}
''';
    await _checkSingleFileChanges(content, expected, warnOnWeakCode: true);
  }

  Future<void> test_whereNotNull() async {
    var content = '''
Iterable<String> f(Iterable<String/*?*/> it) => it.where((s) => s != null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableNullableExtension;

Iterable<String> f(Iterable<String?> it) => it.whereNotNull();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_whereNotNull_and_firstWhereOrNull() async {
    var content = '''
Iterable<String> f(Iterable<String/*?*/> it) => it.where((s) => s != null);
int g(Iterable<int> it) => it.firstWhere((i) => i != 0, orElse: () => null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableExtension, IterableNullableExtension;

Iterable<String> f(Iterable<String?> it) => it.whereNotNull();
int? g(Iterable<int> it) => it.firstWhereOrNull((i) => i != 0);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_whereNotNull_complexType() async {
    var content = '''
Iterable<Map<String, int>> f(Iterable<Map<String/*?*/, int>/*?*/> it)
    => it.where((m) => m != null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableNullableExtension;

Iterable<Map<String?, int>> f(Iterable<Map<String?, int>?> it)
    => it.whereNotNull();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_whereNotNull_iterable_dynamic() async {
    var content = '''
f(Iterable<dynamic> it) => it.where((s) => s != null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableNullableExtension;

f(Iterable<dynamic> it) => it.whereNotNull();
''';
    await _checkSingleFileChanges(content, expected);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49103')
  Future<void> test_whereNotNull_iterable_U() async {
    var content = '''
f<U>(Iterable<U> it) => it.where((s) => s != null);
''';
    // whereNotNull cannot be used in this case, because its signature is:
    //
    //   extension IterableNullableExtension<T extends Object> on Iterable<T?> {
    //     Iterable<T> whereNotNull() => ...;
    //   }
    //
    // When the type system tries to solve for a substitution T=... that makes
    // the extension apply, it gets T=U, but that doesn't work because U is not
    // a subtype of Object.
    //
    // So the migration tool shouldn't change the `where` to `whereNotNull`.
    var expected = '''
f<U>(Iterable<U> it) => it.where((s) => s != null);
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_whereNotNull_iterable_U_extends_object() async {
    var content = '''
f<U extends Object>(Iterable<U> it) => it.where((s) => s != null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableNullableExtension;

f<U extends Object>(Iterable<U> it) => it.whereNotNull();
''';
    await _checkSingleFileChanges(content, expected);
  }

  Future<void> test_whereNotNull_noContext() async {
    var content = '''
f(Iterable<String/*?*/> it) => it.where((s) => s != null);
''';
    var expected = '''
import 'package:collection/collection.dart' show IterableNullableExtension;

f(Iterable<String?> it) => it.whereNotNull();
''';
    await _checkSingleFileChanges(content, expected);
  }
}

@reflectiveTest
class _ProvisionalApiTestPermissive extends _ProvisionalApiTestBase
    with _ProvisionalApiTestCases {
  @override
  bool get _usePermissiveMode => true;
}

/// Tests of the provisional API, where the driver is reset between calls to
/// `prepareInput` and `processInput`, ensuring that the migration algorithm
/// sees different AST and element objects during different phases.
@reflectiveTest
class _ProvisionalApiTestWithReset extends _ProvisionalApiTestBase
    with _ProvisionalApiTestCases {
  @override
  bool get _usePermissiveMode => false;

  @override
  void _betweenStages() {
    driver!.clearLibraryContext();
  }
}
