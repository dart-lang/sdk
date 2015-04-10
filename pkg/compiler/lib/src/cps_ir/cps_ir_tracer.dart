// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_tracer;

import 'dart:async' show EventSink;

import 'cps_ir_nodes.dart' as cps_ir hide Function;
import '../tracer.dart';

/**
 * If true, show LetCont expressions in output.
 */
const bool IR_TRACE_LET_CONT = false;

class IRTracer extends TracerUtil implements cps_ir.Visitor {
  EventSink<String> output;

  IRTracer(this.output);

  visit(cps_ir.Node node) => node.accept(this);

  void traceGraph(String name, cps_ir.RootNode node) {
    if (node.isEmpty) return; // Don't bother printing an empty trace.
    tag("cfg", () {
      printProperty("name", name);

      names = new Names();
      BlockCollector builder = new BlockCollector(names);
      builder.visit(node);

      for (Block block in builder.entries) {
        printBlock(block, entryPointParameters: node.parameters);
      }
      for (Block block in builder.cont2block.values) {
        printBlock(block);
      }
      names = null;
    });
  }

  // Temporary field used during tree walk
  Names names;

  visitFieldDefinition(cps_ir.FieldDefinition node) {
    unexpectedNode(node);
  }

  visitFunctionDefinition(cps_ir.FunctionDefinition node) {
    unexpectedNode(node);
  }

  visitConstructorDefinition(cps_ir.ConstructorDefinition node) {
    unexpectedNode(node);
  }

  visitFieldInitializer(cps_ir.FieldInitializer node) {
    unexpectedNode(node);
  }

  visitSuperInitializer(cps_ir.SuperInitializer node) {
    unexpectedNode(node);
  }

  visitBody(cps_ir.Body node) {
    unexpectedNode(node);
  }

  // Bodies and initializers are not visited.  They contain continuations which
  // are found by a BlockCollector, then those continuations are processed by
  // this visitor.
  unexpectedNode(cps_ir.Node node) {
    throw 'The IR tracer reached an unexpected IR instruction: $node';
  }


  int countUses(cps_ir.Definition definition) {
    int count = 0;
    cps_ir.Reference ref = definition.firstRef;
    while (ref != null) {
      ++count;
      ref = ref.next;
    }
    return count;
  }

