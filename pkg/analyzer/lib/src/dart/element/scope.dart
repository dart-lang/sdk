// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(
    super.parent,
    ConstructorElement element,
    List<FormalParameterFragmentImpl> formalParameterFragments,
  ) {
    var hasWildcardVariables = element.library.featureSet.isEnabled(
      Feature.wildcard_variables,
    );

    for (var formalParameter in formalParameterFragments) {
      if (formalParameter.isOriginOtherFragmentOfEnclosing) {
        continue;
      }

      var name = formalParameter.name;
      if (name == null || name == '_' && hasWildcardVariables) {
        continue;
      }

      // If the parameter is a private named parameter, then the formal
      // parameter's name is the public name, but in the constructor initializer
      // list, it is referred to by its private name.
      if (formalParameter case FieldFormalParameterFragmentImpl(
        :var privateName?,
      )) {
        _getters[privateName] ??= formalParameter.element;
      } else {
        _getters[name] ??= formalParameter.element;
      }
    }
  }
}

/// The scope of the names provided by the `@docImport`s of a file.
///
/// Doc imports are scoped like imports with the parts-with-imports feature:
/// the scope of a file looks up its doc import prefixes, then the names that
/// it doc-imports without a prefix, and then the scope of the enclosing file.
/// A part file can shadow the names doc-imported by its enclosing files, and
/// extend their prefixes.
class DocImportScope with _FileImportsScope implements Scope {
  @override
  final LibraryFragmentImpl _libraryFragment;

  @override
  final DocImportScope? _enclosingScope;

  final List<LibraryImportImpl> _imports;

  @override
  final Map<String, DocImportPrefixElementImpl> _prefixElements = {};

  /// The names imported without a prefix.
  ///
  /// Built lazily, because most documentation comments reference only names
  /// that are found in their lexical scope. It is also built when a doc import
  /// prefix of a part file searches past this file for a prefix to extend.
  @override
  late final PrefixScope _noPrefixScope = PrefixScope(
    libraryFragment: _libraryFragment,
    parent: null,
    parentSearchedScopes: const [],
    libraryImports: _imports,
    prefix: null,
  );

  DocImportScope({
    required LibraryFragmentImpl libraryFragment,
    required DocImportScope? parent,
    required List<LibraryImportImpl> imports,
  }) : _libraryFragment = libraryFragment,
       _enclosingScope = parent,
       _imports = imports {
    var prefixes = <DocImportPrefixElementImpl>{};
    for (var import in imports) {
      var prefix = import.prefix?.element;
      if (prefix is DocImportPrefixElementImpl) {
        prefixes.add(prefix);
        if (prefix.name case var name?) {
          _prefixElements[name] = prefix;
        }
      }
    }

    _buildPrefixScopes(imports: imports, prefixes: prefixes);
  }

  @override
  ScopeLookupResult lookup(String id) {
    if (_libraryFragment.isAllowedAsPrefixName(id)) {
      if (_prefixElements[id] case var prefixElement?) {
        return ScopeLookupResultImpl(getter: prefixElement, setter: null);
      }
    }

    var result = _noPrefixScope.lookup(id);
    if (result.getter != null || result.setter != null) {
      return result;
    }

    if (_enclosingScope case var enclosingScope?) {
      return enclosingScope.lookup(id);
    }
    return result;
  }
}

/// The scope that looks up elements in documentation comments.
///
/// Elements of the lexical scope shadow the names from doc imports.
class DocumentationCommentScope implements Scope {
  final Scope _innerScope;
  final DocImportScope _docImportScope;

  DocumentationCommentScope(this._innerScope, this._docImportScope);

  @override
  ScopeLookupResult lookup(String id) {
    var result = _innerScope.lookup(id);
    if (result.getter != null || result.setter != null) return result;
    return _docImportScope.lookup(id);
  }
}

/// A scope that is lexically enclosed in another scope.
class EnclosedScope with _GettersAndSetters implements Scope {
  final Scope _parent;

  EnclosedScope(Scope parent) : _parent = parent;

  Scope get parent => _parent;

