// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines runtime operations on objects used by the code
/// generator.
part of dart._runtime;

class InvocationImpl extends Invocation {
  final Symbol memberName;
  final List positionalArguments;
  final Map<Symbol, dynamic> namedArguments;
  final List<Type> typeArguments;
  final bool isMethod;
  final bool isGetter;
  final bool isSetter;

  InvocationImpl(memberName, this.positionalArguments,
      {namedArguments,
      List typeArguments,
      this.isMethod: false,
      this.isGetter: false,
      this.isSetter: false})
      : memberName =
            isSetter ? _setterSymbol(memberName) : _dartSymbol(memberName),
        namedArguments = _namedArgsToSymbols(namedArguments),
        typeArguments = typeArguments == null
            ? const []
            : typeArguments.map(wrapType).toList();

  static Map<Symbol, dynamic> _namedArgsToSymbols(namedArgs) {
    if (namedArgs == null) return {};
    return new Map.fromIterable(getOwnPropertyNames(namedArgs),
        key: _dartSymbol, value: (k) => JS('', '#[#]', namedArgs, k));
  }
}

/// Given an object and a method name, tear off the method.
/// Sets the runtime type of the torn off method appropriately,
/// and also binds the object.
///
/// If the optional `f` argument is passed in, it will be used as the method.
/// This supports cases like `super.foo` where we need to tear off the method
/// from the superclass, not from the `obj` directly.
// TODO(leafp): Consider caching the tearoff on the object?
bind(obj, name, method) {
  if (obj == null) obj = jsNull;
  if (method == null) method = JS('', '#[#]', obj, name);
  var f = JS('', '#.bind(#)', method, obj);
  // TODO(jmesserly): canonicalize tearoffs.
  JS('', '#._boundObject = #', f, obj);
  JS('', '#._boundMethod = #', f, method);
  JS('', '#[#] = #', f, _runtimeType, getMethodType(getType(obj), name));
  return f;
}

tagStatic(type, name) {
  var f = JS('', '#.#', type, name);
  if (JS('', '#[#]', f, _runtimeType) == null) {
    JS('', '#[#] = #[#][#]', f, _runtimeType, type, _staticMethodSig, name);
  }
  return f;
}

/// Instantiate a generic method.
///
/// We need to apply the type arguments both to the function, as well as its
/// associated function type.
gbind(f, @rest typeArgs) {
  var result =
      JS('', '(...args) => #.apply(null, #.concat(args))', f, typeArgs);
  var sig = JS('', '#.instantiate(#)', _getRuntimeType(f), typeArgs);
  tag(result, sig);
  return result;
}

// Warning: dload, dput, and dsend assume they are never called on methods
// implemented by the Object base class as those methods can always be
// statically resolved.
dload(obj, field) {
  var f = _canonicalMember(obj, field);

  trackCall(obj);
  if (f != null) {
    var type = getType(obj);

    if (hasField(type, f) || hasGetter(type, f)) return JS('', '#[#]', obj, f);
    if (hasMethod(type, f)) return bind(obj, f, null);

    // Always allow for JS interop objects.
    if (isJsInterop(obj)) return JS('', '#[#]', obj, f);
  }
  return noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[]'), isGetter: true));
}

// Version of dload that matches legacy mirrors behavior for JS types.
dloadMirror(obj, field) {
  var f = _canonicalMember(obj, field);

  trackCall(obj);
  if (f != null) {
    var type = getType(obj);

    if (hasField(type, f) || hasGetter(type, f)) return JS('', '#[#]', obj, f);
    if (hasMethod(type, f)) return bind(obj, f, JS('', 'void 0'));

    // Do not support calls on JS interop objects to match Dart2JS behavior.
  }
  return noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[]'), isGetter: true));
}

_stripGenericArguments(type) {
  var genericClass = getGenericClass(type);
  if (genericClass != null) return JS('', '#()', genericClass);
  return type;
}

