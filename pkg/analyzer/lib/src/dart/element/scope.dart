// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(super.parent, ConstructorElement element) {
    var hasWildcardVariables = element.library.featureSet.isEnabled(
      Feature.wildcard_variables,
    );
    for (var formalParameter in element.formalParameters) {
      // Skip wildcards.
      if (formalParameter.name == '_' && hasWildcardVariables) {
        continue;
      }
      _addGetter(formalParameter);
    }
  }
}

/// The scope that looks up elements in documentation comments.
///
/// Attempts to look up elements in its [innerScope] before searching
/// through any doc imports.
class DocumentationCommentScope with _GettersAndSetters implements Scope {
  /// The scope that will be prioritized in look ups before searching in doc
  /// imports.
  ///
  /// Will be set for each specific comment scope in the `ScopeResolverVisitor`.
  Scope innerScope;

  DocumentationCommentScope(
    this.innerScope,
    List<LibraryElement> docImportLibraries,
  ) {
    for (var importedLibrary in docImportLibraries) {
      if (importedLibrary is LibraryElementImpl) {
        // TODO(kallentu): Handle combinators.
        for (var exportedReference in importedLibrary.exportedReferences) {
          var reference = exportedReference.reference;
          var element = importedLibrary.session.elementFactory
              .elementOfReference3(reference);
          if (element is SetterElement) {
            _addSetter(element);
          } else {
            _addGetter(element);
          }
        }
      }
    }
  }