  @override
  ScopeLookupResult lookup(String id) {
    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      return ScopeLookupResultImpl(getter: getter, setter: setter);
    }

    return _parent.lookup(id);
  }
}

/// The scope defined by an extension.
class ExtensionScope extends EnclosedScope {
  ExtensionScope(super.parent, ExtensionElement element) {
    element.getters.forEach(_addGetter);
    element.setters.forEach(_addSetter);
    element.methods.forEach(_addGetter);
  }
}

class FormalParameterScope extends EnclosedScope {
  FormalParameterScope(
    super.parent,
    List<FormalParameterFragmentImpl> fragments, {
    required FeatureSet featureSet,
  }) {
    for (var fragment in fragments) {
      if (fragment.isOriginOtherFragmentOfEnclosing ||
          fragment is FieldFormalParameterFragmentImpl ||
          fragment is SuperFormalParameterFragmentImpl) {
        continue;
      }

      var name = fragment.name;
      if (featureSet.isEnabled(Feature.wildcard_variables) && name == '_') {
        continue;
      }

      if (name != null) {
        _getters[name] ??= fragment.element;
      }
    }
  }
}

/// Tracking information for all import in [LibraryFragmentImpl].
class ImportsTracking {
  /// Tracking information for each import prefix.
  final Map<PrefixElementImpl?, ImportsTrackingOfPrefix> map;

  ImportsTracking({required this.map});

  /// The elements that are used from [import].
  Set<Element> elementsOf(LibraryImportImpl import) {
    return trackerOf(import)?.importToUsedElements[import] ?? {};
  }

  /// Records that [element] is used, and returns whether any import of
  /// this fragment provides it.
  bool notifyExtensionUsed(ExtensionElement element) {
    var isProvided = false;
    for (var tracking in map.values) {
      isProvided |= tracking.notifyExtensionUsed(element);
    }
    return isProvided;
  }

  ImportsTrackingOfPrefix? trackerOf(LibraryImportImpl import) {
    var prefix = import.prefix?.element;
    return map[prefix];
  }
}

class ImportsTrackingOfPrefix {
  final PrefixScope scope;

  /// Key: an element.
  /// Value: the imports that provide the element.
  final Map<Element, List<LibraryImportImpl>> _elementImports = {};

  /// Key: an import.
  /// Value: used elements imported from the import.
  final Map<LibraryImportImpl, Set<Element>> importToUsedElements = {};

  /// Key: an import.
  /// Value: used elements imported from the import.
  /// Excludes elements from deprecated exports.
  final Map<LibraryImportImpl, Set<Element>> importToAccessedElements2 = {};

  /// Whether the prefix is used without naming an element, so no lookup
  /// tells which of the imports with this prefix is used.
  ///
  /// This happens in comment references like `[math]`, where it is allowed,
  /// and in incomplete code like `math.`, where the parser reports the
  /// missing name. This makes the whole group of imports "used".
  bool hasPrefixUsedWithoutName = false;

  /// We set it temporarily to `false` while resolving combinators.
  bool active = true;

  ImportsTrackingOfPrefix({required this.scope}) {
    _buildElementToImportsMap();
  }

  /// The elements that are used from [import].
  Set<Element> elementsOf(LibraryImportImpl import) {
    return importToUsedElements[import] ?? {};
  }

  /// The subset of [elementsOf], excludes elements that are from deprecated
  /// exports inside the imported library.
  Set<Element> elementsOf2(LibraryImportImpl import) {
    var result = importToAccessedElements2[import];
    if (result != null) {
      return result;
    }

    var accessedElements = elementsOf(import);

    // SAFETY: the scope adds only imports with libraries.
    var importedLibrary = import.importedLibrary!;
    var elementFactory = importedLibrary.internal.elementFactory;

    for (var entry in importedLibrary.exportEntries) {
      var element = elementFactory.elementOfReference3(entry.reference);

      // Check only accessed elements.
      if (!accessedElements.contains(element)) {
        continue;
      }

      // We want to exclude only deprecated exports.
      if (!importedLibrary.isFromDeprecatedExport(entry)) {
        continue;
      }

      // OK, we have to clone the set, and remove the element.
      result ??= accessedElements.toSet();
      result.remove(element);
    }

    result ??= accessedElements;
    return importToAccessedElements2[import] = result;
  }

