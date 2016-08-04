// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.visualizer;

import 'constraints.dart';
import 'builder.dart';
import 'solver.dart';
import '../ast.dart';
import '../text/ast_to_text.dart';
import '../class_hierarchy.dart';

/// Visualizes the constraint system using a Graphviz dot graph.
///
/// Variables are visualized as nodes and constraints as labeled edges.
class Visualizer {
  final Program program;
  final Map<int, GraphNode> variableNodes = <int, GraphNode>{};
  final Map<int, FunctionNode> value2function = <int, FunctionNode>{};
  final Map<FunctionNode, int> function2value = <FunctionNode, int>{};
  final Map<int, Annotation> latticePointAnnotation = <int, Annotation>{};
  final Map<int, Annotation> valueAnnotation = <int, Annotation>{};
  FieldNames fieldNames;
  ConstraintSystem constraints;
  Solver solver;
  Builder builder;

  ClassHierarchy get hierarchy => builder.hierarchy;

  final Map<Member, Set<GraphNode>> _graphNodesInMember =
      <Member, Set<GraphNode>>{};

  Visualizer(this.program);

  static Set<GraphNode> _makeGraphNodeSet() => new Set<GraphNode>();

  Annotator getTextAnnotator() {
    return new TextAnnotator(this);
  }

  GraphNode getVariableNode(int variable) {
    return variableNodes[variable] ??= new GraphNode(variable);
  }

  /// Called from the builder to associate information with a variable.
  ///
  /// The [node] has two purposes: it ensures that the variable will show
  /// up in the graph for a the enclosing member, and the textual form of the
  /// node will be part of its label.
  ///
  /// The optional [info] argument provides additional context beyond the AST
  /// node.  When a constraint variable has no logical 1:1 corresondence with
  /// an AST node, it is best to pick a nearby AST node and set the [info] to
  /// clarify its relationship with the node.
  void annotateVariable(int variable, TreeNode astNode, [String info]) {
    if (astNode != null || info != null) {
      if (astNode is VariableSet ||
          astNode is PropertySet ||
          astNode is StaticSet) {
        // These will also be registered for the right-hand side, which makes
        // for a better annotation.
        return;
      }
      var node = getVariableNode(variable);
      Member member = _getEnclosingMember(astNode);
      node.addAnnotation(member, astNode, info);
      _graphNodesInMember.putIfAbsent(member, _makeGraphNodeSet).add(node);
    }
  }

  void annotateAssign(int source, int destination, TreeNode node) {
    addEdge(source, destination, _getEnclosingMember(node), '');
  }

  void annotateSink(int source, int destination, TreeNode node) {
    addEdge(source, destination, _getEnclosingMember(node), 'sink');
  }

  void annotateLoad(int object, int field, int destination, Member member) {
    String fieldName = fieldNames.getDiagnosticNameOfField(field);
    addEdge(object, destination, member, 'Load[$fieldName]');
  }

  void annotateStore(int object, int field, int source, Member member) {
    String fieldName = fieldNames.getDiagnosticNameOfField(field);
    addEdge(source, object, member, 'Store[$fieldName]');
  }

  void annotateDirectStore(int object, int field, int source, Member member) {
    String fieldName = fieldNames.getDiagnosticNameOfField(field);
    addEdge(source, object, member, 'Store![$fieldName]');
  }

  void annotateLatticePoint(int point, TreeNode node, [String info]) {
    latticePointAnnotation[point] = new Annotation(node, info);
  }

  void annotateValue(int value, TreeNode node, [String info]) {
    valueAnnotation[value] = new Annotation(node, info);
  }

  String getLatticePointName(int latticePoint) {
    if (latticePoint < 0) return 'bottom';
    return latticePointAnnotation[latticePoint].toLabel();
  }

  String getValueName(int value) {
    return valueAnnotation[value].toLabel();
  }

  static Member _getEnclosingMember(TreeNode node) {
    while (node != null) {
      if (node is Member) return node;
      node = node.parent;
    }
    return null;
  }

  void addEdge(int source, int destination, Member member, String label) {
    var sourceNode = getVariableNode(source);
    var destinationNode = getVariableNode(destination);
    _graphNodesInMember.putIfAbsent(member, _makeGraphNodeSet)
      ..add(sourceNode)
      ..add(destinationNode);
    sourceNode.addEdgeTo(destinationNode, member, label);
  }

  void annotateFunction(int value, FunctionNode function) {
    value2function[value] = function;
    function2value[function] = value;
  }

  FunctionNode getFunctionFromValue(int value) {
    return value2function[value];
  }

