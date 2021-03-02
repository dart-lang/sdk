// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecCompletionTest);
    defineReflectiveTests(AnalysisOptionsCompletionTest);
    defineReflectiveTests(FixDataCompletionTest);
  });
}

@reflectiveTest
class AnalysisOptionsCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  @override
  void setUp() {
    registerLintRules();
    super.setUp();
  }

  Future<void> test_nested() async {
    final content = '''
linter:
  rules:
    - ^''';

    final expected = '''
linter:
  rules:
    - annotate_overrides''';

    await verifyCompletions(
      analysisOptionsUri,
      content,
      expectCompletions: [
        'always_declare_return_types',
        'annotate_overrides',
      ],
      verifyEditsFor: 'annotate_overrides',
      expectedContent: expected,
    );
  }

  Future<void> test_nested_prefix() async {
    final content = '''
linter:
  rules:
    - ann^''';

    final expected = '''
linter:
  rules:
    - annotate_overrides''';

    await verifyCompletions(
      analysisOptionsUri,
      content,
      expectCompletions: ['annotate_overrides'],
      verifyEditsFor: 'annotate_overrides',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel() async {
    final content = '''
^''';
    final expected = '''
linter: ''';

    await verifyCompletions(
      analysisOptionsUri,
      content,
      expectCompletions: ['linter: '],
      verifyEditsFor: 'linter: ',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel_prefix() async {
    final content = '''
li^''';
    final expected = '''
linter: ''';

    await verifyCompletions(
      analysisOptionsUri,
      content,
      expectCompletions: ['linter: '],
      verifyEditsFor: 'linter: ',
      expectedContent: expected,
    );
  }
}

@reflectiveTest
class FixDataCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  Uri fixDataUri;

  @override
  void setUp() {
    super.setUp();
    fixDataUri = Uri.file(join(projectFolderPath, 'lib', 'fix_data.yaml'));
  }

  Future<void> test_nested() async {
    final content = '''
version: 1.0.0
transforms:
  - changes:
    - ^''';
    final expected = '''
version: 1.0.0
transforms:
  - changes:
    - kind: ''';

    await verifyCompletions(
      fixDataUri,
      content,
      expectCompletions: ['kind: '],
      verifyEditsFor: 'kind: ',
      expectedContent: expected,
    );
  }

  Future<void> test_nested_prefix() async {
    final content = '''
version: 1.0.0
transforms:
  - changes:
    - ki^''';
    final expected = '''
version: 1.0.0
transforms:
  - changes:
    - kind: ''';

    await verifyCompletions(
      fixDataUri,
      content,
      expectCompletions: ['kind: '],
      verifyEditsFor: 'kind: ',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel() async {
    final content = '''
version: 1.0.0
^''';
    final expected = '''
version: 1.0.0
transforms:''';

    await verifyCompletions(
      fixDataUri,
      content,
      expectCompletions: ['transforms:'],
      verifyEditsFor: 'transforms:',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel_prefix() async {
    final content = '''
tra^''';
    final expected = '''
transforms:''';

    await verifyCompletions(
      fixDataUri,
      content,
      expectCompletions: ['transforms:'],
      verifyEditsFor: 'transforms:',
      expectedContent: expected,
    );
  }
}

@reflectiveTest
class PubspecCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  Future<void> test_insertReplaceRanges() async {
    final content = '''
name: foo
version: 1.0.0

environment:
  s^dk
''';
    final expectedReplaced = '''
name: foo
version: 1.0.0

environment:
  sdk: 
''';
    final expectedInserted = '''
name: foo
version: 1.0.0

environment:
  sdk: dk
''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['sdk: '],
      verifyEditsFor: 'sdk: ',
      verifyInsertReplaceRanges: true,
      expectedContent: expectedReplaced,
      expectedContentIfInserting: expectedInserted,
    );
  }

  Future<void> test_nested() async {
    final content = '''
name: foo
version: 1.0.0

environment:
  ^''';

    final expected = '''
name: foo
version: 1.0.0

environment:
  sdk: ''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['flutter: ', 'sdk: '],
      verifyEditsFor: 'sdk: ',
      expectedContent: expected,
    );
  }

  Future<void> test_nested_prefix() async {
    final content = '''
name: foo
version: 1.0.0

environment:
  sd^''';

    final expected = '''
name: foo
version: 1.0.0

environment:
  sdk: ''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['flutter: ', 'sdk: '],
      verifyEditsFor: 'sdk: ',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel() async {
    final content = '''
version: 1.0.0
^''';
    final expected = '''
version: 1.0.0
name: ''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['name: ', 'description: '],
      verifyEditsFor: 'name: ',
      expectedContent: expected,
    );
  }

  Future<void> test_topLevel_prefix() async {
    final content = '''
na^''';
    final expected = '''
name: ''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['name: ', 'description: '],
      verifyEditsFor: 'name: ',
      expectedContent: expected,
    );
  }
}
