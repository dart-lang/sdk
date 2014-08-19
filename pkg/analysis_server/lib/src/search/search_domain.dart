// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.domain;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/computer/element.dart' as se;
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/search/search_result.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analysis_server/src/services/json.dart';
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
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    bool includePotential =
        request.getRequiredParameter(INCLUDE_POTENTIAL).asBool();
    // prepare elements
    List<Element> elements = server.getElementsAtOffset(file, offset);
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
      var future = computer.compute(element, includePotential);
      future.then((List<SearchResult> results) {
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
    Response response = new Response(request.id);
    response.setResult(ID, searchId);
    if (elements.isNotEmpty) {
      var serverElement = new se.Element.fromEngine(elements[0]);
      response.setResult(ELEMENT, objectToJson(serverElement));
    }
    return response;
  }

  Response findMemberDeclarations(Request request) {
    String name = request.getRequiredParameter(NAME).asString();
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchMemberDeclarations(name);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new Response(request.id)..setResult(ID, searchId);
  }

  Response findMemberReferences(Request request) {
    String name = request.getRequiredParameter(NAME).asString();
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchMemberReferences(name);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new Response(request.id)..setResult(ID, searchId);
  }

  Response findTopLevelDeclarations(Request request) {
    String pattern = request.getRequiredParameter(PATTERN).asString();
    // schedule search
    String searchId = (_nextSearchId++).toString();
    {
      var matchesFuture = searchEngine.searchTopLevelDeclarations(pattern);
      matchesFuture.then((List<SearchMatch> matches) {
        _sendSearchNotification(searchId, true, matches.map(toResult));
      });
    }
    // respond
    return new Response(request.id)..setResult(ID, searchId);
  }

  /**
   * Implement the `search.getTypeHierarchy` request.
   */
  Response getTypeHierarchy(Request request) {
    // prepare parameters
    String file = request.getRequiredParameter(FILE).asString();
    int offset = request.getRequiredParameter(OFFSET).asInt();
    // prepare Element
    List<Element> elements = server.getElementsAtOffset(file, offset);
    Response response = new Response(request.id);
    if (elements.isEmpty) {
      response.setEmptyResult();
      return response;
    }
    Element element = elements.first;
    // prepare type hierarchy
    TypeHierarchyComputer computer = new TypeHierarchyComputer(searchEngine);
    computer.compute(element).then((List<TypeHierarchyItem> items) {
      if (items != null) {
        response.setResult(HIERARCHY_ITEMS, objectToJson(items));
      } else {
        response.setEmptyResult();
      }
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
      Iterable<SearchResult> results) {
    Notification notification = new Notification(SEARCH_RESULTS);
    notification.setParameter(ID, searchId);
    notification.setParameter(LAST, isLast);
    notification.setParameter(RESULTS, objectToJson(results));
    server.sendNotification(notification);
  }

  static SearchResult toResult(SearchMatch match) {
    return new SearchResult.fromMatch(match);
  }
}
