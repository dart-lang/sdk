// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class [ExecutionDomainHandler] implement a [RequestHandler]
 * that handles requests in the `execution` domain.
 */
class ExecutionDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The next execution context identifier to be returned.
   */
  int nextContextId = 0;

  /**
   * A table mapping execution context id's to the root of the context.
   */
  final Map<String, String> contextMap = new HashMap<String, String>();

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ExecutionDomainHandler(this.server);

  /**
   * Implement the `execution.createContext` request.
   */
  Response createContext(Request request) {
    String file =
        new ExecutionCreateContextParams.fromRequest(request).contextRoot;
    String contextId = (nextContextId++).toString();
    contextMap[contextId] = file;
    return new ExecutionCreateContextResult(contextId).toResponse(request.id);
  }

  /**
   * Implement the `execution.deleteContext` request.
   */
  Response deleteContext(Request request) {
    String contextId = new ExecutionDeleteContextParams.fromRequest(request).id;
    contextMap.remove(contextId);
    return new ExecutionDeleteContextResult().toResponse(request.id);
  }

  /**
   * Implement the 'execution.getSuggestions' request.
   */
  void getSuggestions(Request request) async {
//    // TODO(brianwilkerson) Determine whether this await is necessary.
//    await null;
//    var params = new ExecutionGetSuggestionsParams.fromRequest(request);
//    var computer = new RuntimeCompletionComputer(
//        server.resourceProvider,
//        server.fileContentOverlay,
//        server.getAnalysisDriver(params.contextFile),
//        params.code,
//        params.offset,
//        params.contextFile,
//        params.contextOffset,
//        params.variables,
//        params.expressions);
//    RuntimeCompletionResult completionResult = await computer.compute();
//
//    // Send the response.
//    var result = new ExecutionGetSuggestionsResult(
//        suggestions: completionResult.suggestions,
//        expressions: completionResult.expressions);
    // TODO(brianwilkerson) Re-enable this functionality after implementing a
    // way of computing suggestions that is compatible with AnalysisSession.
    var result = new ExecutionGetSuggestionsResult(
        suggestions: <CompletionSuggestion>[],
        expressions: <RuntimeCompletionExpression>[]);
    server.sendResponse(result.toResponse(request.id));
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EXECUTION_REQUEST_CREATE_CONTEXT) {
        return createContext(request);
      } else if (requestName == EXECUTION_REQUEST_DELETE_CONTEXT) {
        return deleteContext(request);
      } else if (requestName == EXECUTION_REQUEST_GET_SUGGESTIONS) {
        getSuggestions(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == EXECUTION_REQUEST_MAP_URI) {
        return mapUri(request);
      } else if (requestName == EXECUTION_REQUEST_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the 'execution.mapUri' request.
   */
  Response mapUri(Request request) {
    ExecutionMapUriParams params =
        new ExecutionMapUriParams.fromRequest(request);
    String contextId = params.id;
    String path = contextMap[contextId];
    if (path == null) {
      return new Response.invalidParameter(request, 'id',
          'There is no execution context with an id of $contextId');
    }

    AnalysisDriver driver = server.getAnalysisDriver(path);
    if (driver == null) {
      return new Response.invalidExecutionContext(request, contextId);
    }
    SourceFactory sourceFactory = driver.sourceFactory;

    String file = params.file;
    String uri = params.uri;
    if (file != null) {
      if (uri != null) {
        return new Response.invalidParameter(request, 'file',
            'Either file or uri must be provided, but not both');
      }
      Resource resource = server.resourceProvider.getResource(file);
      if (!resource.exists) {
        return new Response.invalidParameter(request, 'file', 'Must exist');
      } else if (resource is! File) {
        return new Response.invalidParameter(
            request, 'file', 'Must not refer to a directory');
      }

      Source source = driver.fsState.getFileForPath(file).source;
      if (source.uriKind != UriKind.FILE_URI) {
        uri = source.uri.toString();
      } else {
        uri = sourceFactory.restoreUri(source).toString();
      }
      return new ExecutionMapUriResult(uri: uri).toResponse(request.id);
    } else if (uri != null) {
      Source source = sourceFactory.forUri(uri);
      if (source == null) {
        return new Response.invalidParameter(request, 'uri', 'Invalid URI');
      }
      file = source.fullName;
      return new ExecutionMapUriResult(file: file).toResponse(request.id);
    }
    return new Response.invalidParameter(
        request, 'file', 'Either file or uri must be provided');
  }

  /**
   * Implement the 'execution.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    // Under the analysis driver, setSubscriptions() becomes a no-op.
    return new ExecutionSetSubscriptionsResult().toResponse(request.id);
  }
}
