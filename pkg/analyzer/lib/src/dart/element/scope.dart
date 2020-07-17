// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart' as impl;
import 'package:meta/meta.dart';

/// A scope that is lexically enclosed in another scope.
class EnclosedScope implements Scope {
  final Scope _parent;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  EnclosedScope(Scope parent) : _parent = parent;

  @Deprecated('Use lookup2() that is closer to the language specification')
  @override
  Element lookup({@required String id, @required bool setter}) {
    var result = lookup2(id);
    return setter ? result.setter : result.getter;
  }

  @override
  ScopeLookupResult lookup2(String id) {
    var getter = _getters[id];
    var setter = _setters[id];
    if (getter != null || setter != null) {
      return ScopeLookupResult(getter, setter);
    }

    return _parent.lookup2(id);
  }

  void _addGetter(Element element) {
    _addTo(_getters, element);
  }

  void _addPropertyAccessor(PropertyAccessorElement element) {
    if (element.isGetter) {
      _addGetter(element);
    } else {
      _addSetter(element);
    }
  }

  void _addSetter(Element element) {
    _addTo(_setters, element);
  }

  void _addTo(Map<String, Element> map, Element element) {
    var id = element.displayName;
    map[id] ??= element;
  }
}

class LibraryScope extends EnclosedScope {
  final List<ExtensionElement> extensions = [];

  LibraryScope(LibraryElement library) : super(_LibraryImportScope(library)) {
    extensions.addAll((_parent as _LibraryImportScope).extensions);
    _defineTopLevelElements(library);
  }

  void _addExtension(ExtensionElement element) {
    _addGetter(element);
    if (!extensions.contains(element)) {
      extensions.add(element);
    }
  }

  void _defineLocalNames(CompilationUnitElement compilationUnit) {
    compilationUnit.accessors.forEach(_addPropertyAccessor);
    compilationUnit.enums.forEach(_addGetter);
    compilationUnit.extensions.forEach(_addExtension);
    compilationUnit.functions.forEach(_addGetter);
    compilationUnit.functionTypeAliases.forEach(_addGetter);
    compilationUnit.mixins.forEach(_addGetter);
    compilationUnit.types.forEach(_addGetter);
  }

  void _defineTopLevelElements(LibraryElement library) {
    library.prefixes.forEach(_addGetter);
    library.units.forEach(_defineLocalNames);
  }
}

class PrefixScope implements Scope {
  final LibraryElement _library;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};
  final Set<ExtensionElement> _extensions = {};

  PrefixScope(this._library, PrefixElement prefix) {
    for (var import in _library.imports) {
      if (import.prefix == prefix) {
        var elements = impl.NamespaceBuilder().getImportedElements(import);
        elements.forEach(_add);
      }
    }
  }

  @Deprecated('Use lookup2() that is closer to the language specification')
  @override
  Element lookup({@required String id, @required bool setter}) {
    var result = lookup2(id);
    return setter ? result.setter : result.getter;
  }

  @override
  ScopeLookupResult lookup2(String id) {
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
    @required Map<String, Element> map,
    @required Element element,
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
      conflictingElements.first.name,
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
    return element.library.isInSdk;
  }
}

class _LibraryImportScope implements Scope {
  final LibraryElement _library;
  final PrefixScope _nullPrefixScope;
  List<ExtensionElement> _extensions;

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

  @Deprecated('Use lookup2() that is closer to the language specification')
  @override
  Element lookup({@required String id, @required bool setter}) {
    throw UnimplementedError();
  }

  @override
  ScopeLookupResult lookup2(String id) {
    return _nullPrefixScope.lookup2(id);
  }
}
