// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentSymbolsTest);
  });
}

@reflectiveTest
class DocumentSymbolsTest extends AbstractLspAnalysisServerTest {
  test_hierarchical() async {
    const content = '''
    String topLevel = '';
    class MyClass {
      int myField;
      MyClass(this.myField);
      myMethod() {}
    }
    ''';
    await newFile(mainFilePath, content: content);
    await initialize();

    final symbols = await getDocumentSymbols(mainFileUri.toString());
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
}
