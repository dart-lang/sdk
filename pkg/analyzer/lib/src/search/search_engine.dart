// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.src.search_engine;

///**
// * Instances of the class <code>AndSearchPattern</code> implement a search pattern that matches
// * elements that match all of several other search patterns.
// */
//class AndSearchPattern implements SearchPattern {
//  /**
//   * The patterns used to determine whether this pattern matches an element.
//   */
//  final List<SearchPattern> _patterns;
//
//  /**
//   * Initialize a newly created search pattern to match elements that match all of several other
//   * search patterns.
//   *
//   * @param patterns the patterns used to determine whether this pattern matches an element
//   */
//  AndSearchPattern(this._patterns);
//
//  @override
//  MatchQuality matches(Element element) {
//    MatchQuality highestQuality = null;
//    for (SearchPattern pattern in _patterns) {
//      MatchQuality quality = pattern.matches(element);
//      if (quality == null) {
//        return null;
//      }
//      if (highestQuality == null) {
//        highestQuality = quality;
//      } else {
//        highestQuality = highestQuality.max(quality);
//      }
//    }
//    return highestQuality;
//  }
//}
//
///**
// * Instances of the class <code>CamelCaseSearchPattern</code> implement a search pattern that
// * matches elements whose name matches a partial identifier where camel case conventions are used to
// * perform what is essentially multiple prefix matches.
// */
//class CamelCaseSearchPattern implements SearchPattern {
//  /**
//   * The pattern that matching elements must match.
//   */
//  List<int> _pattern;
//
//  /**
//   * A flag indicating whether the pattern and the name being matched must have exactly the same
//   * number of parts (i.e. the same number of uppercase characters).
//   */
//  final bool _samePartCount;
//
//  /**
//   * Initialize a newly created search pattern to match elements whose names match the given
//   * camel-case pattern.
//   *
//   * @param pattern the pattern that matching elements must match
//   * @param samePartCount `true` if the pattern and the name being matched must have
//   *          exactly the same number of parts (i.e. the same number of uppercase characters)
//   */
//  CamelCaseSearchPattern(String pattern, this._samePartCount) {
//    this._pattern = pattern.toCharArray();
//  }
//
//  @override
//  MatchQuality matches(Element element) {
//    String name = element.displayName;
//    if (name == null) {
//      return null;
//    }
//    if (CharOperation.camelCaseMatch(_pattern, name.toCharArray(), _samePartCount)) {
//      return MatchQuality.EXACT;
//    }
//    return null;
//  }
//}
//
///**
// * Instances of the class `CountingSearchListener` listen for search results, passing those
// * results on to a wrapped listener, but ensure that the wrapped search listener receives only one
// * notification that the search is complete.
// */
//class CountingSearchListener implements SearchListener {
//  /**
//   * The number of times that this listener expects to be told that the search is complete before
//   * passing the information along to the wrapped listener.
//   */
//  int _completionCount = 0;
//
//  /**
//   * The listener that will be notified as results are received and when the given number of search
//   * complete notifications have been received.
//   */
//  final SearchListener _wrappedListener;
//
//  /**
//   * Initialize a newly created search listener to pass search results on to the given listener and
//   * to notify the given listener that the search is complete after getting the given number of
//   * notifications.
//   *
//   * @param completionCount the number of times that this listener expects to be told that the
//   *          search is complete
//   * @param wrappedListener the listener that will be notified as results are received
//   */
//  CountingSearchListener(int completionCount, this._wrappedListener) {
//    this._completionCount = completionCount;
//    if (completionCount == 0) {
//      _wrappedListener.searchComplete();
//    }
//  }
//
//  @override
//  void matchFound(SearchMatch match) {
//    _wrappedListener.matchFound(match);
//  }
//
//  @override
//  void searchComplete() {
//    _completionCount--;
//    if (_completionCount <= 0) {
//      _wrappedListener.searchComplete();
//    }
//  }
//}
//
///**
// * Instances of the class <code>ExactSearchPattern</code> implement a search pattern that matches
// * elements whose name matches a specified identifier exactly.
// */
//class ExactSearchPattern implements SearchPattern {
//  /**
//   * The identifier that matching elements must be equal to.
//   */
//  final String _identifier;
//
//  /**
//   * A flag indicating whether a case sensitive match is to be performed.
//   */
//  final bool _caseSensitive;
//
//  /**
//   * Initialize a newly created search pattern to match elements whose names begin with the given
//   * prefix.
//   *
//   * @param identifier the identifier that matching elements must be equal to
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   */
//  ExactSearchPattern(this._identifier, this._caseSensitive);
//
//  @override
//  MatchQuality matches(Element element) {
//    String name = element.displayName;
//    if (name == null) {
//      return null;
//    }
//    if (_caseSensitive && name == _identifier) {
//      return MatchQuality.EXACT;
//    }
//    if (!_caseSensitive && javaStringEqualsIgnoreCase(name, _identifier)) {
//      return MatchQuality.EXACT;
//    }
//    return null;
//  }
//}
//
///**
// * Instances of the class <code>FilteredSearchListener</code> implement a search listener that
// * delegates to another search listener after removing matches that do not pass a given filter.
// */
//class FilteredSearchListener extends WrappedSearchListener {
//  /**
//   * The filter used to filter the matches.
//   */
//  final SearchFilter _filter;
//
//  /**
//   * Initialize a newly created search listener to pass on any matches that pass the given filter to
//   * the given listener.
//   *
//   * @param filter the filter used to filter the matches
//   * @param listener the search listener being wrapped
//   */
//  FilteredSearchListener(this._filter, SearchListener listener) : super(listener);
//
//  @override
//  void matchFound(SearchMatch match) {
//    if (_filter.passes(match)) {
//      propagateMatch(match);
//    }
//  }
//}
//
///**
// * [SearchListener] used by [SearchEngineImpl] internally to gather asynchronous results
// * and return them synchronously.
// */
//class GatheringSearchListener implements SearchListener {
//  /**
//   * A list containing the matches that have been found so far.
//   */
//  List<SearchMatch> _matches = [];
//
//  /**
//   * A flag indicating whether the search is complete.
//   */
//  bool _isComplete = false;
//
//  /**
//   * @return the the matches that have been found.
//   */
//  List<SearchMatch> get matches {
//    _matches.sort(SearchMatch.SORT_BY_ELEMENT_NAME);
//    return _matches;
//  }
//
//  /**
//   * Return `true` if the search is complete.
//   *
//   * @return `true` if the search is complete
//   */
//  bool get isComplete => _isComplete;
//
//  @override
//  void matchFound(SearchMatch match) {
//    _matches.add(match);
//  }
//
//  @override
//  void searchComplete() {
//    _isComplete = true;
//  }
//}
//
///**
// * Instances of the class <code>LibrarySearchScope</code> implement a search scope that encompasses
// * everything in a given collection of libraries.
// */
//class LibrarySearchScope implements SearchScope {
//  /**
//   * The libraries defining which elements are included in the scope.
//   */
//  final List<LibraryElement> libraries;
//
//  /**
//   * Create a search scope that encompasses everything in the given libraries.
//   *
//   * @param libraries the libraries defining which elements are included in the scope
//   */
//  LibrarySearchScope.con1(Iterable<LibraryElement> libraries) : this.con2(new List.from(libraries));
//
//  /**
//   * Create a search scope that encompasses everything in the given libraries.
//   *
//   * @param libraries the libraries defining which elements are included in the scope
//   */
//  LibrarySearchScope.con2(this.libraries);
//
//  @override
//  bool encloses(Element element) {
//    LibraryElement elementLibrary = element.getAncestor((element) => element is LibraryElement);
//    return ArrayUtils.contains(libraries, elementLibrary);
//  }
//}
//
///**
// * Instances of the class <code>NameMatchingSearchListener</code> implement a search listener that
// * delegates to another search listener after removing matches that do not match a given pattern.
// */
//class NameMatchingSearchListener extends WrappedSearchListener {
//  /**
//   * The pattern used to filter the matches.
//   */
//  final SearchPattern _pattern;
//
//  /**
//   * Initialize a newly created search listener to pass on any matches that match the given pattern
//   * to the given listener.
//   *
//   * @param pattern the pattern used to filter the matches
//   * @param listener the search listener being wrapped
//   */
//  NameMatchingSearchListener(this._pattern, SearchListener listener) : super(listener);
//
//  @override
//  void matchFound(SearchMatch match) {
//    if (_pattern.matches(match.element) != null) {
//      propagateMatch(match);
//    }
//  }
//}
//
///**
// * Instances of the class <code>OrSearchPattern</code> implement a search pattern that matches
// * elements that match any one of several other search patterns.
// */
//class OrSearchPattern implements SearchPattern {
//  /**
//   * The patterns used to determine whether this pattern matches an element.
//   */
//  final List<SearchPattern> _patterns;
//
//  /**
//   * Initialize a newly created search pattern to match elements that match any one of several other
//   * search patterns.
//   *
//   * @param patterns the patterns used to determine whether this pattern matches an element
//   */
//  OrSearchPattern(this._patterns);
//
//  @override
//  MatchQuality matches(Element element) {
//    // Do we want to return the highest quality of match rather than stopping
//    // after the first match? Doing so would be more accurate, but slower.
//    for (SearchPattern pattern in _patterns) {
//      MatchQuality quality = pattern.matches(element);
//      if (quality != null) {
//        return quality;
//      }
//    }
//    return null;
//  }
//}
//
///**
// * Instances of the class <code>PrefixSearchPattern</code> implement a search pattern that matches
// * elements whose name has a given prefix.
// */
//class PrefixSearchPattern implements SearchPattern {
//  /**
//   * The prefix that matching elements must start with.
//   */
//  final String _prefix;
//
//  /**
//   * A flag indicating whether a case sensitive match is to be performed.
//   */
//  final bool _caseSensitive;
//
//  /**
//   * Initialize a newly created search pattern to match elements whose names begin with the given
//   * prefix.
//   *
//   * @param prefix the prefix that matching elements must start with
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   */
//  PrefixSearchPattern(this._prefix, this._caseSensitive);
//
//  @override
//  MatchQuality matches(Element element) {
//    if (element == null) {
//      return null;
//    }
//    String name = element.displayName;
//    if (name == null) {
//      return null;
//    }
//    if (_caseSensitive && startsWith(name, _prefix)) {
//      return MatchQuality.EXACT;
//    }
//    if (!_caseSensitive && startsWithIgnoreCase(name, _prefix)) {
//      return MatchQuality.EXACT;
//    }
//    return null;
//  }
//}
//
///**
// * Instances of the class <code>RegularExpressionSearchPattern</code> implement a search pattern
// * that matches elements whose name matches a given regular expression.
// */
//class RegularExpressionSearchPattern implements SearchPattern {
//  /**
//   * The regular expression pattern that matching elements must match.
//   */
//  RegExp _pattern;
//
//  /**
//   * Initialize a newly created search pattern to match elements whose names begin with the given
//   * prefix.
//   *
//   * @param regularExpression the regular expression that matching elements must match
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   */
//  RegularExpressionSearchPattern(String regularExpression, bool caseSensitive) {
//    _pattern = new RegExp(regularExpression);
//  }
//
//  @override
//  MatchQuality matches(Element element) {
//    if (element == null) {
//      return null;
//    }
//    String name = element.displayName;
//    if (name == null) {
//      return null;
//    }
//    if (new JavaPatternMatcher(_pattern, name).matches()) {
//      return MatchQuality.EXACT;
//    }
//    return null;
//  }
//}
//
///**
// * Factory for [SearchEngine].
// */
//class SearchEngineFactory {
//  /**
//   * @return the new [SearchEngine] instance based on the given [Index].
//   */
//  static SearchEngine createSearchEngine(Index index) => new SearchEngineImpl(index);
//}

