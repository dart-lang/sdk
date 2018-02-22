// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclarationsTest);
  });
}

@reflectiveTest
class DeclarationsTest extends AbstractSearchDomainTest {
  SearchGetElementDeclarationsResult declarationsResult;

  void assertHas(String name, ElementKind kind, {String className}) {
    declarationsResult.declarations.singleWhere((d) =>
        declarationsResult.files[d.fileIndex] == testFile &&
        d.name == name &&
        d.kind == kind &&
        d.className == className);
  }

  test_class() async {
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
    assertHas('s', ElementKind.SETTER, className: 'C');
    assertHas('m', ElementKind.METHOD, className: 'C');
  }

  test_enum() async {
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

  test_multipleFiles() async {
    var a = newFile(join(testFolder, 'a.dart'), content: 'class A {}').path;
    var b = newFile(join(testFolder, 'b.dart'), content: 'class B {}').path;

    Request request = new SearchGetElementDeclarationsParams().toRequest('0');
    Response response = await waitResponse(request);

    var result = new SearchGetElementDeclarationsResult.fromResponse(response);

    expect(result.files, contains(a));
    expect(result.files, contains(b));

    {
      ElementDeclaration declaration =
          result.declarations.singleWhere((d) => d.name == 'A');
      expect(declaration.name, 'A');
      expect(declaration.kind, ElementKind.CLASS);
      expect(result.files[declaration.fileIndex], a);
      expect(declaration.offset, 6);
      expect(declaration.line, 1);
      expect(declaration.column, 7);
    }

    {
      ElementDeclaration declaration =
          result.declarations.singleWhere((d) => d.name == 'B');
      expect(declaration.name, 'B');
      expect(declaration.kind, ElementKind.CLASS);
      expect(result.files[declaration.fileIndex], b);
    }
  }

  test_top() async {
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

  Future<Null> _getDeclarations() async {
    Request request = new SearchGetElementDeclarationsParams().toRequest('0');
    Response response = await waitResponse(request);

    declarationsResult =
        new SearchGetElementDeclarationsResult.fromResponse(response);
  }
}
