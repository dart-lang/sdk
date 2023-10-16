// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceSymbolsTest);
  });
}

@reflectiveTest
class WorkspaceSymbolsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_cancellation() async {
    const content = '''
void f() {}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbolsRequest1 = makeRequest(
      Method.workspace_symbol,
      WorkspaceSymbolParams(query: 'f'),
    );
    final symbolsCancellation1 = makeNotification(
        Method.cancelRequest, CancelParams(id: symbolsRequest1.id));
    final symbolsRequest2 = makeRequest(
      Method.workspace_symbol,
      WorkspaceSymbolParams(query: 'f'),
    );

    final responses = await Future.wait([
      sendRequestToServer(symbolsRequest1),
      sendNotificationToServer(symbolsCancellation1),
      sendRequestToServer(symbolsRequest2),
    ]);

    // Expect the first response was cancelled.
    final symbolsResponse1 = responses[0] as ResponseMessage;
    expect(symbolsResponse1.result, isNull);
    expect(symbolsResponse1.error, isNotNull);
    expect(
      symbolsResponse1.error,
      isResponseError(ErrorCodes.RequestCancelled),
    );

    // But second to complete normally.
    final symbolsResponse2 = responses[2] as ResponseMessage;
    expect(symbolsResponse2.result, hasLength(greaterThanOrEqualTo(1)));
    expect(symbolsResponse2.error, isNull);
  }

  Future<void> test_dependencies_excluded() async {
    newFile(mainFilePath, 'class LocalClass12345 {}');
    await provideConfig(
      initialize,
      {
        'includeDependenciesInWorkspaceSymbols': false,
      },
    );

    expect(await getWorkspaceSymbols('Duration'), isEmpty);
    expect(await getWorkspaceSymbols('LocalClass12345'), isNotEmpty);
  }

  Future<void> test_dependencies_included() async {
    newFile(mainFilePath, 'class LocalClass12345 {}');
    await provideConfig(
      initialize,
      {
        'includeDependenciesInWorkspaceSymbols': true,
      },
    );

    expect(await getWorkspaceSymbols('Duration'), isNotEmpty);
    expect(await getWorkspaceSymbols('LocalClass12345'), isNotEmpty);
  }

  Future<void> test_dependencies_includedByDefault() async {
    newFile(mainFilePath, 'class LocalClass12345 {}');
    await initialize();

    expect(await getWorkspaceSymbols('Duration'), isNotEmpty);
    expect(await getWorkspaceSymbols('LocalClass12345'), isNotEmpty);
  }

  Future<void> test_extensions() async {
    const content = '''
extension StringExtensions on String {}
extension on String {}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbols = await getWorkspaceSymbols('S');

    final namedExtensions =
        symbols.firstWhere((s) => s.name == 'StringExtensions');
    expect(namedExtensions.kind, equals(SymbolKind.Class));
    expect(namedExtensions.containerName, isNull);

