// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch library for dart:mirrors.

import 'dart:_foreign_helper' show JS;
import 'dart:_collection-dev' as _symbol_dev;
import 'dart:_js_helper' show createInvocationMirror;
import 'dart:_interceptors' show getInterceptor;

patch class MirrorSystem {
  patch static String getName(Symbol symbol) => _n(symbol);
}

class _MirrorSystem implements MirrorSystem {
}

String _n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

patch MirrorSystem currentMirrorSystem() => _currentMirrorSystem;

final _MirrorSystem _currentMirrorSystem = new _MirrorSystem();

patch Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  throw new UnsupportedError("MirrorSystem not implemented");
}

patch InstanceMirror reflect(Object reflectee) {
  return new _InstanceMirror(reflectee);
}

final Expando<ClassMirror> _classMirrors = new Expando<ClassMirror>();

patch ClassMirror reflectClass(Type key) => _reflectClass(key);

// TODO(ahe): This is a workaround for http://dartbug.com/10543
ClassMirror _reflectClass(Type key) {
  String className = '$key';
  var constructor = Primitives.getConstructor(className);
  if (constructor == null) {
    // Probably an intercepted class.
    // TODO(ahe): How to handle intercepted classes?
    throw new UnsupportedError('Cannot find class for: $className');
  }
  var mirror = _classMirrors[constructor];
  if (mirror == null) {
    mirror = new _ClassMirror(className, constructor);
    _classMirrors[constructor] = mirror;
  }
  return mirror;
}

class _InstanceMirror extends InstanceMirror {

  final reflectee;

  _InstanceMirror(this.reflectee);

  bool get hasReflectee => true;

  ClassMirror get type => _reflectClass(reflectee.runtimeType);

  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List<Object> positionalArguments,
                                     [Map<String,Object> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    return
        new Future<InstanceMirror>(
            () => invoke(memberName, positionalArguments, namedArguments));
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    // Copy the list to ensure that it can safely be passed to
    // JavaScript.
    var jsList = new List.from(positionalArguments);
    return _invoke(
        memberName, JSInvocationMirror.METHOD,
        '${_n(memberName)}\$${positionalArguments.length}', jsList);
  }

  InstanceMirror _invoke(Symbol name,
                         int type,
                         String mangledName,
                         List arguments) {
    // TODO(ahe): Get the argument names.
    List<String> argumentNames = [];
    Invocation invocation = createInvocationMirror(
        _n(name), mangledName, type, arguments, argumentNames);

    return new _InstanceMirror(delegate(invocation));
  }

  Future<InstanceMirror> setFieldAsync(Symbol fieldName, Object value) {
    return new Future<InstanceMirror>(() => setField(fieldName, value));
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    _invoke(
        fieldName, JSInvocationMirror.SETTER, 'set\$${_n(fieldName)}', [arg]);
    return new _InstanceMirror(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    return _invoke(
        fieldName, JSInvocationMirror.GETTER, 'get\$${_n(fieldName)}', []);
  }

  Future<InstanceMirror> getFieldAsync(Symbol fieldName) {
    return new Future<InstanceMirror>(() => getField(fieldName));
  }

  delegate(Invocation invocation) {
    return JSInvocationMirror.invokeFromMirror(invocation, reflectee);
  }

  String toString() => 'InstanceMirror($reflectee)';
}

class _ClassMirror extends ClassMirror {
  final String _name;
  final _jsConstructor;

  _ClassMirror(this._name, this._jsConstructor) {
  }

  String toString() => 'ClassMirror($_name)';
}
