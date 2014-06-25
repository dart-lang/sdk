// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend.tracer;

import 'dart:async' show EventSink;
import '../tracer.dart';
import 'dart_tree.dart';

class Block {
  Label label;
  int index;
  /// Mixed list of [Statement] and [Block].
  /// A [Block] represents a synthetic goto statement.
  final List statements = [];
  final List<Block> predecessors = <Block>[];
  final List<Block> successors = <Block>[];

  String get name => 'B$index';

  Block([this.label]);

  void addEdgeTo(Block successor) {
    successors.add(successor);
    successor.predecessors.add(this);
  }
}

class BlockCollector extends Visitor {
  // Accumulate a list of blocks.  The current block is the last block in
  // the list.
  final List<Block> blocks = [new Block()..index = 0];

  // Map tree [Label]s (break or continue targets) and [Statement]s
  // (if targets) to blocks.
  final Map<Label, Block> breakTargets = <Label, Block>{};
  final Map<Label, Block> continueTargets = <Label, Block>{};
  final Map<Statement, Block> ifTargets = <Statement, Block>{};

  void _addStatement(Statement statement) {
    blocks.last.statements.add(statement);
  }
  void _addGotoStatement(Block target) {
    blocks.last.statements.add(target);
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
  visitLiteralList(LiteralList node) {}
  visitLiteralMap(LiteralMap node) {}
  visitConstant(Constant node) {}
  visitThis(This node) {}
  visitConditional(Conditional node) {}
  visitLogicalOperator(LogicalOperator node) {}
  visitNot(Not node) {}
  visitTypeOperator(TypeOperator node) {}

  visitLabeledStatement(LabeledStatement node) {
    Block target = new Block(node.label);
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

  visitContinue(Continue node) {
    _addStatement(node);
    blocks.last.addEdgeTo(continueTargets[node.target]);
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

  visitWhileTrue(WhileTrue node) {
    Block continueTarget = new Block();
    _addGotoStatement(continueTarget);

    continueTargets[node.label] = continueTarget;
    blocks.last.addEdgeTo(continueTarget);
    _addBlock(continueTarget);
    _addStatement(node);
    visitStatement(node.body);
  }

  visitWhileCondition(WhileCondition node) {
    Block whileBlock = new Block();
    _addGotoStatement(whileBlock);

    _addBlock(whileBlock);
    _addStatement(node);
    whileBlock.statements.add(node);
    blocks.last.addEdgeTo(whileBlock);

    Block bodyBlock = new Block();
    Block nextBlock = new Block();
    whileBlock.addEdgeTo(bodyBlock);
    whileBlock.addEdgeTo(nextBlock);

    continueTargets[node.label] = bodyBlock;
    _addBlock(bodyBlock);
    visitStatement(node.body);

    _addBlock(nextBlock);
    visitStatement(node.next);

    ifTargets[node.body] = bodyBlock;
    ifTargets[node.next] = nextBlock;
  }

  visitExpressionStatement(ExpressionStatement node) {
    _addStatement(node);
    visitStatement(node.next);
  }
}

class TreeTracer extends TracerUtil with StatementVisitor {
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
        if (block.label != null) {
          printStatement(null,
              "Label ${block.name}, useCount=${block.label.useCount}");
        }
        block.statements.forEach(visitBlockMember);
      });
    });
  }

  void visitBlockMember(member) {
    if (member is Block) {
      printStatement(null, "goto block B${member.name}");
    } else {
      assert(member is Statement);
      visitStatement(member);
    }
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

  visitLabeledStatement(LabeledStatement node) {
    // These do not get added to a block's list of statements.
  }

  visitAssign(Assign node) {
    String name = names.varName(node.variable);
    String rhs = expr(node.definition);
    String extra = node.hasExactlyOneUse ? "[single-use]" : "";
    printStatement(null, "assign $name = $rhs $extra");
  }

  visitReturn(Return node) {
    printStatement(null, "return ${expr(node.value)}");
  }

  visitBreak(Break node) {
    printStatement(null, "break ${collector.breakTargets[node.target].name}");
  }

  visitContinue(Continue node) {
    printStatement(null,
        "continue ${collector.continueTargets[node.target].name}");
  }

  visitIf(If node) {
    String condition = expr(node.condition);
    String thenTarget = collector.ifTargets[node.thenStatement].name;
    String elseTarget = collector.ifTargets[node.elseStatement].name;
    printStatement(null, "if $condition then $thenTarget else $elseTarget");
  }

  visitWhileTrue(WhileTrue node) {
    printStatement(null, "while true do");
  }

  visitWhileCondition(WhileCondition node) {
    String bodyTarget = collector.ifTargets[node.body].name;
    String nextTarget = collector.ifTargets[node.next].name;
    printStatement(null, "while ${expr(node.condition)}");
    printStatement(null, "do $bodyTarget");
    printStatement(null, "then $nextTarget" );
  }

  visitExpressionStatement(ExpressionStatement node) {
    printStatement(null, expr(node.expression));
  }

  String expr(Expression e) {
    return e.accept(new SubexpressionVisitor(names));
  }
}

