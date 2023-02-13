// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the operations that define and manipulate Dart
/// classes.  Included in this are:
///   - Generics
///   - Class metadata
///   - Extension methods
///

// TODO(leafp): Consider splitting some of this out.
part of dart._runtime;

/// Returns a new type that mixes members from base and the mixin.
void applyMixin(to, from) {
  JS('', '#[#] = #', to, _mixin, from);
  var toProto = JS('', '#.prototype', to);
  var fromProto = JS('', '#.prototype', from);
  _copyMembers(toProto, fromProto);
  _mixinSignature(to, from, _methodSig);
  _mixinSignature(to, from, _fieldSig);
  _mixinSignature(to, from, _getterSig);
  _mixinSignature(to, from, _setterSig);
  var mixinOnFn = JS('', '#[#]', from, mixinOn);
  if (mixinOnFn != null) {
    var proto = JS('', '#(#.__proto__).prototype', mixinOnFn, to);
    _copyMembers(toProto, proto);
  }
}

void _copyMembers(to, from) {
  var names = getOwnNamesAndSymbols(from);
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    String name = JS('', '#[#]', names, i);
    if (name == 'constructor') continue;
    _copyMember(to, from, name);
  }
  return to;
}

void _copyMember(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('!', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('!', '#.writable', existing)) {
        JS('', '#[#] = #.value', to, name, desc);
      }
      return;
    }
  }
  var getter = JS('', '#.get', desc);
  var setter = JS('', '#.set', desc);
  if (getter != null) {
    if (setter == null) {
      var obj = JS<Object>(
          '!',
          '#.set = { __proto__: #.__proto__, '
              'set [#](x) { return super[#] = x; } }',
          desc,
          to,
          name,
          name);
      JS<Object>(
          '!', '#.set = #.set', desc, getOwnPropertyDescriptor(obj, name));
    }
  } else if (setter != null) {
    if (getter == null) {
      var obj = JS<Object>(
          '!',
          '#.get = { __proto__: #.__proto__, '
              'get [#]() { return super[#]; } }',
          desc,
          to,
          name,
          name);
      JS<Object>(
          '!', '#.get = #.get', desc, getOwnPropertyDescriptor(obj, name));
    }
  }
  defineProperty(to, name, desc);
}

void _mixinSignature(to, from, kind) {
  JS('', '#[#] = #', to, kind, () {
    var baseMembers = _getMembers(JS('', '#.__proto__', to), kind);
    var fromMembers = _getMembers(from, kind);
    if (fromMembers == null) return baseMembers;
    var toSignature = JS('', '{ __proto__: # }', baseMembers);
    copyProperties(toSignature, fromMembers);
    return toSignature;
  });
}

final _mixin = JS('', 'Symbol("mixin")');