  void lookupResult(Element? element) {
    if (!active) {
      return;
    }

    if (element == null) {
      return;
    }

    if (element is MultiplyDefinedElement) {
      return;
    }

    // SAFETY: if we have `element`, it is from a local import.
    var imports = _elementImports[element]!;
    for (var import in imports) {
      (importToUsedElements[import] ??= {}).add(element);
    }
  }

  /// Records that [element] is used, and returns whether any import of
  /// this scope provides it.
  bool notifyExtensionUsed(ExtensionElement element) {
    var imports = _elementImports[element];
    if (imports == null) {
      return false;
    }
    for (var import in imports) {
      (importToUsedElements[import] ??= {}).add(element);
    }
    return true;
  }

  void notifyPrefixUsedWithoutName() {
    hasPrefixUsedWithoutName = true;
  }

  void _buildElementToImportsMap() {
    for (var import in scope._importElements) {
      var importedLibrary = import.importedLibrary!;
      var elementFactory = importedLibrary.internal.elementFactory;
      var combinators = import.combinators.build();
      for (var entry in importedLibrary.exportEntries) {
        if (combinators.allows(entry.name)) {
          var element = elementFactory.elementOfReference3(entry.reference);
          (_elementImports[element] ??= []).add(import);
        }
      }
    }
  }
}

/// The scope defined by an instance element.
class InstanceScope extends EnclosedScope {
  InstanceScope(super.parent, InstanceElement element) {
    element.getters.forEach(_addGetter);
    element.setters.forEach(_addSetter);
    element.methods.forEach(_addGetter);
  }

  @override
  ScopeLookupResult lookup(String id) {
    // When a lexical lookup encounters an instance member with the requested
    // basename, the returned result should have null as the getter and setter
    // (and that is the result, so we should not search the enclosing scope).
    // This corresponds to the following rule from the specification:
    // "Consider the case where D is an instance member declaration in a class
    // or mixin A. The lexical lookup then yields nothing."
    var getter = _getters[id];
    var setter = _setters[id];
    if (getter == null && setter == null) {
      return _parent.lookup(id);
    }
    if (_isStatic(getter) || _isStatic(setter)) {
      return ScopeLookupResultImpl(getter: getter, setter: setter);
    }
    // A declaration with the right basename was found, so the search ends.
    // Return nulls to ensure that it is handled as with a prepended `this.`.
    return ScopeLookupResultImpl(getter: null, setter: null);
  }

  static bool _isStatic(Element? element) {
    switch (element) {
      case PropertyAccessorElement(:var isStatic) ||
          MethodElement(:var isStatic):
        return isStatic;
      default:
        return false;
    }
  }
}

/// The top-level declarations of the library.
class LibraryDeclarations with _GettersAndSetters {
  List<ExtensionElement> extensions = [];

  LibraryDeclarations(LibraryElementImpl library) {
    library.getters.forEach(_addGetter);
    library.enums.forEach(_addGetter);
    library.extensions.forEach(_addExtension);
    library.extensionTypes.forEach(_addGetter);
    library.setters.forEach(_addSetter);
    library.topLevelFunctions.forEach(_addGetter);
    library.typeAliases.forEach(_addGetter);
    library.mixins.forEach(_addGetter);
    library.classes.forEach(_addGetter);

    // Add implicit 'dart:core' declarations.
    if ('${library.uri}' == 'dart:core') {
      _addGetter(DynamicElementImpl.instance);
      _addGetter(NeverElementImpl.instance);
    }

    extensions = extensions.toFixedList();
  }

  /// Returns a getter or setter with the [name].
  Element? withName(String name) {
    return _getters[name] ?? _setters[name];
  }

  void _addExtension(ExtensionElement element) {
    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }
}

class LibraryFragmentScope with _FileImportsScope implements Scope {
  @override
  final LibraryFragmentImpl _libraryFragment;

  @override
  final LibraryFragmentScope? _enclosingScope;

