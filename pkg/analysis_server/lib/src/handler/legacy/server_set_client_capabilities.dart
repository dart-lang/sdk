// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analyzer/exception/exception.dart';

/// The handler for the `server.setClientCapabilities` request.
class ServerSetClientCapabilitiesHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  new(super.server, super.request, super.cancellationToken, super.performance);

  @override
  Future<void> handle() async {
    try {
      server.clientCapabilities = ServerSetClientCapabilitiesParams.fromRequest(
        request,
        clientUriConverter: server.uriConverter,
      );

      server.checkAnalytics();
    } on RequestFailure catch (exception) {
      _sendFailure(exception.response);
      return;
    } on RequestError catch (error) {
      _sendFailure(Response(request.id, error: error));
      return;
    }
    sendResult(ServerSetClientCapabilitiesResult());

    if (server.editorClientCapabilities.configuration) {
      // Now that we know the client's capabilities, fetch its configuration.
      //
      // This must not be awaited because it sends a request to the client and a
      // client may not process that request until it has had the response to
      // this one. LSP messages that arrive in the meantime wait for the
      // configuration (see [AnalysisServer.lspInitialized]), other legacy
      // requests are handled as usual.
      unawaited(_fetchClientConfiguration());
    } else {
      // There is no configuration to wait for, so LSP messages can be handled
      // immediately (unless an earlier message already completed the
      // initialization).
      server.completeLspInitializationIfNeeded();
    }
  }

  /// Fetches the client's configuration, logging (instead of throwing) any
  /// failure, and then completes LSP initialization if that has not already
  /// happened.
  ///
  /// This runs after the response to this request has been sent, so a failure
  /// escaping here would be reported by the zone in
  /// `LegacyAnalysisServer.handleRequest` as a second (failed) response to it.
  Future<void> _fetchClientConfiguration() async {
    try {
      await server.fetchClientConfiguration();
    } catch (exception, stackTrace) {
      server.instrumentationService.logException(
        CaughtException.withMessage(
          'An error occurred while fetching the client configuration',
          exception,
          stackTrace,
        ),
      );
    } finally {
      // LSP messages must not wait forever, so the gate is released whether the
      // client provided its configuration or not. Where it did not, the
      // defaults are used. It may already have been released by an earlier
      // message.
      server.completeLspInitializationIfNeeded();
    }
  }

  /// Sends [response] for this request, which failed, and completes LSP
  /// initialization if that has not already happened.
  ///
  /// The capabilities were rejected, so no configuration will be requested and
  /// LSP messages must not be left waiting for one. They are handled with the
  /// default configuration instead.
  void _sendFailure(Response response) {
    sendResponse(response);
    server.completeLspInitializationIfNeeded();
  }
}
