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
   * Given a resolved compilation unit, compute suggestions based upon the
   * imports and other dart files (e.g. "part" files) in the library containing
   * the given compilation unit. The returned future completes when the cache
   * is populated.
   *
   * If [shouldWaitForLowPrioritySuggestions] is `true` then the returned
   * future will complete when the cache is fully populated. If `false`,
   * the returned future will complete sooner, but the cache will not include
   * the lower priority suggestions added as a result of a global search.
   * In this case, those lower priority suggestions will be added later
   * when the index has been updated and the global search completes.
   */
  Future<bool> computeImportInfo(CompilationUnit unit,
      SearchEngine searchEngine, bool shouldWaitForLowPrioritySuggestions) {
    importedTypeSuggestions = <CompletionSuggestion>[];
    libraryPrefixSuggestions = <CompletionSuggestion>[];
    otherImportedSuggestions = <CompletionSuggestion>[];
    importedVoidReturnSuggestions = <CompletionSuggestion>[];
    importedClassMap = new Map<String, ClassElement>();
    _importedCompletions = new HashSet<String>();

    // Assert that the compilation unit is resolved
    // and represents the expected source
    assert(unit.element.source == source);

    // Exclude elements from local library
    // because they are provided by LocalComputer
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(unit.element.enclosingElement);

    // Determine the compilation unit defining the library containing
    // this compilation unit
    List<Source> libraries = context.getLibrariesContaining(source);
    Source libSource = null;
    Future<CompilationUnit> futureLibUnit;
    if (libraries != null && libraries.length > 0) {
      libSource = libraries[0];
      if (libSource == source) {
        // If the sources are the same then we already have the library unit
        futureLibUnit = new Future.value(unit);
      } else {
        // If the sources are different, then get the library unit
        // to traverse the library directives and cache the imported elements
        futureLibUnit =
            context.computeResolvedCompilationUnitAsync(libSource, libSource);
      }
    } else {
      futureLibUnit = new Future.value(null);
    }

    // Include explicitly imported elements
    Future futureImportsCached = futureLibUnit.then((CompilationUnit libUnit) {
      if (libUnit != null) {
        libUnit.directives.forEach((Directive directive) {
          if (directive is ImportDirective) {
            ImportElement importElem = directive.element;
            if (importElem != null && importElem.importedLibrary != null) {
              if (directive.prefix == null) {
                Namespace importNamespace =
                    new NamespaceBuilder().createImportNamespaceForDirective(importElem);
                // Include top level elements
                importNamespace.definedNames.forEach(
                    (String name, Element elem) {
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
          } else if (directive is PartDirective) {
            CompilationUnitElement partElem = directive.element;
            if (partElem != null && partElem.source != source) {
              partElem.accept(new _NonLocalElementCacheVisitor(this));
            }
          }
        });
        if (libSource != source) {
          libUnit.element.accept(new _NonLocalElementCacheVisitor(this));
        }
      }
      // Don't wait for search of lower relevance results to complete.
      // Set key indicating results are ready, and lower relevance results
      // will be added to the cache when the search completes.
      _importKey = _computeImportKey(unit);
      return true;
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

    // Add non-imported elements as low relevance
    // after the imported element suggestions have been added
    Future<bool> futureAllCached = futureImportsCached.then((_) {
      return searchEngine.searchTopLevelDeclarations(
          '').then((List<SearchMatch> matches) {
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
    });

    return shouldWaitForLowPrioritySuggestions ?
        futureAllCached :
        futureImportsCached;
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
      sb.write(directive.toSource());
    });
    return sb.toString();
  }
}

/**
 * A visitor for building suggestions based upon the elements defined by
 * a source file contained in the same library but not the same as
 * the source in which the completions are being requested.
 */
class _NonLocalElementCacheVisitor extends GeneralizingElementVisitor {
  final DartCompletionCache cache;

  _NonLocalElementCacheVisitor(this.cache);

  @override
  void visitClassElement(ClassElement element) {
    cache.addSuggestion(element, CompletionRelevance.DEFAULT);
  }

  @override
  void visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  @override
  void visitElement(Element element) {
    // ignored
  }

  @override
  void visitFunctionElement(FunctionElement element) {
    cache.addSuggestion(element, CompletionRelevance.DEFAULT);
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    cache.addSuggestion(element, CompletionRelevance.DEFAULT);
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    cache.addSuggestion(element, CompletionRelevance.DEFAULT);
  }
}
