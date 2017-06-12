// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library test.services.correction.source_range;

import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceRangesTest);
  });
}

@reflectiveTest
class SourceRangesTest extends AbstractSingleUnitTest {
  test_rangeElementName() async {
    await resolveTestUnit('class ABC {}');
    Element element = findElement('ABC');
    expect(rangeElementName(element), new SourceRange(6, 3));
  }

  test_rangeEndEnd_nodeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeEndEnd(mainName, mainBody), new SourceRange(4, 5));
  }

  test_rangeEndStart_nodeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeEndStart(mainName, mainBody), new SourceRange(4, 3));
  }

  void test_rangeError() {
    AnalysisError error =
        new AnalysisError(null, 10, 5, ParserErrorCode.CONST_CLASS, []);
    expect(rangeError(error), new SourceRange(10, 5));
  }

  test_rangeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeNode(mainName), new SourceRange(0, 4));
  }

  test_rangeNodes() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeNodes([mainName, mainBody]), new SourceRange(1, 9));
  }

  test_rangeNodes_empty() async {
    await resolveTestUnit('main() {}');
    expect(rangeNodes([]), new SourceRange(0, 0));
  }

  void test_rangeStartEnd_intInt() {
    expect(rangeStartEnd(10, 25), new SourceRange(10, 15));
  }

  test_rangeStartEnd_nodeNode() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeStartEnd(mainName, mainBody), new SourceRange(1, 9));
  }

  void test_rangeStartLength_int() {
    expect(rangeStartLength(5, 10), new SourceRange(5, 10));
  }

  test_rangeStartLength_node() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeStartLength(mainName, 10), new SourceRange(1, 10));
  }

  void test_rangeStartStart_intInt() {
    expect(rangeStartStart(10, 25), new SourceRange(10, 15));
  }

  test_rangeStartStart_nodeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeStartStart(mainName, mainBody), new SourceRange(0, 7));
  }

  test_rangeToken() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeToken(mainName.beginToken), new SourceRange(1, 4));
  }
}
