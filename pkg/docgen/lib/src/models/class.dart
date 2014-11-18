// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.clazz;

import '../exports/dart2js_mirrors.dart' as dart2js_mirrors;
import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'dummy_mirror.dart';
import 'generic.dart';
import 'library.dart';
import 'method.dart';
import 'model_helpers.dart';
import 'owned_indexable.dart';
import 'variable.dart';

/// A class containing contents of a Dart class.
class Class extends OwnedIndexable<dart2js_mirrors.Dart2JsInterfaceTypeMirror>
    implements Comparable<Class> {

  /// List of the names of interfaces that this class implements.
  List<Class> interfaces = [];

  /// Names of classes that extends or implements this class.
  Set<Class> subclasses = new Set<Class>();

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Inherited variables in the class.
  final Map<String, Variable> inheritedVariables = {};

  /// Methods in the class.
  Map<String, Method> methods;

  final Map<String, Method> inheritedMethods = new Map<String, Method>();

  /// Generic infomation about the class.
  final Map<String, Generic> generics;

  Class _superclass;
  bool get isAbstract => mirror.isAbstract;

  /// Make sure that we don't check for inherited comments more than once.
  bool _commentsEnsured = false;

  /// Returns the [Class] for the given [mirror] if it has already been created,
  /// else creates it.
  factory Class(ClassMirror mirror, Library owner) {
    var clazz = getDocgenObject(mirror, owner);
    if (clazz is DummyMirror) {
      clazz = new Class._(mirror, owner);
    }
    return clazz;
  }

  /// Called when we are constructing a superclass or interface class, but it
  /// is not known if it belongs to the same owner as the original class. In
  /// this case, we create an object whose owner is what the original mirror
  /// says it is.
  factory Class._possiblyDifferentOwner(ClassMirror mirror,
      Library originalOwner) {
    var realOwner = getDocgenObject(mirror.owner);
    if (realOwner is Library) {
      return new Class(mirror, realOwner);
    } else {
      return new Class(mirror, originalOwner);
    }
  }

  Class._(ClassSourceMirror classMirror, Library owner)
      : generics = createGenerics(classMirror),
        super(classMirror, owner) {

    // The reason we do this madness is the superclass and interface owners may
    // not be this class's owner!! Example: BaseClient in http pkg.
    var superinterfaces = classMirror.superinterfaces.map(
        (interface) => new Class._possiblyDifferentOwner(interface, owner));
    this._superclass = classMirror.superclass == null? null :
        new Class._possiblyDifferentOwner(classMirror.superclass, owner);

    interfaces = superinterfaces.toList();
    variables = createVariables(
        dart2js_util.variablesOf(classMirror.declarations), this);
    methods = createMethods(dart2js_util.anyMethodOf(classMirror.declarations),
        this);

    // Tell superclass that you are a subclass, unless you are not
    // visible or an intermediary mixin class.
    if (!classMirror.isNameSynthetic && isVisible && _superclass != null) {
      _superclass.addSubclass(this);
    }

    if (this._superclass != null) addInherited(_superclass);
    interfaces.forEach((interface) => addInherited(interface));
  }

  String _lookupInClassAndSuperclasses(String name) {
    var lookupFunc = determineLookupFunc(name);
    var classScope = this;
    while (classScope != null) {
      var classFunc = lookupFunc(classScope.mirror, name);
      if (classFunc != null) {
        return packagePrefix + getDocgenObject(classFunc, owner).docName;
      }
      classScope = classScope._superclass;
    }
    return null;
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var result = _lookupInClassAndSuperclasses(name);
    if (result != null) {
      return result;
    }
    result = owner.findElementInScope(name);
    return result == null ? super.findElementInScope(name) : result;
  }

  String get typeName => 'class';

  /// Add all inherited variables and methods from the provided superclass.
  /// If [_includePrivate] is true, it also adds the variables and methods from
  /// the superclass.
  void addInherited(Class superclass) {
    inheritedVariables.addAll(superclass.inheritedVariables);
    inheritedVariables.addAll(_allButStatics(superclass.variables));
    addInheritedMethod(superclass, this);
  }

  /** [newParent] refers to the actual class is currently using these methods.
   * which may be different because with the mirror system, we only point to the
   * original canonical superclasse's method.
   */
  void addInheritedMethod(Class parent, Class newParent) {
    parent.inheritedMethods.forEach((name, method) {
      if (!method.mirror.isConstructor) {
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }
    });
    _allButStatics(parent.methods).forEach((name, method) {
      if (!method.mirror.isConstructor) {
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }
    });
  }

  /// Remove statics from the map of inherited items before adding them.
  Map _allButStatics(Map items) {
    var result = {};
    items.forEach((name, item) {
      if (!item.isStatic) {
        result[name] = item;
      }
    });
    return result;
  }

  /// Add the subclass to the class.
  ///
  /// If [this] is private (or an intermediary mixin class), it will add the
  /// subclass to the list of subclasses in the superclasses.
  void addSubclass(Class subclass) {
    if (docName == 'dart:core.Object') return;

    if (!includePrivateMembers && isPrivate || mirror.isNameSynthetic) {
      if (_superclass != null) _superclass.addSubclass(subclass);
      interfaces.forEach((interface) {
        interface.addSubclass(subclass);
      });
    } else {
      subclasses.add(subclass);
    }
  }

  /// Check if this [Class] is an error or exception.
  bool isError() {
    if (qualifiedName == 'dart:core.Error' ||
        qualifiedName == 'dart:core.Exception')
      return true;
    for (var interface in interfaces) {
      if (interface.isError()) return true;
    }
    if (_superclass == null) return false;
    return _superclass.isError();
  }

  /// Makes sure that all methods with inherited equivalents have comments.
  void ensureComments() {
    if (_commentsEnsured) return;
    _commentsEnsured = true;
    if (_superclass != null) _superclass.ensureComments();
    inheritedMethods.forEach((qualifiedName, inheritedMethod) {
      var method = methods[qualifiedName];
      if (method != null) {
        // if we have overwritten this method in this class, we still provide
        // the opportunity to inherit the comments.
        method.ensureCommentFor(inheritedMethod);
      }
    });
    // we need to populate the comments for all methods. so that the subclasses
    // can get for their inherited versions the comments.
    methods.forEach((qualifiedName, method) {
      if (!method.mirror.isConstructor) method.ensureCommentFor(method);
    });
  }

  /// If a class extends a private superclass, find the closest public
  /// superclass of the private superclass.
  String validSuperclass() {
    if (_superclass == null) return 'dart:core.Object';
    if (_superclass.isVisible) return _superclass.qualifiedName;
    return _superclass.validSuperclass();
  }

  /// Generates a map describing the [Class] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'isAbstract' : isAbstract,
    'superclass': validSuperclass(),
    'implements': interfaces.where((i) => i.isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': (subclasses.toList()..sort())
        .map((x) => x.qualifiedName).toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': expandMethodMap(methods),
    'inheritedMethods': expandMethodMap(inheritedMethods),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };

  int compareTo(Class other) => name.compareTo(other.name);

  bool isValidMirror(DeclarationMirror mirror) => mirror is ClassMirror;
}
