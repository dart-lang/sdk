// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.domain;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

/**
 * Instances of the class [SearchDomainHandler] implement a [RequestHandler]
 * that handles requests in the search domain.
 */
class SearchDomainHandler implements protocol.RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * The [Index] for this server.
   */
  final Index index;

  /**
   * The [SearchEngine] for this server.
   */
  final SearchEngine searchEngine;

  /**
   * The next search response id.
   */
  int _nextSearchId = 0;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  SearchDomainHandler(AnalysisServer server)
      : server = server,
        index = server.index,
        searchEngine = server.searchEngine;

  Future findElementReferences(protocol.Request request) async {
    var params =
        new protocol.SearchFindElementReferencesParams.fromRequest(request);
    await server.onAnalysisComplete;
    // prepare elements
    List<Element> elements =
        server.getElementsAtOffset(params.file, params.offset);
    elements = elements.map((Element element) {
      if (element is ImportElement) {
        return element.prefix;
      }
      if (element is FieldFormalParameterElement) {
        return element.field;
      }
      if (element is PropertyAccessorElement) {
        return element.variable;
      }
      return element;
    }).where((Element element) {
      return element != null;
    }).toList();
    // respond
    String searchId = (_nextSearchId++).toString();
    var result = new protocol.SearchFindElementReferencesResult();
    if (elements.isNotEmpty) {
      result.id = searchId;
      result.element = protocol.convertElement(elements.first);
    }
    _sendSearchResult(request, result);
    // search elements
    elements.forEach((Element element) async {
      var computer = new ElementReferencesComputer(searchEngine);
      List<protocol.SearchResult> results =
          await computer.compute(element, params.includePotential);
      bool isLast = identical(element, elements.last);
      _sendSearchNotification(searchId, isLast, results);
    });
  }

  Future findMemberDeclarations(protocol.Request request) async {
    var params =
        new protocol.SearchFindMemberDeclarationsParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    String searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, new protocol.SearchFindMemberDeclarationsResult(searchId));
    // search
    List<SearchMatch> matches =
        await searchEngine.searchMemberDeclarations(params.name);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  Future findMemberReferences(protocol.Request request) async {
    var params =
        new protocol.SearchFindMemberReferencesParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    String searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, new protocol.SearchFindMemberReferencesResult(searchId));
    // search
    List<SearchMatch> matches =
        await searchEngine.searchMemberReferences(params.name);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  Future findTopLevelDeclarations(protocol.Request request) async {
    var params =
        new protocol.SearchFindTopLevelDeclarationsParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    String searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, new protocol.SearchFindTopLevelDeclarationsResult(searchId));
    // search
    List<SearchMatch> matches =
        await searchEngine.searchTopLevelDeclarations(params.pattern);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  /**
   * Implement the `search.getTypeHierarchy` request.
   */
  Future getTypeHierarchy(protocol.Request request) async {
    var params = new protocol.SearchGetTypeHierarchyParams.fromRequest(request);
    String file = params.file;
    // wait for analysis
    if (params.superOnly == true) {
      await server.onFileAnalysisComplete(file);
    } else {
      await server.onAnalysisComplete;
    }
    // prepare element
    List<Element> elements = server.getElementsAtOffset(file, params.offset);
    if (elements.isEmpty) {
      _sendTypeHierarchyNull(request);
      return;
    }
    Element element = elements.first;
    // maybe supertype hierarchy only
    if (params.superOnly == true) {
      TypeHierarchyComputer computer =
          new TypeHierarchyComputer(searchEngine, element);
      List<protocol.TypeHierarchyItem> items = computer.computeSuper();
      protocol.Response response =
          new protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
              .toResponse(request.id);
      server.sendResponse(response);
      return;
    }
    // prepare type hierarchy
    TypeHierarchyComputer computer =
        new TypeHierarchyComputer(searchEngine, element);
    List<protocol.TypeHierarchyItem> items = await computer.compute();
    protocol.Response response =
        new protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
            .toResponse(request.id);
    server.sendResponse(response);
  }

  @override
  protocol.Response handleRequest(protocol.Request request) {
    if (searchEngine == null) {
      return new protocol.Response.noIndexGenerated(request);
    }
    try {
      String requestName = request.method;
      if (requestName == SEARCH_FIND_ELEMENT_REFERENCES) {
        findElementReferences(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_FIND_MEMBER_DECLARATIONS) {
        findMemberDeclarations(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_FIND_MEMBER_REFERENCES) {
        findMemberReferences(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_FIND_TOP_LEVEL_DECLARATIONS) {
        findTopLevelDeclarations(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_GET_TYPE_HIERARCHY) {
        getTypeHierarchy(request);
        return protocol.Response.DELAYED_RESPONSE;
      }
    } on protocol.RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  void _sendSearchNotification(
      String searchId, bool isLast, Iterable<protocol.SearchResult> results) {
    server.sendNotification(
        new protocol.SearchResultsParams(searchId, results.toList(), isLast)
            .toNotification());
  }

  /**
   * Send a search response with the given [result] to the given [request].
   */
  void _sendSearchResult(protocol.Request request, result) {
    protocol.Response response = result.toResponse(request.id);
    server.sendResponse(response);
  }

  void _sendTypeHierarchyNull(protocol.Request request) {
    protocol.Response response =
        new protocol.SearchGetTypeHierarchyResult().toResponse(request.id);
    server.sendResponse(response);
  }

  static protocol.SearchResult toResult(SearchMatch match) {
    return protocol.newSearchResult_fromMatch(match);
  }
}
