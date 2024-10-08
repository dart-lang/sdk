// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide Declaration, Element;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';

/// A base class for providers that can contribute CodeLenses.
///
/// The LSP CodeLens handler will call all registered CodeLens providers and
/// merge the results before responding to the client.
abstract class AbstractCodeLensProvider
    with HandlerHelperMixin, Handler<List<CodeLens>> {
  @override
  final AnalysisServer server;

  AbstractCodeLensProvider(this.server);

  /// Whether the client supports the `dart.goToLocation` command, as produced
  /// by [getNavigationCommand].
  bool clientSupportsGoToLocationCommand(LspClientCapabilities capabilities) =>
      capabilities.supportedCommands.contains(ClientCommands.goToLocation);

  /// Attempt to compute a [Location] to the declaration of [element].
  ///
  /// If for any reason the location cannot be computed, returns `null`.
  Location? getLocation(Element element, Map<String, LineInfo?> lineInfoCache) {
    var source = element.source;
    if (source == null) {
      return null;
    }

    // Map the source onto a URI and only return this item if the client
    // can handle the URI.
    var uri = server.uriConverter.toClientUri(source.fullName);
    if (!server.uriConverter.supportedSchemes.contains(uri.scheme)) {
      return null;
    }

    var lineInfo = lineInfoCache.putIfAbsent(
        source.fullName, () => server.getLineInfo(source.fullName));
    if (lineInfo == null) {
      return null;
    }

    return Location(
      uri: uri,
      range: toRange(lineInfo, element.nameOffset, element.nameLength),
    );
  }

  /// Builds a [Command] that with the text [title] that navigate to the
  /// declaration of [element].
  ///
  /// If for any reason the location cannot be computed, returns `null`.
  Command? getNavigationCommand(
    LspClientCapabilities clientCapabilities,
    String title,
    Element element,
    Map<String, LineInfo?> lineInfoCache,
  ) {
    assert(clientSupportsGoToLocationCommand(clientCapabilities));

    var location = getLocation(element, lineInfoCache);
    if (location == null) {
      return null;
    }

    return Command(
      command: ClientCommands.goToLocation,
      arguments: [location],
      title: title,
    );
  }

  Future<ErrorOr<List<CodeLens>>> handle(
    CodeLensParams params,
    MessageInfo message,
    CancellationToken token,
    Map<String, LineInfo?> lineInfoCache,
  );

  bool isAvailable(
    LspClientCapabilities clientCapabilities,
    CodeLensParams params,
  );
}
