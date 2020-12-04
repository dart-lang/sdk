// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../services/completion/dart/completion_contributor_util.dart';
import 'impl/completion_driver.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BasicCompletionTest);
    defineReflectiveTests(CompletionWithSuggestionsTest);
  });
}

abstract class AbstractCompletionDriverTest with ResourceProviderMixin {
  CompletionDriver driver;
  Map<String, String> packageRoots;
  List<CompletionSuggestion> suggestions;

  String get projectName => 'project';

  String get projectPath => '/$projectName';

  AnalysisServerOptions get serverOptions => AnalysisServerOptions();

  bool get supportsAvailableSuggestions;

  String get testFilePath => '$projectPath/bin/test.dart';

  Future<void> addProjectFile(String relativePath, String content) async {
    newFile('$projectPath/$relativePath', content: content);
    // todo (pq): handle more than lib
    expect(relativePath, startsWith('lib/'));
    var packageRelativePath = relativePath.substring(4);
    var uriStr = 'package:$projectName/$packageRelativePath';
    await driver.waitForSetWithUri(uriStr);
  }

  Future<List<CompletionSuggestion>> addTestFile(String content,
      {int offset}) async {
    driver.addTestFile(content, offset: offset);
    await getSuggestions();
    // For sanity, ensure that there are no errors recorded for project files
    // since that may lead to unexpected results.
    _assertNoErrorsInProjectFiles();
    return suggestions;
  }

  void assertNoSuggestion({
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
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
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
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
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
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
      // todo (pq): consider moving
      const internalLibs = [
        'dart:async2',
        'dart:_interceptors',
        'dart:_internal',
      ];
      for (var lib in driver.sdk.sdkLibraries) {
        var uri = lib.shortName;
        if (!internalLibs.contains(uri)) {
          await driver.waitForSetWithUri(uri);
        }
      }
    }

    suggestions = await driver.getSuggestions();
    return suggestions;
  }

  /// Display sorted suggestions.
  void printSuggestions() {
    suggestions.sort(completionComparator);
    for (var s in suggestions) {
      print(
          '[${s.relevance}] ${s.completion} • ${s.element?.kind?.name ?? ""} ${s.kind.name} ${s.element?.location?.file ?? ""}');
    }
  }

  @mustCallSuper
  void setUp() {
    driver = CompletionDriver(
      supportsAvailableSuggestions: supportsAvailableSuggestions,
      projectPath: projectPath,
      testFilePath: testFilePath,
      resourceProvider: resourceProvider,
      serverOptions: serverOptions,
    );
    driver.createProject(packageRoots: packageRoots);

    newFile('$projectPath/pubspec.yaml', content: '');
    newFile('$projectPath/.packages', content: '''
project:${toUri('$projectPath/lib')}
''');
    // todo (pq): add logic (possibly to driver) that waits for SDK suggestions
  }

  SuggestionMatcher suggestionHas({
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
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
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
  }) =>
      suggestions.where(suggestionHas(
          completion: completion, element: element, kind: kind, file: file));

  CompletionSuggestion suggestionWith({
    @required String completion,
    ElementKind element,
    CompletionSuggestionKind kind,
    String file,
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
class BasicCompletionTest extends AbstractCompletionDriverTest {
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

void main() {
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
class CompletionWithSuggestionsTest extends AbstractCompletionDriverTest {
  @override
  bool get supportsAvailableSuggestions => true;

  @override
  String get testFilePath => '$projectPath/lib/test.dart';

  Future<void> test_project_filterImports_defaultConstructor() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
import 'a.dart';
void main() {
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
void main() {
  ^
}
''');
    assertSuggestion(
        completion: 'E.e',
        element: ElementKind.ENUM_CONSTANT,
        kind: CompletionSuggestionKind.INVOCATION);
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
void main() {
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
void main() {
  ^
}
''');

    assertSuggestion(
        completion: 'A',
        element: ElementKind.CLASS,
        kind: CompletionSuggestionKind.INVOCATION);
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
var v = 0;
''');

    await addTestFile('''
void main() {
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
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'E',
        element: ElementKind.ENUM,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'Ex',
        element: ElementKind.EXTENSION,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'M',
        element: ElementKind.MIXIN,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'T',
        element: ElementKind.FUNCTION_TYPE_ALIAS,
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'v',
        element: ElementKind.TOP_LEVEL_VARIABLE,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_project_lib_fields_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  int f = 0;
}
''');

    await addTestFile('''
void main() {
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
void main() {
  ^
}
''');

    assertSuggestion(
        completion: 'A.f',
        element: ElementKind.FIELD,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_project_lib_getters_class() async {
    await addProjectFile('lib/a.dart', r'''
class A {
  int get g => 0;
}
''');

    await addTestFile('''
void main() {
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
void main() {
  ^
}
''');

    assertSuggestion(
        completion: 'A.g',
        element: ElementKind.GETTER,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  /// See: https://github.com/dart-lang/sdk/issues/40626
  Future<void> test_project_lib_getters_topLevel() async {
    await addProjectFile('lib/a.dart', r'''
int get g => 0;
''');

    await addTestFile('''
void main() {
  ^
}
''');

    assertSuggestion(
        completion: 'g',
        element: ElementKind.GETTER,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  @failingTest
  Future<void> test_project_lib_multipleExports() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addProjectFile('lib/b.dart', r'''
export 'a.dart';
''');

    await addTestFile('''
void main() {
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
void main() {
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
void main() {
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
void main() {
  ^
}
''');

    assertSuggestion(
        completion: 's',
        element: ElementKind.SETTER,
        kind: CompletionSuggestionKind.INVOCATION);
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

void main(List<String> args) {
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

void main(List<String> args) {
  var a = ^
}
''');

    expect(
        suggestionWith(
                completion: 'A',
                element: ElementKind.CONSTRUCTOR,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance,
        greaterThan(suggestionWith(
                completion: 'A',
                element: ElementKind.CLASS,
                kind: CompletionSuggestionKind.INVOCATION)
            .relevance));
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
        kind: CompletionSuggestionKind.INVOCATION);
    assertSuggestion(
        completion: 'A',
        element: ElementKind.CLASS,
        kind: CompletionSuggestionKind.INVOCATION);
  }

  Future<void> test_sdk_lib_future_isNotDuplicated() async {
    await addTestFile('''
void main() {
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
void main() {
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
        kind: CompletionSuggestionKind.INVOCATION);

    // + Top level variables.
    assertSuggestion(
        completion: 'pi',
        file: '/sdk/lib/math/math.dart',
        element: ElementKind.TOP_LEVEL_VARIABLE,
        kind: CompletionSuggestionKind.INVOCATION);

    // (No typedefs, enums, extensions defined in the Mock SDK.)
  }
}
