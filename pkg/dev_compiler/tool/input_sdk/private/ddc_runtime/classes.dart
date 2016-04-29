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
///
mixin(base, @rest mixins) => JS('', '''(() => {
  // Create an initializer for the mixin, so when derived constructor calls
  // super, we can correctly initialize base and mixins.

  // Create a class that will hold all of the mixin methods.
  class Mixin extends $base {
    // Initializer method: run mixin initializers, then the base.
    [$base.name](...args) {
      // Run mixin initializers. They cannot have arguments.
      // Run them backwards so most-derived mixin is initialized first.
      for (let i = $mixins.length - 1; i >= 0; i--) {
        let mixin = $mixins[i];
        let init = mixin.prototype[mixin.name];
        if (init) init.call(this);
      }
      // Run base initializer.
      let init = $base.prototype[base.name];
      if (init) init.apply(this, args);
    }
  }
  // Copy each mixin's methods, with later ones overwriting earlier entries.
  for (let m of $mixins) {
    $copyProperties(Mixin.prototype, m.prototype);
  }

  // Set the signature of the Mixin class to be the composition
  // of the signatures of the mixins.
  $setSignature(Mixin, {
    methods: () => {
      let s = {};
      for (let m of $mixins) {
        $copyProperties(s, m[$_methodSig]);
      }
      return s;
    }
  });

  // Save mixins for reflection
  Mixin[$_mixins] = $mixins;
  return Mixin;
})()''');

getMixins(clazz) => JS('', '$clazz[$_mixins]');

getImplements(clazz) => JS('', '$clazz[$implements_]');

/// The Symbol for storing type arguments on a specialized generic type.
final _typeArguments = JS('', 'Symbol("typeArguments")');
final _originalDeclaration = JS('', 'Symbol("originalDeclaration")');

/// Memoize a generic type constructor function.
generic(typeConstructor) => JS('', '''(() => {
  let length = $typeConstructor.length;
  if (length < 1) {
    $throwInternalError('must have at least one generic type argument');
  }
  let resultMap = new Map();
  function makeGenericType(...args) {
    if (args.length != length && args.length != 0) {
      $throwInternalError('requires ' + length + ' or 0 type arguments');
    }
    while (args.length < length) args.push($dynamicR);

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
        } else {
          value = new Map();
        }
        map.set(arg, value);
      }
    }
    return value;
  }
  return makeGenericType;
})()''');

getGenericClass(type) =>
    JS('', '$safeGetOwnProperty($type, $_originalDeclaration)');

getGenericArgs(type) =>
    JS('', '$safeGetOwnProperty($type, $_typeArguments)');

final _constructorSig = JS('', 'Symbol("sigCtor")');
final _methodSig = JS('', 'Symbol("sig")');
final _staticSig = JS('', 'Symbol("sigStatic")');

/// Get the type of a method from an object using the stored signature
getMethodType(obj, name) => JS('', '''(() => {
  let type = $obj == null ? $Object : $obj.__proto__.constructor;
  return $getMethodTypeFromType(type, $name);
})()''');

/// Get the type of a method from a type using the stored signature
getMethodTypeFromType(type, name) => JS('', '''(() => {
  let sigObj = $type[$_methodSig];
  if (sigObj === void 0) return void 0;
  let parts = sigObj[$name];
  if (parts === void 0) return void 0;
  return $definiteFunctionType.apply(null, parts);
})()''');

/// Get the type of a constructor from a class using the stored signature
/// If name is undefined, returns the type of the default constructor
/// Returns undefined if the constructor is not found.
classGetConstructorType(cls, name) => JS('', '''(() => {
  if(!$name) $name = $cls.name;
  if ($cls === void 0) return void 0;
  if ($cls == null) return void 0;
  let sigCtor = $cls[$_constructorSig];
  if (sigCtor === void 0) return void 0;
  let parts = sigCtor[$name];
  if (parts === void 0) return void 0;
  return $definiteFunctionType.apply(null, parts);
})()''');

/// Given an object and a method name, tear off the method.
/// Sets the runtime type of the torn off method appropriately,
/// and also binds the object.
///
/// If the optional `f` argument is passed in, it will be used as the method.
/// This supports cases like `super.foo` where we need to tear off the method
/// from the superclass, not from the `obj` directly.
/// TODO(leafp): Consider caching the tearoff on the object?
bind(obj, name, f) => JS('', '''(() => {
  if ($f === void 0) $f = $obj[$name];
  $f = $f.bind($obj);
  // TODO(jmesserly): track the function's signature on the function, instead
  // of having to go back to the class?
  let sig = $getMethodType($obj, $name);
  $assert_(sig);
  $tag($f, sig);
  return $f;
})()''');

/// Instantiate a generic method.
///
/// We need to apply the type arguments both to the function, as well as its
/// associated function type.
gbind(f, @rest typeArgs) {
  var result = JS('', '#(...#)', f, typeArgs);
  var sig = JS('', '#(...#)', _getRuntimeType(f), typeArgs);
  tag(result, sig);
  return result;
}

// Set up the method signature field on the constructor
_setMethodSignature(f, sigF) => JS('', '''(() => {
  $defineMemoizedGetter($f, $_methodSig, () => {
    let sigObj = $sigF();
    sigObj.__proto__ = $f.__proto__[$_methodSig];
    return sigObj;
  });
})()''');

// Set up the constructor signature field on the constructor
_setConstructorSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_constructorSig, $sigF)');

// Set up the static signature field on the constructor
_setStaticSignature(f, sigF) =>
    JS('', '$defineMemoizedGetter($f, $_staticSig, $sigF)');