getMixin(clazz) => JS('', 'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz, _mixin, clazz, _mixin);

final mixinOn = JS('', 'Symbol("mixinOn")');

@JSExportName('implements')
final implements_ = JS('', 'Symbol("implements")');

/// Returns `null` if [clazz] doesn't directly implement any interfaces or a
/// a `Function` that when called produces a `List` of the type objects
/// [clazz] implements.
///
/// Note, indirectly (e.g., via superclass) implemented interfaces aren't
/// included here. See compiler.dart for when/how it is emitted.
List<Object> Function()? getImplements(clazz) => JS(
    '',
    'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz,
    implements_,
    clazz,
    implements_);

/// The Symbol for storing type arguments on a specialized generic type.
final _typeArguments = JS('', 'Symbol("typeArguments")');

final _variances = JS('', 'Symbol("variances")');

final _originalDeclaration = JS('', 'Symbol("originalDeclaration")');

final mixinNew = JS('', 'Symbol("dart.mixinNew")');

/// Normalizes `FutureOr` types when they are constructed at runtime.
///
/// This normalization should mirror the normalization performed at compile time
/// in the method named `_normalizeFutureOr()`.
///
/// **NOTE** Normalization of FutureOr<T?>? --> FutureOr<T?> is handled in
/// [nullable].
normalizeFutureOr(typeConstructor, setBaseClass) {
  // The canonical version of the generic FutureOr type constructor.
  var genericFutureOrType =
      JS('!', '#', generic(typeConstructor, setBaseClass));

  normalize(typeArg) {
    // Normalize raw FutureOr --> dynamic
    if (JS<bool>('!', '# == void 0', typeArg)) return _dynamic;

    // FutureOr<dynamic|void|Object?|Object*|Object> -->
    //   dynamic|void|Object?|Object*|Object
    if (_isTop(typeArg) ||
        _equalType(typeArg, Object) ||
        (_jsInstanceOf(typeArg, LegacyType) &&
            JS<bool>('!', '#.type === #', typeArg, Object))) {
      return typeArg;
    }

    // FutureOr<Never> --> Future<Never>
    if (_equalType(typeArg, Never)) {
      return JS('!', '#(#)', getGenericClassStatic<Future>(), typeArg);
    }
    // FutureOr<Null> --> Future<Null>?
    if (_equalType(typeArg, Null)) {
      return nullable(
          JS('!', '#(#)', getGenericClassStatic<Future>(), typeArg));
    }
    // Otherwise, create the FutureOr<T> type as a normal generic type.
    var genericType = JS('!', '#(#)', genericFutureOrType, typeArg);
    // Overwrite the original declaration so that it correctly points back to
    // this method. This ensures that the we can test a type value returned here
    // as a FutureOr because it is equal to 'async.FutureOr` (in the JS).
    JS('!', '#[#] = #', genericType, _originalDeclaration, normalize);
    // Add FutureOr specific is and as methods.
    is_FutureOr(obj) =>
        JS<bool>('!', '#.is(#)', typeArg, obj) ||
        JS<bool>(
            '!', '#(#).is(#)', getGenericClassStatic<Future>(), typeArg, obj);
    JS('!', '#.is = #', genericType, is_FutureOr);

    as_FutureOr(obj) {
      // Special test to handle case for mixed mode non-nullable FutureOr of a
      // legacy type. This allows casts like `null as FutureOr<int*>` to work
      // in weak and sound mode.
      if (obj == null && _jsInstanceOf(typeArg, LegacyType)) {
        return obj;
      }

      if (JS<bool>('!', '#.is(#)', typeArg, obj) ||
          JS<bool>('!', '#(#).is(#)', getGenericClassStatic<Future>(), typeArg,
              obj)) {
        return obj;
      }
      return cast(
          obj, JS('!', '#(#)', getGenericClassStatic<FutureOr>(), typeArg));
    }

    JS('!', '#.as = #', genericType, as_FutureOr);

    return genericType;
  }

  return normalize;
}

/// Memoize a generic type constructor function.
generic(typeConstructor, setBaseClass) => JS('', '''(() => {
  let length = $typeConstructor.length;
  if (length < 1) {
    $throwInternalError('must have at least one generic type argument');
  }
  let resultMap = new Map();
  // TODO(vsm): Rethink how to clear the resultMap on hot restart.
  // A simple clear via:
  //   _cacheMaps.push(resultMap);
  // will break (a) we hoist type expressions in generated code and
  // (b) we don't clear those type expressions in the presence of a
  // hot restart.  Not clearing this map (as we're doing now) should
  // not affect correctness, but can result in a memory leak across
  // multiple restarts.
  function makeGenericType(...args) {
    if (args.length != length && args.length != 0) {
      $throwInternalError('requires ' + length + ' or 0 type arguments');
    }
    while (args.length < length) args.push(${typeRep<dynamic>()});

    let value = resultMap;
    for (let i = 0; i < length; i++) {
      let arg = args[i];
      if (arg == null) {
        $throwInternalError('type arguments should not be null: '
                          + $typeConstructor);
      }
      let map = value;
      value = map.get(arg);
      if (value === void 0) {
        if (i + 1 == length) {
          value = $typeConstructor.apply(null, args);
          // Save the type constructor and arguments for reflection.
          if (value) {
            value[$_typeArguments] = args;
            value[$_originalDeclaration] = makeGenericType;
          }
          map.set(arg, value);
          if ($setBaseClass != null) $setBaseClass.apply(null, args);
        } else {
          value = new Map();
          map.set(arg, value);
        }
      }
    }
    return value;
  }
  makeGenericType[$_genericTypeCtor] = $typeConstructor;
  return makeGenericType;
})()''');

getGenericClass(type) => safeGetOwnProperty(type, _originalDeclaration);

/// Extracts the type argument as the accessor for the JS class.
///
/// Should be used in place of [getGenericClass] when we know the class we want
/// statically.
///
/// This value is extracted and inlined by the compiler without any runtime
/// operations. The implementation here is only provided as a theoretical fall
/// back and shouldn't actually be run.
///
/// For example `getGenericClassStatic<FutureOr>` emits `async.FutureOr$`
/// directly.
external getGenericClassStatic<T>();

// TODO(markzipan): Make this non-nullable if we can ensure this returns
// an empty list or if null and the empty list are semantically the same.
List? getGenericArgs(type) =>
    JS<List?>('', '#', safeGetOwnProperty(type, _typeArguments));

List? getGenericArgVariances(type) =>
    JS<List?>('', '#', safeGetOwnProperty(type, _variances));

void setGenericArgVariances(f, variances) =>
    JS('', '#[#] = #', f, _variances, variances);

List<TypeVariable> getGenericTypeFormals(genericClass) {
  return _typeFormalsFromFunction(getGenericTypeCtor(genericClass));
}

Object instantiateClass(Object genericClass, List<Object> typeArgs) {
  return JS('', '#.apply(null, #)', genericClass, typeArgs);
}

final _constructorSig = JS('', 'Symbol("sigCtor")');
final _methodSig = JS('', 'Symbol("sigMethod")');
final _fieldSig = JS('', 'Symbol("sigField")');
final _getterSig = JS('', 'Symbol("sigGetter")');
final _setterSig = JS('', 'Symbol("sigSetter")');
final _staticMethodSig = JS('', 'Symbol("sigStaticMethod")');
final _staticFieldSig = JS('', 'Symbol("sigStaticField")');
final _staticGetterSig = JS('', 'Symbol("sigStaticGetter")');
final _staticSetterSig = JS('', 'Symbol("sigStaticSetter")');
final _genericTypeCtor = JS('', 'Symbol("genericType")');
final _libraryUri = JS('', 'Symbol("libraryUri")');

getConstructors(value) => _getMembers(value, _constructorSig);
getMethods(value) => _getMembers(value, _methodSig);
getFields(value) => _getMembers(value, _fieldSig);
getGetters(value) => _getMembers(value, _getterSig);
getSetters(value) => _getMembers(value, _setterSig);
getStaticMethods(value) => _getMembers(value, _staticMethodSig);
getStaticFields(value) => _getMembers(value, _staticFieldSig);
getStaticGetters(value) => _getMembers(value, _staticGetterSig);
getStaticSetters(value) => _getMembers(value, _staticSetterSig);

getGenericTypeCtor(value) => JS('', '#[#]', value, _genericTypeCtor);

/// Get the type of an object.
getType(obj) {
  if (obj == null) return JS('!', '#', Object);

  // Object.create(null) produces a js object without a prototype.
  // In that case use the native Object constructor.
  var constructor = JS('!', '#.constructor', obj);
  return JS('!', '# ? # : #.Object.prototype.constructor', constructor,
      constructor, global_);
}

getLibraryUri(value) => JS('', '#[#]', value, _libraryUri);
setLibraryUri(f, uri) => JS('', '#[#] = #', f, _libraryUri, uri);

bool isJsInterop(obj) {
  if (obj == null) return false;
  if (JS('!', 'typeof # === "function"', obj)) {
    // A function is a Dart function if it has runtime type information.
    return JS('!', '#[#] == null', obj, _runtimeType);
  }
  // Primitive types are not JS interop types.
  if (JS('!', 'typeof # !== "object"', obj)) return false;

  // Extension types are not considered JS interop types.
  // Note that it is still possible to call typed JS interop methods on
  // extension types but the calls must be statically typed.
  if (JS('!', '#[#] != null', obj, _extensionType)) return false;

  // Exclude record types.
  if (_jsInstanceOf(obj, _RecordImpl)) return false;
  return !_jsInstanceOf(obj, Object);
}

/// Get the type of a method from a type using the stored signature
getMethodType(type, name) {
  var m = getMethods(type);
  return m != null ? JS('', '#[#]', m, name) : null;
}

/// Gets the type of the corresponding setter (this includes writable fields).
getSetterType(type, name) {
  var setters = getSetters(type);
  if (setters != null) {
    var type = JS('', '#[#]', setters, name);
    if (type != null) {
      return type;
    }
  }
  var fields = getFields(type);
  if (fields != null) {
    var fieldInfo = JS('', '#[#]', fields, name);
    if (fieldInfo != null && JS<bool>('!', '!#.isFinal', fieldInfo)) {
      return JS('', '#.type', fieldInfo);
    }
  }
  return null;
}

finalFieldType(type, metadata) =>
    JS('', '{ type: #, isFinal: true, metadata: # }', type, metadata);

fieldType(type, metadata) =>
    JS('', '{ type: #, isFinal: false, metadata: # }', type, metadata);

/// Get the type of a constructor from a class using the stored signature
/// If name is undefined, returns the type of the default constructor
/// Returns undefined if the constructor is not found.
classGetConstructorType(cls, name) {
  if (cls == null) return null;
  if (name == null) name = 'new';
  var ctors = getConstructors(cls);
  return ctors != null ? JS('', '#[#]', ctors, name) : null;
}

void setMethodSignature(f, sigF) => JS('', '#[#] = #', f, _methodSig, sigF);
void setFieldSignature(f, sigF) => JS('', '#[#] = #', f, _fieldSig, sigF);
void setGetterSignature(f, sigF) => JS('', '#[#] = #', f, _getterSig, sigF);
void setSetterSignature(f, sigF) => JS('', '#[#] = #', f, _setterSig, sigF);

// Set up the constructor signature field on the constructor
void setConstructorSignature(f, sigF) =>
    JS('', '#[#] = #', f, _constructorSig, sigF);

// Set up the static signature field on the constructor
void setStaticMethodSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticMethodSig, sigF);

void setStaticFieldSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticFieldSig, sigF);

void setStaticGetterSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticGetterSig, sigF);

void setStaticSetterSignature(f, sigF) =>
    JS('', '#[#] = #', f, _staticSetterSig, sigF);

_getMembers(type, kind) {
  var sig = JS('', '#[#]', type, kind);
  return JS<bool>('!', 'typeof # == "function"', sig)
      ? JS('', '#[#] = #()', type, kind, sig)
      : sig;
}

bool _hasMember(type, kind, name) {
  var sig = _getMembers(type, kind);
  return sig != null && JS<bool>('!', '# in #', name, sig);
}

bool hasMethod(type, name) => _hasMember(type, _methodSig, name);
bool hasGetter(type, name) => _hasMember(type, _getterSig, name);
bool hasSetter(type, name) => _hasMember(type, _setterSig, name);
bool hasField(type, name) => _hasMember(type, _fieldSig, name);

final _extensionType = JS('', 'Symbol("extensionType")');

final dartx = JS('', 'dartx');

/// Install properties in prototype-first order.  Properties / descriptors from
/// more specific types should overwrite ones from less specific types.
void _installProperties(jsProto, dartType, installedParent) {
  if (JS('!', '# === #', dartType, JS_CLASS_REF(Object))) {
    _installPropertiesForObject(jsProto);
    return;
  }
  // If the extension methods of the parent have been installed on the parent
  // of [jsProto], the methods will be available via prototype inheritance.
  var dartSupertype = JS<Object>('!', '#.__proto__', dartType);
  if (JS('!', '# !== #', dartSupertype, installedParent)) {
    _installProperties(jsProto, dartSupertype, installedParent);
  }

  var dartProto = JS<Object>('!', '#.prototype', dartType);
  copyTheseProperties(jsProto, dartProto, getOwnPropertySymbols(dartProto));
}

