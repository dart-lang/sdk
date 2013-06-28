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
    RuntimeError,
    createRuntimeType,
    createUnmangledInvocationMirror,
    runtimeTypeToString;
import 'dart:_interceptors' show Interceptor, JSExtendableArray;
import 'dart:_js_names';

/// No-op method that is called to inform the compiler that tree-shaking needs
/// to be disabled.
disableTreeShaking() => preserveNames();

/// No-op method that is called to inform the compiler that metadata must be
/// preserved at runtime.
preserveMetadata() {}

String getName(Symbol symbol) {
  preserveNames();
  return n(symbol);
}

class JsMirrorSystem implements MirrorSystem {
  TypeMirror get dynamicType => _dynamicType;
  TypeMirror get voidType => _voidType;

  final static TypeMirror _dynamicType =
      new JsTypeMirror(const Symbol('dynamic'));
  final static TypeMirror _voidType = new JsTypeMirror(const Symbol('void'));

  static final Map<String, List<LibraryMirror>> librariesByName =
      computeLibrariesByName();

  Map<Uri, LibraryMirror> get libraries {
    Map<Uri, LibraryMirror> result = new Map<Uri, LibraryMirror>();
    for (List<LibraryMirror> list in librariesByName.values) {
      for (LibraryMirror library in list) {
        result[library.uri] = library;
      }
    }
    return result;
  }

  Iterable<LibraryMirror> findLibrary(Symbol libraryName) {
    return new List<LibraryMirror>.from(librariesByName[n(libraryName)]);
  }

  static Map<String, List<LibraryMirror>> computeLibrariesByName() {
    disableTreeShaking();
    var result = new Map<String, List<LibraryMirror>>();
    var jsLibraries = JS('JSExtendableArray|Null', 'init.libraries');
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

  // TODO(ahe): Implement this.
  IsolateMirror get isolate => throw new UnimplementedError();
}

abstract class JsMirror {
  const JsMirror();

  abstract String get _prettyName;

  String toString() => _prettyName;

  // TODO(ahe): Remove this method from the API.
  MirrorSystem get mirrors => currentJsMirrorSystem;
}

abstract class JsDeclarationMirror extends JsMirror
    implements DeclarationMirror {
  final Symbol simpleName;

  const JsDeclarationMirror(this.simpleName);

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);

  bool get isPrivate => n(simpleName).startsWith('_');

  bool get isTopLevel => owner != null && owner is LibraryMirror;

  String toString() => "$_prettyName on '${n(simpleName)}'";

  // TODO(ahe): Implement this.
  SourceLocation get location => throw new UnimplementedError();
}

class JsTypeMirror extends JsDeclarationMirror implements TypeMirror {
  JsTypeMirror(Symbol simpleName)
      : super(simpleName);

  String get _prettyName => 'TypeMirror';

  DeclarationMirror get owner => null;

  // TODO(ahe): Doesn't match the specification, see http://dartbug.com/11569.
  bool get isTopLevel => true;

  // TODO(ahe): Implement this.
  List<InstanceMirror> get metadata => throw new UnimplementedError();
}

