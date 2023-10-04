// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'domain_completion_util.dart';
import 'mocks.dart';
import 'services/completion/dart/completion_check.dart';
import 'services/completion/dart/completion_printer.dart' as printer;
import 'services/completion/dart/text_expectations.dart';
import 'src/plugin/plugin_manager_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionDetails2Test);
    defineReflectiveTests(CompletionDomainHandlerGetSuggestions2Test);
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionsTest);
  });
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestionDetails2Test
    extends PubPackageAnalysisServerTest {
  void assertDetailsText(
    CompletionGetSuggestionDetails2Result result,
    String expected, {
    bool printIfFailed = true,
  }) {
    final buffer = StringBuffer();
    _SuggestionDetailsPrinter(
      resourceProvider: resourceProvider,
      fileDisplayMap: {testFile: 'testFile'},
      buffer: buffer,
      result: result,
    ).writeResult();
    final actual = buffer.toString();

    if (actual != expected) {
      if (printIfFailed) {
        print(actual);
      }
      TextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  Future<void> test_alreadyImported() async {
    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
import 'dart:math';
void f() {
  Rand^
}
''', completion: 'Random', libraryUri: 'dart:math');

    assertDetailsText(details, r'''
completion: Random
  change
''');
  }

  Future<void> test_import_dart() async {
    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
void f() {
  R^
}
''', completion: 'Random', libraryUri: 'dart:math');

    assertDetailsText(details, r'''
completion: Random
  change
    testFile
      offset: 0
      length: 0
      replacement: import 'dart:math';\n\n
''');
  }

  Future<void> test_import_package_dependencies() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
dependencies:
  aaa: any
''');

    var aaaRoot = getFolder('$workspaceRootPath/packages/aaa');
    newFile('${aaaRoot.path}/lib/f.dart', '''
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

    assertDetailsText(details, r'''
completion: Test
  change
    testFile
      offset: 0
      length: 0
      replacement: import 'package:aaa/a.dart';\n\n
''');
  }

  Future<void> test_import_package_this() async {
    newFile('$testPackageLibPath/a.dart', '''
class Test {}
''');

    await _configureWithWorkspaceRoot();

    var details = await _getTestCodeDetails('''
void f() {
  T^
}
''', completion: 'Test', libraryUri: 'package:test/a.dart');

    assertDetailsText(details, r'''
completion: Test
  change
    testFile
      offset: 0
      length: 0
      replacement: import 'package:test/a.dart';\n\n
''');
  }

  Future<void> test_invalidLibraryUri() async {
    await _configureWithWorkspaceRoot();

    var request = CompletionGetSuggestionDetails2Params(
            testFile.path, 0, 'Random', '[foo]:bar')
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

  Future<void> _configureWithWorkspaceRoot() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;
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

    newFile(
        path,
        content.substring(0, completionOffset) +
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

    var response = await handleSuccessfulRequest(request);
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
  printer.Configuration printerConfiguration = printer.Configuration(
    filter: (suggestion) {
      final completion = suggestion.completion;
      if (completion.startsWith('A0')) {
        return suggestion.isClass;
      }
      return const {'foo0'}.any(completion.startsWith);
    },
    withIsNotImported: true,
    withLibraryUri: true,
  );

  /// Asserts that the [response] has the [expected] textual dump produced
  /// using [printerConfiguration].
  void assertResponseText(
    CompletionResponseForTesting response,
    String expected, {
    bool printIfFailed = true,
  }) {
    final buffer = StringBuffer();
    printer.CompletionResponsePrinter(
      buffer: buffer,
      configuration: printerConfiguration,
      response: response,
    ).writeResponse();
    final actual = buffer.toString();

    if (actual != expected) {
      if (printIfFailed) {
        print(actual);
      }
      TextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  @override
  void setUp() {
    super.setUp();
    server.completionState.budgetDuration = const Duration(seconds: 30);
  }

  Future<void> test_abort_onAnotherCompletionRequest() async {
    var abortedIdSet = <String>{};
    server.discardedRequests.stream.listen((request) {
      abortedIdSet.add(request.id);
    });

    newFile(testFilePath, '');

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

    printerConfiguration.filter = (suggestion) {
      if (suggestion.isClass) {
        return const {'int'}.contains(suggestion.completion);
      }
      return false;
    };

    assertResponseText(response0, r'''
suggestions
''');

    assertResponseText(response1, r'''
suggestions
''');

    assertResponseText(response2, r'''
suggestions
  int
    kind: class
    isNotImported: null
    libraryUri: dart:core
''');
  }

  Future<void> test_abort_onUpdateContent() async {
    var abortedIdSet = <String>{};
    server.discardedRequests.stream.listen((request) {
      abortedIdSet.add(request.id);
    });

    newFile(testFilePath, '');

    await _configureWithWorkspaceRoot();

    // Schedule a completion request.
    var request = _sendTestCompletionRequest('0', 0);

    // Simulate typing in the IDE.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay('void f() {}'),
      }).toRequest('1'),
    );

    // The request should be aborted.
    var response = await request.toResponse();
    expect(abortedIdSet, {'0'});

    assertResponseText(response, r'''
suggestions
''');
  }

  Future<void> test_applyPendingFileChanges() async {
    await _configureWithWorkspaceRoot();

    // Request with the empty content.
    await _getTestCodeSuggestions('^');

    // Change the file, and request again.
    // Should apply pending file changes before resolving.
    var response = await _getTestCodeSuggestions('Str^');

    printerConfiguration.filter = (suggestion) {
      if (suggestion.isClass) {
        return const {'String'}.contains(suggestion.completion);
      }
      return false;
    };

    assertResponseText(response, r'''
replacement
  left: 3
suggestions
  String
    kind: class
    isNotImported: null
    libraryUri: dart:core
''');
  }

  Future<void> test_isNotImportedFeature_prefixed_classInstanceMethod() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void foo01() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    // The fact that `b.dart` is imported, and `a.dart` is not, does not affect
    // the order of suggestions added with an expression prefix. We are not
    // going to import anything, so this does not matter.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_notImported_dart() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  Rand^
}
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.isClass;
    };

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  Random
    kind: class
    isNotImported: true
    libraryUri: dart:math
