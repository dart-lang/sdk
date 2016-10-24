// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashSet;

import 'package:analyzer/dart/ast/ast.dart' show Identifier;
import 'package:analyzer/dart/element/element.dart';

class PropertyOverrideResult {
  final bool foundGetter;
  final bool foundSetter;

  PropertyOverrideResult(this.foundGetter, this.foundSetter);
}

PropertyOverrideResult checkForPropertyOverride(
    FieldElement field, List<ClassElement> superclasses) {
  bool foundGetter = false;
  bool foundSetter = false;

  for (var superclass in superclasses) {
    var superprop = getProperty(superclass, field.library, field.name);
    if (superprop == null) continue;

    var getter = superprop.getter;
    bool hasGetter = getter != null && !getter.isAbstract;
    if (hasGetter) foundGetter = true;

    var setter = superprop.setter;
    bool hasSetter = setter != null && !setter.isAbstract;
    if (hasSetter) foundSetter = true;
  }

  return new PropertyOverrideResult(foundGetter, foundSetter);
}

FieldElement getProperty(
    ClassElement cls, LibraryElement fromLibrary, String name) {
  // Properties from a different library are not accessible.
  if (Identifier.isPrivateName(name) && cls.library != fromLibrary) {
    return null;
  }
  for (var accessor in cls.accessors) {
    var prop = accessor.variable;
    if (prop.name == name) return prop;
  }
  return null;
}

List<ClassElement> getSuperclasses(ClassElement cls) {
  var result = <ClassElement>[];
  var visited = new HashSet<ClassElement>();
  while (cls != null && visited.add(cls)) {
    for (var mixinType in cls.mixins.reversed) {
      var mixin = mixinType.element;
      if (mixin != null) result.add(mixin);
    }
    var supertype = cls.supertype;
    if (supertype == null) break;

    cls = supertype.element;
    result.add(cls);
  }
  return result;
}
