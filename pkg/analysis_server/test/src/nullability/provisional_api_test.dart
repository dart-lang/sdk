// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/provisional_api.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProvisionalApiTest);
    defineReflectiveTests(ProvisionalApiTestPermissive);
    defineReflectiveTests(ProvisionalApiTestWithReset);
  });
}

/// Tests of the provisional API.
@reflectiveTest
class ProvisionalApiTest extends ProvisionalApiTestBase
    with ProvisionalApiTestCases {
  @override
  bool get usePermissiveMode => false;
}

/// Base class for provisional API tests.
abstract class ProvisionalApiTestBase extends AbstractContextTest {
  bool get usePermissiveMode;

  /// Hook invoked after calling `prepareInput` on each input.
  void _afterPrepare() {}

  /// Verifies that migration of the files in [input] produces the output in
  /// [expectedOutput].
  Future<void> _checkMultipleFileChanges(
      Map<String, String> input, Map<String, String> expectedOutput,
      {NullabilityMigrationAssumptions assumptions:
          const NullabilityMigrationAssumptions()}) async {
    for (var path in input.keys) {
      newFile(path, content: input[path]);
    }
    var listener = new TestMigrationListener();
    var migration = NullabilityMigration(listener,
        permissive: usePermissiveMode, assumptions: assumptions);
    for (var path in input.keys) {
      migration.prepareInput(await session.getResolvedUnit(path));
    }
    _afterPrepare();
    for (var path in input.keys) {
      migration.processInput(await session.getResolvedUnit(path));
    }
    migration.finish();
    var sourceEdits = <String, List<SourceEdit>>{};
    for (var fix in listener.fixes) {
      var path = fix.source.fullName;
      expect(expectedOutput.keys, contains(path));
      (sourceEdits[path] ??= []).addAll(fix.sourceEdits);
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
    _checkMultipleFileChanges({sourcePath: content}, {sourcePath: expected});
  }
}

/// Mixin containing test cases for the provisional API.
mixin ProvisionalApiTestCases on ProvisionalApiTestBase {
  test_data_flow_generic_inward() async {
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
    _checkSingleFileChanges(content, expected);
  }

  test_data_flow_generic_inward_hint() async {
    var content = '''
class C<T> {
  void f(T? t) {}
}
void g(C<int> c, int i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''';

    // The user may override the behavior shown in test_data_flow_generic_inward
    // by explicitly marking f's use of T as nullable.  Since this makes g's
    // call to f valid regardless of the type of c, c's type will remain
    // C<int>.
    var expected = '''
class C<T> {
  void f(T? t) {}
}
void g(C<int> c, int? i) {
  c.f(i);
}
void test(C<int> c) {
  g(c, null);
}
''';
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_no_default_unused_option2() async {
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_no_default_used_non_null_option2_assume_nullable() async {
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
    _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_with_default_unused_option2() async {
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
    _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_with_default_used_non_null_option2() async {
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
    _checkSingleFileChanges(content, expected);
  }

  test_named_parameter_with_default_used_null_option2() async {
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
    _checkSingleFileChanges(content, expected);
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
    _checkSingleFileChanges(content, expected);
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
    _checkMultipleFileChanges(
        {path1: file1, path2: file2}, {path1: expected1, path2: expected2});
  }
}

@reflectiveTest
class ProvisionalApiTestPermissive extends ProvisionalApiTestBase
    with ProvisionalApiTestCases {
  @override
  bool get usePermissiveMode => true;
}

/// Tests of the provisional API, where the driver is reset between calls to
/// `prepareInput` and `processInput`, ensuring that the migration algorithm
/// sees different AST and element objects during different phases.
@reflectiveTest
class ProvisionalApiTestWithReset extends ProvisionalApiTestBase
    with ProvisionalApiTestCases {
  @override
  bool get usePermissiveMode => false;

  @override
  void _afterPrepare() {
    driver.resetUriResolution();
  }
}

class TestMigrationListener implements NullabilityMigrationListener {
  final fixes = <SingleNullabilityFix>[];

  @override
  void addFix(SingleNullabilityFix fix) {
    fixes.add(fix);
  }
}
