// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

main() {
  Map<Expression, DeferredExpression> map = {};
  VariableUse variableUse = new VariableUse('variable');
  DeferredExpression deferred =
      map[variableUse] = new _DeferredExpression(variableUse);
  VariableUse variableUseAlias = new VariableUse('variable');
  map[variableUseAlias] = new _DeferredExpression(variableUseAlias);

  map[deferred] = new _DeferredExpression(deferred);
  Literal literal = new LiteralString('"literal"');
  map[literal] = new _DeferredExpression(literal);

  test(map, '#', [variableUse], 'variable');
  test(map, '#', [deferred], 'variable');
  test(map, '{#: #}', [literal, variableUse], '{literal: variable}');
  test(map, '{#: #}', [literal, deferred], '{literal: variable}');
  test(map, '#.#', [variableUse, literal], 'variable.literal');
  test(map, '#.#', [deferred, literal], 'variable.literal');
  test(map, '# = # + 1', [variableUse, variableUseAlias], '++variable');
  test(map, '# = # + 1', [deferred, variableUseAlias], '++variable');
  test(map, '# = # - 1', [variableUse, variableUseAlias], '--variable');
  test(map, '# = # - 1', [deferred, variableUseAlias], '--variable');
  test(map, '# = # + 2', [variableUse, variableUseAlias], 'variable += 2');
  test(map, '# = # + 2', [deferred, variableUseAlias], 'variable += 2');
  test(map, '# = # * 2', [variableUse, variableUseAlias], 'variable *= 2');
  test(map, '# = # * 2', [deferred, variableUseAlias], 'variable *= 2');

  test(map, '# += # + 1', [variableUse, variableUseAlias],
      'variable += variable + 1');
  test(map, '# += # + 1', [deferred, variableUseAlias],
      'variable += variable + 1');
  test(map, '# += # - 1', [variableUse, variableUseAlias],
      'variable += variable - 1');
  test(map, '# += # - 1', [deferred, variableUseAlias],
      'variable += variable - 1');
  test(map, '# += # + 2', [variableUse, variableUseAlias],
      'variable += variable + 2');
  test(map, '# += # + 2', [deferred, variableUseAlias],
      'variable += variable + 2');
  test(map, '# += # * 2', [variableUse, variableUseAlias],
      'variable += variable * 2');
  test(map, '# += # * 2', [deferred, variableUseAlias],
      'variable += variable * 2');
}

void test(Map<Expression, DeferredExpression> map, String template,
    List<Expression> arguments, String expectedOutput) {
  Expression directExpression =
      js.expressionTemplateFor(template).instantiate(arguments);
  _Context directContext = new _Context();
  Printer directPrinter =
      new Printer(const JavaScriptPrintingOptions(), directContext);
  directPrinter.visit(directExpression);
  Expect.equals(expectedOutput, directContext.text);

  Expression deferredExpression = js
      .expressionTemplateFor(template)
      .instantiate(arguments.map((e) => map[e]).toList());
  _Context deferredContext = new _Context();
  Printer deferredPrinter =
      new Printer(const JavaScriptPrintingOptions(), deferredContext);
  deferredPrinter.visit(deferredExpression);
  Expect.equals(expectedOutput, deferredContext.text);

  for (Expression argument in arguments) {
    DeferredExpression deferred = map[argument];
    Expect.isTrue(
        directContext.enterPositions.containsKey(argument),
        "Argument ${DebugPrint(argument)} not found in direct enter positions: "
        "${directContext.enterPositions.keys}");
    Expect.isTrue(
        deferredContext.enterPositions.containsKey(argument),
        "Argument ${DebugPrint(argument)} not found in "
        "deferred enter positions: "
        "${deferredContext.enterPositions.keys}");
    Expect.isTrue(
        deferredContext.enterPositions.containsKey(deferred),
        "Argument ${DebugPrint(deferred)} not found in "
        "deferred enter positions: "
        "${deferredContext.enterPositions.keys}");
    Expect.equals(directContext.enterPositions[argument],
        deferredContext.enterPositions[argument]);
    Expect.equals(directContext.enterPositions[argument],
        deferredContext.enterPositions[deferred]);

    Expect.isTrue(
        directContext.exitPositions.containsKey(argument),
        "Argument ${DebugPrint(argument)} not found in direct enter positions: "
        "${directContext.exitPositions.keys}");
    Expect.isTrue(
        deferredContext.exitPositions.containsKey(argument),
        "Argument ${DebugPrint(argument)} not found in "
        "deferred enter positions: "
        "${deferredContext.exitPositions.keys}");
    Expect.isTrue(
        deferredContext.exitPositions.containsKey(deferred),
        "Argument ${DebugPrint(deferred)} not found in "
        "deferred enter positions: "
        "${deferredContext.exitPositions.keys}");
    Expect.equals(directContext.exitPositions[argument],
        deferredContext.exitPositions[argument]);
    Expect.equals(directContext.exitPositions[argument],
        deferredContext.exitPositions[deferred]);
  }
}

class _DeferredExpression extends DeferredExpression {
  final Expression value;

  _DeferredExpression(this.value);

  @override
  int get precedenceLevel => value.precedenceLevel;
}

class _Context implements JavaScriptPrintingContext {
  StringBuffer sb = new StringBuffer();
  List<String> errors = [];
  Map<Node, int> enterPositions = {};
  Map<Node, _Position> exitPositions = {};

  @override
  void emit(String string) {
    sb.write(string);
  }

  @override
  void enterNode(Node node, int startPosition) {
    enterPositions[node] = startPosition;
  }

  @override
  void exitNode(
      Node node, int startPosition, int endPosition, int closingPosition) {
    exitPositions[node] =
        new _Position(startPosition, endPosition, closingPosition);
    Expect.equals(enterPositions[node], startPosition);
  }

  @override
  void error(String message) {
    errors.add(message);
  }

  String get text => sb.toString();
}

class _Position {
  final int startPosition;
  final int endPosition;
  final int closingPosition;

  _Position(this.startPosition, this.endPosition, this.closingPosition);

  int get hashCode =>
      13 * startPosition.hashCode +
      17 * endPosition.hashCode +
      19 * closingPosition.hashCode;

  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Position &&
        startPosition == other.startPosition &&
        endPosition == other.endPosition &&
        closingPosition == other.closingPosition;
  }

  String toString() {
    return '_Position(start=$startPosition,'
        'end=$endPosition,closing=$closingPosition)';
  }
}
