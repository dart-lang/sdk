// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/rules/pub/sort_pub_dependencies.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortPubDependenciesTest);
  });
}

@reflectiveTest
class SortPubDependenciesTest with ResourceProviderMixin {
  /// The content of the pubspec file that is being tested.
  late String content;

  /// The result of parsing the [content].
  late YamlNode node;

  /// The diagnostic to be fixed.
  late Diagnostic diagnostic;

  FixKind get kind => PubspecFixKind.sortDependencies;

  Future<void> assertHasFix(String initialContent, String expected) async {
    _validate(initialContent);
    expected = normalizeNewlinesForPlatform(expected);

    var fixes = await _getFixes();
    expect(fixes, hasLength(1));
    var fix = fixes[0];
    expect(fix.kind, kind);
    var edits = fix.change.edits;
    expect(edits, hasLength(1));
    var actual = _applyEdits(content, edits[0].edits);
    expect(actual, expected);
  }

  Future<void> assertNoFix(String initialContent) async {
    _validate(initialContent);
    var fixes = await _getFixes();
    expect(fixes, isEmpty);
  }

  Future<void> test_sortDependencies_alreadySorted() async {
    // When dependencies are already sorted, the lint should not trigger.
    var initialContent = '''
name: test
dependencies:
  aaa: ^1.0.0
  bbb: ^2.0.0
  ccc: ^3.0.0
''';
    initialContent = normalizeNewlinesForPlatform(initialContent);
    content = initialContent;
    var pubspecFile = newFile('/home/test/pubspec.yaml', content);
    node = loadYamlNode(content);

    var errors = validatePubspec(
      source: FileSource(pubspecFile),
      contents: node,
      provider: resourceProvider,
      analysisOptions: _createAnalysisOptions(),
    );
    // No lint error should be reported for sorted dependencies.
    expect(errors.where((e) => e.diagnosticCode.name == 'sort_pub_dependencies'), isEmpty);
  }

  Future<void> test_sortDependencies_simple() async {
    await assertHasFix(
      '''
name: test
dependencies:
  ccc: ^3.0.0
  aaa: ^1.0.0
  bbb: ^2.0.0
''',
      '''
name: test
dependencies:
  aaa: ^1.0.0
  bbb: ^2.0.0
  ccc: ^3.0.0
''',
    );
  }

  Future<void> test_sortDependencies_twoUnsorted() async {
    await assertHasFix(
      '''
name: test
dependencies:
  bbb: ^2.0.0
  aaa: ^1.0.0
''',
      '''
name: test
dependencies:
  aaa: ^1.0.0
  bbb: ^2.0.0
''',
    );
  }

  Future<void> test_sortDevDependencies() async {
    await assertHasFix(
      '''
name: test
dev_dependencies:
  zzz: ^1.0.0
  aaa: ^2.0.0
''',
      '''
name: test
dev_dependencies:
  aaa: ^2.0.0
  zzz: ^1.0.0
''',
    );
  }

  Future<void> test_sortDependencyOverrides() async {
    await assertHasFix(
      '''
name: test
dependency_overrides:
  xyz: ^1.0.0
  abc: ^2.0.0
''',
      '''
name: test
dependency_overrides:
  abc: ^2.0.0
  xyz: ^1.0.0
''',
    );
  }

  String _applyEdits(String content, List<dynamic> edits) {
    // Apply edits in reverse order to preserve offsets.
    var sortedEdits = List.from(edits)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    var result = content;
    for (var edit in sortedEdits) {
      result = result.substring(0, edit.offset) +
          edit.replacement +
          result.substring(edit.offset + edit.length);
    }
    return result;
  }

  AnalysisOptions _createAnalysisOptions() {
    // Register linter rules if not already registered.
    registerLintRules();
    return _TestAnalysisOptions(
      lintRules: [SortPubDependencies()],
    );
  }

  Future<List<Fix>> _getFixes() async {
    var generator = PubspecFixGenerator(
      resourceProvider,
      diagnostic,
      content,
      node,
      defaultEol: testEol,
    );
    return await generator.computeFixes();
  }

  void _validate(String initialContent) {
    content = normalizeNewlinesForPlatform(initialContent);
    var pubspecFile = newFile('/home/test/pubspec.yaml', content);
    node = loadYamlNode(content);

    var errors = validatePubspec(
      source: FileSource(pubspecFile),
      contents: node,
      provider: resourceProvider,
      analysisOptions: _createAnalysisOptions(),
    );

    // Find the sort_pub_dependencies error.
    var sortErrors = errors
        .where((e) => e.diagnosticCode.name == 'sort_pub_dependencies')
        .toList();
    expect(sortErrors, hasLength(1), reason: 'Expected exactly one sort_pub_dependencies error');
    diagnostic = sortErrors.first;
  }
}

/// A minimal test implementation of AnalysisOptions for testing lint rules.
class _TestAnalysisOptions implements AnalysisOptions {
  @override
  final List<dynamic> lintRules;

  _TestAnalysisOptions({required this.lintRules});

  @override
  bool get lint => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