  /// If [entryPointParameters] is given, this block is an entry point
  /// and [entryPointParameters] is the list of function parameters.
  printBlock(Block block, {List<cps_ir.Definition> entryPointParameters}) {
    tag("block", () {
      printProperty("name", block.name);
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      printProperty("predecessors", block.pred.map((n) => n.name));
      printProperty("successors", block.succ.map((n) => n.name));
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
        });
      });
      tag("HIR", () {
        if (entryPointParameters != null) {
          String params = entryPointParameters.map(names.name).join(', ');
          printStmt('x0', 'Entry ($params)');
        }
        for (cps_ir.Parameter param in block.parameters) {
          String name = names.name(param);
          printStmt(name, "Parameter $name [useCount=${countUses(param)}]");
        }
        visit(block.body);
      });
    });
  }

  void printStmt(String resultVar, String contents) {
    int bci = 0;
    int uses = 0;
    addIndent();
    add("$bci $uses $resultVar $contents <|@\n");
  }

  visitLetPrim(cps_ir.LetPrim node) {
    String id = names.name(node.primitive);
    printStmt(id, "LetPrim $id = ${formatPrimitive(node.primitive)}");
    visit(node.body);
  }

  visitLetCont(cps_ir.LetCont node) {
    if (IR_TRACE_LET_CONT) {
      String dummy = names.name(node);
      for (cps_ir.Continuation continuation in node.continuations) {
        String id = names.name(continuation);
        printStmt(dummy, "LetCont $id = <$id>");
      }
    }
    visit(node.body);
  }

  visitLetHandler(cps_ir.LetHandler node) {
    if (IR_TRACE_LET_CONT) {
      String dummy = names.name(node);
      String id = names.name(node.handler);
      printStmt(dummy, "LetHandler $id = <$id>");
    }
    visit(node.body);
  }

  visitLetMutable(cps_ir.LetMutable node) {
    String id = names.name(node.variable);
    printStmt(id, "LetMutable $id = ${formatReference(node.value)}");
    visit(node.body);
  }

  visitInvokeStatic(cps_ir.InvokeStatic node) {
    String dummy = names.name(node);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "InvokeStatic $callName ($args) $kont");
  }

  visitInvokeMethod(cps_ir.InvokeMethod node) {
    String dummy = names.name(node);
    String receiver = formatReference(node.receiver);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy,
        "InvokeMethod $receiver $callName ($args) $kont");
  }

  visitInvokeMethodDirectly(cps_ir.InvokeMethodDirectly node) {
    String dummy = names.name(node);
    String receiver = formatReference(node.receiver);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy,
        "InvokeMethodDirectly $receiver $callName ($args) $kont");
  }

  visitInvokeConstructor(cps_ir.InvokeConstructor node) {
    String dummy = names.name(node);
    String className = node.target.enclosingClass.name;
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${className}';
    } else {
      callName = '${className}.${node.target.name}';
    }
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "InvokeConstructor $callName ($args) $kont");
  }

  visitConcatenateStrings(cps_ir.ConcatenateStrings node) {
    String dummy = names.name(node);
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "ConcatenateStrings ($args) $kont");
  }

  visitLiteralList(cps_ir.LiteralList node) {
    String dummy = names.name(node);
    String values = node.values.map(formatReference).join(', ');
    printStmt(dummy, "LiteralList ($values)");
  }

  visitLiteralMap(cps_ir.LiteralMap node) {
    String dummy = names.name(node);
    List<String> entries = new List<String>();
    for (cps_ir.LiteralMapEntry entry in node.entries) {
      String key = formatReference(entry.key);
      String value = formatReference(entry.value);
      entries.add("$key: $value");
    }
    printStmt(dummy, "LiteralMap (${entries.join(', ')})");
  }

  visitTypeOperator(cps_ir.TypeOperator node) {
    String dummy = names.name(node);
    String operator = node.isTypeTest ? 'is' : 'as';
    List<String> entries = new List<String>();
    String receiver = formatReference(node.receiver);
    printStmt(dummy, "TypeOperator ($operator $receiver ${node.type})");
  }

  visitInvokeContinuation(cps_ir.InvokeContinuation node) {
    String dummy = names.name(node);
    String kont = formatReference(node.continuation);
    String args = node.arguments.map(formatReference).join(', ');
    printStmt(dummy, "InvokeContinuation $kont ($args)");
  }

  visitBranch(cps_ir.Branch node) {
    String dummy = names.name(node);
    String condition = visit(node.condition);
    String trueCont = formatReference(node.trueContinuation);
    String falseCont = formatReference(node.falseContinuation);
    printStmt(dummy, "Branch $condition ($trueCont, $falseCont)");
  }

  visitSetMutableVariable(cps_ir.SetMutableVariable node) {
    String dummy = names.name(node);
    String variable = names.name(node.variable.definition);
    String value = formatReference(node.value);
    printStmt(dummy, 'SetMutableVariable $variable := $value');
    visit(node.body);
  }

  visitDeclareFunction(cps_ir.DeclareFunction node) {
    String dummy = names.name(node);
    String variable = names.name(node.variable);
    printStmt(dummy, 'DeclareFunction $variable');
    visit(node.body);
  }

  String formatReference(cps_ir.Reference ref) {
    cps_ir.Definition target = ref.definition;
    if (target is cps_ir.Continuation && target.isReturnContinuation) {
      return "return"; // Do not generate a name for the return continuation
    } else {
      return names.name(ref.definition);
    }
  }

  String formatPrimitive(cps_ir.Primitive p) => visit(p);

  visitConstant(cps_ir.Constant node) {
    return "Constant ${node.expression.value.toStructuredString()}";
  }

  visitParameter(cps_ir.Parameter node) {
    return "Parameter ${names.name(node)}";
  }

  visitMutableVariable(cps_ir.MutableVariable node) {
    return "MutableVariable ${names.name(node)}";
  }

  visitContinuation(cps_ir.Continuation node) {
    return "Continuation ${names.name(node)}";
  }

  visitIsTrue(cps_ir.IsTrue node) {
    return "IsTrue(${names.name(node.value.definition)})";
  }

  visitSetField(cps_ir.SetField node) {
    String dummy = names.name(node);
    String object = formatReference(node.object);
    String field = node.field.name;
    String value = formatReference(node.value);
    printStmt(dummy, 'SetField $object.$field = $value');
    visit(node.body);
  }

  visitGetField(cps_ir.GetField node) {
    String object = formatReference(node.object);
    String field = node.field.name;
    return 'GetField($object.$field)';
  }

  visitCreateBox(cps_ir.CreateBox node) {
    return 'CreateBox';
  }

  visitCreateInstance(cps_ir.CreateInstance node) {
    String className = node.classElement.name;
    String arguments = node.arguments.map(formatReference).join(', ');
    String typeInformation =
        node.typeInformation.map(formatReference).join(', ');
    return 'CreateInstance $className ($arguments) <$typeInformation>';
  }

  visitIdentical(cps_ir.Identical node) {
    String left = formatReference(node.left);
    String right = formatReference(node.right);
    return "Identical($left, $right)";
  }

  visitInterceptor(cps_ir.Interceptor node) {
    return "Interceptor(${formatReference(node.input)})";
  }

  visitReifyTypeVar(cps_ir.ReifyTypeVar node) {
    return "ReifyTypeVar ${node.typeVariable.name}";
  }

  visitCreateFunction(cps_ir.CreateFunction node) {
    return "CreateFunction ${node.definition.element.name}";
  }

  visitGetMutableVariable(cps_ir.GetMutableVariable node) {
    String variable = names.name(node.variable.definition);
    return 'GetMutableVariable $variable';
  }

  @override
  visitReadTypeVariable(cps_ir.ReadTypeVariable node) {
    return "ReadTypeVariable ${node.variable.element} "
        "${formatReference(node.target)}";
  }

  @override
  visitReifyRuntimeType(cps_ir.ReifyRuntimeType node) {
    return "ReifyRuntimeType ${formatReference(node.value)}";
  }

  @override
  visitTypeExpression(cps_ir.TypeExpression node) {
    return "TypeExpression ${node.dartType} "
        "${node.arguments.map(formatReference).join(', ')}";
  }
}

