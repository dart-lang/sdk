// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._js_mirrors;

import 'dart:_js_embedded_names'
    show
        JsGetName,
        ALL_CLASSES,
        LAZIES,
        LIBRARIES,
        STATICS,
        TYPE_INFORMATION,
        TYPEDEF_PREDICATE_PROPERTY_NAME,
        TYPEDEF_TYPE_PROPERTY_NAME;

import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;

import 'dart:mirrors';

import 'dart:_foreign_helper'
    show
        JS,
        JS_GET_FLAG,
        JS_GET_STATIC_STATE,
        JS_CURRENT_ISOLATE_CONTEXT,
        JS_EMBEDDED_GLOBAL,
        JS_GET_NAME;

import 'dart:_internal' as _symbol_dev;

import 'dart:_js_helper'
    show
        BoundClosure,
        CachedInvocation,
        Closure,
        JSInvocationMirror,
        JsCache,
        Primitives,
        ReflectionInfo,
        RuntimeError,
        TearOffClosure,
        TypeVariable,
        UnimplementedNoSuchMethodError,
        createRuntimeType,
        createUnmangledInvocationMirror,
        extractFunctionTypeObjectFrom,
        getMangledTypeName,
        getMetadata,
        getType,
        getRuntimeType,
        isDartFunctionType,
        runtimeTypeToString,
        setRuntimeTypeInfo,
        throwInvalidReflectionError,
        TypeImpl,
        deferredLoadHook;

import 'dart:_interceptors'
    show Interceptor, JSArray, JSExtendableArray, getInterceptor;

import 'dart:_js_names';

const String METHODS_WITH_OPTIONAL_ARGUMENTS = r'$methodsWithOptionalArguments';

bool hasReflectableProperty(var jsFunction) {
  return JS('bool', '# in #', JS_GET_NAME(JsGetName.REFLECTABLE), jsFunction);
}

/// No-op method that is called to inform the compiler that tree-shaking needs
/// to be disabled.
disableTreeShaking() => preserveNames();

/// No-op method that is called to inform the compiler that metadata must be
/// preserved at runtime.
preserveMetadata() {}

/// No-op method that is called to inform the compiler that the compiler must
/// preserve the URIs.
preserveUris() {}

/// No-op method that is called to inform the compiler that the compiler must
/// preserve the library names.
preserveLibraryNames() {}

String getName(Symbol symbol) {
  preserveNames();
  return n(symbol);
}

class JsMirrorSystem implements MirrorSystem {
  UnmodifiableMapView<Uri, LibraryMirror> _cachedLibraries;

  final IsolateMirror isolate = new JsIsolateMirror();

  JsTypeMirror get dynamicType => _dynamicType;
  JsTypeMirror get voidType => _voidType;

  static final JsTypeMirror _dynamicType =
      new JsTypeMirror(const Symbol('dynamic'));
  static final JsTypeMirror _voidType = new JsTypeMirror(const Symbol('void'));

  static Map<String, List<LibraryMirror>> _librariesByName;

  // Will be set to `true` when we have installed a hook on [deferredLoadHook]
  // to avoid installing it multiple times.
  static bool _hasInstalledDeferredLoadHook = false;

  static Map<String, List<LibraryMirror>> get librariesByName {
    if (_librariesByName == null) {
      _librariesByName = computeLibrariesByName();
      if (!_hasInstalledDeferredLoadHook) {
        _hasInstalledDeferredLoadHook = true;
        // After a deferred import has been loaded new libraries might have
        // been created, so in the hook we erase _librariesByName, so it will be
        // recomputed on the next access.
        deferredLoadHook = () => _librariesByName = null;
      }
    }
    return _librariesByName;
  }

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

  LibraryMirror findLibrary(Symbol libraryName) {
    return librariesByName[n(libraryName)].single;
  }

  static Map<String, List<LibraryMirror>> computeLibrariesByName() {
    disableTreeShaking();
    var result = new Map<String, List<LibraryMirror>>();
    var jsLibraries = JS_EMBEDDED_GLOBAL('JSExtendableArray|Null', LIBRARIES);
    if (jsLibraries == null) return result;
    for (List data in jsLibraries) {
      String name = data[0];
      String uriString = data[1];
      Uri uri;
      // The Uri has been compiled out. Create a URI from the simple name.
      if (uriString != "") {
        uri = Uri.parse(uriString);
      } else {
        uri = new Uri(
            scheme: 'https',
            host: 'dartlang.org',
            path: 'dart2js-stripped-uri',
            queryParameters: {'lib': name});
      }
      List<String> classes = data[2];
      List<String> functions = data[3];
      var metadataFunction = data[4];
      var fields = data[5];
      bool isRoot = data[6];
      var globalObject = data[7];
      List metadata = (metadataFunction == null)
          ? const []
          : JS('List', '#()', metadataFunction);
      var libraries = result.putIfAbsent(name, () => <LibraryMirror>[]);
      libraries.add(new JsLibraryMirror(s(name), uri, classes, functions,
          metadata, fields, isRoot, globalObject));
    }
    return result;
  }
}

abstract class JsMirror implements Mirror {
  const JsMirror();

  String get _prettyName;

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
    return currentJsMirrorSystem.libraries.values
        .firstWhere((JsLibraryMirror library) => library._isRoot);
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

class JsTypeVariableMirror extends JsTypeMirror implements TypeVariableMirror {
  final DeclarationMirror owner;
  final TypeVariable _typeVariable;
  final int _metadataIndex;
  TypeMirror _cachedUpperBound;

  JsTypeVariableMirror(
      TypeVariable typeVariable, this.owner, this._metadataIndex)
      : this._typeVariable = typeVariable,
        super(s(typeVariable.name));

  bool operator ==(other) {
    return (other is JsTypeVariableMirror &&
        simpleName == other.simpleName &&
        owner == other.owner);
  }

  int get hashCode {
    int code = 0x3FFFFFFF & (JsTypeVariableMirror).hashCode;
    code ^= 17 * simpleName.hashCode;
    code ^= 19 * owner.hashCode;
    return code;
  }

  String get _prettyName => 'TypeVariableMirror';

  bool get isTopLevel => false;
  bool get isStatic => false;

  TypeMirror get upperBound {
    if (_cachedUpperBound != null) return _cachedUpperBound;
    return _cachedUpperBound = typeMirrorFromRuntimeTypeRepresentation(
        owner, getType(_typeVariable.bound));
  }

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();
  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();

  _asRuntimeType() => _metadataIndex;
}

class JsTypeMirror extends JsDeclarationMirror implements TypeMirror {
  JsTypeMirror(Symbol simpleName) : super(simpleName);

  String get _prettyName => 'TypeMirror';

  DeclarationMirror get owner => null;

  // TODO(ahe): Doesn't match the specification, see http://dartbug.com/11569.
  bool get isTopLevel => true;

  // TODO(ahe): Implement these.
  List<InstanceMirror> get metadata => throw new UnimplementedError();

  bool get hasReflectedType => false;
  Type get reflectedType {
    throw new UnsupportedError("This type does not support reflectedType");
  }

  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];
  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();
  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();

  _asRuntimeType() {
    if (this == JsMirrorSystem._dynamicType) return null;
    if (this == JsMirrorSystem._voidType) return null;
    throw new RuntimeError('Should not call _asRuntimeType');
  }
}

class JsLibraryMirror extends JsDeclarationMirror
    with JsObjectMirror
    implements LibraryMirror {
  final Uri _uri;
  final List<String> _classes;
  final List<String> _functions;
  final List _metadata;
  final String _compactFieldSpecification;
  final bool _isRoot;
  final _globalObject;
  List<JsMethodMirror> _cachedFunctionMirrors;
  List<VariableMirror> _cachedFields;
  UnmodifiableMapView<Symbol, ClassMirror> _cachedClasses;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedFunctions;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedGetters;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedSetters;
  UnmodifiableMapView<Symbol, VariableMirror> _cachedVariables;
  UnmodifiableMapView<Symbol, Mirror> _cachedMembers;
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedDeclarations;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;

  JsLibraryMirror(
      Symbol simpleName,
      this._uri,
      this._classes,
      this._functions,
      this._metadata,
      this._compactFieldSpecification,
      this._isRoot,
      this._globalObject)
      : super(simpleName) {
    preserveLibraryNames();
  }

  String get _prettyName => 'LibraryMirror';

  Uri get uri {
    preserveUris();
    return _uri;
  }

  Symbol get qualifiedName => simpleName;

  List<JsMethodMirror> get _methods => _functionMirrors;

  Map<Symbol, ClassMirror> get __classes {
    if (_cachedClasses != null) return _cachedClasses;
    var result = new Map();
    for (String className in _classes) {
      var cls = reflectClassByMangledName(className);
      if (cls is ClassMirror) {
        cls = cls.originalDeclaration;
      }
      if (cls is JsClassMirror) {
        result[cls.simpleName] = cls;
        cls._owner = this;
      } else if (cls is JsTypedefMirror) {
        result[cls.simpleName] = cls;
      }
    }
    return _cachedClasses =
        new UnmodifiableMapView<Symbol, ClassMirror>(result);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    String name = n(fieldName);
    if (name.endsWith('=')) throw new ArgumentError('');
    var mirror = __functions[s('$name=')];
    if (mirror == null) mirror = __variables[fieldName];
    if (mirror == null) {
      throw new NoSuchStaticMethodError.method(
          null, setterSymbol(fieldName), [arg], null);
    }
    mirror._setField(this, arg);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    JsMirror mirror = __members[fieldName];
    if (mirror == null) {
      throw new NoSuchStaticMethodError.method(null, fieldName, [], null);
    }
    if (mirror is! MethodMirror) return reflect(mirror._getField(this));
    JsMethodMirror methodMirror = mirror;
    if (methodMirror.isGetter) return reflect(mirror._getField(this));
    assert(methodMirror.isRegularMethod);
    var getter = JS("", "#['\$getter']", methodMirror._jsFunction);
    if (getter == null) throw new UnimplementedError();
    return reflect(JS("", "#()", getter));
  }

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsDeclarationMirror mirror = __members[memberName];

    if (mirror is JsMethodMirror && !mirror.canInvokeReflectively()) {
      throwInvalidReflectionError(n(memberName));
    }
    if (mirror == null || mirror is JsMethodMirror && mirror.isSetter) {
      throw new NoSuchStaticMethodError.method(
          null, memberName, positionalArguments, namedArguments);
    }
    if (mirror is JsMethodMirror && !mirror.isGetter) {
      return reflect(mirror._invoke(positionalArguments, namedArguments));
    }
    return getField(memberName)
        .invoke(#call, positionalArguments, namedArguments);
  }

  delegate(Invocation invocation) {
    throw new UnimplementedError();
  }

  _loadField(String name) {
    // TODO(ahe): What about lazily initialized fields? See
    // [JsClassMirror.getField].

    // '$' (JS_GET_STATIC_STATE()) stores state which is read directly, so we
    // shouldn't use [_globalObject] here.
    assert(JS('bool', '# in #', name, JS_GET_STATIC_STATE()));
    return JS('', '#[#]', JS_GET_STATIC_STATE(), name);
  }

  void _storeField(String name, Object arg) {
    // '$' (JS_GET_STATIC_STATE()) stores state which is stored directly, so we
    // shouldn't use [_globalObject] here.
    assert(JS('bool', '# in #', name, JS_GET_STATIC_STATE()));
    JS('void', '#[#] = #', JS_GET_STATIC_STATE(), name, arg);
  }

  List<JsMethodMirror> get _functionMirrors {
    if (_cachedFunctionMirrors != null) return _cachedFunctionMirrors;
    var result = new List<JsMethodMirror>();
    for (int i = 0; i < _functions.length; i++) {
      String name = _functions[i];
      var jsFunction = JS('', '#[#]', _globalObject, name);
      String unmangledName = mangledGlobalNames[name];
      if (unmangledName == null ||
          JS('bool', "!!#['\$getterStub']", jsFunction)) {
        // If there is no unmangledName, [jsFunction] is either a synthetic
        // implementation detail, or something that is excluded
        // by @MirrorsUsed.
        // If it has a getterStub property it is a synthetic stub.
        // TODO(floitsch): Remove the getterStub hack.
        continue;
      }
      bool isConstructor = unmangledName.startsWith('new ');
      // Top-level functions are static, but constructors are not.
      bool isStatic = !isConstructor;
      if (isConstructor) {
        unmangledName = unmangledName.substring(4).replaceAll(r'$', '.');
      }
      JsMethodMirror mirror = new JsMethodMirror.fromUnmangledName(
          unmangledName, jsFunction, isStatic, isConstructor);
      result.add(mirror);
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

  Map<Symbol, MethodMirror> get __functions {
    if (_cachedFunctions != null) return _cachedFunctions;
    var result = new Map();
    for (JsMethodMirror mirror in _functionMirrors) {
      if (!mirror.isConstructor) result[mirror.simpleName] = mirror;
    }
    return _cachedFunctions =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get __getters {
    if (_cachedGetters != null) return _cachedGetters;
    var result = new Map();
    // TODO(ahe): Implement this.
    return _cachedGetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, MethodMirror> get __setters {
    if (_cachedSetters != null) return _cachedSetters;
    var result = new Map();
    // TODO(ahe): Implement this.
    return _cachedSetters =
        new UnmodifiableMapView<Symbol, MethodMirror>(result);
  }

  Map<Symbol, VariableMirror> get __variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in _fields) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, Mirror> get __members {
    if (_cachedMembers != null) return _cachedMembers;
    Map<Symbol, Mirror> result = new Map.from(__classes);
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }

    __functions.forEach(addToResult);
    __getters.forEach(addToResult);
    __setters.forEach(addToResult);
    __variables.forEach(addToResult);
    return _cachedMembers = new UnmodifiableMapView<Symbol, Mirror>(result);
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    var result = new Map<Symbol, DeclarationMirror>();
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }

    __members.forEach(addToResult);
    return _cachedDeclarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(result);
  }

  List<InstanceMirror> get metadata {
    if (_cachedMetadata != null) return _cachedMetadata;
    preserveMetadata();
    return _cachedMetadata =
        new UnmodifiableListView<InstanceMirror>(_metadata.map(reflect));
  }

  // TODO(ahe): Test this getter.
  DeclarationMirror get owner => null;

  List<LibraryDependencyMirror> get libraryDependencies =>
      throw new UnimplementedError();
}

String n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
}

