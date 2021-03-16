// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:http/http.dart';
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
      applyEditsFor: 'annotate_overrides',
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
      applyEditsFor: 'annotate_overrides',
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
      applyEditsFor: 'linter: ',
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
      applyEditsFor: 'linter: ',
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
      applyEditsFor: 'kind: ',
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
      applyEditsFor: 'kind: ',
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
      applyEditsFor: 'transforms:',
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
      applyEditsFor: 'transforms:',
      expectedContent: expected,
    );
  }
}

@reflectiveTest
class PubspecCompletionTest extends AbstractLspAnalysisServerTest
    with CompletionTestMixin {
  static const samplePackageList = '''
  { "packages": ["one", "two", "three"] }
  ''';

  static const samplePackageDetails = '''
  {
    "name":"package",
    "latest":{
      "version":"1.2.3",
      "pubspec":{
        "description":"Description of package"
      }
    }
  }
  ''';

  @override
  void setUp() {
    super.setUp();
    // Cause retries to run immediately.
    PubApi.failedRetryInitialDelaySeconds = 0;
  }

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
      applyEditsFor: 'sdk: ',
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
      applyEditsFor: 'sdk: ',
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
      applyEditsFor: 'sdk: ',
      expectedContent: expected,
    );
  }

  Future<void> test_package_names() async {
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.toString().endsWith(PubApi.packageNameListPath)) {
        return Response(samplePackageList, 200);
      } else {
        throw UnimplementedError();
      }
    };

    final content = '''
name: foo
version: 1.0.0

dependencies:
  ^''';

    final expected = '''
name: foo
version: 1.0.0

dependencies:
  one: ''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['one: ', 'two: ', 'three: '],
      applyEditsFor: 'one: ',
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
      applyEditsFor: 'name: ',
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
      applyEditsFor: 'name: ',
      expectedContent: expected,
    );
  }
}
