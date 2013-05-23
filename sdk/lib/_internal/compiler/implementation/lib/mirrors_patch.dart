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
  TypeMirror get dynamicType => _dynamicType;
  TypeMirror get voidType => _voidType;

  final static TypeMirror _dynamicType =
      new _TypeMirror(const Symbol('dynamic'));
  final static TypeMirror _voidType = new _TypeMirror(const Symbol('void'));

  static final Map<String, List<LibraryMirror>> librariesByName =
      computeLibrariesByName();

  Iterable<LibraryMirror> findLibrary(Symbol libraryName) {
    return new List<LibraryMirror>.from(librariesByName[_n(libraryName)]);
  }

  static Map<String, List<LibraryMirror>> computeLibrariesByName() {
    var result = new Map<String, List<LibraryMirror>>();
    var jsLibraries = JS('=List|Null', 'init.libraries');
    if (jsLibraries == null) return result;
    for (List data in jsLibraries) {
      String name = data[0];
      Uri uri = Uri.parse(data[1]);
      List<String> classes = data[2];
      List<String> functions = data[3];
      var libraries = result.putIfAbsent(name, () => <LibraryMirror>[]);
      libraries.add(new _LibraryMirror(name, uri, classes, functions));
    }
    return result;
  }
}

class _TypeMirror implements TypeMirror {
  final Symbol simpleName;
  _TypeMirror(this.simpleName);
}

class _LibraryMirror extends _ObjectMirror implements LibraryMirror {
  final String _name;
  final Uri uri;
  final List<String> _classes;
  final List<String> _functions;

  _LibraryMirror(this._name, this.uri, this._classes, this._functions);

  Map<Symbol, ClassMirror> get classes {
    var result = new Map<Symbol, ClassMirror>();
    for (int i = 0; i < _classes.length; i += 2) {
      Symbol symbol = _s(_classes[i]);
      result[symbol] = _reflectClass(symbol, _classes[i + 1]);
    }
    return result;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): This is extremely dangerous!!!
    JS('void', r'$[#] = #', _n(fieldName), arg);
    return new _InstanceMirror(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return new _InstanceMirror(JS('', r'$[#]', _n(fieldName)));
  }
}

String _n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol _s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
}

patch MirrorSystem currentMirrorSystem() => _currentMirrorSystem;

final _MirrorSystem _currentMirrorSystem = new _MirrorSystem();

patch Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  throw new UnsupportedError("MirrorSystem not implemented");
}

patch InstanceMirror reflect(Object reflectee) {
  return new _InstanceMirror(reflectee);
}

final Expando<ClassMirror> _classMirrors = new Expando<ClassMirror>();

patch ClassMirror reflectClass(Type key) => __reflectClass(key);

// TODO(ahe): This is a workaround for http://dartbug.com/10543
ClassMirror __reflectClass(Type key) => _reflectClass(_s('$key'), null);

ClassMirror _reflectClass(Symbol symbol, String fields) {
  String className = _n(symbol);
  var constructor = Primitives.getConstructor(className);
  if (constructor == null) {
    // Probably an intercepted class.
    // TODO(ahe): How to handle intercepted classes?
    throw new UnsupportedError('Cannot find class for: $className');
  }
  var mirror = _classMirrors[constructor];
  if (mirror == null) {
    mirror = new _ClassMirror(symbol, constructor, fields);
    _classMirrors[constructor] = mirror;
  }
  return mirror;
}

abstract class _ObjectMirror implements ObjectMirror {
  Future<InstanceMirror> setFieldAsync(Symbol fieldName, Object value) {
    return new Future<InstanceMirror>(() => this.setField(fieldName, value));
  }

  Future<InstanceMirror> getFieldAsync(Symbol fieldName) {
    return new Future<InstanceMirror>(() => this.getField(fieldName));
  }
}

class _InstanceMirror extends _ObjectMirror implements InstanceMirror {

  final reflectee;

  _InstanceMirror(this.reflectee);

  bool get hasReflectee => true;

  ClassMirror get type => __reflectClass(reflectee.runtimeType);

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

  InstanceMirror setField(Symbol fieldName, Object arg) {
    _invoke(
        fieldName, JSInvocationMirror.SETTER, 'set\$${_n(fieldName)}', [arg]);
    return new _InstanceMirror(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    return _invoke(
        fieldName, JSInvocationMirror.GETTER, 'get\$${_n(fieldName)}', []);
  }

  delegate(Invocation invocation) {
    return JSInvocationMirror.invokeFromMirror(invocation, reflectee);
  }

  String toString() => 'InstanceMirror($reflectee)';
}

class _ClassMirror extends _ObjectMirror implements ClassMirror {
  final Symbol simpleName;
  final _jsConstructor;
  final String _fields;

  _ClassMirror(this.simpleName, this._jsConstructor, this._fields);

  Map<Symbol, Mirror> get members {
    var result = new Map<Symbol, Mirror>();
    var s = _fields.split(";");
    var fields = s[1] == "" ? [] : s[1].split(",");
    for (String field in fields) {
      _VariableMirror mirror = new _VariableMirror.from(field);
      result[mirror.simpleName] = mirror;
    }
    return result;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): This is extremely dangerous!!!
    JS('void', r'$[#] = #', '${_n(simpleName)}_${_n(fieldName)}', arg);
    return new _InstanceMirror(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return new _InstanceMirror(
        JS('', r'$[#]', '${_n(simpleName)}_${_n(fieldName)}'));
  }

  String toString() => 'ClassMirror(${_n(simpleName)})';
}

class _VariableMirror implements VariableMirror {
  final Symbol simpleName;
  final String _jsName;
  final bool _readOnly;

  _VariableMirror(this.simpleName, this._jsName, this._readOnly);

  factory _VariableMirror.from(String descriptor) {
    int length = descriptor.length;
    var code = fieldCode(descriptor.codeUnitAt(length - 1));
    if (code == 0) {
      throw new RuntimeError('Bad field descriptor: $descriptor');
    }
    bool hasGetter = (code & 3) != 0;
    bool hasSetter = (code >> 2) != 0;
    String jsName;
    String accessorName = jsName = descriptor.substring(0, length - 1);
    int divider = descriptor.indexOf(":");
    if (divider > 0) {
      accessorName = accessorName.substring(0, divider);
      jsName = accessorName.substring(divider + 1);
    }
    bool readOnly = hasSetter;
    return new _VariableMirror(_s(accessorName), jsName, readOnly);
  }

  TypeMirror get type => _MirrorSystem._dynamicType;

  static int fieldCode(int code) {
    if (code >= 60 && code <= 64) return code - 59;
    if (code >= 123 && code <= 126) return code - 117;
    if (code >= 37 && code <= 43) return code - 27;
    return 0;
  }
}