Symbol setterSymbol(Symbol symbol) => s("${n(symbol)}=");

final JsMirrorSystem currentJsMirrorSystem = new JsMirrorSystem();

InstanceMirror reflect(Object reflectee) {
  // TODO(sra): This test should be a quick test for something like 'is
  // Function', but only for classes that implement `Function` via a `call`
  // method. The JS form of the test could be something like
  //
  //     if (reflectee instanceof P.Object && reflectee.$isFunction) ...
  //
  // We don't currently have a way get that generated. We should ensure type
  // analysis can express 'not Interceptor' and recognize a negative type test
  // against Interceptor can be optimized to the above test. For now we have to
  // accept the following is compiled to an interceptor-based type check.
  if (reflectee is Function) {
    return new JsClosureMirror(reflectee);
  } else {
    return new JsInstanceMirror(reflectee);
  }
}

TypeMirror reflectType(Type key, [List<Type> typeArguments]) {
  String mangledName = getMangledTypeName(key);
  if (typeArguments != null) {
    if (typeArguments.isEmpty || !typeArguments.every((_) => _ is TypeImpl)) {
      var message = typeArguments.isEmpty
          ? 'Type arguments list can not be empty.'
          : 'Type arguments list must contain only instances of Type.';
      throw new ArgumentError.value(typeArguments, 'typeArguments', message);
    }
    var mangledTypeArguments = typeArguments.map(getMangledTypeName);
    mangledName = "${mangledName}<${mangledTypeArguments.join(', ')}>";
  }
  return reflectClassByMangledName(mangledName);
}

TypeMirror reflectClassByMangledName(String mangledName) {
  String unmangledName = mangledGlobalNames[mangledName];
  if (mangledName == 'dynamic') return JsMirrorSystem._dynamicType;
  if (mangledName == 'void') return JsMirrorSystem._voidType;
  if (unmangledName == null) unmangledName = mangledName;
  return reflectClassByName(s(unmangledName), mangledName);
}

var classMirrors;

TypeMirror reflectClassByName(Symbol symbol, String mangledName) {
  if (classMirrors == null) classMirrors = JsCache.allocate();
  var mirror = JsCache.fetch(classMirrors, mangledName);
  if (mirror != null) return mirror;
  disableTreeShaking();
  int typeArgIndex = mangledName.indexOf("<");
  if (typeArgIndex != -1) {
    TypeMirror originalDeclaration =
        reflectClassByMangledName(mangledName.substring(0, typeArgIndex))
            .originalDeclaration;
    if (originalDeclaration is JsTypedefMirror) {
      throw new UnimplementedError();
    }
    mirror = new JsTypeBoundClassMirror(
        originalDeclaration,
        // Remove the angle brackets enclosing the type arguments.
        mangledName.substring(typeArgIndex + 1, mangledName.length - 1));
    JsCache.update(classMirrors, mangledName, mirror);
    return mirror;
  }
  var allClasses = JS_EMBEDDED_GLOBAL('', ALL_CLASSES);
  var constructor = JS('var', '#[#]', allClasses, mangledName);
  if (constructor == null) {
    // Probably an intercepted class.
    // TODO(ahe): How to handle intercepted classes?
    throw new UnsupportedError('Cannot find class for: ${n(symbol)}');
  }
  var descriptor = JS('', '#["@"]', constructor);
  var fields;
  var fieldsMetadata;
  if (descriptor == null) {
    // This is a native class, or an intercepted class.
    // TODO(ahe): Preserve descriptor for such classes.
  } else if (JS(
      'bool', '# in #', TYPEDEF_PREDICATE_PROPERTY_NAME, descriptor)) {
    // Typedefs are represented as normal classes with two special properties:
    //   TYPEDEF_PREDICATE_PROPERTY_NAME and TYPEDEF_TYPE_PROPERTY_NAME.
    // For example:
    //  MyTypedef: {
    //     "^": "Object;",
    //     $typedefType: 58,
    //     $$isTypedef: true
    //  }
    //  The typedefType is the index into the metadata table.
    int index = JS('int', '#[#]', descriptor, TYPEDEF_TYPE_PROPERTY_NAME);
    mirror = new JsTypedefMirror(symbol, mangledName, getType(index));
  } else {
    fields = JS('', '#[#]', descriptor,
        JS_GET_NAME(JsGetName.CLASS_DESCRIPTOR_PROPERTY));
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

  if (mirror == null) {
    var superclassName = fields.split(';')[0];
    var mixins = superclassName.split('+');
    if (mixins.length > 1 && mangledGlobalNames[mangledName] == null) {
      mirror = reflectMixinApplication(mixins, mangledName);
    } else {
      ClassMirror classMirror = new JsClassMirror(
          symbol, mangledName, constructor, fields, fieldsMetadata);
      List typeVariables =
          JS('JSExtendableArray|Null', '#.prototype["<>"]', constructor);
      if (typeVariables == null || typeVariables.length == 0) {
        mirror = classMirror;
      } else {
        String typeArguments = 'dynamic';
        for (int i = 1; i < typeVariables.length; i++) {
          typeArguments += ',dynamic';
        }
        mirror = new JsTypeBoundClassMirror(classMirror, typeArguments);
      }
    }
  }

  JsCache.update(classMirrors, mangledName, mirror);
  return mirror;
}

/// Splits input `typeArguments` string into a list of strings for each argument.
/// Takes into account nested generic types.
/// For example, `Map<int, String>, String` will become a list of two items:
/// `Map<int, String>` and `String`.
List<String> splitTypeArguments(String typeArguments) {
  if (typeArguments.indexOf('<') == -1) {
    return typeArguments.split(',');
  }
  var argumentList = new List<String>();
  int level = 0;
  String currentTypeArgument = '';

  for (int i = 0; i < typeArguments.length; i++) {
    var character = typeArguments[i];
    if (character == ' ') {
      continue;
    } else if (character == '<') {
      currentTypeArgument += character;
      level++;
    } else if (character == '>') {
      currentTypeArgument += character;
      level--;
    } else if (character == ',') {
      if (level > 0) {
        currentTypeArgument += character;
      } else {
        argumentList.add(currentTypeArgument);
        currentTypeArgument = '';
      }
    } else {
      currentTypeArgument += character;
    }
  }
  argumentList.add(currentTypeArgument);
  return argumentList;
}

Map<Symbol, MethodMirror> filterMethods(List<MethodMirror> methods) {
  var result = new Map();
  for (JsMethodMirror method in methods) {
    if (!method.isConstructor && !method.isGetter && !method.isSetter) {
      result[method.simpleName] = method;
    }
  }
  return result;
}

Map<Symbol, MethodMirror> filterConstructors(methods) {
  var result = new Map();
  for (JsMethodMirror method in methods) {
    if (method.isConstructor) {
      result[method.simpleName] = method;
    }
  }
  return result;
}

Map<Symbol, MethodMirror> filterGetters(
    List<MethodMirror> methods, Map<Symbol, VariableMirror> fields) {
  var result = new Map();
  for (JsMethodMirror method in methods) {
    if (method.isGetter) {
      // TODO(ahe): This is a hack to remove getters corresponding to a field.
      if (fields[method.simpleName] != null) continue;

      result[method.simpleName] = method;
    }
  }
  return result;
}

Map<Symbol, MethodMirror> filterSetters(
    List<MethodMirror> methods, Map<Symbol, VariableMirror> fields) {
  var result = new Map();
  for (JsMethodMirror method in methods) {
    if (method.isSetter) {
      // TODO(ahe): This is a hack to remove setters corresponding to a field.
      String name = n(method.simpleName);
      name = name.substring(0, name.length - 1); // Remove '='.
      if (fields[s(name)] != null) continue;

      result[method.simpleName] = method;
    }
  }
  return result;
}

Map<Symbol, Mirror> filterMembers(
    List<MethodMirror> methods, Map<Symbol, VariableMirror> variables) {
  Map<Symbol, Mirror> result = new Map.from(variables);
  for (JsMethodMirror method in methods) {
    if (method.isSetter) {
      String name = n(method.simpleName);
      name = name.substring(0, name.length - 1);
      // Filter-out setters corresponding to variables.
      if (result[s(name)] is VariableMirror) continue;
    }
    // Constructors aren't 'members'.
    if (method.isConstructor) continue;
    // Filter out synthetic tear-off stubs
    if (JS('bool', r'!!#.$getterStub', method._jsFunction)) continue;
    // Use putIfAbsent to filter-out getters corresponding to variables.
    result.putIfAbsent(method.simpleName, () => method);
  }
  return result;
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

class JsMixinApplication extends JsTypeMirror
    with JsObjectMirror
    implements ClassMirror {
  final ClassMirror superclass;
  final ClassMirror mixin;
  Symbol _cachedSimpleName;
  Map<Symbol, MethodMirror> _cachedInstanceMembers;

  JsMixinApplication(
      ClassMirror superclass, ClassMirror mixin, String mangledName)
      : this.superclass = superclass,
        this.mixin = mixin,
        super(s(mangledName));

  String get _prettyName => 'ClassMirror';

  Symbol get simpleName {
    if (_cachedSimpleName != null) return _cachedSimpleName;
    String superName = n(superclass.qualifiedName);
    return _cachedSimpleName = (superName.contains(' with '))
        ? s('$superName, ${n(mixin.qualifiedName)}')
        : s('$superName with ${n(mixin.qualifiedName)}');
  }

  Symbol get qualifiedName => simpleName;

  // TODO(ahe): Remove this method, only here to silence warning.
  get _mixin => mixin;

  Map<Symbol, Mirror> get __members => _mixin.__members;

  Map<Symbol, MethodMirror> get __methods => _mixin.__methods;

  Map<Symbol, MethodMirror> get __getters => _mixin.__getters;

  Map<Symbol, MethodMirror> get __setters => _mixin.__setters;

  Map<Symbol, VariableMirror> get __variables => _mixin.__variables;

  Map<Symbol, DeclarationMirror> get declarations => mixin.declarations;

  Map<Symbol, MethodMirror> get instanceMembers {
    if (_cachedInstanceMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      if (superclass != null) {
        result.addAll(superclass.instanceMembers);
      }
      result.addAll(mixin.instanceMembers);
      _cachedInstanceMembers = result;
    }
    return _cachedInstanceMembers;
  }

  Map<Symbol, MethodMirror> get staticMembers => mixin.staticMembers;

  _asRuntimeType() => null;

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    throw new NoSuchStaticMethodError.method(
        null, memberName, positionalArguments, namedArguments);
  }

  InstanceMirror getField(Symbol fieldName) {
    throw new NoSuchStaticMethodError.method(null, fieldName, null, null);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    throw new NoSuchStaticMethodError.method(
        null, setterSymbol(fieldName), [arg], null);
  }

  delegate(Invocation invocation) {
    throw new UnimplementedError();
  }

  List<ClassMirror> get superinterfaces => [mixin];

  Map<Symbol, MethodMirror> get __constructors => _mixin.__constructors;

  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    throw new UnsupportedError(
        "Can't instantiate mixin application '${n(qualifiedName)}'");
  }

  bool get isOriginalDeclaration => true;

  ClassMirror get originalDeclaration => this;

  // TODO(ahe): Implement this.
  List<TypeVariableMirror> get typeVariables {
    throw new UnimplementedError();
  }

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get isAbstract => throw new UnimplementedError();

  bool get isEnum => throw new UnimplementedError();

  bool isSubclassOf(ClassMirror other) {
    superclass.isSubclassOf(other) || mixin.isSubclassOf(other);
  }

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();

  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();
}