  int getFunctionValue(FunctionNode node) {
    return function2value[node];
  }

  Set<GraphNode> _getNodesInMember(Member member) {
    return _graphNodesInMember.putIfAbsent(member, _makeGraphNodeSet);
  }

  String _getCodeAsLabel(Member member) {
    String code = debugNodeToString(member);
    code = escapeLabel(code);
    // Replace line-breaks with left-aligned breaks.
    code = code.replaceAll('\n', '\\l');
    return code;
  }

  String _getValueLabel(GraphNode node) {
    int latticePoint = solver.getVariableValue(node.variable);
    if (latticePoint < 0) return 'bottom';
    return escapeLabel(shorten(getLatticePointName(latticePoint)));
  }

  /// Returns the Graphviz Dot code a the subgraph relevant for [member].
  String dumpMember(Member member) {
    int freshIdCounter = 0;
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('digraph {');
    String source = _getCodeAsLabel(member);
    buffer.writeln('source [shape=box,label="$source"]');
    for (GraphNode node in _getNodesInMember(member)) {
      int id = node.variable;
      String label = node.getAnnotationInContextOf(member);
      // Global nodes have a ton of edges that are visualized specially.
      // If the global node has a local annotation, also print its annotated
      // version somewhere, but omit all its edges.
      if (node.isGlobal) {
        if (label != '') {
          label += '\n${node.globalAnnotation.toLabel()}';
          buffer.writeln('$id [shape=record,label="$label"]');
        }
        continue;
      }
      String value = _getValueLabel(node);
      buffer.writeln('$id [shape=record,label="{$label|$value}"]');
      // Add outgoing edges.
      // Keep track of all that edges leave the context of the current member
      // ("external edges").  There can be a huge number of these, so we compact
      // them into a single outgoing edge so as not to flood the graph.
      Set<String> outgoingExternalEdgeLabels = new Set<String>();
      for (Edge edge in node.outputs) {
        if (edge.to.isLocal(member)) {
          buffer.writeln('$id -> ${edge.to.variable} [label="${edge.label}"]');
        } else if (outgoingExternalEdgeLabels.length < 3) {
          String annotation = edge.to.externalLabel;
          if (annotation != '') {
            if (edge.label != '') {
              annotation = '${edge.label} → $annotation';
            }
            outgoingExternalEdgeLabels.add(annotation);
          }
        } else if (outgoingExternalEdgeLabels.length == 3) {
          outgoingExternalEdgeLabels.add('...');
        }
      }
      // Emit the outgoing external edge.
      if (outgoingExternalEdgeLabels.isNotEmpty) {
        int freshId = ++freshIdCounter;
        String outLabel = outgoingExternalEdgeLabels.join('\n');
        buffer.writeln('x$freshId [shape=box,style=dotted,label="$outLabel"]');
        buffer.writeln('$id -> x$freshId [style=dotted]');
      }
      // Show ingoing external edges. As before, avoid flooding the graph in
      // case there are too many of them.
      Set<String> ingoingExternalEdgeLabels = new Set<String>();
      for (Edge edge in node.inputs) {
        GraphNode source = edge.from;
        if (source.isLocal(member)) continue;
        String annotation = source.externalLabel;
        if (annotation != '') {
          if (ingoingExternalEdgeLabels.length < 3) {
            if (edge.label != '') {
              annotation = '$annotation → ${edge.label}';
            }
            ingoingExternalEdgeLabels.add(annotation);
          } else {
            ingoingExternalEdgeLabels.add('...');
            break;
          }
        }
      }
      // Emit the ingoing external edge.
      if (ingoingExternalEdgeLabels.isNotEmpty) {
        int freshId = ++freshIdCounter;
        String sourceLabel = ingoingExternalEdgeLabels.join('\n');
        buffer.writeln('x$freshId '
            '[shape=box,style=dotted,label="$sourceLabel"]');
        buffer.writeln('x$freshId -> ${node.variable} [style=dotted]');
      }
    }
    buffer.writeln('}');
    return '$buffer';
  }
}

class Annotation {
  final TreeNode node;
  final String info;

  Annotation(this.node, this.info);

  String toLabel() {
    if (node == null && info == null) return '(missing annotation)';
    if (node == null) return escapeLabel(info);
    String label = node is NullLiteral
        ? 'null literal'
        : node is FunctionNode ? shorten('${node.parent}') : shorten('$node');
    if (info != null) {
      label = '$info: $label';
    }
    label = escapeLabel(label);
    return label;
  }

