// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/source/line_info.dart';

class FoldingHandler
    extends LspMessageHandler<FoldingRangeParams, List<FoldingRange>> {
  FoldingHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_foldingRange;

  @override
  LspJsonHandler<FoldingRangeParams> get jsonHandler =>
      FoldingRangeParams.jsonHandler;

  @override
  Future<ErrorOr<List<FoldingRange>>> handle(FoldingRangeParams params,
      MessageInfo message, CancellationToken token) async {
    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final lineFoldingOnly = clientCapabilities.lineFoldingOnly;
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final partialResults = <List<FoldingRegion>>[];
      LineInfo? lineInfo;

      final unit = await server.getParsedUnit(path);
      if (unit != null) {
        lineInfo = unit.lineInfo;

        final regions = DartUnitFoldingComputer(lineInfo, unit.unit).compute();
        partialResults.insert(0, regions);
      }

      // Still try to obtain line info for invalid or non-Dart files, as plugins
      // could contribute to those.
      lineInfo ??= server.getLineInfo(path);

      if (lineInfo == null) {
        // Line information would be required to translate folding results to
        // LSP.
        return success(const []);
      }

      final notificationManager = server.notificationManager;
      final pluginResults = notificationManager.folding.getResults(path);
      partialResults.addAll(pluginResults);

      final regions =
          notificationManager.merger.mergeFoldingRegions(partialResults);

      // Ensure sorted by offset for when looking for overlapping ranges in
      // line mode below.
      regions.sort((r1, r2) => r1.offset.compareTo(r2.offset));

      final foldingRanges = regions
          .map((region) =>
              _toFoldingRange(lineInfo!, region, lineOnly: lineFoldingOnly))
          .toList();

      // When in line-only mode, ranges that end on the same line that another
      // ranges starts should be truncated to be on the line before (and if this
      // leave them spanning only a single line, should be removed).
      if (lineFoldingOnly) {
        _compensateForLineFolding(foldingRanges);
      }

      return success(foldingRanges);
    });
  }

  /// Adjust [foldingRanges] taking into count additional rules for line
  /// folding.
  ///
  /// When character folding is supported, a range may start on the same line
  /// that another ends (as long as they don't overlap).
  ///
  /// When only line folding is supported, ranges must not end on the same line
  /// that another starts. In this case, we shrink the previous range (and if
  /// this makes it a single line, remove it).
  void _compensateForLineFolding(List<FoldingRange> foldingRanges) {
    // Loop over items except last (`-1`). We can skip the last item because
    // it has no next item.
    for (var i = 0; i < foldingRanges.length - 1; i++) {
      final range = foldingRanges[i];
      final next = foldingRanges[i + 1];
      // If this item runs into the next but does not completely enclose it...
      if (range.endLine >= next.startLine && range.endLine <= next.endLine) {
        // Truncate it to end on the line before.
        final newEndLine = next.startLine - 1;

        // If it no longer needs to be a folding range at all, remove it.
        if (newEndLine <= range.startLine) {
          foldingRanges.removeAt(i);
          i--;
          continue;
        }

        foldingRanges[i] = FoldingRange(
          startLine: range.startLine,
          endLine: newEndLine,
          kind: range.kind,
        );
      }
    }
  }

  FoldingRange _toFoldingRange(LineInfo lineInfo, FoldingRegion region,
      {required bool lineOnly}) {
    final range = toRange(lineInfo, region.offset, region.length);
    return FoldingRange(
      startLine: range.start.line,
      startCharacter: lineOnly ? null : range.start.character,
      endLine: range.end.line,
      endCharacter: lineOnly ? null : range.end.character,
      kind: toFoldingRangeKind(region.kind),
    );
  }
}