/**
 * Invents (and remembers) names for Continuations, Parameters, etc.
 * The names must match the conventions used by IR Hydra, e.g.
 * Continuations and Functions must have names of form B### since they
 * are visualized as basic blocks.
 */
class Names {
  final Map<Object, String> names = {};
  final Map<String, int> counters = {
    'r': 0,
    'B': 0,
    'v': 0,
    'x': 0,
    'c': 0
  };

  String prefix(x) {
    if (x is cps_ir.Parameter) return 'r';
    if (x is cps_ir.Continuation || x is cps_ir.FunctionDefinition) return 'B';
    if (x is cps_ir.Primitive) return 'v';
    if (x is cps_ir.MutableVariable) return 'c';
    return 'x';
  }

  String name(x) {
    String nam = names[x];
    if (nam == null) {
      String pref = prefix(x);
      int id = counters[pref]++;
      nam = names[x] = '${pref}${id}';
    }
    return nam;
  }
}

/**
 * A vertex in the graph visualization, used in place of basic blocks.
 */
class Block {
  String name;
  final List<cps_ir.Parameter> parameters;
  final cps_ir.Expression body;
  final List<Block> succ = <Block>[];
  final List<Block> pred = <Block>[];

  Block(this.name, this.parameters, this.body);

  void addEdgeTo(Block successor) {
    succ.add(successor);
    successor.pred.add(this);
  }
}

class BlockCollector implements cps_ir.Visitor {
  final Map<cps_ir.Continuation, Block> cont2block =
      <cps_ir.Continuation, Block>{};
  final Set<Block> entries = new Set<Block>();
  Block currentBlock;

  Names names;
  BlockCollector(this.names);

  Block getBlock(cps_ir.Continuation c) {
    Block block = cont2block[c];
    if (block == null) {
      block = new Block(names.name(c), c.parameters, c.body);
      cont2block[c] = block;
    }
    return block;
  }

  visit(cps_ir.Node node) => node.accept(this);

  visitFieldDefinition(cps_ir.FieldDefinition node) {
    visit(node.body);
  }

  visitFunctionDefinition(cps_ir.FunctionDefinition node) {
    visit(node.body);
  }

  visitConstructorDefinition(cps_ir.ConstructorDefinition node) {
    node.initializers.forEach(visit);
    visit(node.body);
  }

  visitBody(cps_ir.Body node) {
    currentBlock = new Block(names.name(node), [], node.body);
    entries.add(currentBlock);
    visit(node.body);
  }

