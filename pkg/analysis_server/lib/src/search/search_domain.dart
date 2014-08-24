// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.domain;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart' as protocol;
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';

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
   * The [SearchEngine] for this server.
   */
  SearchEngine searchEngine;

  /**
   * The next searc response id.
   */
  int _nextSearchId = 0;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  SearchDomainHandler(this.server) {
    searchEngine = server.searchEngine;
  }

  Response findElementReferences(Request request) {
    var params = new protocol.SearchFindElementReferencesParams.fromRequest(request);
    // prepare elements
    List<Element> elements = server.getElementsAtOffset(params.file,
        params.offset);
    elements = elements.map((Element element) {
      if (element is FieldFormalParameterElement) {
        return element.field;
      }
      if (element is PropertyAccessorElement) {
        return element.variable;
      }
      return element;
    }).toList();
    // schedule search
    String searchId = (_nextSearchId++).toString();
    elements.forEach((Element element) {
      var computer = new ElementReferencesComputer(searchEngine);
      var future = computer.compute(element, params.includePotential);
      future.then((List<protocol.SearchResult> results) {
        bool isLast = identical(element, elements.last);
        _sendSearchNotification(searchId, isLast, results);
      });
    });
    if (elements.isEmpty) {
      new Future.microtask(() {
        _sendSearchNotification(searchId, true, []);
      });
    }
    // respond
    protocol.Element element;
    if (elements.isNotEmpty) {
      element = new protocol.Element.fromEngine(elements[0]);
    }
    return new protocol.SearchFindElementReferencesResult(searchId,
        element: element).toResponse(request.id);
  }

  Response findMemberDeclarations(Request request) {
    var params = new protocol.SearchFindMemberDeclarationsParams.fromRequest(request);
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchMemberDeclarations(params.name);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new protocol.SearchFindMemberDeclarationsResult(
        searchId).toResponse(request.id);
  }

  Response findMemberReferences(Request request) {
    var params = new protocol.SearchFindMemberReferencesParams.fromRequest(request);
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchMemberReferences(params.name);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new protocol.SearchFindMemberReferencesResult(searchId).toResponse(
        request.id);
  }

  Response findTopLevelDeclarations(Request request) {
    var params = new protocol.SearchFindTopLevelDeclarationsParams.fromRequest(request);
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchTopLevelDeclarations(params.pattern);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new protocol.SearchFindTopLevelDeclarationsResult(
        searchId).toResponse(request.id);
  }

  /**
   * Implement the `search.getTypeHierarchy` request.
   */
  Response getTypeHierarchy(Request request) {
    var params = new protocol.SearchGetTypeHierarchyParams.fromRequest(request);
    // prepare parameters
    // prepare Element
    List<Element> elements = server.getElementsAtOffset(params.file,
        params.offset);
    if (elements.isEmpty) {
      Response response = new protocol.SearchGetTypeHierarchyResult().toResponse(request.id);
      return response;
    }
    Element element = elements.first;
    // prepare type hierarchy
    TypeHierarchyComputer computer = new TypeHierarchyComputer(searchEngine);
    computer.compute(element).then((List<protocol.TypeHierarchyItem> items) {
      Response response = new protocol.SearchGetTypeHierarchyResult(
          hierarchyItems: items).toResponse(request.id);
      server.sendResponse(response);
    });
    // delay response
    return Response.DELAYED_RESPONSE;
  }

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
      } else if (requestName == SEARCH_GET_TYPE_HIERARCHY) {
        return getTypeHierarchy(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  void _sendSearchNotification(String searchId, bool isLast,
      Iterable<protocol.SearchResult> results) {
    server.sendNotification(new protocol.SearchResultsParams(searchId,
        results.toList(), isLast).toNotification());
  }

  static protocol.SearchResult toResult(SearchMatch match) {
    return new protocol.SearchResult.fromMatch(match);
  }
}
