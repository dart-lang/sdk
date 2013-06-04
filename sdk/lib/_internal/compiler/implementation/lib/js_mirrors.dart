// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:async';
import 'dart:mirrors';

import 'dart:_foreign_helper' show JS, JS_CURRENT_ISOLATE;
import 'dart:_collection-dev' as _symbol_dev;
import 'dart:_js_helper' show
    BoundClosure,
    Closure,
    JSInvocationMirror,
    Null,
    Primitives,
    createInvocationMirror;
import 'dart:_interceptors' show Interceptor;

String getName(Symbol symbol) => n(symbol);

class JsMirrorSystem implements MirrorSystem {
  TypeMirror get dynamicType => _dynamicType;
  TypeMirror get voidType => _voidType;

  final static TypeMirror _dynamicType =
      new JsTypeMirror(const Symbol('dynamic'));
  final static TypeMirror _voidType = new JsTypeMirror(const Symbol('void'));

  static final Map<String, List<LibraryMirror>> librariesByName =
      computeLibrariesByName();

  Iterable<LibraryMirror> findLibrary(Symbol libraryName) {
    return new List<LibraryMirror>.from(librariesByName[n(libraryName)]);
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
          new JsLibraryMirror(s(name), uri, classes, functions, metadata));
    }
    return result;
  }
}

class JsTypeMirror implements TypeMirror {
  final Symbol simpleName;
  JsTypeMirror(this.simpleName);
}

class JsLibraryMirror extends JsObjectMirror implements LibraryMirror {
  final Symbol simpleName;
  final Uri uri;
  final List<String> _classes;
  final List<String> _functions;
  final List _metadata;

  JsLibraryMirror(this.simpleName,
                 this.uri,
                 this._classes,
                 this._functions,
                 this._metadata);

  Symbol get qualifiedName => simpleName;

  Map<Symbol, ClassMirror> get classes {
    var result = new Map<Symbol, ClassMirror>();
    for (String className in _classes) {
      Symbol symbol = s(className);
      JsClassMirror cls = reflectClassByName(symbol);
      result[symbol] = cls;
      cls._owner = this;
    }
    return result;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): This is extremely dangerous!!!
    JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), n(fieldName), arg);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return reflect(JS('', '#[#]', JS_CURRENT_ISOLATE(), n(fieldName)));
  }

  Map<Symbol, MethodMirror> get functions {
    var result = new Map<Symbol, MethodMirror>();
    for (int i = 0; i < _functions.length; i++) {
      String name = _functions[i];
      Symbol symbol = s(name);
      int parameterCount = null; // TODO(ahe): Compute this.
      JsMethodMirror mirror =
          // TODO(ahe): Create accessor for accessing $.  It is also
          // used in js_helper.
          new JsMethodMirror(
              symbol, JS('', '#[#]', JS_CURRENT_ISOLATE(), name),
              parameterCount);
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

  List<InstanceMirror> get metadata => _metadata.map(reflect).toList();
}

String n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
}

final JsMirrorSystem currentJsMirrorSystem = new JsMirrorSystem();

InstanceMirror reflect(Object reflectee) {
  if (reflectee is Closure) {
    return new JsClosureMirror(reflectee);
  } else {
    return new JsInstanceMirror(reflectee);
  }
}

final Expando<ClassMirror> classMirrors = new Expando<ClassMirror>();

ClassMirror reflectType(Type key) => reflectClassByName(s('$key'));

ClassMirror reflectClassByName(Symbol symbol) {
  String className = n(symbol);
  var constructor = Primitives.getConstructor(className);
  if (constructor == null) {
    // Probably an intercepted class.
    // TODO(ahe): How to handle intercepted classes?
    throw new UnsupportedError('Cannot find class for: $className');
  }
  var descriptor = JS('', '#["@"]', constructor);
  var fields;
  var fieldsMetadata;
  if (descriptor == null) {
    // This is a native class, or an intercepted class.
    // TODO(ahe): Preserve descriptor for such classes.
  } else {
    fields = JS('', '#[""]', descriptor);
    if (fields is List) {
      fieldsMetadata = fields.getRange(1, fields.length).toList();
      fields = fields[0];
    }
    if (fields is! String) {
      // TODO(ahe): This is CSP mode.  Find a way to determine the
      // fields of this class.
      fields = '';
    }
  }
  var mirror = classMirrors[constructor];
  if (mirror == null) {
    mirror = new JsClassMirror(symbol, constructor, fields, fieldsMetadata);
    classMirrors[constructor] = mirror;
  }
  return mirror;
}

abstract class JsObjectMirror implements ObjectMirror {
  Future<InstanceMirror> setFieldAsync(Symbol fieldName, Object value) {
    return new Future<InstanceMirror>(() => this.setField(fieldName, value));
  }

  Future<InstanceMirror> getFieldAsync(Symbol fieldName) {
    return new Future<InstanceMirror>(() => this.getField(fieldName));
  }
}

class JsInstanceMirror extends JsObjectMirror implements InstanceMirror {
  final reflectee;

  JsInstanceMirror(this.reflectee);

  bool get hasReflectee => true;

  ClassMirror get type => reflectType(reflectee.runtimeType);

  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List<Object> positionalArguments,
                                     [Map<Symbol, dynamic> namedArguments]) {
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
        '${n(memberName)}\$${positionalArguments.length}', jsList);
  }

  InstanceMirror _invoke(Symbol name,
                         int type,
                         String mangledName,
                         List arguments) {
    // TODO(ahe): Get the argument names.
    List<String> argumentNames = [];
    Invocation invocation = createInvocationMirror(
        n(name), mangledName, type, arguments, argumentNames);

    return reflect(delegate(invocation));
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    _invoke(
        fieldName, JSInvocationMirror.SETTER, 'set\$${n(fieldName)}', [arg]);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    return _invoke(
        fieldName, JSInvocationMirror.GETTER, 'get\$${n(fieldName)}', []);
  }

  delegate(Invocation invocation) {
    return JSInvocationMirror.invokeFromMirror(invocation, reflectee);
  }

  String toString() => 'InstanceMirror($reflectee)';
}

