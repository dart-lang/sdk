// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.checks;

import 'ast.dart';
import 'text/ast_to_text.dart';

class CheckParentPointers extends FakeNodeVisitor {
  static void check(TreeNode node) {
    node.accept(new CheckParentPointers(node.parent));
  }

  TreeNode parent;

  CheckParentPointers([this.parent]);

  defaultTreeNode(TreeNode node) {
    if (node.parent != parent) {
      StringBuffer buffer = new StringBuffer();
      new Printer(buffer).writeNode(parent);
      print(buffer);
      throw 'Parent pointer on ${node.runtimeType} '
          'is ${node.parent.runtimeType} '
          'but should be ${parent.runtimeType}';
    }
    var oldParent = parent;
    parent = node;
    node.visitChildren(this);
    parent = oldParent;
  }
}

abstract class FakeNode implements TreeNode {}

abstract class FakeNodeVisitor extends Visitor {
  visitFakeNode(FakeNode node) => defaultNode(node);
}

class FakeExpression extends Expression implements FakeNode {
  Expression node;

  FakeExpression(this.node) {
    node?.parent = this;
  }

  accept(FakeNodeVisitor v) => v.visitFakeNode(this);

  visitChildren(Visitor v) {
    node?.accept(v);
  }

  transformChildren(Transformer v) {
    if (node != null) {
      node = node.accept(v);
      node?.parent = this;
    }
  }
}

class FakeStatement extends Statement implements FakeNode {
  Statement node;

  FakeStatement(this.node) {
    node?.parent = this;
  }

  accept(FakeNodeVisitor v) => v.visitFakeNode(this);

  visitChildren(Visitor v) {
    node?.accept(v);
  }

  transformChildren(Transformer v) {
    if (node != null) {
      node = node.accept(v);
      node?.parent = this;
    }
  }
}

class InsertWrappers extends Transformer {
  defaultExpression(node) => new FakeExpression(defaultTreeNode(node));
  defaultStatement(node) => new FakeStatement(defaultTreeNode(node));

  visitVariableDeclaration(VariableDeclaration node) {
    return defaultTreeNode(node);
  }
}

class CheckTransformers extends FakeNodeVisitor {
  static void transformAndCheck(TreeNode node) {
    var transformed = node.accept(new InsertWrappers());
    CheckParentPointers.check(transformed);
    transformed.accept(new CheckTransformers());
  }

  defaultNode(TreeNode node) {
    if (node is FakeNode) {
      if (node.parent is FakeNode) {
        throw 'FakeNode was wrapped multiple times';
      }
    } else if (node is Expression ||
        node is Statement && node is! VariableDeclaration) {
      if (node.parent is! FakeNode) {
        throw '${node.runtimeType} inside ${node.parent.runtimeType} was not wrapped';
      }
    }
    node.visitChildren(this);
  }
}

class SizeCounter extends RecursiveVisitor {
  int size = 0;
  int emptyArguments = 0;

  void visit(TreeNode node) => node.accept(this);

  visitArguments(Arguments node) {
    super.visitArguments(node);
    if (node.positional.isEmpty &&
        node.positional.isEmpty &&
        node.types.isEmpty) {
      ++emptyArguments;
    }
  }

  defaultNode(TreeNode node) {
    ++size;
    node.visitChildren(this);
  }
}
