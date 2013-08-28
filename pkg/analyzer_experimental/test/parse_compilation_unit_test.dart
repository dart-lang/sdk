// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_experimental/analyzer.dart';
import 'package:unittest/unittest.dart';

void main() {
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
          error.toString().contains("line 1 of test.dart");
    })));
  });

  test("defaults to '<unknown source>' if no name is provided", () {
    expect(() {
      parseCompilationUnit("void main() => print('Hello, world!')");
    }, throwsA(predicate((error) {
      return error is AnalyzerErrorGroup &&
          error.toString().contains("line 1 of <unknown source>");
    })));
  });
}