void _installPropertiesForObject(jsProto) {
  // core.Object members need to be copied from the non-symbol name to the
  // symbol name.
  var coreObjProto = JS<Object>('!', '#.prototype', JS_CLASS_REF(Object));
  var names = getOwnPropertyNames(coreObjProto);
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    var name = JS<String>('!', '#[#]', names, i);
    if (name == 'constructor') continue;
    var desc = getOwnPropertyDescriptor(coreObjProto, name);
    defineProperty(jsProto, JS('', '#.#', dartx, name), desc);
  }
}

void _installPropertiesForGlobalObject(jsProto) {
  _installPropertiesForObject(jsProto);
  // Use JS toString for JS objects, rather than the Dart one.
  JS('', '#[dartx.toString] = function() { return this.toString(); }', jsProto);
  identityEquals ??= JS('', '#[dartx._equals]', jsProto);
}

final _extensionMap = JS('', 'new Map()');

void _applyExtension(jsType, dartExtType) {
  // TODO(vsm): Not all registered js types are real.
  if (jsType == null) return;
  var jsProto = JS('', '#.prototype', jsType);
  if (jsProto == null) return;

  if (JS('!', '# === #', dartExtType, JS_CLASS_REF(Object))) {
    _installPropertiesForGlobalObject(jsProto);
    return;
  }

  if (JS('!', '# === #.Object', jsType, global_)) {
    var extName = JS<String>('!', '#.name', dartExtType);
    _warn(
        "Attempting to install properties from non-Object type '$extName' onto the native JS Object.");
    return;
  }

  _installProperties(
      jsProto, dartExtType, JS('', '#[#]', jsProto, _extensionType));

  // Mark the JS type's instances so we can easily check for extensions.
  if (JS('!', '# !== #', dartExtType, JS_CLASS_REF(JSFunction))) {
    JS('', '#[#] = #', jsProto, _extensionType, dartExtType);
  }
  JS('', '#[#] = #[#]', jsType, _methodSig, dartExtType, _methodSig);
  JS('', '#[#] = #[#]', jsType, _fieldSig, dartExtType, _fieldSig);
  JS('', '#[#] = #[#]', jsType, _getterSig, dartExtType, _getterSig);
  JS('', '#[#] = #[#]', jsType, _setterSig, dartExtType, _setterSig);
}

