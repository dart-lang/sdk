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
List<VariableMirror> publicFields(ClassMirror mirror) {
  var mine = mirror.variables.values.filter(
      (x) => !(x.isPrivate || x.isStatic));
  var mySuperclass = mirror.superclass;
  if (mySuperclass != mirror) {
    return append(publicFields(mirror.superclass), mine);
  } else {
    return mine;
  }
}

/**
 * Return a list of all the public getters of a class, including inherited
 * getters.
 */
List<MethodMirror> publicGetters(ClassMirror mirror) {
  var mine = mirror.getters.values.filter((x) => !(x.isPrivate || x.isStatic));
  var mySuperclass = mirror.superclass;
  if (mySuperclass != mirror) {
    return append(publicGetters(mirror.superclass), mine);
  } else {
    return mine;
  }
}

/**
 * Return a list of all the public getters of a class which have corresponding
 * setters.
 */
List<MethodMirror> publicGettersWithMatchingSetters(ClassMirror mirror) {
  var setters = mirror.setters;
  return publicGetters(mirror).filter((each) =>
    setters["${each.simpleName}="] != null);
}

/**
 * A particularly bad case of polyfill, because we cannot yet use type names
 * as literals, so we have to be passed an instance and then extract a
 * ClassMirror from that. Given a horrible name as an extra reminder to fix it.
 */
ClassMirror turnInstanceIntoSomethingWeCanUse(x) => reflect(x).type;

/**
 * This is polyfill because we can't hash ClassMirror right now. We
 * don't bother implementing most of its methods because we don't need them.
 */
// TODO(alanknight): Remove this when you can hash mirrors directly
class ClassMirrorWrapper implements ClassMirror {
  ClassMirror mirror;
  ClassMirrorWrapper(this.mirror);
  get simpleName => mirror.simpleName;
  get hashCode => simpleName.hashCode;
  operator ==(x) => x is ClassMirror && simpleName == x.simpleName;
}