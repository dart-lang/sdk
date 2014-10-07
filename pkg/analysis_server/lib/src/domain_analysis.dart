// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.analysis;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' as engine;


/**
 * Instances of the class [AnalysisDomainHandler] implement a [RequestHandler]
 * that handles requests in the `analysis` domain.
 */
class AnalysisDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  AnalysisDomainHandler(this.server);

  /**
   * Implement the `analysis.getErrors` request.
   */
  Response getErrors(Request request) {
    String file = new AnalysisGetErrorsParams.fromRequest(request).file;
    Future<AnalysisDoneReason> completionFuture =
        server.onFileAnalysisComplete(file);
    if (completionFuture == null) {
      return new Response.getErrorsInvalidFile(request);
    }
    completionFuture.then((AnalysisDoneReason reason) {
      switch (reason) {
        case AnalysisDoneReason.COMPLETE:
          engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
          List<AnalysisError> errors;
          if (errorInfo == null) {
            server.sendResponse(new Response.getErrorsInvalidFile(request));
          } else {
            errors = doAnalysisError_listFromEngine(errorInfo.lineInfo,
                errorInfo.errors);
            server.sendResponse(new AnalysisGetErrorsResult(errors).toResponse(
                request.id));
          }
          break;
        case AnalysisDoneReason.CONTEXT_REMOVED:
          // The active contexts have changed, so try again.
          Response response = getErrors(request);
          if (response != Response.DELAYED_RESPONSE) {
            server.sendResponse(response);
          }
          break;
      }
    });
    // delay response
    return Response.DELAYED_RESPONSE;
  }

  /**
   * Implement the `analysis.getHover` request.
   */
  Response getHover(Request request) {
    // prepare parameters
    var params = new AnalysisGetHoverParams.fromRequest(request);
    // prepare hovers
    List<HoverInformation> hovers = <HoverInformation>[];
    List<CompilationUnit> units =
        server.getResolvedCompilationUnits(params.file);
    for (CompilationUnit unit in units) {
      HoverInformation hoverInformation =
          new DartUnitHoverComputer(unit, params.offset).compute();
      if (hoverInformation != null) {
        hovers.add(hoverInformation);
      }
    }
    // send response
    return new AnalysisGetHoverResult(hovers).toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == ANALYSIS_GET_ERRORS) {
        return getErrors(request);
      } else if (requestName == ANALYSIS_GET_HOVER) {
        return getHover(request);
      } else if (requestName == ANALYSIS_REANALYZE) {
        return reanalyze(request);
      } else if (requestName == ANALYSIS_SET_ANALYSIS_ROOTS) {
        return setAnalysisRoots(request);
      } else if (requestName == ANALYSIS_SET_PRIORITY_FILES) {
        return setPriorityFiles(request);
      } else if (requestName == ANALYSIS_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == ANALYSIS_UPDATE_CONTENT) {
        return updateContent(request);
      } else if (requestName == ANALYSIS_UPDATE_OPTIONS) {
        return updateOptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the 'analysis.reanalyze' request.
   */
  Response reanalyze(Request request) {
    server.reanalyze();
    return new AnalysisReanalyzeResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setAnalysisRoots' request.
   */
  Response setAnalysisRoots(Request request) {
    var params = new AnalysisSetAnalysisRootsParams.fromRequest(request);
    // continue in server
    server.setAnalysisRoots(request.id, params.included, params.excluded);
    return new AnalysisSetAnalysisRootsResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setPriorityFiles' request.
   */
  Response setPriorityFiles(Request request) {
    var params = new AnalysisSetPriorityFilesParams.fromRequest(request);
    server.setPriorityFiles(request, params.files);
    return new AnalysisSetPriorityFilesResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    var params = new AnalysisSetSubscriptionsParams.fromRequest(request);
    // parse subscriptions
    Map<AnalysisService, Set<String>> subMap =
        mapMap(params.subscriptions, valueCallback:
          (List<String> subscriptions) => subscriptions.toSet());
    server.setAnalysisSubscriptions(subMap);
    return new AnalysisSetSubscriptionsResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.updateContent' request.
   */
  Response updateContent(Request request) {
    var params = new AnalysisUpdateContentParams.fromRequest(request);
    server.updateContent(request.id, params.files);
    return new AnalysisUpdateContentResult().toResponse(request.id);
  }

  /**
   * Implement the 'analysis.updateOptions' request.
   */
  Response updateOptions(Request request) {
    // options
    var params = new AnalysisUpdateOptionsParams.fromRequest(request);
    AnalysisOptions newOptions = params.options;
    List<OptionUpdater> updaters = new List<OptionUpdater>();
    // TODO(paulberry): analyzeAngular and analyzePolymer are not in the API.
//    if (newOptions.analyzeAngular != null) {
//      updaters.add((engine.AnalysisOptionsImpl options) {
//        options.analyzeAngular = newOptions.analyzeAngular;
//      });
//    }
//    if (newOptions.analyzePolymer != null) {
//      updaters.add((engine.AnalysisOptionsImpl options) {
//        options.analyzePolymer = newOptions.analyzePolymer;
//      });
//    }
    if (newOptions.enableAsync != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.enableAsync = newOptions.enableAsync;
      });
    }
    if (newOptions.enableDeferredLoading != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.enableDeferredLoading = newOptions.enableDeferredLoading;
      });
    }
    if (newOptions.enableEnums != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.enableEnum = newOptions.enableEnums;
      });
    }
    if (newOptions.generateDart2jsHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.dart2jsHint = newOptions.generateDart2jsHints;
      });
    }
    if (newOptions.generateHints != null) {
      updaters.add((engine.AnalysisOptionsImpl options) {
        options.hint = newOptions.generateHints;
      });
    }
    server.updateOptions(updaters);
    return new AnalysisUpdateOptionsResult().toResponse(request.id);
  }
}
