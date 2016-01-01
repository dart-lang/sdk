// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.parse_compilation_unit_test;

import 'package:analyzer/analyzer.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  initializeTestEnvironment();
  test("parses a valid compilation unit successfully", () {
    var unit = parseCompilationUnit("void main() => print('Hello, world!');");
    expect(unit.toString(), equals("void main() => print('Hello, world!');"));
  });

  test("throws errors for an invalid compilation unit", () {
    expect(() {
      parseCompilationUnit("void main() => print('Hello, world!')",
          name: 'test.dart');
    }, throwsA(predicate((error) {
      return error is AnalyzerErrorGroup &&
          error.toString().contains("Error in test.dart: Expected to find ';'");
    })));
  });

  test("defaults to '<unknown source>' if no name is provided", () {
    expect(() {
      parseCompilationUnit("void main() => print('Hello, world!')");
    }, throwsA(predicate((error) {
      return error is AnalyzerErrorGroup &&
          error
              .toString()
              .contains("Error in <unknown source>: Expected to find ';'");
    })));
  });

  test("allows you to specify whether or not to parse function bodies", () {
    var unit = parseCompilationUnit("void main() => print('Hello, world!');",
        parseFunctionBodies: false);
    expect(unit.toString(), equals("void main();"));
  });
}
