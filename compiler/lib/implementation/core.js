// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helpers for lazy static initialization.
 */
var static$uninitialized = {};
var static$initializing = {};

function $maybeBindRtt(fun, fRtt, thisObj) {
  if (fRtt) {
    fun.$lookupRTT = function() {
      return fRtt.call(thisObj);
    }
  }
}

// Optimized versions of closure bindings.
// Name convention: $bind<number-of-scopes>_<number-of-arguments>(fn, this, scopes, args)
function $bind0_0(fn, fRtt, thisObj) {
  var fun = function() {
    return fn.call(thisObj);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind0_1(fn, fRtt, thisObj) {
  var fun = function(arg) {
    return fn.call(thisObj, arg);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind0_2(fn, fRtt, thisObj) {
  var fun = function(arg1, arg2) {
    return fn.call(thisObj, arg1, arg2);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind0_3(fn, fRtt, thisObj) {
  var fun = function(arg1, arg2, arg3) {
    return fn.call(thisObj, arg1, arg2, arg3);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind0_4(fn, fRtt, thisObj) {
  var fun = function(arg1, arg2, arg3, arg4) {
    return fn.call(thisObj, arg1, arg2, arg3, arg4);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind0_5(fn, fRtt, thisObj) {
  var fun = function(arg1, arg2, arg3, arg4, arg5) {
    return fn.call(thisObj, arg1, arg2, arg3, arg4, arg5);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}

function $bind1_0(fn, fRtt, thisObj, scope) {
  var fun = function() {
    return fn.call(thisObj, scope);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind1_1(fn, fRtt, thisObj, scope) {
  var fun = function(arg) {
    return fn.call(thisObj, scope, arg);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind1_2(fn, fRtt, thisObj, scope) {
  var fun = function(arg1, arg2) {
    return fn.call(thisObj, scope, arg1, arg2);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind1_3(fn, fRtt, thisObj, scope) {
  var fun = function(arg1, arg2, arg3) {
    return fn.call(thisObj, scope, arg1, arg2, arg3);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind1_4(fn, fRtt, thisObj, scope) {
  var fun = function(arg1, arg2, arg3, arg4) {
    return fn.call(thisObj, scope, arg1, arg2, arg3, arg4);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind1_5(fn, fRtt, thisObj, scope) {
  var fun = function(arg1, arg2, arg3, arg4, arg5) {
    return fn.call(thisObj, scope, arg1, arg2, arg3, arg4, arg5);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}

function $bind2_0(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function() {
    return fn.call(thisObj, scope1, scope2);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind2_1(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function(arg) {
    return fn.call(thisObj, scope1, scope2, arg);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind2_2(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function(arg1, arg2) {
    return fn.call(thisObj, scope1, scope2, arg1, arg2);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind2_3(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function(arg1, arg2, arg3) {
    return fn.call(thisObj, scope1, scope2, arg1, arg2, arg3);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind2_4(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function(arg1, arg2, arg3, arg4) {
    return fn.call(thisObj, scope1, scope2, arg1, arg2, arg3, arg4);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind2_5(fn, fRtt, thisObj, scope1, scope2) {
  var fun = function(arg1, arg2, arg3, arg4, arg5) {
    return fn.call(thisObj, scope1, scope2, arg1, arg2, arg3, arg4, arg5);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}

function $bind3_0(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function() {
    return fn.call(thisObj, scope1, scope2, scope3);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind3_1(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function(arg) {
    return fn.call(thisObj, scope1, scope2, scope3, arg);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind3_2(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function(arg1, arg2) {
    return fn.call(thisObj, scope1, scope2, scope3, arg1, arg2);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind3_3(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function(arg1, arg2, arg3) {
    return fn.call(thisObj, scope1, scope2, scope3, arg1, arg2, arg3);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind3_4(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function(arg1, arg2, arg3, arg4) {
    return fn.call(thisObj, scope1, scope2, scope3, arg1, arg2, arg3, arg4);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}
function $bind3_5(fn, fRtt, thisObj, scope1, scope2, scope3) {
  var fun = function(arg1, arg2, arg3, arg4, arg5) {
    return fn.call(thisObj, scope1, scope2, scope3, arg1, arg2, arg3, arg4, arg5);
  }
  $maybeBindRtt(fun, fRtt, thisObj);
  return fun;
}

/**
 * Implements extends for dart classes on javascript prototypes.
 * @param {Function} child
 * @param {Function} parent
 */
function $inherits(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}

/**
 * @param {Function} fn
 * @param {Function=} fRtt
 * @param {Object|undefined} thisObj
 * @param {...*} var_args
 */
function $bind(fn, fRtt, thisObj, var_args) {
  var func;
  if (arguments.length > 3) {
    var boundArgs = Array.prototype.slice.call(arguments, 3);
    func = function() {
      // Prepend the bound arguments to the current arguments.
      var newArgs = Array.prototype.slice.call(arguments);
      Array.prototype.unshift.apply(newArgs, boundArgs);
      return fn.apply(thisObj, newArgs);
    };
  } else {
    func = function() {
      return fn.apply(thisObj, arguments);
    };
  }
  if(fRtt) {
    func.$lookupRTT = function() {
      return fRtt.apply(thisObj, arguments);
    };
  }
  return func;
}

/**
 * Dart null object that should be used by JS implementation to test for
 * Dart null.
 *
 * TODO(ngeoffray): update dartc to generate this variable instead of
 *                  undefined.
 * @const
 */
var $Dart$Null = void 0;

function assert(expr) {
  var val = typeof(expr) == 'function' ? $dartcall(expr, []) : expr;
  if (val !== true) {
    $Dart$ThrowException(native_ExceptionHelper_createAssertionError());
  }
}

function BIT_OR$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 | val2
      : val1.BIT_OR$operator(val2);
}

function BIT_XOR$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 ^ val2
      : val1.BIT_XOR$operator(val2);
}

function BIT_AND$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 & val2
      : val1.BIT_AND$operator(val2);
}

function BIT_NOT$operator(val) {
  return (typeof(val) == 'number') ? ~val : val.BIT_NOT$operator();
}

function SHL$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 << val2
      : val1.SHL$operator(val2);
}

function SAR$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 >> val2
      : val1.SAR$operator(val2);
}

function SHR$operator(val1, val2) {
  return val1.SHR$operator(val2);
}

function ADD$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 + val2
      : val1.ADD$operator(val2);
}

function SUB$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 - val2
      : val1.SUB$operator(val2);
}

function MUL$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 * val2
      : val1.MUL$operator(val2);
}

function DIV$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 / val2
      : val1.DIV$operator(val2);
}

function MOD$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? number$euclideanModulo(val1, val2)
      : val1.MOD$operator(val2);
}

function TRUNC$operator(val1, val2) {
  if (typeof(val1) == 'number' && typeof(val2) == 'number') {
    var tmp = val1 / val2;
    return (tmp < 0) ? Math.ceil(tmp) : Math.floor(tmp);
  } else {
    return val1.TRUNC$operator(val2);
  }
}

function negate$operator(val) {
  return (typeof(val) == 'number') ? -val : val.negate$operator();
}

function EQ$operator(val1, val2) {
  return (typeof val1 != 'object')
      ? val1 === val2
      : val1.EQ$operator(val2);
}

function NE$operator(val1, val2) {
  return (typeof val1 != 'object')
      ? val1 !== val2
      : !val1.EQ$operator(val2);
}

function LT$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 < val2
      : val1.LT$operator(val2);
}

function GT$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 > val2
      : val1.GT$operator(val2);
}

function LTE$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 <= val2
      : val1.LTE$operator(val2);
}

function GTE$operator(val1, val2) {
  return (typeof(val1) == 'number' && typeof(val2) == 'number')
      ? val1 >= val2
      : val1.GTE$operator(val2);
}

// The following operator-functions are not called from Dart-generated code, but
// only from handwritten JS code.
function INDEX$operator(obj, index) {
  return obj.INDEX$operator(index);
}

function ASSIGN_INDEX$operator(obj, index, newVal) {
  obj.ASSIGN_INDEX$operator(index, newVal);
}

function $Dart$ThrowException(e) {
  // If e is not a value, we can use V8's captureStackTrace utility method.
  if (e && (typeof e == "object") && Error.captureStackTrace) {
    Error.captureStackTrace(e);
  }
  throw e;
}

function $toString(x) {
  return native__StringJsUtil_toDartString(x);
}

// Translate a JavaScript exception to a Dart exception
// TODO(zundel): cross browser support.  This is Chrome specific.
function $transformBrowserException(e) {
  if (e instanceof TypeError) {
    switch(e.type) {
    case "property_not_function":
    case "called_non_callable":
      if (e.arguments[0] == "undefined") {
        return native_ExceptionHelper_createNullPointerException();
      }
      return native_ExceptionHelper_createObjectNotClosureException();
    case "non_object_property_call":
    case "non_object_property_load":
      return native_ExceptionHelper_createNullPointerException();
    case "undefined_method":
      if (e.arguments[0] == "call" || e.arguments[0] == "apply") {
        return native_ExceptionHelper_createObjectNotClosureException();
      }
      return native_ExceptionHelper_createNoSuchMethodException(
          "", e.arguments[0], []);
    }
  }
  return e;
}

// Throws a NoSuchMethodException (used by named-parameter trampolines).
function $nsme() {
  var e = native_ExceptionHelper_createNoSuchMethodException("", "", []);
  $Dart$ThrowException(e);
}

// Throws a NoSuchMethodException (used when instantiating via a non-existent class or ctor).
function $nsme2(name, args) {
  var e = native_ExceptionHelper_createNoSuchMethodException(name, name, args);
  $Dart$ThrowException(e);
}

// Shared named-argument object used by call-sites with no named arguments.
/** @const */
var $noargs = {count:0};

// Used for invoking dart functions from js.
function $dartcall(fn, args) {
  args.unshift(args.length, $noargs);
  fn.apply(null, args);
}

//
// The following methods are used to create canonical constants.
//

function native_ConstHelper_getConstId(o) {
  return $dart_const_id(o);
}

// compile time const canonicalization helpers
function $dart_const_id(o) {
   if (o === $Dart$Null) return "";
   if (typeof o === "number") return "n" + o;
   if (typeof o === "boolean") return "b" + ((o) ? 1 : 0);
   if (typeof o === "string") return $dart_const_string_id(o);
   if (typeof o === "function") throw "a function is not a constant expression";
   var result = o.$dartConstId;
   if (result === undefined) {
     throw "internal error: reference to non-canonical constant";
   }
   return result;
}

// Array ids have the form: "aID,ID,ID"
function $dart_const_array_id(o) {
  var ids = [];
  for (var i=o.length-1; i>=0; i--) {
    ids.push($dart_const_id(o[i]));
  }
  return "a" + ids.join(",");
}

var $CONST_MAP_PREFIX = ":"

// String ids have the form "sID"
var $string_id = 0;
var $string_id_cache = {};
function $dart_const_string_id(s) {
  var key = $CONST_MAP_PREFIX + s;
  var id = $string_id_cache[key];
  if (!id) {
    id = "s" + (++$string_id);
    $string_id_cache[key] = id;
  }
  return id;
}

// A place to store the canonical consts
var $consts = {};

function $isDartMap(o) {
  return !!(o && o.$implements$Map$Dart);
}

// Intern const object "o"
function $intern(o, type_args) {
  var id;
  // Maps and arrays need special handling
  // TODO(johnlenz): This array check may not be sufficient across iframes.
  if (o instanceof Array) {
    // Dart array literals are implemented as JavaScript native arrays.
    id = $dart_const_array_id(o);
  } else if ($isDartMap(o)) {
    // Dart map literals are currently implemented by a non-const Dart class.
    id = native_ConstHelper_getConstMapId(o);
  } else {
    id = "o" + o.$const_id();
  }
  if (type_args != null) {
    id += '<';
    for (var i=type_args.length-1; i >= 0; i--) {
      id += type_args[i];
      id += ","
    }
    id += '>';
  }
  var key = $CONST_MAP_PREFIX + id;
  var match = $consts[key];
  if (match != null) {
    return match;
  }
  o.$dartConstId = id;
  $consts[key] = o;
  return o;
}

function $Dart$MapLiteralFactory() {
  return native__CoreJsUtil__newMapLiteral();
}