// Version of dput that matches legacy Dart 1 type check rules and mirrors
// behavior for JS types.
// TODO(jacobr): remove the type checking rules workaround when mirrors based
// PageLoader code can generate the correct reified generic types.
dputMirror(obj, field, value) {
  var f = _canonicalMember(obj, field);
  trackCall(obj);
  if (f != null) {
    var setterType = getSetterType(getType(obj), f);
    if (setterType != null) {
      setterType = _stripGenericArguments(setterType);
      return JS('', '#[#] = #._check(#)', obj, f, setterType, value);
    }
  }
  noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[#]', value), isSetter: true));
  return value;
}

dput(obj, field, value) {
  var f = _canonicalMember(obj, field);
  trackCall(obj);
  if (f != null) {
    var setterType = getSetterType(getType(obj), f);
    if (setterType != null) {
      return JS('', '#[#] = #._check(#)', obj, f, setterType, value);
    }
    // Always allow for JS interop objects.
    if (isJsInterop(obj)) {
      return JS('', '#[#] = #', obj, f, value);
    }
  }
  noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[#]', value), isSetter: true));
  return value;
}

/// Check that a function of a given type can be applied to
/// actuals.
_checkApply(type, actuals) => JS('', '''(() => {
  // TODO(vsm): Remove when we no longer need mirrors metadata.
  // An array is used to encode annotations attached to the type.
  if ($type instanceof Array) {
    $type = type[0];
  }
  if ($actuals.length < $type.args.length) return false;
  let index = 0;
  for(let i = 0; i < $type.args.length; ++i) {
    $type.args[i]._check($actuals[i]);
    ++index;
  }
  if ($actuals.length == $type.args.length) return true;
  let extras = $actuals.length - $type.args.length;
  if ($type.optionals.length > 0) {
    if (extras > $type.optionals.length) return false;
    for(let i = 0, j=index; i < extras; ++i, ++j) {
      $type.optionals[i]._check($actuals[j]);
    }
    return true;
  }
  // TODO(leafp): We can't tell when someone might be calling
  // something expecting an optional argument with named arguments

  if (extras != 1) return false;
  // An empty named list means no named arguments
  if ($getOwnPropertyNames($type.named).length == 0) return false;
  let opts = $actuals[index];
  let names = $getOwnPropertyNames(opts);
  // Type is something other than a map
  if (names.length == 0) return false;
  for (var name of names) {
    if (!($hasOwnProperty.call($type.named, name))) {
      return false;
    }
    $type.named[name]._check(opts[name]);
  }
  return true;
})()''');

_toSymbolName(symbol) => JS('', '''(() => {
        let str = $symbol.toString();
        // Strip leading 'Symbol(' and trailing ')'
        return str.substring(7, str.length-1);
    })()''');

_toDisplayName(name) => JS('', '''(() => {
      // Names starting with _ are escaped names used to disambiguate Dart and
      // JS names.
      if ($name[0] === '_') {
        // Inverse of 
        switch($name) {
          case '_get':
            return '[]';
          case '_set':
            return '[]=';
          case '_negate':
            return 'unary-';
          case '_constructor':
          case '_prototype':
            return $name.substring(1);
        }
      }
      return $name;
  })()''');

Symbol _dartSymbol(name) {
  return (JS('bool', 'typeof # === "symbol"', name))
      ? JS('Symbol', '#(new #.new(#, #))', const_, PrivateSymbol,
          _toSymbolName(name), name)
      : JS('Symbol', '#(#.new(#))', const_, Symbol, _toDisplayName(name));
}

Symbol _setterSymbol(name) {
  return (JS('bool', 'typeof # === "symbol"', name))
      ? JS('Symbol', '#(new #.new(# + "=", #))', const_, PrivateSymbol,
          _toSymbolName(name), name)
      : JS('Symbol', '#(#.new(# + "="))', const_, Symbol, _toDisplayName(name));
}

/// Extracts the named argument array from a list of arguments, and returns it.
// TODO(jmesserly): we need to handle named arguments better.
extractNamedArgs(args) {
  if (JS('bool', '#.length > 0', args)) {
    var last = JS('', '#[#.length - 1]', args, args);
    if (JS(
        'bool', '# != null && #.__proto__ === Object.prototype', last, last)) {
      return JS('', '#.pop()', args);
    }
  }
  return null;
}

_checkAndCall(f, ftype, obj, typeArgs, args, name) => JS('', '''(() => {
  $trackCall($obj);

  let originalTarget = obj === void 0 ? f : obj;

  function callNSM() {
    return $noSuchMethod(originalTarget, new $InvocationImpl.new(
        $name, $args, {
          namedArguments: $extractNamedArgs($args),
          typeArguments: $typeArgs,
          isMethod: true
        }));
  }
  if (!($f instanceof Function)) {
    // We're not a function (and hence not a method either)
    // Grab the `call` method if it's not a function.
    if ($f != null) {
      $ftype = $getMethodType($getType($f), 'call');
      $f = f.call ? $bind($f, 'call') : void 0;
    }
    if (!($f instanceof Function)) {
      return callNSM();
    }
  }
  // If f is a function, but not a method (no method type)
  // then it should have been a function valued field, so
  // get the type from the function.
  if ($ftype == null) {
    $ftype = $_getRuntimeType($f);
  }

  if ($ftype == null) {
    // TODO(leafp): Allow JS objects to go through?
    if ($typeArgs != null) {
      // TODO(jmesserly): is there a sensible way to handle these?
      $throwTypeError('call to JS object `' + $obj +
          '` with type arguments <' + $typeArgs + '> is not supported.');
    }
    return $f.apply($obj, $args);
  }

  // Apply type arguments
  if ($ftype instanceof $GenericFunctionType) {
    let formalCount = $ftype.formalCount;
    
    if ($typeArgs == null) {
      $typeArgs = $ftype.instantiateDefaultBounds();
    } else if ($typeArgs.length != formalCount) {
      // TODO(jmesserly): is this the right error?
      $throwTypeError(
          'incorrect number of arguments to generic function ' +
          $typeName($ftype) + ', got <' + $typeArgs + '> expected ' +
          formalCount + '.');
    } else {
      $ftype.checkBounds($typeArgs);
    }
    $ftype = $ftype.instantiate($typeArgs);
  } else if ($typeArgs != null) {
    $throwTypeError(
        'got type arguments to non-generic function ' + $typeName($ftype) +
        ', got <' + $typeArgs + '> expected none.');
  }

  if ($_checkApply($ftype, $args)) {
    if ($typeArgs != null) {
      return $f.apply($obj, $typeArgs.concat($args));
    }
    return $f.apply($obj, $args);
  }

  // TODO(leafp): throw a type error (rather than NSM)
  // if the arity matches but the types are wrong.
  // TODO(jmesserly): nSM should include type args?
  return callNSM();
})()''');

dcall(f, @rest args) =>
    _checkAndCall(f, _getRuntimeType(f), JS('', 'void 0'), null, args, 'call');

dgcall(f, typeArgs, @rest args) => _checkAndCall(
    f, _getRuntimeType(f), JS('', 'void 0'), typeArgs, args, 'call');

/// Helper for REPL dynamic invocation variants that make a best effort to
/// enable accessing private members across library boundaries.
_dhelperRepl(object, field, callback) => JS('', '''(() => {
  let rawField = $field;
  if (typeof(field) == 'symbol') {
    // test if the specified field exists in which case it is safe to use it.
    if ($field in $object) return $callback($field);

    // Symbol is from a different library. Make a best effort to
    $field = $field.toString();
    $field = $field.substring('Symbol('.length, field.length - 1);

  } else if ($field.charAt(0) != '_') {
    // Not a private member so default call path is safe.
    return $callback($field);
  }

  // If the exact field name is present, invoke callback with it.
  if ($field in $object) return $callback($field);

  // TODO(jacobr): warn if there are multiple private members with the same
  // name which could happen if super classes in different libraries have
  // the same private member name.
  let proto = $object;
  while (proto !== null) {
    // Private field (indicated with "_").
    let symbols = Object.getOwnPropertySymbols(proto);
    let target = 'Symbol(' + $field + ')';

    for (let s = 0; s < symbols.length; s++) {
      let sym = symbols[s];
      if (target == sym.toString()) return $callback(sym);
    }
    proto = proto.__proto__;
  }
  // We didn't find a plausible alternate private symbol so just fall back
  // to the regular field.
  return $callback(rawField);
})()''');

dloadRepl(obj, field) =>
    _dhelperRepl(obj, field, (resolvedField) => dload(obj, resolvedField));

dputRepl(obj, field, value) => _dhelperRepl(
    obj, field, (resolvedField) => dput(obj, resolvedField, value));

callMethodRepl(obj, method, typeArgs, args) => _dhelperRepl(obj, method,
    (resolvedField) => callMethod(obj, resolvedField, typeArgs, args, method));

dsendRepl(obj, method, @rest args) => callMethodRepl(obj, method, null, args);

dgsendRepl(obj, typeArgs, method, @rest args) =>
    callMethodRepl(obj, method, typeArgs, args);

/// Shared code for dsend, dindex, and dsetindex.
callMethod(obj, name, typeArgs, args, displayName) {
  var symbol = _canonicalMember(obj, name);
  if (symbol == null) {
    return noSuchMethod(
        obj, new InvocationImpl(displayName, args, isMethod: true));
  }
  var f = obj != null ? JS('', '#[#]', obj, symbol) : null;
  var type = getType(obj);
  var ftype = getMethodType(type, symbol);
  // No such method if dart object and ftype is missing.
  return _checkAndCall(f, ftype, obj, typeArgs, args, displayName);
}

dsend(obj, method, @rest args) => callMethod(obj, method, null, args, method);

dgsend(obj, typeArgs, method, @rest args) =>
    callMethod(obj, method, typeArgs, args, method);

dindex(obj, index) => callMethod(obj, '_get', null, JS('', '[#]', index), '[]');

dsetindex(obj, index, value) =>
    callMethod(obj, '_set', null, JS('', '[#, #]', index, value), '[]=');

/// TODO(leafp): This duplicates code in types.dart.
/// I haven't found a way to factor it out that makes the
/// code generator happy though.
_ignoreMemo(f) => JS('', '''(() => {
  let memo = new Map();
  return (t1, t2) => {
    let map = memo.get(t1);
    let result;
    if (map) {
      result = map.get(t2);
      if (result !== void 0) return result;
    } else {
      memo.set(t1, map = new Map());
    }
    result = $f(t1, t2);
    map.set(t2, result);
    return result;
  };
})()''');

final _ignoreTypeFailure = JS('', '''(() => {
  return $_ignoreMemo((actual, type) => {
      // TODO(vsm): Remove this hack ...
      // This is primarily due to the lack of generic methods,
      // but we need to triage all the types.
    if ($_isFutureOr(type)) {
      // Ignore if we would ignore either side of union.
      let typeArg = $getGenericArgs(type)[0];
      let typeFuture = ${getGenericClass(Future)}(typeArg);
      return $_ignoreTypeFailure(actual, typeFuture) ||
        $_ignoreTypeFailure(actual, typeArg);
    }

    if (!!$isSubtype(type, $Iterable) && !!$isSubtype(actual, $Iterable) ||
        !!$isSubtype(type, $Future) && !!$isSubtype(actual, $Future) ||
        !!$isSubtype(type, $Map) && !!$isSubtype(actual, $Map) ||
        $_isFunctionType(type) && $_isFunctionType(actual) ||
        !!$isSubtype(type, $Stream) && !!$isSubtype(actual, $Stream) ||
        !!$isSubtype(type, $StreamSubscription) &&
        !!$isSubtype(actual, $StreamSubscription)) {
      console.warn('Ignoring cast fail from ' + $typeName(actual) +
                   ' to ' + $typeName(type));
      return true;
    }
    return false;
  });
})()''');

@JSExportName('is')
bool instanceOf(obj, type) {
  if (obj == null) {
    return JS('bool', '# == # || #', type, Null, _isTop(type));
  }
  return JS('#', '!!#', isSubtype(getReifiedType(obj), type));
}

@JSExportName('as')
cast(obj, type, bool typeError) {
  if (obj == null) return obj;
  var actual = getReifiedType(obj);
  var result = isSubtype(actual, type);
  if (JS(
      'bool',
      '# === true || # === null && dart.__ignoreWhitelistedErrors && #(#, #)',
      result,
      result,
      _ignoreTypeFailure,
      actual,
      type)) {
    return obj;
  }
  return castError(obj, type, typeError);
}

bool test(bool obj) {
  if (obj == null) _throwBooleanConversionError();
  return obj;
}

bool dtest(obj) {
  if (obj is! bool) booleanConversionFailed(obj);
  return obj;
}

void _throwBooleanConversionError() =>
    throw new BooleanConversionAssertionError();

void booleanConversionFailed(obj) {
  if (obj == null) {
    _throwBooleanConversionError();
  }
  var actual = getReifiedType(obj);
  var expected = JS('', '#', bool);
  throw new TypeErrorImplementation.fromMessage(
      "type '${typeName(actual)}' is not a subtype of "
      "type '${typeName(expected)}' in boolean expression");
}

castError(obj, type, bool typeError) {
  var objType = getReifiedType(obj);
  if (JS('bool', '!dart.__ignoreAllErrors')) {
    var errorInStrongMode = isSubtype(objType, type) == null;

    var actual = typeName(objType);
    var expected = typeName(type);
    if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');

    var error = JS('bool', '#', typeError)
        ? new TypeErrorImplementation(obj, actual, expected, errorInStrongMode)
        : new CastErrorImplementation(obj, actual, expected, errorInStrongMode);
    throw error;
  }
  JS('', 'console.error(#)',
      'Actual: ${typeName(objType)} Expected: ${typeName(type)}');
  return obj;
}

asInt(obj) {
  if (obj == null) return null;

  if (JS('bool', 'Math.floor(#) != #', obj, obj)) {
    castError(obj, JS('', '#', int), false);
  }
  return obj;
}

/// Checks that `x` is not null or undefined.
// TODO(jmesserly): should we inline this?
notNull(x) {
  if (x == null) throwNullValueError();
  return x;
}

/// The global constant map table.
final constantMaps = JS('', 'new Map()');

constMap<K, V>(JSArray elements) {
  Function(Object, Object) lookupNonTerminal = JS('', '''function(map, key) {
    let result = map.get(key);
    if (result != null) return result;
    map.set(key, result = new Map());
    return result;
  }''');
  var count = elements.length;
  var map = lookupNonTerminal(constantMaps, count);
  for (var i = 0; i < count; i++) {
    map = lookupNonTerminal(map, JS('', '#[#]', elements, i));
  }
  map = lookupNonTerminal(map, K);
  var result = JS('', '#.get(#)', map, V);
  if (result != null) return result;
  result = new ImmutableMap<K, V>.from(elements);
  JS('', '#.set(#, #)', map, V, result);
  return result;
}

bool dassert(value) {
  if (JS('bool', '# != null && #[#] instanceof #', value, value, _runtimeType,
      AbstractFunctionType)) {
    value = JS('', '#(#)', dcall, value);
  }
  return dtest(value);
}

/// Store a JS error for an exception.  For non-primitives, we store as an
/// expando.  For primitive, we use a side cache.  To limit memory leakage, we
/// only keep the last [_maxTraceCache] entries.
final _error = JS('', 'Symbol("_error")');
Map _primitiveErrorCache;
const _maxErrorCache = 10;

bool _isJsError(exception) {
  return JS('bool', '#.Error != null && # instanceof #.Error', global_,
      exception, global_);
}

// Record/return the JS error for an exception.  If an error was already
// recorded, prefer that to [newError].
recordJsError(exception, [newError]) {
  if (_isJsError(exception)) return exception;

  var useExpando =
      exception != null && JS('bool', 'typeof # == "object"', exception);
  var error;
  if (useExpando) {
    error = JS('', '#[#]', exception, _error);
  } else {
    if (_primitiveErrorCache == null) _primitiveErrorCache = {};
    error = _primitiveErrorCache[exception];
  }
  if (error != null) return error;
  if (newError != null) {
    error = newError;
  } else {
    // We should only hit this path when a non-Error was thrown from JS.  In
    // case, there is no stack trace on the exception, so we create one:
    error = JS('', 'new Error()');
  }
  if (useExpando) {
    JS('', '#[#] = #', exception, _error, error);
  } else {
    _primitiveErrorCache[exception] = error;
    if (_primitiveErrorCache.length > _maxErrorCache) {
      _primitiveErrorCache.remove(_primitiveErrorCache.keys.first);
    }
  }
  return error;
}

@JSExportName('throw')
throw_(obj) {
  // Note, we create the error here to avoid the extra frame.
  // package:stack_trace and tests appear to assume this.  We could fix use
  // cases instead, but we're already on the exceptional path here.
  recordJsError(obj, JS('', 'new Error()'));
  JS('', 'throw #', obj);
}

@JSExportName('rethrow')
rethrow_(obj) {
  JS('', 'throw #', obj);
}

// This is a utility function: it is only intended to be called from dev
// tools.
stackPrint(exception) {
  var error = recordJsError(exception);
  JS('', 'console.log(#.stack ? #.stack : "No stack trace for: " + #)', error,
      error, error);
}

// Forward to dart:_js_helper to create a _StackTrace object.
stackTrace(exception) => getTraceFromException(exception);

final _value = JS('', 'Symbol("_value")');

///
/// Looks up a sequence of [keys] in [map], recursively, and
/// returns the result. If the value is not found, [valueFn] will be called to
/// add it. For example:
///
///     let map = new Map();
///     putIfAbsent(map, [1, 2, 'hi ', 'there '], () => 'world');
///
/// ... will create a Map with a structure like:
///
///     { 1: { 2: { 'hi ': { 'there ': 'world' } } } }
///
multiKeyPutIfAbsent(map, keys, valueFn) => JS('', '''(() => {
  for (let k of $keys) {
    let value = $map.get(k);
    if (!value) {
      // TODO(jmesserly): most of these maps are very small (e.g. 1 item),
      // so it may be worth optimizing for that.
      $map.set(k, value = new Map());
    }
    $map = value;
  }
  if ($map.has($_value)) return $map.get($_value);
  let value = $valueFn();
  $map.set($_value, value);
  return value;
})()''');

/// The global constant table.
/// This maps the number of names in the object (n)
/// to a path of length 2*n of maps indexed by the name and
/// and value of the field.  The final map is
/// indexed by runtime type, and contains the canonical
/// version of the object.
final constants = JS('', 'new Map()');

///
/// Canonicalize a constant object.
///
/// Preconditions:
/// - `obj` is an objects or array, not a primitive.
/// - nested values of the object are themselves already canonicalized.
///
@JSExportName('const')
const_(obj) => JS('', '''(() => {
  // TODO(leafp): This table gets quite large in apps.
  // Keeping the paths is probably expensive.  It would probably
  // be more space efficient to just use a direct hash table with
  // an appropriately defined structural equality function.
  function lookupNonTerminal(map, key) {
    let result = map.get(key);
    if (result !== void 0) return result;
    map.set(key, result = new Map());
    return result;
  };
  let names = $getOwnNamesAndSymbols($obj);
  let count = names.length;
  // Index by count.  All of the paths through this map
  // will have 2*count length.
  let map = lookupNonTerminal($constants, count);
  // TODO(jmesserly): there's no guarantee in JS that names/symbols are
  // returned in the same order.
  //
  // We could probably get the same order if we're judicious about
  // initializing fields in a consistent order across all const constructors.
  // Alternatively we need a way to sort them to make consistent.
  //
  // Right now we use the (name,value) pairs in sequence, which prevents
  // an object with incorrect field values being returned, but won't
  // canonicalize correctly if key order is different.
  //
  // See issue https://github.com/dart-lang/sdk/issues/30876
  for (let i = 0; i < count; i++) {
    let name = names[i];
    map = lookupNonTerminal(map, name);
    map = lookupNonTerminal(map, $obj[name]);
  }
  // TODO(leafp): It may be the case that the reified type
  // is always one of the keys already used above?
  let type = $getReifiedType($obj);
  let value = map.get(type);
  if (value) return value;
  map.set(type, $obj);
  return $obj;
})()''');

/// The global constant list table.
/// This maps the number of elements in the list (n)
/// to a path of length n of maps indexed by the value
/// of the field.  The final map is indexed by the element
/// type and contains the canonical version of the list.
final constantLists = JS('', 'new Map()');

/// Canonicalize a constant list
constList(elements, elementType) => JS('', '''(() => {
  function lookupNonTerminal(map, key) {
    let result = map.get(key);
    if (result !== void 0) return result;
    map.set(key, result = new Map());
    return result;
  };
  let count = $elements.length;
  let map = lookupNonTerminal($constantLists, count);
  for (let i = 0; i < count; i++) {
    map = lookupNonTerminal(map, elements[i]);
  }
  let value = map.get($elementType);
  if (value) return value;

  ${getGenericClass(JSArray)}($elementType).unmodifiable($elements);
  map.set($elementType, elements);
  return elements;
})()''');

constFn(x) => JS('', '() => x');

/// Gets the extension symbol given a member [name].
///
/// This is inlined by the compiler when used with a literal string.
extensionSymbol(String name) => JS('', 'dartx[#]', name);

// The following are helpers for Object methods when the receiver
// may be null. These should only be generated by the compiler.
bool equals(x, y) {
  // We handle `y == null` inside our generated operator methods, to keep this
  // function minimal.
  // This pattern resulted from performance testing; it found that dispatching
  // was the fastest solution, even for primitive types.
  return JS('bool', '# == null ? # == null : #[#](#)', x, y, x,
      extensionSymbol('_equals'), y);
}

int hashCode(obj) {
  return obj == null ? 0 : JS('int', '#[#]', obj, extensionSymbol('hashCode'));
}

hashKey(k) {
  if (k == null) return 0;
  switch (JS('String', 'typeof #', k)) {
    case "object":
    case "function":
      return JS('int', '#[#] & 0x3ffffff', k, extensionSymbol('hashCode'));
  }
  // For primitive types we can store the key directly in an ES6 Map.
  return k;
}

@JSExportName('toString')
String _toString(obj) {
  if (obj == null) return "null";
  return JS('String', '#[#]()', obj, extensionSymbol('toString'));
}

// TODO(jmesserly): is the argument type verified statically?
noSuchMethod(obj, Invocation invocation) {
  if (obj == null) defaultNoSuchMethod(obj, invocation);
  return JS('', '#[#](#)', obj, extensionSymbol('noSuchMethod'), invocation);
}

/// The default implementation of `noSuchMethod` to match `Object.noSuchMethod`.
defaultNoSuchMethod(obj, Invocation i) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new NoSuchMethodError.withInvocation(obj, i);
}

runtimeType(obj) {
  return obj == null ? Null : JS('', '#[dartx.runtimeType]', obj);
}

/// Implements Dart's interpolated strings as ES2015 tagged template literals.
///
/// For example: dart.str`hello ${name}`
String str(strings, @rest values) => JS('', '''(() => {
  let s = $strings[0];
  for (let i = 0, len = $values.length; i < len; ) {
    s += $notNull($_toString($values[i])) + $strings[++i];
  }
  return s;
})()''');

final identityHashCode_ = JS('', 'Symbol("_identityHashCode")');

/// Adapts a Dart `get iterator` into a JS `[Symbol.iterator]`.
// TODO(jmesserly): instead of an adaptor, we could compile Dart iterators
// natively implementing the JS iterator protocol. This would allow us to
// optimize them a bit.
final JsIterator = JS('', '''
  class JsIterator {
    constructor(dartIterator) {
      this.dartIterator = dartIterator;
    }
    next() {
      let i = this.dartIterator;
      let done = !i.moveNext();
      return { done: done, value: done ? void 0 : i.current };
    }
  }
''');

_canonicalMember(obj, name) {
  // Private names are symbols and are already canonical.
  if (JS('bool', 'typeof # === "symbol"', name)) return name;

  if (obj != null && JS('bool', '#[#] != null', obj, _extensionType)) {
    return JS('', 'dartx.#', name);
  }

  // Check for certain names that we can't use in JS
  if (JS('bool', '# == "constructor" || # == "prototype"', name, name)) {
    JS('', '# = "+" + #', name, name);
  }
  return name;
}

/// Emulates the implicit "loadLibrary" function provided by a deferred library.
///
/// Libraries are not actually deferred in DDC, so this just returns a future
/// that completes immediately.
Future loadLibrary() => new Future.value();

/// Defines lazy statics.
void defineLazy(to, from) {
  for (var name in getOwnNamesAndSymbols(from)) {
    defineLazyField(to, name, getOwnPropertyDescriptor(from, name));
  }
}