///**
// * Implementation of [SearchEngine].
// */
//class SearchEngineImpl implements SearchEngine {
//  /**
//   * Apply the given filter to the given listener.
//   *
//   * @param filter the filter to be used before passing matches on to the listener, or `null`
//   *          if all matches should be passed on
//   * @param listener the listener that will only be given matches that pass the filter
//   * @return a search listener that will pass to the given listener any matches that pass the given
//   *         filter
//   */
//  static SearchListener _applyFilter(SearchFilter filter, SearchListener listener) {
//    if (filter == null) {
//      return listener;
//    }
//    return new FilteredSearchListener(filter, listener);
//  }
//
//  /**
//   * Apply the given pattern to the given listener.
//   *
//   * @param pattern the pattern to be used before passing matches on to the listener, or
//   *          `null` if all matches should be passed on
//   * @param listener the listener that will only be given matches that match the pattern
//   * @return a search listener that will pass to the given listener any matches that match the given
//   *         pattern
//   */
//  static SearchListener _applyPattern(SearchPattern pattern, SearchListener listener) {
//    if (pattern == null) {
//      return listener;
//    }
//    return new NameMatchingSearchListener(pattern, listener);
//  }
//
//  static List<Element> _createElements(SearchScope scope) {
//    if (scope is LibrarySearchScope) {
//      return scope.libraries;
//    }
//    return <Element> [IndexConstants.UNIVERSE];
//  }
//
//  static RelationshipCallback _newCallback(MatchKind matchKind, SearchScope scope, SearchListener listener) => new SearchEngineImpl_RelationshipCallbackImpl(scope, matchKind, listener);
//
//  /**
//   * The index used to respond to the search requests.
//   */
//  final Index _index;
//
//  /**
//   * Initialize a newly created search engine to use the given index.
//   *
//   * @param index the index used to respond to the search requests
//   */
//  SearchEngineImpl(this._index);
//
//  @override
//  Set<DartType> searchAssignedTypes(PropertyInducingElement variable, SearchScope scope) {
//    PropertyAccessorElement setter = variable.setter;
//    int numRequests = (setter != null ? 2 : 0) + 2;
//    // find locations
//    List<Location> locations = [];
//    CountDownLatch latch = new CountDownLatch(numRequests);
//    if (setter != null) {
//      _index.getRelationships(setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, new Callback());
//      _index.getRelationships(setter, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, new Callback());
//    }
//    _index.getRelationships(variable, IndexConstants.IS_REFERENCED_BY, new Callback());
//    _index.getRelationships(variable, IndexConstants.IS_DEFINED_BY, new Callback());
//    Uninterruptibles.awaitUninterruptibly(latch);
//    // get types from locations
//    Set<DartType> types = new Set();
//    for (Location location in locations) {
//      // check scope
//      if (scope != null) {
//        Element targetElement = location.element;
//        if (!scope.encloses(targetElement)) {
//          continue;
//        }
//      }
//      // we need data
//      if (location is! LocationWithData) {
//        continue;
//      }
//      LocationWithData locationWithData = location as LocationWithData;
//      // add type
//      Object data = locationWithData.data;
//      if (data is DartType) {
//        DartType type = data as DartType;
//        types.add(type);
//      }
//    }
//    // done
//    return types;
//  }
//
//  @override
//  List<SearchMatch> searchDeclarations(String name, SearchScope scope, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchDeclarations(this, name, scope, filter));
//
//  @override
//  void searchDeclarations2(String name, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.IS_DEFINED_BY, _newCallback(MatchKind.NAME_DECLARATION, scope, listener));
//  }
//
//  @override
//  List<SearchMatch> searchFunctionDeclarations(SearchScope scope, SearchPattern pattern, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchFunctionDeclarations(this, scope, pattern, filter));
//
//  @override
//  void searchFunctionDeclarations2(SearchScope scope, SearchPattern pattern, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    List<Element> elements = _createElements(scope);
//    listener = _applyPattern(pattern, listener);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(elements.length, listener);
//    for (Element element in elements) {
//      _index.getRelationships(element, IndexConstants.DEFINES_FUNCTION, _newCallback(MatchKind.FUNCTION_DECLARATION, scope, listener));
//    }
//  }
//
//  @override
//  List<SearchMatch> searchQualifiedMemberReferences(String name, SearchScope scope, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchQualifiedMemberReferences(this, name, scope, filter));
//
//  @override
//  void searchQualifiedMemberReferences2(String name, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(10, listener);
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.IS_REFERENCED_BY_QUALIFIED_RESOLVED, _newCallback(MatchKind.NAME_REFERENCE_RESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.IS_REFERENCED_BY_QUALIFIED_UNRESOLVED, _newCallback(MatchKind.NAME_REFERENCE_UNRESOLVED, scope, listener));
//    // granular resolved operations
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_INVOKED_BY_RESOLVED, _newCallback(MatchKind.NAME_INVOCATION_RESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_READ_BY_RESOLVED, _newCallback(MatchKind.NAME_READ_RESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_READ_WRITTEN_BY_RESOLVED, _newCallback(MatchKind.NAME_READ_WRITE_RESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_WRITTEN_BY_RESOLVED, _newCallback(MatchKind.NAME_WRITE_RESOLVED, scope, listener));
//    // granular unresolved operations
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_INVOKED_BY_UNRESOLVED, _newCallback(MatchKind.NAME_INVOCATION_UNRESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_READ_BY_UNRESOLVED, _newCallback(MatchKind.NAME_READ_UNRESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_READ_WRITTEN_BY_UNRESOLVED, _newCallback(MatchKind.NAME_READ_WRITE_UNRESOLVED, scope, listener));
//    _index.getRelationships(new NameElementImpl(name), IndexConstants.NAME_IS_WRITTEN_BY_UNRESOLVED, _newCallback(MatchKind.NAME_WRITE_UNRESOLVED, scope, listener));
//  }
//
//  @override
//  List<SearchMatch> searchReferences(Element element, SearchScope scope, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchReferences(this, element, scope, filter));
//
//  @override
//  void searchReferences2(Element element, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    if (element == null) {
//      listener.searchComplete();
//      return;
//    }
//    if (element is Member) {
//      element = (element as Member).baseElement;
//    }
//    while (true) {
//      if (element.kind == ElementKind.ANGULAR_COMPONENT || element.kind == ElementKind.ANGULAR_CONTROLLER || element.kind == ElementKind.ANGULAR_FORMATTER || element.kind == ElementKind.ANGULAR_PROPERTY || element.kind == ElementKind.ANGULAR_SCOPE_PROPERTY || element.kind == ElementKind.ANGULAR_SELECTOR) {
//        _searchReferences(element as AngularElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.CLASS) {
//        _searchReferences2(element as ClassElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.COMPILATION_UNIT) {
//        _searchReferences3(element as CompilationUnitElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.CONSTRUCTOR) {
//        _searchReferences4(element as ConstructorElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.FIELD || element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
//        _searchReferences12(element as PropertyInducingElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.FUNCTION) {
//        _searchReferences5(element as FunctionElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.GETTER || element.kind == ElementKind.SETTER) {
//        _searchReferences11(element as PropertyAccessorElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.IMPORT) {
//        _searchReferences7(element as ImportElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.LIBRARY) {
//        _searchReferences8(element as LibraryElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.LOCAL_VARIABLE) {
//        _searchReferences14(element as LocalVariableElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.METHOD) {
//        _searchReferences9(element as MethodElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.PARAMETER) {
//        _searchReferences10(element as ParameterElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
//        _searchReferences6(element as FunctionTypeAliasElement, scope, filter, listener);
//        return;
//      } else if (element.kind == ElementKind.TYPE_PARAMETER) {
//        _searchReferences13(element as TypeParameterElement, scope, filter, listener);
//        return;
//      } else {
//        listener.searchComplete();
//        return;
//      }
//      break;
//    }
//  }
//
//  @override
//  List<SearchMatch> searchSubtypes(ClassElement type, SearchScope scope, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchSubtypes(this, type, scope, filter));
//
//  @override
//  void searchSubtypes2(ClassElement type, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(3, listener);
//    _index.getRelationships(type, IndexConstants.IS_EXTENDED_BY, _newCallback(MatchKind.EXTENDS_REFERENCE, scope, listener));
//    _index.getRelationships(type, IndexConstants.IS_MIXED_IN_BY, _newCallback(MatchKind.WITH_REFERENCE, scope, listener));
//    _index.getRelationships(type, IndexConstants.IS_IMPLEMENTED_BY, _newCallback(MatchKind.IMPLEMENTS_REFERENCE, scope, listener));
//  }
//
//  @override
//  List<SearchMatch> searchTypeDeclarations(SearchScope scope, SearchPattern pattern, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchTypeDeclarations(this, scope, pattern, filter));
//
//  @override
//  void searchTypeDeclarations2(SearchScope scope, SearchPattern pattern, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    List<Element> elements = _createElements(scope);
//    listener = _applyPattern(pattern, listener);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(elements.length * 3, listener);
//    for (Element element in elements) {
//      _index.getRelationships(element, IndexConstants.DEFINES_CLASS, _newCallback(MatchKind.CLASS_DECLARATION, scope, listener));
//      _index.getRelationships(element, IndexConstants.DEFINES_CLASS_ALIAS, _newCallback(MatchKind.CLASS_ALIAS_DECLARATION, scope, listener));
//      _index.getRelationships(element, IndexConstants.DEFINES_FUNCTION_TYPE, _newCallback(MatchKind.FUNCTION_TYPE_DECLARATION, scope, listener));
//    }
//  }
//
//  @override
//  List<SearchMatch> searchVariableDeclarations(SearchScope scope, SearchPattern pattern, SearchFilter filter) => _gatherResults(new SearchRunner_SearchEngineImpl_searchVariableDeclarations(this, scope, pattern, filter));
//
//  @override
//  void searchVariableDeclarations2(SearchScope scope, SearchPattern pattern, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    List<Element> elements = _createElements(scope);
//    listener = _applyPattern(pattern, listener);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(elements.length, listener);
//    for (Element element in elements) {
//      _index.getRelationships(element, IndexConstants.DEFINES_VARIABLE, _newCallback(MatchKind.VARIABLE_DECLARATION, scope, listener));
//    }
//  }
//
//  /**
//   * Use the given runner to perform the given number of asynchronous searches, then wait until the
//   * search has completed and return the results that were produced.
//   *
//   * @param runner the runner used to perform an asynchronous search
//   * @return the results that were produced @ if the results of at least one of the searched could
//   *         not be computed
//   */
//  List<SearchMatch> _gatherResults(SearchEngineImpl_SearchRunner runner) {
//    GatheringSearchListener listener = new GatheringSearchListener();
//    runner.performSearch(listener);
//    while (!listener.isComplete) {
//      Thread.yield();
//    }
//    return listener.matches;
//  }
//
//  void _searchReferences(AngularElement element, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(2, listener);
//    _index.getRelationships(element, IndexConstants.ANGULAR_REFERENCE, _newCallback(MatchKind.ANGULAR_REFERENCE, scope, listener));
//    _index.getRelationships(element, IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE, _newCallback(MatchKind.ANGULAR_CLOSING_TAG_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences2(ClassElement type, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(type, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.TYPE_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences3(CompilationUnitElement unit, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(unit, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.UNIT_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences4(ConstructorElement constructor, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(2, listener);
//    _index.getRelationships(constructor, IndexConstants.IS_DEFINED_BY, _newCallback(MatchKind.CONSTRUCTOR_DECLARATION, scope, listener));
//    _index.getRelationships(constructor, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.CONSTRUCTOR_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences5(FunctionElement function, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(2, listener);
//    _index.getRelationships(function, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.FUNCTION_REFERENCE, scope, listener));
//    _index.getRelationships(function, IndexConstants.IS_INVOKED_BY, _newCallback(MatchKind.FUNCTION_EXECUTION, scope, listener));
//  }
//
//  void _searchReferences6(FunctionTypeAliasElement alias, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(alias, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.FUNCTION_TYPE_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences7(ImportElement imp, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(imp, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.IMPORT_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences8(LibraryElement library, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(library, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.LIBRARY_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences9(MethodElement method, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    // TODO(scheglov) use "5" when add named matches
//    listener = new CountingSearchListener(4, listener);
//    // exact matches
//    _index.getRelationships(method, IndexConstants.IS_INVOKED_BY_UNQUALIFIED, _newCallback(MatchKind.METHOD_INVOCATION, scope, listener));
//    _index.getRelationships(method, IndexConstants.IS_INVOKED_BY_QUALIFIED, _newCallback(MatchKind.METHOD_INVOCATION, scope, listener));
//    _index.getRelationships(method, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, _newCallback(MatchKind.METHOD_REFERENCE, scope, listener));
//    _index.getRelationships(method, IndexConstants.IS_REFERENCED_BY_QUALIFIED, _newCallback(MatchKind.METHOD_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences10(ParameterElement parameter, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(5, listener);
//    _index.getRelationships(parameter, IndexConstants.IS_READ_BY, _newCallback(MatchKind.VARIABLE_READ, scope, listener));
//    _index.getRelationships(parameter, IndexConstants.IS_READ_WRITTEN_BY, _newCallback(MatchKind.VARIABLE_READ_WRITE, scope, listener));
//    _index.getRelationships(parameter, IndexConstants.IS_WRITTEN_BY, _newCallback(MatchKind.VARIABLE_WRITE, scope, listener));
//    _index.getRelationships(parameter, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.NAMED_PARAMETER_REFERENCE, scope, listener));
//    _index.getRelationships(parameter, IndexConstants.IS_INVOKED_BY, _newCallback(MatchKind.FUNCTION_EXECUTION, scope, listener));
//  }
//
//  void _searchReferences11(PropertyAccessorElement accessor, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(2, listener);
//    _index.getRelationships(accessor, IndexConstants.IS_REFERENCED_BY_QUALIFIED, _newCallback(MatchKind.PROPERTY_ACCESSOR_REFERENCE, scope, listener));
//    _index.getRelationships(accessor, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, _newCallback(MatchKind.PROPERTY_ACCESSOR_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences12(PropertyInducingElement field, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    PropertyAccessorElement getter = field.getter;
//    PropertyAccessorElement setter = field.setter;
//    int numRequests = (getter != null ? 4 : 0) + (setter != null ? 2 : 0) + 2;
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(numRequests, listener);
//    if (getter != null) {
//      _index.getRelationships(getter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, _newCallback(MatchKind.FIELD_READ, scope, listener));
//      _index.getRelationships(getter, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, _newCallback(MatchKind.FIELD_READ, scope, listener));
//      _index.getRelationships(getter, IndexConstants.IS_INVOKED_BY_QUALIFIED, _newCallback(MatchKind.FIELD_INVOCATION, scope, listener));
//      _index.getRelationships(getter, IndexConstants.IS_INVOKED_BY_UNQUALIFIED, _newCallback(MatchKind.FIELD_INVOCATION, scope, listener));
//    }
//    if (setter != null) {
//      _index.getRelationships(setter, IndexConstants.IS_REFERENCED_BY_QUALIFIED, _newCallback(MatchKind.FIELD_WRITE, scope, listener));
//      _index.getRelationships(setter, IndexConstants.IS_REFERENCED_BY_UNQUALIFIED, _newCallback(MatchKind.FIELD_WRITE, scope, listener));
//    }
//    _index.getRelationships(field, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.FIELD_REFERENCE, scope, listener));
//    _index.getRelationships(field, IndexConstants.IS_REFERENCED_BY_QUALIFIED, _newCallback(MatchKind.FIELD_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences13(TypeParameterElement typeParameter, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    _index.getRelationships(typeParameter, IndexConstants.IS_REFERENCED_BY, _newCallback(MatchKind.TYPE_PARAMETER_REFERENCE, scope, listener));
//  }
//
//  void _searchReferences14(VariableElement variable, SearchScope scope, SearchFilter filter, SearchListener listener) {
//    assert(listener != null);
//    listener = _applyFilter(filter, listener);
//    listener = new CountingSearchListener(4, listener);
//    _index.getRelationships(variable, IndexConstants.IS_READ_BY, _newCallback(MatchKind.VARIABLE_READ, scope, listener));
//    _index.getRelationships(variable, IndexConstants.IS_READ_WRITTEN_BY, _newCallback(MatchKind.VARIABLE_READ_WRITE, scope, listener));
//    _index.getRelationships(variable, IndexConstants.IS_WRITTEN_BY, _newCallback(MatchKind.VARIABLE_WRITE, scope, listener));
//    _index.getRelationships(variable, IndexConstants.IS_INVOKED_BY, _newCallback(MatchKind.FUNCTION_EXECUTION, scope, listener));
//  }
//}
//
///**
// * Instances of the class <code>RelationshipCallbackImpl</code> implement a callback that can be
// * used to report results to a search listener.
// */
//class SearchEngineImpl_RelationshipCallbackImpl implements RelationshipCallback {
//  final SearchScope _scope;
//
//  /**
//   * The kind of matches that are represented by the results that will be provided to this
//   * callback.
//   */
//  final MatchKind _matchKind;
//
//  /**
//   * The search listener that should be notified when results are found.
//   */
//  final SearchListener _listener;
//
//  /**
//   * Initialize a newly created callback to report matches of the given kind to the given listener
//   * when results are found.
//   *
//   * @param scope the [SearchScope] to return matches from, may be `null` to return
//   *          all matches
//   * @param matchKind the kind of matches that are represented by the results
//   * @param listener the search listener that should be notified when results are found
//   */
//  SearchEngineImpl_RelationshipCallbackImpl(this._scope, this._matchKind, this._listener);
//
//  @override
//  void hasRelationships(Element element, Relationship relationship, List<Location> locations) {
//    for (Location location in locations) {
//      Element targetElement = location.element;
//      // check scope
//      if (_scope != null && !_scope.encloses(targetElement)) {
//        continue;
//      }
//      SourceRange range = new SourceRange(location.offset, location.length);
//      // TODO(scheglov) IndexConstants.DYNAMIC for MatchQuality.NAME
//      MatchQuality quality = MatchQuality.EXACT;
//      //          MatchQuality quality = element.getResource() != IndexConstants.DYNAMIC
//      //              ? MatchQuality.EXACT : MatchQuality.NAME;
//      SearchMatch match = new SearchMatch(quality, _matchKind, targetElement, range);
//      match.qualified = identical(relationship, IndexConstants.IS_REFERENCED_BY_QUALIFIED) || identical(relationship, IndexConstants.IS_INVOKED_BY_QUALIFIED);
//      _listener.matchFound(match);
//    }
//    _listener.searchComplete();
//  }
//}
//
///**
// * The interface <code>SearchRunner</code> defines the behavior of objects that can be used to
// * perform an asynchronous search.
// */
//abstract class SearchEngineImpl_SearchRunner {
//  /**
//   * Perform an asynchronous search, passing the results to the given listener.
//   *
//   * @param listener the listener to which search results should be passed @ if the results could
//   *          not be computed
//   */
//  void performSearch(SearchListener listener);
//}
//
///**
// * The interface <code>SearchListener</code> defines the behavior of objects that are listening for
// * the results of a search.
// */
//abstract class SearchListener {
//  /**
//   * Record the fact that the given match was found.
//   *
//   * @param match the match that was found
//   */
//  void matchFound(SearchMatch match);
//
//  /**
//   * This method is invoked when the search is complete and no additional matches will be found.
//   */
//  void searchComplete();
//}

///**
// * The class <code>SearchPatternFactory</code> defines utility methods that can be used to create
// * search patterns.
// */
//class SearchPatternFactory {
//  /**
//   * Create a pattern that will match any element that is matched by all of the given patterns. If
//   * no patterns are given, then the resulting pattern will not match any elements.
//   *
//   * @param patterns the patterns that must all be matched in order for the new pattern to be
//   *          matched
//   * @return the pattern that was created
//   */
//  static SearchPattern createAndPattern(List<SearchPattern> patterns) {
//    if (patterns.length == 1) {
//      return patterns[0];
//    }
//    return new AndSearchPattern(patterns);
//  }
//
//  /**
//   * Create a pattern that will match any element whose name matches a partial identifier where
//   * camel case conventions are used to perform what is essentially multiple prefix matches.
//   *
//   * @param pattern the pattern that matching elements must match
//   * @param samePartCount `true` if the pattern and the name being matched must have
//   *          exactly the same number of parts (i.e. the same number of uppercase characters)
//   * @return the pattern that was created
//   */
//  static SearchPattern createCamelCasePattern(String prefix, bool samePartCount) => new CamelCaseSearchPattern(prefix, samePartCount);
//
//  /**
//   * Create a pattern that will match any element whose name matches a specified identifier exactly.
//   *
//   * @param identifier the identifier that matching elements must be equal to
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   * @return the pattern that was created
//   */
//  static SearchPattern createExactPattern(String identifier, bool caseSensitive) => new ExactSearchPattern(identifier, caseSensitive);
//
//  /**
//   * Create a pattern that will match any element that is matched by at least one of the given
//   * patterns. If no patterns are given, then the resulting pattern will not match any elements.
//   *
//   * @param patterns the patterns used to determine whether the new pattern is matched
//   * @return the pattern that was created
//   */
//  static SearchPattern createOrPattern(List<SearchPattern> patterns) {
//    if (patterns.length == 1) {
//      return patterns[0];
//    }
//    return new OrSearchPattern(patterns);
//  }
//
//  /**
//   * Create a pattern that will match any element whose name starts with the given prefix.
//   *
//   * @param prefix the prefix of names that match the pattern
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   * @return the pattern that was created
//   */
//  static SearchPattern createPrefixPattern(String prefix, bool caseSensitive) => new PrefixSearchPattern(prefix, caseSensitive);
//
//  /**
//   * Create a pattern that will match any element whose name matches a regular expression.
//   *
//   * @param regularExpression the regular expression that matching elements must match
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   * @return the pattern that was created
//   */
//  static SearchPattern createRegularExpressionPattern(String regularExpression, bool caseSensitive) => new RegularExpressionSearchPattern(regularExpression, caseSensitive);
//
//  /**
//   * Create a pattern that will match any element whose name matches a pattern containing wildcard
//   * characters. The wildcard characters that are currently supported are '?' (to match any single
//   * character) and '*' (to match zero or more characters).
//   *
//   * @param pattern the pattern that matching elements must match
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   * @return the pattern that was created
//   */
//  static SearchPattern createWildcardPattern(String pattern, bool caseSensitive) => new WildcardSearchPattern(pattern, caseSensitive);
//}
//
//class SearchRunner_SearchEngineImpl_searchDeclarations implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  String name;
//
//  SearchScope scope;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchDeclarations(this.SearchEngineImpl_this, this.name, this.scope, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchDeclarations2(name, scope, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchFunctionDeclarations implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  SearchScope scope;
//
//  SearchPattern pattern;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchFunctionDeclarations(this.SearchEngineImpl_this, this.scope, this.pattern, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchFunctionDeclarations2(scope, pattern, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchQualifiedMemberReferences implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  String name;
//
//  SearchScope scope;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchQualifiedMemberReferences(this.SearchEngineImpl_this, this.name, this.scope, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchQualifiedMemberReferences2(name, scope, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchReferences implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  Element element;
//
//  SearchScope scope;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchReferences(this.SearchEngineImpl_this, this.element, this.scope, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchReferences2(element, scope, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchSubtypes implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  ClassElement type;
//
//  SearchScope scope;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchSubtypes(this.SearchEngineImpl_this, this.type, this.scope, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchSubtypes2(type, scope, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchTypeDeclarations implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  SearchScope scope;
//
//  SearchPattern pattern;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchTypeDeclarations(this.SearchEngineImpl_this, this.scope, this.pattern, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchTypeDeclarations2(scope, pattern, filter, listener);
//  }
//}
//
//class SearchRunner_SearchEngineImpl_searchVariableDeclarations implements SearchEngineImpl_SearchRunner {
//  final SearchEngineImpl SearchEngineImpl_this;
//
//  SearchScope scope;
//
//  SearchPattern pattern;
//
//  SearchFilter filter;
//
//  SearchRunner_SearchEngineImpl_searchVariableDeclarations(this.SearchEngineImpl_this, this.scope, this.pattern, this.filter);
//
//  @override
//  void performSearch(SearchListener listener) {
//    SearchEngineImpl_this.searchVariableDeclarations2(scope, pattern, filter, listener);
//  }
//}
//
///**
// * The class <code>SearchScopeFactory</code> defines utility methods that can be used to create
// * search scopes.
// */
//class SearchScopeFactory {
//  /**
//   * A search scope that encompasses everything in the "universe". Because it does not hold any
//   * state there is no reason not to share a single instance.
//   */
//  static SearchScope _UNIVERSE_SCOPE = new UniverseSearchScope();
//
//  /**
//   * Create a search scope that encompasses everything in the given library.
//   *
//   * @param library the library defining which elements are included in the scope
//   * @return the search scope that was created
//   */
//  static SearchScope createLibraryScope(Iterable<LibraryElement> libraries) => new LibrarySearchScope.con1(libraries);
//
//  /**
//   * Create a search scope that encompasses everything in the given libraries.
//   *
//   * @param libraries the libraries defining which elements are included in the scope
//   * @return the search scope that was created
//   */
//  static SearchScope createLibraryScope2(List<LibraryElement> libraries) => new LibrarySearchScope.con2(libraries);
//
//  /**
//   * Create a search scope that encompasses everything in the given library.
//   *
//   * @param library the library defining which elements are included in the scope
//   * @return the search scope that was created
//   */
//  static SearchScope createLibraryScope3(LibraryElement library) => new LibrarySearchScope.con2([library]);
//
//  /**
//   * Create a search scope that encompasses everything in the universe.
//   *
//   * @return the search scope that was created
//   */
//  static SearchScope createUniverseScope() => _UNIVERSE_SCOPE;
//}
//
///**
// * The [SearchScope] that encompasses everything in the universe.
// */
//class UniverseSearchScope implements SearchScope {
//  @override
//  bool encloses(Element element) => true;
//}
//
///**
// * Instances of the class <code>WildcardSearchPattern</code> implement a search pattern that matches
// * elements whose name matches a pattern with wildcard characters. The wildcard characters that are
// * currently supported are '?' (to match any single character) and '*' (to match zero or more
// * characters).
// */
//class WildcardSearchPattern implements SearchPattern {
//  /**
//   * The pattern that matching elements must match.
//   */
//  List<int> _pattern;
//
//  /**
//   * A flag indicating whether a case sensitive match is to be performed.
//   */
//  final bool _caseSensitive;
//
//  /**
//   * Initialize a newly created search pattern to match elements whose names begin with the given
//   * prefix.
//   *
//   * @param pattern the pattern that matching elements must match
//   * @param caseSensitive `true` if a case sensitive match is to be performed
//   */
//  WildcardSearchPattern(String pattern, this._caseSensitive) {
//    this._pattern = _caseSensitive ? pattern.toCharArray() : pattern.toLowerCase().toCharArray();
//  }
//
//  @override
//  MatchQuality matches(Element element) {
//    if (element == null) {
//      return null;
//    }
//    String name = element.displayName;
//    if (name == null) {
//      return null;
//    }
//    if (CharOperation.match(_pattern, name.toCharArray(), _caseSensitive)) {
//      return MatchQuality.EXACT;
//    }
//    return null;
//  }
//}
//
///**
// * Instances of the class <code>ScopedSearchListener</code> implement a search listener that
// * delegates to another search listener after removing matches that are outside a given scope.
// */
//abstract class WrappedSearchListener implements SearchListener {
//  /**
//   * The listener being wrapped.
//   */
//  SearchListener _baseListener;
//
//  /**
//   * Initialize a newly created search listener to wrap the given listener.
//   *
//   * @param listener the search listener being wrapped
//   */
//  WrappedSearchListener(SearchListener listener) {
//    _baseListener = listener;
//  }
//
//  @override
//  void searchComplete() {
//    _baseListener.searchComplete();
//  }
//
//  /**
//   * Pass the given match on to the wrapped listener.
//   *
//   * @param match the match to be propagated
//   */
//  void propagateMatch(SearchMatch match) {
//    _baseListener.matchFound(match);
//  }
//}
