library dart_backend.tracer;

import 'dart:async' show EventSink;
import '../tracer.dart';
import 'dart_tree.dart';
  
class TreeTracer extends TracerUtil implements Visitor {
  
  final EventSink<String> output;
  
  TreeTracer(this.output);
  
  Names names;
  int stmtCounter;
  
  void traceGraph(String name, Expression exp) {
    names = new Names();
    stmtCounter = 0;
    tag("cfg", () {
      printProperty("name", name);
      printBlock(exp);
    });
    names = null;
  }
  
  void printBlock(Expression e) {
    tag("block", () {
      printProperty("name", "B0"); // Update when proper blocks exist
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      printProperty("predecessors", ""); // Update when proper blocks exist
      printProperty("successors", ""); // Update when proper blocks exist
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
        });
      });
      tag("HIR", () {
        e.accept(this);
      });
    });
  }
  
  void printStmt(String def, String contents) {
    int bci = 0;
    int uses = 0;
    if (def == null) {
      def = 'x${stmtCounter++}';
    }
    addIndent();
    add("$bci $uses $def $contents <|@\n");
  }
  
  visitVariable(Variable node) {
    printStmt(null, "dead-use ${names.varName(node)}");
  }
  
  visitSequence(Sequence node) {
    for (Expression e in node.expressions) {
      e.accept(this);
    }
  }
  
  visitLetVal(LetVal node) {
    String name = names.varName(node.variable);
    String rhs = expr(node.definition);
    printStmt(name, "let $name = $rhs");
    node.body.accept(this);
  }
  
  visitInvokeStatic(InvokeStatic node) {
    printStmt(null, expr(node));
  }
  
  visitReturn(Return node) {
    printStmt(null, "return ${expr(node.value)}");
  }
  
  visitConstant(Constant node) {
    printStmt(null, "dead-use ${node.value}");
  }

  visitNode(Node node) {}
  visitExpression(Expression node) {}
  
  String expr(Expression e) {
    return e.accept(new SubExprVisitor(names));
  }
  
}

class SubExprVisitor implements Visitor<String> {
  Names names;
  
  SubExprVisitor(this.names);
  
  String visitVariable(Variable node) {
    return names.varName(node);
  }
  String visitSequence(Sequence node) {
    String exps = node.expressions.map((e) => e.accept(this)).join('; ');
    return "{ $exps }";
  }
  String visitLetVal(LetVal node) {
    String name = names.varName(node.variable);
    String def = node.definition.accept(this);
    String body = node.body.accept(this);
    return "(let $name = $def in $body)";
  }
  String visitInvokeStatic(InvokeStatic node) {
    String head = node.target.name;
    String args = node.arguments.map((e) => e.accept(this)).join(', ');
    return "$head($args)";
  }
  String visitReturn(Return node) {
    return "return ${node.value.accept(this)}";
  }
  String visitConstant(Constant node) {
    return "${node.value}";
  }
  
  visitNode(Node node) {}
  visitExpression(Expression node) {}
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
      if (v.identifier != null) {
        name = v.identifier.token.value;
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