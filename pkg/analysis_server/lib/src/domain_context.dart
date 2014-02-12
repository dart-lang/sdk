// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.context;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class [ContextDomainHandler] implement a [RequestHandler]
 * that handles requests in the context domain.
 */
class ContextDomainHandler implements RequestHandler {
  /**
   * The name of the context.applyChanges request.
   */
  static const String APPLY_CHANGES_NAME = 'context.applyChanges';

  /**
   * The name of the context.setOptions request.
   */
  static const String SET_OPTIONS_NAME = 'context.setOptions';

  /**
   * The name of the context.setPrioritySources request.
   */
  static const String SET_PRIORITY_SOURCES_NAME = 'context.setPrioritySources';

  /**
   * The name of the changes parameter.
   */
  static const String CHANGES_PARAM = 'changes';

  /**
   * The name of the contextId parameter.
   */
  static const String CONTEXT_ID_PARAM = 'contextId';

  /**
   * The name of the options parameter.
   */
  static const String OPTIONS_PARAM = 'options';

  /**
   * The name of the sources parameter.
   */
  static const String SOURCES_PARAM = 'sources';

  /**
   * The name of the cacheSize option.
   */
  static const String CACHE_SIZE_OPTION = 'cacheSize';

  /**
   * The name of the generateHints option.
   */
  static const String GENERATE_HINTS_OPTION = 'generateHints';

  /**
   * The name of the generateDart2jsHints option.
   */
  static const String GENERATE_DART2JS_OPTION = 'generateDart2jsHints';

  /**
   * The name of the provideErrors option.
   */
  static const String PROVIDE_ERRORS_OPTION = 'provideErrors';

  /**
   * The name of the provideNavigation option.
   */
  static const String PROVIDE_NAVIGATION_OPTION = 'provideNavigation';

  /**
   * The name of the provideOutline option.
   */
  static const String PROVIDE_OUTLINE_OPTION = 'provideOutline';

  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ContextDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == APPLY_CHANGES_NAME) {
        return applyChanges(request);
      } else if (requestName == SET_OPTIONS_NAME) {
        return setOptions(request);
      } else if (requestName == SET_PRIORITY_SOURCES_NAME) {
        return setPrioritySources(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Inform the specified context that the changes encoded in the change set
   * have been made. Any invalidated analysis results will be flushed from the
   * context.
   */
  Response applyChanges(Request request) {
    AnalysisContext context = getAnalysisContext(request);
    Map<String, Object> changesData = request.getRequiredParameter(CHANGES_PARAM);
    ChangeSet changeSet = createChangeSet(changesData);

    context.applyChanges(changeSet);
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Convert the given JSON object into a [ChangeSet].
   */
  ChangeSet createChangeSet(Map<String, Object> jsonData) {
    // TODO(brianwilkerson) Implement this.
    return null;
  }

  /**
   * Set the options controlling analysis within a context to the given set of
   * options.
   */
  Response setOptions(Request request) {
    AnalysisContext context = getAnalysisContext(request);

    context.analysisOptions = createAnalysisOptions(request);
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Return the set of analysis options associated with the given [request], or
   * throw a [RequestFailure] exception if the analysis options are not valid.
   */
  AnalysisOptions createAnalysisOptions(Request request) {
    Map<String, Object> optionsData = request.getRequiredParameter(OPTIONS_PARAM);
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    optionsData.forEach((String key, Object value) {
      if (key == CACHE_SIZE_OPTION) {
        options.cacheSize = request.toInt(value);
      } else if (key == GENERATE_HINTS_OPTION) {
        options.hint = request.toBool(value);
      } else if (key == GENERATE_DART2JS_OPTION) {
        options.dart2jsHint = request.toBool(value);
      } else if (key == PROVIDE_ERRORS_OPTION) {
//        options.provideErrors = toBool(request, value);
      } else if (key == PROVIDE_NAVIGATION_OPTION) {
//        options.provideNavigation = toBool(request, value);
      } else if (key == PROVIDE_OUTLINE_OPTION) {
//        options.provideOutline = toBool(request, value);
      } else {
        throw new RequestFailure(new Response.unknownAnalysisOption(request, key));
      }
    });
    return options;
  }

  /**
   * Set the priority sources in the specified context to the sources in the
   * given array.
   */
  Response setPrioritySources(Request request) {
    AnalysisContext context = getAnalysisContext(request);
    List<String> sourcesData = request.getRequiredParameter(SOURCES_PARAM);
    List<Source> sources = convertToSources(context.sourceFactory, sourcesData);

    context.analysisPriorityOrder = sources;
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Convert the given list of strings into a list of sources owned by the given
   * [sourceFactory].
   */
  List<Source> convertToSources(SourceFactory sourceFactory, List<String> sourcesData) {
    List<Source> sources = new List<Source>();
    sourcesData.forEach((String string) {
      sources.add(sourceFactory.fromEncoding(string));
    });
    return sources;
  }

  /**
   * Return the analysis context specified by the given request, or throw a
   * [RequestFailure] exception if either there is no specified context or if
   * the specified context does not exist.
   */
  AnalysisContext getAnalysisContext(Request request) {
    String contextId = request.getRequiredParameter(CONTEXT_ID_PARAM);
    AnalysisContext context = server.contextMap[contextId];
    if (context == null) {
      throw new RequestFailure(new Response.contextDoesNotExist(request));
    }
    return context;
  }
}