// Set the lazily computed runtime type field on static methods
_setStaticTypes(f, names) => JS('', '''(() => {
  for (let name of $names) {
    // TODO(vsm): Need to generate static methods.
    if (!$f[name]) continue;
    $tagLazy($f[name], function() {
      let parts = $f[$_staticSig][name];
      return $definiteFunctionType.apply(null, parts);
    })
  }
})()''');

/// Set up the type signature of a class (constructor object)
/// f is a constructor object
/// signature is an object containing optional properties as follows:
///  methods: A function returning an object mapping method names
///   to method types.  The function is evaluated lazily and cached.
///  statics: A function returning an object mapping static method
///   names to types.  The function is evalutated lazily and cached.
///  names: An array of the names of the static methods.  Used to
///   permit eagerly setting the runtimeType field on the methods
///   while still lazily computing the type descriptor object.
setSignature(f, signature) => JS('', '''(() => {
  // TODO(ochafik): Deconstruct these when supported by Chrome.
  let constructors =
    ('constructors' in signature) ? signature.constructors : () => ({});
  let methods =
    ('methods' in signature) ? signature.methods : () => ({});
  let statics =
    ('statics' in signature) ? signature.statics : () => ({});
  let names =
    ('names' in signature) ? signature.names : [];
  $_setConstructorSignature($f, constructors);
  $_setMethodSignature($f, methods);
  $_setStaticSignature($f, statics);
  $_setStaticTypes($f, names);
  $tagLazy($f, () => $Type);
})()''');

hasMethod(obj, name) => JS('', '$getMethodType($obj, $name) !== void 0');

///
/// Given a class and an initializer method name, creates a constructor
/// function with the same name. For example `new SomeClass.name(args)`.
///
defineNamedConstructor(clazz, name) => JS('', '''(() => {
  let proto = $clazz.prototype;
  let initMethod = proto[$name];
  let ctor = function() { return initMethod.apply(this, arguments); };
  ctor.prototype = proto;
  // Use defineProperty so we don't hit a property defined on Function,
  // like `caller` and `arguments`.
  $defineProperty($clazz, $name, { value: ctor, configurable: true });
})()''');

final _extensionType = JS('', 'Symbol("extensionType")');

getExtensionType(obj) => JS('', '$obj[$_extensionType]');

final dartx = JS('', 'dartx');

getExtensionSymbol(name) => JS('', '''(() => {
  let sym = $dartx[$name];
  if (!sym) $dartx[$name] = sym = Symbol('dartx.' + $name.toString());
  return sym;
})()''');

defineExtensionNames(names) => JS('', '$names.forEach($getExtensionSymbol)');

// Install properties in prototype order.  Properties / descriptors from
// more specific types should overwrite ones from less specific types.
_installProperties(jsProto, extProto) => JS('', '''(() => {
  if (extProto !== $Object.prototype && extProto !== jsProto) {
    $_installProperties(jsProto, extProto.__proto__);
  }
  $copyTheseProperties(jsProto, extProto, $getOwnPropertySymbols(extProto));
})()''');

///
/// Copy symbols from the prototype of the source to destination.
/// These are the only properties safe to copy onto an existing public
/// JavaScript class.
///
registerExtension(jsType, dartExtType) => JS('', '''(() => {
  // TODO(vsm): Not all registered js types are real.
  if (!jsType) return;

  let extProto = $dartExtType.prototype;
  let jsProto = $jsType.prototype;

  // Mark the JS type's instances so we can easily check for extensions.
  jsProto[$_extensionType] = $dartExtType;
  $_installProperties(jsProto, extProto);
  let originalSigFn = $getOwnPropertyDescriptor($dartExtType, $_methodSig).get;
  $assert_(originalSigFn);
  $defineMemoizedGetter($jsType, $_methodSig, originalSigFn);
})()''');

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
    // TODO(vsm): We should be able to generate code to avoid this case.
    // The method may be null if this type implements a potentially native
    // interface but isn't native itself.  For a field on this type, we're not
    // generating a corresponding getter/setter method - it's just a field.
    if (!method) continue;
    $defineProperty(proto, $getExtensionSymbol(name), method);
  }
  // Ensure the signature is available too.
  // TODO(jmesserly): not sure if we can do this in a cleaner way. Essentially
  // we need to copy the signature (and in the future, other data like
  // annotations) any time we copy a method as part of our metaprogramming.
  // It might be more friendly to JS metaprogramming if we include this info
  // on the function.
  let originalSigFn = $getOwnPropertyDescriptor($type, $_methodSig).get;
  $defineMemoizedGetter(type, $_methodSig, function() {
    let sig = originalSigFn();
    for (let name of $methodNames) {
      sig[$getExtensionSymbol(name)] = sig[name];
    }
    return sig;
  });
})()''');

canonicalMember(obj, name) => JS('', '''(() => {
  if ($obj != null && $obj[$_extensionType]) return $dartx[$name];
  // Check for certain names that we can't use in JS
  if ($name == 'constructor' || $name == 'prototype') {
    $name = '+' + $name;
  }
  return $name;
})()''');

/// Sets the type of `obj` to be `type`
setType(obj, type) => JS('', '''(() => {
  $obj.__proto__ = $type.prototype;
  // TODO(vsm): This should be set in registerExtension, but that is only
  // invoked on the generic type (e.g., JSArray<dynamic>, not JSArray<int>).
  $obj.__proto__[$_extensionType] = $type;
  return $obj;
})()''');

/// Sets the element type of a list literal.
list(obj, elementType) =>
    JS('', '$setType($obj, ${getGenericClass(JSArray)}($elementType))');

setBaseClass(derived, base) => JS('', '''(() => {
  // Link the extension to the type it's extending as a base class.
  $derived.prototype.__proto__ = $base.prototype;
})()''');
