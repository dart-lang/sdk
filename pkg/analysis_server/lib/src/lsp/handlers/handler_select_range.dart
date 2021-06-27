// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_selection_ranges.dart'
    hide SelectionRange;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

class SelectionRangeHandler
    extends MessageHandler<SelectionRangeParams, List<SelectionRange>?> {
  SelectionRangeHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_selectionRange;

  @override
  LspJsonHandler<SelectionRangeParams> get jsonHandler =>
      SelectionRangeParams.jsonHandler;

  @override
  Future<ErrorOr<List<SelectionRange>?>> handle(
      SelectionRangeParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      final lineInfo = server.getLineInfo(path);
      // If there is no lineInfo, the request cannot be translated from LSP
      // line/col to server offset/length.
      if (lineInfo == null) {
        return success(null);
      }

      final unit = requireUnresolvedUnit(path);
      final positions = params.positions;
      final offsets = await unit.mapResult((unit) =>
          ErrorOr.all(positions.map((pos) => toOffset(unit.lineInfo, pos))));
      final allRanges = await offsets.mapResult((offsets) =>
          success(_getSelectionRangesForOffsets(offsets, unit, lineInfo)));

      return allRanges;
    });
  }

  SelectionRange _getSelectionRangesForOffset(
      CompilationUnit unit, LineInfo lineInfo, int offset) {
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

    // It's not clear how to respond if a subset of the results
    // do not have results, so for now if the list is empty just return a single
    // range that is exactly the same as the position.
    // TODO(dantup): Update this based on the response to
    // https://github.com/microsoft/language-server-protocol/issues/1270

    return last ?? SelectionRange(range: toRange(lineInfo, offset, 0));
  }

  List<SelectionRange> _getSelectionRangesForOffsets(
      List<int> offsets, ErrorOr<ParsedUnitResult> unit, LineInfo lineInfo) {
    return offsets
        .map((offset) =>
            _getSelectionRangesForOffset(unit.result.unit, lineInfo, offset))
        .toList();
  }
}