/// Apply the previously registered extension to the type of [nativeObject].
/// This is intended for types that are not available to polyfill at startup.
applyExtension(name, nativeObject) {
  var dartExtType = JS('', '#.get(#)', _extensionMap, name);
  var jsType = JS('', '#.constructor', nativeObject);
  _applyExtension(jsType, dartExtType);
}

/// Apply all registered extensions to a window.  This is intended for
/// different frames, where registrations need to be reapplied.
applyAllExtensions(global) {
  JS('', '#.forEach((dartExtType, name) => #(#[name], dartExtType))',
      _extensionMap, _applyExtension, global);
}

/// Copy symbols from the prototype of the source to destination.
/// These are the only properties safe to copy onto an existing public
/// JavaScript class.
registerExtension(name, dartExtType) {
  JS('', '#.set(#, #)', _extensionMap, name, dartExtType);
  var jsType = JS('', '#[#]', global_, name);
  _applyExtension(jsType, dartExtType);
}

/// Apply a previously registered extension for testing purposes.
///
/// This method's only purpose is to aid in testing native classes. Most native
/// tests define JavaScript classes in user code (e.g. in an eval string). The
/// dartdevc compiler properly calls `registerExtension` when processing the
/// native class declarations in Dart, but at that point in time the JavaScript
/// counterpart is not defined.
///
/// This method is used to lookup those registrations and reapply the extension
/// after the JavaScript declarations are added.
///
/// An alternative to this would be to invest in a better test infrastructure
/// that would let us define the JavaScript code prior to loading the compiled
/// module.
applyExtensionForTesting(name) {
  var dartExtType = JS('', '#.get(#)', _extensionMap, name);
  var jsType = JS('', '#[#]', global_, name);
  _applyExtension(jsType, dartExtType);
}

