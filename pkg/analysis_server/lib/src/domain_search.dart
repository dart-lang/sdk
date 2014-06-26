// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.search;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';

/**
 * Instances of the class [SearchDomainHandler] implement a [RequestHandler]
 * that handles requests in the search domain.
 */
class SearchDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  SearchDomainHandler(this.server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == SEARCH_FIND_ELEMENT_REFERENCES) {
        return findElementReferences(request);
      } else if (requestName == SEARCH_FIND_MEMBER_DECLARATIONS) {
        return findMemberDeclarations(request);
      } else if (requestName == SEARCH_FIND_MEMBER_REFERENCES) {
        return findMemberReferences(request);
      } else if (requestName == SEARCH_FIND_TOP_LEVEL_DECLARATIONS) {
        return findTopLevelDeclarations(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  Response findElementReferences(Request request) {
    // file
    RequestDatum fileDatum = request.getRequiredParameter(FILE);
    String file = fileDatum.asString();
    // offset
    RequestDatum offsetDatum = request.getRequiredParameter(OFFSET);
    int offset = offsetDatum.asInt();
    // includePotential
    RequestDatum includePotentialDatum = request.getRequiredParameter(LENGTH);
    bool includePotential = includePotentialDatum.asBool();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response findMemberDeclarations(Request request) {
    // name
    RequestDatum nameDatum = request.getRequiredParameter(FILE);
    String name = nameDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response findMemberReferences(Request request) {
    // name
    RequestDatum nameDatum = request.getRequiredParameter(FILE);
    String name = nameDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }

  Response findTopLevelDeclarations(Request request) {
    // pattern
    RequestDatum patternDatum = request.getRequiredParameter(FILE);
    String pattern = patternDatum.asString();
    // TODO(brianwilkerson) implement
    return null;
  }
}
