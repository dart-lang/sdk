// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionLiteralParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CollectionLiteralParserTest extends ParserDiagnosticsTest {
  void test_listLiteral_for() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  return [1, await for (var x in list) 2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithDeclaration
        loopVariable: DeclaredIdentifier
          keyword: var
          name: x
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_forIf() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  return [
    1,
    await for (var x in list)
      if (c) 2,
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithDeclaration
        loopVariable: DeclaredIdentifier
          keyword: var
          name: x
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: IfElement
        ifKeyword: if
        leftParenthesis: (
        expression: SimpleIdentifier
          token: c
        rightParenthesis: )
        thenElement: IntegerLiteral
          literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_forSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    for (int x = 0; x < 10; ++x) ...[2],
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    ForElement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithDeclarations
        variables: VariableDeclarationList
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: <
          rightOperand: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters
          PrefixExpression
            operator: ++
            operand: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: SpreadElement
        spreadOperator: ...
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_if() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [1, if (true) 2];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElse() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [1, if (true) 2 else 5];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement: IntegerLiteral
        literal: 5
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElseFor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [1, if (true) 2 else for (a in b) 5];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable: SimpleIdentifier
            token: b
        rightParenthesis: )
        body: IntegerLiteral
          literal: 5
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElseSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    if (true) ...[2] else ...?[5],
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 2
          rightBracket: ]
      elseKeyword: else
      elseElement: SpreadElement
        spreadOperator: ...?
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 5
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_ifFor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    if (true)
      for (a in b) 2,
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable: SimpleIdentifier
            token: b
        rightParenthesis: )
        body: IntegerLiteral
          literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_ifSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    if (true) ...[2],
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_spread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    ...[2],
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    SpreadElement
      spreadOperator: ...
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 2
        rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_spreadQ() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return [
    1,
    ...?[2],
  ];
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    SpreadElement
      spreadOperator: ...?
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 2
        rightBracket: ]
  rightBracket: ]
''');
  }

  void test_mapLiteral_for() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  return {1: 7, await for (y in list) 2: 3};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 7
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: y
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: MapLiteralEntry
        key: IntegerLiteral
          literal: 2
        separator: :
        value: IntegerLiteral
          literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_forIf() {
    var parseResult = parseStringWithErrors(r'''
void f() async {
  return {
    1: 7,
    await for (y in list)
      if (c) 2: 3,
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 7
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: y
        inKeyword: in
        iterable: SimpleIdentifier
          token: list
      rightParenthesis: )
      body: IfElement
        ifKeyword: if
        leftParenthesis: (
        expression: SimpleIdentifier
          token: c
        rightParenthesis: )
        thenElement: MapLiteralEntry
          key: IntegerLiteral
            literal: 2
          separator: :
          value: IntegerLiteral
            literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_forSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 7,
    for (x = 0; x < 10; ++x) ...{2: 3},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 7
    ForElement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithExpression
        initialization: AssignmentExpression
          leftHandSide: SimpleIdentifier
            token: x
          operator: =
          rightHandSide: IntegerLiteral
            literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: <
          rightOperand: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters
          PrefixExpression
            operator: ++
            operand: SimpleIdentifier
              token: x
      rightParenthesis: )
      body: SpreadElement
        spreadOperator: ...
        expression: SetOrMapLiteral
          leftBracket: {
          elements
            MapLiteralEntry
              key: IntegerLiteral
                literal: 2
              separator: :
              value: IntegerLiteral
                literal: 3
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_if() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {1: 1, if (true) 2: 4};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: MapLiteralEntry
        key: IntegerLiteral
          literal: 2
        separator: :
        value: IntegerLiteral
          literal: 4
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElse() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {1: 1, if (true) 2: 4 else 5: 6};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: MapLiteralEntry
        key: IntegerLiteral
          literal: 2
        separator: :
        value: IntegerLiteral
          literal: 4
      elseKeyword: else
      elseElement: MapLiteralEntry
        key: IntegerLiteral
          literal: 5
        separator: :
        value: IntegerLiteral
          literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElseFor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {1: 1, if (true) 2: 4 else for (c in d) 5: 6};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: MapLiteralEntry
        key: IntegerLiteral
          literal: 2
        separator: :
        value: IntegerLiteral
          literal: 4
      elseKeyword: else
      elseElement: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: c
          inKeyword: in
          iterable: SimpleIdentifier
            token: d
        rightParenthesis: )
        body: MapLiteralEntry
          key: IntegerLiteral
            literal: 5
          separator: :
          value: IntegerLiteral
            literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElseSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 7,
    if (true) ...{2: 4} else ...?{5: 6},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 7
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: SetOrMapLiteral
          leftBracket: {
          elements
            MapLiteralEntry
              key: IntegerLiteral
                literal: 2
              separator: :
              value: IntegerLiteral
                literal: 4
          rightBracket: }
          isMap: false
      elseKeyword: else
      elseElement: SpreadElement
        spreadOperator: ...?
        expression: SetOrMapLiteral
          leftBracket: {
          elements
            MapLiteralEntry
              key: IntegerLiteral
                literal: 5
              separator: :
              value: IntegerLiteral
                literal: 6
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifFor() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 1,
    if (true)
      for (a in b) 2: 4,
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable: SimpleIdentifier
            token: b
        rightParenthesis: )
        body: MapLiteralEntry
          key: IntegerLiteral
            literal: 2
          separator: :
          value: IntegerLiteral
            literal: 4
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 1,
    if (true) ...{2: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: SetOrMapLiteral
          leftBracket: {
          elements
            MapLiteralEntry
              key: IntegerLiteral
                literal: 2
              separator: :
              value: IntegerLiteral
                literal: 4
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 2,
    ...{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread2_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int, int>{
    1: 2,
    ...{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int, int>{
    ...{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1: 2,
    ...?{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...?
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ2_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int, int>{
    1: 2,
    ...?{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 1
      separator: :
      value: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...?
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int, int>{
    ...?{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...?
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_if() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {1, if (true) 2};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: IntegerLiteral
        literal: 2
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifElse() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {1, if (true) 2 else 5};
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement: IntegerLiteral
        literal: 5
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifElseSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1,
    if (true) ...{2} else ...?[5],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: SetOrMapLiteral
          leftBracket: {
          elements
            IntegerLiteral
              literal: 2
          rightBracket: }
          isMap: false
      elseKeyword: else
      elseElement: SpreadElement
        spreadOperator: ...?
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 5
          rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifSpread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    1,
    if (true) ...[2],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement: SpreadElement
        spreadOperator: ...
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    3,
    ...[4],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
    SpreadElement
      spreadOperator: ...
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 4
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread2Q() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    3,
    ...?[4],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
    SpreadElement
      spreadOperator: ...?
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 4
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int>{
    ...[3],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 3
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spreadQ_typed() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return <int>{
    ...?[3],
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...?
      expression: ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 3
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setOrMapLiteral_spread() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    ...{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_setOrMapLiteral_spreadQ() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  return {
    ...?{3: 4},
  };
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleReturnStatement.expression!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    SpreadElement
      spreadOperator: ...?
      expression: SetOrMapLiteral
        leftBracket: {
        elements
          MapLiteralEntry
            key: IntegerLiteral
              literal: 3
            separator: :
            value: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }
}