///
/// Mark a concrete type as implementing extension methods.
/// For example: `class MyIter implements Iterable`.
///
/// This takes a list of names, which are the extension methods implemented.
/// It will add a forwarder, so the extension method name redirects to the
/// normal Dart method name. For example:
///
///     defineExtensionMembers(MyType, ['add', 'remove']);
///
/// Results in:
///
///     MyType.prototype[dartx.add] = MyType.prototype.add;
///     MyType.prototype[dartx.remove] = MyType.prototype.remove;
///
// TODO(jmesserly): essentially this gives two names to the same method.
// This benefit is roughly equivalent call performance either way, but the
// cost is we need to call defineExtensionMembers any time a subclass
// overrides one of these methods.
defineExtensionMethods(type, Iterable memberNames) {
  var proto = JS('', '#.prototype', type);
  for (var name in memberNames) {
    JS('', '#[dartx.#] = #[#]', proto, name, proto, name);
  }
}

/// Like [defineExtensionMethods], but for getter/setter pairs.
void defineExtensionAccessors(type, Iterable memberNames) {
  var proto = JS<Object>('!', '#.prototype', type);
  for (var name in memberNames) {
    // Find the member. It should always exist (or we have a compiler bug).
    var member;
    var p = proto;
    for (;; p = JS<Object>('!', '#.__proto__', p)) {
      member = getOwnPropertyDescriptor(p, name);
      if (member != null) break;
    }
    defineProperty(proto, JS('', 'dartx[#]', name), member);
  }
}

definePrimitiveHashCode(proto) {
  defineProperty(proto, identityHashCode_,
      getOwnPropertyDescriptor(proto, extensionSymbol('hashCode')));
}

/// Link the extension to the type it's extending as a base class.
setBaseClass(derived, base) {
  JS('', '#.prototype.__proto__ = #.prototype', derived, base);
  // We use __proto__ to track the superclass hierarchy (see isSubtypeOf).
  JS('', '#.__proto__ = #', derived, base);
}

/// Like [setBaseClass], but for generic extension types such as `JSArray<E>`.
setExtensionBaseClass(dartType, jsType) {
  // Mark the generic type as an extension type and link the prototype objects.
  var dartProto = JS('', '#.prototype', dartType);
  JS('', '#[#] = #', dartProto, _extensionType, dartType);
  JS('', '#.__proto__ = #.prototype', dartProto, jsType);
}

