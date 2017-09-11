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

///
/// Returns a new type that mixes members from base and all mixins.
///
/// Each mixin applies in sequence, with further to the right ones overriding
/// previous entries.
///
/// For each mixin, we only take its own properties, not anything from its
/// superclass (prototype).
mixin(base, @rest mixins) => JS('', '''(() => {
  // Create an initializer for the mixin, so when derived constructor calls
  // super, we can correctly initialize base and mixins.

  // Create a class that will hold all of the mixin methods.
  class Mixin extends $base {}
  // Save the original constructor.  For ClassTypeAlias definitions, this
  // is the concrete type.  We embed metadata (e.g., implemented interfaces)
  // on this constructor and need to access that from runtime instances.
  let constructor = Mixin.prototype.constructor;
  // Copy each mixin's methods, with later ones overwriting earlier entries.
  for (let m of $mixins) {
    $copyProperties(Mixin.prototype, m.prototype);
  }
  // Restore original Mixin JS constructor.
  Mixin.prototype.constructor = constructor;  
  // Dart constructors: run mixin constructors, then the base constructors.
  for (let memberName of $getOwnNamesAndSymbols($base)) {
    let member = $safeGetOwnProperty($base, memberName);
    if (typeof member == "function" && member.prototype === base.prototype) {
      $defineValue(Mixin, memberName, function(...args) {
        // Run mixin initializers. They cannot have arguments.
        // Run them backwards so most-derived mixin is initialized first.
        for (let i = $mixins.length - 1; i >= 0; i--) {
          let m = $mixins[i];
          (m[$mixinNew] || m.new).call(this);
        }
        // Run base initializer.
        $base[memberName].apply(this, args);
      }).prototype = Mixin.prototype;
    }
  }

  // Set the signature of the Mixin class to be the composition
  // of the signatures of the mixins.
  $setSignature(Mixin, {
    methods: () => {
      let s = {};
      for (let m of $mixins) {
        if (m[$_methodSig]) $copyProperties(s, m[$_methodSig]);
      }
      return s;
    },
    fields: () => {
      let s = {};
      for (let m of $mixins) {
        if (m[$_fieldSig]) $copyProperties(s, m[$_fieldSig]);
      }
      return s;
    },
    getters: () => {
      let s = {};
      for (let m of $mixins) {
        if (m[$_getterSig]) $copyProperties(s, m[$_getterSig]);
      }
      return s;
    },
    setters: () => {
      let s = {};
      for (let m of $mixins) {
        if (m[$_setterSig]) $copyProperties(s, m[$_setterSig]);
      }
      return s;
    }
  });

  // Save mixins for reflection
  Mixin[$_mixins] = $mixins;
  return Mixin;
})()''');

/// The Symbol for storing type arguments on a specialized generic type.
final _mixins = JS('', 'Symbol("mixins")');

