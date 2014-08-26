// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

class TreeValidatorTask extends CompilerTask {
  TreeValidatorTask(Compiler compiler) : super(compiler);

  void validate(Node tree) {
    assert(check(tree));
  }

  bool check(Node tree) {
    List<InvalidNodeError> errors = [];
    void report(node, message) {
      final error = new InvalidNodeError(node, message);
      errors.add(error);
      compiler.reportWarning(node, MessageKind.GENERIC, {'text': message});
    };
    final validator = new ValidatorVisitor(report);
    tree.accept(new TraversingVisitor(validator));

    return errors.isEmpty;
  }
}

class ValidatorVisitor extends Visitor {
  final Function reportInvalidNode;

  ValidatorVisitor(Function this.reportInvalidNode);

  expect(Node node, bool test, [message]) {
    if (!test) reportInvalidNode(node, message);
  }

  visitNode(Node node) {}

  visitSendSet(SendSet node) {
    final selector = node.selector;
    final name = node.assignmentOperator.source;
    final arguments = node.arguments;

    expect(node, arguments != null);
    expect(node,
           selector is Identifier || selector is FunctionExpression,
           'selector is not assignable');
    if (identical(name, '++') || identical(name, '--')) {
      expect(node, node.assignmentOperator is Operator);
      if (node.isIndex) {
        expect(node, node.arguments.tail.isEmpty);
      } else {
        expect(node, node.arguments.isEmpty);
      }
    } else {
      expect(node, !node.arguments.isEmpty);
    }
  }

  visitReturn(Return node) {
    if (node.hasExpression) {
      // We allow non-expression expressions in Return nodes, but only when
      // using them to hold redirecting factory constructors.
      expect(node, node.expression.asExpression() != null);
    }
  }
}

class InvalidNodeError {
  final Node node;
  final String message;
  InvalidNodeError(this.node, [this.message]);

  toString() {
    String nodeString = node.toDebugString();
    String result = 'invalid node: $nodeString';
    if (message != null) result = '$result ($message)';
    return result;
  }
}
