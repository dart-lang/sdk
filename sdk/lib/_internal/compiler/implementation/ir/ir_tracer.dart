// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_tracer;

import 'dart:async' show EventSink;

import 'ir_nodes.dart' as ir hide Function;
import '../tracer.dart';

/**
 * If true, show LetCont expressions in output.
 */
const bool IR_TRACE_LET_CONT = false;

class IRTracer extends TracerUtil implements ir.Visitor {
  int indent = 0;
  EventSink<String> output;

  IRTracer(this.output);

  visit(ir.Node node) => node.accept(this);

  void traceGraph(String name, ir.FunctionDefinition graph) {
    tag("cfg", () {
      printProperty("name", name);
      visitFunctionDefinition(graph);
    });
  }

  // Temporary field used during tree walk
  Names names;

  visitFunctionDefinition(ir.FunctionDefinition f) {
    names = new Names();
    BlockCollector builder = new BlockCollector(names);
    builder.visit(f);

    printNode(builder.entry);
    for (Block block in builder.cont2block.values) {
      printNode(block);
    }
    names = null;
  }

  int countUses(ir.Definition definition) {
    int count = 0;
    ir.Reference ref = definition.firstRef;
    while (ref != null) {
      ++count;
      ref = ref.nextRef;
    }
    return count;
  }

  printNode(Block block) {
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
        for (ir.Parameter param in block.parameters) {
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

  visitLetPrim(ir.LetPrim node) {
    String id = names.name(node.primitive);
    printStmt(id, "LetPrim $id = ${formatPrimitive(node.primitive)}");
    visit(node.body);
  }

  visitLetCont(ir.LetCont node) {
    if (IR_TRACE_LET_CONT) {
      String dummy = names.name(node);
      String id = names.name(node.continuation);
      printStmt(dummy, "LetCont $id = <$id>");
    }
    visit(node.body);
  }

  visitInvokeStatic(ir.InvokeStatic node) {
    String dummy = names.name(node);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "InvokeStatic $callName ($args) $kont");
  }

  visitInvokeMethod(ir.InvokeMethod node) {
    String dummy = names.name(node);
    String receiver = formatReference(node.receiver);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy,
        "InvokeMethod $receiver $callName ($args) $kont");
  }

