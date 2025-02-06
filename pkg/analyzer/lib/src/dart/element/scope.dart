// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(super.parent, ConstructorElement2 element) {
    var hasWildcardVariables =
        element.library2.featureSet.isEnabled(Feature.wildcard_variables);
    for (var formalParameter in element.formalParameters) {
      // Skip wildcards.
      if (formalParameter.name3 == '_' && hasWildcardVariables) {
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
      this.innerScope, List<LibraryElement2> docImportLibraries) {
    for (var importedLibrary in docImportLibraries) {
      if (importedLibrary is LibraryElementImpl) {
        // TODO(kallentu): Handle combinators.
        for (var exportedReference in importedLibrary.exportedReferences) {
          var reference = exportedReference.reference;
          var element = importedLibrary.session.elementFactory
              .elementOfReference2(reference)!;
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
    if (result.getter2 != null || result.setter2 != null) return result;
    return ScopeLookupResultImpl(
      getter2: _getters[id],
      setter2: _setters[id],
    );
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
      return ScopeLookupResultImpl(
        getter2: getter,
        setter2: setter,
      );
    }

    return _parent.lookup(id);
  }
}

/// The scope defined by an extension.
class ExtensionScope extends EnclosedScope {
  ExtensionScope(
    super.parent,
    ExtensionElement2 element,
  ) {
    element.getters2.forEach(_addGetter);
    element.setters2.forEach(_addSetter);
    element.methods2.forEach(_addGetter);
  }
}

class FormalParameterScope extends EnclosedScope {
  FormalParameterScope(
    super.parent,
    List<FormalParameterElement> elements,
  ) {
    for (var parameter in elements) {
      if (parameter is! FieldFormalParameterElement2 &&
          parameter is! SuperFormalParameterElement2) {
        if (!parameter.isWildcardVariable) {
          _addGetter(parameter);
        }
      }
    }
  }
}

/// Tracking information for all import in [CompilationUnitElementImpl].
class ImportsTracking {
  /// Tracking information for each import prefix.
  final Map<PrefixElementImpl2?, ImportsTrackingOfPrefix> map;

  ImportsTracking({
    required this.map,
  });

  /// The elements that are used from [import].
  Set<Element2> elementsOf(LibraryImportElementImpl import) {
    return trackerOf(import)?.importToUsedElements[import] ?? {};
  }

  void notifyExtensionUsed(ExtensionElement2 element) {
    for (var tracking in map.values) {
      tracking.notifyExtensionUsed(element);
    }
  }

  ImportsTrackingOfPrefix? trackerOf(LibraryImportElementImpl import) {
    var prefix = import.prefix2?.element;
    return map[prefix];
  }
}

class ImportsTrackingOfPrefix {
  final PrefixScope scope;

  /// Key: an element.
  /// Value: the imports that provide the element.
  final Map<Element2, List<LibraryImportElementImpl>> _elementImports = {};

  /// Key: an import.
  /// Value: used elements imported from the import.
  final Map<LibraryImportElementImpl, Set<Element2>> importToUsedElements = {};

  /// Key: an import.
  /// Value: used elements imported from the import.
  /// Excludes elements from deprecated exports.
  final Map<LibraryImportElementImpl, Set<Element2>> importToAccessedElements2 =
      {};

  /// Usually it is an error to use an import prefix without `.identifier`
  /// after it, but we allow this in comment references. This makes the
  /// corresponding group of imports "used".
  bool hasPrefixUsedInCommentReference = false;

  /// We set it temporarily to `false` while resolving combinators.
  bool active = true;

  ImportsTrackingOfPrefix({
    required this.scope,
  }) {
    _buildElementToImportsMap();
  }

  /// The elements that are used from [import].
  Set<Element2> elementsOf(LibraryImportElementImpl import) {
    return importToUsedElements[import] ?? {};
  }

  /// The subset of [elementsOf], excludes elements that are from deprecated
  /// exports inside the imported library.
  Set<Element2> elementsOf2(LibraryImportElementImpl import) {
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
      var element = elementFactory.elementOfReference2(reference)!;

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

  void lookupResult(Element2? element) {
    if (!active) {
      return;
    }

    if (element == null) {
      return;
    }

    if (element is MultiplyDefinedElement2) {
      return;
    }

    // SAFETY: if we have `element`, it is from a local import.
    var imports = _elementImports[element]!;
    for (var import in imports) {
      (importToUsedElements[import] ??= {}).add(element);
    }
  }

  void notifyExtensionUsed(ExtensionElement2 element) {
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
          var element = elementFactory.elementOfReference2(reference)!;
          (_elementImports[element] ??= []).add(import);
        }
      }
    }
  }
}