abstract class JsObjectMirror implements ObjectMirror {}

class JsInstanceMirror extends JsObjectMirror implements InstanceMirror {
  final reflectee;

  JsInstanceMirror(this.reflectee);

  bool get hasReflectee => true;

  ClassMirror get type {
    // The spec guarantees that `null` is the singleton instance of the `Null`
    // class.
    if (reflectee == null) return reflectClass(Null);
    return reflectType(getRuntimeType(reflectee));
  }

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments == null) namedArguments = const {};
    // We can safely pass positionalArguments to _invoke as it will wrap it in
    // a JSArray if needed.
    return _invoke(memberName, JSInvocationMirror.METHOD, positionalArguments,
        namedArguments);
  }

  InstanceMirror _invokeMethodWithNamedArguments(String reflectiveName,
      List positionalArguments, Map<Symbol, dynamic> namedArguments) {
    assert(namedArguments.isNotEmpty);
    var interceptor = getInterceptor(reflectee);

    var jsFunction = JS('', '#[#]', interceptor, reflectiveName);
    if (jsFunction == null) {
      // TODO(ahe): Invoke noSuchMethod.
      throw new UnimplementedNoSuchMethodError(
          'Invoking noSuchMethod with named arguments not implemented');
    }
    ReflectionInfo info = new ReflectionInfo(jsFunction);
    if (jsFunction == null) {
      // TODO(ahe): Invoke noSuchMethod.
      throw new UnimplementedNoSuchMethodError(
          'Invoking noSuchMethod with named arguments not implemented');
    }

    positionalArguments = new List.from(positionalArguments);
    // Check the number of positional arguments is valid.
    if (info.requiredParameterCount != positionalArguments.length) {
      // TODO(ahe): Invoke noSuchMethod.
      throw new UnimplementedNoSuchMethodError(
          'Invoking noSuchMethod with named arguments not implemented');
    }
    var defaultArguments = new Map();
    for (int i = 0; i < info.optionalParameterCount; i++) {
      var parameterName = info.parameterName(i + info.requiredParameterCount);
      var defaultValue =
          getMetadata(info.defaultValue(i + info.requiredParameterCount));
      defaultArguments[parameterName] = defaultValue;
    }
    namedArguments.forEach((Symbol symbol, value) {
      String parameter = n(symbol);
      if (defaultArguments.containsKey(parameter)) {
        defaultArguments[parameter] = value;
      } else {
        // Extraneous named argument.
        // TODO(ahe): Invoke noSuchMethod.
        throw new UnimplementedNoSuchMethodError(
            'Invoking noSuchMethod with named arguments not implemented');
      }
    });
    positionalArguments.addAll(defaultArguments.values);
    // TODO(ahe): Handle intercepted methods.
    return reflect(
        JS('', '#.apply(#, #)', jsFunction, reflectee, positionalArguments));
  }

  /// Grabs hold of the class-specific invocation cache for the reflectee.
  /// All reflectees with the same class share the same cache. The cache
  /// maps reflective names to cached invocation objects with enough decoded
  /// reflective information to know how to to invoke a specific member.
  get _classInvocationCache {
    String cacheName = Primitives.mirrorInvokeCacheName;
    var cacheHolder = (reflectee == null) ? getInterceptor(null) : reflectee;
    var cache = JS('', r'#.constructor[#]', cacheHolder, cacheName);
    if (cache == null) {
      cache = JsCache.allocate();
      JS('void', r'#.constructor[#] = #', cacheHolder, cacheName, cache);
    }
    return cache;
  }

  String _computeReflectiveName(Symbol symbolName, int type,
      List positionalArguments, Map<Symbol, dynamic> namedArguments) {
    String name = n(symbolName);
    switch (type) {
      case JSInvocationMirror.GETTER:
        return name;
      case JSInvocationMirror.SETTER:
        return '$name=';
      case JSInvocationMirror.METHOD:
        if (namedArguments.isNotEmpty) return '$name*';
        int nbArgs = positionalArguments.length as int;
        return "$name:$nbArgs";
    }
    throw new RuntimeError("Could not compute reflective name for $name");
  }

  /**
   * Returns a `CachedInvocation` or `CachedNoSuchMethodInvocation` for the
   * given member.
   *
   * Caches the result.
   */
  _getCachedInvocation(Symbol name, int type, String reflectiveName,
      List positionalArguments, Map<Symbol, dynamic> namedArguments) {
    var cache = _classInvocationCache;
    var cacheEntry = JsCache.fetch(cache, reflectiveName);
    var result;
    if (cacheEntry == null) {
      disableTreeShaking();
      String mangledName = reflectiveNames[reflectiveName];
      List<String> argumentNames = const [];

      // TODO(ahe): We don't need to create an invocation mirror here. The
      // logic from JSInvocationMirror.getCachedInvocation could easily be
      // inlined here.
      Invocation invocation = createUnmangledInvocationMirror(
          name, mangledName, type, positionalArguments, argumentNames);

      cacheEntry =
          JSInvocationMirror.getCachedInvocation(invocation, reflectee);
      JsCache.update(cache, reflectiveName, cacheEntry);
    }
    return cacheEntry;
  }

  bool _isReflectable(CachedInvocation cachedInvocation) {
    // TODO(floitsch): tear-off closure does not guarantee that the
    // function is reflectable.
    var method = cachedInvocation.jsFunction;
    return hasReflectableProperty(method) || reflectee is TearOffClosure;
  }

  /// Invoke the member specified through name and type on the reflectee.
  /// As a side-effect, this populates the class-specific invocation cache
  /// for the reflectee.
  InstanceMirror _invoke(Symbol name, int type, List positionalArguments,
      Map<Symbol, dynamic> namedArguments) {
    String reflectiveName =
        _computeReflectiveName(name, type, positionalArguments, namedArguments);

    if (namedArguments.isNotEmpty) {
      // TODO(floitsch): first, make sure it's not a getter.
      return _invokeMethodWithNamedArguments(
          reflectiveName, positionalArguments, namedArguments);
    }
    var cacheEntry = _getCachedInvocation(
        name, type, reflectiveName, positionalArguments, namedArguments);

    if (cacheEntry.isNoSuchMethod || !_isReflectable(cacheEntry)) {
      // Could be that we want to invoke a getter, or get a method.
      if (type == JSInvocationMirror.METHOD && _instanceFieldExists(name)) {
        return getField(name)
            .invoke(#call, positionalArguments, namedArguments);
      }

      if (type == JSInvocationMirror.SETTER) {
        // For setters we report the setter name "field=".
        name = s("${n(name)}=");
      }

      if (!cacheEntry.isNoSuchMethod) {
        // Not reflectable.
        throwInvalidReflectionError(reflectiveName);
      }

      String mangledName = reflectiveNames[reflectiveName];
      // TODO(ahe): Get the argument names.
      List<String> argumentNames = [];
      Invocation invocation = createUnmangledInvocationMirror(
          name, mangledName, type, positionalArguments, argumentNames);
      return reflect(cacheEntry.invokeOn(reflectee, invocation));
    } else {
      return reflect(cacheEntry.invokeOn(reflectee, positionalArguments));
    }
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    _invoke(fieldName, JSInvocationMirror.SETTER, [arg], const {});
    return reflect(arg);
  }

  // JS helpers for getField optimizations.
  static bool isUndefined(x) => JS('bool', 'typeof # == "undefined"', x);
  static bool isMissingCache(x) => JS('bool', 'typeof # == "number"', x);
  static bool isMissingProbe(Symbol symbol) =>
      JS('bool', 'typeof #.\$p == "undefined"', symbol);
  static bool isEvalAllowed() => !JS_GET_FLAG("USE_CONTENT_SECURITY_POLICY");

  /// The getter cache is lazily allocated after a couple
  /// of invocations of [InstanceMirror.getField]. The delay is
  /// used to avoid too aggressive caching and dynamic function
  /// generation for rarely used mirrors. The cache is specific to
  /// this [InstanceMirror] and maps reflective names to functions
  /// that will invoke the corresponding getter on the reflectee.
  /// The reflectee is passed to the function as the first argument
  /// to avoid the overhead of fetching it from this mirror repeatedly.
  /// The cache is lazily initialized to a JS object so we can
  /// benefit from "map transitions" in the underlying JavaScript
  /// engine to speed up cache probing.
  var _getterCache = 4;

  bool _instanceFieldExists(Symbol name) {
    int getterType = JSInvocationMirror.GETTER;
    String getterName =
        _computeReflectiveName(name, getterType, const [], const {});
    var getterCacheEntry =
        _getCachedInvocation(name, getterType, getterName, const [], const {});
    return !getterCacheEntry.isNoSuchMethod && !getterCacheEntry.isGetterStub;
  }

  InstanceMirror getField(Symbol fieldName) {
    FASTPATH:
    {
      var cache = _getterCache;
      if (isMissingCache(cache) || isMissingProbe(fieldName)) break FASTPATH;
      // If the [fieldName] has an associated probe function, we can use
      // it to read from the getter cache specific to this [InstanceMirror].
      var getter = JS('', '#.\$p(#)', fieldName, cache);
      if (isUndefined(getter)) break FASTPATH;
      // Call the getter passing the reflectee as the first argument.
      var value = JS('', '#(#)', getter, reflectee);
      // The getter has an associate cache of the last [InstanceMirror]
      // returned to avoid repeated invocations of [reflect]. To validate
      // the cache, we check that the value returned by the getter is the
      // same value as last time.
      if (JS('bool', '# === #.v', value, getter)) {
        return JS('InstanceMirror', '#.m', getter);
      } else {
        var result = reflect(value);
        JS('void', '#.v = #', getter, value);
        JS('void', '#.m = #', getter, result);
        return result;
      }
    }
    return _getFieldSlow(fieldName);
  }

  InstanceMirror _getFieldSlow(Symbol fieldName) {
    // First do the slow-case getter invocation. As a side-effect of this,
    // the invocation cache is filled in so we can query it afterwards.
    var result =
        _invoke(fieldName, JSInvocationMirror.GETTER, const [], const {});
    String name = n(fieldName);
    var cacheEntry = JsCache.fetch(_classInvocationCache, name);
    if (cacheEntry.isNoSuchMethod) {
      return result;
    }

    // Make sure we have a getter cache in this [InstanceMirror].
    var cache = _getterCache;
    if (isMissingCache(cache)) {
      if ((_getterCache = --cache) != 0) return result;
      cache = _getterCache = JS('=Object', 'Object.create(null)');
    }

    // Make sure that symbol [fieldName] has a cache probing function ($p).
    bool useEval = isEvalAllowed();
    if (isMissingProbe(fieldName)) {
      var probe = _newProbeFn(name, useEval);
      JS('void', '#.\$p = #', fieldName, probe);
    }

    // Create a new getter function and install it in the cache.
    var mangledName = cacheEntry.mangledName;
    var getter = (cacheEntry.isIntercepted)
        ? _newInterceptedGetterFn(mangledName, useEval)
        : _newGetterFn(mangledName, useEval);
    JS('void', '#[#] = #', cache, name, getter);

    // Initialize the last value (v) and last mirror (m) on the
    // newly generated getter to be a sentinel value that is hard
    // to get hold of through user code.
    JS('void', '#.v = #.m = #', getter, getter, cache);

    // Return the result of the slow-path getter invocation.
    return result;
  }

  _newProbeFn(String id, bool useEval) {
    if (useEval) {
      String body = "return c.$id;";
      return JS('', 'new Function("c", #)', body);
    } else {
      return JS('', '(function(n){return(function(c){return c[n]})})(#)', id);
    }
  }

  _newGetterFn(String name, bool useEval) {
    if (!useEval) return _newGetterNoEvalFn(name);
    // We use a comment that associates the generated function with the
    // class of the reflectee. This makes it more likely that the underlying
    // JavaScript engine will only share the generated code for accessors on the
    // same class (through caching of eval'ed code). This makes the
    // generated call to the getter - e.g. o.get$foo() - much more likely
    // to be monomorphic and inlineable.
    String className = JS('String', '#.constructor.name', reflectee);
    String body = "/* $className */ return o.$name();";
    return JS('', 'new Function("o", #)', body);
  }

  _newGetterNoEvalFn(n) =>
      JS('', '(function(n){return(function(o){return o[n]()})})(#)', n);

  _newInterceptedGetterFn(String name, bool useEval) {
    var object = reflectee;
    // It is possible that the interceptor for a given object is the object
    // itself, so it is important not to share the code that captures the
    // interceptor between multiple different instances of [InstanceMirror].
    var interceptor = getInterceptor(object);
    if (!useEval) return _newInterceptGetterNoEvalFn(name, interceptor);
    String className = JS('String', '#.constructor.name', interceptor);
    String functionName = '$className\$$name';
    String body = '  function $functionName(o){return i.$name(o)}'
        '  return $functionName;';
    return JS('', '(new Function("i", #))(#)', body, interceptor);
  }

  _newInterceptGetterNoEvalFn(n, i) =>
      JS('', '(function(n,i){return(function(o){return i[n](o)})})(#,#)', n, i);

  delegate(Invocation invocation) {
    return JSInvocationMirror.invokeFromMirror(invocation, reflectee);
  }

  operator ==(other) {
    return other is JsInstanceMirror && identical(reflectee, other.reflectee);
  }

  int get hashCode {
    // Avoid hash collisions with the reflectee. This constant is in Smi range
    // and happens to be the inner padding from RFC 2104.
    return identityHashCode(reflectee) ^ 0x36363636;
  }

  String toString() => 'InstanceMirror on ${Error.safeToString(reflectee)}';

  // TODO(ahe): Remove this method from the API.
  MirrorSystem get mirrors => currentJsMirrorSystem;
}

