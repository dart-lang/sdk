// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_utilities/check/check.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'domain_completion_util.dart';
import 'mocks.dart';
import 'services/completion/dart/completion_check.dart';
import 'src/plugin/plugin_manager_test.dart';
import 'utils/change_check.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionDetails2Test);
    defineReflectiveTests(CompletionDomainHandlerGetSuggestions2Test);
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionsTest);
  });
}

/// TODO(scheglov) this is duplicate
class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final bool implicitDynamic;
  final List<String> lints;
  final bool strictCasts;
  final bool strictInference;
  final bool strictRawTypes;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.implicitCasts = true,
    this.implicitDynamic = true,
    this.lints = const [],
    this.strictCasts = false,
    this.strictInference = false,
    this.strictRawTypes = false,
  });

  String toContent() {
    var buffer = StringBuffer();

    buffer.writeln('analyzer:');
    buffer.writeln('  enable-experiment:');
    for (var experiment in experiments) {
      buffer.writeln('    - $experiment');
    }
    buffer.writeln('  language:');
    buffer.writeln('    strict-casts: $strictCasts');
    buffer.writeln('    strict-inference: $strictInference');
    buffer.writeln('    strict-raw-types: $strictRawTypes');
    buffer.writeln('  strong-mode:');
    buffer.writeln('    implicit-casts: $implicitCasts');
    buffer.writeln('    implicit-dynamic: $implicitDynamic');

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestionDetails2Test
    extends PubPackageAnalysisServerTest {
  Future<void> test_alreadyImported() async {
    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
import 'dart:math';
void f() {
  Rand^
}
''', completion: 'Random', libraryUri: 'dart:math');
    check(details)
      ..completion.isEqualTo('Random')
      ..change.edits.isEmpty;
  }

  Future<void> test_import_dart() async {
    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
void f() {
  R^
}
''', completion: 'Random', libraryUri: 'dart:math');
    check(details)
      ..completion.isEqualTo('Random')
      ..change
          .hasFileEdit(testFilePathPlatform)
          .appliedTo(testFileContent)
          .isEqualTo(r'''
import 'dart:math';

void f() {
  R
}
''');
  }

  Future<void> test_import_package_dependencies() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
dependencies:
  aaa: any
''');

    var aaaRoot = getFolder('$workspaceRootPath/packages/aaa');
    newFile('${aaaRoot.path}/lib/f.dart', content: '''
class Test {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path),
    );

    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
void f() {
  T^
}
''', completion: 'Test', libraryUri: 'package:aaa/a.dart');
    check(details)
      ..completion.isEqualTo('Test')
      ..change
          .hasFileEdit(testFilePathPlatform)
          .appliedTo(testFileContent)
          .isEqualTo(r'''
import 'package:aaa/a.dart';

void f() {
  T
}
''');
  }

  Future<void> test_import_package_this() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class Test {}
''');

    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
void f() {
  T^
}
''', completion: 'Test', libraryUri: 'package:test/a.dart');
    check(details)
      ..completion.isEqualTo('Test')
      ..change
          .hasFileEdit(testFilePathPlatform)
          .appliedTo(testFileContent)
          .isEqualTo(r'''
import 'package:test/a.dart';