/// The scope defined by an instance element.
class InstanceScope extends EnclosedScope {
  InstanceScope(super.parent, InstanceElement2 element) {
    element.getters2.forEach(_addGetter);
    element.setters2.forEach(_addSetter);
    element.methods2.forEach(_addGetter);
  }
}

/// The top-level declarations of the library.
class LibraryDeclarations with _GettersAndSetters {
  List<ExtensionElement2> extensions = [];

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
      _addGetter(DynamicElementImpl2.instance);
      _addGetter(NeverElementImpl2.instance);
    }

    extensions = extensions.toFixedList();
  }

  /// Returns a getter or setter with the [name].
  Element2? withName(String name) {
    return _getters[name] ?? _setters[name];
  }

  void _addExtension(ExtensionElement2 element) {
    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }
}

class LibraryFragmentScope implements Scope {
  final LibraryFragmentScope? parent;
  final CompilationUnitElementImpl fragment;
  final PrefixScope noPrefixScope;

  final Map<String, PrefixElementImpl2> _prefixElements = {};

  /// The cached result for [accessibleExtensions].
  List<ExtensionElement2>? _extensions;

  /// This field is set temporarily while resolving all files of a library.
  /// So, we can track which elements were actually returned, and which imports
  /// in which file (including enclosing files) provided these elements.
  ///
  /// When we are done, we remove the tracker, so that it does not use memory
  /// when we are not resolving files of this library.
  ImportsTracking? _importsTracking;

