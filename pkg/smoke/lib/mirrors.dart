// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the smoke services using mirrors.
library smoke.mirrors;

import 'dart:mirrors';
import 'package:smoke/smoke.dart';
import 'package:logging/logging.dart';
import 'src/common.dart';

/// Set up the smoke package to use a mirror-based implementation. To tune what
/// is preserved by `dart:mirrors`, use a @MirrorsUsed annotation and include
/// 'smoke.mirrors' in your override arguments.
useMirrors() {
  configure(new ReflectiveObjectAccessorService(),
      new ReflectiveTypeInspectorService(),
      new ReflectiveSymbolConverterService());
}

var _logger = new Logger('smoke.mirrors');


/// Implements [ObjectAccessorService] using mirrors.
class ReflectiveObjectAccessorService implements ObjectAccessorService {
  read(Object object, Symbol name) => reflect(object).getField(name).reflectee;

  void write(Object object, Symbol name, value) {
    reflect(object).setField(name, value);
  }

  invoke(receiver, Symbol methodName, List args,
      {Map namedArgs, bool adjust: false}) {
    var receiverMirror;
    var method;
    if (receiver is Type && methodName != #toString) {
      receiverMirror = reflectType(receiver);
      method = receiverMirror.declarations[methodName];
    } else {
      receiverMirror = reflect(receiver);
      method = _findMethod(receiverMirror.type, methodName);
    }
    if (method != null && adjust) {
      var required = 0;
      var optional = 0;
      for (var p in method.parameters) {
        if (p.isOptional) {
          if (!p.isNamed) optional++;
        } else {
          required++;
        }
      }
      args = adjustList(args, required, required + optional);
    }
    return receiverMirror.invoke(methodName, args, namedArgs).reflectee;
  }
}

/// Implements [TypeInspectorService] using mirrors.
class ReflectiveTypeInspectorService implements TypeInspectorService {
  bool isSubclassOf(Type type, Type supertype) {
    if (type == supertype || supertype == Object) return true;
    // TODO(sigmund): change to mirror.isSubclassOf when it gets implemented in
    // dart2js. (dartbug.com/12439)
    var mirror = reflectClass(type);
    var top = reflectClass(supertype);
    while (mirror != _objectType) {
      mirror = _safeSuperclass(mirror);
      if (mirror == top) return true;
    }
    return false;
  }

  bool hasGetter(Type type, Symbol name) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return false;
    while (mirror != _objectType) {
      final members = mirror.declarations;
      if (members.containsKey(name)) return true;
      mirror = _safeSuperclass(mirror);
    }
    return false;
  }

  bool hasSetter(Type type, Symbol name) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return false;
    var setterName = _setterName(name);
    while (mirror != _objectType) {
      final members = mirror.declarations;
      var declaration = members[name];
      if (declaration is VariableMirror && !declaration.isFinal) return true;
      if (members.containsKey(setterName)) return true;
      mirror = _safeSuperclass(mirror);
    }
    return false;
  }

  bool hasInstanceMethod(Type type, Symbol name) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return false;
    while (mirror != _objectType) {
      final m = mirror.declarations[name];
      if (m is MethodMirror && m.isRegularMethod && !m.isStatic) return true;
      mirror = _safeSuperclass(mirror);
    }
    return false;
  }

  bool hasStaticMethod(Type type, Symbol name) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return false;
    final m = mirror.declarations[name];
    return m is MethodMirror && m.isRegularMethod && m.isStatic;
  }

  Declaration getDeclaration(Type type, Symbol name) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return null;

    var declaration;
    while (mirror != _objectType) {
      final members = mirror.declarations;
      if (members.containsKey(name)) {
        declaration = members[name];
        break;
      }
      mirror = _safeSuperclass(mirror);
    }
    if (declaration == null) {
      _logger.severe("declaration doesn't exists ($type.$name).");
      return null;
    }
    return new _MirrorDeclaration(mirror, declaration);
  }

  List<Declaration> query(Type type, QueryOptions options) {
    var mirror = reflectType(type);
    if (mirror is! ClassMirror) return null;
    return _query(mirror, options);
  }

  List<Declaration> _query(ClassMirror cls, QueryOptions options) {
    final visitParent = options.includeInherited && cls.superclass != null && 
        // TODO(sigmund): use _toType(cls.superclass) != options.includeUpTo
        // when dartbug.com/16925 gets fixed (_toType fails in dart2js if
        // applied to classes with type-arguments).
        cls.superclass != reflectClass(options.includeUpTo);
    var result = visitParent ? _query(cls.superclass, options) : [];
    for (var member in cls.declarations.values) {
      if (member is! VariableMirror && member is! MethodMirror) continue;
      if (member.isStatic || member.isPrivate) continue;
      var name = member.simpleName;
      bool isMethod = false;
      if (member is VariableMirror) {
        if (!options.includeFields) continue;
        if (options.excludeFinal && member.isFinal) continue;
      }

      // TODO(sigmund): what if we have a setter but no getter?
      if (member is MethodMirror && member.isSetter) continue;
      if (member is MethodMirror && member.isConstructor) continue;

      if (member is MethodMirror && member.isGetter) {
        if (!options.includeProperties) continue;
        if (options.excludeFinal && !_hasSetter(cls, member)) continue;
      }

      if (member is MethodMirror && member.isRegularMethod) {
        if (!options.includeMethods) continue;
        isMethod = true;
      }

      if (options.matches != null && !options.matches(name)) continue;

      var annotations =
          member.metadata.map((m) => m.reflectee).toList();
      if (options.withAnnotations != null &&
          !matchesAnnotation(annotations, options.withAnnotations)) {
        continue;
      }

      // TODO(sigmund): should we cache parts of this declaration so we don't
      // compute them twice?  For example, this chould be `new Declaration(name,
      // type, ...)` and we could reuse what we computed above to implement the
      // query filtering.  Note, when I tried to eagerly compute everything, I
      // run into trouble with type (`type = _toType(member.type)`), dart2js
      // failed when the underlying types had type-arguments (see
      // dartbug.com/16925).
      result.add(new _MirrorDeclaration(cls, member));
    }

    return result;
  }
}

