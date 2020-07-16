// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart' as impl;
import 'package:meta/meta.dart';

class LibraryScope implements Scope {
  final LibraryElement _libraryElement;
  final impl.LibraryScope _implScope;

  LibraryScope(LibraryElement libraryElement)
      : _libraryElement = libraryElement,
        _implScope = impl.LibraryScope(libraryElement);

  @Deprecated('Use lookup2() that is closer to the language specification')
  @override
  Element lookup({@required String id, @required bool setter}) {
    var name = setter ? '$id=' : id;
    var token = SyntheticStringToken(TokenType.IDENTIFIER, name, 0);
    var identifier = astFactory.simpleIdentifier(token);
    return _implScope.lookup(identifier, _libraryElement);
  }

  @override
  ScopeLookupResult lookup2(String id) {
    // ignore: deprecated_member_use_from_same_package
    var getter = lookup(id: id, setter: false);
    // ignore: deprecated_member_use_from_same_package
    var setter = lookup(id: id, setter: true);
    return ScopeLookupResult(getter, setter);
  }
}

class PrefixScope implements Scope {
  final PrefixElement _element;
  final Map<String, Element> _getters = {};
  final Map<String, Element> _setters = {};

  PrefixScope(this._element) {
    for (var import in _element.enclosingElement.imports) {
      if (import.prefix == _element) {
        var elements = impl.NamespaceBuilder().getImportedElements(import);
        elements.forEach(_add);
      }
    }
  }

  @Deprecated('Use lookup2() that is closer to the language specification')
  @override
  Element lookup({@required String id, @required bool setter}) {
    var map = setter ? _setters : _getters;
    return map[id];
  }

  @override
  ScopeLookupResult lookup2(String id) {
    var getter = _getters[id];
    var setter = _setters[id];
    return ScopeLookupResult(getter, setter);
  }

  void _add(Element element) {
    var setter = element is PropertyAccessorElement && element.isSetter;
    _addTo(
      map: setter ? _setters : _getters,
      element: element,
    );
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

    var definingLibrary = _element.enclosingElement;
    return MultiplyDefinedElementImpl(
      definingLibrary.context,
      definingLibrary.session,
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
    if (element is NeverElementImpl) {
      return true;
    }
    return element.library.isInSdk;
  }
}
