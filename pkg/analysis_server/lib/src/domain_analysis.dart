// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.analysis;

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_server/src/services/correction/change.dart';
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
    server.onFileAnalysisComplete(file).then((_) {
      Response response = new Response(request.id);
      engine.AnalysisErrorInfo errorInfo = server.getErrors(file);
      if (errorInfo == null) {
        response.setResult(ERRORS, []);
      } else {
        response.setResult(ERRORS, engineErrorInfoToJson(errorInfo));
      }
      server.sendResponse(response);
    }).catchError((message) {
      if (message is! String) {
        engine.AnalysisEngine.instance.logger.logError(
            'Illegal error message during getErrors: $message');
        message = '';
      }
      Response response = new Response.getErrorsError(request, message);
      response.setResult(ERRORS, []);
      server.sendResponse(response);
    });
    // delay response
    return Response.DELAYED_RESPONSE;
  }

  /**
   * Implement the `analysis.getHover` request.
   */
  Response getHover(Request request) {
    // prepare parameters
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    // prepare hovers
    List<Hover> hovers = <Hover>[];
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    for (CompilationUnit unit in units) {
      Hover hoverInformation =
          new DartUnitHoverComputer(unit, offset).compute();
      if (hoverInformation != null) {
        hovers.add(hoverInformation);
      }
    }
    // send response
    Response response = new Response(request.id);
    response.setResult(HOVERS, hovers);
    return response;
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == ANALYSIS_GET_ERRORS) {
        return getErrors(request);
      } else if (requestName == ANALYSIS_GET_HOVER) {
        return getHover(request);
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
   * Implement the 'analysis.setAnalysisRoots' request.
   */
  Response setAnalysisRoots(Request request) {
    // included
    RequestDatum includedDatum = request.getRequiredParameter(INCLUDED);
    List<String> includedPaths = includedDatum.asStringList();
    // excluded
    RequestDatum excludedDatum = request.getRequiredParameter(EXCLUDED);
    List<String> excludedPaths = excludedDatum.asStringList();
    // continue in server
    server.setAnalysisRoots(request.id, includedPaths, excludedPaths);
    return new Response(request.id);
  }

  /**
   * Implement the 'analysis.setPriorityFiles' request.
   */
  Response setPriorityFiles(Request request) {
    // files
    RequestDatum filesDatum = request.getRequiredParameter(FILES);
    List<String> files = filesDatum.asStringList();
    server.setPriorityFiles(request, files);
    return new Response(request.id);
  }

  /**
   * Implement the 'analysis.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    // parse subscriptions
    Map<AnalysisService, Set<String>> subMap;
    {
      Map<AnalysisService, List<String>> subscriptions =
          new AnalysisSetSubscriptionsParams.fromRequest(request).subscriptions;
      subMap = new HashMap<AnalysisService, Set<String>>();
      subscriptions.forEach((AnalysisService service, List<String> paths) {
        subMap[service] = new HashSet.from(paths);
      });
    }
    server.setAnalysisSubscriptions(subMap);
    return new Response(request.id);
  }

  /**
   * Implement the 'analysis.updateContent' request.
   */
  Response updateContent(Request request) {
    var changes = new HashMap<String, ContentChange>();
    RequestDatum filesDatum = request.getRequiredParameter(FILES);
    for (String file in filesDatum.keys) {
      RequestDatum changeDatum = filesDatum[file];
      ContentChange change = new ContentChange();
      change.type = changeDatum[TYPE].asString();
      switch (change.type) {
        case ADD:
          change.content = changeDatum[CONTENT].asString();
          break;
        case CHANGE:
          change.changes = changeDatum[EDITS].asList((RequestDatum item) {
            int offset = item[OFFSET].asInt();
            int length = item[LENGTH].asInt();
            String replacement = item[REPLACEMENT].asString();
            return new Edit(offset, length, replacement);
          });
          break;
        case REMOVE:
          break;
        default:
          return new Response.invalidParameter(
              request,
              changeDatum[TYPE].path,
              'be one of "add", "change", or "remove"');
      }
      changes[file] = change;
    }
    server.updateContent(changes);
    return new Response(request.id);
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
    return new Response(request.id);
  }
}


/**
 * A description of the change to the content of a file.
 */
class ContentChange {
  /**
   * Type of content change.  'add' means that [content] contains the full
   * content of the file, and [changes] should be null.  'change' means that
   * [changes] contains changes to be applied to the file, and [content] should
   * be null.  'remove' means that the file should be read from the filesystem,
   * and both [content] and [changes] should be null.
   */
  String type;

  String content;
  List<Edit> changes;
}
