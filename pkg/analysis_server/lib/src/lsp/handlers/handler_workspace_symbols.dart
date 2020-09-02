// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handler_document_symbols.dart'
    show defaultSupportedSymbolKinds;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/search/workspace_symbols.dart' as search;

class WorkspaceSymbolHandler
    extends MessageHandler<WorkspaceSymbolParams, List<SymbolInformation>> {
  WorkspaceSymbolHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.workspace_symbol;

  @override
  LspJsonHandler<WorkspaceSymbolParams> get jsonHandler =>
      WorkspaceSymbolParams.jsonHandler;

  @override
  Future<ErrorOr<List<SymbolInformation>>> handle(
      WorkspaceSymbolParams params, CancellationToken token) async {
    // Respond to empty queries with an empty list. The spec says this should
    // be non-empty, however VS Code's client sends empty requests (but then
    // appears to not render the results we supply anyway).
    final query = params?.query ?? '';
    if (query == '') {
      return success([]);
    }

    final symbolCapabilities = server?.clientCapabilities?.workspace?.symbol;

    final clientSupportedSymbolKinds =
        symbolCapabilities?.symbolKind?.valueSet != null
            ? HashSet<SymbolKind>.of(symbolCapabilities.symbolKind.valueSet)
            : defaultSupportedSymbolKinds;

    // Convert the string input into a case-insensitive regex that has wildcards
    // between every character and at start/end to allow for fuzzy matching.
    final fuzzyQuery = query.split('').map(RegExp.escape).join('.*');
    final partialFuzzyQuery = '.*$fuzzyQuery.*';
    final regex = RegExp(partialFuzzyQuery, caseSensitive: false);

    // Cap the number of results we'll return because short queries may match
    // huge numbers on large projects.
    var remainingResults = 500;

    final filePathsHashSet = <String>{};
    final tracker = server.declarationsTracker;
    final declarations = search.WorkspaceSymbols(tracker).declarations(
      regex,
      remainingResults,
      filePathsHashSet,
    );

    // Convert the file paths to something we can quickly index into since
    // we'll be looking things up by index a lot.
    final filePaths = filePathsHashSet.toList();

    // Map the results to SymbolInformations and flatten the list of lists.
    final symbols = declarations
        .map((declaration) => _asSymbolInformation(
              declaration,
              clientSupportedSymbolKinds,
              filePaths,
            ))
        .toList();

    return success(symbols);
  }

  SymbolInformation _asSymbolInformation(
    search.Declaration declaration,
    HashSet<SymbolKind> clientSupportedSymbolKinds,
    List<String> filePaths,
  ) {
    final filePath = filePaths[declaration.fileIndex];

    final kind = declarationKindToSymbolKind(
      clientSupportedSymbolKinds,
      declaration.kind,
    );
    final range = toRange(
      declaration.lineInfo,
      declaration.codeOffset,
      declaration.codeLength,
    );
    final location = Location(
      uri: Uri.file(filePath).toString(),
      range: range,
    );

    final hasParameters =
        declaration.parameters != null && declaration.parameters.isNotEmpty;
    final nameSuffix =
        hasParameters ? (declaration.parameters == '()' ? '()' : '(…)') : '';

    return SymbolInformation(
        name: '${declaration.name}$nameSuffix',
        kind: kind,
        deprecated: null, // We don't have easy access to isDeprecated here.
        location: location,
        containerName: declaration.className ?? declaration.mixinName);
  }
}
