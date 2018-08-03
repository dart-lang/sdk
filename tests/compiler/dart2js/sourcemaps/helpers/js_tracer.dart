// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.js_tracer;

import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_source_mapping.dart';
import 'sourcemap_helper.dart';
import 'trace_graph.dart';

/// Create a [TraceGraph] for [info] registering usage in [coverage].
TraceGraph createTraceGraph(SourceMapInfo info, Coverage coverage) {
  TraceGraph graph = new TraceGraph();
  TraceListener listener = new StepTraceListener(graph);
  CodePositionMap codePositions =
      new CodePositionCoverage(info.jsCodePositions, coverage);
  JavaScriptTracer tracer = new JavaScriptTracer(
      codePositions, const SourceInformationReader(), [
    new CoverageListener(coverage, const SourceInformationReader()),
    listener
  ]);
  info.node.accept(tracer);
  return graph;
}

class StepTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  Map<js.Node, TraceStep> steppableMap = <js.Node, TraceStep>{};
  final TraceGraph graph;

  StepTraceListener(this.graph);

  SourceInformationReader get reader => const SourceInformationReader();

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    SourceInformation sourceInformation = computeSourceInformation(node);
    SourcePositionKind sourcePositionKind = SourcePositionKind.START;
    List text = [node];
    switch (kind) {
      case StepKind.FUN_ENTRY:
        text = ['<entry>'];
        break;
      case StepKind.FUN_EXIT:
        sourcePositionKind = SourcePositionKind.INNER;
        text = ['<exit>'];
        break;
      case StepKind.CALL:
        CallPosition callPosition =
            CallPosition.getSemanticPositionForCall(node);
        sourcePositionKind = callPosition.sourcePositionKind;
        break;
      case StepKind.NEW:
      case StepKind.RETURN:
      case StepKind.BREAK:
      case StepKind.CONTINUE:
      case StepKind.THROW:
      case StepKind.EXPRESSION_STATEMENT:
        break;
      case StepKind.IF_CONDITION:
        js.If ifNode = node;
        text = ['if(', ifNode.condition, ') ...'];
        break;
      case StepKind.FOR_INITIALIZER:
        js.For forNode = node;
        text = ['for(', forNode.init, '; ...) ...'];
        break;
      case StepKind.FOR_CONDITION:
        js.For forNode = node;
        text = ['for(...;', forNode.condition, '; ...) ...'];
        break;
      case StepKind.FOR_UPDATE:
        js.For forNode = node;
        text = ['for(...; ...', forNode.update, ') ...'];
        break;
      case StepKind.WHILE_CONDITION:
        js.While whileNode = node;
        text = ['while(', whileNode.condition, ') ...'];
        break;
      case StepKind.DO_CONDITION:
        js.Do doNode = node;
        text = ['do {... } (', doNode.condition, ')'];
        break;
      case StepKind.SWITCH_EXPRESSION:
        js.Switch switchNode = node;
        text = ['switch(', switchNode.key, ') ...'];
        break;
      case StepKind.NO_INFO:
        break;
    }
    createTraceStep(kind, node,
        offset: offset,
        sourceLocation:
            getSourceLocation(sourceInformation, sourcePositionKind),
        text: text);
  }

  void createTraceStep(StepKind kind, js.Node node,
      {Offset offset, List text, String note, SourceLocation sourceLocation}) {
    int id = steppableMap.length;

    if (text == null) {
      text = [node];
    }

    TraceStep step =
        new TraceStep(kind, id, node, offset, text, sourceLocation);
    graph.addStep(step);

    steppableMap[node] = step;
  }

  void pushBranch(BranchKind kind, [value]) {
    var branch;
    switch (kind) {
      case BranchKind.CONDITION:
        branch = value ? 't' : 'f';
        break;
      case BranchKind.LOOP:
        branch = 'l';
        break;
      case BranchKind.CATCH:
        branch = 'c';
        break;
      case BranchKind.FINALLY:
        branch = 'F';
        break;
      case BranchKind.CASE:
        branch = '$value';
        break;
    }
    graph.pushBranch(branch);
  }

  void popBranch() {
    graph.popBranch();
  }
}
