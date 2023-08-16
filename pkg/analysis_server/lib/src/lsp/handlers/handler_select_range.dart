// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_selection_ranges.dart'
    hide SelectionRange;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

class SelectionRangeHandler
    extends LspMessageHandler<SelectionRangeParams, List<SelectionRange>?> {
  SelectionRangeHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_selectionRange;

  @override
  LspJsonHandler<SelectionRangeParams> get jsonHandler =>
      SelectionRangeParams.jsonHandler;

  @override
  Future<ErrorOr<List<SelectionRange>?>> handle(SelectionRangeParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      final unit = await requireUnresolvedUnit(path);
      final positions = params.positions;
      final offsets = await unit.mapResult((unit) =>
          ErrorOr.all(positions.map((pos) => toOffset(unit.lineInfo, pos))));
      final allRanges = await offsets.mapResult(
          (offsets) => success(_getSelectionRangesForOffsets(offsets, unit)));

      return allRanges;
    });
  }

  SelectionRange _getSelectionRangesForOffset(
      CompilationUnit unit, int offset) {
    final lineInfo = unit.lineInfo;
    final computer = DartSelectionRangeComputer(unit, offset);
    final ranges = computer.compute();
    // Loop through the items starting at the end (the outermost range), using
    // each item as the parent for the next item.
    SelectionRange? last;
    for (var i = ranges.length - 1; i >= 0; i--) {
      final range = ranges[i];
      last = SelectionRange(
        range: toRange(lineInfo, range.offset, range.length),
        parent: last,
      );
    }

    // When there is no range for a given position, return an empty range at the
    // requested position. From the LSP spec:
    //
    // "To allow for results where some positions have selection ranges and
    //  others do not, result[i].range is allowed to be the empty range at
    //  positions[i]."
    return last ?? SelectionRange(range: toRange(lineInfo, offset, 0));
  }

  List<SelectionRange> _getSelectionRangesForOffsets(
      List<int> offsets, ErrorOr<ParsedUnitResult> unit) {
    return offsets
        .map((offset) => _getSelectionRangesForOffset(unit.result.unit, offset))
        .toList();
  }
}