''');
  }

  Future<void> test_notImported_emptyBudget() async {
    await _configureWithWorkspaceRoot();

    // Empty budget, so no not yet imported libraries.
    server.completionState.budgetDuration = const Duration(milliseconds: 0);

    var response = await _getTestCodeSuggestions('''
void f() {
  Rand^
}
''');

    printerConfiguration.filter = (_) => true;

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
''');
  }

  Future<void> test_notImported_lowerRelevance_extension_getter() async {
    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    newFile('$testPackageLibPath/a.dart', '''
extension E1 on int {
  int get foo01 => 0;
}
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: getter
    isNotImported: null
    libraryUri: null
  foo01
    kind: getter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_extension_method() async {
    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    newFile('$testPackageLibPath/a.dart', '''
extension E1 on int {
  void foo01() {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo01
    kind: methodInvocation
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_extension_setter() async {
    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    newFile('$testPackageLibPath/a.dart', '''
extension E1 on int {
  set foo01(int _) {}
}
''');

    newFile('$testPackageLibPath/b.dart', '''
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

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: setter
    isNotImported: null
    libraryUri: null
  foo01
    kind: setter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_topLevel_class() async {
    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  A0^
}
''');

    // `A01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A02
    kind: class
    isNotImported: null
    libraryUri: package:test/b.dart
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_topLevel_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo01 => 0;
''');

    newFile('$testPackageLibPath/b.dart', '''
int get foo02 => 0;
''');

    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: getter
    isNotImported: null
    libraryUri: package:test/b.dart
  foo01
    kind: getter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_topLevel_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
set foo01(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', '''
set foo02(int _) {}
''');

    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: setter
    isNotImported: null
    libraryUri: package:test/b.dart
  foo01
    kind: setter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_lowerRelevance_topLevel_variable() async {
    newFile('$testPackageLibPath/a.dart', '''
var foo01 = 0;
''');

    newFile('$testPackageLibPath/b.dart', '''
var foo02 = 0;
''');

    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    var response = await _getTestCodeSuggestions('''
import 'b.dart';

void f() {
  foo0^
}
''');

    // `foo01` relevance is decreased because it is not yet imported.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: package:test/b.dart
  foo01
    kind: topLevelVariable
    isNotImported: true
    libraryUri: package:test/a.dart
''');
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
    newFile('${aaaRoot.path}/lib/f.dart', '''
class A01 {}
''');
    newFile('${aaaRoot.path}/lib/src/f.dart', '''
class A02 {}
''');

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', '''
class A03 {}
''');
    newFile('${bbbRoot.path}/lib/src/f.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:aaa/f.dart
''');
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
    newFile('${aaaRoot.path}/lib/f.dart', '''
class A01 {}
''');
    newFile('${aaaRoot.path}/lib/src/f.dart', '''
class A02 {}
''');

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', '''
class A03 {}
''');
    newFile('${bbbRoot.path}/lib/src/f.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:aaa/f.dart
  A03
    kind: class
    isNotImported: true
    libraryUri: package:bbb/f.dart
''');
  }

  Future<void> test_notImported_pub_this() async {
    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/a.dart
  A02
    kind: class
    isNotImported: true
    libraryUri: package:test/b.dart
''');
  }

  Future<void> test_notImported_pub_this_hasImport() async {
    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
class A02 {}
''');

    newFile('$testPackageLibPath/b.dart', '''
class A03 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'a.dart';

void f() {
  A0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: null
    libraryUri: package:test/a.dart
  A02
    kind: class
    isNotImported: null
    libraryUri: package:test/a.dart
  A03
    kind: class
    isNotImported: true
    libraryUri: package:test/b.dart
''');
  }

  Future<void> test_notImported_pub_this_hasImport_hasShow() async {
    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
class A02 {}
''');

    newFile('$testPackageLibPath/b.dart', '''
class A03 {}
''');

    await _configureWithWorkspaceRoot();
    printerConfiguration.sorting =
        printer.Sorting.relevanceThenCompletionThenKind;

    var response = await _getTestCodeSuggestions('''
import 'a.dart' show A02;

void f() {
  A0^
}
''');

    // Note:
    // 1. A02 is the first, because it is already imported.
    // 2. A01 is still suggested, but with lower relevance.
    // 3. A03 has the same relevance (not tested), but sorted by name.
    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A02
    kind: class
    isNotImported: null
    libraryUri: package:test/a.dart
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/a.dart
  A03
    kind: class
    isNotImported: true
    libraryUri: package:test/b.dart
''');
  }

  Future<void> test_notImported_pub_this_inLib_excludesTest() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
