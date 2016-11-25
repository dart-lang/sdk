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
  final bool isMethod;
  final bool isGetter;
  final bool isSetter;

  InvocationImpl(String memberName, this.positionalArguments,
      {namedArguments,
      this.isMethod: false,
      this.isGetter: false,
      this.isSetter: false})
      : memberName = _dartSymbol(memberName),
        namedArguments = _namedArgsToSymbols(namedArguments);

  static Map<Symbol, dynamic> _namedArgsToSymbols(namedArgs) {
    if (namedArgs == null) return {};
    return new Map.fromIterable(getOwnPropertyNames(namedArgs),
        key: _dartSymbol, value: (k) => JS('', '#[#]', namedArgs, k));
  }
}

dload(obj, field) {
  var f = _canonicalMember(obj, field);
  _trackCall(obj);
  if (f != null) {
    if (hasMethod(obj, f)) return bind(obj, f, JS('', 'void 0'));
    return JS('', '#[#]', obj, f);
  }
  return noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[]'), isGetter: true));
}

dput(obj, field, value) {
  var f = _canonicalMember(obj, field);
  _trackCall(obj);
  if (f != null) {
    return JS('', '#[#] = #', obj, f, value);
  }
  return noSuchMethod(
      obj, new InvocationImpl(field, JS('', '[#]', value), isSetter: true));
}

/// Check that a function of a given type can be applied to
/// actuals.
_checkApply(type, actuals) => JS(
    '',
    '''(() => {
  if ($actuals.length < $type.args.length) return false;
  let index = 0;
  for(let i = 0; i < $type.args.length; ++i) {
    if (!$instanceOfOrNull($actuals[i], $type.args[i])) return false;
    ++index;
  }
  if ($actuals.length == $type.args.length) return true;
  let extras = $actuals.length - $type.args.length;
  if ($type.optionals.length > 0) {
    if (extras > $type.optionals.length) return false;
    for(let i = 0, j=index; i < extras; ++i, ++j) {
      if (!$instanceOfOrNull($actuals[j], $type.optionals[i])) return false;
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
    if (!$instanceOfOrNull(opts[name], $type.named[name])) return false;
  }
  return true;
})()''');

Symbol _dartSymbol(name) =>
    JS('', '#(#.new(#.toString()))', const_, Symbol, name);

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

