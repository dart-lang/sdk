// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceRangesTest);
  });
}

@reflectiveTest
class SourceRangesTest extends AbstractSingleUnitTest {
  test_elementName() async {
    await resolveTestUnit('class ABC {}');
    Element element = findElement('ABC');
    expect(range.elementName(element), new SourceRange(6, 3));
  }

  test_endEnd() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.endEnd(mainName, mainBody), new SourceRange(4, 5));
  }

  test_endLength() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.endLength(mainName, 3), new SourceRange(4, 3));
  }

  test_endStart() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.endStart(mainName, mainBody), new SourceRange(4, 3));
  }

  test_error() {
    AnalysisError error =
        new AnalysisError(null, 10, 5, ParserErrorCode.CONST_CLASS, []);
    expect(range.error(error), new SourceRange(10, 5));
  }

  test_node() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.node(mainName), new SourceRange(0, 4));
  }

  test_nodes() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.nodes([mainName, mainBody]), new SourceRange(1, 9));
  }

  test_nodes_empty() async {
    await resolveTestUnit('main() {}');
    expect(range.nodes([]), new SourceRange(0, 0));
  }

  test_offsetBy() {
    expect(range.offsetBy(new SourceRange(7, 3), 2), new SourceRange(9, 3));
  }

  test_startEnd_nodeNode() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.startEnd(mainName, mainBody), new SourceRange(1, 9));
  }

  test_startLength_node() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.startLength(mainName, 10), new SourceRange(1, 10));
  }

  test_startOffsetEndOffset() {
    expect(range.startOffsetEndOffset(6, 11), new SourceRange(6, 5));
  }

  test_startStart_nodeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.startStart(mainName, mainBody), new SourceRange(0, 7));
  }

  test_token() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction = testUnit.declarations[0];
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.token(mainName.beginToken), new SourceRange(1, 4));
  }
}
