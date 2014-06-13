// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.analysis;

import 'dart:collection';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';

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

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == METHOD_GET_FIXES) {
        return getFixes(request);
      } else if (requestName == METHOD_GET_MINOR_REFACTORINGS) {
          return getMinorRefactorings(request);
      } else if (requestName == METHOD_SET_ANALYSIS_ROOTS) {
        return setAnalysisRoots(request);
      } else if (requestName == METHOD_SET_PRIORITY_FILES) {
        return setPriorityFiles(request);
      } else if (requestName == METHOD_SET_ANALYSIS_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == METHOD_UPDATE_CONTENT) {
        return updateContent(request);
      } else if (requestName == METHOD_UPDATE_OPTIONS) {
        return updateOptions(request);
      } else if (requestName == METHOD_UPDATE_SDKS) {
        return updateSdks(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response getFixes(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response getMinorRefactorings(Request request) {
    // TODO(scheglov) implement
    return null;
  }

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

  Response setPriorityFiles(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response setSubscriptions(Request request) {
    // parse subscriptions
    Map<AnalysisService, Set<String>> subMap;
    {
      RequestDatum subDatum = request.getRequiredParameter(SUBSCRIPTIONS);
      Map<String, List<String>> subStringMap = subDatum.asStringListMap();
      subMap = new HashMap<AnalysisService, Set<String>>();
      subStringMap.forEach((String serviceName, List<String> paths) {
        AnalysisService service = Enum2.valueOf(AnalysisService.VALUES, serviceName);
        if (service == null) {
          throw new RequestFailure(
              new Response.unknownAnalysisService(request, serviceName));
        }
        subMap[service] = new HashSet.from(paths);
      });
    }
    server.setAnalysisSubscriptions(subMap);
    return new Response(request.id);
  }

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

  Response updateOptions(Request request) {
    // TODO(scheglov) implement
    return null;
  }

  Response updateSdks(Request request) {
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
