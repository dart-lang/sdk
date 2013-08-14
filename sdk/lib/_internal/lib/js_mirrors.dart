// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:async';
import 'dart:collection' show UnmodifiableListView;
import 'dart:mirrors';

import 'dart:_foreign_helper' show
    JS,
    JS_CURRENT_ISOLATE,
    JS_CURRENT_ISOLATE_CONTEXT,
    JS_GET_NAME;
import 'dart:_collection-dev' as _symbol_dev;
import 'dart:_js_helper' show
    BoundClosure,
    Closure,
    JSInvocationMirror,
    JsCache,
    Null,
    Primitives,
    RuntimeError,
    createRuntimeType,
    createUnmangledInvocationMirror,
    runtimeTypeToString;
import 'dart:_interceptors' show
    Interceptor,
    JSExtendableArray;
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
  UnmodifiableMapView<Uri, LibraryMirror> _cachedLibraries;

  final IsolateMirror isolate = new JsIsolateMirror();

  TypeMirror get dynamicType => _dynamicType;
  TypeMirror get voidType => _voidType;

  final static TypeMirror _dynamicType =
      new JsTypeMirror(const Symbol('dynamic'));
  final static TypeMirror _voidType = new JsTypeMirror(const Symbol('void'));

  static final Map<String, List<LibraryMirror>> librariesByName =
      computeLibrariesByName();

  Map<Uri, LibraryMirror> get libraries {
    if (_cachedLibraries != null) return _cachedLibraries;
    Map<Uri, LibraryMirror> result = new Map();
    for (List<LibraryMirror> list in librariesByName.values) {
      for (LibraryMirror library in list) {
        result[library.uri] = library;
      }
    }
    return _cachedLibraries =
        new UnmodifiableMapView<Uri, LibraryMirror>(result);
  }

  Iterable<LibraryMirror> findLibrary(Symbol libraryName) {
    return new UnmodifiableListView<LibraryMirror>(
        librariesByName[n(libraryName)]);
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
      var fields = data[5];
      bool isRoot = data[6];
      List metadata = (metadataFunction == null)
          ? null : JS('List', '#()', metadataFunction);
      var libraries = result.putIfAbsent(name, () => <LibraryMirror>[]);
      libraries.add(
          new JsLibraryMirror(
              s(name), uri, classes, functions, metadata, fields, isRoot));
    }
    return result;
  }
}

abstract class JsMirror implements Mirror {
  const JsMirror();

  abstract String get _prettyName;

  String toString() => _prettyName;

  // TODO(ahe): Remove this method from the API.
  MirrorSystem get mirrors => currentJsMirrorSystem;

  _getField(JsMirror receiver) {
    throw new UnimplementedError();
  }

  void _setField(JsMirror receiver, Object arg) {
    throw new UnimplementedError();
  }

  _loadField(String name) {
    throw new UnimplementedError();
  }

  void _storeField(String name, Object arg) {
    throw new UnimplementedError();
  }
}

// This class is somewhat silly in the current implementation.
class JsIsolateMirror extends JsMirror implements IsolateMirror {
  final _isolateContext = JS_CURRENT_ISOLATE_CONTEXT();

  String get _prettyName => 'Isolate';

  String get debugName {
    String id = _isolateContext == null ? 'X' : _isolateContext.id.toString();
    // Using name similar to what the VM uses.
    return '${n(rootLibrary.simpleName)}-$id';
  }

  bool get isCurrent => JS_CURRENT_ISOLATE_CONTEXT() == _isolateContext;

  LibraryMirror get rootLibrary {
    return currentJsMirrorSystem.libraries.values.firstWhere(
        (JsLibraryMirror library) => library._isRoot);
  }
}