/// Adds type test predicates to a class/interface type [ctor], using the
/// provided [isClass] JS Symbol.
///
/// This will operate quickly for non-generic types, native extension types,
/// as well as matching exact generic type arguments:
///
///     class C<T> {}
///     class D extends C<int> {}
///     main() { dynamic d = new D(); d as C<int>; }
///
addTypeTests(ctor, isClass) {
  if (isClass == null) isClass = JS('', 'Symbol("_is_" + ctor.name)');
  // TODO(jmesserly): since we know we're dealing with class/interface types,
  // we can optimize this rather than go through the generic `dart.is` helpers.
  JS('', '#.prototype[#] = true', ctor, isClass);
  JS(
      '',
      '''#.is = function is_C(obj) {
    return obj != null && (obj[#] || #(obj, this));
  }''',
      ctor,
      isClass,
      instanceOf);
  JS(
      '',
      '''#.as = function as_C(obj) {
    if (obj != null && obj[#]) return obj;
    return #(obj, this);
  }''',
      ctor,
      isClass,
      cast);
}

/// A runtime mapping of interface type recipe to the symbol used to tag the
/// class for simple identification in the dart:rti library.
///
/// Maps String -> JavaScript Symbol.
final _typeTagSymbols = JS<Object>('!', 'new Map()');

Object typeTagSymbol(String recipe) {
  var tag = '${JS_GET_NAME(JsGetName.OPERATOR_IS_PREFIX)}${recipe}';
  var probe = JS<Object?>('', '#[#]', _typeTagSymbols, tag);
  if (probe != null) return probe;
  var tagSymbol = JS<Object>('!', 'Symbol(#)', tag);
  JS('', '#[#] = #', _typeTagSymbols, tag, tagSymbol);
  return tagSymbol;
}

/// Attaches the class type recipe and the type tags for all implemented
/// [interfaceRecipes] to [classRef].
///
/// The tags are used for simple identification of instances in the dart:rti
/// library.
///
/// The first element of [interfaceRecipes] must always be the type recipe for
/// the type represented by [classRef].
void addRtiResources(Object classRef, JSArray<String> interfaceRecipes) {
  // Attach the [classRef]'s own interface type recipe.
  // The recipe is used in dart:_rti to create an [rti.Rti] instance when
  // needed.
  JS('', r'#.# = #[0]', classRef, rti.interfaceTypeRecipePropertyName,
      interfaceRecipes);
  // Add specialized test resources used for fast interface type checks in
  // dart:_rti.
  var prototype = JS<Object>('!', '#.prototype', classRef);
  for (var recipe in interfaceRecipes) {
    var tagSymbol = typeTagSymbol(recipe);
    JS('', '#.# = #', prototype, tagSymbol, true);
  }
}

/// Pre-initializes types with empty type caches.
///
/// Allows us to perform faster lookups on local caches without having to
/// filter out the prototype chain. Also allows types to remain relatively
/// monomorphic, which results in faster execution in V8.
addTypeCaches(type) {
  if (JS_GET_FLAG('NEW_RUNTIME_TYPES')) {
    // Create a rti object cache property used in dart:_rti.
    JS('', '#[#] = null', type, rti.constructorRtiCachePropertyName);
  } else {
    JS('', '#[#] = void 0', type, _cachedLegacy);
    JS('', '#[#] = void 0', type, _cachedNullable);
    var subtypeCacheMap = JS<Object>('!', 'new Map()');
    JS('', '#[#] = #', type, _subtypeCache, subtypeCacheMap);
    JS('', '#.push(#)', _cacheMaps, subtypeCacheMap);
  }
}

// TODO(jmesserly): should we do this for all interfaces?

/// The well known symbol for testing `is Future`
final isFuture = JS('', 'Symbol("_is_Future")');

/// The well known symbol for testing `is Iterable`
final isIterable = JS('', 'Symbol("_is_Iterable")');

/// The well known symbol for testing `is List`
final isList = JS('', 'Symbol("_is_List")');

/// The well known symbol for testing `is Map`
final isMap = JS('', 'Symbol("_is_Map")');

/// The well known symbol for testing `is Stream`
final isStream = JS('', 'Symbol("_is_Stream")');

/// The well known symbol for testing `is StreamSubscription`
final isStreamSubscription = JS('', 'Symbol("_is_StreamSubscription")');

/// The default `operator ==` that calls [identical].
var identityEquals;