/**
 * ClassMirror for generic classes where the type parameters are bound.
 *
 * [typeArguments] will return a list of the type arguments, in constrast
 * to JsCLassMirror that returns an empty list since it represents original
 * declarations and classes that are not generic.
 */
class JsTypeBoundClassMirror extends JsDeclarationMirror
    implements ClassMirror {
  final JsClassMirror _class;

  /**
   * When instantiated this field will hold a string representing the list of
   * type arguments for the class, i.e. what is inside the outermost angle
   * brackets. Then, when get typeArguments is called the first time, the string
   * is parsed into the actual list of TypeMirrors, and stored in
   * [_cachedTypeArguments]. Due to type substitution of, for instance,
   * superclasses the mangled name of the class and hence this string is needed
   * after [_cachedTypeArguments] has been computed.
   *
   * If an integer is encountered as a type argument, it represents the type
   * variable at the corresponding entry in [emitter.globalMetadata].
   */
  String _typeArguments;

  UnmodifiableListView<TypeMirror> _cachedTypeArguments;
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedDeclarations;
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedMembers;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedConstructors;
  Map<Symbol, VariableMirror> _cachedVariables;
  Map<Symbol, MethodMirror> _cachedGetters;
  Map<Symbol, MethodMirror> _cachedSetters;
  Map<Symbol, MethodMirror> _cachedMethodsMap;
  List<JsMethodMirror> _cachedMethods;
  ClassMirror _superclass;
  List<ClassMirror> _cachedSuperinterfaces;
  Map<Symbol, MethodMirror> _cachedInstanceMembers;
  Map<Symbol, MethodMirror> _cachedStaticMembers;

  JsTypeBoundClassMirror(JsClassMirror originalDeclaration, this._typeArguments)
      : _class = originalDeclaration,
        super(originalDeclaration.simpleName);

  String get _prettyName => 'ClassMirror';

  String toString() {
    String result = '$_prettyName on ${n(simpleName)}';
    if (typeArguments != null) {
      result = "$result<${typeArguments.join(', ')}>";
    }
    return result;
  }

  String get _mangledName {
    for (TypeMirror typeArgument in typeArguments) {
      if (typeArgument != JsMirrorSystem._dynamicType) {
        return '${_class._mangledName}<$_typeArguments>';
      }
    }
    // When all type arguments are dynamic, the canonical representation is to
    // drop them.
    return _class._mangledName;
  }

  List<TypeVariableMirror> get typeVariables => _class.typeVariables;

  List<TypeMirror> get typeArguments {
    if (_cachedTypeArguments != null) return _cachedTypeArguments;
    List result = new List();

    addTypeArgument(String typeArgument) {
      int parsedIndex = int.parse(typeArgument, onError: (_) => -1);
      if (parsedIndex == -1) {
        result.add(reflectClassByMangledName(typeArgument.trim()));
      } else {
        TypeVariable typeVariable = getMetadata(parsedIndex);
        TypeMirror owner = reflectClass(typeVariable.owner);
        TypeVariableMirror typeMirror =
            new JsTypeVariableMirror(typeVariable, owner, parsedIndex);
        result.add(typeMirror);
      }
    }

    splitTypeArguments(_typeArguments).forEach(addTypeArgument);
    return _cachedTypeArguments = new UnmodifiableListView(result);
  }

  List<JsMethodMirror> get _methods {
    if (_cachedMethods != null) return _cachedMethods;
    return _cachedMethods = _class._getMethodsWithOwner(this);
  }

  Map<Symbol, MethodMirror> get __methods {
    if (_cachedMethodsMap != null) return _cachedMethodsMap;
    return _cachedMethodsMap =
        new UnmodifiableMapView<Symbol, MethodMirror>(filterMethods(_methods));
  }

  Map<Symbol, MethodMirror> get __constructors {
    if (_cachedConstructors != null) return _cachedConstructors;
    return _cachedConstructors = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterConstructors(_methods));
  }

  Map<Symbol, MethodMirror> get __getters {
    if (_cachedGetters != null) return _cachedGetters;
    return _cachedGetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterGetters(_methods, __variables));
  }

  Map<Symbol, MethodMirror> get __setters {
    if (_cachedSetters != null) return _cachedSetters;
    return _cachedSetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterSetters(_methods, __variables));
  }

  Map<Symbol, VariableMirror> get __variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in _class._getFieldsWithOwner(this)) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, DeclarationMirror> get __members {
    if (_cachedMembers != null) return _cachedMembers;
    return _cachedMembers = new UnmodifiableMapView<Symbol, DeclarationMirror>(
        filterMembers(_methods, __variables));
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    Map<Symbol, DeclarationMirror> result =
        new Map<Symbol, DeclarationMirror>();
    result.addAll(__members);
    result.addAll(__constructors);
    typeVariables.forEach((tv) => result[tv.simpleName] = tv);
    return _cachedDeclarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(result);
  }

  Map<Symbol, MethodMirror> get staticMembers {
    if (_cachedStaticMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      declarations.values.forEach((decl) {
        if (decl is MethodMirror && decl.isStatic && !decl.isConstructor) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] = new JsSyntheticAccessor(
              this, getterName, true, true, false, decl);
          if (!decl.isFinal) {
            var setterName = setterSymbol(decl.simpleName);
            result[setterName] = new JsSyntheticAccessor(
                this, setterName, false, true, false, decl);
          }
        }
      });
      _cachedStaticMembers = result;
    }
    return _cachedStaticMembers;
  }

  Map<Symbol, MethodMirror> get instanceMembers {
    if (_cachedInstanceMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      if (superclass != null) {
        result.addAll(superclass.instanceMembers);
      }
      declarations.values.forEach((decl) {
        if (decl is MethodMirror &&
            !decl.isStatic &&
            !decl.isConstructor &&
            !decl.isAbstract) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && !decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] = new JsSyntheticAccessor(
              this, getterName, true, false, false, decl);
          if (!decl.isFinal) {
            var setterName = setterSymbol(decl.simpleName);
            result[setterName] = new JsSyntheticAccessor(
                this, setterName, false, false, false, decl);
          }
        }
      });
      _cachedInstanceMembers = result;
    }
    return _cachedInstanceMembers;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    return _class.setField(fieldName, arg);
  }

  InstanceMirror getField(Symbol fieldName) => _class.getField(fieldName);

  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    var instance = _class._getInvokedInstance(
        constructorName, positionalArguments, namedArguments);
    return reflect(setRuntimeTypeInfo(
        instance, typeArguments.map((t) => t._asRuntimeType()).toList()));
  }

  _asRuntimeType() {
    return [_class._jsConstructor]
        .addAll(typeArguments.map((t) => t._asRuntimeType()));
  }

  JsLibraryMirror get owner => _class.owner;

  List<InstanceMirror> get metadata => _class.metadata;

  ClassMirror get superclass {
    if (_superclass != null) return _superclass;

    var typeInformationContainer = JS_EMBEDDED_GLOBAL('', TYPE_INFORMATION);
    List<int> typeInformation =
        JS('List|Null', '#[#]', typeInformationContainer, _class._mangledName);
    assert(typeInformation != null);
    var type = getType(typeInformation[0]);
    return _superclass = typeMirrorFromRuntimeTypeRepresentation(this, type);
  }

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return _class.invoke(memberName, positionalArguments, namedArguments);
  }

  delegate(Invocation invocation) {
    throw new UnimplementedError();
  }

  bool get isOriginalDeclaration => false;

  ClassMirror get originalDeclaration => _class;

  List<ClassMirror> get superinterfaces {
    if (_cachedSuperinterfaces != null) return _cachedSuperinterfaces;
    return _cachedSuperinterfaces = _class._getSuperinterfacesWithOwner(this);
  }

  bool get isPrivate => _class.isPrivate;

  bool get isTopLevel => _class.isTopLevel;

  bool get isAbstract => _class.isAbstract;

  bool get isEnum => _class.isEnum;

  bool isSubclassOf(ClassMirror other) => _class.isSubclassOf(other);

  SourceLocation get location => _class.location;

  MirrorSystem get mirrors => _class.mirrors;

  Symbol get qualifiedName => _class.qualifiedName;

  bool get hasReflectedType => true;

  Type get reflectedType => createRuntimeType(_mangledName);

  Symbol get simpleName => _class.simpleName;

  // TODO(ahe): Implement this.
  ClassMirror get mixin => throw new UnimplementedError();

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();

  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();
}

