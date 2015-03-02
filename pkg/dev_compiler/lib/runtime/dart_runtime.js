// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var dart;
(function (dart) {
  var defineProperty = Object.defineProperty;
  var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  var getOwnPropertyNames = Object.getOwnPropertyNames;

  // Adapted from Angular.js
  var FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m;
  var FN_ARG_SPLIT = /,/;
  var FN_ARG = /^\s*(_?)(\S+?)\1\s*$/;
  var STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg;

  function formalParameterList(fn) {
    var fnText,argDecl;
    var args=[];
    fnText = fn.toString().replace(STRIP_COMMENTS, '');
    argDecl = fnText.match(FN_ARGS);

    var r = argDecl[1].split(FN_ARG_SPLIT);
    for(var a in r){
      var arg = r[a];
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
    var formals = formalParameterList(f);
    // TODO(vsm): Type check args!  We need to encode sufficient type info on f.
    if (formals.length < args.length) {
      throwNoSuchMethod(obj, name, args, f);
    } else if (formals.length > args.length) {
      for (var i = args.length; i < formals.length; ++i) {
        if (formals[i].indexOf("opt$") != 0) {
          throwNoSuchMethod(obj, name, args, f);
        }
      }
    }
    return f.apply(obj, args);
  }

  function dinvokef(f/*, ...args*/) {
    var args = Array.prototype.slice.call(arguments, 1);
    return checkAndCall(f, void 0, args, 'call');
  }
  dart.dinvokef = dinvokef;

  function dinvoke(obj, method/*, ...args*/) {
    var args = Array.prototype.slice.call(arguments, 2);
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

  function as_(obj, type) {
    // TODO(vsm): Implement.
    // if (obj == null || is(obj, type)) return obj;
    // throw new core.CastError();
    return obj;
  }
  dart.as = as_;

  function is(obj, type) {
    // TODO(vsm): Implement.
    throw new core.UnimplementedError();
  }
  dart.is = is;

  function isGroundType(type) {
    // TODO(vsm): Implement.
    throw new core.UnimplementedError();
  }
  dart.isGroundType = isGroundType;

  function arity(f) {
    // TODO(vsm): Implement.
    throw new core.UnimplementedError();
  }
  dart.arity = arity;

  function equals(x, y) {
    if (x === null || y === null) return x === y;
    var eq = x['=='];
    return eq ? eq.call(x, y) : x === y;
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
    var init = desc.get;
    var writable = !!desc.set;
    function lazySetter(value) {
      defineProperty(to, name, { value: value, writable: writable });
    }
    function lazyGetter() {
      // Clear the init function to detect circular initialization.
      var f = init;
      if (f === null) throw 'circular initialization for field ' + name;
      init = null;

      // Compute and store the value.
      var value = f();
      lazySetter(value);
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (writable) desc.set = lazySetter;
    defineProperty(to, name, desc);
  }

  function defineLazyProperties(to, from) {
    var names = getOwnPropertyNames(from);
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  dart.defineLazyProperties = defineLazyProperties;

  /**
   * Copy properties from source to destination object.
   * This operation is commonly called `mixin` in JS.
   */
  function copyProperties(to, from) {
    var names = getOwnPropertyNames(from);
    for (var i = 0; i < names.length; i++) {
      var name = names[i];
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
    return to;
  }
  dart.copyProperties = copyProperties;

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
    // Inherit statics from Base to simulate ES6 class inheritance
    // Conceptually this is: `class Mixin extends base {}`
    function Mixin() {
      // TODO(jmesserly): since we're using initializers and not constructors,
      // we can just skip directly to dart.Object.
      dart.Object.apply(this, arguments);
    }
    Mixin.__proto__ = base;
    Mixin.prototype = Object.create(base.prototype);
    Mixin.prototype.constructor = Mixin;
    // Copy each mixin, with later ones overwriting earlier entries.
    var mixins = Array.prototype.slice.call(arguments, 1);
    for (var i = 0; i < mixins.length; i++) {
      copyProperties(Mixin.prototype, mixins[i].prototype);
    }
    // Create an initializer for the mixin, so when derived constructor calls
    // super, we can correctly initialize base and mixins.
    var baseCtor = base.prototype[base.name];
    Mixin.prototype[base.name] = function() {
      // Run mixin initializers. They cannot have arguments.
      // Run them backwards so most-derived mixin is initialized first.
      for (var i = mixins.length - 1; i >= 0; i--) {
        var mixin = mixins[i];
        mixin.prototype[mixin.name].call(this);
      }
      // Run base initializer.
      baseCtor.apply(this, arguments);
    }
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
    var map = new collection.LinkedHashMap();
    if (Array.isArray(values)) {
      for (var i = 0, end = values.length - 1; i < end; i += 2) {
        var key = values[i];
        var value = values[i + 1];
        map.set(key, value);
      }
    } else if (typeof values === 'object') {
      var keys = Object.getOwnPropertyNames(values);
      for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        var value = values[key];
        map.set(key, value);
      }
    }
    return map;
  }

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
    var proto = clazz.prototype;
    var initMethod = proto[clazz.name + '$' + name];
    var ctor = function() { return initMethod.apply(this, arguments); }
    ctor.prototype = proto;
    clazz[name] = ctor;
  }
  dart.defineNamedConstructor = defineNamedConstructor;

  function stackTrace(exception) {
    throw new core.UnimplementedError();
  }
  dart.stackTrace = stackTrace;

  /** The Symbol for storing type arguments on a specialized generic type. */
  dart.typeSignature = Symbol('typeSignature');

  /** Memoize a generic type constructor function. */
  function generic(typeConstructor) {
    var length = typeConstructor.length;
    if (length < 1) throw 'must have at least one generic type argument';

    var resultMap = new Map();
    function makeGenericType(/*...arguments*/) {
      if (arguments.length != length) {
        throw 'requires ' + length + ' type arguments';
      }

      var value = resultMap;
      for (var i = 0; i < length; i++) {
        var arg = arguments[i];
        // TODO(jmesserly): assume `dynamic` here?
        if (arg === void 0) throw 'undefined is not allowed as a type argument';

        var map = value;
        value = map.get(arg);
        if (value === void 0) {
          if (i + 1 == length) {
            value = typeConstructor.apply(null, arguments);
            // Save the type constructor and arguments for reflection.
            if (value) {
              var args = Array.prototype.slice.call(arguments);
              value[dart.typeSignature] = [makeGenericType].concat(args);
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


  /**
   * Implements Dart constructor behavior. Because of V8 `super` [constructor
   * restrictions](https://code.google.com/p/v8/issues/detail?id=3330#c65) we
   * cannot currently emit actual ES6 constructors with super calls. Instead
   * we use the same trick as named constructors, and do them as instance
   * methods that perform initialization.
   */
  // TODO(jmesserly): we'll need to rethink this once the ES6 spec and V8
  // settles. See <https://github.com/dart-lang/dart-dev-compiler/issues/51>.
  // Performance of this pattern is likely to be bad.
  dart.Object = function Object() {
    // Get the class name for this instance.
    var name = this.constructor.name;
    // Call the default constructor.
    var init = this[name];
    var result = void 0;
    if (init) result = init.apply(this, arguments);
    return result === void 0 ? this : result;
  };
  // The initializer for dart.Object
  dart.Object.prototype.Object = function() {};
  dart.Object.prototype.constructor = dart.Object;

})(dart || (dart = {}));
