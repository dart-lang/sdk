// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    if (!AnalysisDriver.useSummary2) {
      defineReflectiveTests(WorkspaceSymbolsTest);
    }
  });
}

@reflectiveTest
class WorkspaceSymbolsTest extends AbstractLspAnalysisServerTest {
  test_fullMatch() async {
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
    expect(symbols.any((s) => s.name == 'MyClass'), isFalse);
    expect(symbols.any((s) => s.name == 'myMethod'), isFalse);
  }

  test_fuzzyMatch() async {
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
    expect(symbols.any((s) => s.name == 'MyClass'), isFalse);
    expect(symbols.any((s) => s.name == 'myMethod'), isFalse);
  }

  test_invalidParams() async {
    await initialize();

    // Create a request that doesn't supply the query param.
    final request = new RequestMessage(
      Either2<num, String>.t1(1),
      Method.workspace_symbol,
      <String, dynamic>{},
      jsonRpcVersion,
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

  test_partialMatch() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      [[int myField]];
      MyClass(this.myField);
      [[myMethod() {}]]
    }
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final symbols = await getWorkspaceSymbols('my');
    final ranges = rangesFromMarkers(content);
    final fieldRange = ranges[0];
    final methodRange = ranges[1];

    final field = symbols.firstWhere((s) => s.name == 'myField');
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals('MyClass'));
    expect(field.location.uri, equals(mainFileUri.toString()));
    expect(field.location.range, equals(fieldRange));

    final klass = symbols.firstWhere((s) => s.name == 'MyClass');
    expect(klass.kind, equals(SymbolKind.Class));
    expect(klass.containerName, isNull);
    expect(klass.location.uri, equals(mainFileUri.toString()));

    final method = symbols.firstWhere((s) => s.name == 'myMethod');
    expect(method.kind, equals(SymbolKind.Method));
    expect(method.containerName, equals('MyClass'));
    expect(method.location.uri, equals(mainFileUri.toString()));
    expect(method.location.range, equals(methodRange));

    // Ensure we didn't get some things that definitely do not match.
    expect(symbols.any((s) => s.name == 'topLevel'), isFalse);
  }
}