class JsSyntheticAccessor implements MethodMirror {
  final DeclarationMirror owner;
  final Symbol simpleName;
  final bool isGetter;
  final bool isStatic;
  final bool isTopLevel;

  /// The field or type that introduces the synthetic accessor.
  final _target;

  JsSyntheticAccessor(this.owner, this.simpleName, this.isGetter, this.isStatic,
      this.isTopLevel, this._target);

  bool get isSynthetic => true;
  bool get isRegularMethod => false;
  bool get isOperator => false;
  bool get isConstructor => false;
  bool get isConstConstructor => false;
  bool get isGenerativeConstructor => false;
  bool get isFactoryConstructor => false;
  bool get isRedirectingConstructor => false;
  bool get isAbstract => false;

  bool get isSetter => !isGetter;
  bool get isPrivate => n(simpleName).startsWith('_');

  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);
  Symbol get constructorName => const Symbol('');

  TypeMirror get returnType => _target.type;
  List<ParameterMirror> get parameters {
    if (isGetter) return const [];
    return new UnmodifiableListView(
        [new JsSyntheticSetterParameter(this, this._target)]);
  }

  List<InstanceMirror> get metadata => const [];
  String get source => null;
  SourceLocation get location => throw new UnimplementedError();
}

class JsSyntheticSetterParameter implements ParameterMirror {
  final DeclarationMirror owner;
  final VariableMirror _target;

  JsSyntheticSetterParameter(this.owner, this._target);

  Symbol get simpleName => _target.simpleName;
  Symbol get qualifiedName => computeQualifiedName(owner, simpleName);
  TypeMirror get type => _target.type;

  bool get isOptional => false;
  bool get isNamed => false;
  bool get isStatic => false;
  bool get isTopLevel => false;
  bool get isConst => false;
  bool get isFinal => true;
  bool get isPrivate => false;
  bool get hasDefaultValue => false;
  InstanceMirror get defaultValue => null;
  List<InstanceMirror> get metadata => const [];
  SourceLocation get location => throw new UnimplementedError();
}

