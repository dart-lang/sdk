// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.server;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';

/**
 * Instances of the class [ServerDomainHandler] implement a [RequestHandler]
 * that handles requests in the server domain.
 */
class ServerDomainHandler implements RequestHandler {
  /**
   * The name of the server.createContext request.
   */
  static const String CREATE_CONTEXT_METHOD = 'server.createContext';

  /**
   * The name of the server.deleteContext request.
   */
  static const String DELETE_CONTEXT_METHOD = 'server.deleteContext';

  /**
   * The name of the server.shutdown request.
   */
  static const String SHUTDOWN_METHOD = 'server.shutdown';

  /**
   * The name of the server.version request.
   */
  static const String VERSION_METHOD = 'server.version';

  /**
   * The name of the contextId parameter.
   */
  static const String CONTEXT_ID_PARAM = 'contextId';

  /**
   * The name of the packageMap parameter.
   */
  static const String PACKAGE_MAP_PARAM = 'packageMap';

  /**
   * The name of the sdkDirectory parameter.
   */
  static const String SDK_DIRECTORY_PARAM = 'sdkDirectory';

  /**
   * The name of the contextId result value.
   */
  static const String CONTEXT_ID_RESULT = 'contextId';

  /**
   * The name of the version result value.
   */
  static const String VERSION_RESULT = 'version';

  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ServerDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == CREATE_CONTEXT_METHOD) {
        return createContext(request);
      } else if (requestName == DELETE_CONTEXT_METHOD) {
        return deleteContext(request);
      } else if (requestName == SHUTDOWN_METHOD) {
        return shutdown(request);
      } else if (requestName == VERSION_METHOD) {
        return version(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Create a new context in which analysis can be performed. The context that
   * is created will persist until server.deleteContext is used to delete it.
   * Clients, therefore, are responsible for managing the lifetime of contexts.
   */
  Response createContext(Request request) {
    String sdkDirectory = request.getRequiredParameter(SDK_DIRECTORY_PARAM);
    Map<String, String> packageMap = request.getParameter(PACKAGE_MAP_PARAM);

    String baseContextId = new DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    String contextId = baseContextId;
    int index = 1;
    while (server.contextMap.containsKey(contextId)) {
      contextId = '$baseContextId-$index';
    }
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    // TODO(brianwilkerson) Use the information from the request to set the
    // source factory in the context.
    context.sourceFactory = new SourceFactory.con2([
      new DartUriResolver(new DirectoryBasedDartSdk(new JavaFile(sdkDirectory))),
      new FileUriResolver(),
      // new PackageUriResolver(),
    ]);
    server.contextMap[contextId] = context;

    Response response = new Response(request.id);
    response.setResult(CONTEXT_ID_RESULT, contextId);
    return response;
  }

  /**
   * Delete the context with the given id. Future attempts to use the context id
   * will result in an error being returned.
   */
  Response deleteContext(Request request) {
    String contextId = request.getRequiredParameter(CONTEXT_ID_PARAM);

    AnalysisContext removedContext = server.contextMap.remove(contextId);
    if (removedContext == null) {
      return new Response.contextDoesNotExist(request);
    }
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Cleanly shutdown the analysis server.
   */
  Response shutdown(Request request) {
    server.running = false;
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Return the version number of the analysis server.
   */
  Response version(Request request) {
    Response response = new Response(request.id);
    response.setResult(VERSION_RESULT, '0.0.1');
    return response;
  }
}