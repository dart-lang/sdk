// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('mirrors.util');

#import('mirrors.dart');
#import('../../compiler/implementation/util/characters.dart');

//------------------------------------------------------------------------------
// Utility functions for using the Mirror API
//------------------------------------------------------------------------------

/**
 * Returns an iterable over the type declarations directly inheriting from
 * the declaration of this type.
 */
Iterable<InterfaceMirror> computeSubdeclarations(InterfaceMirror type) {
  type = type.declaration;
  var subtypes = <InterfaceMirror>[];
  type.system.libraries.forEach((_, library) {
    for (InterfaceMirror otherType in library.types.getValues()) {
      var superClass = otherType.superclass;
      if (superClass !== null) {
        superClass = superClass.declaration;
        if (type.library === superClass.library) {
          if (superClass == type) {
             subtypes.add(otherType);
          }
        }
      }
      final superInterfaces = otherType.interfaces.getValues();
      for (InterfaceMirror superInterface in superInterfaces) {
        superInterface = superInterface.declaration;
        if (type.library === superInterface.library) {
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
    if (mirror.simpleName == name) {
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

LibraryMirror findLibrary(MemberMirror member) {
  ObjectMirror owner = member.surroundingDeclaration;
  if (owner is LibraryMirror) {
    return owner;
  } else if (owner is TypeMirror) {
    return owner.library;
  }
  throw new Exception('Unexpected owner: ${owner}');
}


/**
 * Returns the column of the start of a location.
 */
int getLocationColumn(Location location) {
  String text = location.source.text;
  int index = location.start-1;
  var column = 0;
  while (0 <= index && index < text.length) {
    var charCode = text.charCodeAt(index);
    if (charCode == $CR || charCode == $LF) {
      break;
    }
    index--;
    column++;
  }
  return column;
}
