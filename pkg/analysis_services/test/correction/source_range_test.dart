// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.source_range;

import 'package:analysis_services/src/correction/source_range.dart';
import 'package:analysis_testing/abstract_single_unit.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart' hide isEmpty;


main() {
  groupSep = ' | ';
  runReflectiveTests(SourceRangesTest);
}


@ReflectiveTestCase()
class SourceRangesTest extends AbstractSingleUnitTest {
  void test_rangeElementName() {
    resolveTestUnit('class ABC {}');
    Element element = findElement('ABC');
    expect(rangeElementName(element), new SourceRange(6, 3));
  }

  void test_rangeEndEnd_nodeNode() {
    resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeEndEnd(mainName, mainBody), new SourceRange(4, 5));
  }

  void test_rangeEndStart_nodeNode() {
    resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeEndStart(mainName, mainBody), new SourceRange(4, 3));
  }

  void test_rangeError() {
    AnalysisError error =
        new AnalysisError.con2(null, 10, 5, ParserErrorCode.CONST_CLASS, []);
    expect(rangeError(error), new SourceRange(10, 5));
  }

  void test_rangeNode() {
    resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeNode(mainName), new SourceRange(0, 4));
  }

  void test_rangeNodes() {
    resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeNodes([mainName, mainBody]), new SourceRange(1, 9));
  }

  void test_rangeNodes_empty() {
    resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeNodes([]), new SourceRange(0, 0));
  }

  void test_rangeStartEnd_intInt() {
    expect(rangeStartEnd(10, 25), new SourceRange(10, 15));
  }

  void test_rangeStartEnd_nodeNode() {
    resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeStartEnd(mainName, mainBody), new SourceRange(1, 9));
  }

  void test_rangeStartLength_int() {
    expect(rangeStartLength(5, 10), new SourceRange(5, 10));
  }

  void test_rangeStartLength_node() {
    resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeStartLength(mainName, 10), new SourceRange(1, 10));
  }

  void test_rangeStartStart_intInt() {
    expect(rangeStartStart(10, 25), new SourceRange(10, 15));
  }

  void test_rangeStartStart_nodeNode() {
    resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(rangeStartStart(mainName, mainBody), new SourceRange(0, 7));
  }

  void test_rangeToken() {
    resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(rangeToken(mainName.beginToken), new SourceRange(1, 4));
  }
}