''');

    newFile('$testPackageTestPath/b.dart', '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_notImported_pub_this_inLib_includesThisSrc() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/f.dart', '''
class A01 {}
''');

    newFile('$testPackageLibPath/src/f.dart', '''
class A02 {}
''');

    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
void f() {
  A0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/f.dart
  A02
    kind: class
    isNotImported: true
    libraryUri: package:test/src/f.dart
''');
  }

  Future<void> test_notImported_pub_this_inTest_includesTest() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
''');

    var b = newFile('$testPackageTestPath/b.dart', '''
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

    assertResponseText(response, '''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/a.dart
  A02
    kind: class
    isNotImported: true
    libraryUri: $b_uriStr
''');
  }

  Future<void> test_notImported_pub_this_inTest_includesThisSrc() async {
    writeTestPackagePubspecYamlFile(r'''
name: test
''');

    newFile('$testPackageLibPath/f.dart', '''
class A01 {}
''');

    newFile('$testPackageLibPath/src/f.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: true
    libraryUri: package:test/f.dart
  A02
    kind: class
    isNotImported: true
    libraryUri: package:test/src/f.dart
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_numResults_topLevelVariables_imported_withPrefix() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
suggestions
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: package:test/a.dart
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: package:test/a.dart
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: constructorInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: constructorInvocation
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: null
    libraryUri: null
  foo02
    kind: getter
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: null
    libraryUri: null
  foo02
    kind: getter
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_prefixed_expression_extensionGetters_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: true
    libraryUri: package:test/a.dart
  foo02
    kind: getter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void>
      test_prefixed_expression_extensionGetters_notImported_private() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
  foo02
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_prefixed_expression_extensionMethods_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: true
    libraryUri: package:test/a.dart
  foo02
    kind: methodInvocation
    isNotImported: true
    libraryUri: package:test/a.dart
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: setter
    isNotImported: null
    libraryUri: null
  foo02
    kind: setter
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_prefixed_expression_extensionSetters_notImported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: setter
    isNotImported: true
    libraryUri: package:test/a.dart
  foo02
    kind: setter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void>
      test_prefixed_expression_extensionSetters_notImported_private() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: setter
    isNotImported: true
    libraryUri: package:test/a.dart
''');
  }

  Future<void> test_prefixed_extensionGetters_imported() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: null
    libraryUri: null
  foo02
    kind: getter
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: getter
    isNotImported: null
    libraryUri: null
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: methodInvocation
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_prefixed_importPrefix_class() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'dart:math' as math;

void f() {
  math.Rand^
}
''');

    printerConfiguration.filter = (_) => true;

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  Random
    kind: class
    isNotImported: null
    libraryUri: dart:math
''');
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

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
''');
  }

  Future<void> test_unprefixed_imported_class() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
