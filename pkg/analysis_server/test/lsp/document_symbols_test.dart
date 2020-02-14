// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentSymbolsTest);
  });
}

@reflectiveTest
class DocumentSymbolsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_flat() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      int myField;
      MyClass(this.myField);
      myMethod() {}
    }
    extension StringExtensions on String {}
    extension on String {}
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final result = await getDocumentSymbols(mainFileUri.toString());
    final symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(7));

    final topLevel = symbols[0];
    expect(topLevel.name, equals('topLevel'));
    expect(topLevel.kind, equals(SymbolKind.Variable));
    expect(topLevel.containerName, isNull);

    final myClass = symbols[1];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.containerName, isNull);

    final field = symbols[2];
    expect(field.name, equals('myField'));
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals(myClass.name));

    final constructor = symbols[3];
    expect(constructor.name, equals('MyClass'));
    expect(constructor.kind, equals(SymbolKind.Constructor));
    expect(constructor.containerName, equals(myClass.name));

    final method = symbols[4];
    expect(method.name, equals('myMethod'));
    expect(method.kind, equals(SymbolKind.Method));
    expect(method.containerName, equals(myClass.name));

    final namedExtension = symbols[5];
    expect(namedExtension.name, equals('StringExtensions'));
    expect(namedExtension.containerName, isNull);

    final unnamedExtension = symbols[6];
    expect(unnamedExtension.name, equals('<unnamed extension>'));
    expect(unnamedExtension.containerName, isNull);
  }

  Future<void> test_hierarchical() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      int myField;
      MyClass(this.myField);
      myMethod() {}
    }
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
        textDocumentCapabilities: withHierarchicalDocumentSymbolSupport(
            emptyTextDocumentClientCapabilities));

    final result = await getDocumentSymbols(mainFileUri.toString());
    final symbols = result.map(
      (docsymbols) => docsymbols,
      (symbolInfos) => throw 'Expected DocumentSymbols, got SymbolInformations',
    );

    expect(symbols, hasLength(2));

    final topLevel = symbols[0];
    expect(topLevel.name, equals('topLevel'));
    expect(topLevel.kind, equals(SymbolKind.Variable));

    final myClass = symbols[1];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.children, hasLength(3));

    final field = myClass.children[0];
    expect(field.name, equals('myField'));
    expect(field.kind, equals(SymbolKind.Field));

    final constructor = myClass.children[1];
    expect(constructor.name, equals('MyClass'));
    expect(constructor.kind, equals(SymbolKind.Constructor));

    final method = myClass.children[2];
    expect(method.name, equals('myMethod'));
    expect(method.kind, equals(SymbolKind.Method));
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final result = await getDocumentSymbols(pubspecFileUri.toString());
    final symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, isEmpty);
  }
}
