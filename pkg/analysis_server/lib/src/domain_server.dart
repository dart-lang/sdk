// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.server;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';

/**
 * Instances of the class [ServerDomainHandler] implement a [RequestHandler]
 * that handles requests in the server domain.
 */
class ServerDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ServerDomainHandler(this.server);

  /**
   * Return the version number of the analysis server.
   */
  Response getVersion(Request request) {
    Response response = new Response(request.id);
    response.setResult(VERSION, '0.0.1');
    return response;
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == SERVER_GET_VERSION) {
        return getVersion(request);
      } else if (requestName == SERVER_SET_SUBSCRIPTIONS) {
          return setSubscriptions(request);
      } else if (requestName == SERVER_SHUTDOWN) {
        return shutdown(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Subscribe for services.
   *
   * All previous subscriptions are replaced by the given set of subscriptions.
   */
  Response setSubscriptions(Request request) {
    server.serverServices =
        new ServerSetSubscriptionsParams.fromRequest(request).subscriptions.toSet();
    return new Response(request.id);
  }

  // TODO(scheglov) remove or move to the 'analysis' domain
//  /**
//   * Create a new context in which analysis can be performed. The context that
//   * is created will persist until server.deleteContext is used to delete it.
//   * Clients, therefore, are responsible for managing the lifetime of contexts.
//   */
//  Response createContext(Request request) {
//    String sdkDirectory = request.getRequiredParameter(SDK_DIRECTORY_PARAM).asString();
//    Map<String, String> packageMap = request.getParameter(PACKAGE_MAP_PARAM, {}).asStringMap();
//
//    String contextId = request.getRequiredParameter(AnalysisServer.CONTEXT_ID_PARAM).asString();
//    if (server.contextMap.containsKey(contextId)) {
//      return new Response.contextAlreadyExists(request);
//    }
//    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
//    // TODO(brianwilkerson) Use the information from the request to set the
//    // source factory in the context.
//    DirectoryBasedDartSdk sdk;
//    try {
//      sdk = new DirectoryBasedDartSdk(new JavaFile(sdkDirectory));
//    } on Exception catch (e) {
//      // TODO what error code should be returned here?
//      return new Response(request.id, new RequestError(
//          RequestError.CODE_SDK_ERROR, 'Failed to access sdk: $e'));
//    }
//    context.sourceFactory = new SourceFactory([
//      new DartUriResolver(sdk),
//      new FileUriResolver(),
//      // new PackageUriResolver(),
//    ]);
//    server.contextMap[contextId] = context;
//    server.contextIdMap[context] = contextId;
//
//    Response response = new Response(request.id);
//    return response;
//  }
//
//  /**
//   * Delete the context with the given id. Future attempts to use the context id
//   * will result in an error being returned.
//   */
//  Response deleteContext(Request request) {
//    String contextId = request.getRequiredParameter(AnalysisServer.CONTEXT_ID_PARAM).asString();
//
//    AnalysisContext removedContext = server.contextMap.remove(contextId);
//    if (removedContext == null) {
//      return new Response.contextDoesNotExist(request);
//    }
//    server.contextIdMap.remove(removedContext);
//    Response response = new Response(request.id);
//    return response;
//  }

  /**
   * Cleanly shutdown the analysis server.
   */
  Response shutdown(Request request) {
    server.shutdown();
    Response response = new Response(request.id);
    return response;
  }
}
