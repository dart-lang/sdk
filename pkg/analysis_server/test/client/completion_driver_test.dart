// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../services/completion/dart/completion_check.dart';
import '../services/completion/dart/completion_printer.dart' as printer;
import '../services/completion/dart/text_expectations.dart';
import 'impl/completion_driver.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BasicCompletionTest1);
    defineReflectiveTests(BasicCompletionTest2);
    defineReflectiveTests(CompletionWithSuggestionsTest1);
    defineReflectiveTests(CompletionWithSuggestionsTest2);
  });
}

typedef SuggestionMatcher = bool Function(CompletionSuggestion suggestion);

abstract class AbstractCompletionDriverTest
    extends PubPackageAnalysisServerTest {
  late CompletionDriver driver;

  late List<CompletionSuggestion> suggestions;

  late CompletionResponseForTesting response;

  /// The configuration used by [assertResponse] to limit the number of
  /// suggestions that will be compared by a test. The reasons for the filter
  /// are
  /// - to prevent uninteresting changes to the SDK from breaking the completion
  ///   tests, and
  /// - to keep the expected response text shorter.
  ///
  /// The default filter, initialized in [setUp], prints
  /// - identifier suggestions consisting of a single letter followed by one or
  ///   more digits,
  /// - identifier suggestions that are in the set of [allowedIdentifiers], and
  /// - non-identifier suggestions.
  ///
  /// Tests can override this configuration to change the set of suggestions to
  /// be printed.
  late printer.Configuration printerConfiguration;

  /// A set of identifiers that will be included in the printed version of the
  /// suggestions. Individual tests can replace the default set.
  Set<String> allowedIdentifiers = const {};

  /// A set of completion kinds that should be included in the printed version
  /// of the suggestions. Individual tests can replace the default set.
  Set<CompletionSuggestionKind> allowedKinds = {};

  /// Return `true` if closures (suggestions starting with a left paren) should
  /// be included in the text to be compared.
  bool get includeClosures => false;

  /// Return `true` if keywords should be included in the text to be compared.
  bool get includeKeywords => true;

  bool get isProtocolVersion1 {
    return protocol == TestingCompletionProtocol.version1;
  }

  // ignore:unreachable_from_main
  bool get isProtocolVersion2 {
    return protocol == TestingCompletionProtocol.version2;
  }

  TestingCompletionProtocol get protocol;

  @override
  Future<List<CompletionSuggestion>> addTestFile(String content,
      {int? offset}) async {
    driver.addTestFile(content, offset: offset);

    // Wait after adding the test file, this might affect diagnostics.
    await pumpEventQueue(times: 1000);

    // For sanity, ensure that there are no errors recorded for project files
    // since that may lead to unexpected results.
    _assertNoErrorsInProjectFiles();

    await getSuggestions();
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

  /// Asserts that the [response] has the [expected] textual dump produced
  /// using [printerConfiguration].
  void assertResponse(String expected, {String where = ''}) {
    final buffer = StringBuffer();
    printer.CompletionResponsePrinter(
      buffer: buffer,
      configuration: printerConfiguration,
      response: response,
    ).writeResponse();
    final actual = buffer.toString();

    if (actual != expected) {
      if (where.isEmpty) {
        var target =
            driver.server.server.completionState.currentRequest?.target;
        if (target != null) {
          var containingNode = target.containingNode.runtimeType;
          var entity = target.entity;
          where = ' (containingNode = $containingNode, entity = $entity)';
        }
      }
      TextExpectationsCollector.add(actual);
      fail('''
The actual suggestions do not match the expected suggestions$where.

To accept the current state change the expectation to

$actual
''');
    }
  }

  void assertSuggestion({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
    String? libraryUri,
  }) {
    expect(
        suggestionWith(
          completion: completion,
          element: element,
          kind: kind,
          file: file,
          libraryUri: libraryUri,
        ),
        isNotNull);
  }

  /// TODO(scheglov) Use it everywhere instead of [addTestFile].
  // ignore:unreachable_from_main
  Future<void> computeSuggestions(
    String content,
  ) async {
    // Give the server time to create analysis contexts.
    await pumpEventQueue(times: 1000);

    await addTestFile(content);

    response = CompletionResponseForTesting(
      requestOffset: driver.completionOffset,
      replacementOffset: driver.replacementOffset,
      replacementLength: driver.replacementLength,
      isIncomplete: false, // TODO(scheglov) not correct
      suggestions: suggestions,
    );
  }

  Future<List<CompletionSuggestion>> getSuggestions() async {
    if (isProtocolVersion1) {
      await waitForSetWithUri('dart:core');
      await waitForSetWithUri('dart:async');
    }

    switch (protocol) {
      case TestingCompletionProtocol.version1:
        suggestions = await driver.getSuggestions();
      case TestingCompletionProtocol.version2:
        suggestions = await driver.getSuggestions2();
    }
    return suggestions;
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    driver = CompletionDriver(
      supportsAvailableSuggestions: isProtocolVersion1,
      server: this,
    );
    await driver.createProject();

    // todo (pq): add logic (possibly to driver) that waits for SDK suggestions

    printerConfiguration = printer.Configuration(
      filter: (suggestion) {
        var kind = suggestion.kind;
        if (kind == CompletionSuggestionKind.IDENTIFIER ||
            kind == CompletionSuggestionKind.INVOCATION) {
          var completion = suggestion.completion;
          if (includeClosures && completion.startsWith('(')) {
            return true;
          }
          var periodIndex = completion.indexOf('.');
          if (periodIndex > 0) {
            completion = completion.substring(0, periodIndex);
          }
          return RegExp(r'^_?[a-zA-Z][0-9]+$').hasMatch(completion) ||
              allowedIdentifiers.contains(completion);
        } else if (kind == CompletionSuggestionKind.KEYWORD) {
          return includeKeywords;
        } else if (allowedKinds.contains(kind)) {
          return true;
        }
        return true;
      },
    );
  }

  SuggestionMatcher suggestionHas({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
    String? libraryUri,
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
        // Library URIs are not available in protocol v1 so skip the check to
        // allow the same test to verify for v2.
        if (!isProtocolVersion1 &&
            libraryUri != null &&
            s.libraryUri != libraryUri) {
          return false;
        }
        return true;
      };

  Iterable<CompletionSuggestion> suggestionsWith({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
    String? libraryUri,
  }) =>
      suggestions.where(suggestionHas(
          completion: completion,
          element: element,
          kind: kind,
          file: file,
          libraryUri: libraryUri));

  CompletionSuggestion suggestionWith({
    required String completion,
    ElementKind? element,
    CompletionSuggestionKind? kind,
    String? file,
    String? libraryUri,
  }) {
    final matches = suggestionsWith(
        completion: completion,
        element: element,
        kind: kind,
        file: file,
        libraryUri: libraryUri);
    expect(matches, hasLength(1));
    return matches.first;
  }

  Future<void> waitForSetWithUri(String uri) {
    return driver.waitForSetWithUri(uri);
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
  /// Duplicates (and potentially replaces) [DeprecatedMemberRelevanceTest].
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

  @FailingTest(reason: 'This test fails with available suggestions')
  @override
  Future<void> test_project_lib_multipleExports() async {
    return super.test_project_lib_multipleExports();
  }

  @FailingTest(
      reason:
          'This test fails with available suggestions because it checks libraryUri')
  @override
  Future<void> test_project_lib_multipleExports_filteredByLocal() async {
    return super.test_project_lib_multipleExports_filteredByLocal();
  }
}

@reflectiveTest
class CompletionWithSuggestionsTest2 extends AbstractCompletionDriverTest
    with CompletionWithSuggestionsTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin CompletionWithSuggestionsTestCases on AbstractCompletionDriverTest {
  Future<void> test_project_filterImports_defaultConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
enum E {
  e,
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

    await addTestFile('''
import 'a.dart';
void f() {
  E v = ^
}
''');
    assertSuggestion(
      completion: 'E.e',
      element: ElementKind.ENUM_CONSTANT,
    );
  }

  /// See: https://github.com/dart-lang/sdk/issues/40620
  Future<void> test_project_filterImports_namedConstructors() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A.a();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
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

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int f = 0;
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void m() {
  ^
}
''');

    assertNoSuggestion(completion: 'f');
  }

  Future<void> test_project_lib_getters_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get g => 0;
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'g');
  }

  /// See: https://github.com/dart-lang/sdk/issues/40626
  Future<void> test_project_lib_getters_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get g => 0;
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo() => 0;
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.foo');
  }

  Future<void> test_project_lib_methods_static() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static void foo() => 0;
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.foo');
  }

  Future<void> test_project_lib_multipleExports() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    // Should be suggested from both libraries.
    assertSuggestion(
        completion: 'A',
        libraryUri: 'package:test/a.dart',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'A',
        libraryUri: 'package:test/b.dart',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_project_lib_multipleExports_filteredByImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

    await addTestFile('''
import 'b.dart';
void f() {
  ^
}
''');

    // Should be only one suggestion, which comes from the import of 'b.dart'.
    assertSuggestion(
      completion: 'A',
      element: ElementKind.CLASS,
      libraryUri: 'package:test/b.dart',
    );
  }

  Future<void> test_project_lib_multipleExports_filteredByLocal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
class A {}
void f() {
  ^
}
''');

    // Should be only one suggestion, which comes from local declaration.
    var suggestion = suggestionWith(
      completion: 'A',
      element: ElementKind.CLASS,
    );
    expect(suggestion, isNotNull);
    expect(suggestion.libraryUri, isNull);
  }

  Future<void> test_project_lib_setters_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set s(int s) {}
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 's');
  }

  Future<void> test_project_lib_setters_static() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static set foo(int _) {}
}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

    await addTestFile('''
void f() {
  ^
}
''');

    assertNoSuggestion(completion: 'A.foo');
  }

  /// See: https://github.com/dart-lang/sdk/issues/40626
  Future<void> test_project_lib_setters_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
set s(int s) {}
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';

class A {
  A.b({O o});
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class O { }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
      await waitForSetWithUri('package:test/b.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
class A { }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

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
    newFile('$testPackageLibPath/a.dart', r'''
mixin M { }
mixin class A { }
''');

    if (isProtocolVersion1) {
      await waitForSetWithUri('package:test/a.dart');
    }

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
