dart_library.library('dart/_runtime', null, /* Imports */[
], /* Lazy imports */[
  'dart/core',
  'dart/_interceptors',
  'dart/_js_helper',
  'dart/async',
  'dart/collection'
], function(exports, core, _interceptors, _js_helper, async, collection) {
  'use strict';
  function mixin(base, ...mixins) {
    class Mixin extends base {
      [base.name](...args) {
        for (let i = mixins.length - 1; i >= 0; i--) {
          let mixin = mixins[i];
          let init = mixin.prototype[mixin.name];
          if (init) init.call(this);
        }
        let init = base.prototype[base.name];
        if (init) init.apply(this, args);
      }
    }
    for (let m of mixins) {
      copyProperties(Mixin.prototype, m.prototype);
    }
    setSignature(Mixin, {
      methods: () => {
        let s = {};
        for (let m of mixins) {
          copyProperties(s, m[_methodSig]);
        }
        return s;
      }
    });
    Mixin[_mixins] = mixins;
    return Mixin;
  }
  function getMixins(clazz) {
    return clazz[_mixins];
  }
  function getImplements(clazz) {
    return clazz[implements_];
  }
  const _typeArguments = Symbol("typeArguments");
  const _originalDeclaration = Symbol("originalDeclaration");
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
      while (args.length < length)
        args.push(dynamicR);
      let value = resultMap;
      for (let i = 0; i < length; i++) {
        let arg = args[i];
        if (arg == null) {
          throwInternalError('type arguments should not be null: ' + typeConstructor);
        }
        let map = value;
        value = map.get(arg);
        if (value === void 0) {
          if (i + 1 == length) {
            value = typeConstructor.apply(null, args);
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
  function getGenericClass(type) {
    return safeGetOwnProperty(type, _originalDeclaration);
  }
  function getGenericArgs(type) {
    return safeGetOwnProperty(type, _typeArguments);
  }
  const _constructorSig = Symbol("sigCtor");
  const _methodSig = Symbol("sig");
  const _staticSig = Symbol("sigStatic");
  function getMethodType(obj, name) {
    if (obj === void 0) return void 0;
    if (obj == null) return void 0;
    let sigObj = obj.__proto__.constructor[_methodSig];
    if (sigObj === void 0) return void 0;
    let parts = sigObj[name];
    if (parts === void 0) return void 0;
    return definiteFunctionType.apply(null, parts);
  }
  function classGetConstructorType(cls, name) {
    if (!name) name = cls.name;
    if (cls === void 0) return void 0;
    if (cls == null) return void 0;
    let sigCtor = cls[_constructorSig];
    if (sigCtor === void 0) return void 0;
    let parts = sigCtor[name];
    if (parts === void 0) return void 0;
    return definiteFunctionType.apply(null, parts);
  }
  function bind(obj, name, f) {
    if (f === void 0) f = obj[name];
    f = f.bind(obj);
    let sig = getMethodType(obj, name);
    assert_(sig);
    tag(f, sig);
    return f;
  }
  function _setMethodSignature(f, sigF) {
    defineMemoizedGetter(f, _methodSig, () => {
      let sigObj = sigF();
      sigObj.__proto__ = f.__proto__[_methodSig];
      return sigObj;
    });
  }
  function _setConstructorSignature(f, sigF) {
    return defineMemoizedGetter(f, _constructorSig, sigF);
  }
  function _setStaticSignature(f, sigF) {
    return defineMemoizedGetter(f, _staticSig, sigF);
  }
  function _setStaticTypes(f, names) {
    for (let name of names) {
      tagMemoized(f[name], function() {
        let parts = f[_staticSig][name];
        return definiteFunctionType.apply(null, parts);
      });
    }
  }
  function setSignature(f, signature) {
    let constructors = 'constructors' in signature ? signature.constructors : () => ({});
    let methods = 'methods' in signature ? signature.methods : () => ({});
    let statics = 'statics' in signature ? signature.statics : () => ({});
    let names = 'names' in signature ? signature.names : [];
    _setConstructorSignature(f, constructors);
    _setMethodSignature(f, methods);
    _setStaticSignature(f, statics);
    _setStaticTypes(f, names);
    tagMemoized(f, () => core.Type);
  }
  function hasMethod(obj, name) {
    return getMethodType(obj, name) !== void 0;
  }
  function virtualField(subclass, fieldName) {
    let prop = getOwnPropertyDescriptor(subclass.prototype, fieldName);
    if (prop) return;
    let symbol = Symbol(subclass.name + '.' + fieldName);
    defineProperty(subclass.prototype, fieldName, {
      get: function() {
        return this[symbol];
      },
      set: function(x) {
        this[symbol] = x;
      }
    });
  }
  function defineNamedConstructor(clazz, name) {
    let proto = clazz.prototype;
    let initMethod = proto[name];
    let ctor = function() {
      return initMethod.apply(this, arguments);
    };
    ctor.prototype = proto;
    defineProperty(clazz, name, {value: ctor, configurable: true});
  }
  const _extensionType = Symbol("extensionType");
  const dartx = {};
  function getExtensionSymbol(name) {
    let sym = dartx[name];
    if (!sym) dartx[name] = sym = Symbol('dartx.' + name);
    return sym;
  }
  function defineExtensionNames(names) {
    return names.forEach(getExtensionSymbol);
  }
  function registerExtension(jsType, dartExtType) {
    let extProto = dartExtType.prototype;
    let jsProto = jsType.prototype;
    assert_(jsProto[_extensionType] === void 0);
    jsProto[_extensionType] = extProto;
    let dartObjProto = core.Object.prototype;
    while (extProto !== dartObjProto && extProto !== jsProto) {
      copyTheseProperties(jsProto, extProto, getOwnPropertySymbols(extProto));
      extProto = extProto.__proto__;
    }
    let originalSigFn = getOwnPropertyDescriptor(dartExtType, _methodSig).get;
    assert_(originalSigFn);
    defineMemoizedGetter(jsType, _methodSig, originalSigFn);
  }
  function defineExtensionMembers(type, methodNames) {
    let proto = type.prototype;
    for (let name of methodNames) {
      let method = getOwnPropertyDescriptor(proto, name);
      defineProperty(proto, getExtensionSymbol(name), method);
    }
    let originalSigFn = getOwnPropertyDescriptor(type, _methodSig).get;
    defineMemoizedGetter(type, _methodSig, function() {
      let sig = originalSigFn();
      for (let name of methodNames) {
        sig[getExtensionSymbol(name)] = sig[name];
      }
      return sig;
    });
  }
  function canonicalMember(obj, name) {
    if (obj != null && obj[_extensionType]) return dartx[name];
    if (name == 'constructor' || name == 'prototype') {
      name = '+' + name;
    }
    return name;
  }
  function setType(obj, type) {
    obj.__proto__ = type.prototype;
    return obj;
  }
  function list(obj, elementType) {
    return setType(obj, getGenericClass(_interceptors.JSArray)(elementType));
  }
  function setBaseClass(derived, base) {
    derived.prototype.__proto__ = base.prototype;
  }
  function throwCastError(actual, type) {
    throw_(new _js_helper.CastErrorImplementation(actual, type));
  }
  function throwAssertionError() {
    throw_(new core.AssertionError());
  }
  function throwNullValueError() {
    throw_(new core.NoSuchMethodError(null, new core.Symbol('<Unexpected Null Value>'), null, null, null));
  }
  const _jsIterator = Symbol("_jsIterator");
  const _current = Symbol("_current");
  function syncStar(gen, E, ...args) {
    const SyncIterable_E = getGenericClass(_js_helper.SyncIterable)(E);
    return new SyncIterable_E(gen, args);
  }
  function async_(gen, T, ...args) {
    let iter;
    function onValue(res) {
      if (res === void 0) res = null;
      return next(iter.next(res));
    }
    function onError(err) {
      return next(iter.throw(err));
    }
    function next(ret) {
      if (ret.done) return ret.value;
      let future = ret.value;
      if (!instanceOf(future, getGenericClass(async.Future))) {
        future = async.Future.value(future);
      }
      return future.then(onValue, {onError: onError});
    }
    return getGenericClass(async.Future)(T).new(function() {
      iter = gen(...args)[Symbol.iterator]();
      return onValue();
    });
  }
  const _AsyncStarStreamController = class _AsyncStarStreamController {
    constructor(generator, T, args) {
      this.isAdding = false;
      this.isWaiting = false;
      this.isScheduled = false;
      this.isSuspendedAtYield = false;
      this.canceler = null;
      this.iterator = generator(this, ...args)[Symbol.iterator]();
      this.controller = getGenericClass(async.StreamController)(T).new({
        onListen: (() => this.scheduleGenerator()).bind(this),
        onResume: (() => this.onResume()).bind(this),
        onCancel: (() => this.onCancel()).bind(this)
      });
    }
    onResume() {
      if (this.isSuspendedAtYield) {
        this.scheduleGenerator();
      }
    }
    onCancel() {
      if (this.controller.isClosed) {
        return null;
      }
      if (this.canceler == null) {
        this.canceler = async.Completer.new();
        this.scheduleGenerator();
      }
      return this.canceler.future;
    }
    close() {
      if (this.canceler != null && !this.canceler.isCompleted) {
        this.canceler.complete();
      }
      this.controller.close();
    }
    scheduleGenerator() {
      if (this.isScheduled || this.controller.isPaused || this.isAdding || this.isWaiting) {
        return;
      }
      this.isScheduled = true;
      async.scheduleMicrotask((() => this.runBody()).bind(this));
    }
    runBody(opt_awaitValue) {
      this.isScheduled = false;
      this.isSuspendedAtYield = false;
      this.isWaiting = false;
      let iter;
      try {
        iter = this.iterator.next(opt_awaitValue);
      } catch (e) {
        this.addError(e, stackTrace(e));
        this.close();
        return;
      }

      if (iter.done) {
        this.close();
        return;
      }
      if (this.isSuspendedAtYield || this.isAdding) return;
      this.isWaiting = true;
      let future = iter.value;
      if (!instanceOf(future, getGenericClass(async.Future))) {
        future = async.Future.value(future);
      }
      return future.then((x => this.runBody(x)).bind(this), {
        onError: ((e, s) => this.throwError(e, s)).bind(this)
      });
    }
    add(event) {
      if (!this.controller.hasListener) return true;
      this.controller.add(event);
      this.scheduleGenerator();
      this.isSuspendedAtYield = true;
      return false;
    }
    addStream(stream) {
      if (!this.controller.hasListener) return true;
      this.isAdding = true;
      this.controller.addStream(stream, {cancelOnError: false}).then((() => {
        this.isAdding = false;
        this.scheduleGenerator();
      }).bind(this), {
        onError: ((e, s) => this.throwError(e, s)).bind(this)
      });
    }
    throwError(error, stackTrace) {
      try {
        this.iterator.throw(error);
      } catch (e) {
        this.addError(e, stackTrace);
      }

    }
    addError(error, stackTrace) {
      if (this.canceler != null && !this.canceler.isCompleted) {
        this.canceler.completeError(error, stackTrace);
        return;
      }
      if (!this.controller.hasListener) return;
      this.controller.addError(error, stackTrace);
    }
  };
  function asyncStar(gen, T, ...args) {
    return new _AsyncStarStreamController(gen, T, args).controller.stream;
  }
  function _canonicalFieldName(obj, name, args, displayName) {
    name = canonicalMember(obj, name);
    if (name) return name;
    throwNoSuchMethodFunc(obj, displayName, args);
  }
  function dload(obj, field) {
    field = _canonicalFieldName(obj, field, [], field);
    if (hasMethod(obj, field)) {
      return bind(obj, field);
    }
    let result = obj[field];
    return result;
  }
  function dput(obj, field, value) {
    field = _canonicalFieldName(obj, field, [value], field);
    obj[field] = value;
    return value;
  }
  function checkApply(type, actuals) {
    if (actuals.length < type.args.length) return false;
    let index = 0;
    for (let i = 0; i < type.args.length; ++i) {
      if (!instanceOfOrNull(actuals[i], type.args[i])) return false;
      ++index;
    }
    if (actuals.length == type.args.length) return true;
    let extras = actuals.length - type.args.length;
    if (type.optionals.length > 0) {
      if (extras > type.optionals.length) return false;
      for (let i = 0, j = index; i < extras; ++i, ++j) {
        if (!instanceOfOrNull(actuals[j], type.optionals[i])) return false;
      }
      return true;
    }
    if (extras != 1) return false;
    if (getOwnPropertyNames(type.named).length == 0) return false;
    let opts = actuals[index];
    let names = getOwnPropertyNames(opts);
    if (names.length == 0) return false;
    for (var name of names) {
      if (!hasOwnProperty.call(type.named, name)) {
        return false;
      }
      if (!instanceOfOrNull(opts[name], type.named[name])) return false;
    }
    return true;
  }
  function throwNoSuchMethod(obj, name, pArgs, nArgs, extras) {
    throw_(new core.NoSuchMethodError(obj, name, pArgs, nArgs, extras));
  }
  function throwNoSuchMethodFunc(obj, name, pArgs, opt_func) {
    if (obj === void 0) obj = opt_func;
    throwNoSuchMethod(obj, name, pArgs);
  }
  function checkAndCall(f, ftype, obj, args, name) {
    let originalFunction = f;
    if (!(f instanceof Function)) {
      if (f != null) {
        ftype = getMethodType(f, 'call');
        f = f.call;
      }
      if (!(f instanceof Function)) {
        throwNoSuchMethodFunc(obj, name, args, originalFunction);
      }
    }
    if (ftype === void 0) {
      ftype = read(f);
    }
    if (!ftype) {
      return f.apply(obj, args);
    }
    if (checkApply(ftype, args)) {
      return f.apply(obj, args);
    }
    throwNoSuchMethodFunc(obj, name, args, originalFunction);
  }
  function dcall(f, ...args) {
    let ftype = read(f);
    return checkAndCall(f, ftype, void 0, args, 'call');
  }
  function callMethod(obj, name, args, displayName) {
    let symbol = _canonicalFieldName(obj, name, args, displayName);
    let f = obj != null ? obj[symbol] : null;
    let ftype = getMethodType(obj, name);
    return checkAndCall(f, ftype, obj, args, displayName);
  }
  function dsend(obj, method, ...args) {
    return callMethod(obj, method, args, method);
  }
  function dindex(obj, index) {
    return callMethod(obj, 'get', [index], '[]');
  }
  function dsetindex(obj, index, value) {
    callMethod(obj, 'set', [index, value], '[]=');
    return value;
  }
  function _ignoreTypeFailure(actual, type) {
    if (isSubtype(type, core.Iterable) && isSubtype(actual, core.Iterable) || isSubtype(type, async.Future) && isSubtype(actual, async.Future) || isSubtype(type, core.Map) && isSubtype(actual, core.Map) || isSubtype(type, core.Function) && isSubtype(actual, core.Function) || isSubtype(type, async.Stream) && isSubtype(actual, async.Stream) || isSubtype(type, async.StreamSubscription) && isSubtype(actual, async.StreamSubscription)) {
      console.warn('Ignoring cast fail from ' + typeName(actual) + ' to ' + typeName(type));
      return true;
    }
    return false;
  }
  function strongInstanceOf(obj, type, ignoreFromWhiteList) {
    let actual = realRuntimeType(obj);
    if (isSubtype(actual, type) || actual == jsobject) return true;
    if (ignoreFromWhiteList == void 0) return false;
    if (isGroundType(type)) return false;
    if (_ignoreTypeFailure(actual, type)) return true;
    return false;
  }
  function instanceOfOrNull(obj, type) {
    if (obj == null || strongInstanceOf(obj, type, true)) return true;
    return false;
  }
  function instanceOf(obj, type) {
    if (strongInstanceOf(obj, type)) return true;
    if (isGroundType(type)) return false;
    let actual = realRuntimeType(obj);
    throwStrongModeError('Strong mode is check failure: ' + typeName(actual) + ' does not soundly subtype ' + typeName(type));
  }
  function cast(obj, type) {
    if (instanceOfOrNull(obj, type)) return obj;
    let actual = realRuntimeType(obj);
    if (isGroundType(type)) throwCastError(actual, type);
    if (_ignoreTypeFailure(actual, type)) return obj;
    throwStrongModeError('Strong mode cast failure from ' + typeName(actual) + ' to ' + typeName(type));
  }
  function asInt(obj) {
    if (obj == null) {
      return null;
    }
    if (Math.floor(obj) != obj) {
      throwCastError(realRuntimeType(obj), core.int);
    }
    return obj;
  }
  function arity(f) {
    return {min: f.length, max: f.length};
  }
  function equals(x, y) {
    if (x == null || y == null) return x == y;
    let eq = x['=='];
    return eq ? eq.call(x, y) : x === y;
  }
  function notNull(x) {
    if (x == null) throwNullValueError();
    return x;
  }
  function map(values) {
    let map = collection.LinkedHashMap.new();
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
  function assert_(condition) {
    if (!condition) throwAssertionError();
  }
  const _stack = new WeakMap();
  function throw_(obj) {
    if (obj != null && (typeof obj == 'object' || typeof obj == 'function')) {
      _stack.set(obj, new Error());
    }
    throw obj;
  }
  function getError(exception) {
    var stack = _stack.get(exception);
    return stack !== void 0 ? stack : exception;
  }
  function stackPrint(exception) {
    var error = getError(exception);
    console.log(error.stack ? error.stack : 'No stack trace for: ' + error);
  }
  function stackTrace(exception) {
    var error = getError(exception);
    return _js_helper.getTraceFromException(error);
  }
  function nullSafe(obj, ...callbacks) {
    if (obj == null) return obj;
    for (const callback of callbacks) {
      obj = callback(obj);
      if (obj == null) break;
    }
    return obj;
  }
  const _value = Symbol("_value");
  function multiKeyPutIfAbsent(map, keys, valueFn) {
    for (let k of keys) {
      let value = map.get(k);
      if (!value) {
        map.set(k, value = new Map());
      }
      map = value;
    }
    if (map.has(_value)) return map.get(_value);
    let value = valueFn();
    map.set(_value, value);
    return value;
  }
  const constants = new Map();
  function const_(obj) {
    let objectKey = [realRuntimeType(obj)];
    for (let name of getOwnNamesAndSymbols(obj)) {
      objectKey.push(name);
      objectKey.push(obj[name]);
    }
    return multiKeyPutIfAbsent(constants, objectKey, () => obj);
  }
  function hashCode(obj) {
    if (obj == null) {
      return 0;
    }
    switch (typeof obj) {
      case "number":
      case "boolean":
      {
        return obj & 0x1FFFFFFF;
      }
      case "string":
      {
        return obj.length;
      }
    }
    return obj.hashCode;
  }
  function toString(obj) {
    if (obj == null) {
      return "null";
    }
    return obj.toString();
  }
  function noSuchMethod(obj, invocation) {
    if (obj == null) {
      throwNoSuchMethod(obj, invocation.memberName, invocation.positionalArguments, invocation.namedArguments);
    }
    switch (typeof obj) {
      case "number":
      case "boolean":
      case "string":
      {
        throwNoSuchMethod(obj, invocation.memberName, invocation.positionalArguments, invocation.namedArguments);
      }
    }
    return obj.noSuchMethod(invocation);
  }
  const JsIterator = class JsIterator {
    constructor(dartIterator) {
      this.dartIterator = dartIterator;
    }
    next() {
      let i = this.dartIterator;
      let done = !i.moveNext();
      return {done: done, value: done ? void 0 : i.current};
    }
  };
  function fn(closure, ...args) {
    if (args.length == 1) {
      defineLazyProperty(closure, _runtimeType, {get: args[0]});
      return closure;
    }
    let t;
    if (args.length == 0) {
      t = definiteFunctionType(dynamicR, Array(closure.length).fill(dynamicR));
    } else {
      t = definiteFunctionType.apply(null, args);
    }
    tag(closure, t);
    return closure;
  }
  const _runtimeType = Symbol("_runtimeType");
  function checkPrimitiveType(obj) {
    switch (typeof obj) {
      case "undefined":
      {
        return core.Null;
      }
      case "number":
      {
        return Math.floor(obj) == obj ? core.int : core.double;
      }
      case "boolean":
      {
        return core.bool;
      }
      case "string":
      {
        return core.String;
      }
      case "symbol":
      {
        return Symbol;
      }
    }
    if (obj === null) return core.Null;
    return null;
  }
  function runtimeType(obj) {
    let result = checkPrimitiveType(obj);
    if (result !== null) return result;
    return obj.runtimeType;
  }
  function getFunctionType(obj) {
    let args = Array(obj.length).fill(dynamicR);
    return definiteFunctionType(bottom, args);
  }
  function realRuntimeType(obj) {
    let result = checkPrimitiveType(obj);
    if (result !== null) return result;
    result = obj[_runtimeType];
    if (result) return result;
    result = obj.constructor;
    if (result == Function) {
      return jsobject;
    }
    return result;
  }
  function LazyTagged(infoFn) {
    class _Tagged {
      get [_runtimeType]() {
        return infoFn();
      }
    }
    return _Tagged;
  }
  function read(value) {
    return value[_runtimeType];
  }
  function tag(value, info) {
    value[_runtimeType] = info;
  }
  function tagComputed(value, compute) {
    defineProperty(value, _runtimeType, {get: compute});
  }
  function tagMemoized(value, compute) {
    let cache = null;
    function getter() {
      if (compute == null) return cache;
      cache = compute();
      compute = null;
      return cache;
    }
    tagComputed(value, getter);
  }
  const _mixins = Symbol("mixins");
  const implements_ = Symbol("implements");
  const metadata = Symbol("metadata");
  const TypeRep = class TypeRep extends LazyTagged(() => core.Type) {
    get name() {
      return this.toString();
    }
  };
  const Dynamic = class Dynamic extends TypeRep {
    toString() {
      return "dynamic";
    }
  };
  const dynamicR = new Dynamic();
  const Void = class Void extends TypeRep {
    toString() {
      return "void";
    }
  };
  const voidR = new Void();
  const Bottom = class Bottom extends TypeRep {
    toString() {
      return "bottom";
    }
  };
  const bottom = new Bottom();
  const JSObject = class JSObject extends TypeRep {
    toString() {
      return "NativeJavaScriptObject";
    }
  };
  const jsobject = new JSObject();
  const AbstractFunctionType = class AbstractFunctionType extends TypeRep {
    constructor() {
      super();
      this._stringValue = null;
    }
    toString() {
      return this.name;
    }
    get name() {
      if (this._stringValue) return this._stringValue;
      let buffer = '(';
      for (let i = 0; i < this.args.length; ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += typeName(this.args[i]);
      }
      if (this.optionals.length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '[';
        for (let i = 0; i < this.optionals.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += typeName(this.optionals[i]);
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
          buffer += names[i] + ': ' + typeName(this.named[names[i]]);
        }
        buffer += '}';
      }
      buffer += ') -> ' + typeName(this.returnType);
      this._stringValue = buffer;
      return buffer;
    }
  };
  const FunctionType = class FunctionType extends AbstractFunctionType {
    constructor(definite, returnType, args, optionals, named) {
      super();
      this.definite = definite;
      this.returnType = returnType;
      this.args = args;
      this.optionals = optionals;
      this.named = named;
      this.metadata = [];
      function process(array, metadata) {
        var result = [];
        for (var i = 0; i < array.length; ++i) {
          var arg = array[i];
          if (arg instanceof Array) {
            metadata.push(arg.slice(1));
            result.push(arg[0]);
          } else {
            metadata.push([]);
            result.push(arg);
          }
        }
        return result;
      }
      this.args = process(this.args, this.metadata);
      this.optionals = process(this.optionals, this.metadata);
      this._canonize();
    }
    _canonize() {
      if (this.definite) return;
      function replace(a) {
        return a == dynamicR ? bottom : a;
      }
      this.args = this.args.map(replace);
      if (this.optionals.length > 0) {
        this.optionals = this.optionals.map(replace);
      }
      if (Object.keys(this.named).length > 0) {
        let r = {};
        for (let name of getOwnPropertyNames(this.named)) {
          r[name] = replace(this.named[name]);
        }
        this.named = r;
      }
    }
  };
  const Typedef = class Typedef extends AbstractFunctionType {
    constructor(name, closure) {
      super();
      this._name = name;
      this._closure = closure;
      this._functionType = null;
    }
    get definite() {
      return this._functionType.definite;
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
    get metadata() {
      return this.functionType.metadata;
    }
  };
  function _functionType(definite, returnType, args, extra) {
    let optionals;
    let named;
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
    return new FunctionType(definite, returnType, args, optionals, named);
  }
  function functionType(returnType, args, extra) {
    return _functionType(false, returnType, args, extra);
  }
  function definiteFunctionType(returnType, args, extra) {
    return _functionType(true, returnType, args, extra);
  }
  function typedef(name, closure) {
    return new Typedef(name, closure);
  }
  function isDartType(type) {
    return read(type) === core.Type;
  }
  function typeName(type) {
    if (type instanceof TypeRep) return type.toString();
    let tag = read(type);
    if (tag === core.Type) {
      let name = type.name;
      let args = getGenericArgs(type);
      if (args) {
        name += '<';
        for (let i = 0; i < args.length; ++i) {
          if (i > 0) name += ', ';
          name += typeName(args[i]);
        }
        name += '>';
      }
      return name;
    }
    if (tag) return "Not a type: " + tag.name;
    return "JSObject<" + type.name + ">";
  }
  function isFunctionType(type) {
    return type instanceof AbstractFunctionType || type == core.Function;
  }
  function isFunctionSubType(ft1, ft2) {
    if (ft2 == core.Function) {
      return true;
    }
    let ret1 = ft1.returnType;
    let ret2 = ft2.returnType;
    if (!isSubtype_(ret1, ret2)) {
      if (ret2 != voidR) {
        return false;
      }
    }
    let args1 = ft1.args;
    let args2 = ft2.args;
    if (args1.length > args2.length) {
      return false;
    }
    for (let i = 0; i < args1.length; ++i) {
      if (!isSubtype_(args2[i], args1[i])) {
        return false;
      }
    }
    let optionals1 = ft1.optionals;
    let optionals2 = ft2.optionals;
    if (args1.length + optionals1.length < args2.length + optionals2.length) {
      return false;
    }
    let j = 0;
    for (let i = args1.length; i < args2.length; ++i, ++j) {
      if (!isSubtype_(args2[i], optionals1[j])) {
        return false;
      }
    }
    for (let i = 0; i < optionals2.length; ++i, ++j) {
      if (!isSubtype_(optionals2[i], optionals1[j])) {
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
      if (!isSubtype_(n2, n1)) {
        return false;
      }
    }
    return true;
  }
  function canonicalType(t) {
    if (t === Object) return core.Object;
    if (t === Function) return core.Function;
    if (t === Array) return core.List;
    if (t === String) return core.String;
    if (t === Number) return core.double;
    if (t === Boolean) return core.bool;
    return t;
  }
  const subtypeMap = new Map();
  function isSubtype(t1, t2) {
    let map = subtypeMap.get(t1);
    let result;
    if (map) {
      result = map.get(t2);
      if (result !== void 0) return result;
    } else {
      subtypeMap.set(t1, map = new Map());
    }
    result = isSubtype_(t1, t2);
    map.set(t2, result);
    return result;
  }
  function _isBottom(type) {
    return type == bottom;
  }
  function _isTop(type) {
    return type == core.Object || type == dynamicR;
  }
  function isSubtype_(t1, t2) {
    t1 = canonicalType(t1);
    t2 = canonicalType(t2);
    if (t1 == t2) return true;
    if (_isTop(t2) || _isBottom(t1)) {
      return true;
    }
    if (_isTop(t1) || _isBottom(t2)) {
      return false;
    }
    if (isClassSubType(t1, t2)) {
      return true;
    }
    if (isFunctionType(t1) && isFunctionType(t2)) {
      return isFunctionSubType(t1, t2);
    }
    return false;
  }
  function isClassSubType(t1, t2) {
    t1 = canonicalType(t1);
    assert_(t2 == canonicalType(t2));
    if (t1 == t2) return true;
    if (t1 == core.Object) return false;
    if (t1 == null) return t2 == core.Object || t2 == dynamicR;
    let raw1 = getGenericClass(t1);
    let raw2 = getGenericClass(t2);
    if (raw1 != null && raw1 == raw2) {
      let typeArguments1 = getGenericArgs(t1);
      let typeArguments2 = getGenericArgs(t2);
      let length = typeArguments1.length;
      if (typeArguments2.length == 0) {
        return true;
      } else if (length == 0) {
        return false;
      }
      assert_(length == typeArguments2.length);
      for (let i = 0; i < length; ++i) {
        if (!isSubtype(typeArguments1[i], typeArguments2[i])) {
          return false;
        }
      }
      return true;
    }
    if (isClassSubType(t1.__proto__, t2)) return true;
    let mixins = getMixins(t1);
    if (mixins) {
      for (let m1 of mixins) {
        if (m1 != null && isClassSubType(m1, t2)) return true;
      }
    }
    let getInterfaces = getImplements(t1);
    if (getInterfaces) {
      for (let i1 of getInterfaces()) {
        if (i1 != null && isClassSubType(i1, t2)) return true;
      }
    }
    return false;
  }
  function isGroundType(type) {
    if (type instanceof AbstractFunctionType) {
      if (!_isTop(type.returnType)) return false;
      for (let i = 0; i < type.args.length; ++i) {
        if (!_isBottom(type.args[i])) return false;
      }
      for (let i = 0; i < type.optionals.length; ++i) {
        if (!_isBottom(type.optionals[i])) return false;
      }
      let names = getOwnPropertyNames(type.named);
      for (let i = 0; i < names.length; ++i) {
        if (!_isBottom(type.named[names[i]])) return false;
      }
      return true;
    }
    let typeArgs = getGenericArgs(type);
    if (!typeArgs) return true;
    for (let t of typeArgs) {
      if (t != core.Object && t != dynamicR) return false;
    }
    return true;
  }
  const defineProperty = Object.defineProperty;
  const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
  const getOwnPropertyNames = Object.getOwnPropertyNames;
  const getOwnPropertySymbols = Object.getOwnPropertySymbols;
  const hasOwnProperty = Object.prototype.hasOwnProperty;
  const StrongModeError = (function() {
    function StrongModeError(message) {
      Error.call(this);
      this.message = message;
    }
    ;
    Object.setPrototypeOf(StrongModeError.prototype, Error.prototype);
    return StrongModeError;
  })();
  function throwStrongModeError(message) {
    throw new StrongModeError(message);
  }
  function throwInternalError(message) {
    throw Error(message);
  }
  function getOwnNamesAndSymbols(obj) {
    return getOwnPropertyNames(obj).concat(getOwnPropertySymbols(obj));
  }
  function safeGetOwnProperty(obj, name) {
    let desc = getOwnPropertyDescriptor(obj, name);
    if (desc) return desc.value;
  }
  function defineLazyProperty(to, name, desc) {
    let init = desc.get;
    let value = null;
    function lazySetter(x) {
      init = null;
      value = x;
    }
    function circularInitError() {
      throwInternalError('circular initialization for field ' + name);
    }
    function lazyGetter() {
      if (init == null) return value;
      let f = init;
      init = circularInitError;
      lazySetter(f());
      return value;
    }
    desc.get = lazyGetter;
    desc.configurable = true;
    if (desc.set) desc.set = lazySetter;
    return defineProperty(to, name, desc);
  }
  function defineLazy(to, from) {
    for (let name of getOwnNamesAndSymbols(from)) {
      defineLazyProperty(to, name, getOwnPropertyDescriptor(from, name));
    }
  }
  function defineMemoizedGetter(obj, name, getter) {
    return defineLazyProperty(obj, name, {get: getter});
  }
  function copyTheseProperties(to, from, names) {
    for (let name of names) {
      var desc = getOwnPropertyDescriptor(from, name);
      if (desc != void 0) {
        defineProperty(to, name, desc);
      } else {
        defineLazyProperty(to, name, () => from[name]);
      }
    }
    return to;
  }
  function copyProperties(to, from) {
    return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
  }
  function export_(to, from, show, hide) {
    if (show == void 0 || show.length == 0) {
      show = getOwnNamesAndSymbols(from);
    }
    if (hide != void 0) {
      var hideMap = new Set(hide);
      show = show.filter(k => !hideMap.has(k));
    }
    return copyTheseProperties(to, from, show);
  }
  const defineLazyClass = defineLazy;
  const defineLazyProperties = defineLazy;
  const defineLazyClassGeneric = defineLazyProperty;
  const as_ = cast;
  const is_ = instanceOf;
  const global_ = typeof window == "undefined" ? global : window;
  const JsSymbol = Symbol;
  // Exports:
  exports.mixin = mixin;
  exports.getMixins = getMixins;
  exports.getImplements = getImplements;
  exports.generic = generic;
  exports.getGenericClass = getGenericClass;
  exports.getGenericArgs = getGenericArgs;
  exports.getMethodType = getMethodType;
  exports.classGetConstructorType = classGetConstructorType;
  exports.bind = bind;
  exports.setSignature = setSignature;
  exports.hasMethod = hasMethod;
  exports.virtualField = virtualField;
  exports.defineNamedConstructor = defineNamedConstructor;
  exports.dartx = dartx;
  exports.getExtensionSymbol = getExtensionSymbol;
  exports.defineExtensionNames = defineExtensionNames;
  exports.registerExtension = registerExtension;
  exports.defineExtensionMembers = defineExtensionMembers;
  exports.canonicalMember = canonicalMember;
  exports.setType = setType;
  exports.list = list;
  exports.setBaseClass = setBaseClass;
  exports.throwCastError = throwCastError;
  exports.throwAssertionError = throwAssertionError;
  exports.throwNullValueError = throwNullValueError;
  exports.syncStar = syncStar;
  exports.async = async_;
  exports.asyncStar = asyncStar;
  exports.dload = dload;
  exports.dput = dput;
  exports.checkApply = checkApply;
  exports.throwNoSuchMethod = throwNoSuchMethod;
  exports.throwNoSuchMethodFunc = throwNoSuchMethodFunc;
  exports.checkAndCall = checkAndCall;
  exports.dcall = dcall;
  exports.callMethod = callMethod;
  exports.dsend = dsend;
  exports.dindex = dindex;
  exports.dsetindex = dsetindex;
  exports.strongInstanceOf = strongInstanceOf;
  exports.instanceOfOrNull = instanceOfOrNull;
  exports.instanceOf = instanceOf;
  exports.cast = cast;
  exports.asInt = asInt;
  exports.arity = arity;
  exports.equals = equals;
  exports.notNull = notNull;
  exports.map = map;
  exports.assert = assert_;
  exports.throw = throw_;
  exports.getError = getError;
  exports.stackPrint = stackPrint;
  exports.stackTrace = stackTrace;
  exports.nullSafe = nullSafe;
  exports.multiKeyPutIfAbsent = multiKeyPutIfAbsent;
  exports.constants = constants;
  exports.const = const_;
  exports.hashCode = hashCode;
  exports.toString = toString;
  exports.noSuchMethod = noSuchMethod;
  exports.JsIterator = JsIterator;
  exports.fn = fn;
  exports.checkPrimitiveType = checkPrimitiveType;
  exports.runtimeType = runtimeType;
  exports.getFunctionType = getFunctionType;
  exports.realRuntimeType = realRuntimeType;
  exports.LazyTagged = LazyTagged;
  exports.read = read;
  exports.tag = tag;
  exports.tagComputed = tagComputed;
  exports.tagMemoized = tagMemoized;
  exports.implements = implements_;
  exports.metadata = metadata;
  exports.TypeRep = TypeRep;
  exports.Dynamic = Dynamic;
  exports.dynamic = dynamicR;
  exports.Void = Void;
  exports.void = voidR;
  exports.Bottom = Bottom;
  exports.bottom = bottom;
  exports.JSObject = JSObject;
  exports.jsobject = jsobject;
  exports.AbstractFunctionType = AbstractFunctionType;
  exports.FunctionType = FunctionType;
  exports.Typedef = Typedef;
  exports.functionType = functionType;
  exports.definiteFunctionType = definiteFunctionType;
  exports.typedef = typedef;
  exports.isDartType = isDartType;
  exports.typeName = typeName;
  exports.isFunctionType = isFunctionType;
  exports.isFunctionSubType = isFunctionSubType;
  exports.canonicalType = canonicalType;
  exports.subtypeMap = subtypeMap;
  exports.isSubtype = isSubtype;
  exports.isSubtype_ = isSubtype_;
  exports.isClassSubType = isClassSubType;
  exports.isGroundType = isGroundType;
  exports.defineProperty = defineProperty;
  exports.getOwnPropertyDescriptor = getOwnPropertyDescriptor;
  exports.getOwnPropertyNames = getOwnPropertyNames;
  exports.getOwnPropertySymbols = getOwnPropertySymbols;
  exports.hasOwnProperty = hasOwnProperty;
  exports.StrongModeError = StrongModeError;
  exports.throwStrongModeError = throwStrongModeError;
  exports.throwInternalError = throwInternalError;
  exports.getOwnNamesAndSymbols = getOwnNamesAndSymbols;
  exports.safeGetOwnProperty = safeGetOwnProperty;
  exports.defineLazyProperty = defineLazyProperty;
  exports.defineLazy = defineLazy;
  exports.defineMemoizedGetter = defineMemoizedGetter;
  exports.copyTheseProperties = copyTheseProperties;
  exports.copyProperties = copyProperties;
  exports.export = export_;
  exports.defineLazyClass = defineLazyClass;
  exports.defineLazyProperties = defineLazyProperties;
  exports.defineLazyClassGeneric = defineLazyClassGeneric;
  exports.as = as_;
  exports.is = is_;
  exports.global = global_;
  exports.JsSymbol = JsSymbol;
});