class JsClassMirror extends JsTypeMirror
    with JsObjectMirror
    implements ClassMirror {
  final String _mangledName;
  final _jsConstructor;
  final String _fieldsDescriptor;
  final List _fieldsMetadata;
  final _jsConstructorCache = JsCache.allocate();
  List _metadata;
  ClassMirror _superclass;
  List<JsMethodMirror> _cachedMethods;
  List<VariableMirror> _cachedFields;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedConstructors;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedMethodsMap;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedGetters;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedSetters;
  UnmodifiableMapView<Symbol, VariableMirror> _cachedVariables;
  UnmodifiableMapView<Symbol, Mirror> _cachedMembers;
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedDeclarations;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;
  UnmodifiableListView<ClassMirror> _cachedSuperinterfaces;
  UnmodifiableListView<TypeVariableMirror> _cachedTypeVariables;
  Map<Symbol, MethodMirror> _cachedInstanceMembers;
  Map<Symbol, MethodMirror> _cachedStaticMembers;

  // Set as side-effect of accessing JsLibraryMirror.classes.
  JsLibraryMirror _owner;

  JsClassMirror(Symbol simpleName, this._mangledName, this._jsConstructor,
      this._fieldsDescriptor, this._fieldsMetadata)
      : super(simpleName);

  String get _prettyName => 'ClassMirror';

  Map<Symbol, MethodMirror> get __constructors {
    if (_cachedConstructors != null) return _cachedConstructors;
    return _cachedConstructors = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterConstructors(_methods));
  }

  _asRuntimeType() {
    if (typeVariables.isEmpty) return _jsConstructor;
    var type = [_jsConstructor];
    for (int i = 0; i < typeVariables.length; i++) {
      type.add(JsMirrorSystem._dynamicType._asRuntimeType);
    }
    return type;
  }

  List<JsMethodMirror> _getMethodsWithOwner(DeclarationMirror methodOwner) {
    var prototype = JS('', '#.prototype', _jsConstructor);
    // The prototype might not have been processed yet, so do that now.
    JS('', '#[#]()', prototype,
        JS_GET_NAME(JsGetName.DEFERRED_ACTION_PROPERTY));
    List<String> keys = extractKeys(prototype);
    var result = <JsMethodMirror>[];
    for (String key in keys) {
      if (isReflectiveDataInPrototype(key)) continue;
      String simpleName = mangledNames[key];
      // [simpleName] can be null if [key] represents an implementation
      // detail, for example, a bailout method, or runtime type support.
      // It might also be null if the user has limited what is reified for
      // reflection with metadata.
      if (simpleName == null) continue;
      var function = JS('', '#[#]', prototype, key);
      if (!isOrdinaryReflectableMethod(function)) continue;
      if (isAliasedSuperMethod(function, key)) continue;
      var mirror = new JsMethodMirror.fromUnmangledName(
          simpleName, function, false, false);
      result.add(mirror);
      mirror._owner = methodOwner;
    }

    var statics = JS_EMBEDDED_GLOBAL('', STATICS);
    keys = extractKeys(JS('', '#[#]', statics, _mangledName));
    for (String mangledName in keys) {
      if (isReflectiveDataInPrototype(mangledName)) continue;
      String unmangledName = mangledName;
      var jsFunction = JS('', '#[#]', owner._globalObject, mangledName);

      bool isConstructor = false;
      if (hasReflectableProperty(jsFunction)) {
        String reflectionName =
            JS('String|Null', r'#.$reflectionName', jsFunction);
        if (reflectionName == null) continue;
        isConstructor = reflectionName.startsWith('new ');
        if (isConstructor) {
          reflectionName = reflectionName.substring(4).replaceAll(r'$', '.');
        }
        unmangledName = reflectionName;
      } else {
        continue;
      }
      bool isStatic = !isConstructor; // Constructors are not static.
      JsMethodMirror mirror = new JsMethodMirror.fromUnmangledName(
          unmangledName, jsFunction, isStatic, isConstructor);
      result.add(mirror);
      mirror._owner = methodOwner;
    }

    return result;
  }

  List<JsMethodMirror> get _methods {
    if (_cachedMethods != null) return _cachedMethods;
    return _cachedMethods = _getMethodsWithOwner(this);
  }

  List<VariableMirror> _getFieldsWithOwner(DeclarationMirror fieldOwner) {
    var result = <VariableMirror>[];

    var instanceFieldSpecfication = _fieldsDescriptor.split(';')[1];
    if (_fieldsMetadata != null) {
      instanceFieldSpecfication = [instanceFieldSpecfication]
        ..addAll(_fieldsMetadata);
    }
    parseCompactFieldSpecification(
        fieldOwner, instanceFieldSpecfication, false, result);

    var statics = JS_EMBEDDED_GLOBAL('', STATICS);
    var staticDescriptor = JS('', '#[#]', statics, _mangledName);
    if (staticDescriptor != null) {
      parseCompactFieldSpecification(
          fieldOwner,
          JS('', '#[#]', staticDescriptor,
              JS_GET_NAME(JsGetName.CLASS_DESCRIPTOR_PROPERTY)),
          true,
          result);
    }
    return result;
  }

  List<VariableMirror> get _fields {
    if (_cachedFields != null) return _cachedFields;
    return _cachedFields = _getFieldsWithOwner(this);
  }

  Map<Symbol, MethodMirror> get __methods {
    if (_cachedMethodsMap != null) return _cachedMethodsMap;
    return _cachedMethodsMap =
        new UnmodifiableMapView<Symbol, MethodMirror>(filterMethods(_methods));
  }

  Map<Symbol, MethodMirror> get __getters {
    if (_cachedGetters != null) return _cachedGetters;
    return _cachedGetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterGetters(_methods, __variables));
  }

  Map<Symbol, MethodMirror> get __setters {
    if (_cachedSetters != null) return _cachedSetters;
    return _cachedSetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterSetters(_methods, __variables));
  }

  Map<Symbol, VariableMirror> get __variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in _fields) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, Mirror> get __members {
    if (_cachedMembers != null) return _cachedMembers;
    return _cachedMembers = new UnmodifiableMapView<Symbol, Mirror>(
        filterMembers(_methods, __variables));
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    var result = new Map<Symbol, DeclarationMirror>();
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }

    __members.forEach(addToResult);
    __constructors.forEach(addToResult);
    typeVariables.forEach((tv) => result[tv.simpleName] = tv);
    return _cachedDeclarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(result);
  }

  Map<Symbol, MethodMirror> get staticMembers {
    if (_cachedStaticMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      declarations.values.forEach((decl) {
        if (decl is MethodMirror && decl.isStatic && !decl.isConstructor) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] = new JsSyntheticAccessor(
              this, getterName, true, true, false, decl);
          if (!decl.isFinal) {
            var setterName = setterSymbol(decl.simpleName);
            result[setterName] = new JsSyntheticAccessor(
                this, setterName, false, true, false, decl);
          }
        }
      });
      _cachedStaticMembers = result;
    }
    return _cachedStaticMembers;
  }

  Map<Symbol, MethodMirror> get instanceMembers {
    if (_cachedInstanceMembers == null) {
      var result = new Map<Symbol, MethodMirror>();
      if (superclass != null) {
        result.addAll(superclass.instanceMembers);
      }
      declarations.values.forEach((decl) {
        if (decl is MethodMirror &&
            !decl.isStatic &&
            !decl.isConstructor &&
            !decl.isAbstract) {
          result[decl.simpleName] = decl;
        }
        if (decl is VariableMirror && !decl.isStatic) {
          var getterName = decl.simpleName;
          result[getterName] = new JsSyntheticAccessor(
              this, getterName, true, false, false, decl);
          if (!decl.isFinal) {
            var setterName = setterSymbol(decl.simpleName);
            result[setterName] = new JsSyntheticAccessor(
                this, setterName, false, false, false, decl);
          }
        }
      });
      _cachedInstanceMembers = result;
    }
    return _cachedInstanceMembers;
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    JsVariableMirror mirror = __variables[fieldName];
    if (mirror != null && mirror.isStatic && !mirror.isFinal) {
      // '$' (JS_GET_STATIC_STATE()) stores state which is stored directly, so
      // we shouldn't use [JsLibraryMirror._globalObject] here.
      String jsName = mirror._jsName;
      if (!JS('bool', '# in #', jsName, JS_GET_STATIC_STATE())) {
        throw new RuntimeError('Cannot find "$jsName" in current isolate.');
      }
      JS('void', '#[#] = #', JS_GET_STATIC_STATE(), jsName, arg);
      return reflect(arg);
    }
    Symbol setterName = setterSymbol(fieldName);
    if (mirror == null) {
      JsMethodMirror setter = __setters[setterName];
      if (setter != null) {
        setter._invoke([arg], const {});
        return reflect(arg);
      }
    }
    throw new NoSuchStaticMethodError.method(null, setterName, [arg], null);
  }

  bool _staticFieldExists(Symbol fieldName) {
    JsVariableMirror mirror = __variables[fieldName];
    if (mirror != null) return mirror.isStatic;
    JsMethodMirror getter = __getters[fieldName];
    return getter != null && getter.isStatic;
  }

  InstanceMirror getField(Symbol fieldName) {
    JsVariableMirror mirror = __variables[fieldName];
    if (mirror != null && mirror.isStatic) {
      String jsName = mirror._jsName;
      // '$' (JS_GET_STATIC_STATE()) stores state which is read directly, so
      // we shouldn't use [JsLibraryMirror._globalObject] here.
      if (!JS('bool', '# in #', jsName, JS_GET_STATIC_STATE())) {
        throw new RuntimeError('Cannot find "$jsName" in current isolate.');
      }
      var lazies = JS_EMBEDDED_GLOBAL('', LAZIES);
      if (JS('bool', '# in #', jsName, lazies)) {
        String getterName = JS('String', '#[#]', lazies, jsName);
        return reflect(JS('', '#[#]()', JS_GET_STATIC_STATE(), getterName));
      } else {
        return reflect(JS('', '#[#]', JS_GET_STATIC_STATE(), jsName));
      }
    }
    JsMethodMirror getter = __getters[fieldName];
    if (getter != null && getter.isStatic) {
      return reflect(getter._invoke(const [], const {}));
    }
    // If the fieldName designates a static function we have to return
    // its closure.
    JsMethodMirror method = __methods[fieldName];
    if (method != null && method.isStatic) {
      // We invoke the same getter that Dart code would execute. During
      // initialization we have stored that getter on the function (so that
      // we can find it more easily here).
      var getter = JS("", "#['\$getter']", method._jsFunction);
      if (getter == null) throw new UnimplementedError();
      return reflect(JS("", "#()", getter));
    }
    throw new NoSuchStaticMethodError.method(null, fieldName, null, null);
  }

  _getInvokedInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsMethodMirror mirror =
        JsCache.fetch(_jsConstructorCache, n(constructorName));
    if (mirror == null) {
      mirror = __constructors.values
          .firstWhere((m) => m.constructorName == constructorName, orElse: () {
        throw new NoSuchStaticMethodError.method(
            null, constructorName, positionalArguments, namedArguments);
      });
      JsCache.update(_jsConstructorCache, n(constructorName), mirror);
    }
    return mirror._invoke(positionalArguments, namedArguments);
  }

  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return reflect(_getInvokedInstance(
        constructorName, positionalArguments, namedArguments));
  }

  JsLibraryMirror get owner {
    if (_owner == null) {
      for (var list in JsMirrorSystem.librariesByName.values) {
        for (JsLibraryMirror library in list) {
          // This will set _owner field on all classes as a side
          // effect.  This gives us a fast path to reflect on a
          // class without parsing reflection data.
          library.__classes;
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
      var typeInformationContainer = JS_EMBEDDED_GLOBAL('', TYPE_INFORMATION);
      List<int> typeInformation =
          JS('List|Null', '#[#]', typeInformationContainer, _mangledName);
      if (typeInformation != null) {
        var type = getType(typeInformation[0]);
        _superclass = typeMirrorFromRuntimeTypeRepresentation(this, type);
      } else {
        var superclassName = _fieldsDescriptor.split(';')[0].split(':')[0];
        // TODO(zarah): Remove special handing of mixins.
        var mixins = superclassName.split('+');
        if (mixins.length > 1) {
          if (mixins.length != 2) {
            throw new RuntimeError('Strange mixin: $_fieldsDescriptor');
          }
          _superclass = reflectClassByMangledName(mixins[0]);
        } else {
          // Use _superclass == this to represent class with no superclass
          // (Object).
          _superclass = (superclassName == '')
              ? this
              : reflectClassByMangledName(superclassName);
        }
      }
    }
    return _superclass == this ? null : _superclass;
  }

  InstanceMirror invoke(Symbol memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    // Mirror API gotcha: Calling [invoke] on a ClassMirror means invoke a
    // static method.

    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsMethodMirror mirror = __methods[memberName];

    if (mirror == null && _staticFieldExists(memberName)) {
      return getField(memberName)
          .invoke(#call, positionalArguments, namedArguments);
    }
    if (mirror == null || !mirror.isStatic) {
      throw new NoSuchStaticMethodError.method(
          null, memberName, positionalArguments, namedArguments);
    }
    if (!mirror.canInvokeReflectively()) {
      throwInvalidReflectionError(n(memberName));
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  delegate(Invocation invocation) {
    throw new UnimplementedError();
  }

  bool get isOriginalDeclaration => true;

  ClassMirror get originalDeclaration => this;

  List<ClassMirror> _getSuperinterfacesWithOwner(DeclarationMirror owner) {
    var typeInformationContainer = JS_EMBEDDED_GLOBAL('', TYPE_INFORMATION);
    List<int> typeInformation =
        JS('List|Null', '#[#]', typeInformationContainer, _mangledName);
    List<ClassMirror> result = const <ClassMirror>[];
    if (typeInformation != null) {
      ClassMirror lookupType(int i) {
        var type = getType(i);
        return typeMirrorFromRuntimeTypeRepresentation(owner, type);
      }

      //We skip the first since it is the supertype.
      result = typeInformation.skip(1).map(lookupType).toList();
    }

    return new UnmodifiableListView<ClassMirror>(result);
  }

  List<ClassMirror> get superinterfaces {
    if (_cachedSuperinterfaces != null) return _cachedSuperinterfaces;
    return _cachedSuperinterfaces = _getSuperinterfacesWithOwner(this);
  }

  List<TypeVariableMirror> get typeVariables {
    if (_cachedTypeVariables != null) return _cachedTypeVariables;
    List result = new List();
    List typeVariables =
        JS('JSExtendableArray|Null', '#.prototype["<>"]', _jsConstructor);
    if (typeVariables == null) return result;
    for (int i = 0; i < typeVariables.length; i++) {
      TypeVariable typeVariable = getMetadata(typeVariables[i]);
      result
          .add(new JsTypeVariableMirror(typeVariable, this, typeVariables[i]));
    }
    return _cachedTypeVariables = new UnmodifiableListView(result);
  }

  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get hasReflectedType => typeVariables.length == 0;

  Type get reflectedType {
    if (!hasReflectedType) {
      throw new UnsupportedError(
          "Declarations of generics have no reflected type");
    }
    return createRuntimeType(_mangledName);
  }

  // TODO(ahe): Implement this.
  ClassMirror get mixin => throw new UnimplementedError();

  bool get isAbstract => throw new UnimplementedError();

  bool get isEnum => throw new UnimplementedError();

  bool isSubclassOf(ClassMirror other) {
    if (other is! ClassMirror) {
      throw new ArgumentError(other);
    }
    if (other is JsFunctionTypeMirror) {
      return false;
    }
    if (other is JsClassMirror &&
        JS('bool', '# == #', other._jsConstructor, _jsConstructor)) {
      return true;
    } else if (superclass == null) {
      return false;
    } else {
      return superclass.isSubclassOf(other);
    }
  }
}

class JsVariableMirror extends JsDeclarationMirror implements VariableMirror {
  // TODO(ahe): The values in these fields are virtually untested.
  final String _jsName;
  final bool isFinal;
  final bool isStatic;
  final _metadataFunction;
  final DeclarationMirror _owner;
  final int _type;
  List _metadata;

  JsVariableMirror(Symbol simpleName, this._jsName, this._type, this.isFinal,
      this.isStatic, this._metadataFunction, this._owner)
      : super(simpleName);

  factory JsVariableMirror.from(String descriptor, metadataFunction,
      JsDeclarationMirror owner, bool isStatic) {
    List<String> fieldInformation = descriptor.split('-');
    if (fieldInformation.length == 1) {
      // The field is not available for reflection.
      // TODO(ahe): Should return an unreflectable field.
      return null;
    }

    String field = fieldInformation[0];
    int length = field.length;
    var code = fieldCode(field.codeUnitAt(length - 1));
    bool isFinal = false;
    if (code == 0) return null; // Inherited field.
    bool hasGetter = (code & 3) != 0;
    bool hasSetter = (code >> 2) != 0;
    isFinal = !hasSetter;
    length--;
    String jsName;
    String accessorName = jsName = field.substring(0, length);
    int divider = field.indexOf(':');
    if (divider > 0) {
      accessorName = accessorName.substring(0, divider);
      jsName = field.substring(divider + 1);
    }
    var unmangledName;
    if (isStatic) {
      unmangledName = mangledGlobalNames[accessorName];
    } else {
      String getterPrefix = JS_GET_NAME(JsGetName.GETTER_PREFIX);
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
    int type = int.parse(fieldInformation[1], onError: (_) => null);
    return new JsVariableMirror(s(unmangledName), jsName, type, isFinal,
        isStatic, metadataFunction, owner);
  }

  String get _prettyName => 'VariableMirror';

  TypeMirror get type {
    return typeMirrorFromRuntimeTypeRepresentation(owner, getType(_type));
  }

  DeclarationMirror get owner => _owner;

  List<InstanceMirror> get metadata {
    preserveMetadata();
    if (_metadata == null) {
      _metadata = (_metadataFunction == null)
          ? const []
          : JS('', '#()', _metadataFunction);
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
      // TODO(floitsch): when the field is non-static we don't want to have
      // a mirror as receiver.
      if (isStatic) {
        throw new NoSuchStaticMethodError.method(
            null, setterSymbol(simpleName), [arg], null);
      }
      throw new NoSuchMethodError(this, setterSymbol(simpleName), [arg], null);
    }
    receiver._storeField(_jsName, arg);
  }

  // TODO(ahe): Implement this method.
  bool get isConst => throw new UnimplementedError();
}

class JsClosureMirror extends JsInstanceMirror implements ClosureMirror {
  JsClosureMirror(reflectee) : super(reflectee);

  MethodMirror get function {
    String cacheName = Primitives.mirrorFunctionCacheName;
    JsMethodMirror cachedFunction;
    // TODO(ahe): Restore caching.
    //= JS('JsMethodMirror|Null', r'#.constructor[#]', reflectee, cacheName);
    if (cachedFunction != null) return cachedFunction;
    disableTreeShaking();
    // TODO(ahe): What about optional parameters (named or not).
    String callPrefix = "${JS_GET_NAME(JsGetName.CALL_PREFIX)}\$";

    String callName = JS(
        'String|Null',
        r'''
          (function(reflectee, callPrefix) {
            var properties = Object.keys(reflectee.constructor.prototype);
            var callPrefixLength = callPrefix.length;
            for (var i = 0; i < properties.length; i++) {
              var property = properties[i];
              if (callPrefix == property.substring(0, callPrefixLength) &&
                  property[callPrefixLength] >= "0" &&
                  property[callPrefixLength] <= "9") {
                return property;
              }
            }
            return null;
          })(#, #)''',
        reflectee,
        callPrefix);

    if (callName == null) {
      throw new RuntimeError('Cannot find callName on "$reflectee"');
    }
    // TODO(floitsch): What about optional parameters?
    int parameterCount = int.parse(callName.split(r'$')[1]);
    if (reflectee is BoundClosure) {
      var target = BoundClosure.targetOf(reflectee);
      var self = BoundClosure.selfOf(reflectee);
      var name = mangledNames[BoundClosure.nameOf(reflectee)];
      if (name == null) {
        throwInvalidReflectionError(name);
      }
      cachedFunction =
          new JsMethodMirror.fromUnmangledName(name, target, false, false);
    } else {
      bool isStatic = true; // TODO(ahe): Compute isStatic correctly.
      var jsFunction = JS('', '#[#]', reflectee, callName);
      var dummyOptionalParameterCount = 0;
      cachedFunction = new JsMethodMirror(
          s(callName),
          jsFunction,
          parameterCount,
          dummyOptionalParameterCount,
          false,
          false,
          isStatic,
          false,
          false);
    }
    JS('void', r'#.constructor[#] = #', reflectee, cacheName, cachedFunction);
    return cachedFunction;
  }

  InstanceMirror apply(List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]) {
    return reflect(
        Function.apply(reflectee, positionalArguments, namedArguments));
  }

  TypeMirror get type {
    // Classes that implement [call] do not subclass [Closure], but only
    // implement [Function], so are rejected by this test.
    if (reflectee is Closure) {
      var functionRti = extractFunctionTypeObjectFrom(reflectee);
      if (functionRti != null) {
        return new JsFunctionTypeMirror(functionRti, null);
      }
    }
    // Use the JsInstanceMirror method to return the JsClassMirror.
    // TODO(sra): Should there be a TypeMirror that is both a ClassMirror and
    // FunctionTypeMirror?
    return super.type;
  }

  String toString() => "ClosureMirror on '${Error.safeToString(reflectee)}'";

  // TODO(ahe): Implement this method.
  String get source => throw new UnimplementedError();
}

class JsMethodMirror extends JsDeclarationMirror implements MethodMirror {
  final _jsFunction;
  final int _requiredParameterCount;
  final int _optionalParameterCount;
  final bool isGetter;
  final bool isSetter;
  final bool isStatic;
  final bool isConstructor;
  final bool isOperator;
  DeclarationMirror _owner;
  List _metadata;
  TypeMirror _returnType;
  UnmodifiableListView<ParameterMirror> _parameters;

  JsMethodMirror(
      Symbol simpleName,
      this._jsFunction,
      this._requiredParameterCount,
      this._optionalParameterCount,
      this.isGetter,
      this.isSetter,
      this.isStatic,
      this.isConstructor,
      this.isOperator)
      : super(simpleName);

  factory JsMethodMirror.fromUnmangledName(
      String name, jsFunction, bool isStatic, bool isConstructor) {
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
      ReflectionInfo reflectionInfo = new ReflectionInfo(jsFunction);
      requiredParameterCount = reflectionInfo.requiredParameterCount;
      optionalParameterCount = reflectionInfo.optionalParameterCount;
      assert(int.parse(info[1]) ==
          requiredParameterCount + optionalParameterCount);
    }
    return new JsMethodMirror(
        s(name),
        jsFunction,
        requiredParameterCount,
        optionalParameterCount,
        isGetter,
        isSetter,
        isStatic,
        isConstructor,
        isOperator);
  }

  String get _prettyName => 'MethodMirror';

  int get _parameterCount => _requiredParameterCount + _optionalParameterCount;

  List<ParameterMirror> get parameters {
    if (_parameters != null) return _parameters;
    metadata; // Compute _parameters as a side-effect of extracting metadata.
    return _parameters;
  }

  bool canInvokeReflectively() {
    return hasReflectableProperty(_jsFunction);
  }

  DeclarationMirror get owner => _owner;

  TypeMirror get returnType {
    metadata; // Compute _returnType as a side-effect of extracting metadata.
    return _returnType;
  }

  List<InstanceMirror> get metadata {
    if (_metadata == null) {
      var raw = extractMetadata(_jsFunction);
      var formals = new List(_parameterCount);
      ReflectionInfo info = new ReflectionInfo(_jsFunction);
      if (info != null) {
        assert(_parameterCount ==
            info.requiredParameterCount + info.optionalParameterCount);
        var functionType = info.functionType;
        var type;
        if (functionType is int) {
          type = new JsFunctionTypeMirror(info.computeFunctionRti(null), this);
          assert(_parameterCount == type.parameters.length);
        } else if (isTopLevel) {
          type = new JsFunctionTypeMirror(info.computeFunctionRti(null), owner);
        } else {
          TypeMirror ownerType = owner;
          JsClassMirror ownerClass = ownerType.originalDeclaration;
          type = new JsFunctionTypeMirror(
              info.computeFunctionRti(ownerClass._jsConstructor), owner);
        }
        // Constructors aren't reified with their return type.
        if (isConstructor) {
          _returnType = owner;
        } else {
          _returnType = type.returnType;
        }
        int i = 0;
        bool isNamed = info.areOptionalParametersNamed;
        for (JsParameterMirror parameter in type.parameters) {
          var name = info.parameterName(i);
          List<int> annotations = info.parameterMetadataAnnotations(i);
          var p;
          if (i < info.requiredParameterCount) {
            p = new JsParameterMirror(name, this, parameter._type,
                metadataList: annotations);
          } else {
            var defaultValue = info.defaultValue(i);
            p = new JsParameterMirror(name, this, parameter._type,
                metadataList: annotations,
                isOptional: true,
                isNamed: isNamed,
                defaultValue: defaultValue);
          }
          formals[i++] = p;
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
    int positionalLength = positionalArguments.length;
    if (positionalLength < _requiredParameterCount ||
        positionalLength > _parameterCount ||
        _jsFunction == null) {
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          owner, simpleName, positionalArguments, namedArguments);
    }
    if (positionalLength < _parameterCount) {
      // Fill up with default values.
      // Make a copy so we don't modify the input.
      positionalArguments = positionalArguments.toList();
      for (int i = positionalLength; i < parameters.length; i++) {
        JsParameterMirror parameter = parameters[i];
        positionalArguments.add(parameter.defaultValue.reflectee);
      }
    }
    // Using JS_GET_STATIC_STATE() ('$') here is actually correct, although
    // _jsFunction may not be a property of '$', most static functions do not
    // care who their receiver is. But to lazy getters, it is important that
    // 'this' is '$'.
    return JS('', r'#.apply(#, #)', _jsFunction, JS_GET_STATIC_STATE(),
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
      throw new NoSuchMethodError(this, setterSymbol(simpleName), [], null);
    }
  }

  // Abstract methods are tree-shaken away.
  bool get isAbstract => false;

  // TODO(ahe, 14633): This might not be true for all cases.
  bool get isSynthetic => false;

  // TODO(ahe): Test this.
  bool get isRegularMethod => !isGetter && !isSetter && !isConstructor;

  // TODO(ahe): Implement this method.
  bool get isConstConstructor => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  bool get isGenerativeConstructor => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  bool get isRedirectingConstructor => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  bool get isFactoryConstructor => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  String get source => throw new UnimplementedError();
}

class JsParameterMirror extends JsDeclarationMirror implements ParameterMirror {
  final DeclarationMirror owner;
  // A JS object representing the type.
  final _type;

  final bool isOptional;

  final bool isNamed;

  final int _defaultValue;

  final List<int> metadataList;

  JsParameterMirror(String unmangledName, this.owner, this._type,
      {this.metadataList: const <int>[],
      this.isOptional: false,
      this.isNamed: false,
      defaultValue})
      : _defaultValue = defaultValue,
        super(s(unmangledName));

  String get _prettyName => 'ParameterMirror';

  TypeMirror get type {
    return typeMirrorFromRuntimeTypeRepresentation(owner, _type);
  }

  // Only true for static fields, never for a parameter.
  bool get isStatic => false;

  // TODO(ahe): Implement this.
  bool get isFinal => false;

  // TODO(ahe): Implement this.
  bool get isConst => false;

  bool get hasDefaultValue => _defaultValue != null;

  get defaultValue {
    return hasDefaultValue ? reflect(getMetadata(_defaultValue)) : null;
  }

  List<InstanceMirror> get metadata {
    preserveMetadata();
    return metadataList.map((int i) => reflect(getMetadata(i))).toList();
  }
}

class JsTypedefMirror extends JsDeclarationMirror implements TypedefMirror {
  final String _mangledName;
  JsFunctionTypeMirror referent;

  JsTypedefMirror(Symbol simpleName, this._mangledName, _typeData)
      : super(simpleName) {
    referent = new JsFunctionTypeMirror(_typeData, this);
  }

  JsFunctionTypeMirror get value => referent;

  String get _prettyName => 'TypedefMirror';

  bool get hasReflectedType => throw new UnimplementedError();

  Type get reflectedType => createRuntimeType(_mangledName);

  // TODO(floitsch): Implement this method.
  List<TypeVariableMirror> get typeVariables => throw new UnimplementedError();

  // TODO(floitsch): Implement this method.
  List<TypeMirror> get typeArguments => throw new UnimplementedError();

  bool get isOriginalDeclaration => true;

  TypeMirror get originalDeclaration => this;

  // TODO(floitsch): Implement this method.
  DeclarationMirror get owner => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  List<InstanceMirror> get metadata => throw new UnimplementedError();

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();
  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();
}

// TODO(ahe): Remove this class when API is updated.
class BrokenClassMirror {
  bool get hasReflectedType => throw new UnimplementedError();
  Type get reflectedType => throw new UnimplementedError();
  ClassMirror get superclass => throw new UnimplementedError();
  List<ClassMirror> get superinterfaces => throw new UnimplementedError();
  Map<Symbol, DeclarationMirror> get declarations =>
      throw new UnimplementedError();
  Map<Symbol, MethodMirror> get instanceMembers =>
      throw new UnimplementedError();
  Map<Symbol, MethodMirror> get staticMembers => throw new UnimplementedError();
  ClassMirror get mixin => throw new UnimplementedError();
  InstanceMirror newInstance(Symbol constructorName, List positionalArguments,
          [Map<Symbol, dynamic> namedArguments]) =>
      throw new UnimplementedError();
  InstanceMirror invoke(Symbol memberName, List positionalArguments,
          [Map<Symbol, dynamic> namedArguments]) =>
      throw new UnimplementedError();
  InstanceMirror getField(Symbol fieldName) => throw new UnimplementedError();
  InstanceMirror setField(Symbol fieldName, Object value) =>
      throw new UnimplementedError();
  delegate(Invocation invocation) => throw new UnimplementedError();
  List<TypeVariableMirror> get typeVariables => throw new UnimplementedError();
  List<TypeMirror> get typeArguments => throw new UnimplementedError();
  TypeMirror get originalDeclaration => throw new UnimplementedError();
  Symbol get simpleName => throw new UnimplementedError();
  Symbol get qualifiedName => throw new UnimplementedError();
  bool get isPrivate => throw new UnimplementedError();
  bool get isTopLevel => throw new UnimplementedError();
  SourceLocation get location => throw new UnimplementedError();
  List<InstanceMirror> get metadata => throw new UnimplementedError();
}

class JsFunctionTypeMirror extends BrokenClassMirror
    implements FunctionTypeMirror {
  final _typeData;
  String _cachedToString;
  TypeMirror _cachedReturnType;
  UnmodifiableListView<ParameterMirror> _cachedParameters;
  Type _cachedReflectedType;
  DeclarationMirror owner;

  JsFunctionTypeMirror(this._typeData, this.owner);

  bool get _hasReturnType {
    return JS('bool', '# in #',
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_RETURN_TYPE_TAG), _typeData);
  }

  get _returnType {
    return JS('', '#[#]', _typeData,
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_RETURN_TYPE_TAG));
  }

  bool get _isVoid {
    return JS('bool', '!!#[#]', _typeData,
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_VOID_RETURN_TAG));
  }

  bool get _hasArguments {
    return JS(
        'bool',
        '# in #',
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG),
        _typeData);
  }

  List get _arguments {
    return JS('JSExtendableArray', '#[#]', _typeData,
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG));
  }

  bool get _hasOptionalArguments {
    return JS(
        'bool',
        '# in #',
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG),
        _typeData);
  }

  List get _optionalArguments {
    return JS('JSExtendableArray', '#[#]', _typeData,
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG));
  }

  bool get _hasNamedArguments {
    return JS('bool', '# in #',
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_NAMED_PARAMETERS_TAG), _typeData);
  }

  get _namedArguments {
    return JS('=Object', '#[#]', _typeData,
        JS_GET_NAME(JsGetName.FUNCTION_TYPE_NAMED_PARAMETERS_TAG));
  }

  bool get isOriginalDeclaration => true;

  bool get isAbstract => false;

  bool get isEnum => false;

  TypeMirror get returnType {
    if (_cachedReturnType != null) return _cachedReturnType;
    if (_isVoid) return _cachedReturnType = JsMirrorSystem._voidType;
    if (!_hasReturnType) return _cachedReturnType = JsMirrorSystem._dynamicType;
    return _cachedReturnType =
        typeMirrorFromRuntimeTypeRepresentation(owner, _returnType);
  }

  List<ParameterMirror> get parameters {
    if (_cachedParameters != null) return _cachedParameters;
    List result = [];
    int parameterCount = 0;
    if (_hasArguments) {
      for (var type in _arguments) {
        result.add(
            new JsParameterMirror('argument${parameterCount++}', this, type));
      }
    }
    if (_hasOptionalArguments) {
      for (var type in _optionalArguments) {
        result.add(
            new JsParameterMirror('argument${parameterCount++}', this, type));
      }
    }
    if (_hasNamedArguments) {
      for (var name in extractKeys(_namedArguments)) {
        var type = JS('', '#[#]', _namedArguments, name);
        result.add(new JsParameterMirror(name, this, type));
      }
    }
    return _cachedParameters =
        new UnmodifiableListView<ParameterMirror>(result);
  }

  bool get hasReflectedType => true;
  Type get reflectedType => _cachedReflectedType ??=
      createRuntimeType(runtimeTypeToString(_typeData));

  String _unmangleIfPreserved(String mangled) {
    String result = unmangleGlobalNameIfPreservedAnyways(mangled);
    if (result != null) return result;
    return mangled;
  }

  String toString() {
    if (_cachedToString != null) return _cachedToString;
    var s = "FunctionTypeMirror on '(";
    var sep = '';
    if (_hasArguments) {
      for (var argument in _arguments) {
        s += sep;
        s += _unmangleIfPreserved(runtimeTypeToString(argument));
        sep = ', ';
      }
    }
    if (_hasOptionalArguments) {
      s += '$sep[';
      sep = '';
      for (var argument in _optionalArguments) {
        s += sep;
        s += _unmangleIfPreserved(runtimeTypeToString(argument));
        sep = ', ';
      }
      s += ']';
    }
    if (_hasNamedArguments) {
      s += '$sep{';
      sep = '';
      for (var name in extractKeys(_namedArguments)) {
        s += sep;
        s += '$name: ';
        s += _unmangleIfPreserved(
            runtimeTypeToString(JS('', '#[#]', _namedArguments, name)));
        sep = ', ';
      }
      s += '}';
    }
    s += ') -> ';
    if (_isVoid) {
      s += 'void';
    } else if (_hasReturnType) {
      s += _unmangleIfPreserved(runtimeTypeToString(_returnType));
    } else {
      s += 'dynamic';
    }
    return _cachedToString = "$s'";
  }

  bool isSubclassOf(ClassMirror other) => false;

  bool isSubtypeOf(TypeMirror other) => throw new UnimplementedError();

  bool isAssignableTo(TypeMirror other) => throw new UnimplementedError();

  // TODO(ahe): Implement this method.
  MethodMirror get callMethod => throw new UnimplementedError();
}