abstract class JsDeclarationMirror extends JsMirror
    implements DeclarationMirror {
  final Symbol simpleName;

  const JsDeclarationMirror(this.simpleName);

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);

  bool get isPrivate => n(simpleName).startsWith('_');

  bool get isTopLevel => owner != null && owner is LibraryMirror;

  // TODO(ahe): This should use qualifiedName.
  String toString() => "$_prettyName on '${n(simpleName)}'";

  List<JsMethodMirror> get _methods {
    throw new RuntimeError('Should not call _methods');
  }

  _invoke(List positionalArguments, Map<Symbol, dynamic> namedArguments) {
    throw new RuntimeError('Should not call _invoke');
  }

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
  final String _compactFieldSpecification;
  final bool _isRoot;
  List<JsMethodMirror> _cachedFunctionMirrors;
  List<JsVariableMirror> _cachedFields;
  UnmodifiableMapView<Symbol, ClassMirror> _cachedClasses;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedFunctions;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedGetters;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedSetters;
  UnmodifiableMapView<Symbol, VariableMirror> _cachedVariables;
  UnmodifiableMapView<Symbol, Mirror> _cachedMembers;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;

  JsLibraryMirror(Symbol simpleName,
                  this.uri,
                  this._classes,
                  this._functions,
                  this._metadata,
                  this._compactFieldSpecification,
                  this._isRoot)
      : super(simpleName);

  String get _prettyName => 'LibraryMirror';

  Symbol get qualifiedName => simpleName;

  List<JsMethodMirror> get _methods => _functionMirrors;

  Map<Symbol, ClassMirror> get classes {
    if (_cachedClasses != null) return _cachedClasses;
    var result = new Map();
    for (String className in _classes) {
      var cls = reflectClassByMangledName(className);
      if (cls is JsClassMirror) {
        result[cls.simpleName] = cls;
        cls._owner = this;
      }
    }
    return _cachedClasses =
        new UnmodifiableMapView<Symbol, ClassMirror>(result);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    String name = n(fieldName);
    if (name.endsWith('=')) throw new ArgumentError('');
    var mirror = functions[s('$name=')];
    if (mirror == null) mirror = variables[fieldName];
    if (mirror == null) {
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(this, '${n(fieldName)}=', [arg], null);
    }
    mirror._setField(this, arg);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    JsMirror mirror = members[fieldName];
    if (mirror == null) {
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(this, '${n(fieldName)}', [], null);
    }
    return reflect(mirror._getField(this));
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsDeclarationMirror mirror = members[memberName];
    if (mirror == null) {
      // TODO(ahe): Pass namedArguments when NoSuchMethodError has been
      // fixed to use Symbol.
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          this, '${n(memberName)}', positionalArguments, null);
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  _loadField(String name) {
    assert(JS('bool', '# in #', name, JS_CURRENT_ISOLATE()));
    return JS('', '#[#]', JS_CURRENT_ISOLATE(), name);
  }

  void _storeField(String name, Object arg) {
    assert(JS('bool', '# in #', name, JS_CURRENT_ISOLATE()));
    JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), name, arg);
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

  List<VariableMirror> get _fields {
    if (_cachedFields != null) return _cachedFields;
    var result = <VariableMirror>[];
    parseCompactFieldSpecification(
        this, _compactFieldSpecification, true, result);
    return _cachedFields = result;
  }

  Map<Symbol, MethodMirror> get functions {
    if (_cachedFunctions != null) return _cachedFunctions;
    var result = new Map();
    for (JsMethodMirror mirror in _functionMirrors) {
      if (!mirror.isConstructor) result[mirror.simpleName] = mirror;
    }
    return _cachedFunctions =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get getters {
    if (_cachedGetters != null) return _cachedGetters;
    var result = new Map();
    // TODO(ahe): Implement this.
    return _cachedGetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get setters {
    if (_cachedSetters != null) return _cachedSetters;
    var result = new Map();
    // TODO(ahe): Implement this.
    return _cachedSetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, VariableMirror> get variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in _fields) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, Mirror> get members {
    if (_cachedMembers !=  null) return _cachedMembers;
    Map<Symbol, Mirror> result = new Map.from(classes);
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }
    functions.forEach(addToResult);
    getters.forEach(addToResult);
    setters.forEach(addToResult);
    variables.forEach(addToResult);
    return _cachedMembers = new UnmodifiableMapView<Symbol, Mirror>(result);
  }

  List<InstanceMirror> get metadata {
    if (_cachedMetadata != null) return _cachedMetadata;
    preserveMetadata();
    return _cachedMetadata =
        new UnmodifiableListView<InstanceMirror>(_metadata.map(reflect));
  }

  // TODO(ahe): Test this getter.
  DeclarationMirror get owner => null;
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

ClassMirror reflectType(Type key) {
  // TODO(ahe): Don't discard type arguments to support
  // [ClassMirror.isOriginalDeclaration] and [ClassMirror.originalDeclaration]
  // correctly.
  return reflectClassByMangledName('$key'.split('<')[0]);
}

ClassMirror reflectClassByMangledName(String mangledName) {
  String unmangledName = mangledGlobalNames[mangledName];
  if (unmangledName == null) unmangledName = mangledName;
  return reflectClassByName(s(unmangledName), mangledName);
}

var classMirrors;

ClassMirror reflectClassByName(Symbol symbol, String mangledName) {
  if (classMirrors == null) classMirrors = JsCache.allocate();
  var mirror = JsCache.fetch(classMirrors, mangledName);
  if (mirror != null) return mirror;
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

  var superclassName = fields.split(';')[0];
  var mixins = superclassName.split('+');
  if (mixins.length > 1 && mangledGlobalNames[mangledName] == null) {
    mirror = reflectMixinApplication(mixins, mangledName);
  } else {
    mirror = new JsClassMirror(
        symbol, mangledName, constructorOrInterceptor, fields, fieldsMetadata);
  }

  JsCache.update(classMirrors, mangledName, mirror);
  return mirror;
}

int counter = 0;

ClassMirror reflectMixinApplication(mixinNames, String mangledName) {
  disableTreeShaking();
  var mixins = [];
  for (String mangledName in mixinNames) {
    mixins.add(reflectClassByMangledName(mangledName));
  }
  var it = mixins.iterator;
  it.moveNext();
  var superclass = it.current;
  while (it.moveNext()) {
    superclass = new JsMixinApplication(superclass, it.current, mangledName);
  }
  return superclass;
}

class JsMixinApplication extends JsTypeMirror with JsObjectMirror
    implements ClassMirror {
  final ClassMirror superclass;
  final ClassMirror mixin;

  JsMixinApplication(ClassMirror superclass, ClassMirror mixin,
                     String mangledName)
      : this.superclass = superclass,
        this.mixin = mixin,
        super(s(mangledName));

  String get _prettyName => 'ClassMirror';

  Symbol get simpleName {
    return s('${n(mixin.qualifiedName)}(${n(superclass.qualifiedName)})');
  }

  Symbol get qualifiedName => simpleName;

  Map<Symbol, Mirror> get members => mixin.members;

  Map<Symbol, MethodMirror> get methods => mixin.methods;

  Map<Symbol, MethodMirror> get getters => mixin.getters;

  Map<Symbol, MethodMirror> get setters => mixin.setters;

  Map<Symbol, VariableMirror> get variables => mixin.variables;

  InstanceMirror invoke(
      Symbol memberName,
      List positionalArguments,
      [Map<Symbol,dynamic> namedArguments]) {
    // TODO(ahe): Pass namedArguments when NoSuchMethodError has
    // been fixed to use Symbol.
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, n(memberName), positionalArguments, null);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, n(fieldName), null, null);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, '${n(fieldName)}=', [arg], null);
  }

  List<ClassMirror> get superinterfaces => mixin.superinterfaces;

  Map<Symbol, MethodMirror> get constructors => mixin.constructors;

  InstanceMirror newInstance(
      Symbol constructorName,
      List positionalArguments,
      [Map<Symbol,dynamic> namedArguments]) {
    throw new UnsupportedError(
        "Can't instantiate mixin application '${n(qualifiedName)}'");
  }

  Future<InstanceMirror> newInstanceAsync(
      Symbol constructorName,
      List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return new Future<InstanceMirror>(
        () => this.newInstance(
            constructorName, positionalArguments, namedArguments));
  }

  bool get isOriginalDeclaration => true;

  ClassMirror get originalDeclaration => this;

  // TODO(ahe): Implement these.
  Map<Symbol, TypeVariableMirror> get typeVariables {
    throw new UnimplementedError();
  }
  Map<Symbol, TypeMirror> get typeArguments => throw new UnimplementedError();
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
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    return
        new Future<InstanceMirror>(
            () => invoke(memberName, positionalArguments, namedArguments));
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    String reflectiveName =
        JS('String', '# + ":" + # + ":0"',
           n(memberName), positionalArguments.length);
    // We can safely pass positionalArguments to _invoke as it will wrap it in
    // a JSArray if needed.
    return _invoke(memberName, JSInvocationMirror.METHOD, reflectiveName,
                   positionalArguments);
  }

  InstanceMirror _invoke(Symbol name,
                         int type,
                         String reflectiveName,
                         List arguments) {
    String cacheName = Primitives.mirrorInvokeCacheName;
    var cache = JS('', r'#.constructor[#]', reflectee, cacheName);
    if (cache == null) {
      cache = JsCache.allocate();
      JS('void', r'#.constructor[#] = #', reflectee, cacheName, cache);
    }
    var cacheEntry = JsCache.fetch(cache, reflectiveName);
    var result;
    Invocation invocation;
    if (cacheEntry == null) {
      disableTreeShaking();
      String mangledName = reflectiveNames[reflectiveName];
      // TODO(ahe): Get the argument names.
      List<String> argumentNames = [];
      // TODO(ahe): We don't need to create an invocation mirror here. The
      // logic from JSInvocationMirror.getCachedInvocation could easily be
      // inlined here.
      invocation = createUnmangledInvocationMirror(
          name, mangledName, type, arguments, argumentNames);

      cacheEntry =
          JSInvocationMirror.getCachedInvocation(invocation, reflectee);
      JsCache.update(cache, reflectiveName, cacheEntry);
    }
    if (cacheEntry.isNoSuchMethod) {
      if (invocation == null) {
        String mangledName = reflectiveNames[reflectiveName];
        // TODO(ahe): Get the argument names.
        List<String> argumentNames = [];
        invocation = createUnmangledInvocationMirror(
            name, mangledName, type, arguments, argumentNames);
      }
      return reflect(cacheEntry.invokeOn(reflectee, invocation));
    } else {
      return reflect(cacheEntry.invokeOn(reflectee, arguments));
    }
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    String reflectiveName = '${n(fieldName)}=';
    _invoke(
        s(reflectiveName), JSInvocationMirror.SETTER, reflectiveName, [arg]);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    String reflectiveName = n(fieldName);
    return _invoke(fieldName, JSInvocationMirror.GETTER, reflectiveName, []);
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
  final String _mangledName;
  final _jsConstructorOrInterceptor;
  final String _fieldsDescriptor;
  final List _fieldsMetadata;
  final _jsConstructorCache = JsCache.allocate();
  List _metadata;
  ClassMirror _superclass;
  List<JsMethodMirror> _cachedMethods;
  List<JsVariableMirror> _cachedFields;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedConstructors;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedMethodsMap;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedGetters;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedSetters;
  UnmodifiableMapView<Symbol, VariableMirror> _cachedVariables;
  UnmodifiableMapView<Symbol, Mirror> _cachedMembers;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;

  // Set as side-effect of accessing JsLibraryMirror.classes.
  JsLibraryMirror _owner;

  JsClassMirror(Symbol simpleName,
                this._mangledName,
                this._jsConstructorOrInterceptor,
                this._fieldsDescriptor,
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
    if (_cachedConstructors != null) return _cachedConstructors;
    var result = new Map();
    for (JsMethodMirror method in _methods) {
      if (method.isConstructor) {
        result[method.simpleName] = method;
      }
    }
    return _cachedConstructors =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  List<JsMethodMirror> get _methods {
    if (_cachedMethods != null) return _cachedMethods;
    var prototype = JS('', '#.prototype', _jsConstructor);
    List<String> keys = extractKeys(prototype);
    var result = <JsMethodMirror>[];
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

    keys = extractKeys(JS('', 'init.statics[#]', _mangledName));
    int length = keys.length;
    for (int i = 0; i < length; i++) {
      String mangledName = keys[i];
      String unmangledName = mangledName;
      // TODO(ahe): Create accessor for accessing $.  It is also
      // used in js_helper.
      var jsFunction = JS('', '#[#]', JS_CURRENT_ISOLATE(), mangledName);

      bool isConstructor = false;
      if (i + 1 < length) {
        String reflectionName = keys[i + 1];
        if (reflectionName.startsWith('+')) {
          i++;
          reflectionName = reflectionName.substring(1);
          isConstructor = reflectionName.startsWith('new ');
          if (isConstructor) {
            reflectionName = reflectionName.substring(4).replaceAll(r'$', '.');
          }
        }
        unmangledName = reflectionName;
      }
      bool isStatic = !isConstructor; // Constructors are not static.
      JsMethodMirror mirror =
          new JsMethodMirror.fromUnmangledName(
              unmangledName, jsFunction, isStatic, isConstructor);
      result.add(mirror);
      mirror._owner = this;
    }

    return _cachedMethods = result;
  }

  List<VariableMirror> get _fields {
    if (_cachedFields != null) return _cachedFields;
    var result = <VariableMirror>[];

    var instanceFieldSpecfication = _fieldsDescriptor.split(';')[1];
    if (_fieldsMetadata != null) {
      instanceFieldSpecfication =
          [instanceFieldSpecfication]..addAll(_fieldsMetadata);
    }
    parseCompactFieldSpecification(
        this, instanceFieldSpecfication, false, result);

    var staticDescriptor = JS('', 'init.statics[#]', _mangledName);
    if (staticDescriptor != null) {
      parseCompactFieldSpecification(
          this, JS('', '#[""]', staticDescriptor), true, result);
    }
    _cachedFields = result;
    return _cachedFields;
  }

  Map<Symbol, MethodMirror> get methods {
    if (_cachedMethodsMap != null) return _cachedMethodsMap;
    var result = new Map();
    for (JsMethodMirror method in _methods) {
      if (!method.isConstructor && !method.isGetter && !method.isSetter) {
        result[method.simpleName] = method;
      }
    }
    return _cachedMethodsMap =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get getters {
    if (_cachedGetters != null) return _cachedGetters;
    // TODO(ahe): This is a hack to remove getters corresponding to a field.
    var fields = variables;

    var result = new Map();
    for (JsMethodMirror method in _methods) {
      if (method.isGetter) {

        // TODO(ahe): This is a hack to remove getters corresponding to a field.
        if (fields[method.simpleName] != null) continue;

        result[method.simpleName] = method;
      }
    }
    return _cachedGetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get setters {
    if (_cachedSetters != null) return _cachedSetters;
    // TODO(ahe): This is a hack to remove setters corresponding to a field.
    var fields = variables;

    var result = new Map();
    for (JsMethodMirror method in _methods) {
      if (method.isSetter) {

        // TODO(ahe): This is a hack to remove setters corresponding to a field.
        String name = n(method.simpleName);
        name = name.substring(0, name.length - 1); // Remove '='.
        if (fields[s(name)] != null) continue;

        result[method.simpleName] = method;
      }
    }
    return _cachedSetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, VariableMirror> get variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in _fields) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, Mirror> get members {
    if (_cachedMembers != null) return _cachedMembers;
    Map<Symbol, Mirror> result = new Map.from(variables);
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
    return _cachedMembers = new UnmodifiableMapView<Symbol, Mirror>(result);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    JsVariableMirror mirror = variables[fieldName];
    if (mirror != null && mirror.isStatic && !mirror.isFinal) {
      String jsName = mirror._jsName;
      if (!JS('bool', '# in #', jsName, JS_CURRENT_ISOLATE())) {
        throw new RuntimeError('Cannot find "$jsName" in current isolate.');
      }
      JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), jsName, arg);
      return reflect(arg);
    }
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, '${n(fieldName)}=', [arg], null);
  }

  InstanceMirror getField(Symbol fieldName) {
    JsVariableMirror mirror = variables[fieldName];
    if (mirror != null && mirror.isStatic) {
      String jsName = mirror._jsName;
      if (!JS('bool', '# in #', jsName, JS_CURRENT_ISOLATE())) {
        throw new RuntimeError('Cannot find "$jsName" in current isolate.');
      }
      if (JS('bool', '# in init.lazies', jsName)) {
        String getterName = JS('String', 'init.lazies[#]', jsName);
        return reflect(JS('', '#[#]()', JS_CURRENT_ISOLATE(), getterName));
      } else {
        return reflect(JS('', '#[#]', JS_CURRENT_ISOLATE(), jsName));
      }
    }
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, n(fieldName), null, null);
  }

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsMethodMirror mirror =
        JsCache.fetch(_jsConstructorCache, n(constructorName));
    if (mirror == null) {
      mirror = constructors.values.firstWhere(
          (m) => m.constructorName == constructorName,
          orElse: () {
            // TODO(ahe): Pass namedArguments when NoSuchMethodError has been
            // fixed to use Symbol.
            // TODO(ahe): What receiver to use?
            throw new NoSuchMethodError(
                owner, n(constructorName), positionalArguments, null);
          });
      JsCache.update(_jsConstructorCache, n(constructorName), mirror);
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  Future<InstanceMirror> newInstanceAsync(
      Symbol constructorName,
      List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
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
    if (_cachedMetadata != null) return _cachedMetadata;
    if (_metadata == null) {
      _metadata = extractMetadata(JS('', '#.prototype', _jsConstructor));
    }
    return _cachedMetadata =
        new UnmodifiableListView<InstanceMirror>(_metadata.map(reflect));
  }

  ClassMirror get superclass {
    if (_superclass == null) {
      var superclassName = _fieldsDescriptor.split(';')[0];
      var mixins = superclassName.split('+');
      if (mixins.length > 1) {
        if (mixins.length != 2) {
          throw new RuntimeError('Strange mixin: $_fieldsDescriptor');
        }
        _superclass = reflectClassByMangledName(mixins[0]);
      } else {
        // Use _superclass == this to represent class with no superclass (Object).
        _superclass = (superclassName == '')
            ? this : reflectClassByMangledName(superclassName);
      }
    }
    return _superclass == this ? null : _superclass;
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    // Mirror API gotcha: Calling [invoke] on a ClassMirror means invoke a
    // static method.

    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsMethodMirror mirror = methods[memberName];
    if (mirror == null || !mirror.isStatic) {
      // TODO(ahe): Pass namedArguments when NoSuchMethodError has
      // been fixed to use Symbol.
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          this, n(memberName), positionalArguments, null);
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  bool get isOriginalDeclaration => true;

  ClassMirror get originalDeclaration => this;

  // TODO(ahe): Implement these.
  List<ClassMirror> get superinterfaces => throw new UnimplementedError();
  Map<Symbol, TypeVariableMirror> get typeVariables
      => throw new UnimplementedError();
  Map<Symbol, TypeMirror> get typeArguments => throw new UnimplementedError();
}

class JsVariableMirror extends JsDeclarationMirror implements VariableMirror {
  // TODO(ahe): The values in these fields are virtually untested.
  final String _jsName;
  final bool isFinal;
  final bool isStatic;
  final _metadataFunction;
  final DeclarationMirror _owner;
  List _metadata;

  JsVariableMirror(Symbol simpleName,
                   this._jsName,
                   this.isFinal,
                   this.isStatic,
                   this._metadataFunction,
                   this._owner)
      : super(simpleName);

  factory JsVariableMirror.from(String descriptor,
                                metadataFunction,
                                JsDeclarationMirror owner,
                                bool isStatic) {
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
    var unmangledName;
    if (isStatic) {
      unmangledName = mangledGlobalNames[accessorName];
    } else {
      String getterPrefix = JS_GET_NAME('GETTER_PREFIX');
      unmangledName = mangledNames['$getterPrefix$accessorName'];
    }
    if (unmangledName == null) unmangledName = accessorName;
    if (!hasSetter) {
      // TODO(ahe): This is a hack to handle checked setters in checked mode.
      var setterName = s('$unmangledName=');
      for (JsMethodMirror method in owner._methods) {
        if (method.simpleName == setterName) {
          isFinal = false;
          break;
        }
      }
    }
    return new JsVariableMirror(
        s(unmangledName), jsName, isFinal, isStatic, metadataFunction, owner);
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

  _getField(JsMirror receiver) => receiver._loadField(_jsName);

  void _setField(JsMirror receiver, Object arg) {
    if (isFinal) {
      throw new NoSuchMethodError(this, '${n(simpleName)}=', [arg], null);
    }
    receiver._storeField(_jsName, arg);
  }
}

class JsClosureMirror extends JsInstanceMirror implements ClosureMirror {
  JsClosureMirror(reflectee)
      : super(reflectee);

  MethodMirror get function {
    String cacheName = Primitives.mirrorFunctionCacheName;
    JsMethodMirror cachedFunction =
        JS('JsMethodMirror|Null', r'#.constructor[#]', reflectee, cacheName);
    if (cachedFunction != null) return cachedFunction;
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
      cachedFunction = new JsMethodMirror(
          s(target), JS('', '#[#]', self, target), parameterCount,
          false, false, isStatic, false, false);
    } else {
      var jsFunction = JS('', '#[#]', reflectee, callName);
      cachedFunction = new JsMethodMirror(
          s(callName), jsFunction, parameterCount,
          false, false, isStatic, false, false);
    }
    JS('void', r'#.constructor[#] = #', reflectee, cacheName, cachedFunction);
    return cachedFunction;
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
  final bool isOperator;
  DeclarationMirror _owner;
  List _metadata;
  var _returnType;
  UnmodifiableListView<ParameterMirror> _parameters;

  JsMethodMirror(Symbol simpleName,
                 this._jsFunction,
                 this._parameterCount,
                 this.isGetter,
                 this.isSetter,
                 this.isStatic,
                 this.isConstructor,
                 this.isOperator)
      : super(simpleName);

  factory JsMethodMirror.fromUnmangledName(String name,
                                           jsFunction,
                                           bool isStatic,
                                           bool isConstructor) {
    List<String> info = name.split(':');
    name = info[0];
    bool isOperator = isOperatorName(name);
    bool isSetter = !isOperator && name.endsWith('=');
    int requiredParameterCount = 0;
    int optionalParameterCount = 0;
    bool isGetter = false;
    if (info.length == 1) {
      if (isSetter) {
        requiredParameterCount = 1;
      } else {
        isGetter = true;
        requiredParameterCount = 0;
      }
    } else {
      requiredParameterCount = int.parse(info[1]);
      optionalParameterCount = int.parse(info[2]);
    }
    return new JsMethodMirror(
        s(name), jsFunction, requiredParameterCount + optionalParameterCount,
        isGetter, isSetter, isStatic, isConstructor, isOperator);
  }

  String get _prettyName => 'MethodMirror';

  List<ParameterMirror> get parameters {
    if (_parameters != null) return _parameters;
    metadata; // Compute _parameters as a side-effect of extracting metadata.
    return _parameters;
  }

  DeclarationMirror get owner => _owner;

  TypeMirror get returnType {
    metadata; // Compute _returnType as a side-effect of extracting metadata.
    return typeMirrorFromRuntimeTypeRepresentation(_returnType);
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      var raw = extractMetadata(_jsFunction);
      var formals = new List(_parameterCount);
      if (!raw.isEmpty) {
        _returnType = raw[0];
        int parameterLength = 1 + _parameterCount * 2;
        int formalsCount = 0;
        for (int i = 1; i < parameterLength; i += 2) {
          var name = raw[i];
          var type = raw[i + 1];
          formals[formalsCount++] = new JsParameterMirror(name, this, type);
        }
        raw = raw.sublist(parameterLength);
      } else {
        for (int i = 0; i < _parameterCount; i++) {
          formals[i] = new JsParameterMirror('argument$i', this, null);
        }
      }
      _parameters = new UnmodifiableListView<ParameterMirror>(formals);
      _metadata = new UnmodifiableListView(raw.map(reflect));
    }
    return _metadata;
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

  _invoke(List positionalArguments, Map<Symbol, dynamic> namedArguments) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    if (!isStatic && !isConstructor) {
      throw new RuntimeError('Cannot invoke instance method without receiver.');
    }
    if (_parameterCount != positionalArguments.length || _jsFunction == null) {
      // TODO(ahe): Pass namedArguments when NoSuchMethodError has
      // been fixed to use Symbol.
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          owner, n(simpleName), positionalArguments, null);
    }
    return JS('', r'#.apply(#, #)', _jsFunction, JS_CURRENT_ISOLATE(),
              new List.from(positionalArguments));
  }

  _getField(JsMirror receiver) {
    if (isGetter) {
      return _invoke([], null);
    } else {
      // TODO(ahe): Closurize method.
      throw new UnimplementedError('getField on $receiver');
    }
  }

  _setField(JsMirror receiver, Object arg) {
    if (isSetter) {
      return _invoke([arg], null);
    } else {
      throw new NoSuchMethodError(this, '${n(simpleName)}=', [], null);
    }
  }

  // Abstract methods are tree-shaken away.
  bool get isAbstract => false;

  // TODO(ahe): Test this.
  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  // TODO(ahe): Implement these.
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

  // TODO(ahe): Implement this.
  List<InstanceMirror> get metadata => throw new UnimplementedError();
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
  if (JS('String', 'typeof #', victim) != 'function') return const [];
  String source = JS('String', 'Function.prototype.toString.call(#)', victim);
  int index = source.lastIndexOf(new RegExp('"[0-9,]*";?[ \n\r]*}'));
  if (index == -1) return const [];
  index++;
  int endQuote = source.indexOf('"', index);
  return source.substring(index, endQuote).split(',').map(int.parse).map(
      (int i) => JS('', 'init.metadata[#]', i)).toList();
}