  visitInvokeSuperMethod(ir.InvokeSuperMethod node) {
    String dummy = names.name(node);
    String callName = node.selector.name;
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy,
        "InvokeSuperMethod $callName ($args) $kont");
  }

  visitInvokeConstructor(ir.InvokeConstructor node) {
    String dummy = names.name(node);
    String callName;
    if (node.target.name.isEmpty) {
      callName = '${node.type}';
    } else {
      callName = '${node.type}.${node.target.name}';
    }
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "InvokeConstructor $callName ($args) $kont");
  }

  visitConcatenateStrings(ir.ConcatenateStrings node) {
    String dummy = names.name(node);
    String args = node.arguments.map(formatReference).join(', ');
    String kont = formatReference(node.continuation);
    printStmt(dummy, "ConcatenateStrings ($args) $kont");
  }

  visitLiteralList(ir.LiteralList node) {
    String dummy = names.name(node);
    String values = node.values.map(formatReference).join(', ');
    printStmt(dummy, "LiteralList ($values)");
  }

  visitLiteralMap(ir.LiteralMap node) {
    String dummy = names.name(node);
    List<String> entries = new List<String>();
    for (int i = 0; i < node.values.length; ++i) {
      String key = formatReference(node.keys[i]);
      String value = formatReference(node.values[i]);
      entries.add("$key: $value");
    }
    printStmt(dummy, "LiteralMap (${entries.join(', ')})");
  }

  visitIsCheck(ir.IsCheck node) {
    String dummy = names.name(node);
    List<String> entries = new List<String>();
    String receiver = formatReference(node.receiver);
    printStmt(dummy, "IsCheck ($receiver ${node.type})");
  }

  visitAsCast(ir.AsCast node) {
    String dummy = names.name(node);
    List<String> entries = new List<String>();
    String receiver = formatReference(node.receiver);
    printStmt(dummy, "AsCast ($receiver ${node.type})");
  }

  visitInvokeContinuation(ir.InvokeContinuation node) {
    String dummy = names.name(node);
    String kont = formatReference(node.continuation);
    String args = node.arguments.map(formatReference).join(', ');
    printStmt(dummy, "InvokeContinuation $kont ($args)");
  }

  visitBranch(ir.Branch node) {
    String dummy = names.name(node);
    String condition = visit(node.condition);
    String trueCont = formatReference(node.trueContinuation);
    String falseCont = formatReference(node.falseContinuation);
    printStmt(dummy, "Branch $condition ($trueCont, $falseCont)");
  }

  String formatReference(ir.Reference ref) {
    ir.Definition target = ref.definition;
    if (target is ir.Continuation && target.body == null) {
      return "return"; // Do not generate a name for the return continuation
    } else {
      return names.name(ref.definition);
    }
  }

  String formatPrimitive(ir.Primitive p) => visit(p);

  visitConstant(ir.Constant node) {
    return "Constant ${node.value}";
  }

  visitParameter(ir.Parameter node) {
    return "Parameter ${names.name(node)}";
  }

  visitContinuation(ir.Continuation node) {
    return "Continuation ${names.name(node)}";
  }

  visitIsTrue(ir.IsTrue node) {
    return "IsTrue(${names.name(node.value.definition)})";
  }

  visitThis(ir.This node) {
    return "This";
  }

  visitReifyTypeVar(ir.ReifyTypeVar node) {
    return "ReifyTypeVar ${node.element.name}";
  }

  visitCondition(ir.Condition c) {}
  visitExpression(ir.Expression e) {}
  visitPrimitive(ir.Primitive p) {}
  visitDefinition(ir.Definition d) {}
  visitNode(ir.Node n) {}
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
    'x': 0
  };

  String prefix(x) {
    if (x is ir.Parameter) return 'r';
    if (x is ir.Continuation || x is ir.FunctionDefinition) return 'B';
    if (x is ir.Primitive) return 'v';
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
  final List<ir.Parameter> parameters;
  final ir.Expression body;
  final List<Block> succ = <Block>[];
  final List<Block> pred = <Block>[];

  Block(this.name, this.parameters, this.body);

  void addEdgeTo(Block successor) {
    succ.add(successor);
    successor.pred.add(this);
  }
}

class BlockCollector extends ir.Visitor {
  Block entry;
  final Map<ir.Continuation, Block> cont2block = <ir.Continuation, Block>{};
  Block current_block;

  Names names;
  BlockCollector(this.names);

  Block getBlock(ir.Continuation c) {
    Block block = cont2block[c];
    if (block == null) {
      block = new Block(names.name(c), c.parameters, c.body);
      cont2block[c] = block;
    }
    return block;
  }

  visitFunctionDefinition(ir.FunctionDefinition f) {
    entry = current_block = new Block(names.name(f), [], f.body);
    visit(f.body);
  }

  visitLetPrim(ir.LetPrim exp) {
    visit(exp.body);
  }

  visitLetCont(ir.LetCont exp) {
    visit(exp.continuation);
    visit(exp.body);
  }

  visitInvokeStatic(ir.InvokeStatic exp) {
    ir.Definition target = exp.continuation.definition;
    if (target is ir.Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitInvokeMethod(ir.InvokeMethod exp) {
    ir.Definition target = exp.continuation.definition;
    if (target is ir.Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitInvokeConstructor(ir.InvokeConstructor exp) {
    ir.Definition target = exp.continuation.definition;
    if (target is ir.Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitConcatenateStrings(ir.ConcatenateStrings exp) {
    ir.Definition target = exp.continuation.definition;
    if (target is ir.Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitInvokeContinuation(ir.InvokeContinuation exp) {
    ir.Definition target = exp.continuation.definition;
    if (target is ir.Continuation && target.body != null) {
      current_block.addEdgeTo(getBlock(target));
    }
  }

  visitBranch(ir.Branch exp) {
    ir.Continuation trueTarget = exp.trueContinuation.definition;
    if (trueTarget.body != null) {
      current_block.addEdgeTo(getBlock(trueTarget));
    }
    ir.Continuation falseTarget = exp.falseContinuation.definition;
    if (falseTarget.body != null) {
      current_block.addEdgeTo(getBlock(falseTarget));
    }
  }

  visitContinuation(ir.Continuation c) {
    var old_node = current_block;
    current_block = getBlock(c);
    visit(c.body);
    current_block = old_node;
  }
}