    // Unnamed extensions are not returned in Workspace Symbols.
  }

  Future<void> test_extensionType() async {
    const content = r'''
extension type MyExtensionType(int it) {}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbols = await getWorkspaceSymbols('MyExt');

    final namedExtensions =
        symbols.firstWhere((s) => s.name == 'MyExtensionType');
    expect(namedExtensions.kind, equals(SymbolKind.Class));
    expect(namedExtensions.containerName, isNull);
  }

  Future<void> test_extensionType_method() async {
    const content = r'''
extension type E(int it) {
  void foo() {}
}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbols = await getWorkspaceSymbols('foo');

    final namedExtensions =
        symbols.firstWhere((s) => s.name == 'foo()' && s.containerName == 'E');
    expect(namedExtensions.kind, equals(SymbolKind.Method));
    expect(namedExtensions.containerName, 'E');
  }

  Future<void> test_fullMatch() async {
    const content = '''
[!String topLevel = ''!];
class MyClass {
  int myField;
  MyClass(this.myField);
  myMethod() {}
}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbols = await getWorkspaceSymbols('topLevel');

    final topLevel = symbols.firstWhere((s) => s.name == 'topLevel');
    expect(topLevel.kind, equals(SymbolKind.Variable));
    expect(topLevel.containerName, isNull);
    expect(topLevel.location.uri, equals(mainFileUri));
    expect(topLevel.location.range, equals(code.range.range));

// Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name.contains('MyClass')), isFalse);
    expect(symbols.any((s) => s.name.contains('myMethod')), isFalse);
  }

  Future<void> test_fuzzyMatch() async {
    const content = '''
String topLevel = '';
class MyClass {
  [!int myField!];
  MyClass(this.myField);
  myMethod() {}
}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    // meld should match myField
    final symbols = await getWorkspaceSymbols('meld');

    final field = symbols.firstWhere((s) => s.name == 'myField');
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals('MyClass'));
    expect(field.location.uri, equals(mainFileUri));
    expect(field.location.range, equals(code.range.range));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name.contains('MyClass')), isFalse);
    expect(symbols.any((s) => s.name.contains('myMethod')), isFalse);
  }

  Future<void> test_invalidParams() async {
    await initialize();

    // Create a request that doesn't supply the query param.
    final request = RequestMessage(
      id: Either2<int, String>.t1(1),
      method: Method.workspace_symbol,
      params: <String, dynamic>{},
      jsonrpc: jsonRpcVersion,
    );

    final response = await sendRequestToServer(request);
    final error = response.error!;
    expect(error.code, equals(ErrorCodes.InvalidParams));
    // Ensure the error is useful to the client.
    expect(
      error.message,
      equals('Invalid params for workspace/symbol:\n'
          'params.query must not be undefined'),
    );
  }

  /// Ensure that multiple projects/drivers do not result in duplicate results
  /// for things referenced in both projects.
  Future<void> test_overlappingDrivers() async {
    // Reference an SDK lib.
    const content = "import 'dart:core';";
    // Project 1
    newFile(mainFilePath, content);
    // Project 2
    final otherFilePath = convertPath('/home/otherProject/foo.dart');
    newFile(otherFilePath, content);

    // Initialize with both projects as roots.
    await initialize(workspaceFolders: [
      projectFolderUri,
      pathContext.toUri(convertPath('/home/otherProject')),
    ]);

    // Search for something in the SDK that's referenced by both projects and
    // expect it only shows up once.
    final symbols = await getWorkspaceSymbols('Duration');
    expect(symbols.where((s) => s.name == 'Duration'), hasLength(1));
  }

  Future<void> test_partialMatch() async {
    const content = '''
String topLevel = '';
class MyClass {
  /*[0*/int myField/*0]*/;
  MyClass(this.myField);
  /*[1*/myMethod() {}/*1]*/
  /*[2*/myMethodWithArgs(int a) {}/*2]*/
}
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final symbols = await getWorkspaceSymbols('my');
    final ranges = code.ranges.ranges;
    final fieldRange = ranges[0];
    final methodRange = ranges[1];
    final methodWithArgsRange = ranges[2];

    final field = symbols.firstWhere((s) => s.name == 'myField');
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals('MyClass'));
    expect(field.location.uri, equals(mainFileUri));
    expect(field.location.range, equals(fieldRange));

    final klass = symbols.firstWhere((s) => s.name == 'MyClass');
    expect(klass.kind, equals(SymbolKind.Class));
    expect(klass.containerName, isNull);
    expect(klass.location.uri, equals(mainFileUri));

    final method = symbols.firstWhere((s) => s.name == 'myMethod()');
    expect(method.kind, equals(SymbolKind.Method));
    expect(method.containerName, equals('MyClass'));
    expect(method.location.uri, equals(mainFileUri));
    expect(method.location.range, equals(methodRange));

    final methodWithArgs =
        symbols.firstWhere((s) => s.name == 'myMethodWithArgs(…)');
    expect(methodWithArgs.kind, equals(SymbolKind.Method));
    expect(methodWithArgs.containerName, equals('MyClass'));
    expect(methodWithArgs.location.uri, equals(mainFileUri));
    expect(methodWithArgs.location.range, equals(methodWithArgsRange));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name == 'topLevel'), isFalse);
  }
}
