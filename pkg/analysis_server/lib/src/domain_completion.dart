// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestion_details.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestion_details2.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/completion_get_suggestions2.dart';
import 'package:analysis_server/src/handler/legacy/completion_set_subscriptions.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// Instances of the class [CompletionDomainHandler] implement a
/// [RequestHandler] that handles requests in the completion domain.
class CompletionDomainHandler extends AbstractRequestHandler {
  /// Initialize a new request handler for the given [server].
  CompletionDomainHandler(super.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    if (!server.options.featureSet.completion) {
      return Response.invalidParameter(
        request,
        'request',
        'The completion feature is not enabled',
      );
    }

    return runZonedGuarded<Response?>(() {
      var requestName = request.method;

      if (requestName == COMPLETION_REQUEST_GET_SUGGESTION_DETAILS) {
        CompletionGetSuggestionDetailsHandler(
                server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == COMPLETION_REQUEST_GET_SUGGESTION_DETAILS2) {
        CompletionGetSuggestionDetails2Handler(
                server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == COMPLETION_REQUEST_GET_SUGGESTIONS) {
        CompletionGetSuggestionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == COMPLETION_REQUEST_GET_SUGGESTIONS2) {
        CompletionGetSuggestions2Handler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == COMPLETION_REQUEST_SET_SUBSCRIPTIONS) {
        CompletionSetSubscriptionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
      return null;
    }, (exception, stackTrace) {
      AnalysisEngine.instance.instrumentationService.logException(
          CaughtException.withMessage(
              'Failed to handle completion domain request: ${request.method}',
              exception,
              stackTrace));
    });
  }
}