getMixins(clazz) => JS('', 'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz, _mixins, clazz, _mixins);

@JSExportName('implements')
final _implements = JS('', 'Symbol("implements")');

getImplements(clazz) => JS('', 'Object.hasOwnProperty.call(#, #) ? #[#] : null',
    clazz, _implements, clazz, _implements);

/// The Symbol for storing type arguments on a specialized generic type.
final _typeArguments = JS('', 'Symbol("typeArguments")');

final _originalDeclaration = JS('', 'Symbol("originalDeclaration")');

final mixinNew = JS('', 'Symbol("dart.mixinNew")');

/// Wrap a generic class builder function with future flattening.
flattenFutures(builder) => JS('', '''(() => {
  function flatten(T) {
    if (!T) return $builder($dynamic);
    let futureClass = $getGenericClass($Future);
    //TODO(leafp): This only handles the direct flattening case.
    // It would probably be good to at least search up the class
    // hierarchy.  If we keep doing flattening long term, we may
    // want to implement the full future flattening per spec.
    if ($getGenericClass(T) == futureClass) {
      let args = $getGenericArgs(T);
      if (args) return $builder(args[0]);
    }
    return $builder(T);
  }
  return flatten;
})()''');

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
          if ($setBaseClass) $setBaseClass(value);
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

// TODO(vsm): Collapse into one expando.
final _constructorSig = JS('', 'Symbol("sigCtor")');
final _methodSig = JS('', 'Symbol("sigMethod")');
final _fieldSig = JS('', 'Symbol("sigField")');
final _getterSig = JS('', 'Symbol("sigGetter")');
final _setterSig = JS('', 'Symbol("sigSetter")');
final _staticSig = JS('', 'Symbol("sigStaticMethod")');
final _staticFieldSig = JS('', 'Symbol("sigStaticField")');
final _staticGetterSig = JS('', 'Symbol("sigStaticGetter")');
final _staticSetterSig = JS('', 'Symbol("sigStaticSetter")');
final _genericTypeCtor = JS('', 'Symbol("genericType")');

// TODO(vsm): Collapse this as well - just provide a dart map to mirrors code.
// These are queried by mirrors code.
getConstructorSig(value) => JS('', '#[#]', value, _constructorSig);
getMethodSig(value) => JS('', '#[#]', value, _methodSig);
getFieldSig(value) => JS('', '#[#]', value, _fieldSig);
getGetterSig(value) => JS('', '#[#]', value, _getterSig);
getSetterSig(value) => JS('', '#[#]', value, _setterSig);
getStaticSig(value) => JS('', '#[#]', value, _staticSig);
getStaticFieldSig(value) => JS('', '#[#]', value, _staticFieldSig);
getStaticGetterSig(value) => JS('', '#[#]', value, _staticGetterSig);
getStaticSetterSig(value) => JS('', '#[#]', value, _staticSetterSig);

getGenericTypeCtor(value) => JS('', '#[#]', value, _genericTypeCtor);

/// Get the type of a method from an object using the stored signature
getType(obj) =>
    JS('', '# == null ? # : #.__proto__.constructor', obj, Object, obj);

bool isJsInterop(obj) {
  if (obj == null) return false;
  if (JS('bool', 'typeof # === "function"', obj)) {
    // A function is a Dart function if it has runtime type information.
    return _getRuntimeType(obj) == null;
  }
  // Primitive types are not JS interop types.
  if (JS('bool', 'typeof # !== "object"', obj)) return false;

  // Extension types are not considered JS interop types.
  // Note that it is still possible to call typed JS interop methods on
  // extension types but the calls must be statically typed.
  if (getExtensionType(obj) != null) return false;
  return JS('bool', '!($obj instanceof $Object)');
}

/// Get the type of a method from a type using the stored signature
getMethodType(type, name) {
  var m = JS('', '#[#]', type, _methodSig);
  return m != null ? JS('', '#[#]', m, name) : null;
}

/// Gets the type of the corresponding setter (this includes writable fields).
getSetterType(type, name) {
  var signature = JS('', '#[#]', type, _setterSig);
  if (signature != null) {
    var type = JS('', '#[#]', signature, name);
    if (type != null) {
      // TODO(jmesserly): it would be nice not to encode setters with a full
      // function type.
      if (JS('bool', '# instanceof Array', type)) {
        // The type has metadata attached.  Pull out just the type.
        // TODO(vsm): Come up with a more robust encoding for this or remove
        // if we can deprecate mirrors.
        // Essentially, we've got a FunctionType or a
        // [FunctionType, metadata1, ..., metadataN].
        type = JS('', '#[0]', type);
      }
      return JS('', '#.args[0]', type);
    }
  }
  signature = JS('', '#[#]', type, _fieldSig);
  if (signature != null) {
    var fieldInfo = JS('', '#[#]', signature, name);
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
classGetConstructorType(cls, name) => JS('', '''(() => {
  if(!$name) $name = 'new';
  if ($cls === void 0) return void 0;
  if ($cls == null) return void 0;
  let sigCtor = $cls[$_constructorSig];
  if (sigCtor === void 0) return void 0;
  return sigCtor[$name];
})()''');

// Set up the method signature field on the constructor
_setInstanceSignature(f, sigF, kind) => defineMemoizedGetter(
    f,
    kind,
    JS(
        '',
        '''() => {
          let sigObj = #();
          let proto = #.__proto__;
          // We need to set the root proto to null not undefined.
          sigObj.__proto__ = (# in proto) ? proto[#] : null;
          return sigObj;
        }''',
        sigF,
        f,
        kind,
        kind));

_setMethodSignature(f, sigF) => _setInstanceSignature(f, sigF, _methodSig);
_setFieldSignature(f, sigF) => _setInstanceSignature(f, sigF, _fieldSig);
_setGetterSignature(f, sigF) => _setInstanceSignature(f, sigF, _getterSig);
_setSetterSignature(f, sigF) => _setInstanceSignature(f, sigF, _setterSig);

// Set up the constructor signature field on the constructor
_setConstructorSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_constructorSig, $sigF)');

// Set up the static signature field on the constructor
_setStaticSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_staticSig, $sigF)');

_setStaticFieldSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_staticFieldSig, $sigF)');

_setStaticGetterSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_staticGetterSig, $sigF)');

_setStaticSetterSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_staticSetterSig, $sigF)');

// Set the lazily computed runtime type field on static methods
_setStaticTypes(f, names) => JS('', '''(() => {
  for (let name of $names) {
    // TODO(vsm): Need to generate static methods.
    if (!$f[name]) continue;
    $tagLazy($f[name], function() {
      return $f[$_staticSig][name];
    })
  }
})()''');