class SubexpressionVisitor extends ExpressionVisitor<String> {
  Names names;

  SubexpressionVisitor(this.names);

  String visitVariable(Variable node) {
    return names.varName(node);
  }

  String formatArguments(Invoke node) {
    List<String> args = new List<String>();
    int positionalArgumentCount = node.selector.positionalArgumentCount;
    for (int i = 0; i < positionalArgumentCount; ++i) {
      args.add(node.arguments[i].accept(this));
    }
    for (int i = 0; i < node.selector.namedArgumentCount; ++i) {
      String name = node.selector.namedArguments[i];
      String arg = node.arguments[positionalArgumentCount + i].accept(this);
      args.add("$name: $arg");
    }
    return args.join(', ');
  }

  String visitInvokeStatic(InvokeStatic node) {
    String head = node.target.name;
    String args = formatArguments(node);
    return "$head($args)";
  }

  String visitInvokeMethod(InvokeMethod node) {
    String receiver = node.receiver.accept(this);
    String name = node.selector.name;
    String args = formatArguments(node);
    return "$receiver.$name($args)";
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${node.type}';
    } else {
      callName = '${node.type}.${node.target.name}';
    }
    String args = formatArguments(node);
    String keyword = node.constant != null ? 'const' : 'new';
    return "$keyword $callName($args)";
  }

  String visitConcatenateStrings(ConcatenateStrings node) {
    String args = node.arguments.map(visitExpression).join(', ');
    return "concat [$args]";
  }

  String visitLiteralList(LiteralList node) {
    String values = node.values.map(visitExpression).join(', ');
    return "list [$values]";
  }

  String visitLiteralMap(LiteralMap node) {
    List<String> entries = new List<String>();
    for (int i = 0; i < node.values.length; ++i) {
      String key = visitExpression(node.keys[i]);
      String value = visitExpression(node.values[i]);
      entries.add("$key: $value");
    }
    return "map [${entries.join(', ')}]";
  }

  String visitConstant(Constant node) {
    return "${node.value}";
  }

  String visitThis(This node) {
    return "this";
  }

  bool usesInfixNotation(Expression node) {
    return node is Conditional || node is LogicalOperator;
  }

  String visitConditional(Conditional node) {
    String condition = visitExpression(node.condition);
    String thenExpr = visitExpression(node.thenExpression);
    String elseExpr = visitExpression(node.elseExpression);
    return "$condition ? $thenExpr : $elseExpr";
  }

  String visitLogicalOperator(LogicalOperator node) {
    String left = visitExpression(node.left);
    String right = visitExpression(node.right);
    if (usesInfixNotation(node.left)) {
      left = "($left)";
    }
    if (usesInfixNotation(node.right)) {
      right = "($right)";
    }
    return "$left ${node.operator} $right";
  }

  String visitTypeOperator(TypeOperator node) {
    String receiver = visitExpression(node.receiver);
    String type = "${node.type}";
    return "TypeOperator $receiver ${node.operator} $type";
  }

  String visitNot(Not node) {
    String operand = visitExpression(node.operand);
    if (usesInfixNotation(node.operand)) {
      operand = '($operand)';
    }
    return '!$operand';
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
      String prefix = v.element == null ? 'v' : '${v.element.name}_';
      while (name == null || _usedNames.contains(name)) {
        name = "$prefix${_counter++}";
      }
      _names[v] = name;
      _usedNames.add(name);
    }
    return name;
  }
}