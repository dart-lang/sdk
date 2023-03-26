// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.inferrer.type_graph_dump;

import '../../compiler_api.dart' as api;
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import 'abstract_value_domain.dart';
import 'engine.dart';
import 'type_graph_nodes.dart';
import 'debug.dart';

/// Dumps the type inference graph in Graphviz Dot format into the `typegraph`
/// subfolder of the current working directory. Each function body is dumped in
/// a separate file.
///
/// The resulting .dot files must be processed using the Graphviz `dot` command,
/// which can be obtained from `http://www.graphviz.org`, or installed using
/// most package managers (search for `graphviz` or `dot`).
///
/// Example commands:
///
///     dot -Tpng -O typegraph/main.dot
///     open typegraph/main.dot.png
///
///     dot -Tpng -O typegraph/dart._internal.Sort._dualPivotQuicksort.dot
///     open typegraph/dart._internal.Sort._dualPivotQuicksort.dot.png
///
class TypeGraphDump {
  static const String outputDir = 'typegraph';

  final api.CompilerOutput compilerOutput;
  final InferrerEngine inferrer;
  final Map<TypeInformation, Set<TypeInformation>> assignmentsBeforeAnalysis =
      <TypeInformation, Set<TypeInformation>>{};
  final Map<TypeInformation, Set<TypeInformation>> assignmentsBeforeTracing =
      <TypeInformation, Set<TypeInformation>>{};
  final Set<String> usedFilenames = Set<String>();

  TypeGraphDump(this.compilerOutput, this.inferrer);

  /// Take a copy of the assignment set for each node, since that may change
  /// during the analysis.
  void beforeAnalysis() {
    for (TypeInformation node in inferrer.types.allTypes) {
      Set<TypeInformation> copy = node.inputs.toSet();
      if (!copy.isEmpty) {
        assignmentsBeforeAnalysis[node] = copy;
      }
    }
  }

  /// Like [beforeAnalysis], takes a copy of the assignment sets.
  void beforeTracing() {
    for (TypeInformation node in inferrer.types.allTypes) {
      Set<TypeInformation> copy = node.inputs.toSet();
      if (!copy.isEmpty) {
        assignmentsBeforeTracing[node] = copy;
      }
    }
  }

  /// Dumps the entire graph.
  void afterAnalysis() {
    // Group all the type nodes by their context member.
    Map<MemberEntity, List<TypeInformation>> nodes =
        <MemberEntity, List<TypeInformation>>{};
    for (TypeInformation node in inferrer.types.allTypes) {
      final contextMember = node.contextMember;
      if (contextMember != null) {
        nodes.putIfAbsent(contextMember, () => <TypeInformation>[]).add(node);
      }
    }
    // Print every group separately.
    for (MemberEntity element in nodes.keys) {
      api.OutputSink? output;
      try {
        String name = filenameFromElement(element);
        output = compilerOutput.createOutputSink(
            '$outputDir/$name', 'dot', api.OutputType.debug);
        _GraphGenerator visitor = _GraphGenerator(
            this, element, output, inferrer.abstractValueDomain.getCompactText);
        for (TypeInformation node in nodes[element]!) {
          visitor.visit(node);
        }
        visitor.addMissingNodes();
        visitor.finish();
      } finally {
        if (output != null) {
          output.close();
        }
      }
    }
  }

  /// Returns the filename (without extension) in which to dump the type
  /// graph for [element].
  ///
  /// Will never return the a given filename more than once, even if called with
  /// the same element.
  String filenameFromElement(MemberEntity element) {
    // The toString method of elements include characters that are unsuitable
    // for URIs and file systems.
    List<String?> parts = [];
    parts.add(element.library.canonicalUri.pathSegments.last);
    parts.add(element.enclosingClass?.name);
    if (element.isGetter) {
      parts.add('get-${element.name}');
    } else if (element.isSetter) {
      parts.add('set-${element.name}');
    } else if (element is ConstructorEntity) {
      if (element.name!.isEmpty) {
        parts.add('-constructor');
      } else {
        parts.add(element.name);
      }
    } else {
      parts.add(
          utils.operatorNameToIdentifier(element.name)!.replaceAll(r'$', '-'));
    }
    String filename = parts.where((x) => x != null && x != '').join('.');
    if (usedFilenames.add(filename)) return filename;
    // The filename has already been used by another method. Append a serial
    // number to ensure we don't overwrite it.
    int serialNumber = 2;
    while (!usedFilenames.add('$filename-$serialNumber')) {
      ++serialNumber;
    }
    return '$filename-$serialNumber';
  }
}

/// Builds the Graphviz Dot file for one function body.
class _GraphGenerator extends TypeInformationVisitor {
  final TypeGraphDump global;
  final Set<TypeInformation> seen = Set<TypeInformation>();
  final List<TypeInformation> worklist = <TypeInformation>[];
  final Map<TypeInformation, int> nodeId = <TypeInformation, int>{};
  final String Function(AbstractValue) formatType;
  int usedIds = 0;
  final api.OutputSink output;
  final MemberEntity element;
  final TypeInformation returnValue;

