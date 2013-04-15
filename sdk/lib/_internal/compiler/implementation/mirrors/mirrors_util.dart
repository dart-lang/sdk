// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors_util;

import 'dart:collection' show Queue, IterableBase;

// TODO(rnystrom): Use "package:" URL (#4968).
import 'mirrors.dart';

//------------------------------------------------------------------------------
// Utility functions for using the Mirror API
//------------------------------------------------------------------------------

/**
 * Returns an iterable over the type declarations directly inheriting from
 * the declaration of this type.
 */
Iterable<ClassMirror> computeSubdeclarations(ClassMirror type) {
  type = type.originalDeclaration;
  var subtypes = <ClassMirror>[];
  type.mirrors.libraries.forEach((_, library) {
    for (ClassMirror otherType in library.classes.values) {
      var superClass = otherType.superclass;
      if (superClass != null) {
        superClass = superClass.originalDeclaration;
        if (type.library == superClass.library) {
          if (superClass == type) {
             subtypes.add(otherType);
          }
        }
      }
      final superInterfaces = otherType.superinterfaces;
      for (ClassMirror superInterface in superInterfaces) {
        superInterface = superInterface.originalDeclaration;
        if (type.library == superInterface.library) {
          if (superInterface == type) {
            subtypes.add(otherType);
          }
        }
      }
    }
  });
  return subtypes;
}

LibraryMirror findLibrary(MemberMirror member) {
  DeclarationMirror owner = member.owner;
  if (owner is LibraryMirror) {
    return owner;
  } else if (owner is TypeMirror) {
    return owner.library;
  }
  throw new Exception('Unexpected owner: ${owner}');
}

class HierarchyIterable extends IterableBase<ClassMirror> {
  final bool includeType;
  final ClassMirror type;

  HierarchyIterable(this.type, {bool includeType})
      : this.includeType = includeType;

  Iterator<ClassMirror> get iterator =>
      new HierarchyIterator(type, includeType: includeType);
}

/**
 * [HierarchyIterator] iterates through the class hierarchy of the provided
 * type.
 *
 * First the superclass relation is traversed, skipping [Object], next the
 * superinterface relation and finally is [Object] visited. The supertypes are
 * visited in breadth first order and a superinterface is visited more than once
 * if implemented through multiple supertypes.
 */
class HierarchyIterator implements Iterator<ClassMirror> {
  final Queue<ClassMirror> queue = new Queue<ClassMirror>();
  ClassMirror object;
  ClassMirror _current;

  HierarchyIterator(ClassMirror type, {bool includeType}) {
    if (includeType) {
      queue.add(type);
    } else {
      push(type);
    }
  }

  ClassMirror push(ClassMirror type) {
    if (type.superclass != null) {
      if (type.superclass.isObject) {
        object = type.superclass;
      } else {
        queue.addFirst(type.superclass);
      }
    }
    queue.addAll(type.superinterfaces);
    return type;
  }

  ClassMirror get current => _current;

  bool moveNext() {
    _current = null;
    if (queue.isEmpty) {
      if (object == null) return false;
      _current = object;
      object = null;
      return true;
    } else {
      _current = push(queue.removeFirst());
      return true;
    }
  }
}

final RegExp _singleLineCommentStart = new RegExp(r'^///? ?(.*)');
final RegExp _multiLineCommentStartEnd =
    new RegExp(r'^/\*\*? ?([\s\S]*)\*/$', multiLine: true);
final RegExp _multiLineCommentLineStart = new RegExp(r'^[ \t]*\* ?(.*)');

/**
 * Pulls the raw text out of a comment (i.e. removes the comment
 * characters).
 */
String stripComment(String comment) {
  Match match = _singleLineCommentStart.firstMatch(comment);
  if (match != null) {
    return match[1];
  }
  match = _multiLineCommentStartEnd.firstMatch(comment);
  if (match != null) {
    comment = match[1];
    var sb = new StringBuffer();
    List<String> lines = comment.split('\n');
    for (int index = 0 ; index < lines.length ; index++) {
      String line = lines[index];
      if (index == 0) {
        sb.write(line); // Add the first line unprocessed.
        continue;
      }
      sb.write('\n');
      match = _multiLineCommentLineStart.firstMatch(line);
      if (match != null) {
        sb.write(match[1]);
      } else if (index < lines.length-1 || !line.trim().isEmpty) {
        // Do not add the last line if it only contains white space.
        // This interprets cases like
        //     /*
        //      * Foo
        //      */
        // as "\nFoo\n" and not as "\nFoo\n     ".
        sb.write(line);
      }
    }
    return sb.toString();
  }
  throw new ArgumentError('Invalid comment $comment');
}
