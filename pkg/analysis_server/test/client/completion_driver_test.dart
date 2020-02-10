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

  Future<List<CompletionSuggestion>> getSuggestions() async {
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

  SuggestionMatcher suggestionHas(
          {@required String completion,
          ElementKind element,
          CompletionSuggestionKind kind}) =>
      (CompletionSuggestion s) {
        if (s.completion == completion) {
          if (element != null && s.element?.kind != element) {
            return false;
          }
          if (kind != null && s.kind != kind) {
            return false;
          }
          return true;
        }
        return false;
      };

  Iterable<CompletionSuggestion> suggestionsWith(
          {@required String completion,
          ElementKind element,
          CompletionSuggestionKind kind}) =>
      suggestions.where(
          suggestionHas(completion: completion, element: element, kind: kind));

  CompletionSuggestion suggestionWith(
      {@required String completion,
      ElementKind element,
      CompletionSuggestionKind kind}) {
    final matches =
        suggestionsWith(completion: completion, element: element, kind: kind);
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

  Future<void> test_basic() async {
    await addProjectFile('lib/a.dart', r'''
class A {}
''');

    await addTestFile('''
void main() {
  ^
}
''');

    var suggestions = suggestionsWith(
        completion: 'A', kind: CompletionSuggestionKind.INVOCATION);
    // todo (pq): seems like this should be 1; investigate duplication.
    expect(suggestions, hasLength(2));
  }

  Future<void> test_sdk_lib_suggestions() async {
    await addTestFile('''
void main() {
  ^
}
''');

    // todo (pq): replace with a "real test"; this just proves we're getting end to end.
    expect(
        // from dart:math
        suggestionWith(
            completion: 'tan', kind: CompletionSuggestionKind.INVOCATION),
        isNotNull);
  }
}