  _GraphGenerator(this.global, this.element, this.output, this.formatType)
      : returnValue = global.inferrer.types.getInferredTypeOfMember(element) {
    getNode(returnValue); // Ensure return value is part of graph.
    append('digraph {');
  }

  void finish() {
    append('}');
  }

  /// Ensures that all nodes which have been referenced are generated.
  ///
  /// Sometimes an input to a TypeInformation node does not belong to the same
  /// function body, and the graph looks confusing if they are missing.
  void addMissingNodes() {
    while (worklist.isNotEmpty) {
      TypeInformation node = worklist.removeLast();
      assert(nodeId.containsKey(node));
      visit(node);
    }
  }

  void visit(TypeInformation info) {
    if (seen.contains(info)) return;
    info.accept(this);
  }

  void append(String string) {
    output
      ..add(string)
      ..add('\n');
  }

  String shorten(String text) {
    if (text.length > 40) {
      return text.substring(0, 19) + '...' + text.substring(text.length - 18);
    }
    return text;
  }

  int getFreshId() => ++usedIds;

  /// Obtains a unique ID for the node representing [info].
  String getNode(TypeInformation info) {
    int id = nodeId.putIfAbsent(info, () {
      worklist.add(info); // Ensure that the referenced node is generated.
      return getFreshId();
    });
    return '$id';
  }

  final RegExp escapeRegexp = RegExp('["{}<>|]');

  /// Escapes characters in [text] so it can be used as part of a label.
  String escapeLabel(String text) {
    return text.replaceAllMapped(escapeRegexp, (m) => '\\${m.group(0)}');
  }

  /// Creates an edge from [src] to [dst].
  ///
  /// If [dst] is a record type node, [port] may refer to one of the fields
  /// defined in that record (e.g. `obj`, `arg0`, `arg1`, etc)
  void addEdge(TypeInformation src, TypeInformation dst,
      {String? port, String? color = 'black'}) {
    if (isExternal(src) && isExternal(dst)) {
      return; // Do not add edges between external nodes.
    }
    String dstText = getNode(dst);
    if (port != null) {
      dstText += ':$port';
    }
    if (src is ConcreteTypeInformation) {
      // Concrete types can have a huge number of uses which will flood the
      // graph with very long hard-to-follow edges. Copy the concrete nodes
      // for every use to enhance readability.
      int id = getFreshId();
      String type = escapeLabel('${formatType(src.type)}');
      String text = 'Concrete';
      String label = '{$text|<returnType> $type}';
      append('$id [shape=record,style=dotted,label="$label"]');
      append('$id -> $dstText [color="$color"]');
    } else {
      append('${getNode(src)}:returnType -> $dstText [color="$color"]');
    }
  }

  // Some graphs are flooded by a huge number of phi and narrow nodes.
  // We color the nodes so the "interesting" nodes stand out more.
  static const String defaultNodeColor = '#eeffee';
  static const String phiColor = '#eeffff';
  static const String narrowColor = phiColor;
  static const String callColor = '#ffffee';

  // Colors for edges based on whether they were added or removed during the
  // analysis.
  static const String unchangedEdge = 'black';
  static const String addedEdge = 'green4';
  static const String removedEdge = 'red3';
  static const String temporaryEdge = 'orange'; // Added and then removed again.

  bool isExternal(TypeInformation node) {
    return node != returnValue && node.contextMember != element;
  }

  String getStyleForNode(TypeInformation node, String color) {
    return isExternal(node)
        ? 'style=dotted'
        : 'style=filled,fillcolor="$color"';
  }

  /// Adds details that are not specific to a subclass of [TypeInformation].
  String appendDetails(TypeInformation node, String text) {
    if (node == returnValue) {
      return '$text\n(return value)';
    }
    if (node.contextMember != null && node.contextMember != element) {
      return '$text\n(from ${node.contextMember})';
    }
    return text;
  }

  /// Creates a node for [node] displaying the given [text] in its box.
  ///
  /// [inputs] specify named inputs to the node. If omitted, edges will be
  /// based on [node.inputs].
  void addNode(TypeInformation node, String text,
      {String color = defaultNodeColor, Map<String, TypeInformation>? inputs}) {
    seen.add(node);
    String style = getStyleForNode(node, color);
    text = appendDetails(node, text);
    text = escapeLabel(text);
    String id = getNode(node);
    String returnType = escapeLabel(formatType(node.type));
    if (inputs != null) {
      Iterable<String> keys = inputs.keys.where((key) => inputs[key] != null);
      String header = keys.map((key) => '<a$key> $key').join('|');
      String label = '{{$header}|$text|<returnType> $returnType}';
      append('$id [shape=record,label="$label",$style]');
      for (String key in keys) {
        addEdge(inputs[key]!, node, port: 'a$key');
      }
    } else {
      String label = '{$text|<returnType> $returnType}';
      append('$id [shape=record,label="$label",$style]');
      // Add assignment edges. Color the edges based on whether they were
      // added, removed, temporary, or unchanged.
      final originalSet = global.assignmentsBeforeAnalysis[node] ?? const {};
      var tracerSet = global.assignmentsBeforeTracing[node] ?? const {};
      var currentSet = node.inputs.toSet();
      for (TypeInformation assignment in currentSet) {
        String color =
            originalSet.contains(assignment) ? unchangedEdge : addedEdge;
        addEdge(assignment, node, color: color);
      }
      for (TypeInformation assignment in originalSet) {
        if (!currentSet.contains(assignment)) {
          addEdge(assignment, node, color: removedEdge);
        }
      }
      for (TypeInformation assignment in tracerSet) {
        if (!currentSet.contains(assignment) &&
            !originalSet.contains(assignment)) {
          addEdge(assignment, node, color: temporaryEdge);
        }
      }
    }
    if (PRINT_GRAPH_ALL_NODES) {
      for (TypeInformation user in node.users) {
        if (!isExternal(user)) {
          visit(user);
        }
      }
    }
  }

