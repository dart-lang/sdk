// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: deprecated_member_use_from_same_package
import 'package:analyzer/analyzer.dart';
import 'package:test/test.dart';

void main() {
  test("parses a valid compilation unit successfully", () {
    // ignore: deprecated_member_use_from_same_package
    var unit = parseCompilationUnit("void main() => print('Hello, world!');");
    expect(unit.toString(), equals("void main() => print('Hello, world!');"));
  });

  group('Supports spread collections', () {
    var contents = 'var x = [...[]];';
    void checkCompilationUnit(CompilationUnit unit) {
      var declaration = unit.declarations.single as TopLevelVariableDeclaration;
      var listLiteral =
          declaration.variables.variables.single.initializer as ListLiteral;
      var spread = listLiteral.elements.single as SpreadElement;
      expect(spread.expression, TypeMatcher<ListLiteral>());
    }

    test('with errors suppressed', () {
      checkCompilationUnit(
          // ignore: deprecated_member_use_from_same_package
          parseCompilationUnit(contents, suppressErrors: true));
    });
    test('with errors enabled', () {
      // ignore: deprecated_member_use_from_same_package
      checkCompilationUnit(parseCompilationUnit(contents));
    });
  });

  group('Supports control flow collections', () {
    var contents = 'var x = [if (true) 0 else "foo"];';
    void checkCompilationUnit(CompilationUnit unit) {
      var declaration = unit.declarations.single as TopLevelVariableDeclaration;
      var listLiteral =
          declaration.variables.variables.single.initializer as ListLiteral;
      var ifElement = listLiteral.elements.single as IfElement;
      expect(ifElement.condition, TypeMatcher<BooleanLiteral>());
      expect(ifElement.thenElement, TypeMatcher<IntegerLiteral>());
      expect(ifElement.elseElement, TypeMatcher<StringLiteral>());
    }

    test('with errors suppressed', () {
      checkCompilationUnit(
          // ignore: deprecated_member_use_from_same_package
          parseCompilationUnit(contents, suppressErrors: true));
    });
    test('with errors enabled', () {
      // ignore: deprecated_member_use_from_same_package
      checkCompilationUnit(parseCompilationUnit(contents));
    });
  });

  test("throws errors for an invalid compilation unit", () {
    expect(() {
      // ignore: deprecated_member_use_from_same_package
      parseCompilationUnit("void main() => print('Hello, world!')",
          name: 'test.dart');
    }, throwsA(predicate((error) {
      return error is AnalyzerErrorGroup &&
          error.toString().contains("Error in test.dart: Expected to find ';'");
    })));
  });

  test("defaults to '<unknown source>' if no name is provided", () {
    expect(() {
      // ignore: deprecated_member_use_from_same_package
      parseCompilationUnit("void main() => print('Hello, world!')");
    }, throwsA(predicate((error) {
      return error is AnalyzerErrorGroup &&
          error
              .toString()
              .contains("Error in <unknown source>: Expected to find ';'");
    })));
  });

  test("allows you to specify whether or not to parse function bodies", () {
    // ignore: deprecated_member_use_from_same_package
    var unit = parseCompilationUnit("void main() => print('Hello, world!');",
        parseFunctionBodies: false);
    expect(unit.toString(), equals("void main();"));
  });

  test("allows you to specify whether or not to parse function bodies 2", () {
    // ignore: deprecated_member_use_from_same_package
    var unit = parseCompilationUnit("void main() { print('Hello, world!'); }",
        parseFunctionBodies: false);
    expect(unit.toString(), equals("void main();"));
  });
}
