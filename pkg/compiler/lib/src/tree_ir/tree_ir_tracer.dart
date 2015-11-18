// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_tracer;

import 'dart:async' show EventSink;
import '../tracer.dart';
import 'tree_ir_nodes.dart';

class Block {
  Label label;
  int index;
  /// Mixed list of [Statement] and [Block].
  /// A [Block] represents a synthetic goto statement.
  final List statements = [];
  final List<Block> predecessors = <Block>[];
  final List<Block> successors = <Block>[];

  /// The catch block associated with the immediately enclosing try block or
  /// `null` if not inside a try block.
  Block catcher;

  /// True if this block is the entry point to one of the bodies
  /// (constructors can have multiple bodies).
  bool isEntryPoint = false;

  String get name => 'B$index';

  Block([this.label]);

  void addEdgeTo(Block successor) {
    successors.add(successor);
    successor.predecessors.add(this);
  }
}

class BlockCollector extends StatementVisitor {
  // Accumulate a list of blocks.  The current block is the last block in
  // the list.
  final List<Block> blocks = [];

  // Map tree [Label]s (break or continue targets) and [Statement]s
  // (if targets) to blocks.
  final Map<Label, Block> breakTargets = <Label, Block>{};
  final Map<Label, Block> continueTargets = <Label, Block>{};
  final Map<Statement, Block> substatements = <Statement, Block>{};

  Block catcher;

  void _addStatement(Statement statement) {
    blocks.last.statements.add(statement);
  }
  void _addGotoStatement(Block target) {
    blocks.last.statements.add(target);
  }

  void _addBlock(Block block) {
    block.index = blocks.length;
    block.catcher = catcher;
    blocks.add(block);
  }

  void collect(FunctionDefinition node) {
    _addBlock(new Block()..isEntryPoint = true);
    visitStatement(node.body);
  }

  visitLabeledStatement(LabeledStatement node) {
    Block target = new Block(node.label);
    breakTargets[node.label] = target;
    visitStatement(node.body);
    _addBlock(target);
    visitStatement(node.next);
  }

  visitReturn(Return node) {
    _addStatement(node);
  }

  visitThrow(Throw node) {
    _addStatement(node);
  }

  visitRethrow(Rethrow node) {
    _addStatement(node);
  }

  visitUnreachable(Unreachable node) {
    _addStatement(node);
  }

  visitBreak(Break node) {
    _addStatement(node);
    if (breakTargets.containsKey(node.target)) {
      blocks.last.addEdgeTo(breakTargets[node.target]);
    }
  }

  visitContinue(Continue node) {
    _addStatement(node);
    blocks.last.addEdgeTo(continueTargets[node.target]);
  }

  visitIf(If node) {
    _addStatement(node);
    Block thenTarget = new Block();
    Block elseTarget = new Block();
    substatements[node.thenStatement] = thenTarget;
    substatements[node.elseStatement] = elseTarget;
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

  visitFor(For node) {
    Block whileBlock = new Block();
    _addGotoStatement(whileBlock);

    _addBlock(whileBlock);
    _addStatement(node);
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

    substatements[node.body] = bodyBlock;
    substatements[node.next] = nextBlock;
  }

  visitTry(Try node) {
    _addStatement(node);
    Block tryBlock = new Block();
    Block catchBlock = new Block();

    Block oldCatcher = catcher;
    catcher = catchBlock;
    _addBlock(tryBlock);
    visitStatement(node.tryBody);
    catcher = oldCatcher;

    _addBlock(catchBlock);
    visitStatement(node.catchBody);

    substatements[node.tryBody] = tryBlock;
    substatements[node.catchBody] = catchBlock;
  }

  visitExpressionStatement(ExpressionStatement node) {
    _addStatement(node);
    visitStatement(node.next);
  }

  visitForeignStatement(ForeignStatement node) {
    _addStatement(node);
  }

  visitYield(Yield node) {
    _addStatement(node);
    visitStatement(node.next);
  }
}

class TreeTracer extends TracerUtil with StatementVisitor {
  String get passName => null;

  final EventSink<String> output;

  TreeTracer(this.output);

  List<Variable> parameters;
  Names names;
  BlockCollector collector;
  int statementCounter;

