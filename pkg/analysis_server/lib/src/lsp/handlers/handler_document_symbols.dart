// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Outline;
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' show Outline;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

class DocumentSymbolHandler extends LspMessageHandler<DocumentSymbolParams,
    TextDocumentDocumentSymbolResult> {
  DocumentSymbolHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_documentSymbol;

  @override
  LspJsonHandler<DocumentSymbolParams> get jsonHandler =>
      DocumentSymbolParams.jsonHandler;

  @override
  Future<ErrorOr<TextDocumentDocumentSymbolResult>> handle(
      DocumentSymbolParams params,
      MessageInfo message,
      CancellationToken token) async {
    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null || !isDartDocument(params.textDocument)) {
      return success(
        TextDocumentDocumentSymbolResult.t2([]),
      );
    }

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    return unit.mapResult(
        (unit) => _getSymbols(clientCapabilities, path.result, unit));
  }

  DocumentSymbol _asDocumentSymbol(
    Set<SymbolKind> supportedKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    final codeRange = toRange(lineInfo, outline.codeOffset, outline.codeLength);
    final nameLocation = outline.element.location;
    final nameRange = nameLocation != null
        ? toRange(lineInfo, nameLocation.offset, nameLocation.length)
        : null;
    return DocumentSymbol(
      name: toElementName(outline.element),
      detail: outline.element.parameters,
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      range: codeRange,
      selectionRange: nameRange ?? codeRange,
      children: outline.children
          ?.map((child) => _asDocumentSymbol(supportedKinds, lineInfo, child))
          .toList(),
    );
  }

  SymbolInformation? _asSymbolInformation(
    String? containerName,
    Set<SymbolKind> supportedKinds,
    Uri documentUri,
    LineInfo lineInfo,
    Outline outline,
  ) {
    final location = outline.element.location;
    if (location == null) {
      return null;
    }

    return SymbolInformation(
      name: toElementName(outline.element),
      kind: elementKindToSymbolKind(supportedKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      location: Location(
        uri: documentUri,
        range: toRange(lineInfo, location.offset, location.length),
      ),
      containerName: containerName,
    );
  }

  ErrorOr<TextDocumentDocumentSymbolResult> _getSymbols(
    LspClientCapabilities capabilities,
    String path,
    ResolvedUnitResult unit,
  ) {
    final computer = DartUnitOutlineComputer(unit);
    final outline = computer.compute();

    if (capabilities.hierarchicalSymbols) {
      // Return a tree of DocumentSymbol only if the client shows explicit support
      // for it.
      final children = outline.children;
      if (children == null) {
        return success(null);
      }
      return success(
        TextDocumentDocumentSymbolResult.t1(
          children
              .map((child) => _asDocumentSymbol(
                  capabilities.documentSymbolKinds, unit.lineInfo, child))
              .toList(),
        ),
      );
    } else {
      // Otherwise, we need to use the original flat SymbolInformation.
      final allSymbols = <SymbolInformation>[];
      final documentUri = Uri.file(path);

      // Adds a symbol and it's children recursively, supplying the parent
      // name as required by SymbolInformation.
      void addSymbol(Outline outline, {String? parentName}) {
        final symbol = _asSymbolInformation(
          parentName,
          capabilities.documentSymbolKinds,
          documentUri,
          unit.lineInfo,
          outline,
        );
        if (symbol != null) {
          allSymbols.add(symbol);
        }
        outline.children?.forEach(
          (c) => addSymbol(c, parentName: outline.element.name),
        );
      }

      outline.children?.forEach(addSymbol);

      return success(TextDocumentDocumentSymbolResult.t2(allSymbols));
    }
  }
}
