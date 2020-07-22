// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceSymbolsTest);
  });
}

@reflectiveTest
class WorkspaceSymbolsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_extensions() async {
    const content = '''
    extension StringExtensions on String {}
    extension on String {}
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final symbols = await getWorkspaceSymbols('S');

    final namedExtensions =
        symbols.firstWhere((s) => s.name == 'StringExtensions');
    expect(namedExtensions.kind, equals(SymbolKind.Obj));
    expect(namedExtensions.containerName, isNull);

    // Unnamed extensions are not returned in Workspace Symbols.
  }

  Future<void> test_fullMatch() async {
    const content = '''
    [[String topLevel = '']];
    class MyClass {
      int myField;
      MyClass(this.myField);
      myMethod() {}
    }
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final symbols = await getWorkspaceSymbols('topLevel');

    final topLevel = symbols.firstWhere((s) => s.name == 'topLevel');
    expect(topLevel.kind, equals(SymbolKind.Variable));
    expect(topLevel.containerName, isNull);
    expect(topLevel.location.uri, equals(mainFileUri.toString()));
    expect(topLevel.location.range, equals(rangeFromMarkers(content)));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name.contains('MyClass')), isFalse);
    expect(symbols.any((s) => s.name.contains('myMethod')), isFalse);
  }

  Future<void> test_fuzzyMatch() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      [[int myField]];
      MyClass(this.myField);
      myMethod() {}
    }
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    // meld should match myField
    final symbols = await getWorkspaceSymbols('meld');

    final field = symbols.firstWhere((s) => s.name == 'myField');
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals('MyClass'));
    expect(field.location.uri, equals(mainFileUri.toString()));
    expect(field.location.range, equals(rangeFromMarkers(content)));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name.contains('MyClass')), isFalse);
    expect(symbols.any((s) => s.name.contains('myMethod')), isFalse);
  }

  Future<void> test_invalidParams() async {
    await initialize();

    // Create a request that doesn't supply the query param.
    final request = RequestMessage(
      id: Either2<num, String>.t1(1),
      method: Method.workspace_symbol,
      params: <String, dynamic>{},
      jsonrpc: jsonRpcVersion,
    );

    final response = await sendRequestToServer(request);
    expect(response.error.code, equals(ErrorCodes.InvalidParams));
    // Ensure the error is useful to the client.
    expect(
      response.error.message,
      equals('Invalid params for workspace/symbol:\n'
          'params.query must not be undefined'),
    );
  }

  Future<void> test_partialMatch() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      [[int myField]];
      MyClass(this.myField);
      [[myMethod() {}]]
      [[myMethodWithArgs(int a) {}]]
    }
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final symbols = await getWorkspaceSymbols('my');
    final ranges = rangesFromMarkers(content);
    final fieldRange = ranges[0];
    final methodRange = ranges[1];
    final methodWithArgsRange = ranges[2];

    final field = symbols.firstWhere((s) => s.name == 'myField');
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals('MyClass'));
    expect(field.location.uri, equals(mainFileUri.toString()));
    expect(field.location.range, equals(fieldRange));

    final klass = symbols.firstWhere((s) => s.name == 'MyClass');
    expect(klass.kind, equals(SymbolKind.Class));
    expect(klass.containerName, isNull);
    expect(klass.location.uri, equals(mainFileUri.toString()));

    final method = symbols.firstWhere((s) => s.name == 'myMethod()');
    expect(method.kind, equals(SymbolKind.Method));
    expect(method.containerName, equals('MyClass'));
    expect(method.location.uri, equals(mainFileUri.toString()));
    expect(method.location.range, equals(methodRange));

    final methodWithArgs =
        symbols.firstWhere((s) => s.name == 'myMethodWithArgs(…)');
    expect(methodWithArgs.kind, equals(SymbolKind.Method));
    expect(methodWithArgs.containerName, equals('MyClass'));
    expect(methodWithArgs.location.uri, equals(mainFileUri.toString()));
    expect(methodWithArgs.location.range, equals(methodWithArgsRange));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name == 'topLevel'), isFalse);
  }
}
