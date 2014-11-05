// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirrors_util;

import 'dart:collection' show Queue, IterableBase;

import 'source_mirrors.dart';

//------------------------------------------------------------------------------
// Utility functions for using the Mirror API
//------------------------------------------------------------------------------

String nameOf(DeclarationMirror mirror) =>
    MirrorSystem.getName(mirror.simpleName);

String qualifiedNameOf(DeclarationMirror mirror) =>
    MirrorSystem.getName(mirror.qualifiedName);

// TODO(johnniwinther): Handle private names.
Symbol symbolOf(String name, [LibraryMirror library]) => new Symbol(name);

/**
 * Return the display name for [mirror].
 *
 * The display name is the normal representation of the entity name. In most
 * cases the display name is the simple name, but for a setter 'foo=' the
 * display name is simply 'foo' and for the unary minus operator the display
 * name is 'operator -'. For 'dart:' libraries the display name is the URI and
 * not the library name, for instance 'dart:core' instead of 'dart.core'.
 *
 * The display name is not unique.
 */
String displayName(DeclarationMirror mirror) {
  if (mirror is LibraryMirror) {
    LibraryMirror library = mirror;
    if (library.uri.scheme == 'dart') {
      return library.uri.toString();
    }
  } else if (mirror is MethodMirror) {
    String simpleName = nameOf(mirror);
    if (mirror.isSetter) {
      // Remove trailing '='.
      return simpleName.substring(0, simpleName.length-1);
    } else if (mirror.isOperator) {
      return 'operator ${operatorName(mirror)}';
    } else if (mirror.isConstructor) {
      String className = displayName(mirror.owner);
      if (simpleName == '') {
        return className;
      } else {
        return '$className.$simpleName';
      }
    }
  }
  return MirrorSystem.getName(mirror.simpleName);
}

/**
 * Returns the operator name if [methodMirror] is an operator method,
 * for instance [:'<':] for [:operator <:] and [:'-':] for the unary minus
 * operator. Return [:null:] if [methodMirror] is not an operator method.
 */
String operatorName(MethodMirror methodMirror) {
  if (methodMirror.isOperator) {
    if (methodMirror.simpleName == const Symbol('unary-')) {
      return '-';
    } else {
      return nameOf(methodMirror);
    }
  }
  return null;
}

/**
 * Returns an iterable over the type declarations directly inheriting from
 * the declaration of [type] within [mirrors].
 */
Iterable<ClassMirror> computeSubdeclarations(MirrorSystem mirrors,
                                             ClassMirror type) {
  type = type.originalDeclaration;
  var subtypes = <ClassMirror>[];
  mirrors.libraries.forEach((_, library) {
    library.declarations.values
        .where((mirror) => mirror is ClassMirror)
        .forEach((ClassMirror otherType) {
      var superClass = otherType.superclass;
      if (superClass != null) {
        superClass = superClass.originalDeclaration;
        if (superClass == type) {
          subtypes.add(otherType);
        }
      }
      final superInterfaces = otherType.superinterfaces;
      for (ClassMirror superInterface in superInterfaces) {
        superInterface = superInterface.originalDeclaration;
        if (superInterface == type) {
          subtypes.add(otherType);
        }
      }
    });
  });
  return subtypes;
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
      if (isObject(type.superclass)) {
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

LibraryMirror getLibrary(DeclarationMirror declaration) {
  while (declaration != null && declaration is! LibraryMirror) {
    declaration = declaration.owner;
  }
  return declaration;
}

Iterable<DeclarationMirror> membersOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return declarations.values.where(
      (mirror) => mirror is MethodMirror || mirror is VariableMirror);
}

Iterable<TypeMirror> classesOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return new _TypeOfIterable<ClassMirror>(declarations.values);
}

Iterable<TypeMirror> typesOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return new _TypeOfIterable<TypeMirror>(declarations.values);
}

Iterable<MethodMirror> methodsOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return anyMethodOf(declarations).where((mirror) => mirror.isRegularMethod);
}

Iterable<MethodMirror> constructorsOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return anyMethodOf(declarations).where((mirror) => mirror.isConstructor);
}

Iterable<MethodMirror> settersOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return anyMethodOf(declarations).where((mirror) => mirror.isSetter);
}

Iterable<MethodMirror> gettersOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return anyMethodOf(declarations).where((mirror) => mirror.isGetter);
}

Iterable<MethodMirror> anyMethodOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return new _TypeOfIterable<MethodMirror>(declarations.values);
}

Iterable<VariableMirror> variablesOf(
    Map<Symbol, DeclarationMirror> declarations) {
  return new _TypeOfIterable<VariableMirror>(declarations.values);
}

class _TypeOfIterable<T> extends IterableBase<T> {
  final Iterable _source;

  _TypeOfIterable(this._source);

  Iterator<T> get iterator => new _TypeOfIterator<T>(_source.iterator);
}

class _TypeOfIterator<T> implements Iterator<T> {
  final Iterator _source;

  T get current => _source.current;

  _TypeOfIterator(this._source);

  bool moveNext() {
    while(_source.moveNext()) {
      if (_source.current is T) {
        return true;
      }
    }
    return false;
  }
}