void f() {
  T
}
''');
  }

  Future<void> test_invalidLibraryUri() async {
    await _configureWithWorkspaceRoot();

    var request = CompletionGetSuggestionDetails2Params(
            testFilePathPlatform, 0, 'Random', '[foo]:bar')
        .toRequest('0');

    var response = await handleRequest(request);
    expect(response.error?.code, RequestErrorCode.INVALID_PARAMETER);
    // TODO(scheglov) Check that says "libraryUri".
  }

  Future<void> test_invalidPath() async {
    await _configureWithWorkspaceRoot();

    var request =
        CompletionGetSuggestionDetails2Params('foo', 0, 'Random', 'dart:math')
            .toRequest('0');

    var response = await handleRequest(request);
    expect(response.error?.code, RequestErrorCode.INVALID_FILE_PATH_FORMAT);
  }

  Future<CompletionGetSuggestionDetails2Result> _getCodeDetails({
    required String path,
    required String content,
    required String completion,
    required String libraryUri,
  }) async {
    var completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    newFile(path,
        content: content.substring(0, completionOffset) +
            content.substring(completionOffset + 1));

    return await _getDetails(
      path: path,
      completionOffset: completionOffset,
      completion: completion,
      libraryUri: libraryUri,
    );
  }

  Future<CompletionGetSuggestionDetails2Result> _getDetails({
    required String path,
    required int completionOffset,
    required String completion,
    required String libraryUri,
  }) async {
    var request = CompletionGetSuggestionDetails2Params(
      path,
      completionOffset,
      completion,
      libraryUri,
    ).toRequest('0');

    var response = await _handleSuccessfulRequest(request);
    return CompletionGetSuggestionDetails2Result.fromResponse(response);
  }

  Future<CompletionGetSuggestionDetails2Result> _getTestCodeDetails(
    String content, {
    required String completion,
    required String libraryUri,
  }) async {
    return _getCodeDetails(
      path: convertPath(testFilePath),
      content: content,
      completion: completion,
      libraryUri: libraryUri,
    );
  }
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestions2Test
    extends PubPackageAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    completionDomain.budgetDuration = const Duration(seconds: 30);
  }

  Future<void> test_abort_onAnotherCompletionRequest() async {
    var abortedIdSet = <String>{};
    server.discardedRequests.stream.listen((request) {
      abortedIdSet.add(request.id);
    });

    newFile(testFilePath, content: '');

    await _configureWithWorkspaceRoot();

    // Send three requests, the first two should be aborted.
    var request0 = _sendTestCompletionRequest('0', 0);
    var request1 = _sendTestCompletionRequest('1', 0);
    var request2 = _sendTestCompletionRequest('2', 0);

    // Wait for all three.
    var response0 = await request0.toResponse();
    var response1 = await request1.toResponse();
    var response2 = await request2.toResponse();

    // The first two should be aborted.
    expect(abortedIdSet, {'0', '1'});

    check(response0)
      ..assertIncomplete()
      ..suggestions.isEmpty;

    check(response1)
      ..assertIncomplete()
      ..suggestions.isEmpty;

    check(response2)
      ..assertComplete()
      ..suggestions.containsMatch(
        (suggestion) => suggestion.completion.isEqualTo('int'),
      );
  }

  Future<void> test_abort_onUpdateContent() async {
    var abortedIdSet = <String>{};
    server.discardedRequests.stream.listen((request) {
      abortedIdSet.add(request.id);
    });

    newFile(testFilePath, content: '');

    await _configureWithWorkspaceRoot();

    // Schedule a completion request.
    var request = _sendTestCompletionRequest('0', 0);

    // Simulate typing in the IDE.
    await _handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFilePathPlatform: AddContentOverlay('void f() {}'),
      }).toRequest('1'),
    );

    // The request should be aborted.
    var response = await request.toResponse();
    expect(abortedIdSet, {'0'});

    check(response)
      ..assertIncomplete()
      ..suggestions.isEmpty;
  }

  Future<void> test_isNotImportedFeature_prefixed_classInstanceMethod() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  void foo01() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
import 'a.dart';

class B extends A {
  void foo02() {}
}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f(B b) {
  b.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // The fact that `b.dart` is imported, and `a.dart` is not, does not affect
    // the order of suggestions added with an expression prefix. We are not
    // going to import anything, so this does not matter.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
    ]);
  }

  Future<void> test_notImported_dart() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  Rand^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('Random')
        ..libraryUriToImport.isEqualTo('dart:math'),
    ]);
  }

  Future<void> test_notImported_emptyBudget() async {
    await _configureWithWorkspaceRoot();

    // Empty budget, so no not yet imported libraries.
    completionDomain.budgetDuration = const Duration(milliseconds: 0);

    var response = await _getTestCodeSuggestions('''
void f() {
  Rand^
}
''');

    check(response)
      ..assertIncomplete()
      ..hasReplacement(left: 4)
      ..suggestions.withElementClass.isEmpty;
  }

  Future<void> test_notImported_lowerRelevance_enumConstant() async {
    newFile('$testPackageLibPath/a.dart', content: '''
