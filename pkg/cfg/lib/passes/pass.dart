// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/flow_graph_checker.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';

/// Base class for a pass in the compiler pipeline.
abstract base class Pass {
  final String name;
  late final ErrorContext errorContext;
  late final FlowGraph graph;

  Pass(this.name);

  void initialize(ErrorContext errorContext, FlowGraph graph) {
    this.errorContext = errorContext;
    this.graph = graph;
  }

  void run();

  // Set instruction currently being processed by the pass.
  // Used for crash reporting.
  void set currentInstruction(Instruction? instr) {
    errorContext.instruction = instr;
  }

  // Set block currently being processed by the pass.
  // Used for crash reporting.
  void set currentBlock(Block? block) {
    errorContext.block = block;
  }
}

/// Sequence of passes.
///
/// Provides detailed crash reporting and
/// performs flow graph checking after each pass.
class Pipeline {
  final ErrorContext errorContext = ErrorContext();
  final List<Pass> passes = [];

  Pipeline(List<Pass> passes) {
    this.passes.add(
      FlowGraphChecker('FlowGraphChecker after FlowGraph construction'),
    );
    for (final pass in passes) {
      this.passes.add(pass);
      this.passes.add(FlowGraphChecker('FlowGraphChecker after ${pass.name}'));
    }
  }

  void run(FlowGraph graph) {
    errorContext.runWithContext(() {
      for (final pass in passes) {
        errorContext.graph = graph;
        errorContext.pass = pass.name;

        pass.initialize(errorContext, graph);
        pass.run();

        errorContext.clear();
      }
    });
  }
}

/// Provides detailed context when handling a compiler crash.
class ErrorContext {
  String? pass;
  FlowGraph? graph;
  Block? block;
  Instruction? instruction;
  String? Function(Instruction)? annotator;

  /// Run given [action] and print this error context
  /// if [action] throws any exception.
  T runWithContext<T>(T Function() action) {
    try {
      return action();
    } catch (_) {
      print(
        'Compiler crashed while compiling ${graph?.function ?? 'unknown function'}:',
      );
      print('-------------------------------');
      print(this);
      print('-------------------------------');
      rethrow;
    }
  }

  void clear() {
    pass = null;
    graph = null;
    block = null;
    instruction = null;
    annotator = null;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    final graph = this.graph;
    if (pass != null) {
      buf.writeln('Pass: $pass');
    }
    if (graph != null) {
      buf.writeln('IR:');
      try {
        buf.writeln(IrToText(graph, annotator: annotator));
      } catch (e, st) {
        buf.writeln('<unknown>');
        buf.writeln(e);
        buf.writeln(st);
      }
    }
    final block = this.block;
    if (block != null) {
      try {
        buf.writeln(
          'Block: ${IrToText.instruction(block, annotator: annotator)}',
        );
      } catch (e, st) {
        buf.writeln('<unknown>');
        buf.writeln(e);
        buf.writeln(st);
      }
    }
    final instruction = this.instruction;
    if (instruction != null) {
      try {
        buf.writeln(
          'Instruction: ${IrToText.instruction(instruction, annotator: annotator)}',
        );
      } catch (e, st) {
        buf.writeln('<unknown>');
        buf.writeln(e);
        buf.writeln(st);
      }
    }
    return buf.toString();
  }
}
