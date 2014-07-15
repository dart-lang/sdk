// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.analysis;

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';

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
   * Implement the `analysis.getHover` request.
   */
  Response getAnalysisHover(Request request) {
    // prepare parameters
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    // prepare hovers
    List<Hover> hovers = <Hover>[];
    List<CompilationUnit> units = server.getResolvedCompilationUnits(file);
    for (CompilationUnit unit in units) {
      hovers.add(new DartUnitHoverComputer(unit, offset).compute());
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
      if (requestName == ANALYSIS_GET_HOVER) {
        return getAnalysisHover(request);
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
      } else if (requestName == ANALYSIS_UPDATE_SDKS) {
        return updateSdks(request);
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
      RequestDatum subDatum = request.getRequiredParameter(SUBSCRIPTIONS);
      Map<String, List<String>> subStringMap = subDatum.asStringListMap();
      subMap = new HashMap<AnalysisService, Set<String>>();
      subStringMap.forEach((String serviceName, List<String> paths) {
        AnalysisService service = Enum2.valueOf(AnalysisService.VALUES,
            serviceName);
        if (service == null) {
          throw new RequestFailure(new Response.unknownAnalysisService(request,
              serviceName));
        }
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
    filesDatum.forEachMap((file, changeDatum) {
      var change = new ContentChange();
      change.content = changeDatum[CONTENT].isNull ? null :
          changeDatum[CONTENT].asString();
      if (changeDatum.hasKey(OFFSET)) {
        change.offset = changeDatum[OFFSET].asInt();
        change.oldLength = changeDatum[OLD_LENGTH].asInt();
        change.newLength = changeDatum[NEW_LENGTH].asInt();
      }
      changes[file] = change;
    });
    server.updateContent(changes);
    return new Response(request.id);
  }

  /**
   * Implement the 'analysis.updateOptions' request.
   */
  Response updateOptions(Request request) {
    // options
    RequestDatum optionsDatum = request.getRequiredParameter(OPTIONS);
    List<OptionUpdater> updaters = new List<OptionUpdater>();
    optionsDatum.forEachMap((String optionName, RequestDatum optionDatum) {
      if (optionName == ANALYZE_ANGULAR) {
        bool optionValue = optionDatum.asBool();
        updaters.add((AnalysisOptionsImpl options) {
          options.analyzeAngular = optionValue;
        });
      } else if (optionName == ANALYZE_POLYMER) {
        bool optionValue = optionDatum.asBool();
        updaters.add((AnalysisOptionsImpl options) {
          options.analyzePolymer = optionValue;
        });
      } else if (optionName == ENABLE_ASYNC) {
        // TODO(brianwilkerson) Uncomment this when the option is supported.
//        bool optionValue = optionDatum.asBool();
//        updaters.add((AnalysisOptionsImpl options) {
//          options.enableAsync = optionValue;
//        });
      } else if (optionName == ENABLE_DEFERRED_LOADING) {
        bool optionValue = optionDatum.asBool();
        updaters.add((AnalysisOptionsImpl options) {
          options.enableDeferredLoading = optionValue;
        });
      } else if (optionName == ENABLE_ENUMS) {
        // TODO(brianwilkerson) Uncomment this when the option is supported.
//        bool optionValue = optionDatum.asBool();
//        updaters.add((AnalysisOptionsImpl options) {
//          options.enableEnums = optionValue;
//        });
      } else if (optionName == GENERATE_DART2JS_HINTS) {
        bool optionValue = optionDatum.asBool();
        updaters.add((AnalysisOptionsImpl options) {
          options.dart2jsHint = optionValue;
        });
      } else if (optionName == GENERATE_HINTS) {
        bool optionValue = optionDatum.asBool();
        updaters.add((AnalysisOptionsImpl options) {
          options.hint = optionValue;
        });
      } else {
        throw new RequestFailure(new Response.unknownOptionName(request,
            optionName));
      }
    });
    server.updateOptions(updaters);
    return new Response(request.id);
  }

  /**
   * Implement the 'analysis.updateSdks' request.
   */
  Response updateSdks(Request request) {
    // added
    RequestDatum addedDatum = request.getRequiredParameter(ADDED);
    List<String> added = addedDatum.asStringList();
    // removed
    RequestDatum removedDatum = request.getRequiredParameter(REMOVED);
    List<String> removed = removedDatum.asStringList();
    // default
    RequestDatum defaultDatum = request.getRequiredParameter(DEFAULT);
    String defaultSdk = defaultDatum.asString();
    // TODO(scheglov) implement
    return null;
  }
}


/**
 * A description of the change to the content of a file.
 */
class ContentChange {
  String content;
  int offset;
  int oldLength;
  int newLength;
}