  factory LibraryFragmentScope(CompilationUnitElementImpl fragment) {
    var parent = fragment.enclosingElement3?.scope;
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
      if (prefix.name3 case var name?) {
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
  List<ExtensionElement2> get accessibleExtensions {
    var libraryDeclarations = fragment.library.libraryDeclarations;
    return _extensions ??= {
      ...libraryDeclarations.extensions,
      ...noPrefixScope._extensions,
      for (var prefix in _prefixElements.values) ...prefix.scope._extensions,
      ...?parent?.accessibleExtensions,
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
    return ScopeLookupResultImpl(
      getter2: null,
      setter2: null,
    );
  }

  void notifyExtensionUsed(ExtensionElement2 element) {
    _importsTracking?.notifyExtensionUsed(element);
  }

  PrefixScope? _getParentPrefixScope(PrefixElementImpl2 prefix) {
    var isDeferred = prefix.imports.any((import) {
      return import.prefix2?.isDeferred ?? false;
    });
    if (isDeferred) {
      return null;
    }

    for (var scope = parent; scope != null; scope = scope.parent) {
      var parentPrefix = scope._prefixElements[prefix.name3];
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
        return ScopeLookupResultImpl(
          getter2: prefixElement,
          setter2: null,
        );
      }
    }

    // Try imports of the library fragment.
    var noPrefixResult = noPrefixScope.lookup(id);
    if (noPrefixResult.getter2 != null || noPrefixResult.setter2 != null) {
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
        getter2: libraryGetter,
        setter2: librarySetter,
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

  void add(Element2 element) {
    if (!element.isWildcardVariable) {
      _addGetter(element);
    }
  }
}

class PrefixScope implements Scope {
  final CompilationUnitElementImpl libraryFragment;
  final PrefixScope? parent;

  final List<LibraryImportElementImpl> _importElements = [];

  final Map<String, Element2> _getters = {};
  final Map<String, Element2> _setters = {};
  Set<String>? _settersFromDeprecatedExport;
  Set<String>? _gettersFromDeprecatedExport;
  final Set<ExtensionElement2> _extensions = {};
  LibraryElement2? _deferredLibrary;

  ImportsTrackingOfPrefix? _importsTracking;

  PrefixScope({
    required this.libraryFragment,
    required this.parent,
    required List<LibraryImportElementImpl> libraryImports,
    required PrefixElement2? prefix,
  }) {
    var elementFactory = libraryElement.session.elementFactory;
    for (var import in libraryImports) {
      var importedUri = import.uri;
      if (importedUri is DirectiveUriWithLibraryImpl &&
          import.prefix2?.element == prefix) {
        _importElements.add(import);
        var importedLibrary = importedUri.library;
        var combinators = import.combinators.build();
        for (var exportedReference in importedLibrary.exportedReferences) {
          var reference = exportedReference.reference;
          if (combinators.allows(reference.name)) {
            var element = elementFactory.elementOfReference2(reference)!;
            if (_shouldAdd(importedLibrary, element)) {
              _add(
                element,
                importedLibrary.isFromDeprecatedExport(exportedReference),
              );
            }
          }
        }
        if (import.prefix2 case var importPrefix?) {
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
    return _importsTracking = ImportsTrackingOfPrefix(
      scope: this,
    );
  }

  @override
  ScopeLookupResult lookup(String id) {
    var deferredLibrary = _deferredLibrary;
    if (deferredLibrary != null &&
        id == TopLevelFunctionElement.LOAD_LIBRARY_NAME) {
      return ScopeLookupResultImpl(
        getter2: deferredLibrary.loadLibraryFunction2,
        setter2: null,
      );
    }

    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      _importsTracking?.lookupResult(getter);
      _importsTracking?.lookupResult(setter);
      return PrefixScopeLookupResult(
        getter2: getter,
        setter2: setter,
        getterIsFromDeprecatedExport:
            _gettersFromDeprecatedExport?.contains(id) ?? false,
        setterIsFromDeprecatedExport:
            _settersFromDeprecatedExport?.contains(id) ?? false,
      );
    }

    if (parent case var parent?) {
      return parent.lookup(id);
    }

    return ScopeLookupResultImpl(
      getter2: null,
      setter2: null,
    );
  }

  /// Usually this is an error, but we allow it in comment references.
  void notifyPrefixUsedInCommentReference() {
    _importsTracking?.notifyPrefixUsedInCommentReference();
  }

  void _add(Element2 element, bool isFromDeprecatedExport) {
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
      if (element is ExtensionElement2) {
        _extensions.add(element);
      }
    }
  }

  void _addTo(
    Element2 element, {
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

  Element2 _merge(Element2 existing, Element2 other) {
    if (_isSdkElement(existing)) {
      if (!_isSdkElement(other)) {
        return other;
      }
    } else {
      if (_isSdkElement(other)) {
        return existing;
      }
    }

    var conflictingElements = <Element2>{};
    _addElement(conflictingElements, existing);
    _addElement(conflictingElements, other);

    return MultiplyDefinedElementImpl2(
      libraryFragment,
      conflictingElements.first.name3!,
      conflictingElements.toList(),
    );
  }

  bool _shouldAdd(LibraryElementImpl importedLibrary, Element2 element) {
    // It is an error for the identifier `Record`, denoting the `Record` class
    // from `dart:core`, where that import scope name is only imported from
    // platform libraries, to appear in a library whose language version is
    // less than `v`; assuming that `v` is the language version in which
    // records are released.
    if (!libraryElement.featureSet.isEnabled(Feature.records)) {
      if (importedLibrary.isInSdk &&
          element is ClassElementImpl2 &&
          element.isDartCoreRecord) {
        return false;
      }
    }
    return true;
  }

  static void _addElement(
    Set<Element2> conflictingElements,
    Element2 element,
  ) {
    if (element is MultiplyDefinedElementImpl2) {
      conflictingElements.addAll(element.conflictingElements2);
    } else {
      conflictingElements.add(element);
    }
  }

  static bool _isSdkElement(Element2 element) {
    if (element is DynamicElementImpl2 || element is NeverElementImpl2) {
      return true;
    }
    if (element is MultiplyDefinedElement2) {
      return false;
    }
    return element.library2!.isInSdk;
  }
}

class PrefixScopeLookupResult extends ScopeLookupResultImpl {
  static const int getterIsFromDeprecatedExportBit = 1 << 0;
  static const int setterIsFromDeprecatedExportBit = 1 << 1;

  final int _deprecatedBits;

  PrefixScopeLookupResult({
    required super.getter2,
    required super.setter2,
    required bool getterIsFromDeprecatedExport,
    required bool setterIsFromDeprecatedExport,
  }) : _deprecatedBits = (getterIsFromDeprecatedExport
                ? getterIsFromDeprecatedExportBit
                : 0) |
            (setterIsFromDeprecatedExport
                ? setterIsFromDeprecatedExportBit
                : 0);

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
  final Element2? getter2;

  @override
  final Element2? setter2;

  ScopeLookupResultImpl({
    required this.getter2,
    required this.setter2,
  });
}

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(
    super.parent,
    List<TypeParameterElement2> elements,
  ) {
    for (var element in elements) {
      if (!element.isWildcardVariable) {
        _addGetter(element);
      }
    }
  }
}

mixin _GettersAndSetters {
  final Map<String, Element2> _getters = {};
  final Map<String, Element2> _setters = {};

  void _addGetter(Element2 element) {
    var id = element.lookupName;
    if (id != null) {
      _getters[id] ??= element;
    }
  }

  void _addSetter(Element2 element) {
    var name = element.lookupName;
    if (name != null && name.endsWith('=')) {
      var id = considerCanonicalizeString(name.substring(0, name.length - 1));
      _setters[id] ??= element;
    }
  }
}
