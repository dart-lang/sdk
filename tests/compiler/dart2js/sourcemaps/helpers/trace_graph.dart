// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sourcemap.trace_graph;

import 'dart:collection';

import 'package:compiler/src/io/source_information.dart';
import 'package:compiler/src/io/position_information.dart';
import 'package:compiler/src/js/js_debug.dart';

import 'sourcemap_html_helper.dart';

class TraceGraph {
  List<TraceStep> steps = <TraceStep>[];
  TraceStep entry;
  Queue stack = new Queue();
  Map<int, TraceStep> offsetMap = {};

  void addStep(TraceStep step) {
    steps.add(step);
    int offset = step.offset.value;
    TraceStep existingStep = offsetMap[offset];
    if (existingStep != null) {
      // TODO(johnniwinther): Fix problems with reuse of JS nodes from
      // templates.
      if (identical(existingStep.node, step.node)) {
        print('duplicate node: ${nodeToString(step.node)}');
      } else {
        print('duplicate offset: ${offset} : ${nodeToString(step.node)}');
      }
      print('  ${existingStep.id}:${existingStep.text}:${existingStep.offset}');
      print('  ${step.id}:${step.text}:${step.offset}');
    }
    offsetMap[offset] = step;
    step.stack = stack.toList();
  }

  void pushBranch(branch) {
    stack.addLast(branch);
  }

  void popBranch() {
    stack.removeLast();
  }
}

class TraceStep {
  final kind;
  final int id;
  final node;
  final Offset offset;
  final List text;
  final SourceLocation sourceLocation;

  TraceStep next;
  Map<dynamic, TraceStep> branchMap;

  List stack;

  TraceStep(this.kind, this.id, this.node, this.offset, this.text,
      [this.sourceLocation]);

  String toString() => '<span style="background:${toColorCss(id)}">$id</span>';
}
