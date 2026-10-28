// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeLocator2Test);
    defineReflectiveTests(ScopedNameFinder2Test);
    // ignore: analyzer_v1_ast_use
    defineReflectiveTests(ScopedNameFinderTest);
  });
}

@reflectiveTest
class NodeLocator2Test extends ParserDiagnosticsTest {
  AstNode? locate(CompilationUnit unit, int start, [int? end]) {
    var locator = NodeLocator2(start, end);
    var node = locator.searchWithin(unit)!;
    return node;
  }

  void test_onlyStartOffset() {
    var code = ' f() {} ';
    //             01234567
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var function = unit.declarations2.single as TopLevelFunctionDeclaration;
    var body = function.body as BlockFunctionBody;
    expect(NodeLocator2(0).searchWithin(unit), same(unit));
    expect(NodeLocator2(1).searchWithin(unit), same(function));
    expect(NodeLocator2(2).searchWithin(unit), same(function));
    expect(NodeLocator2(3).searchWithin(unit), same(function.formalParameters));
    expect(NodeLocator2(4).searchWithin(unit), same(function));
    expect(NodeLocator2(5).searchWithin(unit), same(body.block));
    expect(NodeLocator2(6).searchWithin(unit), same(body.block));
    expect(NodeLocator2(7).searchWithin(unit), same(unit));
    expect(NodeLocator2(100).searchWithin(unit), isNull);
  }

  void test_searchWithin_class_afterName_beforeTypeParameters() {
    var source = r'''
class A<T> {}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('<T> {}'));
    expect(node, isA<ClassDeclaration2>());
  }

  void test_searchWithin_constructor_afterName_beforeParameters() {
    var source = r'''
class A {
  A() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    // TODO(dantup): Update these tests to use markers.
    var node = _assertLocate(unit, source.indexOf('() {}'));
    expect(node, isA<ConstructorDeclaration2>());
  }

  void test_searchWithin_function_afterName_beforeParameters() {
    var source = r'''
void f() {}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('() {}'));
    expect(node, isA<TopLevelFunctionDeclaration>());
  }

  void test_searchWithin_function_afterName_beforeTypeParameters() {
    var source = r'''
void f<T>() {}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('<T>() {}'));
    expect(node, isA<TopLevelFunctionDeclaration>());
  }

  void test_searchWithin_method_afterName_beforeParameters() {
    var source = r'''
class A {
  void m() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('() {}'));
    expect(node, isA<MethodDeclaration2>());
  }

  void test_searchWithin_method_afterName_beforeTypeParameters() {
    var source = r'''
class A {
  void m<T>() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('<T>() {}'));
    expect(node, isA<MethodDeclaration2>());
  }

