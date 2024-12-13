// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.js_tracer;

import 'package:compiler/src/io/code_output.dart';
import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js/js_source_mapping.dart';
import 'sourcemap_helper.dart';
import 'trace_graph.dart';

/// Create a [TraceGraph] for [info] registering usage in [coverage].
TraceGraph createTraceGraph(SourceMapInfo info, Coverage coverage) {
  TraceGraph graph = TraceGraph();
  TraceListener listener = StepTraceListener(graph);
  final outBuffer = NoopCodeOutput();
  SourceInformationProcessor sourceInformationProcessor =
      HelperOnlinePositionSourceInformationStrategy([
        CoverageListener(coverage, const SourceInformationReader()),
        listener,
      ]).createProcessor(
        SourceMapperProviderImpl(outBuffer),
        const SourceInformationReader(),
      );

  js.Dart2JSJavaScriptPrintingContext context =
      js.Dart2JSJavaScriptPrintingContext(
        null,
        outBuffer,
        sourceInformationProcessor,
        const js.JavaScriptAnnotationMonitor(),
      );
  js.Printer printer = js.Printer(
    const js.JavaScriptPrintingOptions(),
    context,
  );
  printer.visit(info.node);
  return graph;
}

class StepTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  Map<js.Node, TraceStep> steppableMap = <js.Node, TraceStep>{};
  final TraceGraph graph;

  StepTraceListener(this.graph);

  @override
  SourceInformationReader get reader => const SourceInformationReader();

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    SourceInformation? sourceInformation = computeSourceInformation(node);
    SourcePositionKind sourcePositionKind = SourcePositionKind.start;
    List text = [node];
    switch (kind) {
      case StepKind.funEntry:
        text = ['<entry>'];
        break;
      case StepKind.funExit:
        sourcePositionKind = SourcePositionKind.inner;
        text = ['<exit>'];
        break;
      case StepKind.call:
        CallPosition callPosition = CallPosition.getSemanticPositionForCall(
          node as js.Call,
        );
        sourcePositionKind = callPosition.sourcePositionKind;
        break;
      case StepKind.access:
      case StepKind.new_:
      case StepKind.return_:
      case StepKind.break_:
      case StepKind.continue_:
      case StepKind.throw_:
      case StepKind.expressionStatement:
        break;
      case StepKind.ifCondition:
        final ifNode = node as js.If;
        text = ['if(', ifNode.condition, ') ...'];
        break;
      case StepKind.forInitializer:
        final forNode = node as js.For;
        text = ['for(', forNode.init, '; ...) ...'];
        break;
      case StepKind.forCondition:
        final forNode = node as js.For;
        text = ['for(...;', forNode.condition, '; ...) ...'];
        break;
      case StepKind.forUpdate:
        final forNode = node as js.For;
        text = ['for(...; ...', forNode.update, ') ...'];
        break;
      case StepKind.whileCondition:
        final whileNode = node as js.While;
        text = ['while(', whileNode.condition, ') ...'];
        break;
      case StepKind.doCondition:
        final doNode = node as js.Do;
        text = ['do {... } (', doNode.condition, ')'];
        break;
      case StepKind.switchExpression:
        final switchNode = node as js.Switch;
        text = ['switch(', switchNode.key, ') ...'];
        break;
      case StepKind.noInfo:
        break;
    }
    createTraceStep(
      kind,
      node,
      offset: offset,
      sourceLocation: getSourceLocation(sourceInformation!, sourcePositionKind),
      text: text,
    );
  }

  void createTraceStep(
    StepKind kind,
    js.Node node, {
    required Offset offset,
    List? text,
    String? note,
    SourceLocation? sourceLocation,
  }) {
    int id = steppableMap.length;

    if (text == null) {
      text = [node];
    }

    TraceStep step = TraceStep(kind, id, node, offset, text, sourceLocation);
    graph.addStep(step);

    steppableMap[node] = step;
  }

  @override
  void pushBranch(BranchKind kind, [int? value]) {
    var branch;
    switch (kind) {
      case BranchKind.condition:
        branch = value == 1 ? 't' : 'f';
        break;
      case BranchKind.loop:
        branch = 'l';
        break;
      case BranchKind.catch_:
        branch = 'c';
        break;
      case BranchKind.finally_:
        branch = 'F';
        break;
      case BranchKind.case_:
        branch = '$value';
        break;
    }
    graph.pushBranch(branch);
  }

  @override
  void popBranch() {
    graph.popBranch();
  }
}
