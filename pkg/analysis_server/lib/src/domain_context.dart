// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.context;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class [ContextDomainHandler] implement a [RequestHandler]
 * that handles requests in the context domain.
 *
 * TODO(scheglov) this class is replaces with [AnalysisDomainHandler].
 */
class ContextDomainHandler implements RequestHandler {
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
      } else if (requestName == GET_FIXES_NAME) {
        return getFixes(request);
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
    RequestDatum changesData = request.getRequiredParameter(CHANGES_PARAM);
    ChangeSet changeSet = createChangeSet(
        request,
        context.sourceFactory,
        changesData);

    context.applyChanges(changeSet);
    server.addContextToWorkQueue(context);
    Response response = new Response(request.id);
    return response;
  }

  /**
   * Convert the given JSON object into a [ChangeSet], using the given
   * [sourceFactory] to convert the embedded strings into sources.
   */
  ChangeSet createChangeSet(Request request, SourceFactory sourceFactory,
                            RequestDatum jsonData) {
    ChangeSet changeSet = new ChangeSet();
    if (jsonData.hasKey(ADDED)) {
      convertSources(request, sourceFactory, jsonData[ADDED], (Source source) {
        changeSet.addedSource(source);
      });
    }
    if (jsonData.hasKey(MODIFIED_PARAM)) {
      convertSources(request, sourceFactory, jsonData[MODIFIED_PARAM], (Source source) {
        changeSet.changedSource(source);
      });
    }
    if (jsonData.hasKey(REMOVED)) {
      convertSources(request, sourceFactory, jsonData[REMOVED], (Source source) {
        changeSet.removedSource(source);
      });
    }
    return changeSet;
  }

  /**
   * If the given [sources] is a list of strings, use the given [sourceFactory]
   * to convert each string into a source and pass the source to the given
   * [handler]. Otherwise, throw an exception indicating that the data in the
   * request was not valid.
   */
  void convertSources(Request request, SourceFactory sourceFactory, RequestDatum sources, void handler(Source source)) {
    convertToSources(sourceFactory, sources.asStringList()).forEach(handler);
  }

  /**
   * Return the list of fixes that are available for problems related to the
   * given error in the specified context.
   */
  Response getFixes(Request request) {
    // TODO(brianwilkerson) Implement this.
    Response response = new Response(request.id);
    return response;
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
    RequestDatum optionsData = request.getRequiredParameter(OPTIONS);
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    optionsData.forEachMap((String key, RequestDatum value) {
      if (key == CACHE_SIZE_OPTION) {
        options.cacheSize = value.asInt();
      } else if (key == GENERATE_HINTS_OPTION) {
        options.hint = value.asBool();
      } else if (key == GENERATE_DART2JS_OPTION) {
        options.dart2jsHint = value.asBool();
      } else if (key == PROVIDE_ERRORS_OPTION) {
//        options.provideErrors = value.asBool();
      } else if (key == PROVIDE_NAVIGATION_OPTION) {
//        options.provideNavigation = value.asBool();
      } else if (key == PROVIDE_OUTLINE_OPTION) {
//        options.provideOutline = value.asBool();
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
    List<String> sourcesData = request.getRequiredParameter(SOURCES_PARAM).asStringList();
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
    // TODO(scheglov) remove it after migrating to the new API
    return null;
//    String contextId = request.getRequiredParameter(CONTEXT_ID_PARAM).asString();
//    AnalysisContext context = server.contextMap[contextId];
//    if (context == null) {
//      throw new RequestFailure(new Response.contextDoesNotExist(request));
//    }
//    return context;
  }
}