int findTypeVariableIndex(List<TypeVariableMirror> typeVariables, String name) {
  for (int i = 0; i < typeVariables.length; i++) {
    if (typeVariables[i].simpleName == s(name)) {
      return i;
    }
  }
  throw new ArgumentError('Type variable not present in list.');
}

TypeMirror typeMirrorFromRuntimeTypeRepresentation(
    DeclarationMirror owner, var /*int|List|JsFunction|TypeImpl*/ type) {
  // TODO(ahe): This method might benefit from using convertRtiToRuntimeType
  // instead of working on strings.
  if (type == null) {
    return JsMirrorSystem._dynamicType;
  }

  ClassMirror ownerClass;
  DeclarationMirror context = owner;
  while (context != null) {
    if (context is ClassMirror) {
      ownerClass = context;
      break;
    }
    // TODO(ahe): Get type parameters and arguments from typedefs.
    if (context is TypedefMirror) break;
    context = context.owner;
  }

  String representation;
  if (type is TypeImpl) {
    return reflectType(type);
  } else if (ownerClass == null) {
    representation = runtimeTypeToString(type);
  } else if (ownerClass.isOriginalDeclaration) {
    if (type is num) {
      // [type] represents a type variable so in the context of an original
      // declaration the corresponding type variable should be returned.
      TypeVariable typeVariable = getMetadata(type);
      List<TypeVariableMirror> typeVariables = ownerClass.typeVariables;
      int index = findTypeVariableIndex(typeVariables, typeVariable.name);
      return typeVariables[index];
    } else {
      // Nested type variables will be retrieved lazily (the integer
      // representation is kept in the string) so they are not processed here.
      representation = runtimeTypeToString(type);
    }
  } else {
    TypeMirror getTypeArgument(int index) {
      TypeVariable typeVariable = getMetadata(index);
      int variableIndex =
          findTypeVariableIndex(ownerClass.typeVariables, typeVariable.name);
      return ownerClass.typeArguments[variableIndex];
    }

    if (type is num) {
      // [type] represents a type variable used as type argument for example
      // the type argument of Bar: class Foo<T> extends Bar<T> {}
      TypeMirror typeArgument = getTypeArgument(type);
      if (typeArgument is JsTypeVariableMirror) return typeArgument;
    }
    String substituteTypeVariable(int index) {
      var typeArgument = getTypeArgument(index);
      if (typeArgument is JsTypeVariableMirror) {
        return '${typeArgument._metadataIndex}';
      }
      if (typeArgument is! JsClassMirror &&
          typeArgument is! JsTypeBoundClassMirror) {
        if (typeArgument == JsMirrorSystem._dynamicType) {
          return 'dynamic';
        } else if (typeArgument == JsMirrorSystem._voidType) {
          return 'void';
        } else {
          // TODO(ahe): This case shouldn't happen.
          return 'dynamic';
        }
      }
      return typeArgument._mangledName;
    }

    representation =
        runtimeTypeToString(type, onTypeVariable: substituteTypeVariable);
  }
  if (representation != null) {
    return reflectClassByMangledName(
        getMangledTypeName(createRuntimeType(representation)));
  }
  String typedefPropertyName = JS_GET_NAME(JsGetName.TYPEDEF_TAG);
  if (JS('', '#[#]', type, typedefPropertyName) != null) {
    return typeMirrorFromRuntimeTypeRepresentation(
        owner, JS('', '#[#]', type, typedefPropertyName));
  } else if (isDartFunctionType(type)) {
    return new JsFunctionTypeMirror(type, owner);
  }
  return reflectClass(Function);
}

