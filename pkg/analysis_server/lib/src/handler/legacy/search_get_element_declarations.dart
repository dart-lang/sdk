// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart' as protocol;
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/src/dart/analysis/search.dart' as search;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;

/// The handler for the `search.getElementDeclarations` request.
class SearchGetElementDeclarationsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  SearchGetElementDeclarationsHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    var params =
        protocol.SearchGetElementDeclarationsParams.fromRequest(request);

    protocol.ElementKind getElementKind(search.DeclarationKind kind) {
      return switch (kind) {
        search.DeclarationKind.CLASS => protocol.ElementKind.CLASS,
        search.DeclarationKind.CLASS_TYPE_ALIAS =>
          protocol.ElementKind.CLASS_TYPE_ALIAS,
        search.DeclarationKind.CONSTRUCTOR => protocol.ElementKind.CONSTRUCTOR,
        search.DeclarationKind.ENUM => protocol.ElementKind.ENUM,
        search.DeclarationKind.ENUM_CONSTANT =>
          protocol.ElementKind.ENUM_CONSTANT,
        search.DeclarationKind.EXTENSION => protocol.ElementKind.EXTENSION,
        search.DeclarationKind.EXTENSION_TYPE =>
          protocol.ElementKind.EXTENSION_TYPE,
        search.DeclarationKind.FIELD => protocol.ElementKind.FIELD,
        search.DeclarationKind.FUNCTION => protocol.ElementKind.FUNCTION,
        search.DeclarationKind.FUNCTION_TYPE_ALIAS =>
          protocol.ElementKind.FUNCTION_TYPE_ALIAS,
        search.DeclarationKind.GETTER => protocol.ElementKind.GETTER,
        search.DeclarationKind.METHOD => protocol.ElementKind.METHOD,
        search.DeclarationKind.MIXIN => protocol.ElementKind.MIXIN,
        search.DeclarationKind.SETTER => protocol.ElementKind.SETTER,
        search.DeclarationKind.TYPE_ALIAS => protocol.ElementKind.TYPE_ALIAS,
        search.DeclarationKind.VARIABLE =>
          protocol.ElementKind.TOP_LEVEL_VARIABLE,
      };
    }

    if (!server.options.featureSet.completion) {
      server.sendResponse(Response.unsupportedFeature(
          request.id, 'Completion is not enabled.'));
      return;
    }

    var workspaceSymbols = search.WorkspaceSymbols();
    var analysisDrivers = server.driverMap.values.toList();
    await search.FindDeclarations(
      analysisDrivers,
      workspaceSymbols,
      params.pattern ?? '',
      params.maxResults,
      onlyForFile: params.file,
      ownedFiles: server.ownedFiles,
      performance: performance,
    ).compute();

    var declarations = workspaceSymbols.declarations;
    var elementDeclarations = declarations.map((declaration) {
      return protocol.ElementDeclaration(
          declaration.name,
          getElementKind(declaration.kind),
          declaration.fileIndex,
          declaration.offset,
          declaration.line,
          declaration.column,
          declaration.codeOffset,
          declaration.codeLength,
          className: declaration.className,
          mixinName: declaration.mixinName,
          parameters: declaration.parameters);
    }).toList();

    server.sendResponse(protocol.SearchGetElementDeclarationsResult(
            elementDeclarations, workspaceSymbols.files)
        .toResponse(request.id));
  }
}
