// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol.dart';

class LspNotificationManager extends AbstractNotificationManager {
  /// The analysis server, used to fetch LineInfo in order to map plugin
  /// data structures to LSP structures.
  // Set externally immediately after construction.
  late final LspAnalysisServer server;

  LspNotificationManager(super.pathContext);

  /// Sends errors for a file to the client.
  @override
  void sendAnalysisErrors(
    String filePath,
    List<protocol.AnalysisError> errors,
  ) {
    // Currently these diagnostics are always sent to the editor client, so
    // use those client capabilities.
    var clientCapabilities = server.editorClientCapabilities;
    var diagnostics =
        errors
            .map(
              (error) => pluginToDiagnostic(
                server.uriConverter,
                (path) => server.getLineInfo(path),
                error,
                supportedTags: clientCapabilities?.diagnosticTags,
                clientSupportsCodeDescription:
                    clientCapabilities?.diagnosticCodeDescription ?? false,
              ),
            )
            .toList();

    server.publishDiagnostics(filePath, diagnostics);
  }

  @override
  void sendFoldingRegions(
    String filePath,
    List<protocol.FoldingRegion> mergedFolding,
  ) {
    // In LSP, folding regions are requested by the client with
    // 'textDocument/foldingRange' rather than pushed so there's no need
    // to do anything here. Results are merged by the base class and provided
    // on-demand.
  }

  @override
  void sendHighlightRegions(
    String filePath,
    List<protocol.HighlightRegion> mergedHighlights,
  ) {
    // TODO(dantup): implement sendHighlightRegions
  }

  @override
  void sendNavigations(protocol.AnalysisNavigationParams mergedNavigations) {
    // In LSP, occurrences are requested by the client with 'textDocument/definition'
    // and 'textDocument/references' rather than pushed so there's no need
    // to do anything here. Results are merged by the base class and provided
    // on-demand.
  }

  @override
  void sendOccurrences(
    String filePath,
    List<protocol.Occurrences> mergedOccurrences,
  ) {
    // In LSP, occurrences are requested by the client with
    // 'textDocument/documentHighlight' rather than pushed so there's no need
    // to do anything here. Results are merged by the base class and provided
    // on-demand.
  }

  @override
  void sendOutlines(String filePath, List<protocol.Outline> mergedOutlines) {
    // In LSP, outlines are requested by the client with
    // 'textDocument/documentSymbol' rather than pushed so there's no need
    // to do anything here. Results are merged by the base class and provided
    // on-demand.
  }

  @override
  void sendPluginError(String message) {
    // TODO(srawlins): Implement.
  }

  @override
  void sendPluginErrorNotification(Notification notification) {
    // TODO(dantup): implement sendPluginErrorNotification
  }
}