_checkAndCall(f, ftype, obj, typeArgs, args, name) => JS(
    '',
    '''(() => {
  $_trackCall($obj);

  let originalTarget = obj === void 0 ? f : obj;

  function callNSM() {
    return $noSuchMethod(originalTarget, new $InvocationImpl(
        $name, $args,
        {namedArguments: $extractNamedArgs($args), isMethod: true}));
  }
  if (!($f instanceof Function)) {
    // We're not a function (and hence not a method either)
    // Grab the `call` method if it's not a function.
    if ($f != null) {
      $ftype = $getMethodType($f, 'call');
      $f = $f.call;
    }
    if (!($f instanceof Function)) {
      return callNSM();
    }
  }
  // If f is a function, but not a method (no method type)
  // then it should have been a function valued field, so
  // get the type from the function.
  if ($ftype === void 0) {
    $ftype = $_getRuntimeType($f);
  }

  if (!$ftype) {
    // TODO(leafp): Allow JS objects to go through?
    if ($typeArgs != null) {
      // TODO(jmesserly): is there a sensible way to handle these?
      $throwStrongModeError('call to JS object `' + $obj +
          '` with type arguments <' + $typeArgs + '> is not supported.');
    }
    return $f.apply($obj, $args);
  }

  // Apply type arguments
  let formalCount = $ftype[$_typeFormalCount];
  if (formalCount != null) {
    if ($typeArgs == null) {
      $typeArgs = Array(formalCount).fill($dynamic);
    } else if ($typeArgs.length != formalCount) {
      // TODO(jmesserly): is this the right error?
      $throwStrongModeError(
          'incorrect number of arguments to generic function ' +
          $typeName($ftype) + ', got <' + $typeArgs + '> expected ' +
          formalCount + '.');
    }
    // Instantiate the function.
    $ftype = $ftype.apply(null, $typeArgs);
  } else if ($typeArgs != null) {
    $throwStrongModeError(
        'got type arguments to non-generic function ' + $typeName($ftype) +
        ', got <' + $typeArgs + '> expected none.');
  }

  if ($_checkApply($ftype, $args)) {
    if ($typeArgs != null) {
      return $f.apply($obj, $typeArgs).apply($obj, $args);
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
_dhelperRepl(object, field, callback) => JS(
    '',
    '''(() => {
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

_callMethodRepl(obj, method, typeArgs, args) => _dhelperRepl(obj, method,
    (resolvedField) => _callMethod(obj, resolvedField, typeArgs, args, method));

dsendRepl(obj, method, @rest args) => _callMethodRepl(obj, method, null, args);

dgsendRepl(obj, typeArgs, method, @rest args) =>
    _callMethodRepl(obj, method, typeArgs, args);

class _MethodStats {
  final String typeName;
  final String frame;
  int count;

  _MethodStats(this.typeName, this.frame) {
    count = 0;
  }
}

Map<String, _MethodStats> _callMethodStats = new Map();

List<List<Object>> getDynamicStats() {
  List<List<Object>> ret = [];

  var keys = _callMethodStats.keys.toList();

  keys.sort(
      (a, b) => _callMethodStats[b].count.compareTo(_callMethodStats[a].count));
  for (var key in keys) {
    var stats = _callMethodStats[key];
    ret.add([stats.typeName, stats.frame, stats.count]);
  }

  return ret;
}

clearDynamicStats() {
  _callMethodStats.clear();
}

bool trackProfile = JS('bool', 'dart.global.trackDdcProfile');

_trackCall(obj) {
  if (JS('bool', '!#', trackProfile)) return;

  var actual = getReifiedType(obj);
  String stackStr = JS('String', "new Error().stack");
  var stack = stackStr.split('\n    at ');
  var src = '';
  for (int i = 2; i < stack.length; ++i) {
    var frame = stack[i];
    if (!frame.contains('dart_sdk.js')) {
      src = frame;
      break;
    }
  }

  var actualTypeName = typeName(actual);
  _callMethodStats
      .putIfAbsent(
          "$actualTypeName <$src>", () => new _MethodStats(actualTypeName, src))
      .count++;
}

/// Shared code for dsend, dindex, and dsetindex.
_callMethod(obj, name, typeArgs, args, displayName) {
  var symbol = _canonicalMember(obj, name);
  if (symbol == null) {
    return noSuchMethod(
        obj, new InvocationImpl(displayName, args, isMethod: true));
  }
  var f = obj != null ? JS('', '#[#]', obj, symbol) : null;
  var ftype = getMethodType(obj, symbol);
  return _checkAndCall(f, ftype, obj, typeArgs, args, displayName);
}

dsend(obj, method, @rest args) => _callMethod(obj, method, null, args, method);

dgsend(obj, typeArgs, method, @rest args) =>
    _callMethod(obj, method, typeArgs, args, method);

dindex(obj, index) => _callMethod(obj, '_get', null, JS('', '[#]', index), '[]');

dsetindex(obj, index, value) =>
    _callMethod(obj, '_set', null, JS('', '[#, #]', index, value), '[]=');

/// TODO(leafp): This duplicates code in types.dart.
/// I haven't found a way to factor it out that makes the
/// code generator happy though.
_ignoreMemo(f) => JS(
    '',
    '''(() => {
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

final _ignoreTypeFailure = JS(
    '',
    '''(() => {
  return $_ignoreMemo((actual, type) => {
      // TODO(vsm): Remove this hack ...
      // This is primarily due to the lack of generic methods,
      // but we need to triage all the types.
    if (!!$isSubtype(type, $Iterable) && !!$isSubtype(actual, $Iterable) ||
        !!$isSubtype(type, $Future) && !!$isSubtype(actual, $Future) ||
        !!$isSubtype(type, $Map) && !!$isSubtype(actual, $Map) ||
        $isFunctionType(type) && $isFunctionType(actual) ||
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

/// Returns true if [obj] is an instance of [type]
/// Returns false if [obj] is not an instance of [type] in both spec
///  and strong mode
/// Returns null if [obj] is not an instance of [type] in strong mode
///  but might be in spec mode
bool strongInstanceOf(obj, type, ignoreFromWhiteList) => JS(
    '',
    '''(() => {
  let actual = $getReifiedType($obj);
  let result = $isSubtype(actual, $type);
  if (result || actual == $jsobject ||
      actual == $int && type == $double) return true;
  if (result === false) return false;
  if ($ignoreFromWhiteList == void 0) return result;
  if ($_ignoreTypeFailure(actual, $type)) return true;
  return result;
})()''');

/// Returns true if [obj] is null or an instance of [type]
/// Returns false if [obj] is non-null and not an instance of [type]
/// in strong mode
instanceOfOrNull(obj, type) => JS(
    '',
    '''(() => {
  // If strongInstanceOf returns null, convert to false here.
  if (($obj == null) || $strongInstanceOf($obj, $type, true)) return true;
  return false;
})()''');

@JSExportName('is')
instanceOf(obj, type) => JS(
    '',
    '''(() => {
  let result = $strongInstanceOf($obj, $type);
  if (result !== null) return result;
  let actual = $getReifiedType($obj);
  $throwStrongModeError('Strong mode is-check failure: ' +
    $typeName(actual) + ' does not soundly subtype ' +
    $typeName($type));
})()''');

@JSExportName('as')
cast(obj, type) {
  if (JS('bool', '# == #', type, dynamic) || obj == null) return obj;
  bool result = strongInstanceOf(obj, type, true);
  if (JS('bool', '#', result)) return obj;
  _throwCastError(obj, type, result);
}

check(obj, type) {
  if (JS('bool', '# == #', type, dynamic) || obj == null) return obj;
  bool result = strongInstanceOf(obj, type, true);
  if (JS('bool', '#', result)) return obj;
  _throwTypeError(obj, type, result);
}

bool test(obj) {
  if (obj is bool) return obj;
  return booleanConversionFailed(obj);
}

bool booleanConversionFailed(obj) {
  if (obj == null) {
    throw new BooleanConversionAssertionError();
  }
  var actual = getReifiedType(obj);
  var expected = JS('', '#', bool);
  throw new TypeErrorImplementation.fromMessage(
      "type '${typeName(actual)}' is not a subtype of "
      "type '${typeName(expected)}' in boolean expression");
}

void _throwCastError(obj, type, bool result) {
  var actual = getReifiedType(obj);
  if (result == false) throwCastError(obj, actual, type);

  throwStrongModeCastError(obj, actual, type);
}

void _throwTypeError(obj, type, bool result) {
  var actual = getReifiedType(obj);
  if (result == false) throwTypeError(obj, actual, type);

  throwStrongModeTypeError(obj, actual, type);
}

asInt(obj) {
  if (obj == null) return null;

  if (JS('bool', 'Math.floor(#) != #', obj, obj)) {
    throwCastError(obj, getReifiedType(obj), JS('', '#', int));
  }
  return obj;
}

/// Adds type type test predicates to a constructor for a non-parameterized
/// type. Non-parameterized types can use `instanceof` for subclass checks and
/// fall through to a helper for subtype tests.
addSimpleTypeTests(ctor) => JS(
    '',
    '''(() => {
  $ctor.is = function is_C(object) {
    // This is incorrect for classes [Null] and [Object], so we do not use
    // [addSimpleTypeTests] for these classes.
    if (object instanceof this) return true;
    return dart.is(object, this);
  };
  $ctor.as = function as_C(object) {
    if (object instanceof this) return object;
    return dart.as(object, this);
  };
  $ctor._check = function check_C(object) {
    if (object instanceof this) return object;
    return dart.check(object, this);
  };
})()''');

/// Adds type type test predicates to a constructor. Used for parmeterized
/// types. We avoid `instanceof` for, e.g. `x is ListQueue` since there is
/// no common class for `ListQueue<int>` and `ListQueue<String>`.
addTypeTests(ctor) => JS(
    '',
    '''(() => {
  $ctor.as = function as_G(object) {
    return dart.as(object, this);
  };
  $ctor.is = function is_G(object) {
    return dart.is(object, this);
  };
  $ctor._check = function check_G(object) {
    return dart.check(object, this);
  };
})()''');

equals(x, y) => JS(
    '',
    '''(() => {
  if ($x == null || $y == null) return $x == $y;
  let eq = $x['=='];
  return eq ? eq.call($x, $y) : $x === $y;
})()''');

/// Checks that `x` is not null or undefined. */
notNull(x) {
  if (x == null) throwNullValueError();
  return x;
}

///
/// Creates a dart:collection LinkedHashMap.
///
/// For a map with string keys an object literal can be used, for example
/// `map({'hi': 1, 'there': 2})`.
///
/// Otherwise an array should be used, for example `map([1, 2, 3, 4])` will
/// create a map with keys [1, 3] and values [2, 4]. Each key-value pair
/// should be adjacent entries in the array.
///
/// For a map with no keys the function can be called with no arguments, for
/// example `map()`.
///
// TODO(jmesserly): this could be faster
// TODO(jmesserly): we can use default values `= dynamic` once #417 is fixed.
// TODO(jmesserly): move this to classes for consistentcy with list literals?
map(values, [K, V]) => JS(
    '',
    '''(() => {
  if ($K == null) $K = $dynamic;
  if ($V == null) $V = $dynamic;
  let map = ${getGenericClass(LinkedHashMap)}($K, $V).new();
  if (Array.isArray($values)) {
    for (let i = 0, end = $values.length - 1; i < end; i += 2) {
      let key = $values[i];
      let value = $values[i + 1];
      map._set(key, value);
    }
  } else if (typeof $values === 'object') {
    for (let key of $getOwnPropertyNames($values)) {
      map._set(key, $values[key]);
    }
  }
  return map;
})()''');

@JSExportName('assert')
assert_(condition) => JS(
    '',
    '''(() => {
  if (!$condition) $throwAssertionError();
})()''');

final _stack = JS('', 'new WeakMap()');
@JSExportName('throw')
throw_(obj) => JS(
    '',
    '''(() => {
  if ($obj != null && (typeof $obj == 'object' || typeof $obj == 'function')) {
    // TODO(jmesserly): couldn't we store the most recent stack in a single
    // variable? There should only be one active stack trace. That would
    // allow it to work for things like strings and numbers.
    $_stack.set($obj, new Error());
  }
  throw $obj;
})()''');

getError(exception) => JS(
    '',
    '''(() => {
  var stack = $_stack.get($exception);
  return stack !== void 0 ? stack : $exception;
})()''');

// This is a utility function: it is only intended to be called from dev
// tools.
stackPrint(exception) => JS(
    '',
    '''(() => {
  var error = $getError($exception);
  console.log(error.stack ? error.stack : 'No stack trace for: ' + error);
})()''');

stackTrace(exception) => JS(
    '',
    '''(() => {
  var error = $getError($exception);
  return $getTraceFromException(error);
})()''');

///
/// Implements a sequence of .? operations.
///
/// Will call each successive callback, unless one returns null, which stops
/// the sequence.
///
nullSafe(obj, @rest callbacks) => JS(
    '',
    '''(() => {
  if ($obj == null) return $obj;
  for (let callback of $callbacks) {
    $obj = callback($obj);
    if ($obj == null) break;
  }
  return $obj;
})()''');

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
multiKeyPutIfAbsent(map, keys, valueFn) => JS(
    '',
    '''(() => {
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
const_(obj) => JS(
    '',
    '''(() => {
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

///
/// Canonicalize a constant list
///
constList(elements, elementType) => JS(
    '',
    '''(() => {
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
  value = $list($elements, $elementType);
  map.set($elementType, value);
  return value;
})()''');

// The following are helpers for Object methods when the receiver
// may be null or primitive.  These should only be generated by
// the compiler.
hashCode(obj) {
  if (obj == null) return 0;

  switch (JS('String', 'typeof #', obj)) {
    case "number":
      return JS('', '# & 0x1FFFFFFF', obj);
    case "boolean":
      // From JSBool.hashCode, see comment there.
      return JS('', '# ? (2 * 3 * 23 * 3761) : (269 * 811)', obj);
    case "function":
      // TODO(jmesserly): this doesn't work for method tear-offs.
      return Primitives.objectHashCode(obj);
  }

  var extension = getExtensionType(obj);
  if (extension != null) {
    return JS('', '#[dartx.hashCode]', obj);
  }
  return JS('', '#.hashCode', obj);
}

@JSExportName('toString')
String _toString(obj) {
  if (obj == null) return "null";

  var extension = getExtensionType(obj);
  if (extension != null) {
    return JS('String', '#[dartx.toString]()', obj);
  }
  if (JS('bool', 'typeof # == "function"', obj)) {
    return JS(
        'String', r'"Closure: " + # + " from: " + #', getReifiedType(obj), obj);
  }
  // TODO(jmesserly): restore this faster path once ES Symbol is treated as
  // an extension type (and thus hits the above code path).
  // See https://github.com/dart-lang/dev_compiler/issues/578.
  // return JS('', '"" + #', obj);
  return JS('String', '#.toString()', obj);
}

// TODO(jmesserly): is the argument type verified statically?
noSuchMethod(obj, Invocation invocation) {
  if (obj == null || JS('bool', 'typeof # == "function"', obj)) {
    throw new NoSuchMethodError(obj, invocation.memberName,
        invocation.positionalArguments, invocation.namedArguments);
  }
  // Delegate to the (possibly user-defined) method on the object.
  var extension = getExtensionType(obj);
  if (extension != null) {
    return JS('', '#[dartx.noSuchMethod](#)', obj, invocation);
  }
  return JS('', '#.noSuchMethod(#)', obj, invocation);
}

constFn(x) => JS('', '() => x');

runtimeType(obj) {
  // Handle primitives where the method isn't on the object.
  var result = _checkPrimitiveType(obj);
  if (result != null) return wrapType(result);

  // Delegate to the (possibly user-defined) method on the object.
  var extension = getExtensionType(obj);
  if (extension != null) {
    result = JS('', '#[dartx.runtimeType]', obj);
    // If extension doesn't override runtimeType, return the extension type.
    return result ?? wrapType(extension);
  }
  if (JS('bool', 'typeof # == "function"', obj)) {
    return wrapType(getReifiedType(obj));
  }
  return JS('', '#.runtimeType', obj);
}

/// Implements Dart's interpolated strings as ES2015 tagged template literals.
///
/// For example: dart.str`hello ${name}`
String str(strings, @rest values) => JS(
    '',
    '''(() => {
  let s = $strings[0];
  for (let i = 0, len = $values.length; i < len; ) {
    s += $notNull($_toString($values[i])) + $strings[++i];
  }
  return s;
})()''');

final JsIterator = JS(
    '',
    '''
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

  if (obj != null && getExtensionType(obj) != null) {
    return JS('', 'dartx.#', name);
  }

  // Check for certain names that we can't use in JS
  if (name == 'constructor' || name == 'prototype') {
    name = '+' + name;
  }
  return name;
}

/// Emulates the implicit "loadLibrary" function provided by a deferred library.
///
/// Libraries are not actually deferred in DDC, so this just returns a future
/// that completes immediately.
Future loadLibrary() => new Future.value();