enum E1 {
  foo01
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
enum E2 {
  foo02
}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('E2.foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('E1.foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_extension_getter() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  int get foo01 => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
extension E2 on int {
  int get foo02 => 0;
}
''');

    var response = await _getTestCodeSuggestions(r'''
import 'b.dart';
 
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_extension_method() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  void foo01() {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
extension E2 on int {
  void foo02() {}
}
''');

    var response = await _getTestCodeSuggestions(r'''
import 'b.dart';
 
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_extension_setter() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  set foo01(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
extension E2 on int {
  set foo02(int _) {}
}
''');

    var response = await _getTestCodeSuggestions(r'''
import 'b.dart';
 
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_topLevel_class() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    // `A01` relevance is decreased because it is not yet imported.
    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_topLevel_getter() async {
    newFile('$testPackageLibPath/a.dart', content: '''
int get foo01 => 0;
''');

    newFile('$testPackageLibPath/b.dart', content: '''
int get foo02 => 0;
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_topLevel_setter() async {
    newFile('$testPackageLibPath/a.dart', content: '''
set foo01(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
set foo02(int _) {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_lowerRelevance_topLevel_variable() async {
    newFile('$testPackageLibPath/a.dart', content: '''
var foo01 = 0;
''');

    newFile('$testPackageLibPath/b.dart', content: '''
var foo02 = 0;
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo01` relevance is decreased because it is not yet imported.
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_pub_dependencies_inLib() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
dependencies:
  aaa: any
dev_dependencies:
  bbb: any
''');

    var aaaRoot = getFolder('$workspaceRootPath/packages/aaa');
    newFile('${aaaRoot.path}/lib/f.dart', content: '''
class A01 {}
''');
    newFile('${aaaRoot.path}/lib/src/f.dart', content: '''
class A02 {}
''');

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', content: '''
class A03 {}
''');
    newFile('${bbbRoot.path}/lib/src/f.dart', content: '''
class A04 {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path)
        ..add(name: 'bbb', rootPath: bbbRoot.path),
    );

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:aaa/f.dart'),
    ]);
  }

  Future<void> test_notImported_pub_dependencies_inTest() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
dependencies:
  aaa: any
dev_dependencies:
  bbb: any
''');

    var aaaRoot = getFolder('$workspaceRootPath/packages/aaa');
    newFile('${aaaRoot.path}/lib/f.dart', content: '''
class A01 {}
''');
    newFile('${aaaRoot.path}/lib/src/f.dart', content: '''
class A02 {}
''');

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', content: '''
class A03 {}
''');
    newFile('${bbbRoot.path}/lib/src/f.dart', content: '''
class A04 {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path)
        ..add(name: 'bbb', rootPath: bbbRoot.path),
    );

    await _configureWithWorkspaceRoot();

    var test_path = convertPath('$testPackageTestPath/test.dart');
    var response = await _getCodeSuggestions(
      path: test_path,
      content: '''
void f() {
  A0^
}
''',
    );

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:aaa/f.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A03')
        ..libraryUriToImport.isEqualTo('package:bbb/f.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isEqualTo('package:test/b.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this_hasImport() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
class A02 {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class A03 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'a.dart';

void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('A03')
        ..libraryUriToImport.isEqualTo('package:test/b.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this_hasImport_hasShow() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
class A02 {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class A03 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'a.dart' show A02;

void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    // Note:
    // 1. A02 is the first, because it is already imported.
    // 2. A01 is still suggested, but with lower relevance.
    // 3. A03 has the same relevance (not tested), but sorted by name.
    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A03')
        ..libraryUriToImport.isEqualTo('package:test/b.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this_inLib_excludesTest() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
''');

    newFile('$testPackageTestPath/b.dart', content: '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this_inLib_includesThisSrc() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/f.dart', content: '''
class A01 {}
''');

    newFile('$testPackageLibPath/src/f.dart', content: '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/f.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isEqualTo('package:test/src/f.dart'),
    ]);
  }

  Future<void> test_notImported_pub_this_inTest_includesTest() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
''');

    var b = newFile('$testPackageTestPath/b.dart', content: '''
class A02 {}
''');
    var b_uriStr = toUriStr(b.path);

    await _configureWithWorkspaceRoot();

    var test_path = convertPath('$testPackageTestPath/test.dart');
    var response = await _getCodeSuggestions(
      path: test_path,
      content: '''
void f() {
  A0^
}
''',
    );

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isEqualTo(b_uriStr),
    ]);
  }

  Future<void> test_notImported_pub_this_inTest_includesThisSrc() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/f.dart', content: '''
class A01 {}
''');

    newFile('$testPackageLibPath/src/f.dart', content: '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var test_path = convertPath('$testPackageTestPath/test.dart');
    var response = await _getCodeSuggestions(
      path: test_path,
      content: '''
void f() {
  A0^
}
''',
    );

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..libraryUriToImport.isEqualTo('package:test/f.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..libraryUriToImport.isEqualTo('package:test/src/f.dart'),
    ]);
  }

  Future<void> test_numResults_class_methods() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
  void foo03() {}
}

void f(A a) {
  a.foo0^
}
''', maxResults: 2);

    check(response)
      ..assertIncomplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isMethodInvocation,
    ]);
  }

  Future<void> test_numResults_topLevelVariables() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
var foo01 = 0;
var foo02 = 0;
var foo03 = 0;

void f() {
  foo0^
}
''', maxResults: 2);

    check(response)
      ..assertIncomplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isTopLevelVariable,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isTopLevelVariable,
    ]);
  }

  Future<void> test_numResults_topLevelVariables_imported_withPrefix() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
var foo01 = 0;
var foo02 = 0;
var foo03 = 0;
''');

    var response = await _getTestCodeSuggestions('''
import 'a.dart' as prefix;

void f() {
  prefix.^
}
''', maxResults: 2);

    check(response)
      ..assertIncomplete()
      ..hasEmptyReplacement();

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isTopLevelVariable,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isTopLevelVariable,
    ]);
  }

  Future<void> test_prefixed_class_constructors() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
class A {
  A.foo01();
  A.foo02();
}

void f() {
  A.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isConstructorInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isConstructorInvocation,
    ]);
  }

  Future<void> test_prefixed_class_getters() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
class A {
  int get foo01 => 0;
  int get foo02 => 0;
}

void f(A a) {
  a.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter
        ..libraryUri.isNull
        ..isNotImported.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isGetter
        ..libraryUri.isNull
        ..isNotImported.isNull,
    ]);
  }

  Future<void> test_prefixed_class_methods_instance() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
class A {
  void foo01() {}
  void foo02() {}
}

void f(A a) {
  a.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isMethodInvocation,
    ]);
  }

  Future<void> test_prefixed_class_methods_static() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
class A {
  static void foo01() {}
  static void foo02() {}
}

void f() {
  A.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isMethodInvocation,
    ]);
  }

  Future<void> test_prefixed_expression_extensionGetters() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
extension E1 on int {
  int get foo01 => 0;
  int get foo02 => 0;
  int get bar => 0;
}

extension E2 on double {
  int get foo03 => 0;
}

