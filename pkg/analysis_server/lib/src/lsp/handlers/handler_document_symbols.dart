// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' show Outline;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

// If the client does not provide capabilities.documentSymbol.symbolKind.valueSet
// then we must never send a kind that's not in this list.
final defaultSupportedSymbolKinds = HashSet<SymbolKind>.of([
  SymbolKind.File,
  SymbolKind.Module,
  SymbolKind.Namespace,
  SymbolKind.Package,
  SymbolKind.Class,
  SymbolKind.Method,
  SymbolKind.Property,
  SymbolKind.Field,
  SymbolKind.Constructor,
  SymbolKind.Enum,
  SymbolKind.Interface,
  SymbolKind.Function,
  SymbolKind.Variable,
  SymbolKind.Constant,
  SymbolKind.Str,
  SymbolKind.Number,
  SymbolKind.Boolean,
  SymbolKind.Array,
]);

class DocumentSymbolHandler extends MessageHandler<DocumentSymbolParams,
    Either2<List<DocumentSymbol>, List<SymbolInformation>>> {
  DocumentSymbolHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_documentSymbol;

  @override
  LspJsonHandler<DocumentSymbolParams> get jsonHandler =>
      DocumentSymbolParams.jsonHandler;

  @override
  Future<ErrorOr<Either2<List<DocumentSymbol>, List<SymbolInformation>>>>
      handle(DocumentSymbolParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t2([]),
      );
    }

    final symbolCapabilities =
        server?.clientCapabilities?.textDocument?.documentSymbol;

    final clientSupportedSymbolKinds =
        symbolCapabilities?.symbolKind?.valueSet != null
            ? HashSet<SymbolKind>.of(symbolCapabilities.symbolKind.valueSet)
            : defaultSupportedSymbolKinds;

    final clientSupportsDocumentSymbol =
        symbolCapabilities?.hierarchicalDocumentSymbolSupport ?? false;

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    return unit.mapResult((unit) => _getSymbols(clientSupportedSymbolKinds,
        clientSupportsDocumentSymbol, path.result, unit));
  }

  DocumentSymbol _asDocumentSymbol(
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    return DocumentSymbol(
      name: toElementName(outline.element),
      detail: outline.element.parameters,
      kind: elementKindToSymbolKind(
          clientSupportedSymbolKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      range: toRange(lineInfo, outline.codeOffset, outline.codeLength),
      selectionRange: toRange(lineInfo, outline.element.location.offset,
          outline.element.location.length),
      children: outline.children
          ?.map((child) =>
              _asDocumentSymbol(clientSupportedSymbolKinds, lineInfo, child))
          ?.toList(),
    );
  }

  SymbolInformation _asSymbolInformation(
    String containerName,
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    String documentUri,
    LineInfo lineInfo,
    Outline outline,
  ) {
    return SymbolInformation(
      name: toElementName(outline.element),
      kind: elementKindToSymbolKind(
          clientSupportedSymbolKinds, outline.element.kind),
      deprecated: outline.element.isDeprecated,
      location: Location(
        uri: documentUri,
        range: toRange(lineInfo, outline.element.location.offset,
            outline.element.location.length),
      ),
      containerName: containerName,
    );
  }

  ErrorOr<Either2<List<DocumentSymbol>, List<SymbolInformation>>> _getSymbols(
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    bool clientSupportsDocumentSymbol,
    String path,
    ResolvedUnitResult unit,
  ) {
    final computer = DartUnitOutlineComputer(unit);
    final outline = computer.compute();

    if (clientSupportsDocumentSymbol) {
      // Return a tree of DocumentSymbol only if the client shows explicit support
      // for it.
      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t1(
          outline?.children
              ?.map((child) => _asDocumentSymbol(
                  clientSupportedSymbolKinds, unit.lineInfo, child))
              ?.toList(),
        ),
      );
    } else {
      // Otherwise, we need to use the original flat SymbolInformation.
      final allSymbols = <SymbolInformation>[];
      final documentUri = Uri.file(path).toString();

      // Adds a symbol and it's children recursively, supplying the parent
      // name as required by SymbolInformation.
      void addSymbol(Outline outline, {String parentName}) {
        allSymbols.add(_asSymbolInformation(
          parentName,
          clientSupportedSymbolKinds,
          documentUri,
          unit.lineInfo,
          outline,
        ));
        outline.children?.forEach(
          (c) => addSymbol(c, parentName: outline.element.name),
        );
      }

      outline?.children?.forEach(addSymbol);

      return success(
        Either2<List<DocumentSymbol>, List<SymbolInformation>>.t2(allSymbols),
      );
    }
  }
}
