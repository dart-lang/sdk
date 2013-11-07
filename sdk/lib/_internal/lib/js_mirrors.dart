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
    getMangledTypeName,
    throwInvalidReflectionError,
    hasReflectableProperty,
    runtimeTypeToString,
    TypeVariable;
import 'dart:_interceptors' show
    Interceptor,
    JSExtendableArray;
import 'dart:_js_names';

const String METHODS_WITH_OPTIONAL_ARGUMENTS = r'$methodsWithOptionalArguments';

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

  LibraryMirror findLibrary(Symbol libraryName) {
    return librariesByName[n(libraryName)].single;
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
      var globalObject = data[7];
      List metadata = (metadataFunction == null)
          ? const [] : JS('List', '#()', metadataFunction);
      var libraries = result.putIfAbsent(name, () => <LibraryMirror>[]);
      libraries.add(
          new JsLibraryMirror(
              s(name), uri, classes, functions, metadata, fields, isRoot,
              globalObject));
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

class JsTypeVariableMirror extends JsTypeMirror implements TypeVariableMirror {
  final DeclarationMirror owner;
  final TypeVariable _typeVariable;
  TypeMirror _cachedUpperBound;

  JsTypeVariableMirror(TypeVariable typeVariable, this.owner)
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

  TypeMirror get upperBound {
    if (_cachedUpperBound != null) return _cachedUpperBound;
    return _cachedUpperBound = typeMirrorFromRuntimeTypeRepresentation(
        owner, getMetadata(_typeVariable.bound));
  }
}

class JsTypeMirror extends JsDeclarationMirror implements TypeMirror {
  JsTypeMirror(Symbol simpleName)
      : super(simpleName);

  String get _prettyName => 'TypeMirror';

  DeclarationMirror get owner => null;

  // TODO(ahe): Doesn't match the specification, see http://dartbug.com/11569.
  bool get isTopLevel => true;

  // TODO(ahe): Implement these.
  List<InstanceMirror> get metadata => throw new UnimplementedError();

  bool get hasReflectedType => false;
  Type get reflectedType => throw new UnsupportedError("This type does not support reflectedTypees");

  List<TypeVariableMirror> get typeVariables => const <TypeVariableMirror>[];
  List<TypeMirror> get typeArguments => const <TypeMirror>[];

  bool get isOriginalDeclaration => true;
  TypeMirror get originalDeclaration => this;
}

class JsLibraryMirror extends JsDeclarationMirror with JsObjectMirror
    implements LibraryMirror {
  final Uri uri;
  final List<String> _classes;
  final List<String> _functions;
  final List _metadata;
  final String _compactFieldSpecification;
  final bool _isRoot;
  final _globalObject;
  List<JsMethodMirror> _cachedFunctionMirrors;
  List<JsVariableMirror> _cachedFields;
  UnmodifiableMapView<Symbol, ClassMirror> _cachedClasses;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedFunctions;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedGetters;
  UnmodifiableMapView<Symbol, MethodMirror> _cachedSetters;
  UnmodifiableMapView<Symbol, VariableMirror> _cachedVariables;
  UnmodifiableMapView<Symbol, Mirror> _cachedMembers;
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedDeclarations;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;

  JsLibraryMirror(Symbol simpleName,
                  this.uri,
                  this._classes,
                  this._functions,
                  this._metadata,
                  this._compactFieldSpecification,
                  this._isRoot,
                  this._globalObject)
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
      throw new NoSuchMethodError(this, setterSymbol(fieldName), [arg], null);
    }
    mirror._setField(this, arg);
    return reflect(arg);
  }

  InstanceMirror getField(Symbol fieldName) {
    JsMirror mirror = members[fieldName];
    if (mirror == null) {
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(this, fieldName, [], null);
    }
    return reflect(mirror._getField(this));
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]) {
    if (namedArguments != null && !namedArguments.isEmpty) {
      throw new UnsupportedError('Named arguments are not implemented.');
    }
    JsDeclarationMirror mirror = members[memberName];
    if (mirror == null) {
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          this, memberName, positionalArguments, namedArguments);
    }
    if (mirror is JsMethodMirror) {
      JsMethodMirror method = mirror;
      if (!method.canInvokeReflectively()) {
        throwInvalidReflectionError(n(memberName));
      }
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  _loadField(String name) {
    // TODO(ahe): What about lazily initialized fields? See
    // [JsClassMirror.getField].

    // '$' (JS_CURRENT_ISOLATE()) stores state which is read directly, so we
    // shouldn't use [_globalObject] here.
    assert(JS('bool', '# in #', name, JS_CURRENT_ISOLATE()));
    return JS('', '#[#]', JS_CURRENT_ISOLATE(), name);
  }

  void _storeField(String name, Object arg) {
    // '$' (JS_CURRENT_ISOLATE()) stores state which is stored directly, so we
    // shouldn't use [_globalObject] here.
    assert(JS('bool', '# in #', name, JS_CURRENT_ISOLATE()));
    JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), name, arg);
  }

  List<JsMethodMirror> get _functionMirrors {
    if (_cachedFunctionMirrors != null) return _cachedFunctionMirrors;
    var result = new List<JsMethodMirror>();
    for (int i = 0; i < _functions.length; i++) {
      String name = _functions[i];
      var jsFunction = JS('', '#[#]', _globalObject, name);
      String unmangledName = mangledGlobalNames[name];
      if (unmangledName == null) {
        // If there is no unmangledName, [jsFunction] is either a synthetic
        // implementation detail, or something that is excluded
        // by @MirrorsUsed.
        continue;
      }
      bool isConstructor = unmangledName.startsWith('new ');
      bool isStatic = !isConstructor; // Top-level functions are static, but
                                      // constructors are not.
      if (isConstructor) {
        unmangledName = unmangledName.substring(4).replaceAll(r'$', '.');
      }
      JsMethodMirror mirror =
          new JsMethodMirror.fromUnmangledName(
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

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    var result = new Map<Symbol, DeclarationMirror>();
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }
    members.forEach(addToResult);
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
}

String n(Symbol symbol) => _symbol_dev.Symbol.getName(symbol);

Symbol s(String name) {
  if (name == null) return null;
  return new _symbol_dev.Symbol.unvalidated(name);
}

Symbol setterSymbol(Symbol symbol) => s("${n(symbol)}=");

final JsMirrorSystem currentJsMirrorSystem = new JsMirrorSystem();

InstanceMirror reflect(Object reflectee) {
  if (reflectee is Closure) {
    return new JsClosureMirror(reflectee);
  } else {
    return new JsInstanceMirror(reflectee);
  }
}

TypeMirror reflectType(Type key) {
  return reflectClassByMangledName(getMangledTypeName(key));
}

TypeMirror reflectClassByMangledName(String mangledName) {
  String unmangledName = mangledGlobalNames[mangledName];
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
    mirror = new JsTypeBoundClassMirror(
        reflectClassByMangledName(mangledName.substring(0, typeArgIndex)),
        // Remove the angle brackets enclosing the type arguments.
        mangledName.substring(typeArgIndex + 1, mangledName.length - 1));
    JsCache.update(classMirrors, mangledName, mirror);
    return mirror;
  }
  var constructorOrInterceptor =
      Primitives.getConstructorOrInterceptor(mangledName);
  if (constructorOrInterceptor == null) {
    int index = JS('int|Null', 'init.functionAliases[#]', mangledName);
    if (index != null) {
      mirror = new JsTypedefMirror(symbol, mangledName, getMetadata(index));
      JsCache.update(classMirrors, mangledName, mirror);
      return mirror;
    }
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

Map<Symbol, MethodMirror> filterGetters(List<MethodMirror> methods,
                                        Map<Symbol, VariableMirror> fields) {
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

Map<Symbol, MethodMirror> filterSetters(List<MethodMirror> methods,
                                        Map<Symbol, VariableMirror> fields) {
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

Map<Symbol, Mirror> filterMembers(List<MethodMirror> methods,
                                  Map<Symbol, VariableMirror> variables) {
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

class JsMixinApplication extends JsTypeMirror with JsObjectMirror
    implements ClassMirror {
  final ClassMirror superclass;
  final ClassMirror mixin;
  Symbol _cachedSimpleName;

  JsMixinApplication(ClassMirror superclass, ClassMirror mixin,
                     String mangledName)
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

  Map<Symbol, Mirror> get members => _mixin.members;

  Map<Symbol, MethodMirror> get methods => _mixin.methods;

  Map<Symbol, MethodMirror> get getters => _mixin.getters;

  Map<Symbol, MethodMirror> get setters => _mixin.setters;

  Map<Symbol, VariableMirror> get variables => _mixin.variables;

  Map<Symbol, DeclarationMirror> get declarations => mixin.declarations;

  InstanceMirror invoke(
      Symbol memberName,
      List positionalArguments,
      [Map<Symbol,dynamic> namedArguments]) {
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, memberName,
                                positionalArguments, namedArguments);
  }

  InstanceMirror getField(Symbol fieldName) {
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, fieldName, null, null);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, setterSymbol(fieldName), [arg], null);
  }

  List<ClassMirror> get superinterfaces => [mixin];

  Map<Symbol, MethodMirror> get constructors => _mixin.constructors;

  InstanceMirror newInstance(
      Symbol constructorName,
      List positionalArguments,
      [Map<Symbol,dynamic> namedArguments]) {
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
}

abstract class JsObjectMirror implements ObjectMirror {
}

class JsInstanceMirror extends JsObjectMirror implements InstanceMirror {
  final reflectee;

  JsInstanceMirror(this.reflectee);

  bool get hasReflectee => true;

  ClassMirror get type => reflectType(reflectee.runtimeType);

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    String name = n(memberName);
    String reflectiveName;
    if (namedArguments != null && !namedArguments.isEmpty) {
      var methodsWithOptionalArguments =
          JS('=Object', '#.\$methodsWithOptionalArguments', reflectee);
      String mangledName =
          JS('String|Null', '#[#]', methodsWithOptionalArguments, '*$name');
      if (mangledName == null) {
        // TODO(ahe): Invoke noSuchMethod.
        throw new UnimplementedNoSuchMethodError(
            'Invoking noSuchMethod with named arguments not implemented');
      }
      var defaultValueIndices =
          JS('List|Null', '#[#].\$defaultValues', reflectee, mangledName);
      var defaultValues =
          defaultValueIndices.map((int i) => getMetadata(i))
          .iterator;
      var defaultArguments = new Map();
      reflectiveName = mangledNames[mangledName];
      var reflectiveNames = reflectiveName.split(':');
      int requiredPositionalArgumentCount =
          int.parse(reflectiveNames.elementAt(1));
      positionalArguments = new List.from(positionalArguments);
      // Check the number of positional arguments is valid.
      if (requiredPositionalArgumentCount != positionalArguments.length) {
        // TODO(ahe): Invoke noSuchMethod.
        throw new UnimplementedNoSuchMethodError(
            'Invoking noSuchMethod with named arguments not implemented');
      }
      for (String parameter in reflectiveNames.skip(3)) {
        defaultValues.moveNext();
        defaultArguments[parameter] = defaultValues.current;
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
    } else {
      reflectiveName =
          JS('String', '# + ":" + # + ":0"', name, positionalArguments.length);
    }
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
      List<String> argumentNames = const [];
      if (type == JSInvocationMirror.METHOD) {
        // Note: [argumentNames] are not what the user actually provided, it is
        // always all the named paramters.
        argumentNames = reflectiveName.split(':').skip(3).toList();
      }

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

  operator ==(other) {
    return other is JsInstanceMirror &&
           identical(reflectee, other.reflectee);
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
class JsTypeBoundClassMirror extends JsDeclarationMirror implements ClassMirror {
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

  JsTypeBoundClassMirror(JsClassMirror originalDeclaration, this._typeArguments)
      : _class = originalDeclaration,
        super(originalDeclaration.simpleName);

  String get _prettyName => 'ClassMirror';
  String get _mangledName => '${_class._mangledName}<$_typeArguments>';

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
            new JsTypeVariableMirror(typeVariable, owner);
        result.add(typeMirror);
      }
    }

    if (_typeArguments.indexOf('<') == -1) {
      _typeArguments.split(',').forEach((t) => addTypeArgument(t));
    } else {
      int level = 0;
      String currentTypeArgument = '';

      for (int i = 0; i < _typeArguments.length; i++) {
        var character = _typeArguments[i];
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
            addTypeArgument(currentTypeArgument);
            currentTypeArgument = '';
          }
        } else {
          currentTypeArgument += character;
        }
      }
      addTypeArgument(currentTypeArgument);
    }
    return _cachedTypeArguments = new UnmodifiableListView(result);
  }

  List<JsMethodMirror> get _methods {
    if (_cachedMethods != null) return _cachedMethods;
    return _cachedMethods =_class._getMethodsWithOwner(this);
  }

  Map<Symbol, MethodMirror> get methods {
    if (_cachedMethodsMap != null) return _cachedMethodsMap;
    return _cachedMethodsMap = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterMethods(_methods));
  }

  Map<Symbol, MethodMirror> get constructors {
    if (_cachedConstructors != null) return _cachedConstructors;
    return _cachedConstructors =
        new UnmodifiableMapView<Symbol, MethodMirror>(
            filterConstructors(_methods));
  }

  Map<Symbol, MethodMirror> get getters {
    if (_cachedGetters != null) return _cachedGetters;
    return _cachedGetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterGetters(_methods, variables));
  }

  Map<Symbol, MethodMirror> get setters {
    if (_cachedSetters != null) return _cachedSetters;
    return _cachedSetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterSetters(_methods, variables));
  }

  Map<Symbol, VariableMirror> get variables {
    if (_cachedVariables != null) return _cachedVariables;
    var result = new Map();
    for (JsVariableMirror mirror in  _class._getFieldsWithOwner(this)) {
      result[mirror.simpleName] = mirror;
    }
    return _cachedVariables =
        new UnmodifiableMapView<Symbol, VariableMirror>(result);
  }

  Map<Symbol, DeclarationMirror> get members {
    if (_cachedMembers != null) return _cachedMembers;
    return _cachedMembers = new UnmodifiableMapView<Symbol, DeclarationMirror>(
        filterMembers(_methods, variables));
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    Map<Symbol, DeclarationMirror> result =
        new Map<Symbol, DeclarationMirror>();
    result.addAll(members);
    result.addAll(constructors);
    typeVariables.forEach((tv) => result[tv.simpleName] = tv);
    return _cachedDeclarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(result);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    return _class.setField(fieldName, arg);
  }

  InstanceMirror getField(Symbol fieldName) => _class.getField(fieldName);

  InstanceMirror newInstance(Symbol constructorName,
                             List positionalArguments,
                             [Map<Symbol, dynamic> namedArguments]) {
    return _class.newInstance(constructorName,
                              positionalArguments,
                              namedArguments);
  }

  JsLibraryMirror get owner => _class.owner;

  List<InstanceMirror> get metadata => _class.metadata;

  ClassMirror get superclass {
    if (_superclass != null) return _superclass;

    List<int> typeInformation =
        JS('List|Null', 'init.typeInformation[#]', _class._mangledName);
    assert(typeInformation != null);
    var type = getMetadata(typeInformation[0]);
    return _superclass = typeMirrorFromRuntimeTypeRepresentation(this, type);
  }

  InstanceMirror invoke(Symbol memberName,
                        List positionalArguments,
                        [Map<Symbol,dynamic> namedArguments]) {
    return _class.invoke(memberName, positionalArguments, namedArguments);
  }

  bool get isOriginalDeclaration => false;

  ClassMirror get originalDeclaration => _class;

  List<ClassMirror> get superinterfaces {
    if (_cachedSuperinterfaces != null) return _cachedSuperinterfaces;
    return _cachedSuperinterfaces = _class._getSuperinterfacesWithOwner(this);
  }

  bool get hasReflectedType => _class.hasReflectedType;

  bool get isPrivate => _class.isPrivate;

  bool get isTopLevel => _class.isTopLevel;

  SourceLocation get location => _class.location;

  MirrorSystem get mirrors => _class.mirrors;

  Symbol get qualifiedName => _class.qualifiedName;

  Type get reflectedType => _class.reflectedType;

  Symbol get simpleName => _class.simpleName;
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
  UnmodifiableMapView<Symbol, DeclarationMirror> _cachedDeclarations;
  UnmodifiableListView<InstanceMirror> _cachedMetadata;
  UnmodifiableListView<ClassMirror> _cachedSuperinterfaces;
  UnmodifiableListView<TypeVariableMirror> _cachedTypeVariables;

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
    return _cachedConstructors =
        new UnmodifiableMapView<Symbol, MethodMirror>(
            filterConstructors(_methods));
  }

  List<JsMethodMirror> _getMethodsWithOwner(DeclarationMirror methodOwner) {
    var prototype = JS('', '#.prototype', _jsConstructor);
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
      var mirror =
          new JsMethodMirror.fromUnmangledName(
              simpleName, function, false, false);
      result.add(mirror);
      mirror._owner = methodOwner;
    }

    keys = extractKeys(JS('', 'init.statics[#]', _mangledName));
    int length = keys.length;
    for (int i = 0; i < length; i++) {
      String mangledName = keys[i];
      if (isReflectiveDataInPrototype(mangledName)) continue;
      String unmangledName = mangledName;
      var jsFunction = JS('', '#[#]', owner._globalObject, mangledName);

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
      instanceFieldSpecfication =
          [instanceFieldSpecfication]..addAll(_fieldsMetadata);
    }
    parseCompactFieldSpecification(
        fieldOwner, instanceFieldSpecfication, false, result);

    var staticDescriptor = JS('', 'init.statics[#]', _mangledName);
    if (staticDescriptor != null) {
      parseCompactFieldSpecification(
          fieldOwner, JS('', '#[""]', staticDescriptor), true, result);
    }
    return result;
  }

  List<VariableMirror> get _fields {
    if (_cachedFields != null) return _cachedFields;
    return _cachedFields = _getFieldsWithOwner(this);
  }

  Map<Symbol, MethodMirror> get methods {
    if (_cachedMethodsMap != null) return _cachedMethodsMap;
    return _cachedMethodsMap =
        new UnmodifiableMapView<Symbol, MethodMirror>(filterMethods(_methods));
  }

  Map<Symbol, MethodMirror> get getters {
    if (_cachedGetters != null) return _cachedGetters;
    return _cachedGetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterGetters(_methods, variables));
  }

  Map<Symbol, MethodMirror> get setters {
    if (_cachedSetters != null) return _cachedSetters;
    return _cachedSetters = new UnmodifiableMapView<Symbol, MethodMirror>(
        filterSetters(_methods, variables));
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
    return _cachedMembers = new UnmodifiableMapView<Symbol, Mirror>(
        filterMembers(_methods, variables));
  }

  Map<Symbol, DeclarationMirror> get declarations {
    if (_cachedDeclarations != null) return _cachedDeclarations;
    var result = new Map<Symbol, DeclarationMirror>();
    addToResult(Symbol key, Mirror value) {
      result[key] = value;
    }
    members.forEach(addToResult);
    constructors.forEach(addToResult);
    typeVariables.forEach((tv) => result[tv.simpleName] = tv);
    return _cachedDeclarations =
        new UnmodifiableMapView<Symbol, DeclarationMirror>(result);
  }

  InstanceMirror setField(Symbol fieldName, Object arg) {
    JsVariableMirror mirror = variables[fieldName];
    if (mirror != null && mirror.isStatic && !mirror.isFinal) {
      // '$' (JS_CURRENT_ISOLATE()) stores state which is stored directly, so
      // we shouldn't use [JsLibraryMirror._globalObject] here.
      String jsName = mirror._jsName;
      if (!JS('bool', '# in #', jsName, JS_CURRENT_ISOLATE())) {
        throw new RuntimeError('Cannot find "$jsName" in current isolate.');
      }
      JS('void', '#[#] = #', JS_CURRENT_ISOLATE(), jsName, arg);
      return reflect(arg);
    }
    // TODO(ahe): What receiver to use?
    throw new NoSuchMethodError(this, setterSymbol(fieldName), [arg], null);
  }

  InstanceMirror getField(Symbol fieldName) {
    JsVariableMirror mirror = variables[fieldName];
    if (mirror != null && mirror.isStatic) {
      String jsName = mirror._jsName;
      // '$' (JS_CURRENT_ISOLATE()) stores state which is read directly, so
      // we shouldn't use [JsLibraryMirror._globalObject] here.
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
    throw new NoSuchMethodError(this, fieldName, null, null);
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
            // TODO(ahe): What receiver to use?
            throw new NoSuchMethodError(
                this, constructorName, positionalArguments, namedArguments);
          });
      JsCache.update(_jsConstructorCache, n(constructorName), mirror);
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  JsLibraryMirror get owner {
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
      List<int> typeInformation =
          JS('List|Null', 'init.typeInformation[#]', _mangledName);
      if (typeInformation != null) {
        var type = getMetadata(typeInformation[0]);
        _superclass = typeMirrorFromRuntimeTypeRepresentation(this, type);
      } else {
        var superclassName = _fieldsDescriptor.split(';')[0];
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
              ? this : reflectClassByMangledName(superclassName);
          }
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
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          this, memberName, positionalArguments, namedArguments);
    }
    if (!mirror.canInvokeReflectively()) {
      throwInvalidReflectionError(n(memberName));
    }
    return reflect(mirror._invoke(positionalArguments, namedArguments));
  }

  bool get isOriginalDeclaration => true;

  ClassMirror get originalDeclaration => this;

  List<ClassMirror> _getSuperinterfacesWithOwner(DeclarationMirror owner) {
    List<int> typeInformation =
        JS('List|Null', 'init.typeInformation[#]', _mangledName);
    List<ClassMirror> result = const <ClassMirror>[];
    if (typeInformation != null) {
      ClassMirror lookupType(int i) {
        var type = getMetadata(i);
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
      result.add(new JsTypeVariableMirror(typeVariable, this));
    }
    return _cachedTypeVariables = new UnmodifiableListView(result);
  }

  List<TypeMirror> get typeArguments => const <TypeMirror>[];
}

