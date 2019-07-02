// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_context.dart';

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
  bool get _usePermissiveMode;

  /// Hook invoked after calling `prepareInput` on each input.
  void _afterPrepare() {}

  /// Verifies that migration of the files in [input] produces the output in
  /// [expectedOutput].
  Future<void> _checkMultipleFileChanges(
      Map<String, String> input, Map<String, String> expectedOutput) async {
    for (var path in input.keys) {
      newFile(path, content: input[path]);
    }
    var listener = new _TestMigrationListener();
    var migration =
        NullabilityMigration(listener, permissive: _usePermissiveMode);
    for (var path in input.keys) {
      migration.prepareInput(await session.getResolvedUnit(path));
    }
    _afterPrepare();
    for (var path in input.keys) {
      migration.processInput(await session.getResolvedUnit(path));
    }
    migration.finish();
    var sourceEdits = <String, List<SourceEdit>>{};
    for (var entry in listener._edits.entries) {
      var path = entry.key.fullName;
      expect(expectedOutput.keys, contains(path));
      sourceEdits[path] = entry.value;
    }
    for (var path in expectedOutput.keys) {
      var sourceEditsForPath = sourceEdits[path] ?? [];
      sourceEditsForPath.sort((a, b) => b.offset.compareTo(a.offset));
      expect(SourceEdit.applySequence(input[path], sourceEditsForPath),
          expectedOutput[path]);
    }
  }

  /// Verifies that migraiton of the single file with the given [content]
  /// produces the [expected] output.
  Future<void> _checkSingleFileChanges(String content, String expected) async {
    var sourcePath = convertPath('/home/test/lib/test.dart');
    await _checkMultipleFileChanges(
        {sourcePath: content}, {sourcePath: expected});
  }
}