List<JsVariableMirror> parseCompactFieldSpecification(
    JsDeclarationMirror owner,
    fieldSpecification,
    bool isStatic,
    List<Mirror> result) {
  List fieldsMetadata = null;
  List<String> fieldNames;
  if (fieldSpecification is List) {
    fieldNames = splitFields(fieldSpecification[0], ',');
    fieldsMetadata = fieldSpecification.sublist(1);
  } else if (fieldSpecification is String) {
    fieldNames = splitFields(fieldSpecification, ',');
  } else {
    fieldNames = [];
  }
  int fieldNumber = 0;
  for (String field in fieldNames) {
    var metadata;
    if (fieldsMetadata != null) {
      metadata = fieldsMetadata[fieldNumber++];
    }
    var mirror = new JsVariableMirror.from(field, metadata, owner, isStatic);
    if (mirror != null) {
      result.add(mirror);
    }
  }
}

/// Similar to [String.split], but returns an empty list if [string] is empty.
List<String> splitFields(String string, Pattern pattern) {
  if (string.isEmpty) return <String>[];
  return string.split(pattern);
}

bool isOperatorName(String name) {
  switch (name) {
  case '==':
  case '[]':
  case '*':
  case '/':
  case '%':
  case '~/':
  case '+':
  case '<<':
  case '>>':
  case '>=':
  case '>':
  case '<=':
  case '<':
  case '&':
  case '^':
  case '|':
  case '-':
  case 'unary-':
  case '[]=':
  case '~':
    return true;
  default:
    return false;
  }
}

// Copied from package "unmodifiable_collection".
// TODO(ahe): Lobby to get it added to dart:collection.
class UnmodifiableMapView<K, V> implements Map<K, V> {
  Map<K, V> _source;
  UnmodifiableMapView(Map<K, V> source) : _source = source;

  static void _throw() {
    throw new UnsupportedError("Cannot modify an unmodifiable Map");
  }

  int get length => _source.length;

  bool get isEmpty => _source.isEmpty;

  bool get isNotEmpty => _source.isNotEmpty;

  V operator [](K key) => _source[key];

  bool containsKey(K key) => _source.containsKey(key);

  bool containsValue(V value) => _source.containsValue(value);

  void forEach(void f(K key, V value)) => _source.forEach(f);

  Iterable<K> get keys => _source.keys;

  Iterable<V> get values => _source.values;


  void operator []=(K key, V value) => _throw();

  V putIfAbsent(K key, V ifAbsent()) { _throw(); }

  void addAll(Map<K, V> other) => _throw();

  V remove(K key) { _throw(); }

  void clear() => _throw();
}