/// Set up the type signature of a class (constructor object)
/// f is a constructor object
/// signature is an object containing optional properties as follows:
///  methods: A function returning an object mapping method names
///   to method types.  The function is evaluated lazily and cached.
///  statics: A function returning an object mapping static method
///   names to types.  The function is evaluated lazily and cached.
///  names: An array of the names of the static methods.  Used to
///   permit eagerly setting the runtimeType field on the methods
///   while still lazily computing the type descriptor object.
///  fields: A function returning an object mapping instance field
///    names to types.
setSignature(f, signature) => JS('', '''(() => {
  // TODO(ochafik): Deconstruct these when supported by Chrome.
  let constructors =
    ('constructors' in signature) ? signature.constructors : () => ({});
  let methods =
    ('methods' in signature) ? signature.methods : () => ({});
  let fields =
    ('fields' in signature) ? signature.fields : () => ({});
  let getters =
    ('getters' in signature) ? signature.getters : () => ({});
  let setters =
    ('setters' in signature) ? signature.setters : () => ({});
  let statics =
    ('statics' in signature) ? signature.statics : () => ({});
  let staticFields =
    ('sfields' in signature) ? signature.sfields : () => ({});
  let staticGetters =
    ('sgetters' in signature) ? signature.sgetters : () => ({});
  let staticSetters =
    ('ssetters' in signature) ? signature.ssetters : () => ({});
  let names =
    ('names' in signature) ? signature.names : [];
  $_setConstructorSignature($f, constructors);
  $_setMethodSignature($f, methods);
  $_setFieldSignature($f, fields);
  $_setGetterSignature($f, getters);
  $_setSetterSignature($f, setters);
  $_setStaticSignature($f, statics);
  $_setStaticFieldSignature($f, staticFields);
  $_setStaticGetterSignature($f, staticGetters);
  $_setStaticSetterSignature($f, staticSetters);
  $_setStaticTypes($f, names);
})()''');

bool _hasSigEntry(type, sigF, name) => JS('bool', '''(() => {
  let sigObj = $type[$sigF];
  if (sigObj === void 0) return false;
  return $name in sigObj;
})()''');

bool hasMethod(type, name) => _hasSigEntry(type, _methodSig, name);
bool hasGetter(type, name) => _hasSigEntry(type, _getterSig, name);
bool hasSetter(type, name) => _hasSigEntry(type, _setterSig, name);
bool hasField(type, name) => _hasSigEntry(type, _fieldSig, name);

final _extensionType = JS('', 'Symbol("extensionType")');

/// This assumes that obj is not null
getExtensionType(obj) => JS('', '#[#]', obj, _extensionType);

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
}

final _extensionMap = JS('', 'new Map()');

_applyExtension(jsType, dartExtType) => JS('', '''(() => {
  // TODO(vsm): Not all registered js types are real.
  if (!$jsType) return;

  let jsProto = $jsType.prototype;

  // TODO(vsm): This sometimes doesn't exist on FF.  These types will be
  // broken.
  if (!jsProto) return;
  if ($dartExtType === $Object) {
    $_installPropertiesForGlobalObject(jsProto);
    return;
  }

  $_installProperties(jsProto, $dartExtType, jsProto[$_extensionType]);
  
  // Mark the JS type's instances so we can easily check for extensions.
  if ($dartExtType !== $JSFunction) {
    jsProto[$_extensionType] = $dartExtType;
  }

  function updateSig(sigF) {
    let originalDesc = $getOwnPropertyDescriptor($dartExtType, sigF);
    if (originalDesc === void 0) return;
    let originalSigFn = originalDesc.get;
    $defineMemoizedGetter($jsType, sigF, originalSigFn);
  }
  updateSig($_methodSig);
  updateSig($_fieldSig);
  updateSig($_getterSig);
  updateSig($_setterSig);
})()''');

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
defineExtensionMembers(type, methodNames) => JS('', '''(() => {
  let proto = $type.prototype;
  for (let name of $methodNames) {
    let method = $getOwnPropertyDescriptor(proto, name);
    $defineProperty(proto, $dartx[name], method);
  }
  // Ensure the signature is available too.
  // TODO(jmesserly): not sure if we can do this in a cleaner way. Essentially
  // we need to copy the signature (and in the future, other data like
  // annotations) any time we copy a method as part of our metaprogramming.
  // It might be more friendly to JS metaprogramming if we include this info
  // on the function.
  // Alternatively we can pick a canonical name, and make sure our dynamic
  // operations always use that. For example, if we have all possible extension
  // member names be symbolized, we'll never need to worry about it.

  function upgradeSig(sigF) {
    let originalSigDesc = $getOwnPropertyDescriptor($type, sigF);
    if (originalSigDesc === void 0) return;
    let originalSigFn = originalSigDesc.get;
    $defineMemoizedGetter(type, sigF, function() {
      let sig = originalSigFn();
      let propertyNames = Object.getOwnPropertyNames(sig);
      for (let name of methodNames) {
        if (name in sig) {
          sig[$dartx[name]] = sig[name];
        }
      }
      return sig;
    });
  };
  upgradeSig($_methodSig);
  upgradeSig($_fieldSig);
  upgradeSig($_getterSig);
  upgradeSig($_setterSig);
})()''');

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

defineEnumValues(enumClass, names) {
  var values = [];
  for (var i = 0; i < JS('int', '#.length', names); i++) {
    var value = const_(JS('', 'new #.new(#)', enumClass, i));
    JS('', '#.push(#)', values, value);
    defineValue(enumClass, JS('', '#[#]', names, i), value);
  }
  JS('', '#.values = #', enumClass, constList(values, enumClass));
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
    if (obj != null && obj[#]) return true;
    return #(obj, this);
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