  void test_searchWithin_namedConstructor_afterName_beforeParameters() {
    var source = r'''
class A {
  A.c() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('() {}'));
    expect(node, isA<ConstructorDeclaration2>());
  }

  void test_searchWithin_setter_afterName_beforeParameters() {
    var source = r'''
set s(int i) {}
''';
    var unit = parseTestCodeWithDiagnostics(source).unit;
    var node = _assertLocate(unit, source.indexOf('(int i)'));
    expect(node, isA<TopLevelSetterDeclaration>());
  }

  void test_startEndOffset() {
    var code = ' f() {} ';
    //             01234567
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var function = unit.declarations2.single as TopLevelFunctionDeclaration;
    expect(NodeLocator2(-1, 2).searchWithin(unit), isNull);
    expect(NodeLocator2(0, 2).searchWithin(unit), same(unit));
    expect(NodeLocator2(1, 2).searchWithin(unit), same(function));
    expect(NodeLocator2(1, 3).searchWithin(unit), same(function));
    expect(NodeLocator2(1, 4).searchWithin(unit), same(function));
    expect(NodeLocator2(5, 7).searchWithin(unit), same(unit));
    expect(NodeLocator2(5, 100).searchWithin(unit), isNull);
    expect(NodeLocator2(100, 200).searchWithin(unit), isNull);
  }

  AstNode _assertLocate(CompilationUnit unit, int start, [int? end]) {
    end ??= start;
    var node = locate(unit, start, end)!;
    expect(node.offset <= start, isTrue, reason: "Node starts after range");
    expect(
      node.offset + node.length > end,
      isTrue,
      reason: "Node ends before range",
    );
    return node;
  }
}

@reflectiveTest
class ScopedNameFinder2Test extends ParserDiagnosticsTest {
  void test_constructorInvocation() {
    var code = '''
void f(int parameter) {
  var local = 0;
  new C();
  var after = 1;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations2.single));
  }

  void test_localFunction() {
    var code = '''
void f() {
  void g() {}
  new C();
  void h() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'g'});
    expect(finder.declaration, same(unit.declarations2.single));
  }

  void test_switchMember() {
    var code = '''
void f(int x) {
  switch (x) {
    case 0:
      var local = 0;
      new C();
      var after = 1;
  }
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'x', 'local'});
    expect(finder.declaration, same(unit.declarations2.single));
  }

  void test_topLevelGetter() {
    var code = '''
int get foo {
  var local = 0;
  new C();
  return local;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'local'});
    expect(finder.declaration, same(unit.declarations2.single));
  }

  void test_topLevelGetter_recoveryFormalParameters() {
    var code = '''
int get foo(int parameter) {
//         ^
// [diag.getterWithParameters] Getters must be declared without a parameter list.
  var local = 0;
  new C();
  return local;
}
''';
    var result = parseTestCodeWithDiagnostics(code);
    var unit = result.unit;
    var offset = result.content.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations2.single));
  }

  void test_topLevelSetter() {
    var code = '''
set foo(int parameter) {
  var local = 0;
  new C();
  var after = 1;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering2(offset: offset, length: 7)!;

    var finder = ScopedNameFinder2(offset);
    node.accept2(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations2.single));
  }
}

@reflectiveTest
@V1Ast('The V2 counterpart is ScopedNameFinder2Test.')
class ScopedNameFinderTest extends ParserDiagnosticsTest {
  void test_constructorInvocation() {
    var code = '''
void f(int parameter) {
  var local = 0;
  new C();
  var after = 1;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations.single));
  }

  void test_localFunction() {
    var code = '''
void f() {
  void g() {}
  new C();
  void h() {}
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'g'});
    expect(finder.declaration, same(unit.declarations.single));
  }

  void test_switchMember() {
    var code = '''
void f(int x) {
  switch (x) {
    case 0:
      var local = 0;
      new C();
      var after = 1;
  }
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'x', 'local'});
    expect(finder.declaration, same(unit.declarations.single));
  }

  void test_topLevelGetter() {
    var code = '''
int get foo {
  var local = 0;
  new C();
  return local;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'local'});
    expect(finder.declaration, same(unit.declarations.single));
  }

  void test_topLevelGetter_recoveryFormalParameters() {
    var code = '''
int get foo(int parameter) {
//         ^
// [diag.getterWithParameters] Getters must be declared without a parameter list.
  var local = 0;
  new C();
  return local;
}
''';
    var result = parseTestCodeWithDiagnostics(code);
    var unit = result.unit;
    var offset = result.content.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations.single));
  }

  void test_topLevelSetter() {
    var code = '''
set foo(int parameter) {
  var local = 0;
  new C();
  var after = 1;
}
''';
    var unit = parseTestCodeWithDiagnostics(code).unit;
    var offset = code.indexOf('new C();');
    var node = unit.nodeCovering(offset: offset, length: 7)!;

    var finder = ScopedNameFinder(offset);
    node.accept(finder);

    expect(finder.locals, {'parameter', 'local'});
    expect(finder.declaration, same(unit.declarations.single));
  }
}
