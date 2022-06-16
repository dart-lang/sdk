// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/combinator.dart';

/// The scope defined by a class.
class ClassScope extends EnclosedScope {
  ClassScope(super.parent, ClassElement element) {
    element.accessors.forEach(_addPropertyAccessor);
    element.methods.forEach(_addGetter);
  }
}

/// The scope for the initializers in a constructor.
class ConstructorInitializerScope extends EnclosedScope {
  ConstructorInitializerScope(super.parent, ConstructorElement element) {
    element.parameters.forEach(_addGetter);
  }
}

/// A scope that is lexically enclosed in another scope.
class EnclosedScope implements Scope {
  final Scope _parent;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  EnclosedScope(Scope parent) : _parent = parent;

  Scope get parent => _parent;

  @override
  ScopeLookupResult lookup(String id) {
    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      return ScopeLookupResult(getter, setter);
    }

    return _parent.lookup(id);
  }

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
      var id = name.substring(0, name.length - 1);
      _setters[id] ??= element;
    }
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
        _addGetter(parameter);
      }
    }
  }
}

class LibraryScope extends EnclosedScope {
  final LibraryElement _element;
  final List<ExtensionElement> extensions = [];

  LibraryScope(LibraryElement element)
      : _element = element,
        super(_LibraryImportScope(element)) {
    extensions.addAll((_parent as _LibraryImportScope).extensions);

    _element.prefixes.forEach(_addGetter);
    _element.units.forEach(_addUnitElements);
  }

  void _addExtension(ExtensionElement element) {
    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }

  void _addUnitElements(CompilationUnitElement compilationUnit) {
    compilationUnit.accessors.forEach(_addPropertyAccessor);
    compilationUnit.enums.forEach(_addGetter);
    compilationUnit.extensions.forEach(_addExtension);
    compilationUnit.functions.forEach(_addGetter);
    compilationUnit.typeAliases.forEach(_addGetter);
    compilationUnit.mixins.forEach(_addGetter);
    compilationUnit.classes.forEach(_addGetter);
  }
}

class LocalScope extends EnclosedScope {
  LocalScope(super.parent);

  void add(Element element) {
    _addGetter(element);
  }
}

class PrefixScope implements Scope {
  final LibraryOrAugmentationElement _library;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};
  final Set<ExtensionElement> _extensions = {};
  LibraryElement? _deferredLibrary;

  PrefixScope(this._library, PrefixElement? prefix) {
    for (var import in _library.imports) {
      if (import.prefix == prefix) {
        final importedLibrary = import.importedLibrary;
        if (importedLibrary is LibraryElementImpl) {
          // TODO(scheglov) Ask it from `_library`.
          final elementFactory = importedLibrary.session.elementFactory;
          final combinators = import.combinators.build();
          for (final exportedReference in importedLibrary.exportedReferences) {
            final reference = exportedReference.reference;
            if (combinators.allows(reference.name)) {
              final element = elementFactory.elementOfReference(reference)!;
              _add(element);
            }
          }
          if (import.isDeferred) {
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
      return ScopeLookupResult(deferredLibrary.loadLibraryFunction, null);
    }

    var getter = _getters[id];
    var setter = _setters[id];
    return ScopeLookupResult(getter, setter);
  }

  void _add(Element element) {
    if (element is PropertyAccessorElement && element.isSetter) {
      _addTo(map: _setters, element: element);
    } else {
      _addTo(map: _getters, element: element);
      if (element is ExtensionElement) {
        _extensions.add(element);
      }
    }
  }

  void _addTo({
    required Map<String, Element> map,
    required Element element,
  }) {
    var id = element.displayName;

    var existing = map[id];
    if (existing != null && existing != element) {
      map[id] = _merge(existing, element);
      return;
    }

    map[id] = element;
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
      _library.context,
      _library.session,
      conflictingElements.first.name!,
      conflictingElements.toList(),
    );
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

class TypeParameterScope extends EnclosedScope {
  TypeParameterScope(
    super.parent,
    List<TypeParameterElement> elements,
  ) {
    elements.forEach(_addGetter);
  }
}

class _LibraryImportScope implements Scope {
  final LibraryElement _library;
  final PrefixScope _nullPrefixScope;
  List<ExtensionElement>? _extensions;

  _LibraryImportScope(LibraryElement library)
      : _library = library,
        _nullPrefixScope = PrefixScope(library, null);

  List<ExtensionElement> get extensions {
    return _extensions ??= {
      ..._nullPrefixScope._extensions,
      for (var prefix in _library.prefixes)
        ...(prefix.scope as PrefixScope)._extensions,
    }.toList();
  }

  @override
  ScopeLookupResult lookup(String id) {
    return _nullPrefixScope.lookup(id);
  }
}
