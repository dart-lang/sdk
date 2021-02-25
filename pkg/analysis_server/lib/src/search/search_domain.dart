// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analysis_server/src/search/workspace_symbols.dart' as search;
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';

/// Instances of the class [SearchDomainHandler] implement a [RequestHandler]
/// that handles requests in the search domain.
class SearchDomainHandler implements protocol.RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// The [SearchEngine] for this server.
  final SearchEngine searchEngine;

  /// The next search response id.
  int _nextSearchId = 0;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  SearchDomainHandler(this.server) : searchEngine = server.searchEngine;

  Future findElementReferences(protocol.Request request) async {
    var params =
        protocol.SearchFindElementReferencesParams.fromRequest(request);
    var file = params.file;
    // prepare element
    var element = await server.getElementAtOffset(file, params.offset);
    if (element is ImportElement) {
      element = (element as ImportElement).prefix;
    }
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element is PropertyAccessorElement) {
      element = (element as PropertyAccessorElement).variable;
    }
    // respond
    var searchId = (_nextSearchId++).toString();
    var result = protocol.SearchFindElementReferencesResult();
    if (element != null) {
      result.id = searchId;
      result.element = protocol.convertElement(element);
    }
    _sendSearchResult(request, result);
    // search elements
    if (element != null) {
      var computer = ElementReferencesComputer(searchEngine);
      var results = await computer.compute(element, params.includePotential);
      _sendSearchNotification(searchId, true, results);
    }
  }

  Future findMemberDeclarations(protocol.Request request) async {
    var params =
        protocol.SearchFindMemberDeclarationsParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    var searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, protocol.SearchFindMemberDeclarationsResult(searchId));
    // search
    var matches = await searchEngine.searchMemberDeclarations(params.name);
    matches = SearchMatch.withNotNullElement(matches);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  Future findMemberReferences(protocol.Request request) async {
    var params = protocol.SearchFindMemberReferencesParams.fromRequest(request);
    await server.onAnalysisComplete;
    // respond
    var searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, protocol.SearchFindMemberReferencesResult(searchId));
    // search
    var matches = await searchEngine.searchMemberReferences(params.name);
    matches = SearchMatch.withNotNullElement(matches);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  Future findTopLevelDeclarations(protocol.Request request) async {
    var params =
        protocol.SearchFindTopLevelDeclarationsParams.fromRequest(request);
    try {
      // validate the regex
      RegExp(params.pattern);
    } on FormatException catch (exception) {
      server.sendResponse(protocol.Response.invalidParameter(
          request, 'pattern', exception.message));
      return;
    }

    await server.onAnalysisComplete;
    // respond
    var searchId = (_nextSearchId++).toString();
    _sendSearchResult(
        request, protocol.SearchFindTopLevelDeclarationsResult(searchId));
    // search
    var matches = await searchEngine.searchTopLevelDeclarations(params.pattern);
    matches = SearchMatch.withNotNullElement(matches);
    _sendSearchNotification(searchId, true, matches.map(toResult));
  }

  /// Implement the `search.getDeclarations` request.
  Future getDeclarations(protocol.Request request) async {
    var params =
        protocol.SearchGetElementDeclarationsParams.fromRequest(request);

    RegExp regExp;
    if (params.pattern != null) {
      try {
        regExp = RegExp(params.pattern);
      } on FormatException catch (exception) {
        server.sendResponse(protocol.Response.invalidParameter(
            request, 'pattern', exception.message));
        return;
      }
    }

    protocol.ElementKind getElementKind(search.DeclarationKind kind) {
      switch (kind) {
        case search.DeclarationKind.CLASS:
          return protocol.ElementKind.CLASS;
        case search.DeclarationKind.CLASS_TYPE_ALIAS:
          return protocol.ElementKind.CLASS_TYPE_ALIAS;
        case search.DeclarationKind.CONSTRUCTOR:
          return protocol.ElementKind.CONSTRUCTOR;
        case search.DeclarationKind.ENUM:
          return protocol.ElementKind.ENUM;
        case search.DeclarationKind.ENUM_CONSTANT:
          return protocol.ElementKind.ENUM_CONSTANT;
        case search.DeclarationKind.FIELD:
          return protocol.ElementKind.FIELD;
        case search.DeclarationKind.FUNCTION:
          return protocol.ElementKind.FUNCTION;
        case search.DeclarationKind.FUNCTION_TYPE_ALIAS:
          return protocol.ElementKind.FUNCTION_TYPE_ALIAS;
        case search.DeclarationKind.GETTER:
          return protocol.ElementKind.GETTER;
        case search.DeclarationKind.METHOD:
          return protocol.ElementKind.METHOD;
        case search.DeclarationKind.MIXIN:
          return protocol.ElementKind.MIXIN;
        case search.DeclarationKind.SETTER:
          return protocol.ElementKind.SETTER;
        case search.DeclarationKind.VARIABLE:
          return protocol.ElementKind.TOP_LEVEL_VARIABLE;
        default:
          return protocol.ElementKind.CLASS;
      }
    }

    var tracker = server.declarationsTracker;
    var files = <String>{};
    var remainingMaxResults = params.maxResults;
    var declarations = search.WorkspaceSymbols(tracker).declarations(
      regExp,
      remainingMaxResults,
      files,
      onlyForFile: params.file,
    );

    var elementDeclarations = declarations.map((declaration) {
      return protocol.ElementDeclaration(
          declaration.name,
          getElementKind(declaration.kind),
          declaration.fileIndex,
          declaration.offset,
          declaration.line,
          declaration.column,
          declaration.codeOffset,
          declaration.codeLength,
          className: declaration.className,
          mixinName: declaration.mixinName,
          parameters: declaration.parameters);
    }).toList();

    server.sendResponse(protocol.SearchGetElementDeclarationsResult(
            elementDeclarations, files.toList())
        .toResponse(request.id));
  }

  /// Implement the `search.getTypeHierarchy` request.
  Future getTypeHierarchy(protocol.Request request) async {
    var params = protocol.SearchGetTypeHierarchyParams.fromRequest(request);
    var file = params.file;
    // prepare element
    var element = await server.getElementAtOffset(file, params.offset);
    if (element == null) {
      _sendTypeHierarchyNull(request);
      return;
    }
    // maybe supertype hierarchy only
    if (params.superOnly == true) {
      var computer = TypeHierarchyComputer(searchEngine, element);
      var items = computer.computeSuper();
      var response =
          protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
              .toResponse(request.id);
      server.sendResponse(response);
      return;
    }
    // prepare type hierarchy
    var computer = TypeHierarchyComputer(searchEngine, element);
    var items = await computer.compute();
    var response = protocol.SearchGetTypeHierarchyResult(hierarchyItems: items)
        .toResponse(request.id);
    server.sendResponse(response);
  }

  @override
  protocol.Response handleRequest(protocol.Request request) {
    try {
      var requestName = request.method;
      if (requestName == SEARCH_REQUEST_FIND_ELEMENT_REFERENCES) {
        findElementReferences(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_MEMBER_DECLARATIONS) {
        findMemberDeclarations(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_MEMBER_REFERENCES) {
        findMemberReferences(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_FIND_TOP_LEVEL_DECLARATIONS) {
        findTopLevelDeclarations(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_GET_ELEMENT_DECLARATIONS) {
        getDeclarations(request);
        return protocol.Response.DELAYED_RESPONSE;
      } else if (requestName == SEARCH_REQUEST_GET_TYPE_HIERARCHY) {
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
        protocol.SearchResultsParams(searchId, results.toList(), isLast)
            .toNotification());
  }

  /// Send a search response with the given [result] to the given [request].
  void _sendSearchResult(protocol.Request request, result) {
    protocol.Response response = result.toResponse(request.id);
    server.sendResponse(response);
  }

  void _sendTypeHierarchyNull(protocol.Request request) {
    var response =
        protocol.SearchGetTypeHierarchyResult().toResponse(request.id);
    server.sendResponse(response);
  }

  static protocol.SearchResult toResult(SearchMatch match) {
    return protocol.newSearchResult_fromMatch(match);
  }
}