  @override
  final PrefixScope _noPrefixScope;

  @override
  final Map<String, PrefixElementImpl> _prefixElements = {};

  /// All libraries that contribute to [accessibleExtensions].
  List<LibraryElementImpl>? _importedLibrariesContributingExtensions;

  /// The cached result for [accessibleExtensions].
  List<ExtensionElement>? _extensions;

  /// This field is set temporarily while resolving all files of a library.
  /// So, we can track which elements were actually returned, and which imports
  /// in which file (including enclosing files) provided these elements.
  ///
  /// When we are done, we remove the tracker, so that it does not use memory
  /// when we are not resolving files of this library.
  ImportsTracking? _importsTracking;

  LibraryFragmentScope(LibraryFragmentImpl libraryFragment)
    : _libraryFragment = libraryFragment,
      _enclosingScope = libraryFragment.enclosingFragment?.scope,
      _noPrefixScope = PrefixScope(
        libraryFragment: libraryFragment,
        parent: null,
        parentSearchedScopes: const [],
        libraryImports: libraryFragment.libraryImports,
        prefix: null,
      ) {
    for (var prefix in libraryFragment.prefixes) {
      if (prefix.name case var name?) {
        _prefixElements[name] = prefix;
      }
    }

    _buildPrefixScopes(
      imports: libraryFragment.libraryImports,
      prefixes: libraryFragment.prefixes,
    );
  }

  /// The extensions accessible within the file of this scope.
  List<ExtensionElement> get accessibleExtensions {
    if (_extensions case var extensions?) {
      return extensions;
    }

    globalResultRequirements?.record_libraryFragmentScope_accessibleExtensions(
      importedLibraries: importedLibrariesContributingExtensions,
    );

    return _extensions = {
      ..._libraryFragment.library.libraryDeclarations.extensions,
      ..._noPrefixScope._extensions,
      for (var prefix in _prefixElements.values) ...prefix.scope._extensions,
      ...?_enclosingScope?.accessibleExtensions,
    }.toFixedList();
  }

  List<LibraryElementImpl> get importedLibrariesContributingExtensions {
    return _importedLibrariesContributingExtensions ??= {
      ..._noPrefixScope._importedLibraries,
      for (var prefix in _prefixElements.values)
        ...prefix.scope._importedLibraries,
      ...?_enclosingScope?.importedLibrariesContributingExtensions,
    }.toFixedList();
  }

  // TODO(scheglov): this is kludge.
  // We should not use the fragment scope for resolving combinators.
  // We should use the export scope of the imported library.
  void importsTrackingActive(bool value) {
    if (_importsTracking case var importsTracking?) {
      for (var tracking in importsTracking.map.values) {
        tracking.active = value;
      }
    }
  }

  void importsTrackingDestroy() {
    _noPrefixScope.importsTrackingDestroy();
    for (var prefixElement in _prefixElements.values) {
      prefixElement.scope.importsTrackingDestroy();
    }
    _importsTracking = null;
  }

  ImportsTracking importsTrackingInit() {
    return _importsTracking = ImportsTracking(
      map: {
        null: _noPrefixScope.importsTrackingInit(),
        for (var prefixElement in _prefixElements.values)
          prefixElement: prefixElement.scope.importsTrackingInit(),
      },
    );
  }

  @override
  ScopeLookupResult lookup(String id) {
    // Try declarations of the whole library.
    if (_lookupLibrary(id) case var result?) {
      return result;
    }

    // Try the combined import scope.
    var importResult = _lookupCombined(id);
    if (importResult != null) {
      return importResult;
    }

    // No result.
    return ScopeLookupResultImpl(getter: null, setter: null);
  }

  /// Records that [element] is used.
  ///
  /// The [accessibleExtensions] include extensions from the enclosing
  /// fragments, so we attribute the usage to the nearest fragment that
  /// imports [element].
  void notifyExtensionUsed(ExtensionElement element) {
    for (LibraryFragmentScope? scope = this; scope != null;) {
      if (scope._importsTracking?.notifyExtensionUsed(element) ?? false) {
        return;
      }
      scope = scope._enclosingScope;
    }
  }

