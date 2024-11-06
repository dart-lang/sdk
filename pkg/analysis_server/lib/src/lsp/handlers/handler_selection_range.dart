// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/computer/computer_selection_ranges.dart'
    hide SelectionRange;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

typedef StaticOptions =
    Either3<bool, SelectionRangeOptions, SelectionRangeRegistrationOptions>;

class SelectionRangeHandler
    extends LspMessageHandler<SelectionRangeParams, List<SelectionRange>?> {
  SelectionRangeHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_selectionRange;

  @override
  LspJsonHandler<SelectionRangeParams> get jsonHandler =>
      SelectionRangeParams.jsonHandler;

  @override
  Future<ErrorOr<List<SelectionRange>?>> handle(
    SelectionRangeParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      var unit = await requireUnresolvedUnit(path);
      return unit.mapResultSync((unit) {
        var positions = params.positions;
        var offsets =
            positions.map((pos) => toOffset(unit.lineInfo, pos)).errorOrResults;
        var allRanges = offsets.mapResultSync(
          (offsets) => success(_getSelectionRangesForOffsets(offsets, unit)),
        );

        return allRanges;
      });
    });
  }

  SelectionRange _getSelectionRangesForOffset(
    CompilationUnit unit,
    int offset,
  ) {
    var lineInfo = unit.lineInfo;
    var computer = DartSelectionRangeComputer(unit, offset);
    var ranges = computer.compute();
    // Loop through the items starting at the end (the outermost range), using
    // each item as the parent for the next item.
    SelectionRange? last;
    for (var i = ranges.length - 1; i >= 0; i--) {
      var range = ranges[i];
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
    List<int> offsets,
    ParsedUnitResult result,
  ) {
    return offsets
        .map((offset) => _getSelectionRangesForOffset(result.unit, offset))
        .toList();
  }
}

class SelectionRangeRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  SelectionRangeRegistrations(super.info);

  @override
  ToJsonable? get options =>
      SelectionRangeRegistrationOptions(documentSelector: dartFiles);

  @override
  Method get registrationMethod => Method.textDocument_selectionRange;

  @override
  StaticOptions get staticOptions => Either3.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.selectionRange;
}