class A01 {}
''');

    newFile('$testPackageLibPath/b.dart', '''
class A02 {}
''');

    var response = await _getTestCodeSuggestions('''
import 'a.dart';
import 'b.dart';

void f() {
  A0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 2
suggestions
  A01
    kind: class
    isNotImported: null
    libraryUri: package:test/a.dart
  A02
    kind: class
    isNotImported: null
    libraryUri: package:test/b.dart
''');
  }

  Future<void> test_unprefixed_imported_topLevelVariable() async {
    await _configureWithWorkspaceRoot();

    newFile('$testPackageLibPath/a.dart', '''
var foo01 = 0;
''');

    newFile('$testPackageLibPath/b.dart', '''
var foo02 = 0;
''');

    var response = await _getTestCodeSuggestions('''
import 'a.dart';
import 'b.dart';

void f() {
  foo0^
}
''');

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: package:test/a.dart
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: package:test/b.dart
''');
  }

  Future<void> test_unprefixed_imported_withPrefix_class() async {
    await _configureWithWorkspaceRoot();

    var response = await _getTestCodeSuggestions('''
import 'dart:math' as math;

void f() {
  Rand^
}
''');

    printerConfiguration.filter = (suggestion) {
      return suggestion.isClass;
    };

    // No suggestion without the `math` prefix.
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  math.Random
    kind: class
    isNotImported: null
    libraryUri: dart:math
''');
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

    printerConfiguration
      ..filter = (suggestion) {
        return suggestion.completion.startsWith('foo');
      }
      ..sorting = printer.Sorting.asIs
      ..withRelevance = true;

    // `fooBB` has better score than `fooAB` - prefix match
    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  fooBB
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 504
  fooAB
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 504
''');
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

    printerConfiguration
      ..sorting = printer.Sorting.asIs
      ..withRelevance = true;

    assertResponseText(response, r'''
replacement
  left: 4
suggestions
  foo02
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 565
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 511
''');
  }

  Future<void> test_yaml_analysisOptions_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/analysis_options.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    printerConfiguration
      ..filter = ((_) => true)
      ..withIsNotImported = false
      ..withLibraryUri = false;

    assertResponseText(response, r'''
suggestions
  |analyzer: |
    kind: identifier
  |code-style: |
    kind: identifier
  |include: |
    kind: identifier
  |linter: |
    kind: identifier
''');
  }

  Future<void> test_yaml_fixData_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/fix_data.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    printerConfiguration
      ..filter = ((_) => true)
      ..withIsNotImported = false
      ..withLibraryUri = false;

    assertResponseText(response, r'''
suggestions
  transforms:
    kind: identifier
  |version: |
    kind: identifier
''');
  }

  Future<void> test_yaml_pubspec_root() async {
    await _configureWithWorkspaceRoot();

    var path = convertPath('$testPackageRootPath/pubspec.yaml');
    var response = await _getCodeSuggestions(
      path: path,
      content: '^',
    );

    printerConfiguration
      ..filter = ((_) => true)
      ..withIsNotImported = false
      ..withLibraryUri = false;

    assertResponseText(response, r'''
suggestions
  |dependencies: |
    kind: identifier
  |dependency_overrides: |
    kind: identifier
  |description: |
    kind: identifier
  |dev_dependencies: |
    kind: identifier
  |documentation: |
    kind: identifier
  |environment: |
    kind: identifier
  |executables: |
    kind: identifier
  |flutter: |
    kind: identifier
  |homepage: |
    kind: identifier
  |issue_tracker: |
    kind: identifier
  |name: |
    kind: identifier
  |publish_to: |
    kind: identifier
  |repository: |
    kind: identifier
  screenshots:
    kind: identifier
  |topics: |
    kind: identifier
  |version: |
    kind: identifier
''');
  }

  Future<void> _configureWithWorkspaceRoot() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    await server.onAnalysisComplete;
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

    newFile(
      path,
      content.substring(0, completionOffset) +
          content.substring(completionOffset + 1),
    );

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

    var response = await handleSuccessfulRequest(request);
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
      testFile.path,
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
    await getTestCodeSuggestions('''
void f() { new A(field: ^);}
class A {
  A({this.field: -1}) {}
}
''');
  }

  Future<void> test_ArgumentList_constructor_named_param_label() async {
    await getTestCodeSuggestions('void f() { new A(^);}'
        'class A { A({one, two}) {} }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_factory_named_param_label() async {
    await getTestCodeSuggestions('void f() { new A(^);}'
        'class A { factory A({one, two}) => throw 0; }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withoutSpace() async {
    await getTestCodeSuggestions('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^3); }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withSpace() async {
    await getTestCodeSuggestions('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^ 3); }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withoutSpace() async {
    await getTestCodeSuggestions('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^foo); }');

    // The named arg "b: " should not replace anything.
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ',
        replacementOffset: null, replacementLength: 0);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withSpace() async {
    await getTestCodeSuggestions('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^ foo); }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void> test_ArgumentList_function_named_partiallyTyped() async {
    await getTestCodeSuggestions('''
    class C {
      void m(String firstString, {String secondString}) {}

      void n() {
        m('a', se^'b');
      }
    }
    ''');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'secondString: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'this');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
    // Ensure we replace the correct section.
    expect(replacementOffset, equals(completionOffset - 2));
    expect(replacementLength, equals(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param() async {
    await getTestCodeSuggestions('void f() { int.parse("16", ^);}');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
  }

  Future<void> test_ArgumentList_imported_function_named_param1() async {
    await getTestCodeSuggestions('void f() { foo(o^);} foo({one, two}) {}');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
  }

  Future<void> test_ArgumentList_imported_function_named_param2() async {
    await getTestCodeSuggestions('void f() {A a = new A(); a.foo(one: 7, ^);}'
        'class A { foo({one, two}) {} }');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'const');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'false');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'null');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'true');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'switch');
  }

  Future<void> test_ArgumentList_imported_function_named_param_label1() async {
    await getTestCodeSuggestions('void f() { int.parse("16", r^: 16);}');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param_label3() async {
    await getTestCodeSuggestions('void f() { int.parse("16", ^: 16);}');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_catch() async {
    await getTestCodeSuggestions('void f() {try {} ^}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally');
    expect(suggestions, hasLength(3));
  }

  Future<void> test_catch2() async {
    await getTestCodeSuggestions('void f() {try {} on Foo {} ^}');
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
    await getTestCodeSuggestions('void f() {try {} catch (e) {} finally {} ^}');
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
    await getTestCodeSuggestions('void f() {try {} finally {} ^}');
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
    await getTestCodeSuggestions('void f() {try {} ^ finally {}}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_constructor() async {
    await getTestCodeSuggestions('class A {bool foo; A() : ^;}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor2() async {
    await getTestCodeSuggestions('class A {bool foo; A() : s^;}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor3() async {
    await getTestCodeSuggestions('class A {bool foo; A() : a=7,^;}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor4() async {
    await getTestCodeSuggestions('class A {bool foo; A() : a=7,s^;}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor5() async {
    await getTestCodeSuggestions('class A {bool foo; A() : a=7,s^}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_constructor6() async {
    await getTestCodeSuggestions(
        'class A {bool foo; A() : a=7,^ void bar() {}}');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
  }

  Future<void> test_extension() async {
    await getTestCodeSuggestions('''
class MyClass {
  void foo() {
    ba^
  }
}

extension MyClassExtension on MyClass {
  void bar() {}
}
''');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'bar');
  }

  Future<void> test_html() async {
    //
    // We no longer support the analysis of non-dart files.
    //
    await getCodeSuggestions(
      path: convertPath('$testPackageLibPath/test.html'),
      content: '<html>^</html>',
    );
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    expect(suggestions, hasLength(0));
  }

  Future<void> test_import_uri_with_trailing() async {
    final filePath = '/project/bin/testA.dart';
    final incompleteImportText = toUriStr('/project/bin/t');
    newFile(filePath, 'library libA;');
    await getTestCodeSuggestions('''
    import "$incompleteImportText^.dart";
    void f() {}''');
    expect(replacementOffset,
        equals(completionOffset - incompleteImportText.length));
    expect(replacementLength, equals(5 + incompleteImportText.length));
    assertHasResult(CompletionSuggestionKind.IMPORT, toUriStr(filePath));
    assertNoResult('test');
  }

  Future<void> test_imports() async {
    await getTestCodeSuggestions('''
      import 'dart:html';
      void f() {^}
    ''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
        elementKind: ElementKind.CLASS);
    assertNoResult('test');
  }

  Future<void> test_imports_aborted_new_request() async {
    addTestFile('''
        class foo { }
        c''');
    completionOffset = 31;

    // Make a request for suggestions
    var request1 =
        CompletionGetSuggestionsParams(testFile.path, completionOffset)
            .toRequest('7');
    var responseFuture1 = serverChannel.simulateRequestFromClient(request1);

    // Make another request before the first request completes
    var request2 =
        CompletionGetSuggestionsParams(testFile.path, completionOffset)
            .toRequest('8');
    var responseFuture2 = serverChannel.simulateRequestFromClient(request2);

    // Await first response
    var response1 = await responseFuture1;
    var result1 = CompletionGetSuggestionsResult.fromResponse(response1);
    assertValidId(result1.id);

    // Await second response
    var response2 = await responseFuture2;
    var result2 = CompletionGetSuggestionsResult.fromResponse(response2);
    assertValidId(result2.id);

    // Wait for all processing to be complete
    await server.onAnalysisComplete;
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
    var request =
        CompletionGetSuggestionsParams(testFile.path, completionOffset)
            .toRequest('0');
    var responseFuture = handleSuccessfulRequest(request);

    // Simulate user deleting text after request but before suggestions returned
    server.updateContent(
        'uc1', {testFile.path: AddContentOverlay(testFileContent)});
    server.updateContent('uc2', {
      testFile.path:
          ChangeContentOverlay([SourceEdit(completionOffset - 1, 1, '')])
    });

    // Await a response
    var response = await responseFuture;
    completionId = response.id;
    assertValidId(completionId);

    // Wait for all processing to be complete
    await server.onAnalysisComplete;
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
    completionOffset = 20;
    await waitForTasksFinished();
    server.updateContent(
        'uc1', {testFile.path: AddContentOverlay(testFileContent)});
    server.updateContent('uc2', {
      testFile.path:
          ChangeContentOverlay([SourceEdit(completionOffset, 0, 'xp')])
    });
    completionOffset += 2;
    await getSuggestions(
      path: testFile.path,
      completionOffset: completionOffset,
    );
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
    addTestFile('''
      import "package:foo/foo.dart";
      import "package:bar/bar.dart";
      class Baz { }''');
    completionOffset = 0;

    // Wait for analysis then edit the content
    await waitForTasksFinished();
    var precedingContent = testFileContent.substring(0, 0);
    var trailingContent = testFileContent.substring(completionOffset);
    var revisedContent = '${precedingContent}i$trailingContent';
    ++completionOffset;
    server.handleRequest(AnalysisUpdateContentParams(
        {testFile.path: AddContentOverlay(revisedContent)}).toRequest('add1'));

    // Request code completion immediately after edit
    var response = await handleSuccessfulRequest(
        CompletionGetSuggestionsParams(testFile.path, completionOffset)
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

  Future<void> test_imports_prefixed() async {
    await getTestCodeSuggestions('''
      import 'dart:html' as foo;
      void f() {^}
    ''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
    assertNoResult('HtmlElement');
    assertNoResult('test');
  }

  Future<void> test_imports_prefixed2() async {
    await getTestCodeSuggestions('''
      import 'dart:html' as foo;
      void f() {foo.^}
    ''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement');
    assertNoResult('test');
  }

  Future<void> test_inComment_block_beforeDartDoc() async {
    await getTestCodeSuggestions('''
/* text ^ */

/// some doc comments
class SomeClass {}
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_block_beforeNode() async {
    await getTestCodeSuggestions('''
  void f(aaa, bbb) {
    /* text ^ */
    print(42);
  }
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfFile_withNewline() async {
    await getTestCodeSuggestions('''
    // text ^
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfFile_withoutNewline() async {
    await getTestCodeSuggestions('// text ^');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeDartDoc() async {
    await getTestCodeSuggestions('''
// text ^

/// some doc comments
class SomeClass {}
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeNode() async {
    await getTestCodeSuggestions('''
  void f(aaa, bbb) {
    // text ^
    print(42);
  }
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeToken() async {
    await getTestCodeSuggestions('''
  void f(aaa, bbb) {
    // text ^
  }
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc1() async {
    await getTestCodeSuggestions('''
  /// ^
  void f(aaa, bbb) {}
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc2() async {
    await getTestCodeSuggestions('''
  /// Some text^
  void f(aaa, bbb) {}
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc3() async {
    await getTestCodeSuggestions('''
class MyClass {
  /// ^
  void foo() {}

  void bar() {}
}

extension MyClassExtension on MyClass {
  void baz() {}
}
  ''');
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc_reference1() async {
    newFile('/testA.dart', '''
  part of libA;
  foo(bar) => 0;''');
    await getTestCodeSuggestions('''
  library libA;
  part "${toUriStr('/testA.dart')}";
  import "dart:math";
  /// The [^]
  void f(aaa, bbb) {}
  ''');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'f');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'min');
  }

  Future<void> test_inDartDoc_reference2() async {
    await getTestCodeSuggestions('''
  /// The [m^]
  void f(aaa, bbb) {}
  ''');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'f');
  }

  Future<void> test_inDartDoc_reference3() async {
    await getTestCodeSuggestions('''
class MyClass {
  /// [^]
  void foo() {}

  void bar() {}
}

extension MyClassExtension on MyClass {
  void baz() {}
}
  ''');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'bar');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'baz');
  }

  Future<void> test_inherited() async {
    await getTestCodeSuggestions('''
class A {
  m() {}
}
class B extends A {
  x() {^}
}
''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = CompletionGetSuggestionsParams('test.dart', 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        CompletionGetSuggestionsParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invocation() async {
    await getTestCodeSuggestions('class A {b() {}} void f() {A a; a.^}');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
  }

  Future<void> test_invocation_withTrailingStmt() async {
    await getTestCodeSuggestions(
        'class A {b() {}} void f() {A a; a.^ int x = 7;}');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
  }

  Future<void> test_is_asPrefixedIdentifierStart() async {
    await getTestCodeSuggestions('''
class A { var isVisible;}
void f(A p) { var v1 = p.is^; }''');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'isVisible');
  }

  Future<void> test_keyword() async {
    await getTestCodeSuggestions('library A; cl^');
    expect(replacementOffset, equals(completionOffset - 2));
    expect(replacementLength, equals(2));
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'class');
  }

  Future<void> test_local_implicitCreation() async {
    await getTestCodeSuggestions('''
class A {
  A();
  A.named();
}
void f() {
  ^
}
''');

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

  Future<void> test_local_named_constructor() async {
    await getTestCodeSuggestions('class A {A.c(); x() {new A.^}}');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'c');
    assertNoResult('A');
  }

  Future<void> test_local_override() async {
    newFile('/project/bin/a.dart', 'class A {m() {}}');
    await getTestCodeSuggestions('''
import 'a.dart';
class B extends A {
  m() {}
  x() {^}
}
''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
  }

  Future<void> test_local_shadowClass() async {
    await getTestCodeSuggestions('''
class A {
  A();
  A.named();
}
void f() {
  int A = 0;
  ^
}
''');

    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));

    // The class is suggested.
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A');

    // Class and all its constructors are shadowed by the local variable.
    assertNoResult('A', elementKind: ElementKind.CLASS);
    assertNoResult('A', elementKind: ElementKind.CONSTRUCTOR);
    assertNoResult('A.named', elementKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_locals() async {
    await getTestCodeSuggestions(
        'class A {var a; x() {var b;^}} class DateTime { }');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'a');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'b');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'x');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'DateTime',
        elementKind: ElementKind.CLASS);
  }

  Future<void> test_offset_past_eof() async {
    addTestFile('void f() { }');
    var request =
        CompletionGetSuggestionsParams(testFile.path, 300).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_PARAMETER,
    );
  }

  Future<void> test_overrides() async {
    newFile('/project/bin/a.dart', 'class A {m() {}}');
    await getTestCodeSuggestions('''
import 'a.dart';
class B extends A {m() {^}}
''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
  }

  Future<void> test_partFile() async {
    newFile('$testPackageLibPath/a.dart', '''
      library libA;
      import 'dart:html';
      part 'test.dart';
      class A { }
    ''');
    await getTestCodeSuggestions('''
      part of libA;
      void f() {^}''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
        elementKind: ElementKind.CLASS);
    assertNoResult('test');
  }

  Future<void> test_partFile2() async {
    newFile('$testPackageLibPath/a.dart', '''
      part of libA;
      class A { }''');
    await getTestCodeSuggestions('''
      library libA;
      part "a.dart";
      import 'dart:html';
      void f() {^}
    ''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'HtmlElement',
        elementKind: ElementKind.CLASS);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'A',
        elementKind: ElementKind.CLASS);
    assertNoResult('test');
  }

  Future<void> test_sentToPlugins() async {
    if (!AnalysisServer.supportsPlugins) return;
    addTestFile('''
      void f() {

      }
    ''');
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c',
        TestNotificationManager(), InstrumentationService.NULL_SERVICE);
    var result = plugin.CompletionGetSuggestionsResult(
        testFileContent.indexOf('^'), 0, <CompletionSuggestion>[
      CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          DART_RELEVANCE_DEFAULT, 'plugin completion', 3, 0, false, false)
    ]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };
    await getTestCodeSuggestions('''
      void f() {
        ^
      }
    ''');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'plugin completion',
        selectionOffset: 3);
  }

  Future<void> test_simple() async {
    await getTestCodeSuggestions('''
      void f() {
        ^
      }
    ''');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'Object',
        elementKind: ElementKind.CLASS);
    assertNoResult('HtmlElement');
    assertNoResult('test');
  }

  Future<void> test_static() async {
    await getTestCodeSuggestions(
        'class A {static b() {} c() {}} void f() {A.^}');
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    assertNoResult('c');
  }

  Future<void> test_topLevel() async {
    await getTestCodeSuggestions('''
      typedef foo();
      var test = '';
      void f() {tes^t}
    ''');
    expect(replacementOffset, equals(completionOffset - 3));
    expect(replacementLength, equals(4));
    // Suggestions based upon imported elements are partially filtered
    //assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'test');
    assertNoResult('HtmlElement');
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

class _SuggestionDetailsPrinter {
  final StringBuffer buffer;
  final CompletionGetSuggestionDetails2Result result;
  final ResourceProvider resourceProvider;
  final Map<File, String> fileDisplayMap;

  String _indent = '';

  _SuggestionDetailsPrinter({
    required this.buffer,
    required this.result,
    required this.resourceProvider,
    required this.fileDisplayMap,
  });

  void writeResult() {
    _writelnWithIndent('completion: ${result.completion}');
    _withIndent(() {
      _writeChange(result.change);
    });
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeChange(SourceChange change) {
    _writelnWithIndent('change');
    _withIndent(() {
      for (final fileEdit in change.edits) {
        _writeSourceFileEdit(fileEdit);
      }
    });
  }

  void _writelnWithIndent(String line) {
    buffer.write(_indent);
    buffer.writeln(line);
  }

  void _writeSourceEdit(SourceEdit edit) {
    _writelnWithIndent('offset: ${edit.offset}');
    _writelnWithIndent('length: ${edit.length}');

    final replacementStr = edit.replacement.replaceAll('\n', r'\n');
    _writelnWithIndent('replacement: $replacementStr');
  }

  void _writeSourceFileEdit(SourceFileEdit fileEdit) {
    final file = resourceProvider.getFile(fileEdit.file);
    final fileStr = fileDisplayMap[file] ?? fail('No display name: $file');
    _writelnWithIndent(fileStr);

    _withIndent(() {
      for (final edit in fileEdit.edits) {
        _writeSourceEdit(edit);
      }
    });
  }
}

extension on CompletionSuggestion {
  bool get isClass {
    return kind == CompletionSuggestionKind.IDENTIFIER &&
        element?.kind == ElementKind.CLASS;
  }
}
