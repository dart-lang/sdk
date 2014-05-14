// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend.tracer;

import 'dart:async' show EventSink;
import '../tracer.dart';
import 'dart_tree.dart';

class Block {
  int index;
  final List<Statement> statements = <Statement>[];
  final List<Block> predecessors = <Block>[];
  final List<Block> successors = <Block>[];

  String get name => 'B$index';

  void addEdgeTo(Block successor) {
    successors.add(successor);
    successor.predecessors.add(this);
  }
}

class BlockCollector extends Visitor {
  // Accumulate a list of blocks.  The current block is the last block in
  // the list.
  final List<Block> blocks = [new Block()..index = 0];

  // Map tree [Label]s (break targets) and [Statement]s (if targets) to
  // blocks.
  final Map<Label, Block> breakTargets = <Label, Block>{};
  final Map<Statement, Block> ifTargets = <Statement, Block>{};

  void _addStatement(Statement statement) {
    blocks.last.statements.add(statement);
  }

  void _addBlock(Block block) {
    block.index = blocks.length;
    blocks.add(block);
  }

  void collect(FunctionDefinition function) {
    visitStatement(function.body);
  }

  visitVariable(Variable node) {}
  visitInvokeStatic(InvokeStatic node) {}
  visitInvokeMethod(InvokeMethod node) {}
  visitInvokeConstructor(InvokeConstructor node) {}
  visitConcatenateStrings(ConcatenateStrings node) {}
  visitConstant(Constant node) {}
  visitConditional(Conditional node) {}

  visitLabeledStatement(LabeledStatement node) {
    Block target = new Block();
    breakTargets[node.label] = target;
    visitStatement(node.body);
    _addBlock(target);
    visitStatement(node.next);
  }

  visitAssign(Assign node) {
    _addStatement(node);
    visitStatement(node.next);
  }

  visitReturn(Return node) {
    _addStatement(node);
  }

  visitBreak(Break node) {
    _addStatement(node);
    blocks.last.addEdgeTo(breakTargets[node.target]);
  }

  visitIf(If node) {
    _addStatement(node);
    Block thenTarget = new Block();
    Block elseTarget = new Block();
    ifTargets[node.thenStatement] = thenTarget;
    ifTargets[node.elseStatement] = elseTarget;
    blocks.last.addEdgeTo(thenTarget);
    blocks.last.addEdgeTo(elseTarget);
    _addBlock(thenTarget);
    visitStatement(node.thenStatement);
    _addBlock(elseTarget);
    visitStatement(node.elseStatement);
  }

  visitExpressionStatement(ExpressionStatement node) {
    _addStatement(node);
    visitStatement(node.next);
  }
}

class TreeTracer extends TracerUtil with Visitor {
  final EventSink<String> output;

  TreeTracer(this.output);

  Names names;
  BlockCollector collector;
  int statementCounter;

  void traceGraph(String name, FunctionDefinition function) {
    names = new Names();
    statementCounter = 0;
    collector = new BlockCollector();
    collector.collect(function);
    tag("cfg", () {
      printProperty("name", name);
      int blockCounter = 0;
      collector.blocks.forEach(printBlock);
    });
    names = null;
  }

  void printBlock(Block block) {
    tag("block", () {
      printProperty("name", block.name);
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      printProperty("predecessors", block.predecessors.map((b) => b.name));
      printProperty("successors", block.successors.map((b) => b.name));
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
        });
      });
      tag("HIR", () {
        block.statements.forEach(visitStatement);
      });
    });
  }

  void printStatement(String name, String contents) {
    int bci = 0;
    int uses = 0;
    if (name == null) {
      name = 'x${statementCounter++}';
    }
    addIndent();
    add("$bci $uses $name $contents <|@\n");
  }

  visitVariable(Variable node) {
    printStatement(null, "dead-use ${names.varName(node)}");
  }

  visitInvokeStatic(InvokeStatic node) {
    printStatement(null, expr(node));
  }

  visitConstant(Constant node) {
    printStatement(null, "dead-use ${node.value}");
  }

  visitLabeledStatement(LabeledStatement node) {
    // These do not get added to a block's list of statements.
  }

  visitAssign(Assign node) {
    String name = names.varName(node.variable);
    String rhs = expr(node.definition);
    printStatement(name, "let $name = $rhs");
  }

  visitInvokeMethod(InvokeMethod node) {
    printStatement(null, expr(node));
  }

  visitInvokeConstructor(InvokeConstructor node) {
    printStatement(null, expr(node));
  }

  visitConcatenateStrings(ConcatenateStrings node) {
    printStatement(null, expr(node));
  }

  visitConditional(Conditional node) {
    printStatement(null, expr(node));
  }

  visitReturn(Return node) {
    printStatement(null, "return ${expr(node.value)}");
  }

  visitBreak(Break node) {
    printStatement(null, "break ${collector.breakTargets[node.target].name}");
  }

  visitIf(If node) {
    String condition = expr(node.condition);
    String thenTarget = collector.ifTargets[node.thenStatement].name;
    String elseTarget = collector.ifTargets[node.elseStatement].name;
    printStatement(null, "if $condition then $thenTarget else $elseTarget");
  }

  visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
  }

  String expr(Expression e) {
    return e.accept(new SubexpressionVisitor(names));
  }
}

class SubexpressionVisitor extends Visitor<String, String> {
  Names names;

  SubexpressionVisitor(this.names);

  String visitVariable(Variable node) {
    return names.varName(node);
  }

  String visitInvokeStatic(InvokeStatic node) {
    String head = node.target.name;
    String args = node.arguments.map((e) => e.accept(this)).join(', ');
    return "$head($args)";
  }

  String visitInvokeMethod(InvokeMethod node) {
    String receiver = node.receiver.accept(this);
    String name = node.selector.name;
    String args = node.arguments.map((e) => e.accept(this)).join(', ');
    return "$receiver.$name($args)";
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${node.type}';
    } else {
      callName = '${node.type}.${node.target.name}';
    }
    String args = node.arguments.map(visitExpression).join(', ');
    return "new $callName($args)";
  }

  String visitConcatenateStrings(ConcatenateStrings node) {
    String args = node.arguments.map(visitExpression).join(', ');
    return "concat [$args]";
  }

  String visitConstant(Constant node) {
    return "${node.value}";
  }

  String visitConditional(Conditional node) {
    return visitExpression(node.condition) + ' ? ' +
           visitExpression(node.thenExpression) + ' : ' +
           visitExpression(node.elseExpression);
  }

  // Note: There should not be statements in the context of expressions.
  String visitStatement(Statement node) {
    return "${node.runtimeType} statement in expression context";
  }

  String visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  String visitAssign(Assign node) => visitStatement(node);
  String visitReturn(Return node) => visitStatement(node);
  String visitBreak(Break node) => visitStatement(node);
  String visitIf(If node) => visitStatement(node);
  String visitExpressionStatement(ExpressionStatement node) {
    return visitStatement(node);
  }
}

/**
 * Invents (and remembers) names for Variables that do not have an associated
 * identifier.
 *
 * In case a variable is named v0, v1, etc, it may be assigned a different
 * name to avoid clashing with a previously synthesized variable name.
 */
class Names {
  final Map<Variable, String> _names = {};
  final Set<String> _usedNames = new Set();
  int _counter = 0;

  String varName(Variable v) {
    String name = _names[v];
    if (name == null) {
      name = v.name;
      if (v.cachedName != null) {
        name = v.cachedName;
      }
      while (name == null || _usedNames.contains(name)) {
        name = "v${_counter++}";
      }
      _names[v] = name;
      _usedNames.add(name);
    }
    return name;
  }
}