// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element,
    ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {
    // TODO: implement computeFast
    // - compute results based upon current search, then replace those results
    // during the full compute phase
    // - filter results based upon completion offset
    return false;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return request.node.accept(new _ImportedVisitor(request));
  }
}

/**
 * A visitor for determining which imported class and top level variable
 * should be suggested and building those suggestions.
 */
class _ImportedVisitor extends GeneralizingAstVisitor<Future<bool>> {
  final DartCompletionRequest request;

  _ImportedVisitor(this.request);

  @override
  Future<bool> visitBlock(Block node) {
    return _addImportedElementSuggestions();
  }

  @override
  Future<bool> visitNode(AstNode node) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitSimpleIdentifier(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is Combinator) {
      return _addCombinatorSuggestions(parent);
    }
    if (parent is ExpressionStatement) {
      return _addImportedElementSuggestions();
    }
    return new Future.value(false);
  }

  Future _addCombinatorSuggestions(Combinator node) {
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      LibraryElement library = directive.uriElement;
      LibraryElementSuggestionBuilder.suggestionsFor(request, library);
      return new Future.value(true);
    }

    return new Future.value(false);
  }

  Future<bool> _addImportedElementSuggestions() {

    // Exclude elements from local library
    // because they are provided by LocalComputer
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(request.unit.element.enclosingElement);

    // Include explicitly imported elements
    request.unit.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        ImportElement importElem = directive.element;
        if (importElem != null && importElem.importedLibrary != null) {
          if (directive.prefix == null) {
            Namespace importNamespace =
                new NamespaceBuilder().createImportNamespaceForDirective(importElem);
            importNamespace.definedNames.forEach((_, Element element) {
              _addElementSuggestion(element, CompletionRelevance.DEFAULT);
            });
          } else {
            // Exclude elements from prefixed imports
            // because they are provided by InvocationComputer
            excludedLibs.add(importElem.importedLibrary);
            _addLibraryPrefixSuggestion(importElem);
          }
        }
      }
    });

    // Include implicitly imported dart:core elements
    Source coreUri = request.context.sourceFactory.forUri('dart:core');
    LibraryElement coreLib = request.context.getLibraryElement(coreUri);
    Namespace coreNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(coreLib);
    coreNamespace.definedNames.forEach((_, Element element) {
      _addElementSuggestion(element, CompletionRelevance.DEFAULT);
    });

    // Add non-imported elements as low relevance
    var future = request.searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      Set<String> completionSet = new Set<String>();
      request.suggestions.forEach((CompletionSuggestion suggestion) {
        completionSet.add(suggestion.completion);
      });
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic &&
              !excludedLibs.contains(element.library) &&
              !completionSet.contains(element.displayName)) {
            _addElementSuggestion(element, CompletionRelevance.LOW);
          }
        }
      });
      return true;
    });
  }

  void _addElementSuggestion(Element element, CompletionRelevance relevance) {
    CompletionSuggestionKind kind =
        new CompletionSuggestionKind.fromElementKind(element.kind);

    String completion = element.displayName;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        kind,
        relevance,
        completion,
        completion.length,
        0,
        element.isDeprecated,
        false);

    suggestion.element = new protocol.Element.fromEngine(element);

    DartType type;
    if (element is FunctionElement) {
      type = element.returnType;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      type = element.returnType;
    } else if (element is TopLevelVariableElement) {
      type = element.type;
    }
    if (type != null) {
      String name = type.displayName;
      if (name != null && name.length > 0 && name != 'dynamic') {
        suggestion.returnType = name;
      }
    }

    request.suggestions.add(suggestion);
  }

  void _addLibraryPrefixSuggestion(ImportElement importElem) {
    String completion = importElem.prefix.displayName;
    if (completion != null && completion.length > 0) {
      CompletionSuggestion suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.LIBRARY_PREFIX,
          CompletionRelevance.DEFAULT,
          completion,
          completion.length,
          0,
          importElem.isDeprecated,
          false);
      LibraryElement lib = importElem.importedLibrary;
      if (lib != null) {
        suggestion.element = new protocol.Element.fromEngine(lib);
      }
      request.suggestions.add(suggestion);
    }
  }
}
