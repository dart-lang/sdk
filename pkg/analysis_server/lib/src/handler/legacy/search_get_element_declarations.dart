// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart' as protocol;
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
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params =
        protocol.SearchGetElementDeclarationsParams.fromRequest(request);

    RegExp? regExp;
    var pattern = params.pattern;
    if (pattern != null) {
      try {
        regExp = RegExp(pattern);
      } on FormatException catch (exception) {
        server.sendResponse(protocol.Response.invalidParameter(
            request, 'pattern', exception.message));
        return;
      }
    }

    protocol.ElementKind getElementKind(search.DeclarationKind kind) {
      switch (kind) {
        case search.DeclarationKind.CLASS:
          return protocol.ElementKind.CLASS;
        case search.DeclarationKind.CLASS_TYPE_ALIAS:
          return protocol.ElementKind.CLASS_TYPE_ALIAS;
        case search.DeclarationKind.CONSTRUCTOR:
          return protocol.ElementKind.CONSTRUCTOR;
        case search.DeclarationKind.ENUM:
          return protocol.ElementKind.ENUM;
        case search.DeclarationKind.ENUM_CONSTANT:
          return protocol.ElementKind.ENUM_CONSTANT;
        case search.DeclarationKind.FIELD:
          return protocol.ElementKind.FIELD;
        case search.DeclarationKind.FUNCTION:
          return protocol.ElementKind.FUNCTION;
        case search.DeclarationKind.FUNCTION_TYPE_ALIAS:
          return protocol.ElementKind.FUNCTION_TYPE_ALIAS;
        case search.DeclarationKind.GETTER:
          return protocol.ElementKind.GETTER;
        case search.DeclarationKind.METHOD:
          return protocol.ElementKind.METHOD;
        case search.DeclarationKind.MIXIN:
          return protocol.ElementKind.MIXIN;
        case search.DeclarationKind.SETTER:
          return protocol.ElementKind.SETTER;
        case search.DeclarationKind.TYPE_ALIAS:
          return protocol.ElementKind.TYPE_ALIAS;
        case search.DeclarationKind.VARIABLE:
          return protocol.ElementKind.TOP_LEVEL_VARIABLE;
        default:
          return protocol.ElementKind.CLASS;
      }
    }

    if (!server.options.featureSet.completion) {
      server.sendResponse(Response.unsupportedFeature(
          request.id, 'Completion is not enabled.'));
      return;
    }

    var workspaceSymbols = search.WorkspaceSymbols();
    var analysisDrivers = server.driverMap.values.toList();
    for (var analysisDriver in analysisDrivers) {
      await analysisDriver.search.declarations(
          workspaceSymbols, regExp, params.maxResults,
          onlyForFile: params.file);
    }

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
