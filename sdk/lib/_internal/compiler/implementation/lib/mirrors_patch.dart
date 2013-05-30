// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch library for dart:mirrors.

import 'dart:_foreign_helper' show JS, JS_CURRENT_ISOLATE;
import 'dart:_collection-dev' as _symbol_dev;
import 'dart:_js_helper' show createInvocationMirror;
import 'dart:_interceptors' show Interceptor;

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
      var metadataFunction = data[4];
      List metadata = (metadataFunction == null)
          ? null : JS('List', '#()', metadataFunction);
      var libraries = result.putIfAbsent(name, () => <LibraryMirror>[]);
      libraries.add(
          new _LibraryMirror(_s(name), uri, classes, functions, metadata));
    }
    return result;
  }
}

class _TypeMirror implements TypeMirror {
  final Symbol simpleName;
  _TypeMirror(this.simpleName);
}

class _LibraryMirror extends _ObjectMirror implements LibraryMirror {
  final Symbol simpleName;
  final Uri uri;
  final List<String> _classes;
  final List<String> _functions;
  final List _metadata;

  _LibraryMirror(this.simpleName,
                 this.uri,
                 this._classes,
                 this._functions,
                 this._metadata);

  Symbol get qualifiedName => simpleName;

  Map<Symbol, ClassMirror> get classes {
    var result = new Map<Symbol, ClassMirror>();
    for (int i = 0; i < _classes.length; i += 2) {
      Symbol symbol = _s(_classes[i]);
      _ClassMirror cls = _reflectClass(symbol, _classes[i + 1]);
      result[symbol] = cls;
      cls._owner = this;
    }
    return result;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): This is extremely dangerous!!!
    JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), _n(fieldName), arg);
    return _reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return _reflect(JS('', '#[#]', JS_CURRENT_ISOLATE(), _n(fieldName)));
  }

  Map<Symbol, MethodMirror> get functions {
    var result = new Map<Symbol, MethodMirror>();
    for (int i = 0; i < _functions.length; i++) {
      String name = _functions[i];
      Symbol symbol = _s(name);
      int parameterCount = null; // TODO(ahe): Compute this.
      _MethodMirror mirror =
          // TODO(ahe): Create accessor for accessing $.  It is also
          // used in js_helper.
          new _MethodMirror(
              symbol, JS('', '#[#]', JS_CURRENT_ISOLATE(), name), parameterCount);
      // TODO(ahe): Cache mirrors.
      result[symbol] = mirror;
      mirror._owner = this;
    }
    return result;
  }

  Map<Symbol, MethodMirror> get getters {
    var result = new Map<Symbol, MethodMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, MethodMirror> get setters {
    var result = new Map<Symbol, MethodMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, VariableMirror> get variables {
    var result = new Map<Symbol, VariableMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, Mirror> get members {
    Map<Symbol, Mirror> result = new Map<Symbol, Mirror>.from(classes);
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }
    functions.forEach(addToResult);
    getters.forEach(addToResult);
    setters.forEach(addToResult);
    variables.forEach(addToResult);
    return result;
  }

  List<InstanceMirror> get metadata => _metadata.map(reflect);
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

// TODO(ahe): This is a workaround for http://dartbug.com/10543
patch InstanceMirror reflect(Object reflectee) => _reflect(reflectee);

InstanceMirror _reflect(Object reflectee) {
  if (reflectee is Closure) {
    return new _ClosureMirror(reflectee);
  } else {
    return new _InstanceMirror(reflectee);
  }
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

    return _reflect(delegate(invocation));
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    _invoke(
        fieldName, JSInvocationMirror.SETTER, 'set\$${_n(fieldName)}', [arg]);
    return _reflect(arg);
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
  // Set as side-effect of accessing _LibraryMirror.classes.
  _LibraryMirror _owner;

  _ClassMirror(this.simpleName, this._jsConstructor, this._fields);

  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);

  Map<Symbol, MethodMirror> get functions {
    var result = new Map<Symbol, MethodMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, MethodMirror> get getters {
    var result = new Map<Symbol, MethodMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, MethodMirror> get setters {
    var result = new Map<Symbol, MethodMirror>();
    // TODO(ahe): Implement this.
    return result;
  }

  Map<Symbol, VariableMirror> get variables {
    var result = new Map<Symbol, VariableMirror>();
    var s = _fields.split(";");
    var fields = s[1] == "" ? [] : s[1].split(",");
    for (String field in fields) {
      _VariableMirror mirror = new _VariableMirror.from(field);
      result[mirror.simpleName] = mirror;
      mirror._owner = this;
    }
    return result;
  }

  Map<Symbol, Mirror> get members {
    Map<Symbol, Mirror> result = new Map<Symbol, Mirror>.from(functions);
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }
    getters.forEach(addToResult);
    setters.forEach(addToResult);
    variables.forEach(addToResult);
    return result;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): This is extremely dangerous!!!
    JS('void', '#[#] = #', JS_CURRENT_ISOLATE(),
       '${_n(simpleName)}_${_n(fieldName)}', arg);
    return _reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return _reflect(
        JS('', '#[#]', JS_CURRENT_ISOLATE(),
           '${_n(simpleName)}_${_n(fieldName)}'));
  }

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol,dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    String constructorName = '${_n(simpleName)}\$${_n(constructorName)}';
    return _reflect(JS('', r'#[#].apply(#, #)', JS_CURRENT_ISOLATE(),
                       constructorName,
                       JS_CURRENT_ISOLATE(),
                       new List.from(positionalArguments)));
  }

  Future<InstanceMirror> newInstanceAsync(
      Symbol constructorName,
      List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    return new Future<InstanceMirror>(
        () => newInstance(
            constructorName, positionalArguments, namedArguments));
  }

  DeclarationMirror get owner {
    if (_owner == null) {
      if (_jsConstructor is Interceptor) {
        _owner = __reflectClass(Object).owner;
      } else {
        for (var list in _MirrorSystem.librariesByName.values) {
          for (_LibraryMirror library in list) {
            // This will set _owner field on all clasess as a side
            // effect.  This gives us a fast path to reflect on a
            // class without parsing reflection data.
            library.classes;
          }
        }
      }
      if (_owner == null) {
        throw new StateError('Class "${_n(simpleName)}" has no owner');
      }
    }
    return _owner;
  }

  String toString() => 'ClassMirror(${_n(simpleName)})';
}

