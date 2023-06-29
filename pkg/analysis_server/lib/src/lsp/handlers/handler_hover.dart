// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

class HoverHandler
    extends LspMessageHandler<TextDocumentPositionParams, Hover?> {
  HoverHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_hover;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<Hover?>> handle(TextDocumentPositionParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return offset.mapResult((offset) => _getHover(unit.result, offset));
  }

  Hover? toHover(LineInfo lineInfo, HoverInformation? hover) {
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

    // Description + Types.
    final elementDescription = hover.elementDescription;
    final staticType = hover.staticType;
    final isDeprecated = hover.isDeprecated ?? false;
    if (elementDescription != null) {
      content.writeln('```dart');
      if (isDeprecated) {
        content.write('(deprecated) ');
      }
      content
        ..writeln(elementDescription)
        ..writeln('```');
    }
    if (staticType != null) {
      content
        ..writeln('Type: `$staticType`')
        ..writeln();
    }

    // Source library.
    final containingLibraryName = hover.containingLibraryName;
    if (containingLibraryName != null && containingLibraryName.isNotEmpty) {
      content
        ..writeln('*$containingLibraryName*')
        ..writeln();
    }

    // Doc comments.
    if (hover.dartdoc != null) {
      if (content.length != 0) {
        content.writeln(divider);
      }
      content.writeln(cleanDartdoc(hover.dartdoc));
    }

    final formats = server.lspClientCapabilities?.hoverContentFormats;
    return Hover(
      contents:
          asMarkupContentOrString(formats, content.toString().trimRight()),
      range: toRange(lineInfo, hover.offset, hover.length),
    );
  }

  ErrorOr<Hover?> _getHover(ResolvedUnitResult unit, int offset) {
    final compilationUnit = unit.unit;
    final computer = DartUnitHoverComputer(
      server.getDartdocDirectiveInfoFor(unit),
      compilationUnit,
      offset,
      documentationPreference:
          server.lspClientConfiguration.global.preferredDocumentation,
    );
    final hover = computer.compute();
    return success(toHover(unit.lineInfo, hover));
  }
}
