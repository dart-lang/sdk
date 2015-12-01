// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/* This library defines the operations that define and manipulate Dart
 * classes.  Included in this are:
 *   - Generics
 *   - Class metadata
 *   - Extension methods
 */

// TODO(leafp): Consider splitting some of this out.
dart_library.library('dart/_classes', null, /* Imports */[
], /* Lazy Imports */[
  'dart/_utils',
  'dart/core',
  'dart/_interceptors',
  'dart/_types',
  'dart/_rtti',
], function(exports, dart_utils, core, _interceptors, types, rtti) {
  'use strict';

  const assert = dart_utils.assert_;
  const copyProperties = dart_utils.copyProperties;
  const copyTheseProperties = dart_utils.copyTheseProperties;
  const defineMemoizedGetter = dart_utils.defineMemoizedGetter;
  const safeGetOwnProperty = dart_utils.safeGetOwnProperty;
  const throwInternalError = dart_utils.throwInternalError;

  const defineProperty = Object.defineProperty;
  const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const getOwnPropertySymbols = Object.getOwnPropertySymbols;

  /** The Symbol for storing type arguments on a specialized generic type. */
  const _mixins = Symbol('mixins');
  const _implements = Symbol('implements');
  exports.implements = _implements;
  const _metadata = Symbol('metadata');
  exports.metadata = _metadata;

  /**
   * Returns a new type that mixes members from base and all mixins.
   *
   * Each mixin applies in sequence, with further to the right ones overriding
   * previous entries.
   *
   * For each mixin, we only take its own properties, not anything from its
   * superclass (prototype).
   */
  function mixin(base, ...mixins) {
    // Create an initializer for the mixin, so when derived constructor calls
    // super, we can correctly initialize base and mixins.

    // Create a class that will hold all of the mixin methods.
    class Mixin extends base {
      // Initializer method: run mixin initializers, then the base.
      [base.name](...args) {
        // Run mixin initializers. They cannot have arguments.
        // Run them backwards so most-derived mixin is initialized first.
        for (let i = mixins.length - 1; i >= 0; i--) {
          let mixin = mixins[i];
          let init = mixin.prototype[mixin.name];
          if (init) init.call(this);
        }
        // Run base initializer.
        let init = base.prototype[base.name];
        if (init) init.apply(this, args);
      }
    }
    // Copy each mixin's methods, with later ones overwriting earlier entries.
    for (let m of mixins) {
      copyProperties(Mixin.prototype, m.prototype);
    }

    // Set the signature of the Mixin class to be the composition
    // of the signatures of the mixins.
    setSignature(Mixin, {
      methods: () => {
        let s = {};
        for (let m of mixins) {
          copyProperties(s, m[_methodSig]);
        }
        return s;
      }
    });

    // Save mixins for reflection
    Mixin[_mixins] = mixins;
    return Mixin;
  }
  exports.mixin = mixin;

  function getMixins (clazz) {
    return clazz[_mixins];
  }
  exports.getMixins = getMixins;

  function getImplements (clazz) {
    return clazz[_implements];
  }
  exports.getImplements = getImplements;

  /** The Symbol for storing type arguments on a specialized generic type. */
  let _typeArguments = Symbol('typeArguments');
  let _originalDeclaration = Symbol('originalDeclaration');

  /** Memoize a generic type constructor function. */
  function generic(typeConstructor) {
    let length = typeConstructor.length;
    if (length < 1) {
      throwInternalError('must have at least one generic type argument');
    }
    let resultMap = new Map();
    function makeGenericType(...args) {
      if (args.length != length && args.length != 0) {
        throwInternalError('requires ' + length + ' or 0 type arguments');
      }
      while (args.length < length) args.push(types.dynamic);

      let value = resultMap;
      for (let i = 0; i < length; i++) {
        let arg = args[i];
        if (arg == null) {
          throwInternalError('type arguments should not be null: '
                            + typeConstructor);
        }
        let map = value;
        value = map.get(arg);
        if (value === void 0) {
          if (i + 1 == length) {
            value = typeConstructor.apply(null, args);
            // Save the type constructor and arguments for reflection.
            if (value) {
              value[_typeArguments] = args;
              value[_originalDeclaration] = makeGenericType;
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
  }
  exports.generic = generic;

  function getGenericClass(type) {
    return safeGetOwnProperty(type, _originalDeclaration);
  };
  exports.getGenericClass = getGenericClass;

  function getGenericArgs(type) {
    return safeGetOwnProperty(type, _typeArguments);
  };
  exports.getGenericArgs = getGenericArgs;

  let _constructorSig = Symbol('sigCtor');
  let _methodSig = Symbol("sig");
  let _staticSig = Symbol("sigStatic");

  /// Get the type of a method using the stored signature
  function _getMethodType(obj, name) {
    if (obj === void 0) return void 0;
    if (obj == null) return void 0;
    let sigObj = obj.__proto__.constructor[_methodSig];
    if (sigObj === void 0) return void 0;
    let parts = sigObj[name];
    if (parts === void 0) return void 0;
    return types.definiteFunctionType.apply(null, parts);
  }

  /// Get the type of a constructor from a class using the stored signature
  /// If name is undefined, returns the type of the default constructor
  /// Returns undefined if the constructor is not found.
  function _getConstructorType(cls, name) {
    if(!name) name = cls.name;
    if (cls === void 0) return void 0;
    if (cls == null) return void 0;
    let sigCtor = cls[_constructorSig];
    if (sigCtor === void 0) return void 0;
    let parts = sigCtor[name];
    if (parts === void 0) return void 0;
    return types.definiteFunctionType.apply(null, parts);
  }
  exports.classGetConstructorType = _getConstructorType;

  /// Given an object and a method name, tear off the method.
  /// Sets the runtime type of the torn off method appropriately,
  /// and also binds the object.
  ///
  /// If the optional `f` argument is passed in, it will be used as the method.
  /// This supports cases like `super.foo` where we need to tear off the method
  /// from the superclass, not from the `obj` directly.
  /// TODO(leafp): Consider caching the tearoff on the object?
  function bind(obj, name, f) {
    if (f === void 0) f = obj[name];
    f = f.bind(obj);
    // TODO(jmesserly): track the function's signature on the function, instead
    // of having to go back to the class?
    let sig = _getMethodType(obj, name);
    assert(sig);
    rtti.tag(f, sig);
    return f;
  }
  exports.bind = bind;

  // Set up the method signature field on the constructor
  function _setMethodSignature(f, sigF) {
    defineMemoizedGetter(f, _methodSig, () => {
      let sigObj = sigF();
      sigObj.__proto__ = f.__proto__[_methodSig];
      return sigObj;
    });
  }

  // Set up the constructor signature field on the constructor
  function _setConstructorSignature(f, sigF) {
    defineMemoizedGetter(f, _constructorSig, sigF);
  }

  // Set up the static signature field on the constructor
  function _setStaticSignature(f, sigF) {
    defineMemoizedGetter(f, _staticSig, sigF);
  }

  // Set the lazily computed runtime type field on static methods
  function _setStaticTypes(f, names) {
    for (let name of names) {
      rtti.tagMemoized(f[name], function() {
        let parts = f[_staticSig][name];
        return types.definiteFunctionType.apply(null, parts);
      })
    }
  }

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
  function setSignature(f, signature) {
    let constructors =
      ('constructors' in signature) ? signature.constructors : () => ({});
    let methods =
      ('methods' in signature) ? signature.methods : () => ({});
    let statics =
      ('statics' in signature) ? signature.statics : () => ({});
    let names =
      ('names' in signature) ? signature.names : [];
    _setConstructorSignature(f, constructors);
    _setMethodSignature(f, methods);
    _setStaticSignature(f, statics);
    _setStaticTypes(f, names);
    rtti.tagMemoized(f, () => core.Type);
  }
  exports.setSignature = setSignature;

  function hasMethod(obj, name) {
    return _getMethodType(obj, name) !== void 0;
  }
  exports.hasMethod = hasMethod;

  exports.getMethodType = _getMethodType;

  /**
   * This is called whenever a derived class needs to introduce a new field,
   * shadowing a field or getter/setter pair on its parent.
   *
   * This is important because otherwise, trying to read or write the field
   * would end up calling the getter or setter, and one of those might not even
   * exist, resulting in a runtime error. Even if they did exist, that's the
   * wrong behavior if a new field was declared.
   */
  function virtualField(subclass, fieldName) {
    // If the field is already overridden, do nothing.
    let prop = getOwnPropertyDescriptor(subclass.prototype, fieldName);
    if (prop) return;

    let symbol = Symbol(subclass.name + '.' + fieldName);
    defineProperty(subclass.prototype, fieldName, {
      get: function() { return this[symbol]; },
      set: function(x) { this[symbol] = x; }
    });
  }
  exports.virtualField = virtualField;

  /**
   * Given a class and an initializer method name, creates a constructor
   * function with the same name. For example `new SomeClass.name(args)`.
   */
  function defineNamedConstructor(clazz, name) {
    let proto = clazz.prototype;
    let initMethod = proto[name];
    let ctor = function() { return initMethod.apply(this, arguments); };
    ctor.prototype = proto;
    // Use defineProperty so we don't hit a property defined on Function,
    // like `caller` and `arguments`.
    defineProperty(clazz, name, { value: ctor, configurable: true });
  }
  exports.defineNamedConstructor = defineNamedConstructor;

  let _extensionType = Symbol('extensionType');

  let dartx = {};
  exports.dartx = dartx;

  function getExtensionSymbol(name) {
    let sym = dartx[name];
    if (!sym) dartx[name] = sym = Symbol('dartx.' + name);
    return sym;
  }

  function defineExtensionNames(names) {
    names.forEach(getExtensionSymbol);
  }
  exports.defineExtensionNames = defineExtensionNames;

  /**
   * Copy symbols from the prototype of the source to destination.
   * These are the only properties safe to copy onto an existing public
   * JavaScript class.
   */
  function registerExtension(jsType, dartExtType) {
    let extProto = dartExtType.prototype;
    let jsProto = jsType.prototype;

    // Mark the JS type's instances so we can easily check for extensions.
    assert(jsProto[_extensionType] === void 0);
    jsProto[_extensionType] = extProto;

    let dartObjProto = core.Object.prototype;
    while (extProto !== dartObjProto && extProto !== jsProto) {
      copyTheseProperties(jsProto, extProto, getOwnPropertySymbols(extProto));
      extProto = extProto.__proto__;
    }
    let originalSigFn = getOwnPropertyDescriptor(dartExtType, _methodSig).get;
    assert(originalSigFn);
    defineMemoizedGetter(jsType, _methodSig, originalSigFn);
  }
  exports.registerExtension = registerExtension;

  /**
   * Mark a concrete type as implementing extension methods.
   * For example: `class MyIter implements Iterable`.
   *
   * This takes a list of names, which are the extension methods implemented.
   * It will add a forwarder, so the extension method name redirects to the
   * normal Dart method name. For example:
   *
   *     defineExtensionMembers(MyType, ['add', 'remove']);
   *
   * Results in:
   *
   *     MyType.prototype[dartx.add] = MyType.prototype.add;
   *     MyType.prototype[dartx.remove] = MyType.prototype.remove;
   */
  // TODO(jmesserly): essentially this gives two names to the same method.
  // This benefit is roughly equivalent call performance either way, but the
  // cost is we need to call defineExtensionMembers any time a subclass
  // overrides one of these methods.
  function defineExtensionMembers(type, methodNames) {
    let proto = type.prototype;
    for (let name of methodNames) {
      let method = getOwnPropertyDescriptor(proto, name);
      defineProperty(proto, getExtensionSymbol(name), method);
    }
    // Ensure the signature is available too.
    // TODO(jmesserly): not sure if we can do this in a cleaner way. Essentially
    // we need to copy the signature (and in the future, other data like
    // annotations) any time we copy a method as part of our metaprogramming.
    // It might be more friendly to JS metaprogramming if we include this info
    // on the function.
    let originalSigFn = getOwnPropertyDescriptor(type, _methodSig).get;
    defineMemoizedGetter(type, _methodSig, function() {
      let sig = originalSigFn();
      for (let name of methodNames) {
        sig[getExtensionSymbol(name)] = sig[name];
      }
      return sig;
    });
  }
  exports.defineExtensionMembers = defineExtensionMembers;

  function canonicalMember(obj, name) {
    if (obj != null && obj[_extensionType]) return dartx[name];
    // Check for certain names that we can't use in JS
    if (name == 'constructor' || name == 'prototype') {
      name = '+' + name;
    }
    return name;
  }
  exports.canonicalMember = canonicalMember;

  /** Sets the type of `obj` to be `type` */
  function setType(obj, type) {
    obj.__proto__ = type.prototype;
    return obj;
  }

  /** Sets the element type of a list literal. */
  function list(obj, elementType) {
    return setType(obj, _interceptors.JSArray$(elementType));
  }
  exports.list = list;

  function setBaseClass(derived, base) {
    // Link the extension to the type it's extending as a base class.
    derived.prototype.__proto__ = base.prototype;
  }
  exports.setBaseClass = setBaseClass;

});
