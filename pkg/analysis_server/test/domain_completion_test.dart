// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'mocks.dart';
import 'services/completion/dart/completion_check.dart';
import 'services/completion/dart/completion_printer.dart' as printer;
import 'services/completion/dart/text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionDetails2Test);
    defineReflectiveTests(CompletionDomainHandlerGetSuggestions2Test);
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
    var buffer = StringBuffer();
    _SuggestionDetailsPrinter(
      resourceProvider: resourceProvider,
      fileDisplayMap: {testFile: 'testFile'},
      buffer: buffer,
      result: result,
    ).writeResult();
    var actual = buffer.toString();

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
    // TODO(scheglov): Check that says "libraryUri".
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
      var completion = suggestion.completion;
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
    var buffer = StringBuffer();
    printer.CompletionResponsePrinter(
      buffer: buffer,
      configuration: printerConfiguration,
      response: response,
    ).writeResponse();
    var actual = buffer.toString();

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
    server.completionState.budgetDuration = const Duration();

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

  Future<void> test_notImported_pub_dependencies_inBin() async {
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

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', '''
class A02 {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path)
        ..add(name: 'bbb', rootPath: bbbRoot.path),
    );

    await _configureWithWorkspaceRoot();

    var binPath = convertPath('$testPackageRootPath/bin/main.dart');
    var response = await _getCodeSuggestions(
      path: binPath,
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

  Future<void> test_notImported_pub_dependencies_inWeb() async {
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

    var bbbRoot = getFolder('$workspaceRootPath/packages/bbb');
    newFile('${bbbRoot.path}/lib/f.dart', '''
class A02 {}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: aaaRoot.path)
        ..add(name: 'bbb', rootPath: bbbRoot.path),
    );

    await _configureWithWorkspaceRoot();

    var webPath = convertPath('$testPackageRootPath/web/main.dart');
    var response = await _getCodeSuggestions(
      path: webPath,
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
  Random
    kind: constructorInvocation
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
    relevance: 503
  fooAB
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 503
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
    relevance: 558
  foo01
    kind: topLevelVariable
    isNotImported: null
    libraryUri: null
    relevance: 510
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
  |resolution: |
    kind: identifier
  screenshots:
    kind: identifier
  |topics: |
    kind: identifier
  |version: |
    kind: identifier
  workspace:
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

    // Extract the internal request object.
    var dartRequest = server.completionState.currentRequest;

    return CompletionResponseForTesting(
      requestOffset: completionOffset,
      requestLocationName: dartRequest?.collectorLocationName,
      opTypeLocationName: dartRequest?.opType.completionLocation,
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
      requestLocationName: null,
      opTypeLocationName: null,
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
      for (var fileEdit in change.edits) {
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

    var replacementStr = edit.replacement.replaceAll('\n', r'\n');
    _writelnWithIndent('replacement: $replacementStr');
  }

  void _writeSourceFileEdit(SourceFileEdit fileEdit) {
    var file = resourceProvider.getFile(fileEdit.file);
    var fileStr = fileDisplayMap[file] ?? fail('No display name: $file');
    _writelnWithIndent(fileStr);

    _withIndent(() {
      for (var edit in fileEdit.edits) {
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
