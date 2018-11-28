// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/computer/computer_outline.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';

// If the client does not provide capabilities.completion.completionItemKind.valueSet
// then we must never send a kind that's not in this list.
final defaultSupportedSymbolKinds = new HashSet<SymbolKind>.of([
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

// TODO(dantup): hierarchicalDocumentSymbolSupport (if false, can't use
// DocumentSymbol)

class DocumentSymbolHandler
    extends MessageHandler<DocumentSymbolParams, List<DocumentSymbol>> {
  DocumentSymbolHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_documentSymbol;

  @override
  DocumentSymbolParams convertParams(Map<String, dynamic> json) =>
      DocumentSymbolParams.fromJson(json);

  Future<ErrorOr<List<DocumentSymbol>>> handle(
      DocumentSymbolParams params) async {
    final completionCapabilities =
        server?.clientCapabilities?.textDocument?.documentSymbol;

    final clientSupportedSymbolKinds = completionCapabilities
                ?.symbolKind?.valueSet !=
            null
        ? new HashSet<SymbolKind>.of(completionCapabilities.symbolKind.valueSet)
        : defaultSupportedSymbolKinds;

    final path = pathOf(params.textDocument);
    final unit = await path.mapResult(requireUnit);
    return unit.mapResult(
        (unit) => _getSymbols(clientSupportedSymbolKinds, path.result, unit));
  }

  ErrorOr<List<DocumentSymbol>> _getSymbols(
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    String path,
    ResolvedUnitResult unit,
  ) {
    final computer =
        new DartUnitOutlineComputer(path, unit.lineInfo, unit.unit);
    final outline = computer.compute();

    return success(
      outline?.children
          ?.map((child) =>
              _convert(clientSupportedSymbolKinds, unit.lineInfo, child))
          ?.toList(),
    );
  }

  DocumentSymbol _convert(
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    LineInfo lineInfo,
    Outline outline,
  ) {
    return new DocumentSymbol(
      outline.element.name,
      outline.element.parameters,
      elementKindToSymbolKind(clientSupportedSymbolKinds, outline.element.kind),
      outline.element.isDeprecated,
      toRange(lineInfo, outline.codeOffset, outline.codeLength),
      toRange(lineInfo, outline.element.location.offset,
          outline.element.location.length),
      outline.children
          ?.map(
              (child) => _convert(clientSupportedSymbolKinds, lineInfo, child))
          ?.toList(),
    );
  }
}