void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isGetter,
    ]);
  }

  Future<void> test_prefixed_expression_extensionGetters_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  int get foo01 => 0;
  int get bar => 0;
}

extension E2 on int {
  int get foo02 => 0;
}

extension E3 on double {
  int get foo03 => 0;
}
''');

    var response = await _getTestCodeSuggestions(r'''
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isGetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void>
      test_prefixed_expression_extensionGetters_notImported_private() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  int get foo01 => 0;
}

extension _E2 on int {
  int get foo02 => 0;
}

extension on int {
  int get foo03 => 0;
}
''');

    var response = await _getTestCodeSuggestions(r'''
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_prefixed_expression_extensionMethods() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
extension E1 on int {
  void foo01() {}
  void foo02() {}
  void bar() {}
}

extension E2 on double {
  void foo03() {}
}

void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isMethodInvocation,
    ]);
  }

  Future<void> test_prefixed_expression_extensionMethods_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  void foo01() {}
  void bar() {}
}

extension E2 on int {
  void foo02() {}
}

extension E3 on double {
  void foo03() {}
}
''');

    var response = await _getTestCodeSuggestions(r'''
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isMethodInvocation
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_prefixed_expression_extensionSetters() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
extension E1 on int {
  set foo01(int _) {}
  set foo02(int _) {}
  set bar(int _) {}
}

extension E2 on double {
  set foo03(int _) {}
}

void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isSetter,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isSetter,
    ]);
  }

  Future<void> test_prefixed_expression_extensionSetters_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  set foo01(int _) {}
  set bar(int _) {}
}

extension E2 on int {
  set foo02(int _) {}
}

extension E3 on double {
  set foo03(int _) {}
}
''');

    var response = await _getTestCodeSuggestions(r'''
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isSetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isSetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void>
      test_prefixed_expression_extensionSetters_notImported_private() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  set foo01(int _) {}
}

extension _E2 on int {
  set foo02(int _) {}
}

extension on int {
  set foo03(int _) {}
}
''');

    var response = await _getTestCodeSuggestions(r'''
void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isSetter
        ..libraryUriToImport.isEqualTo('package:test/a.dart'),
    ]);
  }

  Future<void> test_prefixed_extensionGetters_imported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
extension E1 on int {
  int get foo01 => 0;
  int get foo02 => 0;
  int get bar => 0;
}

extension E2 on double {
  int get foo03 => 0;
}
''');

    var response = await _getTestCodeSuggestions(r'''
import 'a.dart';

void f() {
  0.foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isGetter,
    ]);
  }

  Future<void> test_prefixed_extensionOverride_extensionGetters() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
extension E1 on int {
  int get foo01 => 0;
}

extension E2 on int {
  int get foo02 => 0;
}

void f() {
  E1(0).foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isGetter,
    ]);
  }

  Future<void> test_prefixed_extensionOverride_extensionMethods() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
extension E1 on int {
  void foo01() {}
}

extension E2 on int {
  void foo01() {}
}

void f() {
  E1(0).foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isMethodInvocation,
    ]);
  }

  Future<void> test_prefixed_importPrefix_class() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'dart:math' as math;

void f() {
  math.Rand^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('Random')
        ..libraryUri.isEqualTo('dart:math')
        ..isNotImported.isNull,
    ]);
  }

  Future<void> test_unprefixed_filters() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
var foo01 = 0;
var foo02 = 0;
var bar01 = 0;
var bar02 = 0;

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isTopLevelVariable,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isTopLevelVariable,
    ]);
  }

  Future<void> test_unprefixed_imported_class() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', content: '''
class A02 {}
''');

    var response = await _getTestCodeSuggestions('''
import 'a.dart';
import 'b.dart';

void f() {
  A0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 2);

    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('A01')
        ..isClass
        ..libraryUri.isEqualTo('package:test/a.dart')
        ..isNotImported.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('A02')
        ..isClass
        ..libraryUri.isEqualTo('package:test/b.dart')
        ..isNotImported.isNull,
    ]);
  }

  Future<void> test_unprefixed_imported_topLevelVariable() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', content: '''
var foo01 = 0;
''');

    newFile('$testPackageLibPath/b.dart', content: '''
var foo02 = 0;
''');

    var response = await _getTestCodeSuggestions('''
import 'a.dart';
import 'b.dart';

void f() {
  foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isTopLevelVariable
        ..libraryUri.isEqualTo('package:test/a.dart')
        ..isNotImported.isNull,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isTopLevelVariable
        ..libraryUri.isEqualTo('package:test/b.dart')
        ..isNotImported.isNull,
    ]);
  }

  Future<void> test_unprefixed_imported_withPrefix_class() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'dart:math' as math;

void f() {
  Rand^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // No suggestion without the `math` prefix.
    check(response).suggestions.withElementClass.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('math.Random')
        ..libraryUri.isEqualTo('dart:math')
        ..isNotImported.isNull,
    ]);
  }

  Future<void> test_unprefixed_sorts_byScore() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
var fooAB = 0;
var fooBB = 0;

