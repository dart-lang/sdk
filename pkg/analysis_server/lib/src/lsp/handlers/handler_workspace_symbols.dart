// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analyzer/src/dart/analysis/search.dart' as search;

typedef StaticOptions = Either2<bool, WorkspaceSymbolOptions>;

class WorkspaceSymbolHandler extends SharedMessageHandler<WorkspaceSymbolParams,
    List<SymbolInformation>> {
  WorkspaceSymbolHandler(super.server);
  @override
  Method get handlesMessage => Method.workspace_symbol;

  @override
  LspJsonHandler<WorkspaceSymbolParams> get jsonHandler =>
      WorkspaceSymbolParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<SymbolInformation>>> handle(WorkspaceSymbolParams params,
      MessageInfo message, CancellationToken token) async {
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    // Respond to empty queries with an empty list. The spec says this should
    // be non-empty, however VS Code's client sends empty requests (but then
    // appears to not render the results we supply anyway).
    // TODO(dantup): The spec has been updated to allow empty queries. Clients
    // may expect a full list in this case, though we may choose not to send
    // it on performance grounds until they type a filter.
    var query = params.query;
    if (query == '') {
      return success([]);
    }

    var supportedSymbolKinds = clientCapabilities.workspaceSymbolKinds;
    var searchOnlyAnalyzed = !server
        .lspClientConfiguration.global.includeDependenciesInWorkspaceSymbols;

    // Cap the number of results we'll return because short queries may match
    // huge numbers on large projects.
    var remainingResults = 500;

    var workspaceSymbols = search.WorkspaceSymbols();
    await message.performance.runAsync(
      'findDeclarations',
      (performance) async {
        var analysisDrivers = server.driverMap.values.toList();
        await search.FindDeclarations(
          analysisDrivers,
          workspaceSymbols,
          query,
          remainingResults,
          onlyAnalyzed: searchOnlyAnalyzed,
          ownedFiles: server.ownedFiles,
          performance: performance,
        ).compute(token);
      },
    );

    if (workspaceSymbols.cancelled) {
      return cancelled();
    }

    // Map the results to SymbolInformations and flatten the list of lists.
    var symbols = message.performance.run('convert', (performance) {
      var declarations = workspaceSymbols.declarations;
      performance.getDataInt('declarations').value = declarations.length;
      return declarations.map((declaration) {
        return _asSymbolInformation(
          declaration,
          supportedSymbolKinds,
          workspaceSymbols.files,
        );
      }).toList();
    });

    return success(symbols);
  }

  SymbolInformation _asSymbolInformation(
    search.Declaration declaration,
    Set<SymbolKind> supportedKinds,
    List<String> filePaths,
  ) {
    var filePath = filePaths[declaration.fileIndex];

    var kind = declarationKindToSymbolKind(
      supportedKinds,
      declaration.kind,
    );
    var range = toRange(
      declaration.lineInfo,
      declaration.codeOffset,
      declaration.codeLength,
    );
    var location = Location(
      uri: uriConverter.toClientUri(filePath),
      range: range,
    );

    var parameters = declaration.parameters;
    var hasParameters = parameters != null && parameters.isNotEmpty;
    var nameSuffix = hasParameters ? (parameters == '()' ? '()' : '(…)') : '';

    return SymbolInformation(
      name: '${declaration.name}$nameSuffix',
      kind: kind,
      location: location,
      containerName: declaration.className ?? declaration.mixinName,
    );
  }
}

class WorkspaceSymbolRegistrations extends FeatureRegistration
    with StaticRegistration<StaticOptions> {
  WorkspaceSymbolRegistrations(super.info);

  @override
  List<LspDynamicRegistration> get dynamicRegistrations => [];

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => false;
}
