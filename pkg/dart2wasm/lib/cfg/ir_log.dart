// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:kernel/ast.dart';

/// Accumulates the CFG IR dump for the entire compilation unit.
class CfgLog {
  static final Uri defaultUri = Uri();

  final List<String> lines = [];

  CfgLog();

  /// Appends a successfully compiled function's IR [graph] to the log and
  /// returns the [InstructionTextPosition]s shifted to their offsets in this
  /// log.
  Map<Instruction, InstructionTextPosition> append(
    Member member,
    FlowGraph graph,
  ) {
    lines.add('--- ${_formatMemberName(member)} ---');
    final startLine = lines.length;
    final positions = <Instruction, InstructionTextPosition>{};
    lines.addAll(IrToText(graph, positions: positions).lines);
    return positions..updateAll((_, pos) => pos.withLineOffset(startLine));
  }

  /// Appends a `<failed>` marker for a function that fell back to non-CFG
  /// codegen.
  void appendFailed(Member member) {
    lines.add('--- ${_formatMemberName(member)} ---');
    lines.add('<failed>');
    lines.add('');
  }

  String getText() => lines.join('\n');
}

String _formatMemberName(Member member) {
  final cls = member.enclosingClass;
  final prefix = cls != null ? '${cls.name}.' : '';
  final kindPrefix = member is Procedure
      ? (member.isGetter
            ? 'get '
            : member.isSetter
            ? 'set '
            : '')
      : '';
  return '$kindPrefix$prefix${member.name.text}';
}