void f() {
  fooB^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `fooBB` has better score than `fooAB` - prefix match
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('fooBB')
        ..isTopLevelVariable,
      (suggestion) => suggestion
        ..completion.isEqualTo('fooAB')
        ..isTopLevelVariable,
    ]);
  }

  Future<void> test_unprefixed_sorts_byType() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions(r'''
var foo01 = 0.0;
var foo02 = 0;

void f() {
  int v = foo0^
}
''');

    check(response)
      ..assertComplete()
      ..hasReplacement(left: 4);

    // `foo02` has better relevance, its type matches the context type
    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('foo02')
        ..isTopLevelVariable,
      (suggestion) => suggestion
        ..completion.isEqualTo('foo01')
        ..isTopLevelVariable,
    ]);
  }

  Future<void> test_yaml_analysisOptions_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/analysis_options.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    check(response)
      ..assertComplete()
      ..hasEmptyReplacement();

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('analyzer: ')
        ..kind.isIdentifier,
      (suggestion) => suggestion
        ..completion.isEqualTo('include: ')
        ..kind.isIdentifier,
      (suggestion) => suggestion
        ..completion.isEqualTo('linter: ')
        ..kind.isIdentifier,
    ]);
  }

  Future<void> test_yaml_fixData_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/fix_data.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    check(response)
      ..assertComplete()
      ..hasEmptyReplacement();

    check(response).suggestions.matches([
      (suggestion) => suggestion
        ..completion.isEqualTo('version: ')
        ..kind.isIdentifier,
      (suggestion) => suggestion
        ..completion.isEqualTo('transforms:')
        ..kind.isIdentifier,
    ]);
  }

  Future<void> test_yaml_pubspec_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/pubspec.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    check(response)
      ..assertComplete()
      ..hasEmptyReplacement();

    check(response).suggestions.includesAll([
      (suggestion) => suggestion
        ..completion.isEqualTo('name: ')
        ..kind.isIdentifier,
      (suggestion) => suggestion
        ..completion.isEqualTo('dependencies: ')
        ..kind.isIdentifier,
      (suggestion) => suggestion
        ..completion.isEqualTo('dev_dependencies: ')
        ..kind.isIdentifier,
    ]);
  }

  Future<CompletionResponseForTesting> _getCodeSuggestions({
    required String path,
    required String content,
    int maxResults = 1 << 10,
  }) async {
    var completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    newFile(path,
        content: content.substring(0, completionOffset) +
            content.substring(completionOffset + 1));

    return await _getSuggestions(
      path: path,
      completionOffset: completionOffset,
      maxResults: maxResults,
    );
  }

  Future<CompletionResponseForTesting> _getSuggestions({
    required String path,
    required int completionOffset,
    required int maxResults,
  }) async {
    var request = CompletionGetSuggestions2Params(
      path,
      completionOffset,
      maxResults,
    ).toRequest('0');

    var response = await _handleSuccessfulRequest(request);
    var result = CompletionGetSuggestions2Result.fromResponse(response);
    return CompletionResponseForTesting(
      requestOffset: completionOffset,
      replacementOffset: result.replacementOffset,
      replacementLength: result.replacementLength,
      isIncomplete: result.isIncomplete,
      suggestions: result.suggestions,
    );
  }

  Future<CompletionResponseForTesting> _getTestCodeSuggestions(
    String content, {
    int maxResults = 1 << 10,
  }) {
    return _getCodeSuggestions(
      path: convertPath(testFilePath),
      content: content,
      maxResults: maxResults,
    );
  }

  RequestWithFutureResponse _sendTestCompletionRequest(String id, int offset) {
    var request = CompletionGetSuggestions2Params(
      testFilePathPlatform,
      0,
      1 << 10,
    ).toRequest(id);
    var futureResponse = handleRequest(request);
    return RequestWithFutureResponse(offset, request, futureResponse);
  }
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestionsTest
    extends AbstractCompletionDomainTest {
  Future<void> test_ArgumentList_constructor_named_fieldFormalParam() async {
    // https://github.com/dart-lang/sdk/issues/31023
    addTestFile('''
void f() { new A(field: ^);}
class A {
  A({this.field: -1}) {}
}
''');
    await getSuggestions();
  }

  Future<void> test_ArgumentList_constructor_named_param_label() async {
    addTestFile('void f() { new A(^);}'
        'class A { A({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_factory_named_param_label() async {
    addTestFile('void f() { new A(^);}'
        'class A { factory A({one, two}) => throw 0; }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withoutSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^3); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^ 3); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withoutSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^foo); }');
    await getSuggestions();
    expect(suggestions, hasLength(1));

    // The named arg "b: " should not replace anything.
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ',
        replacementOffset: null, replacementLength: 0);
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^ foo); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void> test_ArgumentList_function_named_partiallyTyped() async {
    addTestFile('''
    class C {
      void m(String firstString, {String secondString}) {}

      void n() {
        m('a', se^'b');
      }
    }
    ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'secondString: ');
    expect(suggestions, hasLength(1));
    // Ensure we replace the correct section.
    expect(replacementOffset, equals(completionOffset - 2));
    expect(replacementLength, equals(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param() async {
    addTestFile('void f() { int.parse("16", ^);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param1() async {
    addTestFile('void f() { foo(o^);} foo({one, two}) {}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param2() async {
    addTestFile('void f() {A a = new A(); a.foo(one: 7, ^);}'
        'class A { foo({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(1));
  }

  Future<void> test_ArgumentList_imported_function_named_param_label1() async {
    addTestFile('void f() { int.parse("16", r^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param_label3() async {
    addTestFile('void f() { int.parse("16", ^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_catch() async {
    addTestFile('void f() {try {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally');
    expect(suggestions, hasLength(3));
  }

  Future<void> test_catch2() async {
    addTestFile('void f() {try {} on Foo {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch3() async {
    addTestFile('void f() {try {} catch (e) {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch4() async {
    addTestFile('void f() {try {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch5() async {
    addTestFile('void f() {try {} ^ finally {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_constructor() async {
    addTestFile('class A {bool foo; A() : ^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor2() async {
    addTestFile('class A {bool foo; A() : s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor3() async {
    addTestFile('class A {bool foo; A() : a=7,^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor4() async {
    addTestFile('class A {bool foo; A() : a=7,s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor5() async {
    addTestFile('class A {bool foo; A() : a=7,s^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor6() async {
    addTestFile('class A {bool foo; A() : a=7,^ void bar() {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_extension() async {
    addTestFile('''
class MyClass {
  void foo() {
    ba^
  }
}

extension MyClassExtension on MyClass {
  void bar() {}
}
''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'bar');
  }

  Future<void> test_html() {
    //
    // We no longer support the analysis of non-dart files.
    //
    testFile = convertPath('/project/web/test.html');
    addTestFile('''
      <html>^</html>
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      expect(suggestions, hasLength(0));
    });
  }

  Future<void> test_import_uri_with_trailing() {
    final filePath = '/project/bin/testA.dart';
    final incompleteImportText = toUriStr('/project/bin/t');
    newFile(filePath, content: 'library libA;');
    addTestFile('''
    import "$incompleteImportText^.dart";
    void f() {}''');
    return getSuggestions().then((_) {
      expect(replacementOffset,
          equals(completionOffset - incompleteImportText.length));
      expect(replacementLength, equals(5 + incompleteImportText.length));
      assertHasResult(CompletionSuggestionKind.IMPORT, toUriStr(filePath));
      assertNoResult('test');
    });
  }

  Future<void> test_imports() {
    addTestFile('''
      import 'dart:html';
      void f() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  Future<void> test_imports_aborted_new_request() async {
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    var request1 = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('7');
    var responseFuture1 = waitResponse(request1);

    // Make another request before the first request completes
    var request2 = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('8');
    var responseFuture2 = waitResponse(request2);

    // Await first response
    var response1 = await responseFuture1;
    var result1 = CompletionGetSuggestionsResult.fromResponse(response1);
    assertValidId(result1.id);

    // Await second response
    var response2 = await responseFuture2;
    var result2 = CompletionGetSuggestionsResult.fromResponse(response2);
    assertValidId(result2.id);

    // Wait for all processing to be complete
    await analysisHandler.server.onAnalysisComplete;
    await pumpEventQueue();

    // Assert that first request has been aborted
    expect(allSuggestions[result1.id], hasLength(0));

    // Assert valid results for the second request
    expect(allSuggestions[result2.id], same(suggestions));
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'class');
  }

  @failingTest
  Future<void> test_imports_aborted_source_changed() async {
    // TODO(brianwilkerson) Figure out whether this test makes sense when
    // running the new driver. It waits for an initial empty notification then
    // waits for a new notification. But I think that under the driver we only
    // ever send one notification.
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var responseFuture = waitResponse(request);

    // Simulate user deleting text after request but before suggestions returned
    server.updateContent('uc1', {testFile: AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile: ChangeContentOverlay([SourceEdit(completionOffset - 1, 1, '')])
    });

    // Await a response
    var response = await responseFuture;
    completionId = response.id;
    assertValidId(completionId);

    // Wait for all processing to be complete
    await analysisHandler.server.onAnalysisComplete;
    await pumpEventQueue();

    // Assert that request has been aborted
    expect(suggestionsDone, isTrue);
    expect(suggestions, hasLength(0));
  }

  Future<void> test_imports_incremental() async {
    addTestFile('''library foo;
      e^
      import "dart:async";
      import "package:foo/foo.dart";
      class foo { }''');
    await waitForTasksFinished();
    server.updateContent('uc1', {testFile: AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile: ChangeContentOverlay([SourceEdit(completionOffset, 0, 'xp')])
    });
    completionOffset += 2;
    await getSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8);
    assertNoResult('extends');
    assertNoResult('library');
  }

  Future<void> test_imports_partial() async {
    addTestFile('''^
      import "package:foo/foo.dart";
      import "package:bar/bar.dart";
      class Baz { }''');

    // Wait for analysis then edit the content
    await waitForTasksFinished();
    var revisedContent = testCode.substring(0, completionOffset) +
        'i' +
        testCode.substring(completionOffset);
    ++completionOffset;
    server.handleRequest(AnalysisUpdateContentParams(
        {testFile: AddContentOverlay(revisedContent)}).toRequest('add1'));

    // Request code completion immediately after edit
    var response = await waitResponse(
        CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0'));
    completionId = response.id;
    assertValidId(completionId);
    await waitForTasksFinished();
    // wait for response to arrive
    // because although the analysis is complete (waitForTasksFinished)
    // the response may not yet have been processed
    while (replacementOffset == null) {
      await Future.delayed(Duration(milliseconds: 5));
    }
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'library');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'part \'\';',
        selectionOffset: 6);
    assertNoResult('extends');
  }

  Future<void> test_imports_prefixed() {
    addTestFile('''
      import 'dart:html' as foo;
      void f() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  Future<void> test_imports_prefixed2() {
    addTestFile('''
      import 'dart:html' as foo;
      void f() {foo.^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement');
      assertNoResult('test');
    });
  }

  Future<void> test_inComment_block_beforeDartDoc() async {
    addTestFile('''
/* text ^ */

/// some doc comments
class SomeClass {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_block_beforeNode() async {
    addTestFile('''
  void f(aaa, bbb) {
    /* text ^ */
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfFile_withNewline() async {
    addTestFile('''
    // text ^
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfFile_withoutNewline() async {
    addTestFile('// text ^');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeDartDoc() async {
    addTestFile('''
// text ^

/// some doc comments
class SomeClass {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeNode() async {
    addTestFile('''
  void f(aaa, bbb) {
    // text ^
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeToken() async {
    addTestFile('''
  void f(aaa, bbb) {
    // text ^
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc1() async {
    addTestFile('''
  /// ^
  void f(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc2() async {
    addTestFile('''
  /// Some text^
  void f(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc3() async {
    addTestFile('''
class MyClass {
  /// ^
  void foo() {}

  void bar() {}
}

extension MyClassExtension on MyClass {
  void baz() {}
}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc_reference1() async {
    newFile('/testA.dart', content: '''
  part of libA;
  foo(bar) => 0;''');
    addTestFile('''
  library libA;
  part "${toUriStr('/testA.dart')}";
  import "dart:math";
  /// The [^]
  void f(aaa, bbb) {}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'f');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'min');
  }

  Future<void> test_inDartDoc_reference2() async {
    addTestFile('''
  /// The [m^]
  void f(aaa, bbb) {}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'f');
  }

  Future<void> test_inDartDoc_reference3() async {
    addTestFile('''
class MyClass {
  /// [^]
  void foo() {}

  void bar() {}
}

extension MyClassExtension on MyClass {
  void baz() {}
}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'bar');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'baz');
  }

  Future<void> test_inherited() {
    addTestFile('''
class A {
  m() {}
}
class B extends A {
  x() {^}
}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = CompletionGetSuggestionsParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        CompletionGetSuggestionsParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invocation() {
    addTestFile('class A {b() {}} void f() {A a; a.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  Future<void> test_invocation_withTrailingStmt() {
    addTestFile('class A {b() {}} void f() {A a; a.^ int x = 7;}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  Future<void> test_is_asPrefixedIdentifierStart() async {
    addTestFile('''
class A { var isVisible;}
void f(A p) { var v1 = p.is^; }''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'isVisible');
  }

  Future<void> test_keyword() {
    addTestFile('library A; cl^');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 2));
      expect(replacementLength, equals(2));
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
          selectionOffset: 8);
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'class');
    });
  }

  Future<void> test_local_implicitCreation() async {
    addTestFile('''
class A {
  A();
  A.named();
}
void f() {
  ^
}
''');
    await getSuggestions();

    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));

    // The class is suggested.
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
        elementKind: ElementKind.CLASS);

    // Both constructors - default and named, are suggested.
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
        elementKind: ElementKind.CONSTRUCTOR);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A.named',
        elementKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_local_named_constructor() {
    addTestFile('class A {A.c(); x() {new A.^}}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'c');
      assertNoResult('A');
    });
  }

  Future<void> test_local_override() {
    newFile('/project/bin/a.dart', content: 'class A {m() {}}');
    addTestFile('''
import 'a.dart';
class B extends A {
  m() {}
  x() {^}
}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  Future<void> test_local_shadowClass() async {
    addTestFile('''
class A {
  A();
  A.named();
}
void f() {
  int A = 0;
  ^
}
''');
    await getSuggestions();

    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));

    // The class is suggested.
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A');

    // Class and all its constructors are shadowed by the local variable.
    assertNoResult('A', elementKind: ElementKind.CLASS);
    assertNoResult('A', elementKind: ElementKind.CONSTRUCTOR);
    assertNoResult('A.named', elementKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_locals() {
    addTestFile('class A {var a; x() {var b;^}} class DateTime { }');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'a');
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'b');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'x');
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'DateTime',
          elementKind: ElementKind.CLASS);
    });
  }

  Future<void> test_offset_past_eof() async {
    addTestFile('void f() { }', offset: 300);
    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(response.id, '0');
    expect(response.error!.code, RequestErrorCode.INVALID_PARAMETER);
  }

  Future<void> test_overrides() {
    newFile('/project/bin/a.dart', content: 'class A {m() {}}');
    addTestFile('''
import 'a.dart';
class B extends A {m() {^}}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  Future<void> test_partFile() {
    newFile('/project/bin/a.dart', content: '''
      library libA;
      import 'dart:html';
      part 'test.dart';
      class A { }
    ''');
    addTestFile('''
      part of libA;
      void f() {^}''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  Future<void> test_partFile2() {
    newFile('/project/bin/a.dart', content: '''
      part of libA;
      class A { }''');
    addTestFile('''
      library libA;
      part "a.dart";
      import 'dart:html';
      void f() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('''
      void f() {
        ^
      }
    ''');
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c',
        TestNotificationManager(), InstrumentationService.NULL_SERVICE);
    var result = plugin.CompletionGetSuggestionsResult(
        testFile.indexOf('^'), 0, <CompletionSuggestion>[
      CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          DART_RELEVANCE_DEFAULT, 'plugin completion', 3, 0, false, false)
    ]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'plugin completion',
        selectionOffset: 3);
  }

  Future<void> test_simple() {
    addTestFile('''
      void f() {
        ^
      }
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
          elementKind: ElementKind.CLASS);
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  Future<void> test_static() async {
    addTestFile('class A {static b() {} c() {}} void f() {A.^}');
    await getSuggestions();
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    assertNoResult('c');
  }

  Future<void> test_topLevel() {
    addTestFile('''
      typedef foo();
      var test = '';
      void f() {tes^t}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 3));
      expect(replacementLength, equals(4));
      // Suggestions based upon imported elements are partially filtered
      //assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'test');
      assertNoResult('HtmlElement');
    });
  }
}