  ScopeLookupResult? _lookupCombined(String id) {
    // Try prefix elements.
    if (_libraryFragment.isAllowedAsPrefixName(id)) {
      if (_prefixElements[id] case var prefixElement?) {
        return ScopeLookupResultImpl(getter: prefixElement, setter: null);
      }
    }

    // Try imports of the library fragment.
    var noPrefixResult = _noPrefixScope.lookup(id);
    if (noPrefixResult.getter != null || noPrefixResult.setter != null) {
      return noPrefixResult;
    }

    // Try the combined import scope of the enclosing file.
    return _enclosingScope?._lookupCombined(id);
  }

  ScopeLookupResult? _lookupLibrary(String id) {
    var libraryDeclarations = _libraryFragment.library.libraryDeclarations;
    var libraryGetter = libraryDeclarations._getters[id];
    var librarySetter = libraryDeclarations._setters[id];
    if (libraryGetter != null || librarySetter != null) {
      return ScopeLookupResultImpl(
        getter: libraryGetter,
        setter: librarySetter,
      );
    }
    return null;
  }
}

class LocalScope extends EnclosedScope {
  final FeatureSet _featureSet;

  LocalScope(super.parent, {required FeatureSet featureSet})
    : _featureSet = featureSet;

  void add(Element element) {
    assert(() {
      return element is LocalVariableElement ||
          element is LocalFunctionElement ||
          // TODO(scheglov): why not FormalParameterScope?
          element is FormalParameterElement;
    }());
    if (element.name == '_') {
      if (element is PatternVariableElement ||
          _featureSet.isEnabled(Feature.wildcard_variables)) {
        return;
      }
    }
    _addGetter(element);
  }

  void addAll(Iterable<Element> elements) {
    for (var element in elements) {
      add(element);
    }
  }
}

class PrefixScope implements Scope {
  final LibraryFragmentImpl libraryFragment;

  /// The prefix of this scope, `null` for the imports without a prefix.
  final PrefixElement? _prefixElement;

  /// The scope of the prefix with the same name in an enclosing file, whose
  /// names are also accessible through this prefix.
  ///
  /// It is `null` if this prefix, or the nearest prefix with the same name in
  /// an enclosing file, is deferred: a deferred prefix provides only the names
  /// of its own library. It is also `null` if there is no such prefix, and for
  /// the imports without a prefix.
  ///
  /// We search the enclosing files from the nearest one, and stop at the
  /// first file that has a prefix with this name, or imports this name
  /// without a prefix.
  final PrefixScope? _parent;

  /// The scopes of the imports without a prefix of the enclosing files that
  /// we searched for the name of this prefix to choose [_parent].
  ///
  /// The choice depends on the names that these scopes import, so every time
  /// [parent] is read, we record this requirement.
  final List<PrefixScope> _parentSearchedScopes;

