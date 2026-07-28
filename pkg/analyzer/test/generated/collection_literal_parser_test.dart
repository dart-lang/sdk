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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  return [1, await for (var x in list) 2];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
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
        iterable2: SimpleIdentifier
          token: list
      rightParenthesis: )
      body2: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_forIf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  return [
    1,
    await for (var x in list)
      if (c) 2,
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
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
        iterable2: SimpleIdentifier
          token: list
      rightParenthesis: )
      body2: IfElement
        ifKeyword: if
        leftParenthesis: (
        expression2: SimpleIdentifier
          token: c
        rightParenthesis: )
        thenElement2: IntegerLiteral
          literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_forSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    for (int x = 0; x < 10; ++x) ...[2],
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
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
              initializer2: IntegerLiteral
                literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: <
          rightOperand2: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters2
          PrefixExpression
            operator: ++
            operand2: SimpleIdentifier
              token: x
      rightParenthesis: )
      body2: SpreadElement
        spreadOperator: ...
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [1, if (true) 2];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: IntegerLiteral
        literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElse() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [1, if (true) 2 else 5];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement2: IntegerLiteral
        literal: 5
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElseFor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [1, if (true) 2 else for (a in b) 5];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement2: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable2: SimpleIdentifier
            token: b
        rightParenthesis: )
        body2: IntegerLiteral
          literal: 5
  rightBracket: ]
''');
  }

  void test_listLiteral_ifElseSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    if (true) ...[2] else ...?[5],
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 2
          rightBracket: ]
      elseKeyword: else
      elseElement2: SpreadElement
        spreadOperator: ...?
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 5
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_ifFor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    if (true)
      for (a in b) 2,
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable2: SimpleIdentifier
            token: b
        rightParenthesis: )
        body2: IntegerLiteral
          literal: 2
  rightBracket: ]
''');
  }

  void test_listLiteral_ifSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    if (true) ...[2],
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_spread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    ...[2],
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    SpreadElement
      spreadOperator: ...
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 2
        rightBracket: ]
  rightBracket: ]
