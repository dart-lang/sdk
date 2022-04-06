// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/execution_create_context.dart';
import 'package:analysis_server/src/handler/legacy/execution_delete_context.dart';
import 'package:analysis_server/src/handler/legacy/execution_get_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/execution_map_uri.dart';
import 'package:analysis_server/src/handler/legacy/execution_set_subscriptions.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/execution/execution_context.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// Instances of the class [ExecutionDomainHandler] implement a [RequestHandler]
/// that handles requests in the `execution` domain.
class ExecutionDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// The context used by the execution domain handlers.
  final ExecutionContext executionContext;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  ExecutionDomainHandler(this.server, this.executionContext);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == EXECUTION_REQUEST_CREATE_CONTEXT) {
        ExecutionCreateContextHandler(
                server, request, cancellationToken, executionContext)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EXECUTION_REQUEST_DELETE_CONTEXT) {
        ExecutionDeleteContextHandler(
                server, request, cancellationToken, executionContext)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EXECUTION_REQUEST_GET_SUGGESTIONS) {
        ExecutionGetSuggestionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EXECUTION_REQUEST_MAP_URI) {
        ExecutionMapUriHandler(
                server, request, cancellationToken, executionContext)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EXECUTION_REQUEST_SET_SUBSCRIPTIONS) {
        ExecutionSetSubscriptionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