class _VariableMirror implements VariableMirror {
  // TODO(ahe): The values in these fields are virtually untested.
  final Symbol simpleName;
  final String _jsName;
  final bool _readOnly;
  DeclarationMirror _owner;

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
    bool readOnly = !hasSetter;
    return new _VariableMirror(_s(accessorName), jsName, readOnly);
  }

  TypeMirror get type => _MirrorSystem._dynamicType;

  DeclarationMirror get owner => _owner;

  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);

  static int fieldCode(int code) {
    if (code >= 60 && code <= 64) return code - 59;
    if (code >= 123 && code <= 126) return code - 117;
    if (code >= 37 && code <= 43) return code - 27;
    return 0;
  }
}

class _ClosureMirror extends _InstanceMirror implements ClosureMirror {
  _ClosureMirror(reflectee) : super(reflectee);

  MethodMirror get function {
    // TODO(ahe): What about optional parameters (named or not).
    var extractCallName = JS('', r'''
function(reflectee) {
  for (var property in reflectee) {
    if ("call$" == property.substring(0, 5)) return property;
  }
  return null;
}
''');
    String callName = JS('String|Null', '#(#)', extractCallName, reflectee);
    if (callName == null) {
      throw new RuntimeError('Cannot find callName on "$reflectee"');
    }
    var jsFunction = JS('', '#[#]', reflectee, callName);
    int parameterCount = int.parse(callName.split(r'$')[1]);
    return new _MethodMirror(_s(callName), jsFunction, parameterCount);
  }

  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]) {
    return _reflect(
        Function.apply(reflectee, positionalArguments, namedArguments));
  }

  Future<InstanceMirror> applyAsync(List positionalArguments,
                                    [Map<Symbol, dynamic> namedArguments]) {
    return new Future<InstanceMirror>(
        () => apply(positionalArguments, namedArguments));
  }
}

class _MethodMirror implements MethodMirror {
  final Symbol simpleName;
  final _jsFunction;
  final int _parameterCount;
  DeclarationMirror _owner;

  _MethodMirror(this.simpleName, this._jsFunction, this._parameterCount);

  List<ParameterMirror> get parameters {
    // TODO(ahe): Fill the list with parameter mirrors.
    return new List<ParameterMirror>(_parameterCount);
  }

  DeclarationMirror get owner => _owner;

  Symbol get qualifiedName => _computeQualifiedName(owner, simpleName);
}

Symbol _computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  String ownerName = _n(owner.qualifiedName);
  if (ownerName == '') return simpleName;
  return _s('$ownerName.${_n(simpleName)}');
}
