// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.dart.cache;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
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
   * Suggestions for constructors
   * or `null` if nothing has been cached.
   */
  List<CompletionSuggestion> importedConstructorSuggestions;

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
   * Return the [ClassElement] for Object.
   */
  ClassElement get objectClassElement {
    if (_objectClassElement == null) {
      Source coreUri = context.sourceFactory.forUri('dart:core');
      LibraryElement coreLib = context.getLibraryElement(coreUri);
      _objectClassElement = coreLib.getType('Object');
    }
    return _objectClassElement;
  }

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
    importedConstructorSuggestions = <CompletionSuggestion>[];
    importedVoidReturnSuggestions = <CompletionSuggestion>[];
    importedClassMap = new Map<String, ClassElement>();
    _importedCompletions = new HashSet<String>();

    // Assert that the compilation unit is resolved
    // and represents the expected source
    assert(unit.element.source == source);

    // Exclude elements from local library
    // because they are provided by LocalReferenceContributor
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(unit.element.enclosingElement);

    // Determine the compilation unit defining the library containing
    // this compilation unit
    List<Source> libraries = context.getLibrariesContaining(source);
    assert(libraries != null);
    Source libSource = libraries.length > 0 ? libraries[0] : null;
    Future<CompilationUnit> futureLibUnit = _computeLibUnit(libSource, unit);

    // Include implicitly imported dart:core elements
    _addDartCoreSuggestions();

    // Include explicitly imported and part elements
    Future futureImportsCached = futureLibUnit.then((CompilationUnit libUnit) {
      _addImportedElemSuggestions(libSource, libUnit, excludedLibs);
      // Don't wait for search of lower relevance results to complete.
      // Set key indicating results are ready, and lower relevance results
      // will be added to the cache when the search completes.
      _importKey = _computeImportKey(unit);
      return true;
    });

    // Add non-imported elements as low relevance
    // after the imported element suggestions have been added
    Future<bool> futureAllCached = futureImportsCached.then((_) {
      return searchEngine
          .searchTopLevelDeclarations('')
          .then((List<SearchMatch> matches) {
        _addNonImportedElementSuggestions(matches, excludedLibs);
        return true;
      });
    });

    return shouldWaitForLowPrioritySuggestions
        ? futureAllCached
        : futureImportsCached;
  }

  /**
   * Return `true` if the import information is cached for the given
   * compilation unit.
   */
  bool isImportInfoCached(CompilationUnit unit) =>
      _importKey != null && _importKey == _computeImportKey(unit);

  /**
   * Add constructor suggestions for the given class.
   */
  void _addConstructorSuggestions(ClassElement classElem, int relevance) {
    String className = classElem.name;
    for (ConstructorElement constructor in classElem.constructors) {
      if (!constructor.isPrivate) {
        CompletionSuggestion suggestion =
            createSuggestion(constructor, relevance: relevance);
        String name = suggestion.completion;
        name = name.length > 0 ? '$className.$name' : className;
        suggestion.completion = name;
        suggestion.selectionOffset = suggestion.completion.length;
        importedConstructorSuggestions.add(suggestion);
      }
    }
  }

  /**
   * Add suggestions for implicitly imported elements in dart:core.
   */
  void _addDartCoreSuggestions() {
    Source coreUri = context.sourceFactory.forUri('dart:core');
    LibraryElement coreLib = context.getLibraryElement(coreUri);
    if (coreLib == null) {
      // If the core library has not been analyzed yet, then we cannot add any
      // suggestions from it.
      return;
    }
    Namespace coreNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(coreLib);
    coreNamespace.definedNames.forEach((String name, Element elem) {
      if (elem is ClassElement) {
        importedClassMap[name] = elem;
      }
      _addSuggestion(elem, DART_RELEVANCE_DEFAULT);
    });
  }

  /**
   * Add suggestions for explicitly imported and part elements in the given
   * library. Add libraries that should not have their elements suggested
   * even as low priority to [excludedLibs].
   */
  void _addImportedElemSuggestions(Source libSource, CompilationUnit libUnit,
      Set<LibraryElement> excludedLibs) {
    if (libUnit != null) {
      libUnit.directives.forEach((Directive directive) {
        if (directive is ImportDirective) {
          ImportElement importElem = directive.element;
          if (importElem != null && importElem.importedLibrary != null) {
            if (directive.prefix == null) {
              Namespace importNamespace = new NamespaceBuilder()
                  .createImportNamespaceForDirective(importElem);
              // Include top level elements
              importNamespace.definedNames.forEach((String name, Element elem) {
                if (elem is ClassElement) {
                  importedClassMap[name] = elem;
                }
                _addSuggestion(elem, DART_RELEVANCE_DEFAULT);
              });
            } else {
              // Exclude elements from prefixed imports
              // because they are provided by PrefixedElementContributor
              _addLibraryPrefixSuggestion(importElem);
              excludedLibs.add(importElem.importedLibrary);
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
  }

  void _addLibraryPrefixSuggestion(ImportElement importElem) {
    CompletionSuggestion suggestion = null;
    String completion = importElem.prefix.displayName;
    if (completion != null && completion.length > 0) {
      suggestion = new CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
          DART_RELEVANCE_DEFAULT, completion, completion.length, 0,
          importElem.isDeprecated, false);
      LibraryElement lib = importElem.importedLibrary;
      if (lib != null) {
        suggestion.element = newElement_fromEngine(lib);
      }
      libraryPrefixSuggestions.add(suggestion);
      _importedCompletions.add(suggestion.completion);
    }
  }

  /**
   * Add suggestions for all top level elements in the context
   * excluding those elemnents for which suggestions have already been added.
   */
  void _addNonImportedElementSuggestions(
      List<SearchMatch> matches, Set<LibraryElement> excludedLibs) {

    // Exclude internal Dart SDK libraries
    for (var lib in context.sourceFactory.dartSdk.sdkLibraries) {
      if (lib.isInternal) {
        Source libUri = context.sourceFactory.forUri(lib.shortName);
        if (libUri != null) {
          LibraryElement libElem = context.getLibraryElement(libUri);
          if (libElem != null) {
            excludedLibs.add(libElem);
          }
        }
      }
    }

    AnalysisContext sdkContext = context.sourceFactory.dartSdk.context;
    matches.forEach((SearchMatch match) {
      if (match.kind == MatchKind.DECLARATION) {
        Element element = match.element;
        if ((element.context == context || element.context == sdkContext) &&
            element.isPublic &&
            !excludedLibs.contains(element.library) &&
            !_importedCompletions.contains(element.displayName)) {
          _addSuggestion(element, DART_RELEVANCE_LOW);
        }
      }
    });
  }

  /**
   * Add a suggestion for the given element.
   */
  void _addSuggestion(Element element, int relevance) {
    if (element is ExecutableElement) {
      if (element.isOperator) {
        return;
      }
    }

    CompletionSuggestion suggestion =
        createSuggestion(element, relevance: relevance);

    if (element is ExecutableElement) {
      DartType returnType = element.returnType;
      if (returnType != null && returnType.isVoid) {
        importedVoidReturnSuggestions.add(suggestion);
      } else {
        otherImportedSuggestions.add(suggestion);
      }
    } else if (element is FunctionTypeAliasElement) {
      importedTypeSuggestions.add(suggestion);
    } else if (element is ClassElement) {
      importedTypeSuggestions.add(suggestion);
      _addConstructorSuggestions(element, relevance);
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

  /**
   * Compute the library unit for the given library source,
   * where the [unit] is the resolved compilation unit associated with [source].
   */
  Future<CompilationUnit> _computeLibUnit(
      Source libSource, CompilationUnit unit) {
    // If the sources are the same then we already have the library unit
    if (libSource == source) {
      return new Future.value(unit);
    }
    // If [source] is a part, then compute the library unit
    if (libSource != null) {
      return context.computeResolvedCompilationUnitAsync(libSource, libSource);
    }
    return new Future.value(null);
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
    cache._addSuggestion(element, DART_RELEVANCE_DEFAULT);
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
    cache._addSuggestion(element, DART_RELEVANCE_DEFAULT);
  }

  @override
  void visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    cache._addSuggestion(element, DART_RELEVANCE_DEFAULT);
  }

  @override
  void visitTopLevelVariableElement(TopLevelVariableElement element) {
    cache._addSuggestion(element, DART_RELEVANCE_DEFAULT);
  }
}
