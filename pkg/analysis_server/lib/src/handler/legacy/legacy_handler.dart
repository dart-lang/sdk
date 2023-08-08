// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/scanner/errors.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.g.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// A request handler for the completion domain.
abstract class CompletionHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  CompletionHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  /// Return `true` if completion is disabled and the handler should return. If
  /// `true` is returned then a response will already have been returned, so
  /// subclasses should not return a second response.
  bool get completionIsDisabled {
    if (!server.options.featureSet.completion) {
      sendResponse(Response.invalidParameter(
        request,
        'request',
        'The completion feature is not enabled',
      ));
      return true;
    }
    return false;
  }
}

/// A request handler for the legacy protocol.
abstract class LegacyHandler {
  /// The analysis server that is using this handler to process a request.
  final LegacyAnalysisServer server;

  /// The request being handled.
  final Request request;

  /// The token used in order to allow the request to be cancelled. Not all
  /// handlers support cancelling a request.
  final CancellationToken cancellationToken;

  final OperationPerformanceImpl performance;

  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  LegacyHandler(
      this.server, this.request, this.cancellationToken, this.performance);

  /// Whether this command records its own analytics and should be excluded from
  /// logging by the server.
  ///
  /// This is useful if a command is generic (for example "lsp.handle") and
  /// can record a more specific command name.
  bool get recordsOwnAnalytics => false;

  /// Handle the [request].
  Future<void> handle();

  /// Return the number of syntactic errors in the list of [errors].
  int numberOfSyntacticErrors(List<AnalysisError> errors) {
    var numScanParseErrors = 0;
    for (var error in errors) {
      if (error.errorCode is ScannerErrorCode ||
          error.errorCode is ParserErrorCode) {
        numScanParseErrors++;
      }
    }
    return numScanParseErrors;
  }

  /// Send the [response] to the client.
  void sendResponse(Response response) {
    server.sendResponse(response);
  }

  /// Send a response to the client that is associated with the given [request]
  /// and whose body if the given [result].
  void sendResult(ResponseResult result) {
    sendResponse(result.toResponse(request.id));
  }

  /// Send a notification built from the given [params].
  void sendSearchResults(SearchResultsParams params) {
    server.sendNotification(params.toNotification());
  }
}
