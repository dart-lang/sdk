library kernel.type_propagation.visualizer;

import 'constraints.dart';
import 'builder.dart';
import 'solver.dart';
import '../ast.dart';
import '../text/ast_to_text.dart';

/// Visualizes the constraint system using a Graphviz dot graph.
///
/// Variables are visualized as nodes and constraints as labeled edges.
class Visualizer {
  final Program program;
  final Map<int, List<Annotation>> annotations = <int, List<Annotation>>{};
  FieldNames fieldNames;
  ConstraintSystem constraints;
  Solver solver;
  Builder builder;

  List<GraphNode> _graphNodes;
  final Map<Member, Set<GraphNode>> _graphNodesInMember =
      <Member, Set<GraphNode>>{};

  Visualizer(this.program);

  static List<Annotation> _makeAnnotationList() => <Annotation>[];
  static Set<GraphNode> _makeGraphNodeSet() => new Set<GraphNode>();

  List<Annotation> getAnnotations(int variable) {
    return annotations.putIfAbsent(variable, _makeAnnotationList);
  }

  Annotator getTextAnnotator() {
    return new TextAnnotator(this);
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
  void annotateVariable(int variable, TreeNode node, [String info]) {
    if (node != null || info != null) {
      if (node is VariableSet || node is PropertySet || node is StaticSet) {
        // There will always be a separte annotation added for the right-hand
        // side of these nodes, which gives a better visualization.
        return;
      }
      getAnnotations(variable).add(new Annotation(node, info));
    }
  }

  Set<GraphNode> _getNodesInMember(Member member) {
    return _graphNodesInMember.putIfAbsent(member, _makeGraphNodeSet);
  }

  /// Builds the entire graph.
  ///
  /// Because the graph is too large to visualize at once, we also build an
  /// index for lookup up the subgraph that is relevant for a given member.
  void _buildGraph() {
    _graphNodes = new List<GraphNode>(constraints.numberOfVariables);
    // Create all the graph nodes and index them by their enclosing members.
    for (int i = 0; i < constraints.numberOfVariables; ++i) {
      var graphNode = new GraphNode(i);
      _graphNodes[i] = graphNode;
      for (var annotation in getAnnotations(i)) {
        // Note: the member may be null, and this is intentional.
        // We use null as context for "global" nodes.
        Member member = _getEnclosingMember(annotation.node);
        graphNode.annotationForContext[member] = annotation;
        _getNodesInMember(member).add(graphNode);
      }
    }
    // Add all the constraint edges.
    for (int i = 0; i < constraints.assignments.length; i += 2) {
      int source = constraints.assignments[i];
      int destination = constraints.assignments[i + 1];
      GraphNode sourceNode = _graphNodes[source];
      GraphNode destinationNode = _graphNodes[destination];
      sourceNode.addEdgeTo(destinationNode);
    }
    for (int i = 0; i < constraints.loads.length; i += 3) {
      int object = constraints.loads[i];
      int field = constraints.loads[i + 1];
      int destination = constraints.loads[i + 2];
      GraphNode objectNode = _graphNodes[object];
      String fieldName = fieldNames.getDiagnosticNameOfField(field);
      GraphNode destinationNode = _graphNodes[destination];
      objectNode.addEdgeTo(destinationNode,
          label: escapeLabel('Load[$fieldName]'));
    }
    for (int i = 0; i < constraints.stores.length; i += 3) {
      int object = constraints.stores[i];
      int field = constraints.stores[i + 1];
      int source = constraints.stores[i + 2];
      GraphNode objectNode = _graphNodes[object];
      String fieldName = fieldNames.getDiagnosticNameOfField(field);
      GraphNode sourceNode = _graphNodes[source];
      sourceNode.addEdgeTo(objectNode, label: escapeLabel('Store[$fieldName]'));
    }
  }

  Member _getEnclosingMember(TreeNode node) {
    while (node != null) {
      if (node is Member) return node;
      node = node.parent;
    }
    return null;
  }

  String _getCodeAsLabel(Member member) {
    String code = debugNodeToString(member);
    code = escapeLabel(code);
    // Replace line-breaks with left-aligned breaks.
    code = code.replaceAll('\n', '\\l');
    return code;
  }

  /// Returns the Graphviz Dot code a the subgraph relevant for [member].
  String dumpMember(Member member) {
    if (_graphNodes == null) {
      _buildGraph();
    }
    int freshIdCounter = 0;
    StringBuffer buffer = new StringBuffer();
    buffer.writeln('digraph {');
    String source = _getCodeAsLabel(member);
    buffer.writeln('source [shape=box,label="$source"]');
    for (GraphNode node in _getNodesInMember(member)) {
      int id = node.variable;
      Annotation annotation = node.annotationForContext[member];
      String label = annotation.toLabel();
      if (node.isGlobal) {
        label += '\n${node.globalAnnotation.toLabel()}';
      }
      buffer.writeln('$id [shape=box,label="$label"]');
      // Add outgoing edges.
      // Keep track of all that edges leave the context of the current member
      // ("external edges").  There can be a huge number of these, so we compact
      // them into a single outgoing edge so as not to flood the graph.
      Set<String> outgoingExternalEdgeLabels = new Set<String>();
      for (Edge edge in node.outputs) {
        if (edge.to.annotationForContext.containsKey(member)) {
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
      if (!node.isGlobal && outgoingExternalEdgeLabels.isNotEmpty) {
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
        if (source.isInScope(member)) continue;
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
    String label = node is NullLiteral ? 'null literal' : shorten('$node');
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

  /// The annotation to show when visualized in the context of a given member.
  final Map<Member, Annotation> annotationForContext = <Member, Annotation>{};

  GraphNode(this.variable);

  bool get isGlobal => annotationForContext.containsKey(null);
  Annotation get globalAnnotation => annotationForContext[null];
  bool isInScope(Member member) => annotationForContext.containsKey(member);

  /// The label to show for the given node when seen from the context of
  /// another member.
  String get externalLabel {
    if (isGlobal) return globalAnnotation.toLabel();
    if (annotationForContext.isEmpty) return '';
    Member member = annotationForContext.keys.first;
    Annotation annotation = annotationForContext[member];
    return annotation.toLabelWithContext(member);
  }

  void addEdgeTo(GraphNode other, {String label: ''}) {
    Edge edge = new Edge(this, other, label);
    outputs.add(edge);
    other.inputs.add(edge);
  }
}

class Edge {
  final GraphNode from, to;
  final String label;

  Edge(this.from, this.to, this.label);
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

  String getValueForVariable(Printer printer, int variable) {
    if (variable == null) {
      return '<missing type>';
    }
    Class value = visualizer.solver.getVariableValue(variable);
    if (value == null) {
      return 'bottom';
    } else {
      return printer.getClassReference(value);
    }
  }

  TextAnnotator(this.visualizer) {
    // The correspondence between AST and constraint system is exposed by the
    // builder, but only at the level of Members.
    // To get to the correspondence at the statement/expression level, we use
    // the annotation map from the visualizer API.
    // TODO(asgerf): If we use these annotations for testing, the necessary
    //   bindings should arguably be part of the API for the Builder.
    visualizer.annotations
        .forEach((int variable, List<Annotation> annotations) {
      for (Annotation annotation in annotations) {
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
        printer, builder.functionParameters[node] ?? variables[node]);
  }

  String annotateReturn(Printer printer, FunctionNode node) {
    return getValueForVariable(printer, functionReturns[node]);
  }

  String annotateField(Printer printer, Field node) {
    return getValueForVariable(printer, builder.fields[node]);
  }
}