Symbol computeQualifiedName(DeclarationMirror owner, Symbol simpleName) {
  if (owner == null) return simpleName;
  String ownerName = n(owner.qualifiedName);
  return s('$ownerName.${n(simpleName)}');
}

List extractMetadata(victim) {
  preserveMetadata();
  var metadataFunction;
  if (JS('bool', 'Object.prototype.hasOwnProperty.call(#, "@")', victim)) {
    metadataFunction = JS('', '#["@"]', victim);
  }
  if (metadataFunction != null) return JS('', '#()', metadataFunction);
  if (JS('bool', 'typeof # != "function"', victim)) return const [];
  if (JS('bool', '# in #', r'$metadataIndex', victim)) {
    return JSArray
        .markFixedList(JS('JSExtendableArray',
            r'#.$reflectionInfo.splice(#.$metadataIndex)', victim, victim))
        .map((int i) => getMetadata(i))
        .toList();
  }
  return const [];
}

void parseCompactFieldSpecification(JsDeclarationMirror owner,
    fieldSpecification, bool isStatic, List<Mirror> result) {
  List fieldsMetadata = null;
  List<String> fields;
  if (fieldSpecification is List) {
    fields = splitFields(fieldSpecification[0], ',');
    fieldsMetadata = fieldSpecification.sublist(1);
  } else if (fieldSpecification is String) {
    fields = splitFields(fieldSpecification, ',');
  } else {
    fields = [];
  }
  int fieldNumber = 0;
  for (String field in fields) {
    if (r'$ti' == field) continue; // Strip type info pseudofield.
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

/// Returns true if the key represent ancillary reflection data, that is, not a
/// method.
bool isReflectiveDataInPrototype(String key) {
  if (key == JS_GET_NAME(JsGetName.CLASS_DESCRIPTOR_PROPERTY) ||
      key == METHODS_WITH_OPTIONAL_ARGUMENTS) {
    return true;
  }
  String firstChar = key[0];
  return firstChar == '*' || firstChar == '+';
}

/// Returns `true` if [jsFunction] is an ordinary reflectable method and
/// not a (potentially reflectable) stub or otherwise non-reflectable method.
bool isOrdinaryReflectableMethod(var jsFunction) {
  return JS('bool', r'#.$reflectable === 1', jsFunction);
}

/// Returns true if [key] is only an aliased entry for [function] in the
/// prototype.
bool isAliasedSuperMethod(var jsFunction, String key) {
  var stubName = JS('String|Null', r'#.$stubName', jsFunction);
  return stubName != null && key != stubName;
}

class NoSuchStaticMethodError extends Error implements NoSuchMethodError {
  static const int MISSING_CONSTRUCTOR = 0;
  static const int MISSING_METHOD = 1;
  final ClassMirror _cls;
  final Symbol _name;
  final List _positionalArguments;
  final Map<Symbol, dynamic> _namedArguments;
  final int _kind;

  NoSuchStaticMethodError.missingConstructor(
      this._cls, this._name, this._positionalArguments, this._namedArguments)
      : _kind = MISSING_CONSTRUCTOR;

  /// If the given class is `null` the static method/getter/setter is top-level.
  NoSuchStaticMethodError.method(
      this._cls, this._name, this._positionalArguments, this._namedArguments)
      : _kind = MISSING_METHOD;

  String toString() {
    // TODO(floitsch): show arguments.
    switch (_kind) {
      case MISSING_CONSTRUCTOR:
        return "NoSuchMethodError: No constructor named '${n(_name)}' in class"
            " '${n(_cls.qualifiedName)}'.";
      case MISSING_METHOD:
        if (_cls == null) {
          return "NoSuchMethodError: No top-level method named '${n(_name)}'.";
        }
        return "NoSuchMethodError: No static method named '${n(_name)}' in"
            " class '${n(_cls.qualifiedName)}'";
      default:
        return 'NoSuchMethodError';
    }
  }
}

Symbol getSymbol(String name, LibraryMirror library) {
  if (_isPublicSymbol(name)) {
    return new _symbol_dev.Symbol.validated(name);
  }
  if (library == null) {
    throw new ArgumentError("Library required for private symbol name: $name");
  }
  if (!_symbol_dev.Symbol.isValidSymbol(name)) {
    throw new ArgumentError("Not a valid symbol name: $name");
  }
  throw new UnimplementedError(
      "MirrorSystem.getSymbol not implemented for private names");
}

bool _isPublicSymbol(String name) {
  // A symbol is public if it doesn't start with '_' and it doesn't
  // have a part (following a '.') that starts with '_'.
  const int UNDERSCORE = 0x5f;
  if (name.isEmpty) return true;
  int index = -1;
  do {
    if (name.codeUnitAt(index + 1) == UNDERSCORE) return false;
    index = name.indexOf('.', index + 1);
  } while (index >= 0 && index + 1 < name.length);
  return true;
}
