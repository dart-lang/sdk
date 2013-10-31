// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provides some additional convenience methods on top of the basic mirrors
 */
library mirrors_helpers;

// Import and re-export mirrors here to minimize both dependence on mirrors
// and the number of times we have to be told that mirrors aren't finished yet.
import 'dart:mirrors';
export 'dart:mirrors';
import 'serialization_helpers.dart';

// TODO(alanknight): Remove this method.  It is working around a bug
// in the Dart VM which incorrectly returns Object as the superclass
// of Object.
_getSuperclass(ClassMirror mirror) {
  var superclass = mirror.superclass;
  return (superclass == mirror) ? null : superclass;
}

/**
 * Return a list of all the public fields of a class, including inherited
 * fields.
 */
Iterable<VariableMirror> publicFields(ClassMirror mirror) {
  var mine = mirror.declarations.values.where(
      (x) => x is VariableMirror && !(x.isPrivate || x.isStatic));
  var mySuperclass = _getSuperclass(mirror);
  if (mySuperclass != null) {
    return append(publicFields(mySuperclass), mine);
  } else {
    return new List<VariableMirror>.from(mine);
  }
}

/** Return true if the class has a field named [name]. Note that this
 * includes private fields, but excludes statics. */
bool hasField(Symbol name, ClassMirror mirror) {
  if (name == null) return false;
  var field = mirror.declarations[name];
  if (field is VariableMirror && !field.isStatic) return true;
  var superclass = _getSuperclass(mirror);
  if (superclass == null) return false;
  return hasField(name, superclass);
}

/**
 * Return a list of all the getters of a class, including inherited
 * getters. Note that this allows private getters, but excludes statics.
 */
Iterable<MethodMirror> publicGetters(ClassMirror mirror) {
  var mine = mirror.declarations.values.where(
      (x) => x is MethodMirror && x.isGetter && !(x.isPrivate || x.isStatic));
  var mySuperclass = _getSuperclass(mirror);
  if (mySuperclass != null) {
    return append(publicGetters(mySuperclass), mine);
  } else {
    return new List<MethodMirror>.from(mine);
  }
}

/** Return true if the class has a getter named [name] */
bool hasGetter(Symbol name, ClassMirror mirror) {
  if (name == null) return false;
  var getter = mirror.declarations[name];
  if (getter is MethodMirror && getter.isGetter && !getter.isStatic) {
    return true;
  }
  var superclass = _getSuperclass(mirror);
  if (superclass == null) return false;
  return hasField(name, superclass);
}

/**
 * Return a list of all the public getters of a class which have corresponding
 * setters.
 */
Iterable<MethodMirror> publicGettersWithMatchingSetters(ClassMirror mirror) {
  var declarations = mirror.declarations;
  return publicGetters(mirror).where((each) =>
    // TODO(alanknight): Use new Symbol here?
    declarations["${each.simpleName}="] != null);
}

/**
 * Given either an instance or a type, returns the type. Instances of Type
 * will be treated as types. Passing in an instance is really just backward
 * compatibility.
 */
ClassMirror turnInstanceIntoSomethingWeCanUse(x) {
  if (x is Type) return reflectClass(x);
  return reflect(x).type;
}
