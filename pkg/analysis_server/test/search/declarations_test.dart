// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclarationsTest);
  });
}

@reflectiveTest
class DeclarationsTest extends AbstractSearchDomainTest {
  SearchGetElementDeclarationsResult declarationsResult;

  ElementDeclaration assertHas(String name, ElementKind kind,
      {String className, String mixinName}) {
    return declarationsResult.declarations.singleWhere((ElementDeclaration d) =>
        declarationsResult.files[d.fileIndex] == testFile &&
        d.name == name &&
        d.kind == kind &&
        d.className == className &&
        d.mixinName == mixinName);
  }

  void assertNo(String name) {
    expect(
        declarationsResult.declarations,
        isNot(contains(predicate((ElementDeclaration d) =>
            declarationsResult.files[d.fileIndex] == testFile &&
            d.name == name))));
  }

  Future<void> test_class() async {
    addTestFile(r'''
class C {
  int f;
  C();
  C.named();
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    await _getDeclarations();

    assertHas('C', ElementKind.CLASS);
    assertHas('f', ElementKind.FIELD, className: 'C');
    assertHas('named', ElementKind.CONSTRUCTOR, className: 'C');
    assertHas('g', ElementKind.GETTER, className: 'C');

    {
      var declaration = assertHas('s', ElementKind.SETTER, className: 'C');
      expect(declaration.codeOffset, 59);
      expect(declaration.codeLength, 16);
    }

    {
      var declaration = assertHas('m', ElementKind.METHOD, className: 'C');
      expect(declaration.codeOffset, 78);
      expect(declaration.codeLength, 11);
    }
  }

  Future<void> test_enum() async {
    addTestFile(r'''
enum E {
  a, b, c
}
''');
    await _getDeclarations();

    assertHas('E', ElementKind.ENUM);
    assertHas('a', ElementKind.ENUM_CONSTANT);
    assertHas('b', ElementKind.ENUM_CONSTANT);
    assertHas('c', ElementKind.ENUM_CONSTANT);
  }

  Future<void> test_maxResults() async {
    newFile(join(testFolder, 'a.dart'), content: r'''
class A {}
class B {}
''').path;
    newFile(join(testFolder, 'b.dart'), content: r'''
class C {}
class D {}
''').path;

    // Limit to exactly one file.
    await _getDeclarations(pattern: r'^[A-D]$', maxResults: 2);
    expect(declarationsResult.declarations, hasLength(2));

    // Limit in the middle of the second file.
    await _getDeclarations(pattern: r'^[A-D]$', maxResults: 3);
    expect(declarationsResult.declarations, hasLength(3));

    // No limit.
    await _getDeclarations(pattern: r'^[A-D]$');
    expect(declarationsResult.declarations, hasLength(4));
  }

  Future<void> test_mixin() async {
    addTestFile(r'''
mixin M {
  int f;
  int get g => 0;
  void set s(_) {}
  void m() {}
}
''');
    await _getDeclarations();

    assertHas('M', ElementKind.MIXIN);
    assertHas('f', ElementKind.FIELD, mixinName: 'M');
    assertHas('g', ElementKind.GETTER, mixinName: 'M');
    assertHas('s', ElementKind.SETTER, mixinName: 'M');
    assertHas('m', ElementKind.METHOD, mixinName: 'M');
  }

  Future<void> test_multipleFiles() async {
    var a = newFile(join(testFolder, 'a.dart'), content: 'class A {}').path;
    var b = newFile(join(testFolder, 'b.dart'), content: 'class B {}').path;

    await _getDeclarations();

    expect(declarationsResult.files, contains(a));
    expect(declarationsResult.files, contains(b));

    {
      var declaration =
          declarationsResult.declarations.singleWhere((d) => d.name == 'A');
      expect(declaration.name, 'A');
      expect(declaration.kind, ElementKind.CLASS);
      expect(declarationsResult.files[declaration.fileIndex], a);
      expect(declaration.offset, 6);
      expect(declaration.line, 1);
      expect(declaration.column, 7);
    }

    {
      var declaration =
          declarationsResult.declarations.singleWhere((d) => d.name == 'B');
      expect(declaration.name, 'B');
      expect(declaration.kind, ElementKind.CLASS);
      expect(declarationsResult.files[declaration.fileIndex], b);
    }
  }

  Future<void> test_onlyForFile() async {
    var a = newFile(join(testFolder, 'a.dart'), content: 'class A {}').path;
    newFile(join(testFolder, 'b.dart'), content: 'class B {}').path;

    await _getDeclarations(file: a);

    expect(declarationsResult.files, [a]);
    expect(declarationsResult.declarations, hasLength(1));

    var declaration = declarationsResult.declarations[0];
    expect(declaration.name, 'A');
    expect(declaration.kind, ElementKind.CLASS);
    expect(declarationsResult.files[declaration.fileIndex], a);
  }

  Future<void> test_parameters() async {
    addTestFile(r'''
void f(bool a, String b) {}
''');
    await _getDeclarations();

    var declaration = assertHas('f', ElementKind.FUNCTION);
    expect(declaration.parameters, '(bool a, String b)');
  }

  Future<void> test_regExp() async {
    addTestFile(r'''
class A {}
class B {}
class C {}
class D {}
''');
    await _getDeclarations(pattern: r'[A-C]');

    assertHas('A', ElementKind.CLASS);
    assertHas('B', ElementKind.CLASS);
    assertHas('C', ElementKind.CLASS);
    assertNo('D');
  }

  Future<void> test_top() async {
    addTestFile(r'''
int get g => 0;
void set s(_) {}
void f(int p) {}
int v;
typedef void tf1();
typedef tf2<T> = int Function<S>(T tp, S sp);
''');
    await _getDeclarations();

    assertHas('g', ElementKind.GETTER);
    assertHas('s', ElementKind.SETTER);
    assertHas('f', ElementKind.FUNCTION);
    assertHas('v', ElementKind.TOP_LEVEL_VARIABLE);
    assertHas('tf1', ElementKind.FUNCTION_TYPE_ALIAS);
    assertHas('tf2', ElementKind.FUNCTION_TYPE_ALIAS);
  }

  Future<void> _getDeclarations(
      {String file, String pattern, int maxResults}) async {
    var request = SearchGetElementDeclarationsParams(
            file: file, pattern: pattern, maxResults: maxResults)
        .toRequest('0');
    var response = await waitResponse(request);

    declarationsResult =
        SearchGetElementDeclarationsResult.fromResponse(response);
  }
}