/// Mixin containing test cases for the provisional API.
mixin _ProvisionalApiTestCases on _ProvisionalApiTestBase {
  test_class_alias_synthetic_constructor_with_parameters() async {
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

  test_class_with_default_constructor() async {
    var content = '''
void main() => f(Foo());
f(Foo f) {}
class Foo {}
''';
    var expected = '''
void main() => f(Foo());
f(Foo f) {}
class Foo {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_comment_bang_implies_non_null_intent() async {
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
void f(int/*!*/ i) {}
void g(bool b, int? i) {
  if (b) f(i!);
}
main() {
  g(false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_comment_question_implies_nullable() async {
    var content = '''
void _f() {
  int/*?*/ i = 0;
}
''';
    var expected = '''
void _f() {
  int?/*?*/ i = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

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

  test_conditional_non_null_usage_does_not_imply_non_null_intent() async {
    var content = '''
void f(bool b, int i, int j) {
  if (b) i.gcd(j);
}
void g(bool b, int i, int j) {
  if (b) f(b, i, j);
}
main() {
  g(false, 0, null);
}
''';
    var expected = '''
void f(bool b, int i, int? j) {
  if (b) i.gcd(j!);
}
void g(bool b, int i, int? j) {
  if (b) f(b, i, j);
}
main() {
  g(false, 0, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_conditional_usage_does_not_propagate_non_null_intent() async {
    var content = '''
void f(int i) {
  assert(i != null);
}
void g(bool b, int i) {
  if (b) f(i);
}
void h(bool b1, bool b2, int i) {
  if (b1) g(b2, i);
}
main() {
  h(true, false, null);
}
''';
    var expected = '''
void f(int i) {
  assert(i != null);
}
void g(bool b, int? i) {
  if (b) f(i!);
}
void h(bool b1, bool b2, int? i) {
  if (b1) g(b2, i);
}
main() {
  h(true, false, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_constructorDeclaration_factory_non_null_return() async {
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

  test_constructorDeclaration_factory_simple() async {
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

  test_constructorDeclaration_named() async {
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

  test_constructorDeclaration_namedParameter() async {
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

  test_data_flow_assignment_field() async {
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

  test_data_flow_assignment_field_in_cascade() async {
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

  test_data_flow_assignment_local() async {
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

  test_data_flow_assignment_setter() async {
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

  test_data_flow_field_read() async {
    var content = '''
class C {
  int/*?*/ f = 0;
}
int f(C c) => c.f;
''';
    var expected = '''
class C {
  int?/*?*/ f = 0;
}
int? f(C c) => c.f;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_function_return_type() async {
    var content = '''
int Function() f(int Function() x) => x;
int g() => null;
main() {
  f(g);
}
''';
    var expected = '''
int? Function() f(int? Function() x) => x;
int? g() => null;
main() {
  f(g);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_generic_contravariant_inward() async {
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
    //
    // TODO(paulberry): possible improvement: detect that since C uses T in a
    // contravariant way, and deduce that test should change to
    // `void test(C<int?> c)`
    var expected = '''
class C<T> {
  void f(T t) {}
}
void g(C<int?> c, int? i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_generic_contravariant_inward_function() async {
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

  test_data_flow_generic_contravariant_inward_using_core_class() async {
    var content = '''
void f(List<int> x, int i) {
  x.add(i);
}
void test(List<int> x) {
  f(x, null);
}
''';
    // TODO(paulberry): possible improvement: detect that since add uses T in
    // a contravariant way, and deduce that test should change to
    // `void test(List<int?> x)`
    var expected = '''
void f(List<int?> x, int? i) {
  x.add(i);
}
void test(List<int> x) {
  f(x, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_generic_covariant_outward() async {
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

  test_data_flow_generic_covariant_substituted() async {
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
int? f(C<int?/*?*/> x) => x.getValue();
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_indexed_get_index_value() async {
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

  test_data_flow_indexed_get_value() async {
    var content = '''
class C {
  int operator[](int i) => null;
}
int f(C c) => c[0];
''';
    var expected = '''
class C {
  int? operator[](int i) => null;
}
int? f(C c) => c[0];
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_indexed_set_index_value() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void f(C c) {
  c[null] = 0;
}
''';
    var expected = '''
class C {
  void operator[]=(int? i, int j) {}
}
void f(C c) {
  c[null] = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_indexed_set_index_value_in_cascade() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void f(C c) {
  c..[null] = 0;
}
''';
    var expected = '''
class C {
  void operator[]=(int? i, int j) {}
}
void f(C c) {
  c..[null] = 0;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_indexed_set_value() async {
    var content = '''
class C {
  void operator[]=(int i, int j) {}
}
void f(C c) {
  c[0] = null;
}
''';
    var expected = '''
class C {
  void operator[]=(int i, int? j) {}
}
void f(C c) {
  c[0] = null;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_inward() async {
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

  test_data_flow_inward_missing_type() async {
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

  test_data_flow_local_declaration() async {
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

  test_data_flow_local_reference() async {
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

  test_data_flow_method_call_in_cascade() async {
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

  test_data_flow_outward() async {
    var content = '''
int f(int i) => null;
int g(int i) => f(i);
''';

    var expected = '''
int? f(int i) => null;
int? g(int i) => f(i);
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_data_flow_outward_missing_type() async {
    var content = '''
f(int i) => null; // TODO(danrubel): suggest type
int g(int i) => f(i);
''';

    var expected = '''
f(int i) => null; // TODO(danrubel): suggest type
int? g(int i) => f(i);
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_discard_simple_condition() async {
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
int f(int i) {
  /* if (i == null) {
    return null;
  } else {
    */ return i + 1; /*
  } */
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_field_formal_param_typed() async {
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

  test_field_formal_param_typed_non_nullable() async {
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
  int/*!*/ i;
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

  test_field_formal_param_untyped() async {
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

  test_field_type_inferred() async {
    var content = '''
int f() => null;
class C {
  var x = 1;
  void g() {
    x = f();
  }
}
''';
    // The type of x is inferred from its initializer, so it is non-nullable,
    // even though we try to assign a nullable value to it.  So a null check
    // must be added.
    var expected = '''
int? f() => null;
class C {
  var x = 1;
  void g() {
    x = f()!;
  }
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_function_expression_invocation() async {
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
  int?/*?*/ Function() g();
}
int? test(C c) {
  c.f()(null);
  return c.g()();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_function_expression_invocation_via_getter() async {
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
  int?/*?*/ Function() get g;
}
int? test(C c) {
  c.f(null);
  return c.g();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_generic_function_type_syntax_inferred_dynamic_return() async {
    var content = '''
abstract class C {
  Function() f();
}
Object g(C c) => c.f()();
''';
    var expected = '''
abstract class C {
  Function() f();
}
Object? g(C c) => c.f()();
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_genericType_noTypeArguments() async {
    var content = '''
void f(C c) {}
class C<E> {}
''';
    var expected = '''
void f(C c) {}
class C<E> {}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_genericType_noTypeArguments_use_bound() async {
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

  test_getter_topLevel() async {
    var content = '''
int get g => 0;
''';
    var expected = '''
int get g => 0;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_ifStatement_nullCheck_noElse() async {
    var content = '''
int f(int x) {
  if (x == null) return 0;
  return x;
}
''';
    var expected = '''
int f(int x) {
  if (x == null) return 0;
  return x;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_inferred_method_parameter_type_non_nullable() async {
    var content = '''
class B {
  void f(int i) {
    assert(i != null);
  }
}
class C extends B {
  void f(i) {}
}
void g(C c, int i, bool b) {
  if (b) {
    c.f(i);
  }
}
void h(C c) {
  g(c, null, false);
}
''';
    // B.f's parameter type is `int`.  Since C.f's parameter type is inferred
    // from B.f's, it has a parameter type of `int` too.  Therefore there must
    // be a null check in g().
    var expected = '''
class B {
  void f(int i) {
    assert(i != null);
  }
}
class C extends B {
  void f(i) {}
}
void g(C c, int? i, bool b) {
  if (b) {
    c.f(i!);
  }
}
void h(C c) {
  g(c, null, false);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_inferred_method_parameter_type_nullable() async {
    var content = '''
class B {
  void f(int i) {}
}
class C extends B {
  void f(i) {}
}
void g(C c) {
  c.f(null);
}
''';
    // The call to C.f from g forces C.f's parameter to be nullable.  Since
    // C.f's parameter type is inferred from B.f's parameter type, B.f's
    // parameter must be nullable too.
    var expected = '''
class B {
  void f(int? i) {}
}
class C extends B {
  void f(i) {}
}
void g(C c) {
  c.f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_inferred_method_return_type_non_nullable() async {
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

  test_inferred_method_return_type_nullable() async {
    var content = '''
class B {
  int f() => null;
}
class C extends B {
  f() => 1;
}
int g(C c) => c.f();
''';
    // B.f's return type is `int?`.  Since C.f's return type is inferred from
    // B.f's, it has a return type of `int?` too.  Therefore g's return type
    // must be `int?`.
    var expected = '''
class B {
  int? f() => null;
}
class C extends B {
  f() => 1;
}
int? g(C c) => c.f();
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_instance_creation_generic() async {
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

  test_instanceCreation_noTypeArguments_noParameters() async {
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

  test_localVariable_type_inferred() async {
    var content = '''
int f() => null;
void main() {
  var x = 1;
  x = f();
}
''';
    // The type of x is inferred from its initializer, so it is non-nullable,
    // even though we try to assign a nullable value to it.  So a null check
    // must be added.
    var expected = '''
int? f() => null;
void main() {
  var x = 1;
  x = f()!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_no_default_unused() async {
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

  test_named_parameter_no_default_unused_propagate() async {
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

  test_named_parameter_no_default_unused_required() async {
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
void f({@required String s}) {}
main() {
  f();
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_no_default_used_non_null() async {
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

  test_named_parameter_no_default_used_non_null_propagate() async {
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

  test_named_parameter_no_default_used_null_option2() async {
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

  test_named_parameter_no_default_used_null_required() async {
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
void f({@required String? s}) {}
main() {
  f(s: null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

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

  test_named_parameter_with_null_default_unused_option2() async {
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

  test_non_null_assertion() async {
    var content = '''
int f(int i, [int j]) {
  if (i == 0) return i;
  return i + j;
}
''';

    var expected = '''
int f(int i, [int? j]) {
  if (i == 0) return i;
  return i + j!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_null_aware_getter_invocation() async {
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

  test_null_aware_method_invocation() async {
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

  test_null_aware_setter_invocation_null_target() async {
    var content = '''
class C {
  void set x(int value);
}
int f(C c) => c?.x = 1;
main() {
  f(null);
}
''';
    var expected = '''
class C {
  void set x(int value);
}
int? f(C? c) => c?.x = 1;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_null_aware_setter_invocation_null_value() async {
    var content = '''
class C {
  void set x(int value);
}
int f(C c) => c?.x = 1;
main() {
  f(null);
}
''';
    var expected = '''
class C {
  void set x(int value);
}
int? f(C? c) => c?.x = 1;
main() {
  f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_override_parameter_type_non_nullable() async {
    var content = '''
abstract class Base {
  void f(int i);
}
class Derived extends Base {
  void f(int i) {
    assert(i != null);
  }
}
void g(int i, bool b, Base base) {
  if (b) {
    base.f(i);
  }
}
void h(Base base) {
  g(null, false, base);
}
''';
    var expected = '''
abstract class Base {
  void f(int i);
}
class Derived extends Base {
  void f(int i) {
    assert(i != null);
  }
}
void g(int? i, bool b, Base base) {
  if (b) {
    base.f(i!);
  }
}
void h(Base base) {
  g(null, false, base);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_override_parameter_type_nullable() async {
    var content = '''
abstract class Base {
  void f(int i);
}
class Derived extends Base {
  void f(int i) {}
}
void g(int i, Base base) {
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
void g(int i, Base base) {
  base.f(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_override_return_type_non_nullable() async {
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
  int/*!*/ f();
}
class Derived extends Base {
  int f() => g()!;
}
int? g() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_override_return_type_nullable() async {
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

  test_override_return_type_nullable_substitution_complex() async {
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

  test_override_return_type_nullable_substitution_simple() async {
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

  test_parameter_genericFunctionType() async {
    var content = '''
int f(int x, int Function(int i) g) {
  return g(x);
}
''';
    var expected = '''
int f(int x, int Function(int i) g) {
  return g(x);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_prefixExpression_bang() async {
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

  test_redirecting_constructor_factory() async {
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
  factory C(int? i, int j) = D;
}
class D implements C {
  D(int? i, int j);
}
main() {
  C(null, 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_redirecting_constructor_ordinary() async {
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
  C(int? i, int j) : this.named(j, i);
  C.named(int j, int? i);
}
main() {
  C(null, 1);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_single_file_multiple_changes() async {
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

  test_single_file_single_change() async {
    var content = '''
int f() => null;
''';
    var expected = '''
int? f() => null;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_topLevelFunction_parameterType_implicit_dynamic() async {
    var content = '''
Object f(x) => x;
''';
    var expected = '''
Object? f(x) => x;
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_topLevelFunction_returnType_implicit_dynamic() async {
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

  test_topLevelVariable_type_inferred() async {
    var content = '''
int f() => null;
var x = 1;
void main() {
  x = f();
}
''';
    // The type of x is inferred from its initializer, so it is non-nullable,
    // even though we try to assign a nullable value to it.  So a null check
    // must be added.
    var expected = '''
int? f() => null;
var x = 1;
void main() {
  x = f()!;
}
''';
    await _checkSingleFileChanges(content, expected);
  }

  test_two_files() async {
    var root = '/home/test/lib';
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

  test_type_argument_flows_to_bound() async {
    // The inference of C<int?> forces class C to be declared as
    // C<T extends Object?>.
    var content = '''
class C<T extends Object> {
  void m(T t);
}
class D<T extends Object> {
  void m(T t);
}
f(C<int> c, D<int> d) {
  c.m(null);
}
''';
    var expected = '''
class C<T extends Object?> {
  void m(T t);
}
class D<T extends Object> {
  void m(T t);
}
f(C<int?> c, D<int> d) {
  c.m(null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

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

  test_unconditional_cascaded_indexed_set_implies_non_null_intent() async {
    var content = '''
class C {
  operator[]=(int i, int j) {}
}
void f(C c) {
  c..[1] = 2;
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
  operator[]=(int i, int j) {}
}
void f(C c) {
  c..[1] = 2;
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

  test_unconditional_method_call_implies_non_null_intent() async {
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

  test_unconditional_non_null_usage_implies_non_null_intent() async {
    var content = '''
void f(int i, int j) {
  i.gcd(j);
}
void g(bool b, int i, int j) {
  if (b) f(i, j);
}
main() {
  g(false, 0, null);
}
''';
    var expected = '''
void f(int i, int j) {
  i.gcd(j);
}
void g(bool b, int i, int? j) {
  if (b) f(i, j!);
}
main() {
  g(false, 0, null);
}
''';
    await _checkSingleFileChanges(content, expected);
  }

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

  test_unconditional_usage_propagates_non_null_intent() async {
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
}

@reflectiveTest
class _ProvisionalApiTestPermissive extends _ProvisionalApiTestBase
    with _ProvisionalApiTestCases {
  @override
  bool get _usePermissiveMode => true;

  // TODO(danrubel): Remove this once the superclass test has been fixed.
  // This runs in permissive mode but not when permissive mode is disabled.
  test_instanceCreation_noTypeArguments_noParameters() async {
    super.test_instanceCreation_noTypeArguments_noParameters();
  }
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
  void _afterPrepare() {
    driver.resetUriResolution();
  }
}

class _TestMigrationListener implements NullabilityMigrationListener {
  final _edits = <Source, List<SourceEdit>>{};

  List<String> details = [];

  @override
  void addDetail(String detail) {
    details.add(detail);
  }

  @override
  void addEdit(SingleNullabilityFix fix, SourceEdit edit) {
    (_edits[fix.source] ??= []).add(edit);
  }

  @override
  void addFix(SingleNullabilityFix fix) {}
}
