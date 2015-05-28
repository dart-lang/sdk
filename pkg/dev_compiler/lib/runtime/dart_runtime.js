// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var dart, _js_helper, _js_primitives;
(function (dart) {
  'use strict';

  // TODO(vsm): This is referenced (as init.globalState) from
  // isolate_helper.dart.  Where should it go?
  // See: https://github.com/dart-lang/dev_compiler/issues/164
  dart.globalState = null;

  let defineProperty = Object.defineProperty;
  let getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  let getOwnPropertyNames = Object.getOwnPropertyNames;
  let getOwnPropertySymbols = Object.getOwnPropertySymbols;

  function getOwnNamesAndSymbols(obj) {
    return getOwnPropertyNames(obj).concat(getOwnPropertySymbols(obj));
  }

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
    for (let arg of r) {
      arg.replace(FN_ARG, function(all, underscore, name){
        args.push(name);
      });
    }
    return args;
  }

  function dload(obj, field) {
    field = _canonicalFieldName(obj, field);
    if (_getMethodType(obj, field) !== void 0) {
      return dart.bind(obj, field);
    }
    // TODO(vsm): Implement NSM robustly.  An 'in' check breaks on certain
    // types.  hasOwnProperty doesn't chase the proto chain.
    // Also, do we want an NSM on regular JS objects?
    // See: https://github.com/dart-lang/dev_compiler/issues/169
    var result = obj[field];

    // TODO(leafp): Decide whether to keep this for javascript
    // objects, or just use the javascript semantics.
    if (typeof result == "function" &&
        !Object.prototype.hasOwnProperty.call(obj, field)) {
      // This appears to be a method tearoff.  Bind this.
      return result.bind(obj);
    }
    return result;
  }
  dart.dload = dload;

  function dput(obj, field, value) {
    field = _canonicalFieldName(obj, field);
    // TODO(vsm): Implement NSM and type checks.
    // See: https://github.com/dart-lang/dev_compiler/issues/170
    obj[field] = value;
  }
  dart.dput = dput;

  // TODO(jmesserly): this should call noSuchMethod, not throw.
  function throwNoSuchMethod(obj, name, args, opt_func) {
    if (obj === void 0) obj = opt_func;
    throw new core.NoSuchMethodError(obj, name, args);
  }

  function checkAndCall(f, ftype, obj, args, name) {
    if (!(f instanceof Function)) {
      // We're not a function (and hence not a method either)
      // Grab the `call` method if it's not a function.
      if (f !== null) {
        ftype = _getMethodType(f, 'call');
        f = f.call;
      }
      if (!(f instanceof Function)) {
        throwNoSuchMethod(obj, name, args);
      }
    }
    // If f is a function, but not a method (no method type)
    // then it should have been a function valued field, so
    // get the type from the function.
    if (ftype === void 0) {
      ftype = _getFunctionType(f);
    }

    if (!ftype) {
      // TODO(leafp): Allow JS objects to go through?
      // This includes the DOM.
      return f.apply(obj, args);
    }

    if (ftype.checkApply(args)) {
      return f.apply(obj, args);
    }

    // TODO(leafp): throw a type error (rather than NSM)
    // if the arity matches but the types are wrong.
    throwNoSuchMethod(obj, name, args, f);
  }

  function dcall(f/*, ...args*/) {
    let args = Array.prototype.slice.call(arguments, 1);
    let ftype = _getFunctionType(f);
    return checkAndCall(f, ftype, void 0, args, 'call');
  }
  dart.dcall = dcall;

  // TODO(vsm): Automatically build this.
  // All dynamic methods should check for these.
  // See: https://github.com/dart-lang/dev_compiler/issues/142
  var _extensionMethods = {
    // Lazy - as these symbols may not be loaded yet.
    // TODO(vsm): This should record / check the receiver type
    // as well.  E.g., only look for core.$map if the receiver
    // is an Iterable.
    'map': () => core.$map,
  };

  // TODO(leafp): Integrate this with the eventual proper extension
  // method system.
  function _canonicalFieldName(obj, name) {
    if (obj[name] === void 0) return _extensionMethods[name]();
    return name;
  }

  function dsend(obj, method/*, ...args*/) {
    let args = Array.prototype.slice.call(arguments, 2);
    let symbol = _canonicalFieldName(obj, method);
    let f = obj[symbol];
    let ftype = _getMethodType(obj, symbol);
    return checkAndCall(f, ftype, obj, args, method);
  }
  dart.dsend = dsend;

  function dindex(obj, index) {
    // TODO(jmesserly): remove this special case once Array extensions are
    // hooked up.
    if (obj instanceof Array && realRuntimeType(index) == core.int) {
      return obj[index];
    }
    return checkAndCall(obj.get, obj, [index], '[]');
  }
  dart.dindex = dindex;

  function dsetindex(obj, index, value) {
    return checkAndCall(obj.set, obj, [index, value], '[]=');
  }
  dart.dsetindex = dsetindex;

  function typeToString(type) {
    if (typeof(type) == "function") {
      var name = type.name;
      var args = type[dart.typeArguments];
      if (args) {
        name += '<';
        for (var i = 0; i < args.length; ++i) {
          if (i > 0) name += ', ';
          name += typeToString(args[i]);
        }
        name += '>';
      }
      return name;
    } else {
      return type.toString();
    }
  }
  dart.typeName = typeToString;

  function cast(obj, type) {
    // TODO(vsm): handle non-nullable types
    if (obj == null) return obj;
    let actual = realRuntimeType(obj);
    if (isSubtype(actual, type)) return obj;
    // TODO(vsm): Remove this hack ... due to
    // lack of generic methods.
    if (isSubtype(type, core.Iterable) && isSubtype(actual, core.Iterable) ||
        isSubtype(type, async.Future) && isSubtype(actual, async.Future) ||
        isSubtype(type, core.Map) && isSubtype(actual, core.Map)) {
      console.log('Warning: ignoring cast fail from ' + typeToString(actual) + ' to ' + typeToString(type));
      return obj;
    }
    // console.log('Error: cast fail from ' + typeToString(actual) + ' to ' + typeToString(type));
    throw new _js_helper.CastErrorImplementation(actual, type);
  }
  dart.as = cast;


  // TODO(vsm): How should we encode the runtime type?
  let _runtimeType = Symbol('_runtimeType');

  function checkPrimitiveType(obj) {
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
    return null;
  }

  /**
   * Returns the runtime type of obj. This is the same as `obj.realRuntimeType`
   * but will not call an overridden getter.
   *
   * Currently this will return null for non-Dart objects.
   */
  function realRuntimeType(obj) {
    var result = checkPrimitiveType(obj);
    if (result !== null) return result;
    // TODO(vsm): Should we treat Dart and JS objects differently here?
    // E.g., we can check if obj instanceof core.Object to differentiate.
    result = obj[_runtimeType];
    if (result) return result;
    result = obj.constructor;
    if (result == Function) {
      return getFunctionType(obj);
    }
    return result;
  }
  dart.realRuntimeType = realRuntimeType;

  function instanceOf(obj, type) {
    return isSubtype(realRuntimeType(obj), type);
  }
  dart.is = instanceOf;

  function instanceOfOrNull(obj, type) {
    return (obj == null) || instanceOf(obj, type);
  }

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
    if (t2 == core.Type) {
      // Special case Types.
      result = t1.prototype instanceof core.Type ||
        t1 instanceof AbstractFunctionType ||
        isSubtype_(t1, t2);
    } else {
      result = isSubtype_(t1, t2)
    }
    map.set(t2, result);
    return result;
  }
  dart.isSubtype = isSubtype;

  function _isBottom(type, dynamicIsBottom) {
    return (type == dart.dynamic && dynamicIsBottom) || type == dart.bottom;
  }

  function _isTop(type, dynamicIsBottom) {
    return type == core.Object || (type == dart.dynamic && !dynamicIsBottom);
  }

  function isSubtype_(t1, t2, opt_dynamicIsBottom) {
    let dynamicIsBottom =
      opt_dynamicIsBottom === void 0 ? false : opt_dynamicIsBottom;

    t1 = canonicalType(t1);
    t2 = canonicalType(t2);
    if (t1 == t2) return true;

    // In Dart, dynamic is effectively both top and bottom.
    // Here, we treat dynamic as one or the other depending on context,
    // but not both.

    // Trivially true.
    if (_isTop(t2, dynamicIsBottom) || _isBottom(t1, dynamicIsBottom)) {
      return true;
    }

    // Trivially false.
    if (_isTop(t1, dynamicIsBottom) || _isBottom(t2, dynamicIsBottom)) {
      return false;
    }

    // "Traditional" name-based subtype check.
    if (isClassSubType(t1, t2)) {
      return true;
    }

    // Function subtyping.
    // TODO(vsm): Handle Objects with call methods.  Those are functions
    // even if they do not *nominally* subtype core.Function.
    if (isFunctionType(t1) &&
        isFunctionType(t2)) {
      return isFunctionSubType(t1, t2);
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
    t1 = canonicalType(t1);
    assert(t2 == canonicalType(t2));
    if (t1 == t2) return true;

    if (t1 == core.Object) return false;

    // If t1 is a JS Object, we may not hit core.Object.
    if (t1 == null) return t2 == core.Object || t2 == dart.dynamic;

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

  // TODO(jmesserly): this isn't currently used, but it could be if we want
  // `obj is NonGroundType<T,S>` to be rejected at runtime instead of compile
  // time.
  function isGroundType(type) {
    // TODO(vsm): Cache this if we start using it at runtime.

    if (type instanceof AbstractFunctionType) {
      if (!_isTop(type.returnType, false)) return false;
      for (let i = 0; i < type.args.length; ++i) {
        if (!_isBottom(type.args[i], true)) return false;
      }
      for (let i = 0; i < type.optionals.length; ++i) {
        if (!_isBottom(type.optionals[i], true)) return false;
      }
      var names = getOwnPropertyNames(type.named);
      for (let i = 0; i < names.length; ++i) {
        if (!_isBottom(type.named[names[i]], true)) return false;
      }
      return true;
    }

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

  function _typeName(type) {
    if (type === void 0) throw "Undefined type";
    var name = type.name;
    if (!name) throw 'Unexpected type: ' + type;
    return name;
  }

  class AbstractFunctionType {
    constructor() {
      this._stringValue = null;
    }

    /// Check that a function of this type can be applied to 
    /// actuals.
    checkApply(actuals) {
      if (actuals.length < this.args.length) return false;
      var index = 0;
      for(let i = 0; i < this.args.length; ++i) {
        if (!instanceOfOrNull(actuals[i], this.args[i])) return false;
        ++index;
      }
      if (actuals.length == this.args.length) return true;
      let extras = actuals.length - this.args.length;
      if (this.optionals.length > 0) {
        if (extras > this.optionals.length) return false;
        for(let i = 0, j=index; i < extras; ++i, ++j) {
          if (!instanceOfOrNull(actuals[j], this.optionals[i])) return false;
        }
        return true;
      }
      // TODO(leafp): We can't tell when someone might be calling
      // something expecting an optional argument with named arguments

      if (extras != 1) return false;
      // An empty named list means no named arguments
      if (getOwnPropertyNames(this.named).length == 0) return false;
      let opts = actuals[index];
      let names = getOwnPropertyNames(opts);
      // This is something other than a map
      if (names.length == 0) return false;
      for (name of names) {
        if (!(Object.prototype.hasOwnProperty.call(this.named, name))) {
          return false;
        }
        if (!instanceOfOrNull(opts[name], this.named[name])) return false;
      }
      return true;
    }

    get name() {
      if (this._stringValue) return this._stringValue;

      var buffer = '(';
      for (let i = 0; i < this.args.length; ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += _typeName(this.args[i]);
      }
      if (this.optionals.length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '[';
        for (let i = 0; i < this.optionals.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += _typeName(this.optionals[i]);
        }
        buffer += ']';
      } else if (Object.keys(this.named).length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '{';
        let names = getOwnPropertyNames(this.named).sort();
        for (let i = 0; i < names.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += names[i] + ': ' + _typeName(this.named[names[i]]);
        }
        buffer += '}';
      }

      buffer += ') -> ' + _typeName(this.returnType);
      this._stringValue = buffer;
      return buffer;
    }
  }

  class FunctionType extends AbstractFunctionType {
    constructor(returnType, args, optionals, named) {
      super();
      this.returnType = returnType;
      this.args = args;
      this.optionals = optionals;
      this.named = named;
    }
  }

  /// Tag a closure with a type, using one of three forms:
  /// dart.fn(cls) marks cls has having no optional or named
  ///  parameters, with all argument and return types as dynamic
  /// dart.fn(cls, func) marks cls with the lazily computed
  ///  runtime type as computed by func()
  /// dart.fn(cls, rType, argsT, extras) marks cls as having the
  ///  runtime type dart.functionType(rType, argsT, extras)
  function fn(closure/* ...args*/) {
    // Closure and a lazy type constructor
    if (arguments.length == 2) {
      defineLazyProperty(closure, _runtimeType, {get : arguments[1]});
      return closure;
    }
    var t;
    if (arguments.length == 1) {
      // No type arguments, it's all dynamic
      let len = closure.length;
      function build() {
        let args = Array.apply(null, new Array(len)).map(() => core.Object);
        return functionType(core.Object, args);
      }
      // We could be called before Object is defined.
      if (core.Object === void 0) return fn(closure, build);
      t = build();
    } else {
      // We're passed the piecewise components of the function type,
      // construct it.
      let args = Array.prototype.slice.call(arguments, 1);
      t = functionType.apply(null, args);
    }
    setRuntimeType(closure, t);
    return closure;
  }
  dart.fn = fn;

  function functionType(returnType, args, extra) {
    // TODO(vsm): Cache / memomize?
    var optionals;
    var named;
    if (extra === void 0) {
      optionals = [];
      named = {};
    } else if (extra instanceof Array) {
      optionals = extra;
      named = {};
    } else {
      optionals = [];
      named = extra;
    }
    return new FunctionType(returnType, args, optionals, named);
  }
  dart.functionType = functionType;

  class Typedef extends AbstractFunctionType {
    constructor(name, closure) {
      super();
      this._name = name;
      this._closure = closure;
      this._functionType = null;
    }

    get name() {
      return this._name;
    }

    get functionType() {
      if (!this._functionType) {
        this._functionType = this._closure();
      }
      return this._functionType;
    }

    get returnType() {
      return this.functionType.returnType;
    }

    get args() {
      return this.functionType.args;
    }

    get optionals() {
      return this.functionType.optionals;
    }

    get named() {
      return this.functionType.named;
    }
  }

  function typedef(name, closure) {
    return new Typedef(name, closure);
  }
  dart.typedef = typedef;

  function isFunctionType(type) {
    return isClassSubType(type, core.Function) ||
        type instanceof AbstractFunctionType;
  }

  function getFunctionType(obj) {
    // TODO(vsm): Encode this properly on the function for Dart-generated code.
    var args = Array.apply(null, new Array(obj.length)).map(() => core.Object);
    return functionType(dart.bottom, args);
  }

  function isFunctionSubType(ft1, ft2) {
    if (ft2 == core.Function) {
      return true;
    }

    let ret1 = ft1.returnType;
    let ret2 = ft2.returnType;

    if (!isSubtype_(ret1, ret2)) {
      // Covariant return types
      // Note, void (which can only appear as a return type) is effectively
      // treated as dynamic.  If the base return type is void, we allow any
      // subtype return type.
      // E.g., we allow:
      //   () -> int <: () -> void
      if (ret2 != dart.void) {
        return false;
      }
    }

    let args1 = ft1.args;
    let args2 = ft2.args;

    if (args1.length > args2.length) {
      return false;
    }

    for (let i = 0; i < args1.length; ++i) {
      if (!isSubtype_(args2[i], args1[i], true)) {
        return false;
      }
    }

    let optionals1 = ft1.optionals;
    let optionals2 = ft2.optionals;

    if (args1.length + optionals1.length < args2.length + optionals2.length) {
      return false;
    }

    var j = 0;
    for (let i = args1.length; i < args2.length; ++i, ++j) {
      if (!isSubtype_(args2[i], optionals1[j], true)) {
        return false;
      }
    }

    for (let i = 0; i < optionals2.length; ++i, ++j) {
      if (!isSubtype_(optionals2[i], optionals1[j], true)) {
        return false;
      }
    }

    let named1 = ft1.named;
    let named2 = ft2.named;

    let names = getOwnPropertyNames(named2);
    for (let i = 0; i < names.length; ++i) {
      let name = names[i];
      let n1 = named1[name];
      let n2 = named2[name];
      if (n1 === void 0) {
        return false;
      }
      if (!isSubtype_(n2, n1, true)) {
        return false;
      }
    }

    return true;
  }

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
    for (let name of getOwnNamesAndSymbols(from)) {
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  // TODO(jmesserly): these are identical, but this makes it easier to grep for.
  dart.defineLazyClass = defineLazy;
  dart.defineLazyProperties = defineLazy;
  dart.defineLazyClassGeneric = defineLazyProperty;

  function defineMemoizedGetter(obj, name, get) {
    let cache = null;
    function getter() {
      if (cache != null) return cache;
      cache = get();
      get = null;
      return cache;
    }
    defineProperty(obj, name, {get : getter});
  }

  function copyPropertiesHelper(to, from, names) {
    for (let name of names) {
      defineProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
    return to;
  }

  /**
   * Copy properties from source to destination object.
   * This operation is commonly called `mixin` in JS.
   */
  function copyProperties(to, from) {
    return copyPropertiesHelper(to, from, getOwnNamesAndSymbols(from));
  }
  dart.copyProperties = copyProperties;

  /**
   * Copy symbols from the prototype of the source to destination.
   * These are the only properties safe to copy onto an existing public
   * JavaScript class.
   */
  function registerExtension(to, from) {
    return copyPropertiesHelper(to.prototype, from.prototype,
        getOwnPropertySymbols(from.prototype));
  }
  dart.registerExtension = registerExtension;

  function setBaseClass(derived, base) {
    // Link the extension to the type it's extending as a base class.
    derived.prototype.__proto__ = base.prototype;
  }
  dart.setBaseClass = setBaseClass;

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
  dart.virtualField = virtualField;

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

    // Set the signature of the Mixin class to be the composition
    // of the signatures of the mixins.
    dart.setSignature(Mixin, {
      methods : () => {
        let s = {};
        for (let m of mixins) {
          copyProperties(s, m[_methodSig]);
        }
        return s;
      }
    });

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
      for (let key of getOwnPropertyNames(values)) {
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
    // Use defineProperty so we don't hit a property defined on Function,
    // like `caller` and `arguments`.
    defineProperty(clazz, name, { value: ctor, configurable: true });
  }
  dart.defineNamedConstructor = defineNamedConstructor;

  function stackTrace(exception) {
    return _js_helper.getTraceFromException(exception);
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
      // TODO(leafp): This should really be core.Object for
      // consistency, but Object is not attached to core
      // until the entire core library has been processed,
      // which is too late.
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

  let _constructorSig = Symbol('sigCtor');
  let _methodSig = Symbol("sig");
  let _staticSig = Symbol("sigStatic");

  /// Get the type of a function using the store runtime type
  function _getFunctionType(f) {
    return f[_runtimeType];
  }

  /// Get the type of a method using the stored signature
  function _getMethodType(obj, name) {
    if (obj === void 0) return void 0;
    if (obj == null) return void 0;
    let sigObj = obj.__proto__.constructor[_methodSig];
    if (sigObj === void 0) return void 0;
    let parts = sigObj[name];
    if (parts === void 0) return void 0;
    let sig = functionType.apply(null, parts);
    return sig;
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
    let sig = functionType.apply(null, parts);
    return sig;
  }
  dart.classGetConstructorType = _getConstructorType;

  /// Given an object and a method name, tear off the method.
  /// Sets the runtime type of the torn off method appropriately,
  /// and also binds the object.
  /// TODO(leafp): Consider caching the tearoff on the object?
  function bind(obj, name) {
    let f = obj[name].bind(obj);
    let sig = _getMethodType(obj, name)
    assert(sig);
    setRuntimeType(f, sig);
    return f;
  }
  dart.bind = bind;

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
      function getT() {
        let parts = f[_staticSig][name];
        return functionType.apply(null, parts);
      };
      defineProperty(f[name], _runtimeType, {get : getT});
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
  };
  dart.setSignature = setSignature;

  let _value = Symbol('_value');
  /**
   * Looks up a sequence of [keys] in [map], recursively, and
   * returns the result. If the value is not found, [valueFn] will be called to
   * add it. For example:
   *
   *     var map = new Map();
   *     putIfAbsent(map, [1, 2, 'hi ', 'there '], () => 'world');
   *
   * ... will create a Map with a structure like:
   *
   *     { 1: { 2: { 'hi ': { 'there ': 'world' } } } }
   */
  function multiKeyPutIfAbsent(map, keys, valueFn) {
    for (let k of keys) {
      let value = map.get(k);
      if (!value) {
        // TODO(jmesserly): most of these maps are very small (e.g. 1 item),
        // so it may be worth optimizing for that.
        map.set(k, value = new Map());
      }
      map = value;
    }
    if (map.has(_value)) return map.get(_value);
    let value = valueFn();
    map.set(_value, value);
    return value;
  }

  /** The global constant table. */
  let constants = new Map();

  /**
   * Canonicalize a constant object.
   *
   * Preconditions:
   * - `obj` is an objects or array, not a primitive.
   * - nested values of the object are themselves already canonicalized.
   */
  function constant(obj) {
    let objectKey = [realRuntimeType(obj)];
    // There's no guarantee in JS that names/symbols are returned in the same
    // order. We could probably get the same order if we're judicious about
    // initializing them, but easier to not depend on that.
    for (let name of getOwnNamesAndSymbols(obj)) {
      // TODO(jmesserly): we can make this faster if needed.
      objectKey.push(name);
      objectKey.push(obj[name]);
    }
    return multiKeyPutIfAbsent(constants, objectKey, () => obj);
  }
  dart.const = constant;

  // TODO(vsm): Rationalize these type methods.  We're currently using the
  // setType / proto scheme for nominal types (e.g., classes) and the
  // setRuntimeType / field scheme for structural types (e.g., functions
  // - and only in tests for now).
  // See: https://github.com/dart-lang/dev_compiler/issues/172

  /** Sets the type of `obj` to be `type` */
  function setType(obj, type) {
    obj.__proto__ = type.prototype;
    return obj;
  }
  dart.setType = setType;

  /** Sets the internal runtime type of `obj` to be `type` */
  function setRuntimeType(obj, type) {
    obj[_runtimeType] = type;
  }
  dart.setRuntimeType = setRuntimeType;

  // The following are helpers for Object methods when the receiver
  // may be null or primitive.  These should only be generated by
  // the compiler.
  function hashCode(obj) {
    if (obj == null) {
      return 0;
    }
    // TODO(vsm): What should we do for primitives and non-Dart objects?
    switch (typeof obj) {
      case "number":
      case "boolean":
        return obj & 0x1FFFFFFF;
      case "string":
        // TODO(vsm): Call the JSString hashCode?
        return obj.length;
    }
    return obj.hashCode;
  }
  dart.hashCode = hashCode;

  function runtimeType(obj) {
    var result = checkPrimitiveType(obj);
    if (result !== null) return result;
    return obj.runtimeType;
  }
  dart.runtimeType = runtimeType;

  function toString(obj) {
    if (obj == null) {
      return "null";
    }
    return obj.toString();
  }
  dart.toString = toString;

  function noSuchMethod(obj, invocation) {
    if (obj == null) {
      throw new core.NoSuchMethodError(obj, invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments);
    }
    switch (typeof obj) {
      case "number":
      case "boolean":
      case "string":
        throw new core.NoSuchMethodError(obj, invocation.memberName,
          invocation.positionalArguments, invocation.namedArguments);
    }
    return obj.noSuchMethod(invocation);
  }
  dart.noSuchMethod = noSuchMethod;

  class JsIterator {
    constructor(dartIterator) {
      this.dartIterator = dartIterator;
    }
    next() {
      let i = this.dartIterator;
      var done = !i.moveNext();
      return { done: done, value: done ? void 0 : i.current };
    }
  }
  dart.JsIterator = JsIterator;

  // TODO(jmesserly): right now this is a sentinel. It should be a type object
  // of some sort, assuming we keep around `dynamic` at runtime.
  dart.dynamic = { toString() { return 'dynamic'; }, get name() {return toString();}};
  dart.void = { toString() { return 'void'; }, get name() {return toString();}};
  dart.bottom = { toString() { return 'bottom'; }, get name() {return toString();}};

  dart.global = window || global;
  dart.JsSymbol = Symbol;

  function import_(value) {
    // TODO(vsm): Change this to a hard throw.
    // For now, we're missing some libraries.  E.g., dart:js:
    // https://github.com/dart-lang/dev_compiler/issues/168
    if (!value) {
      console.log('missing required module');
    }
    return value;
  }
  dart.import = import_;
  
  function lazyImport(value) {
    return defineLibrary(value, {});
  }
  dart.lazyImport = lazyImport;

  function defineLibrary(value, defaultValue) {
    return value ? value : defaultValue;
  }
  dart.defineLibrary = defineLibrary;

  // TODO(jmesserly): hack to bootstrap the SDK
  _js_helper = _js_helper || {};
  _js_helper.checkNum = notNull;

  _js_primitives = _js_primitives || {};
  _js_primitives.printString = (s) => console.log(s);

  // TODO(vsm): Plumb this correctly.
  // See: https://github.com/dart-lang/dev_compiler/issues/40
  String.prototype.contains = function(sub) { return this.indexOf(sub) >= 0; }
  let _split = String.prototype.split;
  String.prototype.split = function() {
    let result = _split.apply(this, arguments);
    dart.setType(result, core.List$(core.String));
    return result;
  }
  String.prototype.get = function(i) {
    return this[i];
  }
  String.prototype.codeUnitAt = function(i) {
    return this.charCodeAt(i);
  }
  String.prototype.replaceAllMapped =  function(from, cb) {
    return this.replace(from.multiple, function() {
      // Remove offset & string from the result array
      var matches = arguments;
      matches.splice(-2, 2);
      // The callback receives match, p1, ..., pn
      return cb(matches);
    });
  }
  String.prototype['+'] = function(arg) { return this.valueOf() + arg; };

  Boolean.prototype['!'] = function() { return !this.valueOf(); };
  Boolean.prototype['&&'] = function(arg) { return this.valueOf() && arg; };
  Boolean.prototype['||'] = function(arg) { return this.valueOf() || arg; };
  Number.prototype['<'] = function(arg) { return this.valueOf() < arg; };
  Number.prototype['<='] = function(arg) { return this.valueOf() <= arg; };
  Number.prototype['>'] = function(arg) { return this.valueOf() > arg; };
  Number.prototype['+'] = function(arg) { return this.valueOf() + arg; };

  // TODO(vsm): DOM facades?
  // See: https://github.com/dart-lang/dev_compiler/issues/173
  NodeList.prototype.get = function(i) { return this[i]; };
  NamedNodeMap.prototype.get = function(i) { return this[i]; };
  DOMTokenList.prototype.get = function(i) { return this[i]; };

})(dart || (dart = {}));
