// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(super.parent, ConstructorElement element) {
    element.parameters.forEach(_addGetter);
  }
}

/// The scope that looks up elements in doc imports.
///
/// Attempts to look up elements in its [innerScope] before searching
/// through the doc imports.
class DocImportScope with _GettersAndSetters implements Scope {
  /// The scope that will be prioritized in look ups before searching in doc
  /// imports.
  ///
  /// Will be set for each specific comment scope in the `ScopeResolverVisitor`.
  Scope innerScope;

  DocImportScope(this.innerScope, List<LibraryElement> docImportLibraries) {
    for (var importedLibrary in docImportLibraries) {
      if (importedLibrary is LibraryElementImpl) {
        // TODO(kallentu): Handle combinators.
        for (var exportedReference in importedLibrary.exportedReferences) {
          var reference = exportedReference.reference;
          var element = importedLibrary.session.elementFactory
              .elementOfReference(reference)!;
          if (element is PropertyAccessorElement && element.isSetter) {
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
    return ScopeLookupResultImpl(_getters[id], _setters[id]);
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
      return ScopeLookupResultImpl(getter, setter);
    }

    return _parent.lookup(id);
  }
}

/// The scope defined by an extension.
class ExtensionScope extends EnclosedScope {
  ExtensionScope(
    super.parent,
    ExtensionElement element,
  ) {
    element.accessors.forEach(_addPropertyAccessor);
    element.methods.forEach(_addGetter);
  }
}

class FormalParameterScope extends EnclosedScope {
  FormalParameterScope(
    super.parent,
    List<ParameterElement> elements,
  ) {
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

/// The scope defined by an instance element.
class InstanceScope extends EnclosedScope {
  InstanceScope(super.parent, InstanceElement element) {
    var augmented = element.augmented;
    augmented.accessors.forEach(_addPropertyAccessor);
    augmented.methods.forEach(_addGetter);
  }
}

class LibraryOrAugmentationScope extends EnclosedScope {
  final LibraryOrAugmentationElementImpl _container;
  List<ExtensionElement> extensions = [];

  factory LibraryOrAugmentationScope(
    LibraryOrAugmentationElementImpl container,
  ) {
    var importScope = _LibraryOrAugmentationImportScope(container);
    return LibraryOrAugmentationScope._(container, importScope);
  }

  LibraryOrAugmentationScope._(
    this._container,
    _LibraryOrAugmentationImportScope importScope,
  ) : super(importScope) {
    extensions.addAll(importScope.extensions);

    _container.prefixes.forEach(_addGetter);
    _container.library.units.forEach(_addUnitElements);

    // Add implicit 'dart:core' declarations.
    if ('${_container.source.uri}' == 'dart:core') {
      _addGetter(DynamicElementImpl.instance);
      _addGetter(NeverElementImpl.instance);
    }

    extensions = extensions.toFixedList();
  }

  void _addExtension(ExtensionElement element) {
    if (element.isAugmentation) {
      return;
    }

    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }

  void _addUnitElements(CompilationUnitElement compilationUnit) {
    for (var element in compilationUnit.accessors) {
      if (element.augmentation == null) {
        _addPropertyAccessor(element);
      }
    }

    for (var element in compilationUnit.functions) {
      if (element.augmentation == null) {
        _addGetter(element);
      }
    }

    compilationUnit.enums.forEach(_addGetter);
    compilationUnit.extensions.forEach(_addExtension);
    compilationUnit.extensionTypes.forEach(_addGetter);
    compilationUnit.typeAliases.forEach(_addGetter);
    compilationUnit.mixins.forEach(_addGetter);
    compilationUnit.classes.forEach(_addGetter);
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
  final LibraryOrAugmentationElementImpl _container;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};
  Set<String>? _settersFromDeprecatedExport;
  Set<String>? _gettersFromDeprecatedExport;
  final Set<ExtensionElement> _extensions = {};
  LibraryElement? _deferredLibrary;

  PrefixScope(this._container, PrefixElement? prefix) {
    var elementFactory = _container.session.elementFactory;
    for (var import in _container.libraryImports) {
      var importedUri = import.uri;
      if (importedUri is DirectiveUriWithLibrary &&
          import.prefix?.element == prefix) {
        var importedLibrary = importedUri.library;
        if (importedLibrary is LibraryElementImpl) {
          var combinators = import.combinators.build();
          for (var exportedReference in importedLibrary.exportedReferences) {
            var reference = exportedReference.reference;
            if (combinators.allows(reference.name)) {
              var element = elementFactory.elementOfReference(reference)!;
              if (_shouldAdd(importedLibrary, element)) {
                _add(
                  element,
                  importedLibrary.isFromDeprecatedExport(exportedReference),
                );
              }
            }
          }
          if (import.prefix is DeferredImportElementPrefix) {
            _deferredLibrary ??= importedLibrary;
          }
        }
      }
    }
  }

  @override
  ScopeLookupResult lookup(String id) {
    var deferredLibrary = _deferredLibrary;
    if (deferredLibrary != null && id == FunctionElement.LOAD_LIBRARY_NAME) {
      return ScopeLookupResultImpl(deferredLibrary.loadLibraryFunction, null);
    }

    return PrefixScopeLookupResult(
        _getters[id],
        _setters[id],
        _gettersFromDeprecatedExport?.contains(id) ?? false,
        _settersFromDeprecatedExport?.contains(id) ?? false);
  }

  void _add(Element element, bool isFromDeprecatedExport) {
    if (element is PropertyAccessorElement && element.isSetter) {
      _addTo(element, isFromDeprecatedExport, isSetter: true);
    } else {
      _addTo(element, isFromDeprecatedExport, isSetter: false);
      if (element is ExtensionElement) {
        _extensions.add(element);
      }
    }
  }

  void _addTo(Element element, bool isDeprecatedExport,
      {required bool isSetter}) {
    var map = isSetter ? _setters : _getters;
    var id = element.displayName;
    var existing = map[id];

    if (existing == null) {
      map[id] = element;
      if (isDeprecatedExport) {
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
      if (wasFromDeprecatedExport && !isDeprecatedExport) {
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
      _container.context,
      _container.session,
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
    if (!_container.featureSet.isEnabled(Feature.records)) {
      if (importedLibrary.isInSdk &&
          element is ClassElementImpl &&
          element.isDartCoreRecord) {
        return false;
      }
    }
    return true;
  }

  static void _addElement(
    Set<Element> conflictingElements,
    Element element,
  ) {
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

  PrefixScopeLookupResult(
    super.importedGetter,
    super.importedSetter,
    bool getterIsFromDeprecatedExport,
    bool setterIsFromDeprecatedExport,
  ) : _deprecatedBits = (getterIsFromDeprecatedExport
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

class ScopeLookupResultImpl implements ScopeLookupResult {
  @override
  final Element? getter;

  @override
  final Element? setter;

  ScopeLookupResultImpl(this.getter, this.setter);
}

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(
    super.parent,
    List<TypeParameterElement> elements,
  ) {
    elements.forEach(_addGetter);
  }
}

mixin _GettersAndSetters {
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  void _addGetter(Element element) {
    var id = element.name;
    if (id != null) {
      _getters[id] ??= element;
    }
  }

  void _addPropertyAccessor(PropertyAccessorElement element) {
    if (element.isGetter) {
      _addGetter(element);
    } else {
      _addSetter(element);
    }
  }

  void _addSetter(Element element) {
    var name = element.name;
    if (name != null && name.endsWith('=')) {
      var id = considerCanonicalizeString(name.substring(0, name.length - 1));
      _setters[id] ??= element;
    }
  }
}

class _LibraryOrAugmentationImportScope implements Scope {
  final LibraryOrAugmentationElementImpl _container;
  final PrefixScope _nullPrefixScope;
  List<ExtensionElement>? _extensions;

  _LibraryOrAugmentationImportScope(LibraryOrAugmentationElementImpl container)
      : _container = container,
        _nullPrefixScope = PrefixScope(container, null);

  List<ExtensionElement> get extensions {
    return _extensions ??= {
      ..._nullPrefixScope._extensions,
      for (var prefix in _container.prefixes)
        ...(prefix.scope as PrefixScope)._extensions,
    }.toFixedList();
  }

  @override
  ScopeLookupResult lookup(String id) {
    return _nullPrefixScope.lookup(id);
  }
}

extension on Element {
  bool get isWildcardVariable =>
      name == '_' &&
      (this is LocalVariableElement || this is ParameterElement) &&
      (library?.featureSet.isEnabled(Feature.wildcard_variables) ?? false);
}