class JsClassMirror extends JsObjectMirror implements ClassMirror {
  final Symbol simpleName;
  final _jsConstructor;
  final String _fields;
  final List _fieldsMetadata;
  List _metadata;
  // Set as side-effect of accessing JsLibraryMirror.classes.
  JsLibraryMirror _owner;

  JsClassMirror(this.simpleName,
                this._jsConstructor,
                this._fields,
                this._fieldsMetadata);

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);

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
    int fieldNumber = 0;
    for (String field in fields) {
      var metadata;
      if (_fieldsMetadata != null) {
        metadata = _fieldsMetadata[fieldNumber++];
      }
      JsVariableMirror mirror = new JsVariableMirror.from(field, metadata);
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
       '${n(simpleName)}_${n(fieldName)}', arg);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): This is extremely dangerous!!!
    return reflect(
        JS('', '#[#]', JS_CURRENT_ISOLATE(),
           '${n(simpleName)}_${n(fieldName)}'));
  }

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol,dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    String constructorName = '${n(simpleName)}\$${n(constructorName)}';
    return reflect(JS('', r'#[#].apply(#, #)', JS_CURRENT_ISOLATE(),
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
        _owner = reflectType(Object).owner;
      } else {
        for (var list in JsMirrorSystem.librariesByName.values) {
          for (JsLibraryMirror library in list) {
            // This will set _owner field on all clasess as a side
            // effect.  This gives us a fast path to reflect on a
            // class without parsing reflection data.
            library.classes;
          }
        }
      }
      if (_owner == null) {
        throw new StateError('Class "${n(simpleName)}" has no owner');
      }
    }
    return _owner;
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      _metadata = extractMetadata(JS('', '#.prototype', _jsConstructor));
    }
    return _metadata.map(reflect).toList();
  }

  String toString() => 'ClassMirror(${n(simpleName)})';
}

class JsVariableMirror implements VariableMirror {
  // TODO(ahe): The values in these fields are virtually untested.
  final Symbol simpleName;
  final String _jsName;
  final bool _readOnly;
  final _metadataFunction;
  DeclarationMirror _owner;
  List _metadata;

  JsVariableMirror(this.simpleName,
                   this._jsName,
                   this._readOnly,
                   this._metadataFunction);

  factory JsVariableMirror.from(String descriptor, metadataFunction) {
    int length = descriptor.length;
    var code = fieldCode(descriptor.codeUnitAt(length - 1));
    if (code == 0) {
      throw new ArgumentError('Bad field descriptor: $descriptor');
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
    return new JsVariableMirror(
        s(accessorName), jsName, readOnly, metadataFunction);
  }

  TypeMirror get type => JsMirrorSystem._dynamicType;

  DeclarationMirror get owner => _owner;

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      _metadata = (_metadataFunction == null)
          ? const [] : JS('', '#()', _metadataFunction);
    }
    return _metadata.map(reflect).toList();
  }

  static int fieldCode(int code) {
    if (code >= 60 && code <= 64) return code - 59;
    if (code >= 123 && code <= 126) return code - 117;
    if (code >= 37 && code <= 43) return code - 27;
    return 0;
  }
}

class JsClosureMirror extends JsInstanceMirror implements ClosureMirror {
  JsClosureMirror(reflectee) : super(reflectee);

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
      throw new ArgumentError('Cannot find callName on "$reflectee"');
    }
    int parameterCount = int.parse(callName.split(r'$')[1]);
    if (reflectee is BoundClosure) {
      var target = BoundClosure.targetOf(reflectee);
      var self = BoundClosure.selfOf(reflectee);
      return new JsMethodMirror(
          s(target), JS('', '#[#]', self, target), parameterCount);
    } else {
      var jsFunction = JS('', '#[#]', reflectee, callName);
      return new JsMethodMirror(s(callName), jsFunction, parameterCount);
    }
  }

  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]) {
    return reflect(
        Function.apply(reflectee, positionalArguments, namedArguments));
  }

  Future<InstanceMirror> applyAsync(List positionalArguments,
                                    [Map<Symbol, dynamic> namedArguments]) {
    return new Future<InstanceMirror>(
        () => apply(positionalArguments, namedArguments));
  }
}

class JsMethodMirror implements MethodMirror {
  final Symbol simpleName;
  final _jsFunction;
  final int _parameterCount;
  DeclarationMirror _owner;
  List _metadata;

  JsMethodMirror(this.simpleName, this._jsFunction, this._parameterCount);

  List<ParameterMirror> get parameters {
    // TODO(ahe): Fill the list with parameter mirrors.
    return new List<ParameterMirror>(_parameterCount);
  }

  DeclarationMirror get owner => _owner;

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      _metadata = extractMetadata(_jsFunction);
    }
    return _metadata.map(reflect).toList();
  }
}

Symbol computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  String ownerName = n(owner.qualifiedName);
  if (ownerName == '') return simpleName;
  return s('$ownerName.${n(simpleName)}');
}

List extractMetadata(victim) {
  var metadataFunction = JS('', '#["@"]', victim);
  return (metadataFunction == null)
      ? const [] : JS('', '#()', metadataFunction);
}
