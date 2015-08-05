// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:collection';
import 'dart:mirrors';
import 'dart:_foreign_helper' show JS;
import 'dart:_internal' as _internal;

String getName(Symbol symbol) =>
    _internal.Symbol.getName(symbol as _internal.Symbol);

Symbol getSymbol(name, library) =>
    throw new UnimplementedError("MirrorSystem.getSymbol unimplemented");

final currentJsMirrorSystem = throw new UnimplementedError(
    "MirrorSystem.currentJsMirrorSystem unimplemented");

InstanceMirror reflect(reflectee) => new JsInstanceMirror._(reflectee);

TypeMirror reflectType(Type key) {
  // TODO(vsm): Might not be a class.
  return new JsClassMirror._(key);
}

final dynamic _dart = JS('', 'dart');
final _metadata = JS('', '#.metadata', _dart);

dynamic _dload(obj, String name) {
  return JS('', '#.dload(#, #)', _dart, obj, name);
}

void _dput(obj, String name, val) {
  JS('', '#.dput(#, #, #)', _dart, obj, name, val);
}

dynamic _dsend(obj, String name, List args) {
  return JS('', '#.dsend(#, #, ...#)', _dart, obj, name, args);
}

class JsInstanceMirror implements InstanceMirror {
  final Object reflectee;

  JsInstanceMirror._(this.reflectee);

  InstanceMirror getField(Symbol symbol) {
    var name = getName(symbol);
    var field = _dload(reflectee, name);
    return new JsInstanceMirror._(field);
  }

  InstanceMirror setField(Symbol symbol, Object value) {
    var name = getName(symbol);
    var field = _dput(reflectee, name, value);
    return new JsInstanceMirror._(field);
  }

  InstanceMirror invoke(Symbol symbol, List<dynamic> args,
      [Map<Symbol, dynamic> namedArgs]) {
    var name = getName(symbol);
    if (namedArgs != null) {
      args = new List.from(args);
      args.add(_toJsMap(namedArgs));
    }
    var result = _dsend(reflectee, name, args);
    return new JsInstanceMirror._(result);
  }

  dynamic _toJsMap(Map<Symbol, dynamic> map) {
    var obj = JS('', '{}');
    map.forEach((Symbol key, value) {
      JS('', '#[#] = #', obj, getName(key), value);
    });
    return obj;
  }
}

class JsClassMirror implements ClassMirror {
  final Type _cls;
  final Symbol simpleName;

  List<InstanceMirror> _metadata;
  Map<Symbol, MethodMirror> _declarations;

  // TODO(vsm):These need to be immutable when escaping from this class.
  List<InstanceMirror> get metadata => _metadata;
  Map<Symbol, MethodMirror> get declarations => _declarations;

  JsClassMirror._(Type cls)
      : _cls = cls,
        simpleName = new Symbol(JS('String', '#.name', cls)) {
    // Load metadata.
    var fn = JS('List<InstanceMirror>', '#[dart.metadata]', _cls);
    _metadata = (fn == null)
        ? <InstanceMirror>[]
        : new List<InstanceMirror>.from(fn().map((i) => new JsInstanceMirror._(i)));

    // Load declarations.
    // TODO(vsm): This is only populating the default constructor right now.
    _declarations = new Map<Symbol, MethodMirror>();
    _declarations[simpleName] = new JsMethodMirror._(this, _cls);
  }

  InstanceMirror newInstance(Symbol constructorName, List args,
      [Map<Symbol, dynamic> namedArgs]) {
    // TODO(vsm): Support named constructors and named arguments.
    assert(getName(constructorName) == "");
    assert(namedArgs == null || namedArgs.isEmpty);
    var instance = JS('', 'new #(...#)', _cls, args);
    return new JsInstanceMirror._(instance);
  }
}

class JsTypeMirror implements TypeMirror {
  final Type reflectedType;

  JsTypeMirror._(this.reflectedType);
}

class JsParameterMirror implements ParameterMirror {
  final String _name;
  final TypeMirror type;
  final List<InstanceMirror> metadata = [];

  JsParameterMirror._(this._name, Type t) : type = new JsTypeMirror._(t);
}

class JsMethodMirror implements MethodMirror {
  final String _name;
  final dynamic _method;
  List<ParameterMirror> _params;

  JsMethodMirror._(JsClassMirror cls, this._method)
      : _name = getName(cls.simpleName) {
    var ftype = JS('', '#.classGetConstructorType(#)', _dart, cls._cls);
    _params = _createParameterMirrorList(ftype);
  }

  // TODO(vsm): Support named constructors.
  Symbol get constructorName => new Symbol('');
  List<ParameterMirror> get parameters => _params;

  List<ParameterMirror> _createParameterMirrorList(ftype) {
    if (ftype == null) {
      // TODO(vsm): No explicit constructor.  Verify this.
      return [];
    }

    // TODO(vsm): Add named args.
    List args = ftype.args;
    List opts = ftype.optionals;
    var params = new List<ParameterMirror>(args.length + opts.length);

    for (var i = 0; i < args.length; ++i) {
      var type = args[i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', type);
      params[i] = param;
    }

    for (var i = 0; i < opts.length; ++i) {
      var type = opts[i];
      // TODO(vsm): Recover the param name.
      var param = new JsParameterMirror._('', type);
      params[i + args.length] = param;
    }

    return params;
  }
}
