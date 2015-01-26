// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.execution;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
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
   * The subscription to the 'onAnalysisComplete' events,
   * used to send notifications when
   */
  StreamSubscription onFileAnalyzed;

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
      Source source = server.getSource(params.file);
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
      if (onFileAnalyzed == null) {
        onFileAnalyzed = server.onFileAnalyzed.listen(_fileAnalyzed);
        _reportCurrentFileStatus();
      }
    } else {
      if (onFileAnalyzed != null) {
        onFileAnalyzed.cancel();
        onFileAnalyzed = null;
      }
    }
    return new ExecutionSetSubscriptionsResult().toResponse(request.id);
  }

  void _fileAnalyzed(ChangeNotice notice) {
    Source source = notice.source;
    String filePath = source.fullName;
    if (!_isInAnalysisRoot(filePath)) {
      return;
    }
    AnalysisContext context = server.getAnalysisContext(filePath);
    if (AnalysisEngine.isDartFileName(filePath)) {
      ExecutableKind kind = ExecutableKind.NOT_EXECUTABLE;
      if (context.isClientLibrary(source)) {
        kind = ExecutableKind.CLIENT;
        if (context.isServerLibrary(source)) {
          kind = ExecutableKind.EITHER;
        }
      } else if (context.isServerLibrary(source)) {
        kind = ExecutableKind.SERVER;
      }
      server.sendNotification(
          new ExecutionLaunchDataParams(filePath, kind: kind).toNotification());
    } else if (AnalysisEngine.isHtmlFileName(filePath)) {
      List<Source> libraries = context.getLibrariesReferencedFromHtml(source);
      server.sendNotification(
          new ExecutionLaunchDataParams(
              filePath,
              referencedFiles: _getFullNames(libraries)).toNotification());
    }
  }

  /**
   * Return `true` if the given [filePath] represents a file that is in an
   * analysis root.
   */
  bool _isInAnalysisRoot(String filePath) =>
      server.contextDirectoryManager.isInAnalysisRoot(filePath);

  void _reportCurrentFileStatus() {
    for (AnalysisContext context in server.getAnalysisContexts()) {
      List<Source> librarySources = context.librarySources;
      List<Source> clientSources = context.launchableClientLibrarySources;
      List<Source> serverSources = context.launchableServerLibrarySources;
      for (Source source in clientSources) {
        if (serverSources.remove(source)) {
          _sendKindNotification(source.fullName, ExecutableKind.EITHER);
        } else {
          _sendKindNotification(source.fullName, ExecutableKind.CLIENT);
        }
        librarySources.remove(source);
      }
      for (Source source in serverSources) {
        _sendKindNotification(source.fullName, ExecutableKind.SERVER);
        librarySources.remove(source);
      }
      for (Source source in librarySources) {
        _sendKindNotification(source.fullName, ExecutableKind.NOT_EXECUTABLE);
      }
      for (Source source in context.htmlSources) {
        String filePath = source.fullName;
        if (_isInAnalysisRoot(filePath)) {
          List<Source> libraries =
              context.getLibrariesReferencedFromHtml(source);
          server.sendNotification(
              new ExecutionLaunchDataParams(
                  filePath,
                  referencedFiles: _getFullNames(libraries)).toNotification());
        }
      }
    }
  }

  /**
   * Send a notification indicating the [kind] of the file with the given
   * [filePath], but only if the file is in an analysis root.
   */
  void _sendKindNotification(String filePath, ExecutableKind kind) {
    if (_isInAnalysisRoot(filePath)) {
      server.sendNotification(
          new ExecutionLaunchDataParams(filePath, kind: kind).toNotification());
    }
  }

  static List<String> _getFullNames(List<Source> sources) {
    return sources.map((Source source) => source.fullName).toList();
  }
}
