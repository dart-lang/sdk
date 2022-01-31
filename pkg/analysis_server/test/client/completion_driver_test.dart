// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../domain_completion_test.dart';
import '../services/completion/dart/completion_check.dart';
import '../services/completion/dart/completion_contributor_util.dart';
import 'impl/completion_driver.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BasicCompletionTest1);
    defineReflectiveTests(BasicCompletionTest2);
    defineReflectiveTests(CompletionWithSuggestionsTest1);
    defineReflectiveTests(CompletionWithSuggestionsTest2);
  });
}

abstract class AbstractCompletionDriverTest
    extends PubPackageAnalysisServerTest {
  late CompletionDriver driver;
  late List<CompletionSuggestion> suggestions;

  bool get isProtocolVersion2 {
    return protocol == TestingCompletionProtocol.version2;
  }

  TestingCompletionProtocol get protocol;

  AnalysisServerOptions get serverOptions => AnalysisServerOptions();

  bool get supportsAvailableSuggestions;

  Future<void> addProjectFile(String relativePath, String content) async {
    newFile('$testPackageRootPath/$relativePath', content: content);
    // todo (pq): handle more than lib
    expect(relativePath, startsWith('lib/'));
    var packageRelativePath = relativePath.substring(4);
    var uriStr = 'package:test/$packageRelativePath';
    await driver.waitForSetWithUri(uriStr);
  }

  Future<List<CompletionSuggestion>> addTestFile(String content,
      {int? offset}) async {
    driver.addTestFile(content, offset: offset);
    await getSuggestions();
    // For sanity, ensure that there are no errors recorded for project files
    // since that may lead to unexpected results.
    _assertNoErrorsInProjectFiles();
    return suggestions;
  }

  void assertNoSuggestion({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) {
    expect(
        suggestionsWith(
          completion: completion,
          element: element,
          kind: kind,
          file: file,
        ),
        isEmpty);
  }

  void assertSuggestion({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) {
    expect(
        suggestionWith(
          completion: completion,
          element: element,
          kind: kind,
          file: file,
        ),
        isNotNull);
  }

  void assertSuggestions({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) {
    expect(
        suggestionWith(
          completion: completion,
          element: element,
          kind: kind,
          file: file,
        ),
        isNotNull);
  }

  Future<List<CompletionSuggestion>> getSuggestions() async {
    if (supportsAvailableSuggestions) {
      await driver.waitForSetWithUri('dart:core');
      await driver.waitForSetWithUri('dart:async');
    }

    switch (protocol) {
      case TestingCompletionProtocol.version1:
        suggestions = await driver.getSuggestions();
        break;
      case TestingCompletionProtocol.version2:
        suggestions = await driver.getSuggestions2();
        break;
    }
    return suggestions;
  }

  /// TODO(scheglov) Use it everywhere instead of [addTestFile].
  Future<CompletionResponseForTesting> getTestCodeSuggestions(
    String content,
  ) async {
    await addTestFile(content);

    return CompletionResponseForTesting(
      requestOffset: driver.completionOffset,
      replacementOffset: driver.replacementOffset,
      replacementLength: driver.replacementLength,
      isIncomplete: false, // TODO(scheglov) not correct
      suggestions: suggestions,
    );
  }

  /// Display sorted suggestions.
  void printSuggestions() {
    suggestions.sort(completionComparator);
    for (var s in suggestions) {
      print(
          '[${s.relevance}] ${s.completion} • ${s.element?.kind.name ?? ""} ${s.kind.name} ${s.element?.location?.file ?? ""}');
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    driver = CompletionDriver(
      supportsAvailableSuggestions: supportsAvailableSuggestions,
      server: this,
    );
    await driver.createProject();

    // todo (pq): add logic (possibly to driver) that waits for SDK suggestions
  }

  SuggestionMatcher suggestionHas({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) =>
      (CompletionSuggestion s) {
        if (s.completion != completion) {
          return false;
        }
        if (element != null && s.element?.kind != element) {
          return false;
        }
        if (kind != null && s.kind != kind) {
          return false;
        }

        if (file != null && s.element?.location?.file != convertPath(file)) {
          return false;
        }
        return true;
      };

  Iterable<CompletionSuggestion> suggestionsWith({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) =>
      suggestions.where(suggestionHas(
          completion: completion, element: element, kind: kind, file: file));

  CompletionSuggestion suggestionWith({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
  }) {
    final matches = suggestionsWith(
        completion: completion, element: element, kind: kind, file: file);
    expect(matches, hasLength(1));
    return matches.first;
  }

  void _assertNoErrorsInProjectFiles() {
    var errors = <AnalysisError>[];
    driver.filesErrors.forEach((file, fileErrors) {
      // Completion test files are likely to be incomplete and so may have
      // errors
      if (file != convertPath(testFilePath)) {
        errors.addAll(fileErrors);
      }
    });
    expect(errors, isEmpty);
  }
}

@reflectiveTest
class BasicCompletionTest1 extends AbstractCompletionDriverTest
    with BasicCompletionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class BasicCompletionTest2 extends AbstractCompletionDriverTest
    with BasicCompletionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin BasicCompletionTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => false;

  /// Duplicates (and potentially replaces DeprecatedMemberRelevanceTest).
  Future<void> test_deprecated_member_relevance() async {
    await addTestFile('''
class A {
  void a1() { }
  @deprecated
  void a2() { }
}

void f() {
  var a = A();
  a.^
}
''');

    expect(
        suggestionWith(
                completion: 'a2',
                element: ElementKind.METHOD,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance,
        lessThan(suggestionWith(
                completion: 'a1',
                element: ElementKind.METHOD,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance));
  }
}

@reflectiveTest
class CompletionWithSuggestionsTest1 extends AbstractCompletionDriverTest
    with CompletionWithSuggestionsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;

  @failingTest
  @override
  Future<void> test_project_lib_multipleExports() async {
    return super.test_project_lib_multipleExports();
  }
}

@reflectiveTest
class CompletionWithSuggestionsTest2 extends AbstractCompletionDriverTest
    with CompletionWithSuggestionsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;

  @FailingTest(reason: 'Not implemented yet')
  @override
  Future<void> test_project_lib_fields_static() {
    // TODO: implement test_project_lib_fields_static
    return super.test_project_lib_fields_static();
  }

  @FailingTest(reason: 'Not implemented yet')
  @override
  Future<void> test_project_lib_getters_static() {
    // TODO: implement test_project_lib_getters_static
    return super.test_project_lib_getters_static();
  }
}

mixin CompletionWithSuggestionsTestCases on AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  Future<void> test_project_filterImports_defaultConstructor() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
import 'a.dart';
void f() {
  ^
}
''');

    assertSuggestion(
        completion: 'A',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  /// See: https://github.com/dart-lang/sdk/issues/40620
  Future<void> test_project_filterImports_enumValues() async {
    await addProjectFile('lib/a.dart', r'''
enum E {
  e,
}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
import 'a.dart';
void f() {
  ^
}
''');
    assertSuggestion(
      completion: 'E.e',
      element: ElementKind.ENUM_CONSTANT,
    );
  }

  /// See: https://github.com/dart-lang/sdk/issues/40620
  Future<void> test_project_filterImports_namedConstructors() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  A.a();
}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
import 'a.dart';
void f() {
  ^
}
''');

    assertSuggestion(
        completion: 'A.a',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_project_filterMultipleImports() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
import 'a.dart';
import 'b.dart';
void f() {
  ^
}
''');

    assertSuggestion(
      completion: 'A',
      element: ElementKind.CLASS,
    );
  }

  Future<void> test_project_lib() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
enum E {
  e,
}
extension Ex on A {}
mixin M { }
typedef T = Function(Object);
typedef T2 = double;
var v = 0;
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertSuggestion(
        completion: 'A',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
      completion: 'A',
      element: ElementKind.CLASS,
    );
    assertSuggestion(
      completion: 'E',
      element: ElementKind.ENUM,
    );
    assertSuggestion(
      completion: 'Ex',
      element: ElementKind.EXTENSION,
    );
    assertSuggestion(
      completion: 'M',
      element: ElementKind.MIXIN,
    );
    assertSuggestion(
      completion: 'T',
      element: ElementKind.TYPE_ALIAS,
    );
    assertSuggestion(
      completion: 'T2',
      element: ElementKind.TYPE_ALIAS,
    );
    assertSuggestion(
      completion: 'v',
      element: ElementKind.TOP_LEVEL_VARIABLE,
    );
  }

  Future<void> test_project_lib_fields_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  int f = 0;
}
''');

    await addTestFile('''
void m() {
  ^
}
''');

    assertNoSuggestion(completion: 'f');
  }

  Future<void> test_project_lib_fields_static() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  static int f = 0;
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertSuggestion(
      completion: 'A.f',
      element: ElementKind.FIELD,
    );
  }

  Future<void> test_project_lib_getters_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  int get g => 0;
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'g');
  }

  Future<void> test_project_lib_getters_static() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  static int get g => 0;
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertSuggestion(
      completion: 'A.g',
      element: ElementKind.GETTER,
    );
  }

  /// See: https://github.com/dart-lang/sdk/issues/40626
  Future<void> test_project_lib_getters_topLevel() async {
    await addProjectFile('lib/a.dart', r'''
int get g => 0;
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertSuggestion(
      completion: 'g',
      element: ElementKind.GETTER,
    );
  }

  Future<void> test_project_lib_methods_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  void foo() => 0;
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.foo');
  }

  Future<void> test_project_lib_methods_static() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  static void foo() => 0;
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.foo');
  }

  Future<void> test_project_lib_multipleExports() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
void f() {
  ^
}
''');

    // Should only have one suggestion.
    assertSuggestion(
        completion: 'A',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_project_lib_setters_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  set s(int s) {}
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 's');
  }

  Future<void> test_project_lib_setters_static() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  static set g(int g) {}
}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.g');
  }

  /// See: https://github.com/dart-lang/sdk/issues/40626
  Future<void> test_project_lib_setters_topLevel() async {
    await addProjectFile('lib/a.dart', r'''
set s(int s) {}
''');

    await addTestFile('''
void f() {
  ^
}
''');

    assertSuggestion(
      completion: 's',
      element: ElementKind.SETTER,
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/38739')
  Future<void>
      test_project_suggestionRelevance_constructorParameterType() async {
    await addProjectFile('lib/a.dart', r'''
import 'b.dart';

class A {
  A.b({O o});
}
''');

    await addProjectFile('lib/b.dart', r'''
class O { }
''');

    await addTestFile('''
import 'a.dart';

void f(List<String> args) {
  var a = A.b(o: ^)
}
''');

    expect(
        suggestionWith(
                completion: 'O',
                element: ElementKind.CONSTRUCTOR,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance,
        greaterThan(suggestionWith(
                completion: 'args',
                element: ElementKind.PARAMETER,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance));
  }

  Future<void> test_project_suggestionRelevance_constructorsAndTypes() async {
    await addProjectFile('lib/a.dart', r'''
class A { }
''');

    await addTestFile('''
import 'a.dart';

void f(List<String> args) {
  var a = ^
}
''');

    expect(
      suggestionWith(
        completion: 'A',
        element: ElementKind.CONSTRUCTOR,
      ).relevance,
      greaterThan(
        suggestionWith(
          completion: 'A',
          element: ElementKind.CLASS,
        ).relevance,
      ),
    );
  }

  /// See: https://github.com/dart-lang/sdk/issues/35529
  Future<void> test_project_suggestMixins() async {
    await addProjectFile('lib/a.dart', r'''
mixin M { }
class A { }
''');

    await addTestFile('''
class C extends Object with ^
''');

    assertSuggestion(
      completion: 'M',
      element: ElementKind.MIXIN,
    );
    assertSuggestion(
      completion: 'A',
      element: ElementKind.CLASS,
    );
  }

  Future<void> test_sdk_lib_future_isNotDuplicated() async {
    await addTestFile('''
void f() {
  ^
}
''');

    expect(
        suggestionsWith(
            completion: 'Future.value',
            file: '/sdk/lib/async/async.dart',
            element: ElementKind.CONSTRUCTOR,
            kind: CompletionSuggestionKind.INVOCATION),
        hasLength(1));
  }

  Future<void> test_sdk_lib_suggestions() async {
    await addTestFile('''
void f() {
  ^
}
''');

    // A kind-filtered set of SDK suggestions.

    // Constructors should be visible.
    assertSuggestion(
        completion: 'Timer',
        file: '/sdk/lib/async/async.dart',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);

    // But not methods.
    assertNoSuggestion(
        // dart:async (StreamSubscription)
        completion: 'asFuture',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    // +  Functions.
    assertSuggestion(
        completion: 'print',
        file: '/sdk/lib/core/core.dart',
        element: ElementKind.FUNCTION,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'tan',
        file: '/sdk/lib/math/math.dart',
        element: ElementKind.FUNCTION,
        kind: CompletionSuggestionKind.INVOCATION);

    // + Classes.
    assertSuggestion(
      completion: 'HashMap',
      file: '/sdk/lib/collection/collection.dart',
      element: ElementKind.CLASS,
    );

    // + Top level variables.
    assertSuggestion(
      completion: 'pi',
      file: '/sdk/lib/math/math.dart',
      element: ElementKind.TOP_LEVEL_VARIABLE,
    );

    // (No typedefs, enums, extensions defined in the Mock SDK.)
  }
}

enum TestingCompletionProtocol { version1, version2 }