  @override
  ScopeLookupResult lookup(String id) {
    var result = innerScope.lookup(id);
    if (result.getter != null || result.setter != null) return result;
    return ScopeLookupResultImpl(getter: _getters[id], setter: _setters[id]);
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
  FormalParameterScope(super.parent, List<FormalParameterElement> elements) {
    for (var parameter in elements) {
      if (parameter is! FieldFormalParameterElement &&
          parameter is! SuperFormalParameterElement) {
        if (!parameter.isWildcardVariable) {
          _addGetter(parameter);
        }
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

  void notifyExtensionUsed(ExtensionElement element) {
    for (var tracking in map.values) {
      tracking.notifyExtensionUsed(element);
    }
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

  /// Usually it is an error to use an import prefix without `.identifier`
  /// after it, but we allow this in comment references. This makes the
  /// corresponding group of imports "used".
  bool hasPrefixUsedInCommentReference = false;

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
    var elementFactory = importedLibrary.session.elementFactory;

    for (var exportedReference in importedLibrary.exportedReferences) {
      var reference = exportedReference.reference;
      var element = elementFactory.elementOfReference3(reference);

      // Check only accessed elements.
      if (!accessedElements.contains(element)) {
        continue;
      }

      // We want to exclude only deprecated exports.
      if (!importedLibrary.isFromDeprecatedExport(exportedReference)) {
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

  void notifyExtensionUsed(ExtensionElement element) {
    var imports = _elementImports[element];
    if (imports != null) {
      for (var import in imports) {
        (importToUsedElements[import] ??= {}).add(element);
      }
    } else {
      // We include into `accessibleExtensions` elements from parents.
      // So, it is possible that the element is not from this scope.
      // In this case we notify the parent tracker.
      var parentTracking = scope.parent?._importsTracking;
      parentTracking?.notifyExtensionUsed(element);
    }
  }

  void notifyPrefixUsedInCommentReference() {
    hasPrefixUsedInCommentReference = true;
  }

  void _buildElementToImportsMap() {
    for (var import in scope._importElements) {
      var importedLibrary = import.importedLibrary!;
      var elementFactory = importedLibrary.session.elementFactory;
      var combinators = import.combinators.build();
      for (var exportedReference in importedLibrary.exportedReferences) {
        var reference = exportedReference.reference;
        if (combinators.allows(reference.name)) {
          var element = elementFactory.elementOfReference3(reference);
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
    if ('${library.source.uri}' == 'dart:core') {
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

class LibraryFragmentScope implements Scope {
  final LibraryFragmentScope? parent;
  final LibraryFragmentImpl fragment;
  final PrefixScope noPrefixScope;

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

  factory LibraryFragmentScope(LibraryFragmentImpl fragment) {
    var parent = fragment.enclosingFragment?.scope;
    return LibraryFragmentScope._(
      parent: parent,
      fragment: fragment,
      noPrefixScope: PrefixScope(
        libraryFragment: fragment,
        parent: parent?.noPrefixScope,
        libraryImports: fragment.libraryImports,
        prefix: null,
      ),
    );
  }

  LibraryFragmentScope._({
    required this.parent,
    required this.fragment,
    required this.noPrefixScope,
  }) {
    for (var prefix in fragment.prefixes) {
      if (prefix.name case var name?) {
        _prefixElements[name] = prefix;
      }
      prefix.scope = PrefixScope(
        libraryFragment: fragment,
        parent: _getParentPrefixScope(prefix),
        libraryImports: fragment.libraryImports,
        prefix: prefix,
      );
    }
  }

  /// The extensions accessible within [fragment].
  List<ExtensionElement> get accessibleExtensions {
    if (_extensions case var extensions?) {
      return extensions;
    }

    globalResultRequirements?.record_libraryFragmentScope_accessibleExtensions(
      importedLibraries: importedLibrariesContributingExtensions,
    );

    return _extensions =
        {
          ...fragment.library.libraryDeclarations.extensions,
          ...noPrefixScope._extensions,
          for (var prefix in _prefixElements.values)
            ...prefix.scope._extensions,
          ...?parent?.accessibleExtensions,
        }.toFixedList();
  }

  List<LibraryElementImpl> get importedLibrariesContributingExtensions {
    return _importedLibrariesContributingExtensions ??=
        {
          ...noPrefixScope._importedLibraries,
          for (var prefix in _prefixElements.values)
            ...prefix.scope._importedLibraries,
          ...?parent?.importedLibrariesContributingExtensions,
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
    noPrefixScope.importsTrackingDestroy();
    for (var prefixElement in _prefixElements.values) {
      prefixElement.scope.importsTrackingDestroy();
    }
    _importsTracking = null;
  }

  ImportsTracking importsTrackingInit() {
    return _importsTracking = ImportsTracking(
      map: {
        null: noPrefixScope.importsTrackingInit(),
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

  void notifyExtensionUsed(ExtensionElement element) {
    _importsTracking?.notifyExtensionUsed(element);
  }

  PrefixScope? _getParentPrefixScope(PrefixElementImpl prefix) {
    var isDeferred = prefix.imports.any((import) {
      return import.prefix?.isDeferred ?? false;
    });
    if (isDeferred) {
      return null;
    }

    for (var scope = parent; scope != null; scope = scope.parent) {
      var parentPrefix = scope._prefixElements[prefix.name];
      if (parentPrefix != null) {
        return parentPrefix.scope;
      }
    }
    return null;
  }

  ScopeLookupResult? _lookupCombined(String id) {
    // Try prefix elements.
    if (_shouldTryPrefixElement(id)) {
      if (_prefixElements[id] case var prefixElement?) {
        return ScopeLookupResultImpl(getter: prefixElement, setter: null);
      }
    }

    // Try imports of the library fragment.
    var noPrefixResult = noPrefixScope.lookup(id);
    if (noPrefixResult.getter != null || noPrefixResult.setter != null) {
      return noPrefixResult;
    }

    // Try the parent's combined import scope.
    return parent?._lookupCombined(id);
  }

  ScopeLookupResult? _lookupLibrary(String id) {
    var libraryDeclarations = fragment.library.libraryDeclarations;
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

  bool _shouldTryPrefixElement(String id) {
    if (id == '_') {
      var featureSet = fragment.library.featureSet;
      return !featureSet.isEnabled(Feature.wildcard_variables);
    }
    return true;
  }
}

class LocalScope extends EnclosedScope {
  LocalScope(super.parent);

  void add(Element element) {
    if (!element.isWildcardVariable) {
      _addGetter(element);
    }
  }
}

class PrefixScope implements Scope {
  final LibraryFragmentImpl libraryFragment;
  final PrefixScope? parent;

  final List<LibraryImportImpl> _importElements = [];
  final List<LibraryElementImpl> _importedLibraries = [];

  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};
  Set<String>? _settersFromDeprecatedExport;
  Set<String>? _gettersFromDeprecatedExport;
  final Set<ExtensionElement> _extensions = {};
  LibraryElement? _deferredLibrary;

  ImportsTrackingOfPrefix? _importsTracking;

  PrefixScope({
    required this.libraryFragment,
    required this.parent,
    required List<LibraryImportImpl> libraryImports,
    required PrefixElement? prefix,
  }) {
    var elementFactory = libraryElement.session.elementFactory;
    for (var import in libraryImports) {
      var importedUri = import.uri;
      if (importedUri is DirectiveUriWithLibraryImpl &&
          import.prefix?.element == prefix) {
        _importElements.add(import);
        var importedLibrary = importedUri.library;
        _importedLibraries.add(importedLibrary);
        var combinators = import.combinators.build();
        for (var exportedReference in importedLibrary.exportedReferences) {
          var reference = exportedReference.reference;
          if (combinators.allows(reference.name)) {
            var element = elementFactory.elementOfReference3(reference);
            if (_shouldAdd(importedLibrary, element)) {
              _add(
                element,
                importedLibrary.isFromDeprecatedExport(exportedReference),
              );
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

  LibraryElementImpl get libraryElement {
    return libraryFragment.element;
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

    if (globalResultRequirements case var resultRequirements?) {
      resultRequirements.record_importPrefixScope_lookup(
        importedLibraries: _importedLibraries,
        id: id,
      );
    }

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

  /// Usually this is an error, but we allow it in comment references.
  void notifyPrefixUsedInCommentReference() {
    _importsTracking?.notifyPrefixUsedInCommentReference();
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

    var deprecatedSet =
        isSetter ? _settersFromDeprecatedExport : _gettersFromDeprecatedExport;
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

class ScopeLookupResultImpl extends ScopeLookupResult {
  @override
  final Element? getter;

  @override
  final Element? setter;

  ScopeLookupResultImpl({required this.getter, required this.setter});

  @Deprecated('Use getter instead')
  @override
  Element? get getter2 => getter;

  @Deprecated('Use getter instead')
  @override
  Element? get setter2 => setter;
}

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(super.parent, List<TypeParameterElement> elements) {
    for (var element in elements) {
      if (!element.isWildcardVariable) {
        _addGetter(element);
      }
    }
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
