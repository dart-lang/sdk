// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

/// Visitor that computes whether two [Node]s are structurally equivalent.
class EquivalenceVisitor implements NodeVisitor1<bool, Node> {
  const EquivalenceVisitor();

  /// Called when [node1] and [node2] are not equivalent.
  ///
  /// Override this to collect or report information on the inequivalent nodes.
  bool failAt(Node node1, Node node2) => false;

  /// Returns whether the non-node values [value1] and [value2] are equivalent.
  bool testValues(Node node1, Object value1, Node node2, Object value2) =>
      value1 == value2;

  /// Returns whether the labels [label1] and [label2] are equivalent.
  bool testLabels(Node node1, String label1, Node node2, String label2) =>
      label1 == label2;

  bool testNodes(Node node1, Node node2) {
    if (identical(node1, node2)) return true;
    if (node1 == null || node2 == null) return failAt(node1, node2);
    return node1.accept1(this, node2);
  }

  bool testNodeLists(List<Node> list1, List<Node> list2) {
    int index = 0;
    while (index < list1.length && index < list2.length) {
      if (!testNodes(list1[index], list2[index])) return false;
      index++;
    }
    if (index < list1.length) {
      return failAt(list1[index], null);
    } else if (index < list2.length) {
      return failAt(list2[index], null);
    }
    return true;
  }

  @override
  bool visitProgram(Program node, Node arg) {
    if (arg is! Program) return failAt(node, arg);
    Program other = arg;
    return testNodeLists(node.body, other.body);
  }