  @override
  void visitNarrowTypeInformation(NarrowTypeInformation info) {
    // Omit unused Narrows.
    if (!PRINT_GRAPH_ALL_NODES && info.users.isEmpty) return;
    addNode(info, 'Narrow\n${formatType(info.typeAnnotation)}',
        color: narrowColor);
  }

  @override
  void visitPhiElementTypeInformation(PhiElementTypeInformation info) {
    // Omit unused Phis.
    if (!PRINT_GRAPH_ALL_NODES && info.users.isEmpty) return;
    addNode(info, 'Phi ${info.variable?.name ?? ''}', color: phiColor);
  }

  @override
  void visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info) {
    addNode(info, 'ElementInContainer');
  }

  @override
  void visitElementInSetTypeInformation(ElementInSetTypeInformation info) {
    addNode(info, 'ElementInSet');
  }

  @override
  void visitKeyInMapTypeInformation(KeyInMapTypeInformation info) {
    addNode(info, 'KeyInMap');
  }

  @override
  void visitValueInMapTypeInformation(ValueInMapTypeInformation info) {
    addNode(info, 'ValueInMap');
  }

  @override
  void visitRecordFieldAccessTypeInformation(
      RecordFieldAccessTypeInformation info) {
    addNode(info, 'RecordFieldAccess(${info.getterName})',
        color: callColor, inputs: {'obj': info.receiver});
  }

  @override
  void visitListTypeInformation(ListTypeInformation info) {
    addNode(info, 'List');
  }

  @override
  void visitSetTypeInformation(SetTypeInformation info) {
    addNode(info, 'Set');
  }

  @override
  void visitMapTypeInformation(MapTypeInformation info) {
    addNode(info, 'Map');
  }

  @override
  void visitRecordTypeInformation(RecordTypeInformation info) {
    addNode(info, 'Record');
  }

  @override
  void visitConcreteTypeInformation(ConcreteTypeInformation info) {
    addNode(info, 'Concrete');
  }

  @override
  void visitStringLiteralTypeInformation(StringLiteralTypeInformation info) {
    String text = shorten(info.value).replaceAll('\n', '\\n');
    addNode(info, 'StringLiteral\n"$text"');
  }

  @override
  void visitBoolLiteralTypeInformation(BoolLiteralTypeInformation info) {
    addNode(info, 'BoolLiteral\n${info.value}');
  }

  void handleCall(CallSiteTypeInformation info, String text,
      Map<String, TypeInformation> inputs) {
    String sourceCode = shorten('${info.debugName}');
    text = '$text\n$sourceCode';
    final arguments = info.arguments;
    if (arguments != null) {
      for (int i = 0; i < arguments.positional.length; ++i) {
        inputs['arg$i'] = arguments.positional[i];
      }
      for (String argName in arguments.named.keys) {
        inputs[argName] = arguments.named[argName]!;
      }
    }
    addNode(info, text, color: callColor, inputs: inputs);
  }

  @override
  void visitClosureCallSiteTypeInformation(
      ClosureCallSiteTypeInformation info) {
    handleCall(info, 'ClosureCallSite', {});
  }

  @override
  void visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    handleCall(info, 'StaticCallSite', {});
  }

  @override
  void visitDynamicCallSiteTypeInformation(
      DynamicCallSiteTypeInformation info) {
    handleCall(info, 'DynamicCallSite', {'obj': info.receiver});
  }

  @override
  void visitMemberTypeInformation(MemberTypeInformation info) {
    addNode(info, 'Member\n${info.debugName}');
  }

  @override
  void visitParameterTypeInformation(ParameterTypeInformation info) {
    addNode(info, 'Parameter ${info.debugName}');
  }

  @override
  void visitClosureTypeInformation(ClosureTypeInformation info) {
    String text = shorten('${info.debugName}');
    addNode(info, 'Closure\n$text');
  }

  @override
  void visitAwaitTypeInformation(AwaitTypeInformation info) {
    String text = shorten('${info.debugName}');
    addNode(info, 'Await\n$text');
  }

  @override
  void visitYieldTypeInformation(YieldTypeInformation info) {
    String text = shorten('${info.debugName}');
    addNode(info, 'Yield\n$text');
  }
}
