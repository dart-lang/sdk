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

/**
 * Return a list of all the public fields of a class, including inherited
 * fields.
 */
Iterable<VariableMirror> publicFields(ClassMirror mirror) {
  var mine = mirror.variables.values.where(
      (x) => !(x.isPrivate || x.isStatic));
  var mySuperclass = mirror.superclass;
  if (mySuperclass != mirror) {
    return append(publicFields(mirror.superclass), mine);
  } else {
    return mine;
  }
}

/** Return true if the class has a field named [name]. Note that this
 * includes private fields, but excludes statics. */
bool hasField(String name, ClassMirror mirror) {
  var field = mirror.variables[name];
  if (field != null && !field.isStatic) return true;
  var superclass = mirror.superclass;
  if (superclass == mirror) return false;
  return hasField(name, superclass);
}

/**
 * Return a list of all the getters of a class, including inherited
 * getters. Note that this allows private getters, but excludes statics.
 */
Iterable<MethodMirror> publicGetters(ClassMirror mirror) {
  var mine = mirror.getters.values.where((x) => !(x.isPrivate || x.isStatic));
  var mySuperclass = mirror.superclass;
  if (mySuperclass != mirror) {
    return append(publicGetters(mirror.superclass), mine);
  } else {
    return mine.toList();
  }
}

/** Return true if the class has a getter named [name] */
bool hasGetter(String name, ClassMirror mirror) {
  var getter = mirror.getters[name];
  if (getter != null && !getter.isStatic) return true;
  var superclass = mirror.superclass;
  if (superclass == mirror) return false;
  return hasField(name, superclass);
}

/**
 * Return a list of all the public getters of a class which have corresponding
 * setters.
 */
Iterable<MethodMirror> publicGettersWithMatchingSetters(ClassMirror mirror) {
  var setters = mirror.setters;
  return publicGetters(mirror).where((each) =>
    setters["${each.simpleName}="] != null);
}

/**
 * A particularly bad case of polyfill, because we cannot yet use type names
 * as literals, so we have to be passed an instance and then extract a
 * ClassMirror from that. Given a horrible name as an extra reminder to fix it.
 */
ClassMirror turnInstanceIntoSomethingWeCanUse(x) => reflect(x).type;
