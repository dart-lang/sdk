// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

class HoverHandler extends MessageHandler<TextDocumentPositionParams, Hover> {
  HoverHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_hover;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<Hover>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) => _getHover(unit.result, offset));
  }

  Hover toHover(LineInfo lineInfo, HoverInformation hover) {
    if (hover == null) {
      return null;
    }

    // Import prefix tooltips are not useful currently.
    // https://github.com/dart-lang/sdk/issues/32735
    if (hover.elementKind == 'import prefix') {
      return null;
    }

    final content = StringBuffer();
    const divider = '---';

    // Description.
    if (hover.elementDescription != null) {
      content.writeln('```dart');
      if (hover.isDeprecated) {
        content.write('(deprecated) ');
      }
      content..writeln(hover.elementDescription)..writeln('```');
    }

    // Source library.
    if (hover.containingLibraryName != null &&
        hover.containingLibraryName.isNotEmpty) {
      content..writeln('*${hover.containingLibraryName}*')..writeln();
    }

    // Doc comments.
    if (hover.dartdoc != null) {
      if (content.length != 0) {
        content.writeln(divider);
      }
      content.writeln(cleanDartdoc(hover.dartdoc));
    }

    final formats =
        server?.clientCapabilities?.textDocument?.hover?.contentFormat;
    return Hover(
      contents:
          asStringOrMarkupContent(formats, content.toString().trimRight()),
      range: toRange(lineInfo, hover.offset, hover.length),
    );
  }

  ErrorOr<Hover> _getHover(ResolvedUnitResult unit, int offset) {
    final hover = DartUnitHoverComputer(
            server.getDartdocDirectiveInfoFor(unit), unit.unit, offset)
        .compute();
    return success(toHover(unit.lineInfo, hover));
  }
}
