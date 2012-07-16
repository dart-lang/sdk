// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors.util');

#import('mirrors.dart');

//------------------------------------------------------------------------------
// Utility functions for using the Mirror API
//------------------------------------------------------------------------------

/**
 * Returns an iterable over the type declarations directly inheriting from
 * the declaration of this type.
 */
Iterable<InterfaceMirror> computeSubdeclarations(MirrorSystem system,
                                                 InterfaceMirror type) {
  type = type.declaration;
  var subtypes = <InterfaceMirror>[];
  system.libraries().forEach((_, library) {
    for (InterfaceMirror otherType in library.types().getValues()) {
      var superClass = otherType.superclass();
      if (superClass !== null) {
        superClass = superClass.declaration;
        if (type.library() === superClass.library()) {
          if (superClass == type) {
             subtypes.add(otherType);
          }
        }
      }
      final superInterfaces = otherType.interfaces().getValues();
      for (InterfaceMirror superInterface in superInterfaces) {
        superInterface = superInterface.declaration;
        if (type.library() === superInterface.library()) {
          if (superInterface == type) {
            subtypes.add(otherType);
          }
        }
      }
    }
  });
  return subtypes;
}

/**
 * Finds the mirror in [map] by the simple name [name]. If [constructorName] or
 * [operatorName] is provided, a constructor/operator method by that name is
 * returned.
 */
Mirror findMirror(Map<Object,Mirror> map, String name,
                  [String constructorName, String operatorName]) {
  var foundMirror = null;
  map.forEach((_, Mirror mirror) {
    if (mirror.simpleName() == name) {
      if (constructorName !== null) {
        if (mirror is MethodMirror &&
            constructorName == mirror.constructorName) {
          foundMirror = mirror;
        }
      } else if (operatorName !== null) {
        if (mirror is MethodMirror &&
            operatorName == mirror.operatorName) {
          foundMirror = mirror;
        }
      } else {
        foundMirror = mirror;
      }
    }
  });
  return foundMirror;
}