/// Implements [SymbolConverterService] using mirrors.
class ReflectiveSymbolConverterService implements SymbolConverterService {
  String symbolToName(Symbol symbol) => MirrorSystem.getName(symbol);
  Symbol nameToSymbol(String name) => new Symbol(name);
}


// TODO(jmesserly): workaround for:
// https://code.google.com/p/dart/issues/detail?id=10029
Symbol _setterName(Symbol getter) =>
    new Symbol('${MirrorSystem.getName(getter)}=');


ClassMirror _safeSuperclass(ClassMirror type) {
  try {
    var t = type.superclass;
    // TODO(sigmund): workaround for darbug.com/17779.
    // Interceptor is leaked by dart2js. It has the same methods as Object
    // (including noSuchMethod), and our code above assumes that it doesn't
    // exist. Most queries exclude Object, so they should exclude Interceptor
    // too. We don't check for t.simpleName == #Interceptor because depending on
    // dart2js optimizations it may be #Interceptor or #num/Interceptor.
    // Checking for a private library seems to reliably filter this out.
    if (t != null && t.owner != null && t.owner.isPrivate) {
      t = _objectType;
    }
    return t;
  } on UnsupportedError catch (e) {
    // Note: dart2js throws UnsupportedError when the type is not reflectable.
    return _objectType;
  }
}

MethodMirror _findMethod(ClassMirror type, Symbol name) {
  do {
    var member = type.declarations[name];
    if (member is MethodMirror) return member;
    type = type.superclass;
  } while (type != null);
}

// When recursively looking for symbols up the type-hierarchy it's generally a
// good idea to stop at Object, since we know it doesn't have what we want.
// TODO(jmesserly): This is also a workaround for what appears to be a V8
// bug introduced between Chrome 31 and 32. After 32
// JsClassMirror.declarations on Object calls
// JsClassMirror.typeVariables, which tries to get the _jsConstructor's
// .prototype["<>"]. This ends up getting the "" property instead, maybe
// because "<>" doesn't exist, and gets ";" which then blows up because
// the code later on expects a List of ints.
final _objectType = reflectClass(Object);

bool _hasSetter(ClassMirror cls, MethodMirror getter) {
  var mirror = cls.declarations[_setterName(getter.simpleName)];
  return mirror is MethodMirror && mirror.isSetter;
}

Type _toType(TypeMirror t) {
  // TODO(sigmund): this line can go away after dartbug.com/16962
  if (t == _objectType) return Object;
  if (t is ClassMirror) return t.reflectedType;
  if (t == null || t.qualifiedName != #dynamic) {
    _logger.warning('unknown type ($t).');
  }
  return dynamic;
}

class _MirrorDeclaration implements Declaration {
  final ClassMirror _cls;
  final _original;

  _MirrorDeclaration(this._cls, DeclarationMirror this._original);

  Symbol get name => _original.simpleName;

  DeclarationKind get kind => isField ? FIELD : isProperty ? PROPERTY : METHOD;

  bool get isField => _original is VariableMirror;

  bool get isProperty =>
      _original is MethodMirror && !_original.isRegularMethod;

  bool get isMethod => !isField && !isProperty;

  /// If this is a property, whether it's read only (final fields or properties
  /// with no setter).
  bool get isFinal =>
      (_original is VariableMirror && _original.isFinal) ||
      (_original is MethodMirror && _original.isGetter &&
           !_hasSetter(_cls, _original));

  /// If this is a property, it's declared type (including dynamic if it's not
  /// declared). For methods, the returned type.
  Type get type {
    if (_original is MethodMirror && _original.isRegularMethod) {
      return Function;
    }
    var typeMirror = _original is VariableMirror ? _original.type
        : _original.returnType;
    return _toType(typeMirror);
  }

  /// Whether this symbol is static.
  bool get isStatic => _original.isStatic;

  /// List of annotations in this declaration.
  List get annotations => _original.metadata.map((a) => a.reflectee).toList();

  int get hashCode => name.hashCode;
  operator ==(other) => other is Declaration && name == other.name &&
      kind == other.kind && isFinal == other.isFinal &&
      type == other.type && isStatic == other.isStatic &&
      compareLists(annotations, other.annotations);
  String toString() => (new StringBuffer()
      ..write('(mirror-based-declaration ')
      ..write(name)
      ..write(isField ? ' (field) '
          : (isProperty ? ' (property) ' : ' (method) '))
      ..write(isFinal ? 'final ' : '')
      ..write(isStatic ? 'static ' : '')
      ..write(annotations)
      ..write(')')).toString();
}
