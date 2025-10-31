// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';

/// Instances of the class [SocketServer] implement the common parts of
/// http-based and stdio-based analysis servers.  The primary responsibility of
/// the SocketServer is to manage the lifetime of the AnalysisServer and to
/// encode and decode the JSON messages exchanged with the client.
class LspSocketServer implements AbstractSocketServer {
  @override
  final AnalysisServerOptions analysisServerOptions;

  /// The analysis server that was created when a client established a
  /// connection, or `null` if no such connection has yet been established.
  @override
  LspAnalysisServer? analysisServer;

  /// The function used to create a new SDK using the default SDK.
  final DartSdkManager sdkManager;

  @override
  final DiagnosticServer diagnosticServer;

  /// The object through which analytics are to be sent.
  final AnalyticsManager analyticsManager;

  final InstrumentationService instrumentationService;

  /// An optional manager to handle file systems which may not always be
  /// available.
  final DetachableFileSystemManager? detachableFileSystemManager;

  LspSocketServer(
    this.analysisServerOptions,
    this.diagnosticServer,
    this.analyticsManager,
    this.sdkManager,
    this.instrumentationService,
    this.detachableFileSystemManager,
  );

  /// Create an analysis server which will communicate with the client using the
  /// given serverChannel.
  void createAnalysisServer(LspServerCommunicationChannel serverChannel) {
    if (analysisServer != null) {
      var error = ResponseError(
        code: ServerErrorCodes.serverAlreadyStarted,
        message: 'Server already started',
      );
      serverChannel.sendNotification(
        NotificationMessage(
          method: Method.window_showMessage,
          params: ShowMessageParams(
            type: MessageType.Error,
            message: error.message,
          ),
          jsonrpc: jsonRpcVersion,
        ),
      );
      serverChannel.listen((Message message) {
        if (message is RequestMessage) {
          serverChannel.sendResponse(
            ResponseMessage(
              id: message.id,
              error: error,
              jsonrpc: jsonRpcVersion,
            ),
          );
        }
      });
      return;
    }

    var resourceProvider = PhysicalResourceProvider(
      stateLocation: analysisServerOptions.cacheFolder,
    );

    var server = analysisServer = LspAnalysisServer(
      serverChannel,
      resourceProvider,
      analysisServerOptions,
      sdkManager,
      analyticsManager,
      CrashReportingAttachmentsBuilder.empty,
      instrumentationService,
      diagnosticServer: diagnosticServer,
      detachableFileSystemManager: detachableFileSystemManager,
      enableBlazeWatcher: true,
    );
    detachableFileSystemManager?.setAnalysisServer(server);
  }
}
