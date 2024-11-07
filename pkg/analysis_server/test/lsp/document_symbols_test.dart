// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
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
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(2));

    var themeEnum = symbols[0];
    expect(themeEnum.name, equals('Theme'));
    expect(themeEnum.kind, equals(SymbolKind.Enum));
    expect(themeEnum.containerName, isNull);

    var enumValue = symbols[1];
    expect(enumValue.name, equals('light'));
    // EnumMember is not in the original LSP list, so unless the client explicitly
    // advertises support, we will fall back to Enum.
    expect(enumValue.kind, equals(SymbolKind.Enum));
    expect(enumValue.containerName, 'Theme');
  }

  Future<void> test_enumMember_supported() async {
    setDocumentSymbolKinds([SymbolKind.Enum, SymbolKind.EnumMember]);

    const content = '''
enum Theme {
  light,
}
''';
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(2));

    var themeEnum = symbols[0];
    expect(themeEnum.name, equals('Theme'));
    expect(themeEnum.kind, equals(SymbolKind.Enum));
    expect(themeEnum.containerName, isNull);

    var enumValue = symbols[1];
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
extension type A(int i) {
  static const int foo = 0;
}
''';
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(9));

    var topLevel = symbols[0];
    expect(topLevel.name, equals('topLevel'));
    expect(topLevel.kind, equals(SymbolKind.Variable));
    expect(topLevel.containerName, isNull);

    var myClass = symbols[1];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.containerName, isNull);

    var field = symbols[2];
    expect(field.name, equals('myField'));
    expect(field.kind, equals(SymbolKind.Field));
    expect(field.containerName, equals(myClass.name));

    var constructor = symbols[3];
    expect(constructor.name, equals('MyClass'));
    expect(constructor.kind, equals(SymbolKind.Constructor));
    expect(constructor.containerName, equals(myClass.name));

    var method = symbols[4];
    expect(method.name, equals('myMethod'));
    expect(method.kind, equals(SymbolKind.Method));
    expect(method.containerName, equals(myClass.name));

    var namedExtension = symbols[5];
    expect(namedExtension.name, equals('StringExtensions'));
    expect(namedExtension.containerName, isNull);

    var unnamedExtension = symbols[6];
    expect(unnamedExtension.name, equals('<unnamed extension>'));
    expect(unnamedExtension.containerName, isNull);

    var extensionTypeA = symbols[7];
    expect(extensionTypeA.name, equals('A'));
    expect(extensionTypeA.containerName, isNull);

    var foo = symbols[8];
    expect(foo.name, equals('foo'));
    expect(foo.containerName, equals('A'));
    expect(foo.kind, equals(SymbolKind.Field));
  }

  Future<void> test_hierarchical() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
String topLevel = '';
class MyClass {
  int myField;
  MyClass(this.myField);
  myMethod() {}
}
''';
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => docsymbols,
      (symbolInfos) => throw 'Expected DocumentSymbols, got SymbolInformations',
    );

    expect(symbols, hasLength(2));

    var topLevel = symbols[0];
    expect(topLevel.name, equals('topLevel'));
    expect(topLevel.kind, equals(SymbolKind.Variable));

    var myClass = symbols[1];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.children, hasLength(3));

    var field = myClass.children![0];
    expect(field.name, equals('myField'));
    expect(field.kind, equals(SymbolKind.Field));

    var constructor = myClass.children![1];
    expect(constructor.name, equals('MyClass'));
    expect(constructor.kind, equals(SymbolKind.Constructor));

    var method = myClass.children![2];
    expect(method.name, equals('myMethod'));
    expect(method.kind, equals(SymbolKind.Method));
  }

  Future<void> test_macroGenerated() async {
    setDartTextDocumentContentProviderSupport();
    addMacros([declareInTypeMacro()]);

    const content = '''
import 'macros.dart';

@DeclareInType('void f() {}')
class A {}
''';
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileMacroUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(2));

    var topLevel = symbols[0];
    expect(topLevel.name, equals('A'));
    expect(topLevel.kind, equals(SymbolKind.Class));
    expect(topLevel.containerName, isNull);

    var myClass = symbols[1];
    expect(myClass.name, equals('f'));
    expect(myClass.kind, equals(SymbolKind.Method));
    expect(myClass.containerName, equals('A'));
  }

  Future<void> test_noAnalysisRoot_openedFile() async {
    // When there are no analysis roots and we open a file, it should be added as
    // a temporary root allowing us to service requests for it.
    const content = 'class MyClass {}';
    newFile(mainFilePath, content);
    await initialize(allowEmptyRootUri: true);
    await openFile(mainFileUri, content);

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, hasLength(1));

    var myClass = symbols[0];
    expect(myClass.name, equals('MyClass'));
    expect(myClass.kind, equals(SymbolKind.Class));
    expect(myClass.containerName, isNull);
  }

  Future<void> test_noAnalysisRoot_unopenedFile() async {
    // When there are no analysis roots and we receive requests for a file that
    // was not opened, we will reject the file due to not being analyzed.
    const content = 'class MyClass {}';
    newFile(mainFilePath, content);
    await initialize(allowEmptyRootUri: true);

    await expectLater(
      getDocumentSymbols(mainFileUri),
      throwsA(
        isResponseError(
          ServerErrorCodes.FileNotAnalyzed,
          message: 'File is not being analyzed',
        ),
      ),
    );
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    var result = await getDocumentSymbols(pubspecFileUri);
    // Since the list is empty, it will deserialize into whatever the first
    // type is, so just accept both types.
    var symbols = result.map(
      (docsymbols) => docsymbols,
      (symbolInfos) => symbolInfos,
    );
    expect(symbols, isEmpty);
  }
}