class JsVariableMirror extends JsDeclarationMirror implements VariableMirror {
  static final int REFLECTION_MARKER = 45;

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
    if (code == REFLECTION_MARKER) {
      // If the field descriptor has a reflection marker, remove it by
      // changing length and getting the real getter/setter code.  The
      // descriptor will be truncated below.
      length--;
      code = fieldCode(descriptor.codeUnitAt(length - 1));
    } else {
      // The field is not available for reflection.
      return null;
    }
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
      jsName = descriptor.substring(divider + 1);
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
    if (code == REFLECTION_MARKER) return code;
    if (code >= 60 && code <= 64) return code - 59;
    if (code >= 123 && code <= 126) return code - 117;
    if (code >= 37 && code <= 43) return code - 27;
    return 0;
  }

  _getField(JsMirror receiver) => receiver._loadField(_jsName);

  void _setField(JsMirror receiver, Object arg) {
    if (isFinal) {
      throw new NoSuchMethodError(this, setterSymbol(simpleName), [arg], null);
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
    if (reflectee is BoundClosure) {
      var target = BoundClosure.targetOf(reflectee);
      var self = BoundClosure.selfOf(reflectee);
      var name = mangledNames[BoundClosure.nameOf(reflectee)];
      if (name == null) {
        throwInvalidReflectionError(name);
      }
      cachedFunction = new JsMethodMirror.fromUnmangledName(
          name, target, false, false);
    } else {
      bool isStatic = true; // TODO(ahe): Compute isStatic correctly.
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

  String toString() => "ClosureMirror on '${Error.safeToString(reflectee)}'";

  // TODO(ahe): Implement these.
  String get source => throw new UnimplementedError();
  InstanceMirror findInContext(Symbol name) {
    throw new UnsupportedError("ClosureMirror.findInContext not yet supported");
  }
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

  bool canInvokeReflectively() {
    return hasReflectableProperty(_jsFunction);
  }

  DeclarationMirror get owner => _owner;

  TypeMirror get returnType {
    metadata; // Compute _returnType as a side-effect of extracting metadata.
    return typeMirrorFromRuntimeTypeRepresentation(owner, _returnType);
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
      // TODO(ahe): What receiver to use?
      throw new NoSuchMethodError(
          owner, simpleName, positionalArguments, namedArguments);
    }
    // Using JS_CURRENT_ISOLATE() ('$') here is actually correct, although
    // _jsFunction may not be a property of '$', most static functions do not
    // care who their receiver is. But to lazy getters, it is important that
    // 'this' is '$'.
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
      throw new NoSuchMethodError(this, setterSymbol(simpleName), [], null);
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
  final DeclarationMirror owner;
  // A JS object representing the type.
  final _type;

  JsParameterMirror(String unmangledName, this.owner, this._type)
      : super(s(unmangledName));

  String get _prettyName => 'ParameterMirror';

  TypeMirror get type {
    return typeMirrorFromRuntimeTypeRepresentation(owner, _type);
  }

  // Only true for static fields, never for a parameter.
  bool get isStatic => false;

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

class JsTypedefMirror extends JsDeclarationMirror implements TypedefMirror {
  final String _mangledName;
  JsFunctionTypeMirror referent;

  JsTypedefMirror(Symbol simpleName,  this._mangledName, _typeData)
      : super(simpleName) {
    referent = new JsFunctionTypeMirror(_typeData, this);
  }

  JsFunctionTypeMirror get value => referent;

  String get _prettyName => 'TypedefMirror';
}

class JsFunctionTypeMirror implements FunctionTypeMirror {
  final _typeData;
  String _cachedToString;
  TypeMirror _cachedReturnType;
  UnmodifiableListView<ParameterMirror> _cachedParameters;
  DeclarationMirror owner;

  JsFunctionTypeMirror(this._typeData, this.owner);

  bool get _hasReturnType => JS('bool', '"ret" in #', _typeData);
  get _returnType => JS('', '#.ret', _typeData);

  bool get _isVoid => JS('bool', '!!#.void', _typeData);

  bool get _hasArguments => JS('bool', '"args" in #', _typeData);
  List get _arguments => JS('JSExtendableArray', '#.args', _typeData);

  bool get _hasOptionalArguments => JS('bool', '"opt" in #', _typeData);
  List get _optionalArguments => JS('JSExtendableArray', '#.opt', _typeData);

  bool get _hasNamedArguments => JS('bool', '"named" in #', _typeData);
  get _namedArguments => JS('=Object', '#.named', _typeData);
  bool get isOriginalDeclaration => true;

  TypeMirror get returnType {
    if (_cachedReturnType != null) return _cachedReturnType;
    if (_isVoid) return _cachedReturnType = JsMirrorSystem._voidType;
    if (!_hasReturnType) return _cachedReturnType = JsMirrorSystem._dynamicType;
    return _cachedReturnType =
          typeMirrorFromRuntimeTypeRepresentation(this, _returnType);
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
    return _cachedParameters = new UnmodifiableListView<ParameterMirror>(
        result);
  }

  String toString() {
    if (_cachedToString != null) return _cachedToString;
    var s = "FunctionTypeMirror on '(";
    var sep = '';
    if (_hasArguments) {
      for (var argument in _arguments) {
        s += sep;
        s += runtimeTypeToString(argument);
        sep = ', ';
      }
    }
    if (_hasOptionalArguments) {
      s += '$sep[';
      sep = '';
      for (var argument in _optionalArguments) {
        s += sep;
        s += runtimeTypeToString(argument);
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
        s += runtimeTypeToString(JS('', '#[#]', _namedArguments, name));
        sep = ', ';
      }
      s += '}';
    }
    s += ') -> ';
    if (_isVoid) {
      s += 'void';
    } else if (_hasReturnType) {
      s += runtimeTypeToString(_returnType);
    } else {
      s += 'dynamic';
    }
    return _cachedToString = "$s'";
  }
}

int findTypeVariableIndex(List<TypeVariableMirror> typeVariables, String name) {
  for (int i = 0; i < typeVariables.length; i++) {
    if (typeVariables[i].simpleName == s(name)) {
      return i;
    }
  }
  throw new ArgumentError('Type variable not present in list.');
}

getMetadata(int index) => JS('', 'init.metadata[#]', index);

TypeMirror typeMirrorFromRuntimeTypeRepresentation(
    DeclarationMirror owner,
    var /*int|List|JsFunction*/ type) {
  ClassMirror ownerClass;
  DeclarationMirror context = owner;
    while(context != null) {
    if (context is ClassMirror) {
      ownerClass = context;
      break;
    }
    context = context.owner;
  }

  String representation;
  if (type == null){
    return JsMirrorSystem._dynamicType;
  } else if (ownerClass == null) {
    representation = runtimeTypeToString(type);
  } else if (ownerClass.isOriginalDeclaration) {
    if (type is int) {
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
    String substituteTypeVariable(int index) {
      TypeVariable typeVariable = getMetadata(index);
      int variableIndex =
          findTypeVariableIndex(ownerClass.typeVariables, typeVariable.name);
      var typeArgument = ownerClass.typeArguments[variableIndex];
      assert(typeArgument is JsClassMirror ||
             typeArgument is JsTypeBoundClassMirror);
      return typeArgument._mangledName;
    }
    representation =
        runtimeTypeToString(type, onTypeVariable: substituteTypeVariable);
  }
  if (representation != null) {
    return reflectType(createRuntimeType(representation));
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
  var metadataFunction = JS('', '#["@"]', victim);
  if (metadataFunction != null) return JS('', '#()', metadataFunction);
  if (JS('String', 'typeof #', victim) != 'function') return const [];
  String source = JS('String', 'Function.prototype.toString.call(#)', victim);
  int index = source.lastIndexOf(new RegExp('"[0-9,]*";?[ \n\r]*}'));
  if (index == -1) return const [];
  index++;
  int endQuote = source.indexOf('"', index);
  return source.substring(index, endQuote).split(',').map(int.parse).map(
      (int i) => getMetadata(i)).toList();
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

/// Returns true if the key represent ancillary reflection data, that is, not a
/// method.
bool isReflectiveDataInPrototype(String key) {
  if (key == '' || key == METHODS_WITH_OPTIONAL_ARGUMENTS) return true;
  String firstChar = key[0];
  return firstChar == '*' || firstChar == '+';
}

// Copied from package "unmodifiable_collection".
// TODO(14314): Move to dart:collection.
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

// TODO(ahe): Remove this class and call noSuchMethod instead.
class UnimplementedNoSuchMethodError extends Error
    implements NoSuchMethodError {
  final String _message;

  UnimplementedNoSuchMethodError(this._message);

  String toString() => "Unsupported operation: $_message";
}
