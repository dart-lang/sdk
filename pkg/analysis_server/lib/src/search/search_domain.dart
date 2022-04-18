// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/search_find_element_references.dart';
import 'package:analysis_server/src/handler/legacy/search_find_member_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_find_member_references.dart';
import 'package:analysis_server/src/handler/legacy/search_find_top_level_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_get_element_declarations.dart';
import 'package:analysis_server/src/handler/legacy/search_get_type_hierarchy.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// Instances of the class [SearchDomainHandler] implement a [RequestHandler]
/// that handles requests in the search domain.
class SearchDomainHandler implements protocol.RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  SearchDomainHandler(this.server);

  @override
  protocol.Response? handleRequest(
      protocol.Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == SEARCH_REQUEST_FIND_ELEMENT_REFERENCES) {
        SearchFindElementReferencesHandler(server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_MEMBER_DECLARATIONS) {
        SearchFindMemberDeclarationsHandler(server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_MEMBER_REFERENCES) {
        SearchFindMemberReferencesHandler(server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_TOP_LEVEL_DECLARATIONS) {
        SearchFindTopLevelDeclarationsHandler(
                server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_GET_ELEMENT_DECLARATIONS) {
        SearchGetElementDeclarationsHandler(server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_GET_TYPE_HIERARCHY) {
        SearchGetTypeHierarchyHandler(server, request, cancellationToken)
            .handle();
        return protocol.Response.DELAYED_RESPONSE;
      }
    } on protocol.RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  static protocol.SearchResult toResult(SearchMatch match) {
    return protocol.newSearchResult_fromMatch(match);
  }
}
