// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

/// Dartium ElementUpgrader implementation.
class _VMElementUpgrader implements ElementUpgrader {
  final Type _type;
  final Type _nativeType;
  final String _extendsTag;

  _VMElementUpgrader(Document document, Type type, String extendsTag)
      : _type = type,
        _extendsTag = extendsTag,
        _nativeType = _validateCustomType(type).reflectedType {
    if (extendsTag == null) {
      if (_nativeType != HtmlElement) {
        throw new UnsupportedError('Class must provide extendsTag if base '
            'native class is not HtmlElement');
      }
    } else {
      if (document.createElement(extendsTag).runtimeType != _nativeType) {
        throw new UnsupportedError(
            'extendsTag does not match base native class');
      }
    }
  }

  Element upgrade(element) {
    // Only exact type matches are supported- cannot be a subclass.
    if (element.runtimeType != _nativeType) {
      throw new ArgumentError('element is not subclass of $_nativeType');
    }
    return _createCustomUpgrader(_type, element);
  }
}

/// Validates that the custom type is properly formed-
///
/// * Is a user-defined class.
/// * Has a created constructor with zero args.
/// * Derives from an Element subclass.
///
/// Then returns the native base class.
ClassMirror _validateCustomType(Type type) {
  ClassMirror cls = reflectClass(type);
  if (_isBuiltinType(cls)) {
    throw new UnsupportedError('Invalid custom element from '
        '${(cls.owner as LibraryMirror).uri}.');
  }

  var className = MirrorSystem.getName(cls.simpleName);
  if (cls.isAbstract) {
    throw new UnsupportedError('Invalid custom element '
        'class $className is abstract.');
  }

  var createdConstructor = cls.declarations[new Symbol('$className.created')];
  if (createdConstructor == null ||
      createdConstructor is! MethodMirror ||
      !createdConstructor.isConstructor) {
    throw new UnsupportedError(
        'Class is missing constructor $className.created');
  }

  if (createdConstructor.parameters.length > 0) {
    throw new UnsupportedError(
        'Constructor $className.created must take zero arguments');
  }

  Symbol objectName = reflectClass(Object).qualifiedName;
  bool isRoot(ClassMirror cls) =>
      cls == null || cls.qualifiedName == objectName;
  Symbol elementName = reflectClass(HtmlElement).qualifiedName;
  bool isElement(ClassMirror cls) =>
      cls != null && cls.qualifiedName == elementName;
  ClassMirror superClass = cls.superclass;
  ClassMirror nativeClass = _isBuiltinType(superClass) ? superClass : null;
  while (!isRoot(superClass) && !isElement(superClass)) {
    superClass = superClass.superclass;
    if (nativeClass == null && _isBuiltinType(superClass)) {
      nativeClass = superClass;
    }
  }
  return nativeClass;
}

bool _isBuiltinType(ClassMirror cls) {
  // TODO(vsm): Find a less hackish way to do this.
  LibraryMirror lib = cls.owner;
  String libName = lib.uri.toString();
  return libName.startsWith('dart:');
}