  void traceGraph(String name, FunctionDefinition node) {
    parameters = node.parameters;
    tag("cfg", () {
      printProperty("name", name);
      names = new Names();
      statementCounter = 0;
      collector = new BlockCollector();
      collector.collect(node);
      collector.blocks.forEach(printBlock);
    });
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
        if (block.isEntryPoint) {
          String params = parameters.map(names.varName).join(', ');
          printStatement(null, 'Entry ($params)');
        }
        if (block.label != null) {
          printStatement(null,
              "Label ${block.name}, useCount=${block.label.useCount}");
        }
        if (block.catcher != null) {
          printStatement(null, 'Catch exceptions at ${block.catcher.name}');
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

  visitReturn(Return node) {
    printStatement(null, "return ${expr(node.value)}");
  }

  visitThrow(Throw node) {
    printStatement(null, "throw ${expr(node.value)}");
  }

  visitRethrow(Rethrow node) {
    printStatement(null, "rethrow");
  }

  visitUnreachable(Unreachable node) {
    printStatement(null, "unreachable");
  }

  visitBreak(Break node) {
    Block block = collector.breakTargets[node.target];
    String name = block != null ? block.name : '<missing label>';
    printStatement(null, "break $name");
  }

  visitContinue(Continue node) {
    printStatement(null,
        "continue ${collector.continueTargets[node.target].name}");
  }

  visitIf(If node) {
    String condition = expr(node.condition);
    String thenTarget = collector.substatements[node.thenStatement].name;
    String elseTarget = collector.substatements[node.elseStatement].name;
    printStatement(null, "if $condition then $thenTarget else $elseTarget");
  }

  visitWhileTrue(WhileTrue node) {
    printStatement(null, "while true do");
  }

  visitFor(For node) {
    String bodyTarget = collector.substatements[node.body].name;
    String nextTarget = collector.substatements[node.next].name;
    String updates = node.updates.map(expr).join(', ');
    printStatement(null, "while ${expr(node.condition)}");
    printStatement(null, "do $bodyTarget");
    printStatement(null, "updates ($updates)");
    printStatement(null, "then $nextTarget" );
  }

  visitTry(Try node) {
    String tryTarget = collector.substatements[node.tryBody].name;
    String catchParams = node.catchParameters.map(names.varName).join(',');
    String catchTarget = collector.substatements[node.catchBody].name;
    printStatement(null, 'try $tryTarget catch($catchParams) $catchTarget');
  }

  visitExpressionStatement(ExpressionStatement node) {
    printStatement(null, expr(node.expression));
  }

  visitSetField(SetField node) {
    String object = expr(node.object);
    String field = node.field.name;
    String value = expr(node.value);
    if (SubexpressionVisitor.usesInfixNotation(node.object)) {
      object = '($object)';
    }
    printStatement(null, '$object.$field = $value');
  }

  String expr(Expression e) {
    return e.accept(new SubexpressionVisitor(names));
  }

  @override
  visitForeignStatement(ForeignStatement node) {
    printStatement(null, 'foreign ${node.codeTemplate.source}');
  }

  @override
  visitYield(Yield node) {
    String name = node.hasStar ? 'yield*' : 'yield';
    printStatement(null, '$name ${expr(node.input)}');
  }
}

class SubexpressionVisitor extends ExpressionVisitor<String> {
  Names names;

  SubexpressionVisitor(this.names);

  String visitVariableUse(VariableUse node) {
    return names.varName(node.variable);
  }

  String visitAssign(Assign node) {
    String variable = names.varName(node.variable);
    String value = visitExpression(node.value);
    return '$variable = $value';
  }

  String formatArguments(Invoke node) {
    return node.arguments.map(visitExpression).join(', ');
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

  String visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    String receiver = visitExpression(node.receiver);
    String host = node.target.enclosingClass.name;
    String name = node.selector.name;
    String args = formatArguments(node);
    return "$receiver.$host::$name($args)";
  }

  String visitInvokeConstructor(InvokeConstructor node) {
    String className = node.target.enclosingClass.name;
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${className}';
    } else {
      callName = '${className}.${node.target.name}';
    }
    String args = formatArguments(node);
    String keyword = node.constant != null ? 'const' : 'new';
    return "$keyword $callName($args)";
  }

  String visitLiteralList(LiteralList node) {
    String values = node.values.map(visitExpression).join(', ');
    return "list [$values]";
  }

  String visitLiteralMap(LiteralMap node) {
    List<String> entries = new List<String>();
    node.entries.forEach((LiteralMapEntry entry) {
      String key = visitExpression(entry.key);
      String value = visitExpression(entry.value);
      entries.add("$key: $value");
    });
    return "map [${entries.join(', ')}]";
  }

  String visitConstant(Constant node) {
    return "${node.value.toStructuredString()}";
  }

  String visitThis(This node) {
    return "this";
  }

  static bool usesInfixNotation(Expression node) {
    return node is Conditional ||
           node is LogicalOperator ||
           node is Assign ||
           node is SetField;
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
    String value = visitExpression(node.value);
    String type = "${node.type}";
    return "TypeOperator $value ${node.operator} $type";
  }

  String visitNot(Not node) {
    String operand = visitExpression(node.operand);
    if (usesInfixNotation(node.operand)) {
      operand = '($operand)';
    }
    return '!$operand';
  }

  String visitFunctionExpression(FunctionExpression node) {
    return "function ${node.definition.element.name}";
  }

  String visitGetField(GetField node) {
    String object = visitExpression(node.object);
    String field = node.field.name;
    if (usesInfixNotation(node.object)) {
      object = '($object)';
    }
    return '$object.$field';
  }

  String visitSetField(SetField node) {
    String object = visitExpression(node.object);
    String field = node.field.name;
    if (usesInfixNotation(node.object)) {
      object = '($object)';
    }
    String value = visitExpression(node.value);
    return '$object.$field = $value';
  }

  String visitGetStatic(GetStatic node) {
    String element = node.element.name;
    return element;
  }

  String visitSetStatic(SetStatic node) {
    String element = node.element.name;
    String value = visitExpression(node.value);
    return '$element = $value';
  }

  String visitGetTypeTestProperty(GetTypeTestProperty node) {
    String object = visitExpression(node.object);
    if (usesInfixNotation(node.object)) {
      object = '($object)';
    }
    // TODO(sra): Fix up this.
    return '$object."is-${node.dartType}"';
  }

  String visitCreateBox(CreateBox node) {
    return 'CreateBox';
  }

  String visitCreateInstance(CreateInstance node) {
    String className = node.classElement.name;
    String arguments = node.arguments.map(visitExpression).join(', ');
    return 'CreateInstance $className($arguments)';
  }

  @override
  String visitReadTypeVariable(ReadTypeVariable node) {
    return 'Read ${node.variable.element} ${visitExpression(node.target)}';
  }

  @override
  String visitReifyRuntimeType(ReifyRuntimeType node) {
    return 'Reify ${node.value}';
  }

  @override
  String visitTypeExpression(TypeExpression node) {
    return node.dartType.toString();
  }

  @override
  String visitCreateInvocationMirror(CreateInvocationMirror node) {
    String args = node.arguments.map(visitExpression).join(', ');
    return 'CreateInvocationMirror(${node.selector.name}, $args)';
  }

  @override
  String visitInterceptor(Interceptor node) {
    return 'Interceptor(${visitExpression(node.input)})';
  }

  @override
  String visitForeignExpression(ForeignExpression node) {
    String arguments = node.arguments.map(visitExpression).join(', ');
    return 'Foreign "${node.codeTemplate.source}"($arguments)';
  }

  @override
  String visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    String args = node.arguments.map(visitExpression).join(', ');
    return 'ApplyBuiltinOperator ${node.operator} ($args)';
  }

  @override
  String visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    String receiver = visitExpression(node.receiver);
    String args = node.arguments.map(visitExpression).join(', ');
    return 'ApplyBuiltinMethod ${node.method} $receiver ($args)';
  }

  @override
  String visitGetLength(GetLength node) {
    String object = visitExpression(node.object);
    return 'GetLength($object)';
  }

  @override
  String visitGetIndex(GetIndex node) {
    String object = visitExpression(node.object);
    String index = visitExpression(node.index);
    return 'GetIndex($object, $index)';
  }

  @override
  String visitSetIndex(SetIndex node) {
    String object = visitExpression(node.object);
    String index = visitExpression(node.index);
    String value = visitExpression(node.value);
    return 'SetIndex($object, $index, $value)';
  }

  @override
  String visitAwait(Await node) {
    String value = visitExpression(node.input);
    return 'Await($value)';
  }

  @override
  String visitYield(Yield node) {
    String value = visitExpression(node.input);
    return 'Yield($value)';
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
