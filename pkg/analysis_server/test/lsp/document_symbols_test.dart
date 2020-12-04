// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentSymbolsTest);
  });
}

@reflectiveTest
class DocumentSymbolsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_enumMember_notSupported() async {
    const content = '''
    enum Theme {
      light,
    }
    ''';
    newFile(mainFilePath, content: content);
    await initialize();

    final result = await getDocumentSymbols(mainFileUri.toString());
    final symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(2));

    final themeEnum = symbols[0];
    expect(themeEnum.name, equals('Theme'));
    expect(themeEnum.kind, equals(SymbolKind.Enum));
    expect(themeEnum.containerName, isNull);

    final enumValue = symbols[1];
    expect(enumValue.name, equals('light'));
    // EnumMember is not in the original LSP list, so unless the client explicitly
    // advertises support, we will fall back to Enum.
    expect(enumValue.kind, equals(SymbolKind.Enum));
    expect(enumValue.containerName, 'Theme');
  }

  Future<void> test_enumMember_supported() async {
    const content = '''
    enum Theme {
      light,
    }
    ''';
    newFile(mainFilePath, content: content);
    await initialize(
      textDocumentCapabilities: withDocumentSymbolKinds(
        emptyTextDocumentClientCapabilities,
        [SymbolKind.Enum, SymbolKind.EnumMember],
      ),
    );

    final result = await getDocumentSymbols(mainFileUri.toString());
    final symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(2));

    final themeEnum = symbols[0];
    expect(themeEnum.name, equals('Theme'));
    expect(themeEnum.kind, equals(SymbolKind.Enum));
    expect(themeEnum.containerName, isNull);

    final enumValue = symbols[1];
    expect(enumValue.name, equals('light'));
    expect(enumValue.kind, equals(SymbolKind.EnumMember));
    expect(enumValue.containerName, 'Theme');
  }

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

  Future<void> test_noAnalysisRoot_openedFile() async {
    // When there are no analysis roots and we open a file, it should be added as
    // a temporary root allowing us to service requests for it.
    const content = 'class MyClass {}';
    newFile(mainFilePath, content: content);
    await initialize(allowEmptyRootUri: true);
    await openFile(mainFileUri, content);

    final result = await getDocumentSymbols(mainFileUri.toString());
    final symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(1));

    final myClass = symbols[0];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.containerName, isNull);
  }

  Future<void> test_noAnalysisRoot_unopenedFile() async {
    // When there are no analysis roots and we receive requests for a file that
    // was not opened, we will reject the file due to not being analyzed.
    const content = 'class MyClass {}';
    newFile(mainFilePath, content: content);
    await initialize(allowEmptyRootUri: true);

    await expectLater(getDocumentSymbols(mainFileUri.toString()),
        throwsA(isResponseError(ServerErrorCodes.InvalidFilePath)));
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final result = await getDocumentSymbols(pubspecFileUri.toString());
    // Since the list is empty, it will deserialise into whatever the first
    // type is, so just accept both types.
    final symbols = result.map(
      (docsymbols) => docsymbols,
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, isEmpty);
  }
}