  final List<LibraryImportImpl> _importElements = [];
  final List<LibraryElementImpl> _importedLibraries = [];

  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};
  Set<String>? _settersFromDeprecatedExport;
  Set<String>? _gettersFromDeprecatedExport;
  final Set<ExtensionElement> _extensions = {};
  LibraryElement? _deferredLibrary;

  ImportsTrackingOfPrefix? _importsTracking;

  final PrefixScopeRequirementState _requirementState =
      PrefixScopeRequirementState();

  PrefixScope({
    required this.libraryFragment,
    required PrefixScope? parent,
    required List<PrefixScope> parentSearchedScopes,
    required List<LibraryImportImpl> libraryImports,
    required PrefixElement? prefix,
  }) : _prefixElement = prefix,
       _parent = parent,
       _parentSearchedScopes = parentSearchedScopes {
    var elementFactory = libraryElement.session.elementFactory;
    for (var import in libraryImports) {
      var importedUri = import.uri;
      if (importedUri is DirectiveUriWithLibraryImpl &&
          import.prefix?.element == prefix) {
        _importElements.add(import);
        var importedLibrary = importedUri.library;
        _importedLibraries.add(importedLibrary);
        var combinators = import.combinators.build();
        for (var entry in importedLibrary.exportEntries) {
          if (combinators.allows(entry.name)) {
            var element = elementFactory.elementOfReference3(entry.reference);
            if (_shouldAdd(importedLibrary, element)) {
              _add(element, importedLibrary.isFromDeprecatedExport(entry));
            }
          }
        }
        if (import.prefix case var importPrefix?) {
          if (importPrefix.isDeferred) {
            _deferredLibrary ??= importedLibrary;
          }
        }
      }
    }
  }

  /// The libraries imported into this scope, and into [parent].
  ///
  /// Excludes the libraries of files that don't exist, because their URIs
  /// are already reported, and they don't provide any elements.
  List<LibraryElementImpl> get libraries {
    return {
      for (var library in _importedLibraries)
        if (!library.isOriginNotExistingFile) library,
      ...?parent?.libraries,
    }.toList();
  }

  LibraryElementImpl get libraryElement {
    return libraryFragment.element;
  }

  /// Returns [_parent], and records that the result depends on its choice.
  PrefixScope? get parent {
    if (_prefixElement?.name case var name?) {
      for (var scope in _parentSearchedScopes) {
        scope._recordLookupRequirement(name);
      }
    }
    return _parent;
  }

  void importsTrackingDestroy() {
    _importsTracking = null;
  }

  ImportsTrackingOfPrefix importsTrackingInit() {
    return _importsTracking = ImportsTrackingOfPrefix(scope: this);
  }

  @override
  ScopeLookupResult lookup(String id) {
    var deferredLibrary = _deferredLibrary;
    if (deferredLibrary != null &&
        id == TopLevelFunctionElement.LOAD_LIBRARY_NAME) {
      return ScopeLookupResultImpl(
        getter: deferredLibrary.loadLibraryFunction,
        setter: null,
      );
    }

    _recordLookupRequirement(id);

    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      _importsTracking?.lookupResult(getter);
      _importsTracking?.lookupResult(setter);
      return PrefixScopeLookupResult(
        getter: getter,
        setter: setter,
        getterIsFromDeprecatedExport:
            _gettersFromDeprecatedExport?.contains(id) ?? false,
        setterIsFromDeprecatedExport:
            _settersFromDeprecatedExport?.contains(id) ?? false,
      );
    }

    if (parent case var parent?) {
      return parent.lookup(id);
    }

    return ScopeLookupResultImpl(getter: null, setter: null);
  }

  /// Notifies that the prefix is used without naming an element.
  ///
  /// See [ImportsTrackingOfPrefix.hasPrefixUsedWithoutName].
  void notifyPrefixUsedWithoutName() {
    _importsTracking?.notifyPrefixUsedWithoutName();
  }

  void _add(Element element, bool isFromDeprecatedExport) {
    if (element is SetterElement) {
      _addTo(
        element,
        isFromDeprecatedExport: isFromDeprecatedExport,
        isSetter: true,
      );
    } else {
      _addTo(
        element,
        isFromDeprecatedExport: isFromDeprecatedExport,
        isSetter: false,
      );
      if (element is ExtensionElement) {
        _extensions.add(element);
      }
    }
  }

  void _addTo(
    Element element, {
    required bool isFromDeprecatedExport,
    required bool isSetter,
  }) {
    var map = isSetter ? _setters : _getters;
    var id = element.displayName;
    var existing = map[id];

    if (existing == null) {
      map[id] = element;
      if (isFromDeprecatedExport) {
        if (isSetter) {
          (_settersFromDeprecatedExport ??= {}).add(id);
        } else {
          (_gettersFromDeprecatedExport ??= {}).add(id);
        }
      }
      return;
    }

    var deprecatedSet = isSetter
        ? _settersFromDeprecatedExport
        : _gettersFromDeprecatedExport;
    var wasFromDeprecatedExport = deprecatedSet?.contains(id) ?? false;
    if (existing == element) {
      if (wasFromDeprecatedExport && !isFromDeprecatedExport) {
        deprecatedSet!.remove(id);
      }
      return;
    }

    map[id] = _merge(existing, element);
    if (wasFromDeprecatedExport) {
      deprecatedSet!.remove(id);
    }
  }

  /// Whether the imports of this scope (without [parent]) provide a getter
  /// or setter named [id].
  ///
  /// Unlike [lookup], this is not a use of an import, so it is not tracked,
  /// and does not record a requirement.
  bool _importsName(String id) {
    return _getters.containsKey(id) || _setters.containsKey(id);
  }

  Element _merge(Element existing, Element other) {
    if (_isSdkElement(existing)) {
      if (!_isSdkElement(other)) {
        return other;
      }
    } else {
      if (_isSdkElement(other)) {
        return existing;
      }
    }

    var conflictingElements = <Element>{};
    _addElement(conflictingElements, existing);
    _addElement(conflictingElements, other);

    return MultiplyDefinedElementImpl(
      libraryFragment,
      conflictingElements.first.name!,
      conflictingElements.toList(),
    );
  }

  /// Records that [id] was looked up in the imports of this scope.
  void _recordLookupRequirement(String id) {
    if (globalResultRequirements case var resultRequirements?) {
      resultRequirements.record_importPrefixScope_lookup(
        state: _requirementState,
        importedLibraries: _importedLibraries,
        id: id,
      );
    }
  }

  bool _shouldAdd(LibraryElementImpl importedLibrary, Element element) {
    // It is an error for the identifier `Record`, denoting the `Record` class
    // from `dart:core`, where that import scope name is only imported from
    // platform libraries, to appear in a library whose language version is
    // less than `v`; assuming that `v` is the language version in which
    // records are released.
    if (!libraryElement.featureSet.isEnabled(Feature.records)) {
      if (importedLibrary.isInSdk &&
          element is ClassElementImpl &&
          element.isDartCoreRecord) {
        return false;
      }
    }
    return true;
  }

  static void _addElement(Set<Element> conflictingElements, Element element) {
    if (element is MultiplyDefinedElementImpl) {
      conflictingElements.addAll(element.conflictingElements);
    } else {
      conflictingElements.add(element);
    }
  }

  static bool _isSdkElement(Element element) {
    if (element is DynamicElementImpl || element is NeverElementImpl) {
      return true;
    }
    if (element is MultiplyDefinedElement) {
      return false;
    }
    return element.library!.isInSdk;
  }
}

