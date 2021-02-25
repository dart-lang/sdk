// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/analysis_server_abstract.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/diagnostic_server.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';

abstract class AbstractSocketServer {
  AbstractAnalysisServer get analysisServer;

  AnalysisServerOptions get analysisServerOptions;

  DiagnosticServer get diagnosticServer;
}

/// Instances of the class [SocketServer] implement the common parts of
/// http-based and stdio-based analysis servers.  The primary responsibility of
/// the SocketServer is to manage the lifetime of the AnalysisServer and to
/// encode and decode the JSON messages exchanged with the client.
class SocketServer implements AbstractSocketServer {
  @override
  final AnalysisServerOptions analysisServerOptions;

  /// The function used to create a new SDK using the default SDK.
  final DartSdkManager sdkManager;

  final CrashReportingAttachmentsBuilder crashReportingAttachmentsBuilder;
  final InstrumentationService instrumentationService;
  final RequestStatisticsHelper requestStatistics;
  @override
  final DiagnosticServer diagnosticServer;
  final DetachableFileSystemManager detachableFileSystemManager;

  /// The analysis server that was created when a client established a
  /// connection, or `null` if no such connection has yet been established.
  @override
  AnalysisServer analysisServer;

  SocketServer(
      this.analysisServerOptions,
      this.sdkManager,
      this.crashReportingAttachmentsBuilder,
      this.instrumentationService,
      this.requestStatistics,
      this.diagnosticServer,
      this.detachableFileSystemManager);

  /// Create an analysis server which will communicate with the client using the
  /// given serverChannel.
  void createAnalysisServer(ServerCommunicationChannel serverChannel) {
    if (analysisServer != null) {
      var error = RequestError(
          RequestErrorCode.SERVER_ALREADY_STARTED, 'Server already started');
      serverChannel.sendResponse(Response('', error: error));
      serverChannel.listen((Request request) {
        serverChannel.sendResponse(Response(request.id, error: error));
      });
      return;
    }

    var resourceProvider = PhysicalResourceProvider(
        stateLocation: analysisServerOptions.cacheFolder);

    analysisServer = AnalysisServer(
      serverChannel,
      resourceProvider,
      analysisServerOptions,
      sdkManager,
      crashReportingAttachmentsBuilder,
      instrumentationService,
      requestStatistics: requestStatistics,
      diagnosticServer: diagnosticServer,
      detachableFileSystemManager: detachableFileSystemManager,
    );
    detachableFileSystemManager?.setAnalysisServer(analysisServer);
  }
}
