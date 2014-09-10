// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.execution;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'dart:collection';
import 'package:analyzer/src/generated/engine.dart';
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
  Map<String, String> contextMap = new HashMap<String, String>();

  /**
   * The listener used to send notifications when
   */
  LaunchDataNotificationListener launchDataListener;

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

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == EXECUTION_CREATE_CONTEXT) {
        return createContext(request);
      } else if (requestName == EXECUTION_DELETE_CONTEXT) {
        return deleteContext(request);
      } else if (requestName == EXECUTION_MAP_URI) {
        return mapUri(request);
      } else if (requestName == EXECUTION_SET_SUBSCRIPTIONS) {
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
      return new Response.invalidParameter(
          request,
          'id',
          'There is no execution context with an id of $contextId');
    }
    AnalysisContext context = server.getAnalysisContext(path);
    if (params.file != null) {
      if (params.uri != null) {
        return new Response.invalidParameter(
            request,
            'file',
            'Either file or uri must be provided, but not both');
      }
      Source source = server.getSource(path);
      String uri = context.sourceFactory.restoreUri(source).toString();
      return new ExecutionMapUriResult(uri: uri).toResponse(request.id);
    } else if (params.uri != null) {
      Source source = context.sourceFactory.forUri(params.uri);
      String file = source.fullName;
      return new ExecutionMapUriResult(file: file).toResponse(request.id);
    }
    return new Response.invalidParameter(
        request,
        'file',
        'Either file or uri must be provided');
  }

  /**
   * Implement the 'execution.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    List<ExecutionService> subscriptions =
        new ExecutionSetSubscriptionsParams.fromRequest(request).subscriptions;
    if (subscriptions.contains(ExecutionService.LAUNCH_DATA)) {
      if (launchDataListener == null) {
        launchDataListener = new LaunchDataNotificationListener(server);
        server.addAnalysisServerListener(launchDataListener);
        if (server.isAnalysisComplete()) {
          launchDataListener.analysisComplete();
        }
      }
    } else {
      if (launchDataListener != null) {
        server.removeAnalysisServerListener(launchDataListener);
        launchDataListener = null;
      }
    }
    return new ExecutionSetSubscriptionsResult().toResponse(request.id);
  }
}

/**
 * Instances of the class [LaunchDataNotificationListener] listen for analysis
 * to be complete and then notify the client of the launch data that has been
 * computed.
 */
class LaunchDataNotificationListener implements AnalysisServerListener {
  /**
   * The analysis server used to send notifications.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created listener to send notifications through the given
   * [server] when analysis is complete.
   */
  LaunchDataNotificationListener(this.server);

  @override
  void analysisComplete() {
    List<ExecutableFile> executables = [];
    Map<String, List<String>> dartToHtml = new HashMap<String, List<String>>();
    Map<String, List<String>> htmlToDart = new HashMap<String, List<String>>();
    for (AnalysisContext context in server.getAnalysisContexts()) {
      List<Source> clientSources = context.launchableClientLibrarySources;
      List<Source> serverSources = context.launchableServerLibrarySources;
      for (Source source in clientSources) {
        ExecutableKind kind = ExecutableKind.CLIENT;
        if (serverSources.remove(source)) {
          kind = ExecutableKind.EITHER;
        }
        executables.add(new ExecutableFile(source.fullName, kind));
      }
      for (Source source in serverSources) {
        executables.add(
            new ExecutableFile(source.fullName, ExecutableKind.SERVER));
      }

      for (Source librarySource in context.librarySources) {
        List<Source> files = context.getHtmlFilesReferencing(librarySource);
        if (files.isNotEmpty) {
          // TODO(brianwilkerson) Handle the case where the same library is
          // being analyzed in multiple contexts.
          dartToHtml[librarySource.fullName] = getFullNames(files);
        }
      }

      for (Source htmlSource in context.htmlSources) {
        List<Source> libraries =
            context.getLibrariesReferencedFromHtml(htmlSource);
        if (libraries.isNotEmpty) {
          // TODO(brianwilkerson) Handle the case where the same HTML file is
          // being analyzed in multiple contexts.
          htmlToDart[htmlSource.fullName] = getFullNames(libraries);
        }
      }
    }
    server.sendNotification(
        new ExecutionLaunchDataParams(
            executables,
            dartToHtml,
            htmlToDart).toNotification());
  }

  List<String> getFullNames(List<Source> sources) {
    return sources.map((Source source) => source.fullName).toList();
  }
}
