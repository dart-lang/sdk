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
import 'package:analyzer/dart/element/element2.dart';

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

  /// Attempt to compute a [Location] to [fragment].
  ///
  /// If for any reason the location cannot be computed, returns `null`.
  Location? getLocation(Fragment fragment) {
    // We can't produce a location to a name if there isn't one.
    var nameOffset = fragment.nameOffset2;
    var nameLength = fragment.element.displayName.length;
    if (nameOffset == null) {
      return null;
    }

    // Map the source onto a URI and only return this item if the client
    // can handle the URI.
    var source = fragment.libraryFragment!.source;
    var uri = server.uriConverter.toClientUri(source.fullName);
    if (!server.uriConverter.supportedSchemes.contains(uri.scheme)) {
      return null;
    }

    var lineInfo = fragment.libraryFragment!.lineInfo;
    return Location(uri: uri, range: toRange(lineInfo, nameOffset, nameLength));
  }

  /// Builds a [Command] that with the text [title] that navigate to the
  /// [fragment].
  ///
  /// If for any reason the location cannot be computed, returns `null`.
  Command? getNavigationCommand(
    LspClientCapabilities clientCapabilities,
    String title,
    Fragment fragment,
  ) {
    assert(clientSupportsGoToLocationCommand(clientCapabilities));

    var location = getLocation(fragment);
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
  );

  bool isAvailable(
    LspClientCapabilities clientCapabilities,
    CodeLensParams params,
  );
}
