// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  Future<void> addTestFile(String content, {int offset}) async {
    driver.addTestFile(content, offset: offset);
    await getSuggestions();
  }

  void expectNoSuggestion({
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

  void expectSuggestion({
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
        resourceProvider: resourceProvider);
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

  void assertNoErrorsInCode() {
    var errors = <AnalysisError>[];
    driver.filesErrors.forEach((_, fileErrors) {
      errors.addAll(fileErrors);
    });
    expect(errors, isEmpty);
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
int v;
''');

    await addTestFile('''
void main() {
  ^
}
''');

    assertNoErrorsInCode();

    expectSuggestion(
        completion: 'A',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'A',
        element: ElementKind.CLASS,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'E',
        element: ElementKind.ENUM,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'Ex',
        element: ElementKind.EXTENSION,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'M',
        element: ElementKind.MIXIN,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'T',
        element: ElementKind.FUNCTION_TYPE_ALIAS,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'v',
        element: ElementKind.TOP_LEVEL_VARIABLE,
        kind: CompletionSuggestionKind.INVOCATION);

    // todo (pq): getters/setters?
  }

  @failingTest
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
    expectSuggestion(
        completion: 'Timer',
        file: '/sdk/lib/async/async.dart',
        element: ElementKind.CONSTRUCTOR,
        kind: CompletionSuggestionKind.INVOCATION);

    // But not methods.
    expectNoSuggestion(
        // dart:async (StreamSubscription)
        completion: 'asFuture',
        element: ElementKind.METHOD,
        kind: CompletionSuggestionKind.INVOCATION);

    // +  Functions.
    expectSuggestion(
        completion: 'print',
        file: '/sdk/lib/core/core.dart',
        element: ElementKind.FUNCTION,
        kind: CompletionSuggestionKind.INVOCATION);
    expectSuggestion(
        completion: 'tan',
        file: '/sdk/lib/math/math.dart',
        element: ElementKind.FUNCTION,
        kind: CompletionSuggestionKind.INVOCATION);

    // + Classes.
    expectSuggestion(
        completion: 'HashMap',
        file: '/sdk/lib/collection/collection.dart',
        element: ElementKind.CLASS,
        kind: CompletionSuggestionKind.INVOCATION);

    // + Top level variables.
    expectSuggestion(
        completion: 'PI',
        file: '/sdk/lib/math/math.dart',
        element: ElementKind.TOP_LEVEL_VARIABLE,
        kind: CompletionSuggestionKind.INVOCATION);

    // (No typedefs, enums, extensions defined in the Mock SDK.)
  }
}