  String toLabelWithContext(Member member) {
    String label = toLabel();
    if (node == member) {
      return label;
    } else {
      return '$label in $member';
    }
  }
}

class GraphNode {
  final int variable;
  final List<Edge> inputs = <Edge>[];
  final List<Edge> outputs = <Edge>[];
  final List<Annotation> annotations = <Annotation>[];

  /// The annotation to show when visualized in the context of a given member.
  final Map<Member, Annotation> annotationForContext = <Member, Annotation>{};

  GraphNode(this.variable);

  bool get isGlobal => annotationForContext.containsKey(null);
  Annotation get globalAnnotation => annotationForContext[null];
  bool isInScope(Member member) => annotationForContext.containsKey(member);
  bool isLocal(Member member) => !isGlobal && isInScope(member);

  /// The label to show for the given node when seen from the context of
  /// another member.
  String get externalLabel {
    if (isGlobal) return globalAnnotation.toLabel();
    if (annotationForContext.isEmpty) return '$variable';
    Member member = annotationForContext.keys.first;
    Annotation annotation = annotationForContext[member];
    return '$variable:' + annotation.toLabelWithContext(member);
  }

  String getAnnotationInContextOf(Member member) {
    if (annotationForContext.isEmpty) return '';
    Annotation annotation = annotationForContext[member];
    if (annotation != null) return '$variable:' + annotation.toLabel();
    annotation =
        annotationForContext[null] ?? annotationForContext.values.first;
    return '$variable:' + annotation.toLabelWithContext(member);
  }

  void addEdgeTo(GraphNode other, Member member, String label) {
    Edge edge = new Edge(this, other, member, label);
    outputs.add(edge);
    other.inputs.add(edge);
  }

  void addAnnotation(Member member, TreeNode astNode, String info) {
    var annotation = new Annotation(astNode, info);
    annotations.add(annotation);
    annotationForContext[member] = annotation;
  }
}

class Edge {
  final GraphNode from, to;
  final Member member;
  final String label;

  Edge(this.from, this.to, this.member, this.label);
}

final RegExp escapeRegexp = new RegExp('["{}<>|]', multiLine: true);

/// Escapes characters in [text] so it can be used as part of a label.
String escapeLabel(String text) {
  return text.replaceAllMapped(escapeRegexp, (m) => '\\${m.group(0)}');
}

String shorten(String text) {
  text = text.replaceAll('\n  ', ' ').replaceAll('\n', ' ').trim();
  if (text.length > 60) {
    return text.substring(0, 30) + '...' + text.substring(text.length - 27);
  }
  return text;
}

class TextAnnotator extends Annotator {
  final Visualizer visualizer;
  final Map<VariableDeclaration, int> variables = <VariableDeclaration, int>{};
  final Map<FunctionNode, int> functionReturns = <FunctionNode, int>{};

  Builder get builder => visualizer.builder;

  String getReference(Node node, Printer printer) {
    if (node is Class) return printer.getClassReference(node);
    if (node is Member) return printer.getMemberReference(node);
    if (node is Library) return printer.getLibraryReference(node);
    return debugNodeToString(node);
  }

  String getValueForVariable(Printer printer, int variable) {
    if (variable == null) {
      return '<missing type>';
    }
    var value = visualizer.solver.getValueInferredForVariable(variable);
    return printer.getInferredValueString(value);
  }

  TextAnnotator(this.visualizer) {
    // The correspondence between AST and constraint system is exposed by the
    // builder, but only at the level of Members.
    // To get to the correspondence at the statement/expression level, we use
    // the annotation map from the visualizer API.
    // TODO(asgerf): If we use these annotations for testing, the necessary
    //   bindings should arguably be part of the API for the Builder.
    visualizer.variableNodes.forEach((int variable, GraphNode node) {
      for (Annotation annotation in node.annotations) {
        if (annotation.node is VariableDeclaration && annotation.info == null) {
          variables[annotation.node] = variable;
        }
        if (annotation.node is FunctionNode && annotation.info == 'return') {
          functionReturns[annotation.node] = variable;
        }
      }
    });
  }

  String annotateVariable(Printer printer, VariableDeclaration node) {
    return getValueForVariable(
        printer, builder.global.parameters[node] ?? variables[node]);
  }

  String annotateReturn(Printer printer, FunctionNode node) {
    if (node.parent is Constructor) return null;
    return getValueForVariable(printer, builder.global.returns[node]);
  }

  String annotateField(Printer printer, Field node) {
    return getValueForVariable(printer, builder.global.fields[node]);
  }
}