class PubPackageAnalysisServerTest with ResourceProviderMixin {
  late final MockServerChannel serverChannel;
  late final AnalysisServer server;

  AnalysisDomainHandler get analysisDomain {
    return server.handlers.whereType<AnalysisDomainHandler>().single;
  }

  CompletionDomainHandler get completionDomain {
    return server.handlers.whereType<CompletionDomainHandler>().single;
  }

  List<String> get experiments => [
        EnableString.enhanced_enums,
        EnableString.named_arguments_anywhere,
        EnableString.super_parameters,
      ];

  String get testFileContent => getFile(testFilePath).readAsStringSync();

  String get testFilePath => '$testPackageLibPath/test.dart';

  String get testFilePathPlatform => convertPath(testFilePath);

  String get testPackageLibPath => '$testPackageRootPath/lib';

  Folder get testPackageRoot => getFolder(testPackageRootPath);

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get testPackageTestPath => '$testPackageRootPath/test';

  String get workspaceRootPath => '/home';

  Future<Response> handleRequest(Request request) async {
    return await serverChannel.sendRequest(request);
  }

  Future<void> setRoots({
    required List<String> included,
    required List<String> excluded,
  }) async {
    var includedConverted = included.map(convertPath).toList();
    var excludedConverted = excluded.map(convertPath).toList();
    await _handleSuccessfulRequest(
      AnalysisSetAnalysisRootsParams(
        includedConverted,
        excludedConverted,
        packageRoots: {},
      ).toRequest('0'),
    );
  }

