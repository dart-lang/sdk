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
///
/// The mixin must be non-generic; generic mixins are handled by [genericMixin].
void mixinMembers(to, from) {
  JS('', '#[#] = #', to, _mixin, from);
  var toProto = JS('', '#.prototype', to);
  var fromProto = JS('', '#.prototype', from);
  _copyMembers(toProto, fromProto);
  _mixinSignature(to, from, _methodSig);
  _mixinSignature(to, from, _fieldSig);
  _mixinSignature(to, from, _getterSig);
  _mixinSignature(to, from, _setterSig);
}

void _copyMembers(to, from) {
  var names = getOwnNamesAndSymbols(from);
  for (var i = 0, n = JS('int', '#.length', names); i < n; ++i) {
    var name = JS('', '#[#]', names, i);
    if (name == 'constructor') continue;
    _copyMember(to, from, name);
  }
  return to;
}

void _copyMember(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('bool', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('bool', '#.writable', existing)) {
        JS('', '#[#] = #.value', to, name, desc);
      }
      return;
    }
  }
  var getter = JS('', '#.get', desc);
  var setter = JS('', '#.set', desc);
  if (getter != null) {
    if (setter == null) {
      var obj = JS(
          '',
          '#.set = { __proto__: #.__proto__, '
          'set [#](x) { return super[#] = x; } }',
          desc,
          to,
          name,
          name);
      JS('', '#.set = #.set', desc, getOwnPropertyDescriptor(obj, name));
    }
  } else if (setter != null) {
    if (getter == null) {
      var obj = JS(
          '',
          '#.get = { __proto__: #.__proto__, '
          'get [#]() { return super[#]; } }',
          desc,
          to,
          name,
          name);
      JS('', '#.get = #.get', desc, getOwnPropertyDescriptor(obj, name));
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

@JSExportName('implements')
final _implements = JS('', 'Symbol("implements")');

getImplements(clazz) => JS('', 'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz, _implements, clazz, _implements);

/// The Symbol for storing type arguments on a specialized generic type.
final _typeArguments = JS('', 'Symbol("typeArguments")');

final _originalDeclaration = JS('', 'Symbol("originalDeclaration")');

final mixinNew = JS('', 'Symbol("dart.mixinNew")');

/// Memoize a generic type constructor function.
generic(typeConstructor, setBaseClass) => JS('', '''(() => {
  let length = $typeConstructor.length;
  if (length < 1) {
    $throwInternalError('must have at least one generic type argument');
  }
  let resultMap = new Map();
  function makeGenericType(...args) {
    if (args.length != length && args.length != 0) {
      $throwInternalError('requires ' + length + ' or 0 type arguments');
    }
    while (args.length < length) args.push($dynamic);

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

List getGenericArgs(type) =>
    JS('List', '#', safeGetOwnProperty(type, _typeArguments));

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

/// Get the type of a method from an object using the stored signature
getType(obj) =>
    JS('', '# == null ? # : #.__proto__.constructor', obj, Object, obj);

bool isJsInterop(obj) {
  if (obj == null) return false;
  if (JS('bool', 'typeof # === "function"', obj)) {
    // A function is a Dart function if it has runtime type information.
    return JS('bool', '#[#] == null', obj, _runtimeType);
  }
  // Primitive types are not JS interop types.
  if (JS('bool', 'typeof # !== "object"', obj)) return false;

  // Extension types are not considered JS interop types.
  // Note that it is still possible to call typed JS interop methods on
  // extension types but the calls must be statically typed.
  if (JS('bool', '#[#] != null', obj, _extensionType)) return false;
  return JS('bool', '!($obj instanceof $Object)');
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
      if (JS('bool', '# instanceof Array', type)) {
        // The type has metadata attached.  Pull out just the type.
        // TODO(jmesserly): remove when we remove mirrors
        return JS('', '#[0]', type);
      }
      return type;
    }
  }
  var fields = getFields(type);
  if (fields != null) {
    var fieldInfo = JS('', '#[#]', fields, name);
    if (fieldInfo != null && JS('bool', '!#.isFinal', fieldInfo)) {
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
  return JS('bool', 'typeof # == "function"', sig)
      ? JS('', '#[#] = #', type, kind, sig())
      : sig;
}

bool _hasMember(type, kind, name) {
  var sig = _getMembers(type, kind);
  return sig != null && JS('bool', '# in #', name, sig);
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
  if (JS('bool', '# === #', dartType, Object)) {
    _installPropertiesForObject(jsProto);
    return;
  }
  // If the extension methods of the parent have been installed on the parent
  // of [jsProto], the methods will be available via prototype inheritance.
  var dartSupertype = JS('', '#.__proto__', dartType);
  if (JS('bool', '# !== #', dartSupertype, installedParent)) {
    _installProperties(jsProto, dartSupertype, installedParent);
  }

  var dartProto = JS('', '#.prototype', dartType);
  copyTheseProperties(jsProto, dartProto, getOwnPropertySymbols(dartProto));
}

void _installPropertiesForObject(jsProto) {
  // core.Object members need to be copied from the non-symbol name to the
  // symbol name.
  var coreObjProto = JS('', '#.prototype', Object);
  var names = getOwnPropertyNames(coreObjProto);
  for (int i = 0; i < JS('int', '#.length', names); ++i) {
    var name = JS('String', '#[#]', names, i);
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

_applyExtension(jsType, dartExtType) {
  // TODO(vsm): Not all registered js types are real.
  if (jsType == null) return;
  var jsProto = JS('', '#.prototype', jsType);
  if (jsProto == null) return;

  if (JS('bool', '# === #', dartExtType, Object)) {
    _installPropertiesForGlobalObject(jsProto);
    return;
  }

  _installProperties(
      jsProto, dartExtType, JS('', '#[#]', jsProto, _extensionType));

  // Mark the JS type's instances so we can easily check for extensions.
  if (JS('bool', '# !== #', dartExtType, JSFunction)) {
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
defineExtensionAccessors(type, Iterable memberNames) {
  var proto = JS('', '#.prototype', type);
  for (var name in memberNames) {
    // Find the member. It should always exist (or we have a compiler bug).
    var member;
    var p = proto;
    for (;; p = JS('', '#.__proto__', p)) {
      member = JS('', 'Object.getOwnPropertyDescriptor(#, #)', p, name);
      if (member != null) break;
    }
    JS('', 'Object.defineProperty(#, dartx[#], #)', proto, name, member);
  }
}

definePrimitiveHashCode(proto) {
  defineProperty(proto, identityHashCode_,
      getOwnPropertyDescriptor(proto, extensionSymbol('hashCode')));
}

/// Link the extension to the type it's extending as a base class.
setBaseClass(derived, base) {
  JS('', '#.prototype.__proto__ = #.prototype', derived, base);
  // We use __proto__ to track the superclass hierarchy (see isSubtype).
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
    if (obj == null || obj[#]) return obj;
    return #(obj, this, false);
  }''',
      ctor,
      isClass,
      cast);
  JS(
      '',
      '''#._check = function check_C(obj) {
    if (obj == null || obj[#]) return obj;
    return #(obj, this, true);
  }''',
      ctor,
      isClass,
      cast);
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