  visitFieldInitializer(cps_ir.FieldInitializer node) {
    visit(node.body);
  }

  visitSuperInitializer(cps_ir.SuperInitializer node) {
    node.arguments.forEach(visit);
  }

  visitLetPrim(cps_ir.LetPrim exp) {
    visit(exp.body);
  }

  visitLetCont(cps_ir.LetCont exp) {
    exp.continuations.forEach(visit);
    visit(exp.body);
  }

  visitLetHandler(cps_ir.LetHandler exp) {
    visit(exp.handler);
    visit(exp.body);
  }

  visitLetMutable(cps_ir.LetMutable exp) {
    visit(exp.body);
  }

  void addEdgeToContinuation(cps_ir.Reference continuation) {
    cps_ir.Definition target = continuation.definition;
    if (target is cps_ir.Continuation && !target.isReturnContinuation) {
      currentBlock.addEdgeTo(getBlock(target));
    }
  }

  visitInvokeContinuation(cps_ir.InvokeContinuation exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitInvokeStatic(cps_ir.InvokeStatic exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitInvokeMethod(cps_ir.InvokeMethod exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitInvokeMethodDirectly(cps_ir.InvokeMethodDirectly exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitInvokeConstructor(cps_ir.InvokeConstructor exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitConcatenateStrings(cps_ir.ConcatenateStrings exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitSetMutableVariable(cps_ir.SetMutableVariable exp) {
    visit(exp.body);
  }

  visitSetField(cps_ir.SetField exp) {
    visit(exp.body);
  }

  visitDeclareFunction(cps_ir.DeclareFunction exp) {
    visit(exp.body);
  }

  visitBranch(cps_ir.Branch exp) {
    cps_ir.Continuation trueTarget = exp.trueContinuation.definition;
    if (!trueTarget.isReturnContinuation) {
      currentBlock.addEdgeTo(getBlock(trueTarget));
    }
    cps_ir.Continuation falseTarget = exp.falseContinuation.definition;
    if (!falseTarget.isReturnContinuation) {
      currentBlock.addEdgeTo(getBlock(falseTarget));
    }
  }

  visitTypeOperator(cps_ir.TypeOperator exp) {
    addEdgeToContinuation(exp.continuation);
  }

  visitContinuation(cps_ir.Continuation c) {
    var old_node = currentBlock;
    currentBlock = getBlock(c);
    visit(c.body);
    currentBlock = old_node;
  }

  // Primitives and conditions are not visited when searching for blocks.
  unexpectedNode(cps_ir.Node node) {
    throw "The IR tracer's block collector reached an unexpected IR "
        "instruction: $node";
  }

  visitLiteralList(cps_ir.LiteralList node) {
    unexpectedNode(node);
  }
  visitLiteralMap(cps_ir.LiteralMap node) {
    unexpectedNode(node);
  }
  visitConstant(cps_ir.Constant node) {
    unexpectedNode(node);
  }
  visitReifyTypeVar(cps_ir.ReifyTypeVar node) {
    unexpectedNode(node);
  }
  visitCreateFunction(cps_ir.CreateFunction node) {
    unexpectedNode(node);
  }
  visitGetMutableVariable(cps_ir.GetMutableVariable node) {
    unexpectedNode(node);
  }
  visitParameter(cps_ir.Parameter node) {
    unexpectedNode(node);
  }
  visitMutableVariable(cps_ir.MutableVariable node) {
    unexpectedNode(node);
  }
  visitGetField(cps_ir.GetField node) {
    unexpectedNode(node);
  }
  visitCreateBox(cps_ir.CreateBox node) {
    unexpectedNode(node);
  }
  visitCreateInstance(cps_ir.CreateInstance node) {
    unexpectedNode(node);
  }
  visitIsTrue(cps_ir.IsTrue node) {
    unexpectedNode(node);
  }
  visitIdentical(cps_ir.Identical node) {
    unexpectedNode(node);
  }
  visitInterceptor(cps_ir.Interceptor node) {
    unexpectedNode(node);
  }

  @override
  visitReadTypeVariable(cps_ir.ReadTypeVariable node) {
    unexpectedNode(node);
  }

  @override
  visitReifyRuntimeType(cps_ir.ReifyRuntimeType node) {
    unexpectedNode(node);
  }

  @override
  visitTypeExpression(cps_ir.TypeExpression node) {
    unexpectedNode(node);
  }
}