  @mustCallSuper
  void setUp() {
    serverChannel = MockServerChannel();

    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    writeTestPackageConfig();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
      ),
    );

    server = AnalysisServer(
      serverChannel,
      resourceProvider,
      AnalysisServerOptions(),
      DartSdkManager(sdkRoot.path),
      CrashReportingAttachmentsBuilder.empty,
      InstrumentationService.NULL_SERVICE,
    );

    completionDomain.budgetDuration = const Duration(seconds: 30);
  }

  void writePackageConfig(Folder root, PackageConfigFileBuilder config) {
    newPackageConfigJsonFile(
      root.path,
      content: config.toContent(toUriStr: toUriStr),
    );
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      content: config.toContent(),
    );
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion,
    );

    writePackageConfig(testPackageRoot, config);
  }

  void writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }

  Future<void> _configureWithWorkspaceRoot() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;
  }

  /// Validates that the given [request] is handled successfully.
  Future<Response> _handleSuccessfulRequest(Request request) async {
    var response = await handleRequest(request);
    expect(response, isResponseSuccess(request.id));
    return response;
  }
}

class RequestWithFutureResponse {
  final int offset;
  final Request request;
  final Future<Response> futureResponse;

  RequestWithFutureResponse(this.offset, this.request, this.futureResponse);

  Future<CompletionResponseForTesting> toResponse() async {
    var response = await futureResponse;
    expect(response, isResponseSuccess(request.id));
    var result = CompletionGetSuggestions2Result.fromResponse(response);
    return CompletionResponseForTesting(
      requestOffset: offset,
      replacementOffset: result.replacementOffset,
      replacementLength: result.replacementLength,
      isIncomplete: result.isIncomplete,
      suggestions: result.suggestions,
    );
  }
}

extension on CheckTarget<CompletionGetSuggestionDetails2Result> {
  @useResult
  CheckTarget<SourceChange> get change {
    return nest(
      value.change,
      (selected) => 'has change ${valueStr(selected)}',
    );
  }

  @useResult
  CheckTarget<String> get completion {
    return nest(
      value.completion,
      (selected) => 'has completion ${valueStr(selected)}',
    );
  }
}