class PrefixScopeLookupResult extends ScopeLookupResultImpl {
  static const int getterIsFromDeprecatedExportBit = 1 << 0;
  static const int setterIsFromDeprecatedExportBit = 1 << 1;

  final int _deprecatedBits;

  PrefixScopeLookupResult({
    required super.getter,
    required super.setter,
    required bool getterIsFromDeprecatedExport,
    required bool setterIsFromDeprecatedExport,
  }) : _deprecatedBits =
           (getterIsFromDeprecatedExport
               ? getterIsFromDeprecatedExportBit
               : 0) |
           (setterIsFromDeprecatedExport ? setterIsFromDeprecatedExportBit : 0);

  /// This flag is set to `true` if [getter] is available using import
  /// directives where every imported library re-exports the element, and
  /// every such `export` directive is marked as deprecated.
  bool get getterIsFromDeprecatedExport =>
      (_deprecatedBits & getterIsFromDeprecatedExportBit) != 0;

  /// This flag is set to `true` if [setter] is available using import
  /// directives where every imported library re-exports the element, and
  /// every such `export` directive is marked as deprecated.
  bool get setterIsFromDeprecatedExport =>
      (_deprecatedBits & setterIsFromDeprecatedExportBit) != 0;
}

/// The primary parameter scope.
///
/// It includes every primary formal parameter which is not declaring, not
/// initializing, and not a super parameter.
class PrimaryParameterScope extends EnclosedScope {
  PrimaryParameterScope(
    super.parent,
    ConstructorElement element,
    List<FormalParameterFragmentImpl> formalParameterFragments,
  ) {
    assert(element.isPrimary);

    var hasWildcardVariables = element.library.featureSet.isEnabled(
      Feature.wildcard_variables,
    );

    for (var fragment in formalParameterFragments) {
      if (fragment.isOriginOtherFragmentOfEnclosing ||
          fragment is FieldFormalParameterFragmentImpl ||
          fragment is SuperFormalParameterFragmentImpl) {
        continue;
      }

      var name = fragment.name;
      if (name == null || hasWildcardVariables && name == '_') {
        continue;
      }

      _getters[name] ??= fragment.element;
    }
  }
}