''');
  }

  void test_listLiteral_spreadQ() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return [
    1,
    ...?[2],
  ];
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements2
    IntegerLiteral
      literal: 1
    SpreadElement
      spreadOperator: ...?
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 2
        rightBracket: ]
  rightBracket: ]
''');
  }

  void test_mapLiteral_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  return {1: 7, await for (y in list) 2: 3};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 7
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: y
        inKeyword: in
        iterable2: SimpleIdentifier
          token: list
      rightParenthesis: )
      body2: MapLiteralEntry
        key2: IntegerLiteral
          literal: 2
        separator: :
        value2: IntegerLiteral
          literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_forIf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {
  return {
    1: 7,
    await for (y in list)
      if (c) 2: 3,
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 7
    ForElement
      awaitKeyword: await
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForEachPartsWithIdentifier
        identifier: SimpleIdentifier
          token: y
        inKeyword: in
        iterable2: SimpleIdentifier
          token: list
      rightParenthesis: )
      body2: IfElement
        ifKeyword: if
        leftParenthesis: (
        expression2: SimpleIdentifier
          token: c
        rightParenthesis: )
        thenElement2: MapLiteralEntry
          key2: IntegerLiteral
            literal: 2
          separator: :
          value2: IntegerLiteral
            literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_forSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 7,
    for (x = 0; x < 10; ++x) ...{2: 3},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 7
    ForElement
      forKeyword: for
      leftParenthesis: (
      forLoopParts: ForPartsWithExpression
        initialization2: AssignmentExpression
          leftHandSide2: SimpleIdentifier
            token: x
          operator: =
          rightHandSide2: IntegerLiteral
            literal: 0
        leftSeparator: ;
        condition: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: <
          rightOperand2: IntegerLiteral
            literal: 10
        rightSeparator: ;
        updaters2
          PrefixExpression
            operator: ++
            operand2: SimpleIdentifier
              token: x
      rightParenthesis: )
      body2: SpreadElement
        spreadOperator: ...
        expression2: SetOrMapLiteral
          leftBracket: {
          elements2
            MapLiteralEntry
              key2: IntegerLiteral
                literal: 2
              separator: :
              value2: IntegerLiteral
                literal: 3
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {1: 1, if (true) 2: 4};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: MapLiteralEntry
        key2: IntegerLiteral
          literal: 2
        separator: :
        value2: IntegerLiteral
          literal: 4
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElse() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {1: 1, if (true) 2: 4 else 5: 6};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: MapLiteralEntry
        key2: IntegerLiteral
          literal: 2
        separator: :
        value2: IntegerLiteral
          literal: 4
      elseKeyword: else
      elseElement2: MapLiteralEntry
        key2: IntegerLiteral
          literal: 5
        separator: :
        value2: IntegerLiteral
          literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElseFor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {1: 1, if (true) 2: 4 else for (c in d) 5: 6};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: MapLiteralEntry
        key2: IntegerLiteral
          literal: 2
        separator: :
        value2: IntegerLiteral
          literal: 4
      elseKeyword: else
      elseElement2: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: c
          inKeyword: in
          iterable2: SimpleIdentifier
            token: d
        rightParenthesis: )
        body2: MapLiteralEntry
          key2: IntegerLiteral
            literal: 5
          separator: :
          value2: IntegerLiteral
            literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifElseSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 7,
    if (true) ...{2: 4} else ...?{5: 6},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 7
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: SetOrMapLiteral
          leftBracket: {
          elements2
            MapLiteralEntry
              key2: IntegerLiteral
                literal: 2
              separator: :
              value2: IntegerLiteral
                literal: 4
          rightBracket: }
          isMap: false
      elseKeyword: else
      elseElement2: SpreadElement
        spreadOperator: ...?
        expression2: SetOrMapLiteral
          leftBracket: {
          elements2
            MapLiteralEntry
              key2: IntegerLiteral
                literal: 5
              separator: :
              value2: IntegerLiteral
                literal: 6
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifFor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 1,
    if (true)
      for (a in b) 2: 4,
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: ForElement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: a
          inKeyword: in
          iterable2: SimpleIdentifier
            token: b
        rightParenthesis: )
        body2: MapLiteralEntry
          key2: IntegerLiteral
            literal: 2
          separator: :
          value2: IntegerLiteral
            literal: 4
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_ifSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 1,
    if (true) ...{2: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: SetOrMapLiteral
          leftBracket: {
          elements2
            MapLiteralEntry
              key2: IntegerLiteral
                literal: 2
              separator: :
              value2: IntegerLiteral
                literal: 4
          rightBracket: }
          isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 2,
    ...{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread2_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int, int>{
    1: 2,
    ...{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
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
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spread_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int, int>{
    ...{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
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
  elements2
    SpreadElement
      spreadOperator: ...
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1: 2,
    ...?{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...?
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ2_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int, int>{
    1: 2,
    ...?{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
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
  elements2
    MapLiteralEntry
      key2: IntegerLiteral
        literal: 1
      separator: :
      value2: IntegerLiteral
        literal: 2
    SpreadElement
      spreadOperator: ...?
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_spreadQ_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int, int>{
    ...?{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
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
  elements2
    SpreadElement
      spreadOperator: ...?
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {1, if (true) 2};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: IntegerLiteral
        literal: 2
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifElse() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {1, if (true) 2 else 5};
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: IntegerLiteral
        literal: 2
      elseKeyword: else
      elseElement2: IntegerLiteral
        literal: 5
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifElseSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1,
    if (true) ...{2} else ...?[5],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: SetOrMapLiteral
          leftBracket: {
          elements2
            IntegerLiteral
              literal: 2
          rightBracket: }
          isMap: false
      elseKeyword: else
      elseElement2: SpreadElement
        spreadOperator: ...?
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 5
          rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_ifSpread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    1,
    if (true) ...[2],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 1
    IfElement
      ifKeyword: if
      leftParenthesis: (
      expression2: BooleanLiteral
        literal: true
      rightParenthesis: )
      thenElement2: SpreadElement
        spreadOperator: ...
        expression2: ListLiteral
          leftBracket: [
          elements2
            IntegerLiteral
              literal: 2
          rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    3,
    ...[4],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 3
    SpreadElement
      spreadOperator: ...
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 4
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread2Q() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    3,
    ...?[4],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    IntegerLiteral
      literal: 3
    SpreadElement
      spreadOperator: ...?
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 4
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spread_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int>{
    ...[3],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements2
    SpreadElement
      spreadOperator: ...
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 3
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_spreadQ_typed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return <int>{
    ...?[3],
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements2
    SpreadElement
      spreadOperator: ...?
      expression2: ListLiteral
        leftBracket: [
        elements2
          IntegerLiteral
            literal: 3
        rightBracket: ]
  rightBracket: }
  isMap: false
''');
  }

  void test_setOrMapLiteral_spread() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    ...{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    SpreadElement
      spreadOperator: ...
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_setOrMapLiteral_spreadQ() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return {
    ...?{3: 4},
  };
}
''');
    var node = parseResult.findNode.singleReturnStatement.expression2!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements2
    SpreadElement
      spreadOperator: ...?
      expression2: SetOrMapLiteral
        leftBracket: {
        elements2
          MapLiteralEntry
            key2: IntegerLiteral
              literal: 3
            separator: :
            value2: IntegerLiteral
              literal: 4
        rightBracket: }
        isMap: false
  rightBracket: }
  isMap: false
''');
  }
}
