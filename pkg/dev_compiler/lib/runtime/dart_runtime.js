// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var dart, _js_helper;
(function (dart) {
  'use strict';

  let defineProperty = Object.defineProperty;
  let getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  let getOwnPropertyNames = Object.getOwnPropertyNames;

  // Adapted from Angular.js
  let FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m;
  let FN_ARG_SPLIT = /,/;
  let FN_ARG = /^\s*(_?)(\S+?)\1\s*$/;
  let STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg;

  function formalParameterList(fn) {
    let fnText,argDecl;
    let args=[];
    fnText = fn.toString().replace(STRIP_COMMENTS, '');
    argDecl = fnText.match(FN_ARGS);

    let r = argDecl[1].split(FN_ARG_SPLIT);
    for(let a in r) {
      let arg = r[a];
      arg.replace(FN_ARG, function(all, underscore, name){
        args.push(name);
      });
    }
    return args;
  }

  function dload(obj, field) {
    if (!(field in obj)) {
      throw new core.NoSuchMethodError(obj, field);
    }
    return obj[field];
  }
  dart.dload = dload;

  // TODO(jmesserly): this should call noSuchMethod, not throw.
  function throwNoSuchMethod(obj, name, args, opt_func) {
    if (obj === void 0) obj = opt_func;
    throw new core.NoSuchMethodError(obj, name, args);
  }

  function checkAndCall(f, obj, args, name) {
    if (!(f instanceof Function)) {
      // Grab the `call` method if it's not a function.
      if (f !== null) f = f.call;
      if (!(f instanceof Function)) {
        throwNoSuchMethod(obj, method, args);
      }
    }
    let formals = formalParameterList(f);
    // TODO(vsm): Type check args!  We need to encode sufficient type info on f.
    if (formals.length < args.length) {
      throwNoSuchMethod(obj, name, args, f);
    } else if (formals.length > args.length) {
      for (let i = args.length; i < formals.length; ++i) {
        if (formals[i].indexOf("opt$") != 0) {
          throwNoSuchMethod(obj, name, args, f);
        }
      }
    }
    return f.apply(obj, args);
  }

  function dinvokef(f/*, ...args*/) {
    let args = Array.prototype.slice.call(arguments, 1);
    return checkAndCall(f, void 0, args, 'call');
  }
  dart.dinvokef = dinvokef;

  function dinvoke(obj, method/*, ...args*/) {
    let args = Array.prototype.slice.call(arguments, 2);
    return checkAndCall(obj[method], obj, args, method);
  }
  dart.dinvoke = dinvoke;

  function dindex(obj, index) {
    return checkAndCall(obj.get, obj, [index], '[]');
  }
  dart.dindex = dindex;

  function dsetindex(obj, index, value) {
    return checkAndCall(obj.set, obj, [index, value], '[]=');
  }
  dart.dsetindex = dindex;

  function dbinary(left, op, right) {
    return checkAndCall(left[op], left, [right], op);
  }
  dart.dbinary = dbinary;

  function cast(obj, type) {
    // TODO(vsm): handle non-nullable types
    if (obj == null) return obj;
    let actual = getRuntimeType(obj);
    if (isSubtype(actual, type)) return obj;
    throw new _js_helper.CastErrorImplementation(actual, type);
  }
  dart.as = cast;

  /**
   * Returns the runtime type of obj. This is the same as `obj.runtimeType`
   * but will not call an overridden getter.
   *
   * Currently this will return null for non-Dart objects.
   */
  function getRuntimeType(obj) {
    switch (typeof obj) {
      case "undefined":
        return core.Null;
      case "number":
        return Math.floor(obj) == obj ? core.int : core.double;
      case "boolean":
        return core.bool;
      case "string":
        return core.String;
      case "symbol":
        return Symbol;
    }
    // Undefined is handled above. For historical reasons,
    // typeof null == "object" in JS.
    if (obj === null) return core.Null;
    return obj.constructor;
  }
  dart.getRuntimeType = getRuntimeType;

  function instanceOf(obj, type) {
    return isSubtype(getRuntimeType(obj), type);
  }
  dart.is = instanceOf;

  /**
   * Computes the canonical type.
   * This maps JS types onto their corresponding Dart Type.
   */
  // TODO(jmesserly): lots more needs to be done here.
  function canonicalType(t) {
    if (t === Object) return core.Object;
    if (t === Function) return core.Function;
    if (t === Array) return core.List;

    // We shouldn't normally get here with these types, unless something strange
    // happens like subclassing Number in JS and passing it to Dart.
    if (t === String) return core.String;
    if (t === Number) return core.double;
    if (t === Boolean) return core.bool;
    return t;
  }

  let subtypeMap = new Map();
  function isSubtype(t1, t2) {
    // See if we already know the answer
    // TODO(jmesserly): general purpose memoize function?
    let map = subtypeMap.get(t1);
    let result;
    if (map) {
      result = map.get(t2);
      if (result !== void 0) return result;
    } else {
      subtypeMap.set(t1, map = new Map());
    }
    map.set(t2, result = isSubtype_(t1, t2));
    return result;
  }
  dart.isSubtype = isSubtype;

  function isSubtype_(t1, t2) {
    t1 = canonicalType(t1);
    t2 = canonicalType(t2);
    if (t1 == t2) return true;

    // In Dart, dynamic is effectively both top and bottom.
    // Here, we treat dynamic as top - the base type of everything.
    if (t1 == dart.dynamic) return false;
    if (t2 == dart.dynamic) return true;

    if (t2 == core.Object) return true;
    if (t1 == core.Object) return false;

    // "Traditional" name-based subtype check.
    if (isClassSubType(t1, t2)) {
      return true;
    }

    // Function subtyping.
    // TODO(jmesserly): implement this properly.
    if (isClassSubType(t1, core.Function) &&
        isClassSubType(t2, core.Function)) {
      return true;
    }
    return false;
  }

  function safeGetOwnProperty(obj, name) {
    var desc = getOwnPropertyDescriptor(obj, name);
    if (desc) return desc.value;
  }

  function isClassSubType(t1, t2) {
    // We support Dart's covariant generics with the caveat that we do not
    // substitute bottom for dynamic in subtyping rules.
    // I.e., given T1, ..., Tn where at least one Ti != dynamic we disallow:
    // - S !<: S<T1, ..., Tn>
    // - S<dynamic, ..., dynamic> !<: S<T1, ..., Tn>
    if (t1 == t2) return true;

    if (t1 == core.Object) return false;

    // Check if t1 and t2 have the same raw type.  If so, check covariance on
    // type parameters.
    let raw1 = safeGetOwnProperty(t1, dart.originalDeclaration);
    let raw2 = safeGetOwnProperty(t2, dart.originalDeclaration);
    if (raw1 != null && raw1 == raw2) {
      let typeArguments1 = safeGetOwnProperty(t1, dart.typeArguments);
      let typeArguments2 = safeGetOwnProperty(t2, dart.typeArguments);
      let length = typeArguments1.length;
      if (typeArguments2.length == 0) {
        // t2 is the raw form of t1
        return true;
      } else if (length == 0) {
        // t1 is raw, but t2 is not
        return false;
      }
      assert(length == typeArguments2.length);
      for (let i = 0; i < length; ++i) {
        if (!isSubtype(typeArguments1[i], typeArguments2[i])) {
          return false;
        }
      }
      return true;
    }

    // Check superclass.
    if (isClassSubType(t1.__proto__, t2)) return true;

    // Check mixins.
    let mixins = safeGetOwnProperty(t1, dart.mixins);
    if (mixins) {
      for (let m1 of mixins) {
        // TODO(jmesserly): remove the != null check once we can load core libs.
        if (m1 != null && isClassSubType(m1, t2)) return true;
      }
    }

    // Check interfaces.
    let getInterfaces = safeGetOwnProperty(t1, dart.implements);
    if (getInterfaces) {
      for (let i1 of getInterfaces()) {
        // TODO(jmesserly): remove the != null check once we can load core libs.
        if (i1 != null && isClassSubType(i1, t2)) return true;
      }
    }

    return false;
  }

  function closureWrap(obj, type) {
    // TODO(vsm): Remove this once we handle in the checker.
    return obj;
  }
  dart.closureWrap = closureWrap;


  // TODO(jmesserly): this isn't currently used, but it could be if we want
  // `obj is NonGroundType<T,S>` to be rejected at runtime instead of compile
  // time. Also TODO: update this to handle functions.
  function isGroundType(type) {
    let typeArgs = safeGetOwnProperty(type, dart.typeArguments);
    if (!typeArgs) return true;
    for (let t of typeArgs) {
      if (t != core.Object && t != dart.dynamic) return false;
    }
    return true;
  }
  dart.isGroundType = isGroundType;

  function arity(f) {
    // TODO(jmesserly): need to parse optional params.
    // In ES6, length is the number of required arguments.
    return { min: f.length, max: f.length };
  }
  dart.arity = arity;

  function equals(x, y) {
    if (x == null || y == null) return x == y;
    let eq = x['=='];
    return eq ? eq.call(x, y) : x == y;
  }
  dart.equals = equals;

  /** Checks that `x` is not null or undefined. */
  function notNull(x) {
    if (x == null) throw 'expected not-null value';
    return x;
  }
  dart.notNull = notNull;

  /**
   * Defines a lazy property.
   * After initial get or set, it will replace itself with a value property.
   */
  // TODO(jmesserly): is this the best implementation for JS engines?
  // TODO(jmesserly): reusing descriptor objects has been shown to improve
  // performance in other projects (e.g. webcomponents.js ShadowDOM polyfill).
  function defineLazyProperty(to, name, desc) {
    let init = desc.get;
    let writable = !!desc.set;
    function lazySetter(value) {
      defineProperty(to, name, { value: value, writable: writable });
    }
    function lazyGetter() {
      // Clear the init function to detect circular initialization.
      let f = init;
      if (f === null) throw 'circular initialization for field ' + name;
      init = null;

      // Compute and store the value.
      let value = f();
      lazySetter(value);
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (writable) desc.set = lazySetter;
    defineProperty(to, name, desc);
  }

  function defineLazy(to, from) {
    let names = getOwnPropertyNames(from);
    for (let i = 0; i < names.length; i++) {
      let name = names[i];
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  // TODO(jmesserly): these are identical, but this makes it easier to grep for.
  dart.defineLazyClass = defineLazy;
  dart.defineLazyProperties = defineLazy;
  dart.defineLazyClassGeneric = defineLazyProperty;

  /**
   * Copy properties from source to destination object.
   * This operation is commonly called `mixin` in JS.
   */
  function copyProperties(to, from) {
    let names = getOwnPropertyNames(from);
    for (let i = 0; i < names.length; i++) {
      let name = names[i];
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
    return to;
  }
  dart.copyProperties = copyProperties;


  /** The Symbol for storing type arguments on a specialized generic type. */
  dart.mixins = Symbol('mixins');
  dart.implements = Symbol('implements');

  /**
   * Returns a new type that mixes members from base and all mixins.
   *
   * Each mixin applies in sequence, with further to the right ones overriding
   * previous entries.
   *
   * For each mixin, we only take its own properties, not anything from its
   * superclass (prototype).
   */
  function mixin(base/*, ...mixins*/) {
    // Create an initializer for the mixin, so when derived constructor calls
    // super, we can correctly initialize base and mixins.
    let mixins = Array.prototype.slice.call(arguments, 1);

    // Create a class that will hold all of the mixin methods.
    class Mixin extends base {
      // Initializer method: run mixin initializers, then the base.
      [base.name](/*...args*/) {
        // Run mixin initializers. They cannot have arguments.
        // Run them backwards so most-derived mixin is initialized first.
        for (let i = mixins.length - 1; i >= 0; i--) {
          let mixin = mixins[i];
          let init = mixin.prototype[mixin.name];
          if (init) init.call(this);
        }
        // Run base initializer.
        let init = base.prototype[base.name];
        if (init) init.apply(this, arguments);
      }
    }
    // Copy each mixin's methods, with later ones overwriting earlier entries.
    for (let m of mixins) {
      copyProperties(Mixin.prototype, m.prototype);
    }
    // Save mixins for reflection
    Mixin[dart.mixins] = mixins;
    return Mixin;
  }
  dart.mixin = mixin;

  /**
   * Creates a dart:collection LinkedHashMap.
   *
   * For a map with string keys an object literal can be used, for example
   * `map({'hi': 1, 'there': 2})`.
   *
   * Otherwise an array should be used, for example `map([1, 2, 3, 4])` will
   * create a map with keys [1, 3] and values [2, 4]. Each key-value pair
   * should be adjacent entries in the array.
   *
   * For a map with no keys the function can be called with no arguments, for
   * example `map()`.
   */
  // TODO(jmesserly): this could be faster
  function map(values) {
    let map = new collection.LinkedHashMap();
    if (Array.isArray(values)) {
      for (let i = 0, end = values.length - 1; i < end; i += 2) {
        let key = values[i];
        let value = values[i + 1];
        map.set(key, value);
      }
    } else if (typeof values === 'object') {
      for (let key of Object.getOwnPropertyNames(values)) {
        map.set(key, values[key]);
      }
    }
    return map;
  }
  dart.map = map;

  function assert(condition) {
    // TODO(jmesserly): throw assertion error.
    if (!condition) throw 'assertion failed';
  }
  dart.assert = assert;

  function throw_(obj) { throw obj; }
  dart.throw_ = throw_;

  /**
   * Given a class and an initializer method name, creates a constructor
   * function with the same name. For example `new SomeClass.name(args)`.
   */
  function defineNamedConstructor(clazz, name) {
    let proto = clazz.prototype;
    let initMethod = proto[name];
    let ctor = function() { return initMethod.apply(this, arguments); }
    ctor.prototype = proto;
    clazz[name] = ctor;
  }
  dart.defineNamedConstructor = defineNamedConstructor;

  function stackTrace(exception) {
    throw new core.UnimplementedError();
  }
  dart.stackTrace = stackTrace;

  /** The Symbol for storing type arguments on a specialized generic type. */
  dart.typeArguments = Symbol('typeArguments');
  dart.originalDeclaration = Symbol('originalDeclaration');

  /** Memoize a generic type constructor function. */
  function generic(typeConstructor) {
    let length = typeConstructor.length;
    if (length < 1) throw Error('must have at least one generic type argument');

    let resultMap = new Map();
    function makeGenericType(/*...arguments*/) {
      if (arguments.length != length && arguments.length != 0) {
        throw Error('requires ' + length + ' or 0 type arguments');
      }
      let args = Array.prototype.slice.call(arguments);
      while (args.length < length) args.push(dart.dynamic);

      let value = resultMap;
      for (let i = 0; i < length; i++) {
        let arg = args[i];
        if (arg == null) {
          throw Error('type arguments should not be null: ' + typeConstructor);
        }
        let map = value;
        value = map.get(arg);
        if (value === void 0) {
          if (i + 1 == length) {
            value = typeConstructor.apply(null, args);
            // Save the type constructor and arguments for reflection.
            if (value) {
              value[dart.typeArguments] = args;
              value[dart.originalDeclaration] = makeGenericType;
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
  dart.generic = generic;

  // TODO(jmesserly): right now this is a sentinel. It should be a type object
  // of some sort, assuming we keep around `dynamic` at runtime.
  dart.dynamic = { toString() { return 'dynamic'; } };

  dart.JsSymbol = Symbol;

  // TODO(jmesserly): hack to bootstrap the SDK
  _js_helper = _js_helper || {};
  _js_helper.checkNum = notNull;

})(dart || (dart = {}));
