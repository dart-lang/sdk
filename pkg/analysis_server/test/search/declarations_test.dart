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
  late SearchGetElementDeclarationsResult declarationsResult;

  ElementDeclaration assertHas(String name, ElementKind kind,
      {String? className, String? mixinName}) {
    return declarationsResult.declarations.singleWhere((ElementDeclaration d) =>
        declarationsResult.files[d.fileIndex] == testFile.path &&
        d.name == name &&
        d.kind == kind &&
        d.className == className &&
        d.mixinName == mixinName);
  }

  void assertNo(String name) {
    expect(
        declarationsResult.declarations,
        isNot(contains(predicate((ElementDeclaration d) =>
            declarationsResult.files[d.fileIndex] == testFile.path &&
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

  Future<void> test_extension() async {
    addTestFile(r'''
extension E on int {
  int get foo01 => 0;
  void set foo02(_) {}
  void foo03() {}
}
''');
    await _getDeclarations();

    assertHas('E', ElementKind.EXTENSION);

    {
      var declaration = assertHas('foo01', ElementKind.GETTER);
      expect(declaration.codeOffset, 23);
      expect(declaration.codeLength, 19);
    }

    {
      var declaration = assertHas('foo02', ElementKind.SETTER);
      expect(declaration.codeOffset, 45);
      expect(declaration.codeLength, 20);
    }

    {
      var declaration = assertHas('foo03', ElementKind.METHOD);
      expect(declaration.codeOffset, 68);
      expect(declaration.codeLength, 15);
    }
  }

  Future<void> test_fuzzyMatch() async {
    addTestFile(r'''
class MyClassFirst {}
class MyClassSecond {}
class OtherClass {}
''');
    await _getDeclarations(pattern: r'MyClass');

    assertHas('MyClassFirst', ElementKind.CLASS);
    assertHas('MyClassSecond', ElementKind.CLASS);
    assertNo('OtherClass');
  }

  Future<void> test_maxResults() async {
    newFile('$testPackageLibPath/a.dart', r'''
class MyClass1 {}
class MyClass2 {}
''').path;
    newFile('$testPackageLibPath/b.dart', r'''
class MyClass3 {}
class MyClass4 {}
''').path;

    // Limit to exactly one file.
    await _getDeclarations(pattern: r'MyClass', maxResults: 2);
    expect(declarationsResult.declarations, hasLength(2));

    // Limit in the middle of the second file.
    await _getDeclarations(pattern: r'MyClass', maxResults: 3);
    expect(declarationsResult.declarations, hasLength(3));

    // No limit.
    await _getDeclarations(pattern: r'MyClass');
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
    var a = newFile('$testPackageLibPath/a.dart', 'class A {}').path;
    var b = newFile('$testPackageLibPath/b.dart', 'class B {}').path;

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
    var a = newFile('$testPackageLibPath/a.dart', 'class A {}').path;
    newFile('$testPackageLibPath/b.dart', 'class B {}').path;

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

  /// Elements in part files should return paths of the definitions, not the
  /// parent library.
  Future<void> test_parts() async {
    var a = newFile('$testPackageLibPath/a.dart', "part 'b.dart';").path;
    var b = newFile('$testPackageLibPath/b.dart', '''
part of 'a.dart';
class A {}
''').path;

    await _getDeclarations(pattern: 'A');

    expect(declarationsResult.files, isNot(contains(a)));
    expect(declarationsResult.files, contains(b));

    var declaration =
        declarationsResult.declarations.singleWhere((d) => d.name == 'A');
    expect(declaration.name, 'A');
    expect(declaration.kind, ElementKind.CLASS);
    expect(declarationsResult.files[declaration.fileIndex], b);
    expect(declaration.offset, 24);
    expect(declaration.line, 2);
    expect(declaration.column, 7);
  }

  Future<void> test_top() async {
    addTestFile(r'''
int get g => 0;
void set s(_) {}
void f(int p) {}
int v;
typedef void tf1();
typedef tf2<T> = int Function<S>(T tp, S sp);
typedef td3 = double;
''');
    await _getDeclarations();

    assertHas('g', ElementKind.GETTER);
    assertHas('s', ElementKind.SETTER);
    assertHas('f', ElementKind.FUNCTION);
    assertHas('v', ElementKind.TOP_LEVEL_VARIABLE);
    assertHas('tf1', ElementKind.TYPE_ALIAS);
    assertHas('tf2', ElementKind.TYPE_ALIAS);
    assertHas('td3', ElementKind.TYPE_ALIAS);
  }

  Future<void> _getDeclarations(
      {String? file, String? pattern, int? maxResults}) async {
    var request = SearchGetElementDeclarationsParams(
            file: file, pattern: pattern, maxResults: maxResults)
        .toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);

    declarationsResult = SearchGetElementDeclarationsResult.fromResponse(
        response,
        clientUriConverter: server.uriConverter);
  }
}
