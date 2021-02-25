// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:scrape/scrape.dart';

void main(List<String> arguments) {
  Scrape()
    ..addHistogram('Statements')
    ..addVisitor(() => ControlFlowVisitor())
    ..runCommandLine(arguments);
}

class ControlFlowVisitor extends ScrapeVisitor {
  @override
  void visitDoStatement(DoStatement node) {
    record('Statements', 'do while');
    super.visitDoStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts is ForEachParts) {
      record('Statements', 'for in');
    } else {
      record('Statements', 'for ;;');
    }
    super.visitForStatement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      record('Statements', 'if else');
    } else {
      record('Statements', 'if');
    }
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    record('Statements', 'switch');
    super.visitSwitchStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    record('Statements', 'while');
    super.visitWhileStatement(node);
  }
}