class ScopeLookupResultImpl extends ScopeLookupResult {
  @override
  final Element? getter;

  @override
  final Element? setter;

  ScopeLookupResultImpl({required this.getter, required this.setter});
}

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(
    super.parent,
    List<TypeParameterElement> elements, {
    required FeatureSet featureSet,
  }) {
    var wildcardVariablesEnabled = featureSet.isEnabled(
      Feature.wildcard_variables,
    );
    for (var element in elements) {
      if (wildcardVariablesEnabled && element.name == '_') {
        continue;
      }
      _addGetter(element);
    }
  }
}

/// The scope of the imports, or of the doc imports, of a file.
///
/// Doc imports are scoped like imports, so the prefixes of both extend the
/// prefixes of the enclosing files by the same rules, implemented once here.
mixin _FileImportsScope {
  /// The scope of the same kind of the enclosing file.
  _FileImportsScope? get _enclosingScope;

  /// The file of this scope.
  LibraryFragmentImpl get _libraryFragment;

  /// The scope of the names imported without a prefix.
  PrefixScope get _noPrefixScope;

  /// The prefixes declared in this file, by name.
  Map<String, PrefixElementImpl> get _prefixElements;

  /// Sets the scope of each of the [prefixes] declared in this file, built
  /// from those of the [imports] that use it.
  void _buildPrefixScopes({
    required List<LibraryImportImpl> imports,
    required Iterable<PrefixElementImpl> prefixes,
  }) {
    for (var prefix in prefixes) {
      var (:parent, :searchedScopes) = _getParentPrefixScope(prefix);
      prefix.scope = PrefixScope(
        libraryFragment: _libraryFragment,
        parent: parent,
        parentSearchedScopes: searchedScopes,
        libraryImports: imports,
        prefix: prefix,
      );
    }
  }

  /// Returns the scope of the prefix of an enclosing file that [prefix]
  /// extends, and the scopes that we searched to find it.
  ///
  /// A deferred prefix extends nothing. Otherwise we search the enclosing
  /// files from the nearest one, and stop at the first file that has a prefix
  /// with this name, or imports this name without a prefix. If that prefix is
  /// deferred, [prefix] extends nothing either.
  ({PrefixScope? parent, List<PrefixScope> searchedScopes})
  _getParentPrefixScope(PrefixElementImpl prefix) {
    var name = prefix.name;
    if (name == null || prefix.isDeferred) {
      return (parent: null, searchedScopes: const []);
    }

    var searchedScopes = <PrefixScope>[];
    for (
      var scope = _enclosingScope;
      scope != null;
      scope = scope._enclosingScope
    ) {
      if (scope._prefixElements[name] case var parentPrefix?) {
        return (
          parent: parentPrefix.isDeferred ? null : parentPrefix.scope,
          searchedScopes: searchedScopes,
        );
      }
      searchedScopes.add(scope._noPrefixScope);
      if (scope._noPrefixScope._importsName(name)) {
        break;
      }
    }
    return (parent: null, searchedScopes: searchedScopes);
  }
}

mixin _GettersAndSetters {
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  void _addGetter(Element element) {
    var id = element.lookupName;
    if (id != null) {
      _getters[id] ??= element;
    }
  }

  void _addSetter(Element element) {
    var name = element.lookupName;
    if (name != null && name.endsWith('=')) {
      var id = considerCanonicalizeString(name.substring(0, name.length - 1));
      _setters[id] ??= element;
    }
  }
}

extension on LibraryFragmentImpl {
  /// Whether [id] can be the name of an import prefix.
  ///
  /// With wildcard variables, `as _` does not declare a prefix.
  bool isAllowedAsPrefixName(String id) {
    if (id == '_') {
      return !library.featureSet.isEnabled(Feature.wildcard_variables);
    }
    return true;
  }
}
