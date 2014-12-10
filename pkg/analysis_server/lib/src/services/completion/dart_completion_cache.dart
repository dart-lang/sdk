// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.cache;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The `DartCompletionCache` contains cached information from a prior code
 * completion operation.
 */
class DartCompletionCache extends CompletionCache {

  /**
   * A hash of the import directives
   * or `null` if nothing has been cached.
   */
  String _importKey;

  /**
   * Library prefix suggestions based upon imports,
   * or `null` if nothing has been cached.
   */
  List<CompletionSuggestion> libraryPrefixSuggestions;

  /**
   * Type suggestions based upon imports,
   * or `null` if nothing has been cached.
   */
  List<CompletionSuggestion> importedTypeSuggestions;

  /**
   * Suggestions for methods and functions that have void return type,
   * or `null` if nothing has been cached.
   */
  List<CompletionSuggestion> importedVoidReturnSuggestions;

  /**
   * Other suggestions based upon imports,
   * or `null` if nothing has been cached.
   */
  List<CompletionSuggestion> otherImportedSuggestions;

  /**
   * A collection of all imported completions
   * or `null` if nothing has been cached.
   */
  HashSet<String> _importedCompletions;

  /**
   * A map of simple identifier to imported class element
   * or `null` if nothing has been cached.
   */
  Map<String, ClassElement> importedClassMap;

  /**
   * The [ClassElement] for Object.
   */
  ClassElement _objectClassElement;

  DartCompletionCache(AnalysisContext context, Source source)
      : super(context, source);

  /**
   * Return a hash of the import directives for the cached import info
   * or `null` if nothing has been cached.
   */
  String get importKey => _importKey;

  /**
   * Compute suggestions based upon the imports in the given compilation unit.
   * On return, the cache will be populated except for lower priority
   * suggestions added as a result of a global search. Callers may wait
   * on the returned future if they want to ensure those lower priority
   * suggestions are part of the cached suggestions.
   */
  Future<bool> computeImportInfo(CompilationUnit unit,
      SearchEngine searchEngine) {
    importedTypeSuggestions = <CompletionSuggestion>[];
    libraryPrefixSuggestions = <CompletionSuggestion>[];
    otherImportedSuggestions = <CompletionSuggestion>[];
    importedVoidReturnSuggestions = <CompletionSuggestion>[];
    importedClassMap = new Map<String, ClassElement>();
    _importedCompletions = new HashSet<String>();

    // Exclude elements from local library
    // because they are provided by LocalComputer
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(unit.element.enclosingElement);

    // Include explicitly imported elements
    unit.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        ImportElement importElem = directive.element;
        if (importElem != null && importElem.importedLibrary != null) {
          if (directive.prefix == null) {
            Namespace importNamespace =
                new NamespaceBuilder().createImportNamespaceForDirective(importElem);
            // Include top level elements
            importNamespace.definedNames.forEach((String name, Element elem) {
              if (elem is ClassElement) {
                importedClassMap[name] = elem;
              }
              addSuggestion(elem, CompletionRelevance.DEFAULT);
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
    Source coreUri = context.sourceFactory.forUri('dart:core');
    LibraryElement coreLib = context.getLibraryElement(coreUri);
    Namespace coreNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(coreLib);
    coreNamespace.definedNames.forEach((String name, Element elem) {
      if (elem is ClassElement) {
        importedClassMap[name] = elem;
      }
      addSuggestion(elem, CompletionRelevance.DEFAULT);
    });
    _objectClassElement = importedClassMap['Object'];

    /*
     * Don't wait for search of lower relevance results to complete.
     * Set key indicating results are ready, and lower relevance results
     * will be added to the cache when the search completes.
     */
    _importKey = _computeImportKey(unit);

    // Add non-imported elements as low relevance
    Future<List<SearchMatch>> future =
        searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic &&
              !excludedLibs.contains(element.library) &&
              !_importedCompletions.contains(element.displayName)) {
            addSuggestion(element, CompletionRelevance.LOW);
          }
        }
      });
      return true;
    });
  }

  /**
   * Return the [ClassElement] for Object.
   */
  ClassElement get objectClassElement {
    if (_objectClassElement == null) {
      Source coreUri = context.sourceFactory.forUri('dart:core');
      LibraryElement coreLib = context.getLibraryElement(coreUri);
      Namespace coreNamespace =
          new NamespaceBuilder().createPublicNamespaceForLibrary(coreLib);
      _objectClassElement = coreNamespace.definedNames['Object'];
    }
    return _objectClassElement;
  }

  /**
   * Return `true` if the import information is cached for the given
   * compilation unit.
   */
  bool isImportInfoCached(CompilationUnit unit) =>
      _importKey != null && _importKey == _computeImportKey(unit);

  void _addLibraryPrefixSuggestion(ImportElement importElem) {
    CompletionSuggestion suggestion = null;
    String completion = importElem.prefix.displayName;
    if (completion != null && completion.length > 0) {
      suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          CompletionRelevance.DEFAULT,
          completion,
          completion.length,
          0,
          importElem.isDeprecated,
          false);
      LibraryElement lib = importElem.importedLibrary;
      if (lib != null) {
        suggestion.element = newElement_fromEngine(lib);
      }
      libraryPrefixSuggestions.add(suggestion);
      _importedCompletions.add(suggestion.completion);
    }
  }

  void addSuggestion(Element element, CompletionRelevance relevance) {

    if (element is ExecutableElement) {
      if (element.isOperator) {
        return;
      }
    }

    CompletionSuggestion suggestion =
        createElementSuggestion(element, relevance: relevance);

    if (element is ExecutableElement) {
      DartType returnType = element.returnType;
      if (returnType != null && returnType.isVoid) {
        importedVoidReturnSuggestions.add(suggestion);
      } else {
        otherImportedSuggestions.add(suggestion);
      }
    } else if (element is ClassElement) {
      importedTypeSuggestions.add(suggestion);
    } else {
      otherImportedSuggestions.add(suggestion);
    }
    _importedCompletions.add(suggestion.completion);
  }

  /**
   * Compute the hash of the imports for the given compilation unit.
   */
  String _computeImportKey(CompilationUnit unit) {
    StringBuffer sb = new StringBuffer();
    unit.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        sb.write(directive.toSource());
      }
    });
    return sb.toString();
  }
}