  @override
  bool visitInterpolatedDeclaration(InterpolatedDeclaration node, Node arg) {
    if (arg is! InterpolatedDeclaration) return failAt(node, arg);
    InterpolatedDeclaration other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitInterpolatedStatement(InterpolatedStatement node, Node arg) {
    if (arg is! InterpolatedStatement) return failAt(node, arg);
    InterpolatedStatement other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitInterpolatedSelector(InterpolatedSelector node, Node arg) {
    if (arg is! InterpolatedSelector) return failAt(node, arg);
    InterpolatedSelector other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitInterpolatedParameter(InterpolatedParameter node, Node arg) {
    if (arg is! InterpolatedParameter) return failAt(node, arg);
    InterpolatedParameter other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitInterpolatedLiteral(InterpolatedLiteral node, Node arg) {
    if (arg is! InterpolatedLiteral) return failAt(node, arg);
    InterpolatedLiteral other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitInterpolatedExpression(InterpolatedExpression node, Node arg) {
    if (arg is! InterpolatedExpression) return failAt(node, arg);
    InterpolatedExpression other = arg;
    return testValues(node, node.nameOrPosition, other, other.nameOrPosition);
  }

  @override
  bool visitComment(Comment node, Node arg) {
    if (arg is! Comment) return failAt(node, arg);
    Comment other = arg;
    return testValues(node, node.comment, other, other.comment);
  }

  @override
  bool visitAwait(Await node, Node arg) {
    if (arg is! Await) return failAt(node, arg);
    Await other = arg;
    return testNodes(node.expression, other.expression);
  }

  @override
  bool visitRegExpLiteral(RegExpLiteral node, Node arg) {
    if (arg is! RegExpLiteral) return failAt(node, arg);
    RegExpLiteral other = arg;
    return testValues(node, node.pattern, other, other.pattern);
  }

  @override
  bool visitProperty(Property node, Node arg) {
    if (arg is! Property) return failAt(node, arg);
    Property other = arg;
    return testNodes(node.name, other.name) &&
        testNodes(node.value, other.value);
  }

  @override
  bool visitObjectInitializer(ObjectInitializer node, Node arg) {
    if (arg is! ObjectInitializer) return failAt(node, arg);
    ObjectInitializer other = arg;
    return testNodeLists(node.properties, other.properties);
  }

  @override
  bool visitArrayHole(ArrayHole node, Node arg) {
    if (arg is! ArrayHole) return failAt(node, arg);
    return true;
  }

  @override
  bool visitArrayInitializer(ArrayInitializer node, Node arg) {
    if (arg is! ArrayInitializer) return failAt(node, arg);
    ArrayInitializer other = arg;
    return testNodeLists(node.elements, other.elements);
  }

  @override
  bool visitName(Name node, Node arg) {
    if (arg is! Name) return failAt(node, arg);
    Name other = arg;
    return testValues(node, node.key, other, other.key);
  }

  @override
  bool visitStringConcatenation(StringConcatenation node, Node arg) {
    if (arg is! StringConcatenation) return failAt(node, arg);
    StringConcatenation other = arg;
    return testNodeLists(node.parts, other.parts);
  }

  @override
  bool visitLiteralNull(LiteralNull node, Node arg) {
    if (arg is! LiteralNull) return failAt(node, arg);
    return true;
  }

  @override
  bool visitLiteralNumber(LiteralNumber node, Node arg) {
    if (arg is! LiteralNumber) return failAt(node, arg);
    LiteralNumber other = arg;
    return testValues(node, node.value, other, other.value);
  }

  @override
  bool visitLiteralString(LiteralString node, Node arg) {
    if (arg is! LiteralString) return failAt(node, arg);
    LiteralString other = arg;
    return testValues(node, node.value, other, other.value);
  }

  @override
  bool visitLiteralBool(LiteralBool node, Node arg) {
    if (arg is! LiteralBool) return failAt(node, arg);
    LiteralBool other = arg;
    return testValues(node, node.value, other, other.value);
  }

  @override
  bool visitDeferredString(DeferredString node, Node arg) {
    if (arg is! DeferredString) return failAt(node, arg);
    DeferredString other = arg;
    return testValues(node, node.value, other, other.value);
  }

  @override
  bool visitDeferredNumber(DeferredNumber node, Node arg) {
    if (arg is! DeferredNumber) return failAt(node, arg);
    DeferredNumber other = arg;
    return testValues(node, node.value, other, other.value);
  }

  @override
  bool visitDeferredExpression(DeferredExpression node, Node arg) {
    if (arg is! DeferredExpression) return failAt(node, arg);
    DeferredExpression other = arg;
    return testNodes(node.value, other.value);
  }

  @override
  bool visitFun(Fun node, Node arg) {
    if (arg is! Fun) return failAt(node, arg);
    Fun other = arg;
    return testNodeLists(node.params, other.params) &&
        testNodes(node.body, other.body) &&
        testValues(node, node.asyncModifier, other, other.asyncModifier);
  }

  @override
  bool visitNamedFunction(NamedFunction node, Node arg) {
    if (arg is! NamedFunction) return failAt(node, arg);
    NamedFunction other = arg;
    return testNodes(node.name, other.name) &&
        testNodes(node.function, other.function);
  }

  @override
  bool visitAccess(PropertyAccess node, Node arg) {
    if (arg is! PropertyAccess) return failAt(node, arg);
    PropertyAccess other = arg;
    return testNodes(node.receiver, other.receiver) &&
        testNodes(node.selector, other.selector);
  }

  @override
  bool visitParameter(Parameter node, Node arg) {
    if (arg is! Parameter) return failAt(node, arg);
    Parameter other = arg;
    return testValues(node, node.name, other, other.name);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node, Node arg) {
    if (arg is! VariableDeclaration) return failAt(node, arg);
    VariableDeclaration other = arg;
    return testValues(node, node.name, other, other.name) &&
        testValues(node, node.allowRename, other, other.allowRename);
  }

  @override
  bool visitThis(This node, Node arg) {
    if (arg is! This) return failAt(node, arg);
    return true;
  }

  @override
  bool visitVariableUse(VariableUse node, Node arg) {
    if (arg is! VariableUse) return failAt(node, arg);
    VariableUse other = arg;
    return testValues(node, node.name, other, other.name);
  }

  @override
  bool visitPostfix(Postfix node, Node arg) {
    if (arg is! Postfix) return failAt(node, arg);
    Postfix other = arg;
    return testValues(node, node.op, other, other.op) &&
        testNodes(node.argument, other.argument);
  }

  @override
  bool visitPrefix(Prefix node, Node arg) {
    if (arg is! Prefix) return failAt(node, arg);
    Prefix other = arg;
    return testValues(node, node.op, other, other.op) &&
        testNodes(node.argument, other.argument);
  }

  @override
  bool visitBinary(Binary node, Node arg) {
    if (arg is! Binary) return failAt(node, arg);
    Binary other = arg;
    return testNodes(node.left, other.left) &&
        testValues(node, node.op, other, other.op) &&
        testNodes(node.right, other.right);
  }

  @override
  bool visitCall(Call node, Node arg) {
    if (arg is! Call) return failAt(node, arg);
    Call other = arg;
    return testNodes(node.target, other.target) &&
        testNodeLists(node.arguments, other.arguments);
  }

  @override
  bool visitNew(New node, Node arg) {
    if (arg is! New) return failAt(node, arg);
    New other = arg;
    return testNodes(node.target, other.target) &&
        testNodeLists(node.arguments, other.arguments);
  }

  @override
  bool visitConditional(Conditional node, Node arg) {
    if (arg is! Conditional) return failAt(node, arg);
    Conditional other = arg;
    return testNodes(node.condition, other.condition) &&
        testNodes(node.then, other.then) &&
        testNodes(node.otherwise, other.otherwise);
  }

  @override
  bool visitVariableInitialization(VariableInitialization node, Node arg) {
    if (arg is! VariableInitialization) return failAt(node, arg);
    VariableInitialization other = arg;
    return testNodes(node.declaration, other.declaration) &&
        testNodes(node.leftHandSide, other.leftHandSide) &&
        testValues(node, node.op, other, other.op) &&
        testNodes(node.value, other.value);
  }

  @override
  bool visitAssignment(Assignment node, Node arg) {
    if (arg is! Assignment) return failAt(node, arg);
    Assignment other = arg;
    return testNodes(node.leftHandSide, other.leftHandSide) &&
        testValues(node, node.op, other, other.op) &&
        testNodes(node.value, other.value);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node, Node arg) {
    if (arg is! VariableDeclarationList) return failAt(node, arg);
    VariableDeclarationList other = arg;
    return testNodeLists(node.declarations, other.declarations);
  }

  @override
  bool visitLiteralExpression(LiteralExpression node, Node arg) {
    if (arg is! LiteralExpression) return failAt(node, arg);
    LiteralExpression other = arg;
    return testValues(node, node.template, other, other.template) &&
        testNodeLists(node.inputs, other.inputs);
  }

  @override
  bool visitDartYield(DartYield node, Node arg) {
    if (arg is! DartYield) return failAt(node, arg);
    DartYield other = arg;
    return testNodes(node.expression, other.expression) &&
        testValues(node, node.hasStar, other, other.hasStar);
  }

  @override
  bool visitLiteralStatement(LiteralStatement node, Node arg) {
    if (arg is! LiteralStatement) return failAt(node, arg);
    LiteralStatement other = arg;
    return testValues(node, node.code, other, other.code);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node, Node arg) {
    if (arg is! LabeledStatement) return failAt(node, arg);
    LabeledStatement other = arg;
    return testLabels(node, node.label, other, other.label) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node, Node arg) {
    if (arg is! FunctionDeclaration) return failAt(node, arg);
    FunctionDeclaration other = arg;
    return testNodes(node.name, other.name) &&
        testNodes(node.function, other.function);
  }

  @override
  bool visitDefault(Default node, Node arg) {
    if (arg is! Default) return failAt(node, arg);
    Default other = arg;
    return testNodes(node.body, other.body);
  }

  @override
  bool visitCase(Case node, Node arg) {
    if (arg is! Case) return failAt(node, arg);
    Case other = arg;
    return testNodes(node.expression, other.expression) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitSwitch(Switch node, Node arg) {
    if (arg is! Switch) return failAt(node, arg);
    Switch other = arg;
    return testNodes(node.key, other.key) &&
        testNodeLists(node.cases, other.cases);
  }

  @override
  bool visitCatch(Catch node, Node arg) {
    if (arg is! Catch) return failAt(node, arg);
    Catch other = arg;
    return testNodes(node.declaration, other.declaration) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitTry(Try node, Node arg) {
    if (arg is! Try) return failAt(node, arg);
    Try other = arg;
    return testNodes(node.body, other.body) &&
        testNodes(node.catchPart, other.catchPart) &&
        testNodes(node.finallyPart, other.finallyPart);
  }

  @override
  bool visitThrow(Throw node, Node arg) {
    if (arg is! Throw) return failAt(node, arg);
    Throw other = arg;
    return testNodes(node.expression, other.expression);
  }

  @override
  bool visitReturn(Return node, Node arg) {
    if (arg is! Return) return failAt(node, arg);
    Return other = arg;
    return testNodes(node.value, other.value);
  }

  @override
  bool visitBreak(Break node, Node arg) {
    if (arg is! Break) return failAt(node, arg);
    Break other = arg;
    return testLabels(node, node.targetLabel, other, other.targetLabel);
  }

  @override
  bool visitContinue(Continue node, Node arg) {
    if (arg is! Continue) return failAt(node, arg);
    Continue other = arg;
    return testLabels(node, node.targetLabel, other, other.targetLabel);
  }

  @override
  bool visitDo(Do node, Node arg) {
    if (arg is! Do) return failAt(node, arg);
    Do other = arg;
    return testNodes(node.condition, other.condition) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitWhile(While node, Node arg) {
    if (arg is! While) return failAt(node, arg);
    While other = arg;
    return testNodes(node.condition, other.condition) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitForIn(ForIn node, Node arg) {
    if (arg is! ForIn) return failAt(node, arg);
    ForIn other = arg;
    return testNodes(node.leftHandSide, other.leftHandSide) &&
        testNodes(node.object, other.object) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitFor(For node, Node arg) {
    if (arg is! For) return failAt(node, arg);
    For other = arg;
    return testNodes(node.init, other.init) &&
        testNodes(node.condition, other.condition) &&
        testNodes(node.update, other.update) &&
        testNodes(node.body, other.body);
  }

  @override
  bool visitIf(If node, Node arg) {
    if (arg is! If) return failAt(node, arg);
    If other = arg;
    return testNodes(node.condition, other.condition) &&
        testNodes(node.then, other.then) &&
        testNodes(node.otherwise, other.otherwise);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node, Node arg) {
    if (arg is! EmptyStatement) return failAt(node, arg);
    return true;
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node, Node arg) {
    if (arg is! ExpressionStatement) return failAt(node, arg);
    ExpressionStatement other = arg;
    return testNodes(node.expression, other.expression);
  }

  @override
  bool visitBlock(Block node, Node arg) {
    if (arg is! Block) return failAt(node, arg);
    Block other = arg;
    return testNodeLists(node.statements, other.statements);
  }
}