class JsLibraryMirror extends JsDeclarationMirror with JsObjectMirror
    implements LibraryMirror {
  final Uri uri;
  final List<String> _classes;
  final List<String> _functions;
  final List _metadata;
  List<JsMethodMirror> _cachedFunctionMirrors;

  JsLibraryMirror(Symbol simpleName,
                 this.uri,
                 this._classes,
                 this._functions,
                 this._metadata)
      : super(simpleName);

  String get _prettyName => 'LibraryMirror';

  Symbol get qualifiedName => simpleName;

  Map<Symbol, ClassMirror> get classes {
    var result = new Map<Symbol, ClassMirror>();
    for (String className in _classes) {
      JsClassMirror cls = reflectClassByMangledName(className);
      result[cls.simpleName] = cls;
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

  List<JsMethodMirror> get _functionMirrors {
    if (_cachedFunctionMirrors != null) return _cachedFunctionMirrors;
    var result = new List<JsMethodMirror>(_functions.length);
    for (int i = 0; i < _functions.length; i++) {
      String name = _functions[i];
      // TODO(ahe): Create accessor for accessing $.  It is also
      // used in js_helper.
      var jsFunction = JS('', '#[#]', JS_CURRENT_ISOLATE(), name);
      String unmangledName = mangledGlobalNames[name];
      if (unmangledName == null) unmangledName = name;
      bool isConstructor = unmangledName.startsWith('new ');
      bool isStatic = !isConstructor; // Top-level functions are static, but
                                      // constructors are not.
      if (isConstructor) {
        unmangledName = unmangledName.substring(4).replaceAll(r'$', '.');
      }
      JsMethodMirror mirror =
          new JsMethodMirror.fromUnmangledName(
              unmangledName, jsFunction, isStatic, isConstructor);
      result[i] = mirror;
      mirror._owner = this;
    }
    return _cachedFunctionMirrors = result;
  }

  Map<Symbol, MethodMirror> get functions {
    var result = new Map<Symbol, MethodMirror>();
    for (JsMethodMirror mirror in _functionMirrors) {
      if (!mirror.isConstructor) result[mirror.simpleName] = mirror;
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

  List<InstanceMirror> get metadata {
    preserveMetadata();
    return _metadata.map(reflect).toList();
  }

  // TODO(ahe): Implement these.
  DeclarationMirror get owner => throw new UnimplementedError();
  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    throw new UnimplementedError();
  }
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

ClassMirror reflectType(Type key) {
  return reflectClassByMangledName('$key'.split('<')[0]);
}

ClassMirror reflectClassByMangledName(String mangledName) {
  String unmangledName = mangledGlobalNames[mangledName];
  if (unmangledName == null) unmangledName = mangledName;
  return reflectClassByName(s(unmangledName), mangledName);
}

ClassMirror reflectClassByName(Symbol symbol, String mangledName) {
  disableTreeShaking();
  var constructorOrInterceptor =
      Primitives.getConstructorOrInterceptor(mangledName);
  if (constructorOrInterceptor == null) {
    // Probably an intercepted class.
    // TODO(ahe): How to handle intercepted classes?
    throw new UnsupportedError('Cannot find class for: ${n(symbol)}');
  }
  var constructor = (constructorOrInterceptor is Interceptor)
      ? JS('', '#.constructor', constructorOrInterceptor)
      : constructorOrInterceptor;
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
  var mirror = classMirrors[constructorOrInterceptor];
  if (mirror == null) {
    mirror = new JsClassMirror(
        symbol, constructorOrInterceptor, fields, fieldsMetadata);
    classMirrors[constructorOrInterceptor] = mirror;
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

  Future<InstanceMirror> invokeAsync(Symbol memberName,
                                     List positionalArguments,
                                     [Map<Symbol, dynamic> namedArguments]) {
    return new Future<InstanceMirror>(
        () => this.invoke(memberName, positionalArguments, namedArguments));
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
    String reflectiveName = '${n(memberName)}:${positionalArguments.length}:0';
    String mangledName = reflectiveNames[reflectiveName];
    return _invoke(memberName, JSInvocationMirror.METHOD, mangledName, jsList);
  }

  InstanceMirror _invoke(Symbol name,
                         int type,
                         String mangledName,
                         List arguments) {
    disableTreeShaking();
    // TODO(ahe): Get the argument names.
    List<String> argumentNames = [];
    Invocation invocation = createUnmangledInvocationMirror(
        name, mangledName, type, arguments, argumentNames);

    return reflect(delegate(invocation));
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    String reflectiveName = '${n(fieldName)}=';
    String mangledName = reflectiveNames[reflectiveName];
    _invoke(s(reflectiveName), JSInvocationMirror.SETTER, mangledName, [arg]);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    String reflectiveName = n(fieldName);
    String mangledName = reflectiveNames[reflectiveName];
    return _invoke(fieldName, JSInvocationMirror.GETTER, mangledName, []);
  }

  delegate(Invocation invocation) {
    return JSInvocationMirror.invokeFromMirror(invocation, reflectee);
  }

  String toString() => 'InstanceMirror on ${Error.safeToString(reflectee)}';

  // TODO(ahe): Remove this method from the API.
  MirrorSystem get mirrors => currentJsMirrorSystem;
}

class JsClassMirror extends JsTypeMirror with JsObjectMirror
    implements ClassMirror {
  final _jsConstructorOrInterceptor;
  final String _fields;
  final List _fieldsMetadata;
  List _metadata;
  JsClassMirror _superclass;
  List<JsMethodMirror> _cachedMethods;

  // Set as side-effect of accessing JsLibraryMirror.classes.
  JsLibraryMirror _owner;

  JsClassMirror(Symbol simpleName,
                this._jsConstructorOrInterceptor,
                this._fields,
                this._fieldsMetadata)
      : super(simpleName);

  String get _prettyName => 'ClassMirror';

  get _jsConstructor {
    if (_jsConstructorOrInterceptor is Interceptor) {
      return JS('', '#.constructor', _jsConstructorOrInterceptor);
    } else {
      return _jsConstructorOrInterceptor;
    }
  }

  Map<Symbol, MethodMirror> get constructors {
    Map<Symbol, MethodMirror> result = new Map<Symbol, MethodMirror>();
    JsLibraryMirror library = owner;
    String unmangledName = n(simpleName);
    for (JsMethodMirror mirror in library._functionMirrors) {
      Symbol name = mirror.simpleName;
      if (mirror.isConstructor
          && (name == simpleName || n(name).startsWith('$unmangledName.'))) {
        result[name] = mirror;
        mirror._owner = this;
      }
    }
    return result;
  }

  List<JsMethodMirror> get _methods {
    if (_cachedMethods != null) return _cachedMethods;
    var prototype = JS('', '#.prototype', _jsConstructor);
    List<String> keys = extractKeys(prototype);
    var result = <JsMethodMirror>[];
    int i = 0;
    for (String key in keys) {
      if (key == '') continue;
      String simpleName = mangledNames[key];
      // [simpleName] can be null if [key] represents an implementation
      // detail, for example, a bailout method, or runtime type support.
      // It might also be null if the user has limited what is reified for
      // reflection with metadata.
      if (simpleName == null) continue;
      var function = JS('', '#[#]', prototype, key);
      var mirror =
          new JsMethodMirror.fromUnmangledName(
              simpleName, function, false, false);
      result.add(mirror);
      mirror._owner = this;
    }
    return _cachedMethods = result;
  }

  Map<Symbol, MethodMirror> get methods {
    var result = new Map<Symbol, MethodMirror>();
    for (JsMethodMirror method in _methods) {
      if (!method.isGetter && !method.isSetter) {
        result[method.simpleName] = method;
      }
    }
    return result;
  }

  Map<Symbol, MethodMirror> get getters {
    // TODO(ahe): Should this include getters for fields?
    var result = new Map<Symbol, MethodMirror>();
    for (JsMethodMirror method in _methods) {
      if (method.isGetter) {
        result[method.simpleName] = method;
      }
    }
    return result;
  }

  Map<Symbol, MethodMirror> get setters {
    // TODO(ahe): Should this include setters for fields?
    var result = new Map<Symbol, MethodMirror>();
    for (JsMethodMirror method in _methods) {
      if (method.isSetter) {
        result[method.simpleName] = method;
      }
    }
    return result;
  }

  Map<Symbol, VariableMirror> get variables {
    var result = new Map<Symbol, VariableMirror>();
    var s = _fields.split(';');
    var fields = s[1] == '' ? [] : s[1].split(',');
    int fieldNumber = 0;
    for (String field in fields) {
      var metadata;
      if (_fieldsMetadata != null) {
        metadata = _fieldsMetadata[fieldNumber++];
      }
      JsVariableMirror mirror = new JsVariableMirror.from(field, metadata);
      if (mirror != null) {
        result[mirror.simpleName] = mirror;
        mirror._owner = this;
      }
    }
    return result;
  }

  Map<Symbol, Mirror> get members {
    Map<Symbol, Mirror> result = new Map<Symbol, Mirror>.from(variables);
    for (JsMethodMirror method in _methods) {
      if (method.isSetter) {
        String name = n(method.simpleName);
        name = name.substring(0, name.length - 1);
        // Filter-out setters corresponding to variables.
        if (result[s(name)] is VariableMirror) continue;
      }
      // Use putIfAbsent to filter-out getters corresponding to variables.
      result.putIfAbsent(method.simpleName, () => method);
    }
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
                             [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented');
    }
    String reflectiveName = 'new ${n(simpleName)}';
    String name = n(constructorName);
    if (!name.isEmpty) {
      reflectiveName = '$reflectiveName\$$name';
    }
    reflectiveName = '$reflectiveName:${positionalArguments.length}:0';
    String mangledName = reflectiveGlobalNames[reflectiveName];
    var factory = JS('', '#[#]', JS_CURRENT_ISOLATE(), mangledName);
    if (factory == null) {
      // TODO(ahe): Pass namedArguments when NoSuchMethodError has
      // been fixed to use Symbol.
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          this, reflectiveName, positionalArguments, null);
    }
    return reflect(JS('', r'#.apply(#, #)',
                      factory,
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
      if (_jsConstructorOrInterceptor is Interceptor) {
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

  ClassMirror get superclass {
    if (_superclass == null) {
      var superclassName = _fields.split(';')[0];
      // Use _superclass == this to represent class with no superclass (Object).
      _superclass = (superclassName == '')
          ? this : reflectClassByMangledName(superclassName);
    }
    return _superclass == this ? null : _superclass;
  }

  // TODO(ahe): Implement these;
  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    throw new UnimplementedError();
  }
  List<ClassMirror> get superinterfaces => throw new UnimplementedError();
  Map<Symbol, TypeVariableMirror> get typeVariables
      => throw new UnimplementedError();
  Map<Symbol, TypeMirror> get typeArguments => throw new UnimplementedError();
  bool get isOriginalDeclaration => throw new UnimplementedError();
  ClassMirror get originalDeclaration => throw new UnimplementedError();
  bool get isClass => throw new UnimplementedError();
  ClassMirror get defaultFactory => throw new UnimplementedError();
}

class JsVariableMirror extends JsDeclarationMirror implements VariableMirror {
  // TODO(ahe): The values in these fields are virtually untested.
  final String _jsName;
  final bool isFinal;
  final bool isStatic;
  final _metadataFunction;
  DeclarationMirror _owner;
  List _metadata;

  JsVariableMirror(Symbol simpleName,
                   this._jsName,
                   this.isFinal,
                   this.isStatic,
                   this._metadataFunction)
      : super(simpleName);

  factory JsVariableMirror.from(String descriptor, metadataFunction) {
    int length = descriptor.length;
    var code = fieldCode(descriptor.codeUnitAt(length - 1));
    bool isFinal = false;
    if (code == 0) return null; // Inherited field.
    bool hasGetter = (code & 3) != 0;
    bool hasSetter = (code >> 2) != 0;
    isFinal = !hasSetter;
    length--;
    String jsName;
    String accessorName = jsName = descriptor.substring(0, length);
    int divider = descriptor.indexOf(':');
    if (divider > 0) {
      accessorName = accessorName.substring(0, divider);
      jsName = accessorName.substring(divider + 1);
    }
    return new JsVariableMirror(
        s(accessorName), jsName, isFinal, false, metadataFunction);
  }

  String get _prettyName => 'VariableMirror';

  // TODO(ahe): Improve this information and test it.
  TypeMirror get type => JsMirrorSystem._dynamicType;

  DeclarationMirror get owner => _owner;

  List<InstanceMirror> get metadata {
    preserveMetadata();
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
  JsClosureMirror(reflectee)
      : super(reflectee);

  MethodMirror get function {
    disableTreeShaking();
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
    int parameterCount = int.parse(callName.split(r'$')[1]);
    bool isStatic = true; // TODO(ahe): Compute isStatic correctly.
    if (reflectee is BoundClosure) {
      var target = BoundClosure.targetOf(reflectee);
      var self = BoundClosure.selfOf(reflectee);
      return new JsMethodMirror(
          s(target), JS('', '#[#]', self, target), parameterCount,
          false, false, isStatic, false);
    } else {
      var jsFunction = JS('', '#[#]', reflectee, callName);
      return new JsMethodMirror(
          s(callName), jsFunction, parameterCount,
          false, false, isStatic, false);
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

  String toString() => "ClosureMirror on '${Error.safeToString(reflectee)}'";

  // TODO(ahe): Implement these.
  String get source => throw new UnimplementedError();
  Future<InstanceMirror> findInContext(Symbol name)
      => throw new UnimplementedError();
}

class JsMethodMirror extends JsDeclarationMirror implements MethodMirror {
  final _jsFunction;
  final int _parameterCount;
  final bool isGetter;
  final bool isSetter;
  final bool isStatic;
  final bool isConstructor;
  DeclarationMirror _owner;
  List _metadata;
  var _returnType;
  var _parameters;

  JsMethodMirror(Symbol simpleName,
                 this._jsFunction,
                 this._parameterCount,
                 this.isGetter,
                 this.isSetter,
                 this.isStatic,
                 this.isConstructor)
      : super(simpleName);

  factory JsMethodMirror.fromUnmangledName(String name,
                                           jsFunction,
                                           bool isStatic,
                                           bool isConstructor) {
    List<String> info = name.split(':');
    name = info[0];
    bool isSetter = name.endsWith('=');
    int requiredParameterCount = 0;
    int optionalParameterCount = 0;
    bool isGetter = false;
    if (info.length == 1) {
      if (isSetter) {
        requiredParameterCount = 2;
      } else {
        isGetter = true;
        requiredParameterCount = 1;
      }
    } else {
      requiredParameterCount = int.parse(info[1]);
      optionalParameterCount = int.parse(info[2]);
    }
    return new JsMethodMirror(
        s(name), jsFunction, requiredParameterCount + optionalParameterCount,
        isGetter, isSetter, isStatic, isConstructor);
  }

  String get _prettyName => 'MethodMirror';

  List<ParameterMirror> get parameters {
    metadata; // Compute _parameters as a side-effect of extracting metadata.
    return new List<ParameterMirror>.from(_parameters);
  }

  DeclarationMirror get owner => _owner;

  TypeMirror get returnType {
    metadata; // Compute _returnType as a side-effect of extracting metadata.
    return typeMirrorFromRuntimeTypeRepresentation(_returnType);
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      var raw = extractMetadata(_jsFunction);
      _returnType = raw[0];
      int parameterLength = 1 + _parameterCount * 2;
      var formals = new List<ParameterMirror>(_parameterCount);
      int formalsCount = 0;
      for (int i = 1; i < parameterLength; i += 2) {
        var name = raw[i];
        var type = raw[i + 1];
        formals[formalsCount++] = new JsParameterMirror(name, this, type);
      }
      _parameters = formals;
      _metadata = raw.sublist(parameterLength);
    }
    return _metadata.map(reflect).toList();
  }

  Symbol get constructorName {
    // TODO(ahe): I believe it is more appropriate to throw an exception or
    // return null.
    if (!isConstructor) return const Symbol('');
    String name = n(simpleName);
    int index = name.indexOf('.');
    if (index == -1) return const Symbol('');
    return s(name.substring(index + 1));
  }

  // TODO(ahe): Implement these.
  bool get isAbstract => throw new UnimplementedError();
  bool get isRegularMethod => throw new UnimplementedError();
  bool get isOperator => throw new UnimplementedError();
  bool get isConstConstructor => throw new UnimplementedError();
  bool get isGenerativeConstructor => throw new UnimplementedError();
  bool get isRedirectingConstructor => throw new UnimplementedError();
  bool get isFactoryConstructor => throw new UnimplementedError();
}

class JsParameterMirror extends JsDeclarationMirror implements ParameterMirror {
  final JsMethodMirror owner;
  // A JS object representing the type.
  final _type;

  JsParameterMirror(String unmangledName, this.owner, this._type)
      : super(s(unmangledName));

  String get _prettyName => 'ParameterMirror';

  TypeMirror get type => typeMirrorFromRuntimeTypeRepresentation(_type);

  bool get isStatic => owner.isStatic;

  // TODO(ahe): Implement this.
  bool get isFinal => false;

  // TODO(ahe): Implement this.
  bool get isOptional => false;

  // TODO(ahe): Implement this.
  bool get isNamed => false;

  // TODO(ahe): Implement this.
  bool get hasDefaultValue => false;

  // TODO(ahe): Implement this.
  get defaultValue => null;
}

TypeMirror typeMirrorFromRuntimeTypeRepresentation(type) {
  if (type == null) return JsMirrorSystem._dynamicType;
  String representation = runtimeTypeToString(type);
  if (representation == null) return reflectClass(Function);
  return reflectClass(createRuntimeType(representation));
}

Symbol computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  String ownerName = n(owner.qualifiedName);
  if (ownerName == '') return simpleName;
  return s('$ownerName.${n(simpleName)}');
}

List extractMetadata(victim) {
  preserveMetadata();
  var metadataFunction = JS('', '#["@"]', victim);
  if (metadataFunction != null) return JS('', '#()', metadataFunction);
  String source = JS('String', 'Function.prototype.toString.call(#)', victim);
  int index = source.lastIndexOf(new RegExp('"[0-9,]*";?[ \n\r]*}'));
  if (index == -1) return const [];
  index++;
  int endQuote = source.indexOf('"', index);
  return source.substring(index, endQuote).split(',').map(int.parse).map(
      (int i) => JS('', 'init.metadata[#]', i)).toList();
}
