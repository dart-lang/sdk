// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentSymbolsTest);
  });
}

@reflectiveTest
class DocumentSymbolsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_emptyBodies() async {
    failTestOnErrorDiagnostic = false; // Enum without items is an error

    var content = '''
class /*[0*/A/*0]*/;
mixin /*[1*/M/*1]*/;
enum /*[2*/En/*2]*/;
extension /*[3*/Ex1/*3]*/ on String;
extension /*[4*/Ex2/*4]*/;
extension on /*[5*/String/*5]*/;
extension on/*[6*//*6]*/;
''';

    await verifySymbolNamesWithRanges(content, [
      'A',
      'M',
      'En',
      'Ex1',
      'Ex2',
      'extension on String',
      '<unnamed extension>',
    ]);
  }

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

  Future<void> test_extension_names() async {
    failTestOnErrorDiagnostic = false;

    const content = '''
extension /*[0*/StringExtensions/*0]*/ on String {}
extension /*[1*/_StringExtensions/*1]*/ on String {}
extension on /*[2*/String/*2]*/ {}
extension on /*[3*//*3]*/{}
''';

    await verifySymbolNamesWithRanges(content, [
      'StringExtensions',
      '_StringExtensions',
      'extension on String',
      '<unnamed extension>',
    ]);
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
    expect(unnamedExtension.name, equals('extension on String'));
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
    var symbols = await _getSymbols(content);
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

  Future<void> test_hierarchical_constructor_primary() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*//*[1*/MyClass/*1]*//*0]*/();
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'MyClass',
        code.ranges[0],
        children: [_isConstructor('MyClass', code.ranges[1])],
      ),
    ]);
  }

  Future<void> test_hierarchical_constructor_primary_body() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*/A/*0]*/(final int /*[1*/a/*1]*/, int b) {
  /*[2*/this/*2]*/ {}
}
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'A',
        code.ranges[0],
        children: [
          _isConstructor('A', code.ranges[0]),
          _isSymbol('a', .Field, code.ranges[1]),
          _isConstructor('this', code.ranges[2]),
        ],
      ),
    ]);
  }

  Future<void> test_hierarchical_constructor_primary_named() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*/MyClass/*0]*//*[1*/.named/*1]*/();
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'MyClass',
        code.ranges[0],
        children: [_isConstructor('MyClass.named', code.ranges[1])],
      ),
    ]);
  }

  Future<void> test_hierarchical_constructor_secondary_new() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*/MyClass/*0]*/ {
  /*[1*/new/*1]*/();
  new /*[2*/named/*2]*/();
}
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'MyClass',
        code.ranges[0],
        children: [
          _isConstructor('MyClass', code.ranges[1]),
          _isConstructor('MyClass.named', code.ranges[2]),
        ],
      ),
    ]);
  }

  Future<void> test_hierarchical_constructor_secondary_typeName() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*/MyClass/*0]*/ {
  /*[1*/MyClass/*1]*/();
  MyClass./*[2*/named/*2]*/();
}
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'MyClass',
        code.ranges[0],
        children: [
          _isConstructor('MyClass', code.ranges[1]),
          _isConstructor('MyClass.named', code.ranges[2]),
        ],
      ),
    ]);
  }

  Future<void> test_hierarchical_constructor_secondary_typeName_new() async {
    setHierarchicalDocumentSymbolSupport();

    const content = '''
class /*[0*/MyClass/*0]*/ {
  MyClass./*[1*/new/*1]*/();
}
''';
    var code = TestCode.parse(content);
    var symbols = await _getSymbols(code.code);

    expect(symbols, [
      _isClass(
        'MyClass',
        code.ranges[0],
        children: [_isConstructor('MyClass', code.ranges[1])],
      ),
    ]);
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
          ServerErrorCodes.fileNotAnalyzed,
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

  /// Using [content] as the test file, verifies that the returned document
  /// symbols exactly match [expectedNames] in-order along with the matching
  /// ranges marked in [content].
  Future<void> verifySymbolNamesWithRanges(
    String content,
    List<String> expectedNames,
  ) async {
    var code = TestCode.parseNormalized(content);
    expect(
      code.ranges,
      hasLength(expectedNames.length),
      reason:
          'The number of expected names must match the number of '
          'marked ranges in the code',
    );

    newFile(mainFilePath, code.code);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    var symbols = result.map(
      (docsymbols) => throw 'Expected SymbolInformations, got DocumentSymbols',
      (symbolInfos) => symbolInfos,
    );
    var results = symbols
        .map((symbol) => (symbol.name, symbol.location.range))
        .toList();
    expect(
      results,
      code.ranges.mapIndexed((i, range) => (expectedNames[i], range.range)),
    );
  }

  Future<List<DocumentSymbol>> _getSymbols(String content) async {
    newFile(mainFilePath, content);
    await initialize();

    var result = await getDocumentSymbols(mainFileUri);
    return result.map(
      (docsymbols) => docsymbols,
      (symbolInfos) => throw 'Expected DocumentSymbols, got SymbolInformations',
    );
  }

  Matcher _isClass(
    String name,
    TestCodeRange range, {
    List<Matcher>? children,
  }) {
    return _isSymbol(name, .Class, range, children: children);
  }

  Matcher _isConstructor(
    String name,
    TestCodeRange range, {
    List<Matcher>? children,
  }) {
    return _isSymbol(name, .Constructor, range, children: children);
  }

  Matcher _isSymbol(
    String name,
    SymbolKind kind,
    TestCodeRange selectionRange, {
    List<Matcher>? children,
  }) {
    return isA<DocumentSymbol>()
        .having((symbol) => symbol.name, 'name', name)
        .having((symbol) => symbol.kind, 'kind', kind)
        .having(
          (symbol) => symbol.selectionRange,
          'selectionRange',
          selectionRange.range,
        )
        .having((symbol) => symbol.children, 'children', children);
  }
}