bool isObject(TypeMirror mirror) =>
    mirror is ClassMirror && mirror.superclass == null;

/// Returns `true` if [cls] is declared in a private dart library.
bool isFromPrivateDartLibrary(ClassMirror cls) {
  if (isMixinApplication(cls)) cls = cls.mixin;
  var uri = getLibrary(cls).uri;
  return uri.scheme == 'dart' && uri.path.startsWith('_');
}

/// Returns `true` if [mirror] reflects a mixin application.
bool isMixinApplication(Mirror mirror) {
  return mirror is ClassMirror && mirror.mixin != mirror;
}

/**
 * Returns the superclass of [cls] skipping unnamed mixin applications.
 *
 * For instance, for all of the following definitions this method returns [:B:].
 *
 *     class A extends B {}
 *     class A extends B with C1, C2 {}
 *     class A extends B implements D1, D2 {}
 *     class A extends B with C1, C2 implements D1, D2 {}
 *     class A = B with C1, C2;
 *     abstract class A = B with C1, C2 implements D1, D2;
 */
ClassSourceMirror getSuperclass(ClassSourceMirror cls) {
  ClassSourceMirror superclass = cls.superclass;
  while (isMixinApplication(superclass) && superclass.isNameSynthetic) {
    superclass = superclass.superclass;
  }
  return superclass;
}

/**
 * Returns the mixins directly applied to [cls].
 *
 * For instance, for all of the following definitions this method returns
 * [:C1, C2:].
 *
 *     class A extends B with C1, C2 {}
 *     class A extends B with C1, C2 implements D1, D2 {}
 *     class A = B with C1, C2;
 *     abstract class A = B with C1, C2 implements D1, D2;
 */
Iterable<ClassSourceMirror> getAppliedMixins(ClassSourceMirror cls) {
  List<ClassSourceMirror> mixins = <ClassSourceMirror>[];
  ClassSourceMirror superclass = cls.superclass;
  while (isMixinApplication(superclass) && superclass.isNameSynthetic) {
    mixins.add(superclass.mixin);
    superclass = superclass.superclass;
  }
  if (mixins.length > 1) {
    mixins = new List<ClassSourceMirror>.from(mixins.reversed);
  }
  if (isMixinApplication(cls)) {
    mixins.add(cls.mixin);
  }
  return mixins;
}

/**
 * Returns the superinterfaces directly and explicitly implemented by [cls].
 *
 * For instance, for all of the following definitions this method returns
 * [:D1, D2:].
 *
 *     class A extends B implements D1, D2 {}
 *     class A extends B with C1, C2 implements D1, D2 {}
 *     abstract class A = B with C1, C2 implements D1, D2;
 */
Iterable<ClassMirror> getExplicitInterfaces(ClassMirror cls) {
  if (isMixinApplication(cls)) {
    bool first = true;
    ClassMirror mixin = cls.mixin;
    bool filter(ClassMirror superinterface) {
      if (first && superinterface == mixin) {
        first = false;
        return false;
      }
      return true;
    }
    return cls.superinterfaces.where(filter);
  }
  return cls.superinterfaces;
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

/**
 * Looks up [name] in the scope [declaration].
 *
 * If [name] is of the form 'a.b.c', 'a' is looked up in the scope of
 * [declaration] and if unresolved 'a.b' is looked in the scope of
 * [declaration]. Each identifier of the remaining suffix, 'c' or 'b.c', is
 * then looked up in the local scope of the previous result.
 *
 * For instance, assumming that [:Iterable:] is imported into the scope of
 * [declaration] via the prefix 'col', 'col.Iterable.E' finds the type
 * variable of [:Iterable:] and 'col.Iterable.contains.element' finds the
 * [:element:] parameter of the [:contains:] method on [:Iterable:].
 */
DeclarationMirror lookupQualifiedInScope(DeclarationSourceMirror declaration,
                                         String name) {
  // TODO(11653): Support lookup of constructors using the [:new Foo:]
  // syntax.
  int offset = 1;
  List<String> parts = name.split('.');
  DeclarationMirror result = declaration.lookupInScope(parts[0]);
  if (result == null && parts.length > 1) {
    // Try lookup of `prefix.id`.
    result = declaration.lookupInScope('${parts[0]}.${parts[1]}');
    offset = 2;
  }
  if (result == null) return null;
  LibraryMirror library = getLibrary(result);
  while (result != null && offset < parts.length) {
    result = _lookupLocal(result, symbolOf(parts[offset++], library));
  }
  return result;
}

DeclarationMirror _lookupLocal(Mirror mirror, Symbol id) {
  DeclarationMirror result;
  if (mirror is LibraryMirror) {
    // Try member lookup.
    result = mirror.declarations[id];
  } else if (mirror is ClassMirror) {
    // Try member lookup.
    result = mirror.declarations[id];
    if (result != null) return result;
    // Try type variables.
    result = mirror.typeVariables.firstWhere(
        (TypeVariableMirror v) => v.simpleName == id, orElse: () => null);
  } else if (mirror is MethodMirror) {
    result = mirror.parameters.firstWhere(
        (ParameterMirror p) => p.simpleName == id, orElse: () => null);
  }
  return result;

}