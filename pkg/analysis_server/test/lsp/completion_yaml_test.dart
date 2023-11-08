// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/pub/pub_api.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:http/http.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../mocks.dart';
import '../utils/test_code_extensions.dart';
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
  late Uri fixDataUri;

  @override
  void setUp() {
    super.setUp();
    fixDataUri = toUri(join(projectFolderPath, 'lib', 'fix_data.yaml'));
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
  /// Sample package name list JSON in the same format as the API:
  /// https://pub.dev/api/package-name-completion-data
  static const samplePackageList = '''
  { "packages": ["one", "two", "three"] }
  ''';

  /// Sample package details JSON in the same format as the API:
  /// https://pub.dev/api/packages/devtools
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

  Future<void> test_nested_afterString() async {
    final content = '''
name: foo
  ^''';

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: [],
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
      expectCompletions: ['sdk: '],
      applyEditsFor: 'sdk: ',
      expectedContent: expected,
    );
  }

  Future<void> test_package_description() async {
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.path.startsWith(PubApi.packageNameListPath)) {
        return Response(samplePackageList, 200);
      } else if (request.url.path.startsWith(PubApi.packageInfoPath)) {
        return Response(samplePackageDetails, 200);
      } else {
        throw UnimplementedError();
      }
    };

    final content = '''
name: foo
version: 1.0.0

dependencies:
  ^''';
    final code = TestCode.parse(content);

    await initialize();
    await openFile(pubspecFileUri, code.code);
    await pumpEventQueue();

    // Descriptions are included in the documentation field that is only added
    // when completions are resolved.
    final completion = await getResolvedCompletion(
      pubspecFileUri,
      code.position.position,
      'one: ',
    );
    expect(
      completion.documentation!.valueEquals('Description of package'),
      isTrue,
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

  Future<void> test_package_versions_fromApi() async {
    httpClient.sendHandler = (BaseRequest request) async {
      if (request.url.path.startsWith(PubApi.packageNameListPath)) {
        return Response(samplePackageList, 200);
      } else if (request.url.path.startsWith(PubApi.packageInfoPath)) {
        return Response(samplePackageDetails, 200);
      } else {
        throw UnimplementedError();
      }
    };

    final content = '''
name: foo
version: 1.0.0

dependencies:
  ^''';
    final code = TestCode.parse(content);

    final expected = '''
name: foo
version: 1.0.0

dependencies:
  one: ^1.2.3''';

    await initialize();
    await openFile(pubspecFileUri, code.code);

    // Versions are currently only available if we've previously resolved on the
    // package name, so first complete/resolve that.
    final newContent = (await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['one: '],
      resolve: true,
      applyEditsFor: 'one: ',
      openCloseFile: false,
    ))!;
    await replaceFile(222, pubspecFileUri, newContent);

    await verifyCompletions(
      pubspecFileUri,
      newContent.replaceFirst(
          'one: ', 'one: ^'), // Insert caret at new location
      expectCompletions: ['^1.2.3'],
      applyEditsFor: '^1.2.3',
      expectedContent: expected,
      openCloseFile: false,
    );
  }

  Future<void> test_package_versions_fromPubOutdated() async {
    final json = r'''
    {
      "packages": [
        {
          "package":    "one",
          "latest":     { "version": "3.2.1" },
          "resolvable": { "version": "1.2.4" }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, json, '');

    final content = '''
name: foo
version: 1.0.0

dependencies:
  one: ^''';
    final code = TestCode.parse(content);

    final expected = '''
name: foo
version: 1.0.0

dependencies:
  one: ^1.2.4''';

    await initialize();
    await openFile(pubspecFileUri, code.code);
    await pumpEventQueue(times: 500);

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['^1.2.4', '^3.2.1'],
      applyEditsFor: '^1.2.4',
      expectedContent: expected,
      openCloseFile: false,
    );
  }

  Future<void> test_package_versions_fromPubOutdated_afterChange() async {
    final initialJson = r'''
    {
      "packages": [
        {
          "package":    "one",
          "latest":     { "version": "3.2.1" },
          "resolvable": { "version": "1.2.3" }
        }
      ]
    }
    ''';
    final updatedJson = r'''
    {
      "packages": [
        {
          "package":    "one",
          "latest":     { "version": "2.1.0" },
          "resolvable": { "version": "2.3.4" }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, initialJson, '');

    final content = '''
name: foo
version: 1.0.0

dependencies:
  one: ^''';
    final code = TestCode.parse(content);

    final expected = '''
name: foo
version: 1.0.0

dependencies:
  one: ^2.3.4''';

    newFile(pubspecFilePath, content);
    await initialize();
    await openFile(pubspecFileUri, code.code);
    await pumpEventQueue(times: 500);

    // Modify the underlying file which should trigger an update of the
    // cached data.
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, updatedJson, '');
    modifyFile(pubspecFilePath, '$content# trailing comment');
    await pumpEventQueue(times: 500);

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: ['^2.3.4', '^2.1.0'],
      applyEditsFor: '^2.3.4',
      expectedContent: expected,
      openCloseFile: false,
    );

    // Also verify the detail fields were populated as expected.
    expect(
      completionResults.singleWhere((c) => c.label == '^2.3.4').detail,
      equals('latest compatible'),
    );
    expect(
      completionResults.singleWhere((c) => c.label == '^2.1.0').detail,
      equals('latest'),
    );
  }

  Future<void> test_package_versions_fromPubOutdated_afterDelete() async {
    final initialJson = r'''
    {
      "packages": [
        {
          "package":    "one",
          "latest":     { "version": "3.2.1" },
          "resolvable": { "version": "1.2.3" }
        }
      ]
    }
    ''';
    processRunner.startHandler =
        (executable, args, {dir, env}) => MockProcess(1, 0, initialJson, '');

    final content = '''
name: foo
version: 1.0.0

dependencies:
  one: ^''';
    final code = TestCode.parse(content);

    newFile(pubspecFilePath, content);
    await initialize();
    await openFile(pubspecFileUri, code.code);
    await pumpEventQueue(times: 500);

    // Delete the underlying file which should trigger eviction of the cache.
    deleteFile(pubspecFilePath);
    await pumpEventQueue(times: 500);

    await verifyCompletions(
      pubspecFileUri,
      content,
      expectCompletions: [],
      openCloseFile: false,
    );

    // There should have been no version numbers.
    expect(completionResults, isEmpty);
  }

  Future<void> test_prefixFilter() async {
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
  on^''';
    final code = TestCode.parse(content);

    await initialize();
    await openFile(pubspecFileUri, content);
    await pumpEventQueue();

    completionResults =
        await getCompletion(pubspecFileUri, code.position.position);
    expect(completionResults.length, equals(1));
    expect(completionResults.single.label, equals('one: '));
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
      expectCompletions: ['name: '],
      applyEditsFor: 'name: ',
      expectedContent: expected,
    );
  }
}
