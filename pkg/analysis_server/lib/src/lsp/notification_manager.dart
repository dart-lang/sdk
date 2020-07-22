// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:path/path.dart';

class LspNotificationManager extends AbstractNotificationManager {
  /// The channel used to send notifications to the client.
  final LspServerCommunicationChannel channel;

  /// The analysis server, used to fetch LineInfo in order to map plugin
  /// data structures to LSP structures.
  LspAnalysisServer server;

  LspNotificationManager(this.channel, Context pathContext)
      : super(pathContext);

  /// Sends errors for a file to the client.
  @override
  void sendAnalysisErrors(
      String filePath, List<protocol.AnalysisError> errors) {
    final diagnostics = errors
        .map((error) => pluginToDiagnostic(server.getLineInfo, error))
        .toList();

    final params = PublishDiagnosticsParams(
        uri: Uri.file(filePath).toString(), diagnostics: diagnostics);
    final message = NotificationMessage(
      method: Method.textDocument_publishDiagnostics,
      params: params,
      jsonrpc: jsonRpcVersion,
    );

    channel.sendNotification(message);
  }

  @override
  void sendFoldingRegions(
      String filePath, List<protocol.FoldingRegion> mergedFolding) {
    // In LSP, folding regions are requested by the client with
    // 'textDocument/foldingRange' rather than pushed so there's no need
    // to do anything here. Results are merged by the base class and provided
    // on-demand.
  }

  @override
  void sendHighlightRegions(
      String filePath, List<protocol.HighlightRegion> mergedHighlights) {
    // TODO: implement sendHighlightRegions
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
      String filePath, List<protocol.Occurrences> mergedOccurrences) {
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
  void sendPluginErrorNotification(Notification notification) {
    // TODO: implement sendPluginErrorNotification
  }
}
