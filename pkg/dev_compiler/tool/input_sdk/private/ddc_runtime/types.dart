// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the representation of runtime types.
part of dart._runtime;

final metadata = JS('', 'Symbol("metadata")');

/// The symbol used to store the cached `Type` object associated with a class.
final _typeObject = JS('', 'Symbol("typeObject")');

/// Types in dart are represented internally at runtime as follows.
///
///   - Normal nominal types, produced from classes, are represented
///     at runtime by the JS class of which they are an instance.
///     If the type is the result of instantiating a generic class,
///     then the "classes" module manages the association between the
///     instantiated class and the original class declaration
///     and the type arguments with which it was instantiated.  This
///     assocation can be queried via the "classes" module".
///
///   - All other types are represented as instances of class TypeRep,
///     defined in this module.
///     - Dynamic, Void, and Bottom are singleton instances of sentinal
///       classes.
///     - Function types are instances of subclasses of AbstractFunctionType.
///
/// Function types are represented in one of two ways:
///   - As an instance of FunctionType.  These are eagerly computed.
///   - As an instance of TypeDef.  The TypeDef representation lazily
///     computes an instance of FunctionType, and delegates to that instance.
///
/// These above "runtime types" are what is used for implementing DDC's
/// internal type checks. These objects are distinct from the objects exposed
/// to user code by class literals and calling `Object.runtimeType`. In DDC,
/// the latter are represented by instances of WrappedType which contain a
/// real runtime type internally. This ensures that the returned object only
/// exposes the API that Type defines:
///
///     get String name;
///     String toString();
///
/// These "runtime types" have methods for performing type checks. The methods
/// have the following JavaScript names which are designed to not collide with
/// static methods, which are also placed 'on' the class constructor function.
///
///     T.is(o): Implements 'o is T'.
///     T.as(o): Implements 'o as T'.
///     T._check(o): Implements the type assertion of 'T x = o;'
///
/// By convention, we used named JavaScript functions for these methods with the
/// name 'is_X', 'as_X' and 'check_X' for various X to indicate the type or the
/// implementation strategy for the test (e.g 'is_String', 'is_G' for generic
/// types, etc.)
// TODO(jmesserly): we shouldn't implement Type here. It should be moved down
// to AbstractFunctionType.
class TypeRep implements Type {
  TypeRep() {
    _initialize;
  }
  String get name => this.toString();
}

class Dynamic extends TypeRep {
  toString() => 'dynamic';
}

class LazyJSType implements Type {
  final _jsTypeCallback;
  final _dartName;

  LazyJSType(this._jsTypeCallback, this._dartName);

  get _rawJSType => JS('', '#()', _jsTypeCallback);

  toString() => _jsTypeCallback != null ? typeName(_rawJSType) : _dartName;
}

void _warn(arg) {
  JS('void', 'console.warn(#)', arg);
}

_isInstanceOfLazyJSType(o, LazyJSType t) {
  if (t._jsTypeCallback != null) {
    if (t._rawJSType == null) {
      var expected = t._dartName;
      var actual = typeName(getReifiedType(o));
      _warn('Cannot find native JavaScript type ($expected) '
          'to type check $actual');
      return true;
    }
    return JS('bool', 'dart.is(#, #)', o, t._rawJSType);
  }
  if (o == null) return false;
  // Anonymous case: match any JS type.
  return _isJSObject(o);
}

_asInstanceOfLazyJSType(o, LazyJSType t) {
  if (t._jsTypeCallback != null) {
    if (t._rawJSType == null) {
      var expected = t._dartName;
      var actual = typeName(getReifiedType(o));
      _warn('Cannot find native JavaScript type ($expected) '
          'to type check $actual');
      return o;
    }
    return JS('bool', 'dart.as(#, #)', o, t._rawJSType);
  }
  // Anonymous case: allow any JS type.
  if (o == null) return null;
  if (!_isJSObject(o)) _throwCastError(o, t, true);
  return o;
}

bool _isJSObject(o) => JS('bool', '!dart.getReifiedType(o)[dart._runtimeType]');

@JSExportName('dynamic')
final _dynamic = new Dynamic();

final _initialize = _initialize2();

_initialize2() => JS(
    '',
    '''(() => {
  // JavaScript API forwards to runtime library.
  $TypeRep.prototype.is = function is_T(object) {
    return dart.is(object, this);
  };
  $TypeRep.prototype.as = function as_T(object) {
    return dart.as(object, this);
  };
  $TypeRep.prototype._check = function check_T(object) {
    return dart.check(object, this);
  };

  // Fast path for type `dynamic`.
  $Dynamic.prototype.is = function is_Dynamic(object) {
    return true;
  };
  $Dynamic.prototype.as = function as_Dynamic(object) {
    return object;
  };
  $Dynamic.prototype._check = function check_Dynamic(object) {
    return object;
  };

  $LazyJSType.prototype.is = function is_T(object) {
    return $_isInstanceOfLazyJSType(object, this);
  };
  $LazyJSType.prototype.as = function as_T(object) {
    return $_asInstanceOfLazyJSType(object, this);
  };
  $LazyJSType.prototype._check = function check_T(object) {
    return $_asInstanceOfLazyJSType(object, this);
  };
})()''');

class Void extends TypeRep {
  toString() => 'void';
}

@JSExportName('void')
final _void = new Void();

class Bottom extends TypeRep {
  toString() => 'bottom';
}

final bottom = new Bottom();

class JSObject extends TypeRep {
  toString() => 'NativeJavaScriptObject';
}

final jsobject = new JSObject();

class WrappedType extends Type {
  final _wrappedType;
  WrappedType(this._wrappedType);
  toString() => typeName(_wrappedType);
}

abstract class AbstractFunctionType extends TypeRep {
  String _stringValue = null;
  get args;
  get optionals;
  get metadata;
  get named;
  get returnType;

  AbstractFunctionType() {}

  toString() {
    return name;
  }

  get name {
    if (_stringValue != null) return _stringValue;

    var buffer = '(';
    for (var i = 0; JS('bool', '# < #.length', i, args); ++i) {
      if (i > 0) {
        buffer += ', ';
      }
      buffer += typeName(JS('', '#[#]', args, i));
    }
    if (JS('bool', '#.length > 0', optionals)) {
      if (JS('bool', '#.length > 0', args)) buffer += ', ';
      buffer += '[';
      for (var i = 0; JS('bool', '# < #.length', i, optionals); ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += typeName(JS('', '#[#]', optionals, i));
      }
      buffer += ']';
    } else if (JS('bool', 'Object.keys(#).length > 0', named)) {
      if (JS('bool', '#.length > 0', args)) buffer += ', ';
      buffer += '{';
      var names = getOwnPropertyNames(named);
      JS('', '#.sort()', names);
      for (var i = 0; JS('', '# < #.length', i, names); ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        var typeNameString = typeName(JS('', '#[#[#]]', named, names, i));
        buffer += '${JS('', '#[#]', names, i)}: $typeNameString';
      }
      buffer += '}';
    }

    var returnTypeName = typeName(returnType);
    buffer += ') -> $returnTypeName';
    _stringValue = buffer;
    return buffer;
  }
}

/// Memo table for named argument groups. A named argument packet
/// {name1 : type1, ..., namen : typen} corresponds to the path
/// n, name1, type1, ...., namen, typen.  The element of the map
/// reached via this path (if any) is the canonical representative
/// for this packet.
final _fnTypeNamedArgMap = JS('', 'new Map()');

/// Memo table for positional argument groups. A positional argument
/// packet [type1, ..., typen] (required or optional) corresponds to
/// the path n, type1, ...., typen.  The element reached via
/// this path (if any) is the canonical representative for this
/// packet. Note that required and optional parameters packages
/// may have the same canonical representation.
final _fnTypeArrayArgMap = JS('', 'new Map()');

/// Memo table for function types. The index path consists of the
/// path length - 1, the returnType, the canonical positional argument
/// packet, and if present, the canonical optional or named argument
/// packet.  A level of indirection could be avoided here if desired.
final _fnTypeTypeMap = JS('', 'new Map()');

/// Memo table for small function types with no optional or named
/// arguments and less than a fixed n (currently 3) number of
/// required arguments.  Indexing into this table by the number
/// of required arguments yields a map which is indexed by the
/// argument types themselves.  The element reached via this
/// index path (if present) is the canonical function type.
final List _fnTypeSmallMap = JS('', '[new Map(), new Map(), new Map()]');

_memoizeArray(map, arr, create) => JS(
    '',
    '''(() => {
  let len = $arr.length;
  $map = $_lookupNonTerminal($map, len);
  for (var i = 0; i < len-1; ++i) {
    $map = $_lookupNonTerminal($map, $arr[i]);
  }
  let result = $map.get($arr[len-1]);
  if (result !== void 0) return result;
  $map.set($arr[len-1], result = $create());
  return result;
})()''');

// Map dynamic to bottom. If meta-data is present,
// we slice off the remaining meta-data and make
// it the second element of a packet for processing
// later on in the constructor.
_normalizeParameter(a) => JS(
    '',
    '''(() => {
  if ($a instanceof Array) {
    let result = [];
    result.push(($a[0] == $dynamic) ? $bottom : $a[0]);
    result.push($a.slice(1));
    return result;
  }
  return ($a == $dynamic) ? $bottom : $a;
})()''');

_canonicalizeArray(definite, array, map) => JS(
    '',
    '''(() => {
  let arr = ($definite)
     ? $array
     : $array.map($_normalizeParameter);
  return $_memoizeArray($map, arr, () => arr);
})()''');

// TODO(leafp): This only canonicalizes of the names are
// emitted in a consistent order.
_canonicalizeNamed(definite, named, map) => JS(
    '',
    '''(() => {
  let key = [];
  let names = $getOwnPropertyNames($named);
  let r = {};
  for (var i = 0; i < names.length; ++i) {
    let name = names[i];
    let type = $named[name];
    if (!definite) r[name] = type = $_normalizeParameter(type);
    key.push(name);
    key.push(type);
  }
  if (!$definite) $named = r;
  return $_memoizeArray($map, key, () => $named);
})()''');

_lookupNonTerminal(map, key) => JS(
    '',
    '''(() => {
  let result = $map.get($key);
  if (result !== void 0) return result;
  $map.set($key, result = new Map());
  return result;
})()''');

// TODO(leafp): This handles some low hanging fruit, but
// really we should make all of this faster, and also
// handle more cases here.
_createSmall(count, definite, returnType, required) => JS(
    '',
    '''(() => {
  let map = $_fnTypeSmallMap[$count];
  let args = ($definite) ? $required
    : $required.map($_normalizeParameter);
  for (var i = 0; i < $count; ++i) {
    map = $_lookupNonTerminal(map, args[i]);
 }
 let result = map.get($returnType);
 if (result !== void 0) return result;
 result = new $FunctionType($returnType, args, [], {});
 map.set($returnType, result);
 return result;
})()''');

class FunctionType extends AbstractFunctionType {
  final returnType;
  dynamic args;
  dynamic optionals;
  final named;
  dynamic metadata;

  /**
   * Construct a function type. There are two arrow constructors,
   * distinguished by the "definite" flag.
   *
   * The fuzzy arrow (definite is false) treats any arguments
   * of type dynamic as having type bottom, and will always be
   * called with a dynamic invoke.
   *
   * The definite arrow (definite is true) leaves arguments unchanged.
   *
   * We eagerly normalize the argument types to avoid having to deal with
   * this logic in multiple places.
   *
   * This code does best effort canonicalization.  It does not guarantee
   * that all instances will share.
   *
   */
  static create(definite, returnType, args, extra) {
    // Note that if extra is ever passed as an empty array
    // or an empty map, we can end up with semantically
    // identical function types that don't canonicalize
    // to the same object since we won't fall into this
    // fast path.
    if (JS('bool', '# === void 0', extra) && JS('', '#.length < 3', args)) {
      return _createSmall(JS('', '#.length', args), definite, returnType, args);
    }
    args = _canonicalizeArray(definite, args, _fnTypeArrayArgMap);
    var keys;
    var create;
    if (JS('bool', '# === void 0', extra)) {
      keys = [returnType, args];
      create = () => new FunctionType(returnType, args, [], JS('', '{}'));
    } else if (JS('bool', '# instanceof Array', extra)) {
      var optionals = _canonicalizeArray(definite, extra, _fnTypeArrayArgMap);
      keys = [returnType, args, optionals];
      create =
          () => new FunctionType(returnType, args, optionals, JS('', '{}'));
    } else {
      var named = _canonicalizeNamed(definite, extra, _fnTypeNamedArgMap);
      keys = [returnType, args, named];
      create = () => new FunctionType(returnType, args, [], named);
    }
    return _memoizeArray(_fnTypeTypeMap, keys, create);
  }

  _process(array, metadata) {
    var result = [];
    for (var i = 0; JS('bool', '# < #.length', i, array); ++i) {
      var arg = JS('', '#[#]', array, i);
      if (JS('bool', '# instanceof Array', arg)) {
        metadata.add(JS('', '#.slice(1)', arg));
        result.add(JS('', '#[0]', arg));
      } else {
        JS('', '#.push([])', metadata);
        JS('', '#.push(#)', result, arg);
      }
    }
    return result;
  }

  FunctionType(this.returnType, this.args, this.optionals, this.named) {
    // TODO(vsm): This is just parameter metadata for now.
    metadata = [];
    this.args = _process(this.args, metadata);
    this.optionals = _process(this.optionals, metadata);
    // TODO(vsm): Add named arguments.
  }
}

// TODO(jacobr): we can't define this typedef due to execution order issues.
//typedef AbstractFunctionType FunctionTypeClosure();

class Typedef extends AbstractFunctionType {
  dynamic _name;
  dynamic /*FunctionTypeClosure*/ _closure;
  AbstractFunctionType _functionType;

  Typedef(this._name, this._closure) {}

  get name {
    return _name;
  }

  AbstractFunctionType get functionType {
    if (_functionType == null) {
      _functionType = JS('', '#()', _closure);
    }
    return _functionType;
  }

  get returnType {
    return functionType.returnType;
  }

  List get args {
    return functionType.args;
  }

  List get optionals {
    return functionType.optionals;
  }

  get named {
    return functionType.named;
  }

  List get metadata {
    return functionType.metadata;
  }
}

typedef(name, /*FunctionTypeClosure*/ closure) {
  return new Typedef(name, closure);
}

final _typeFormalCount = JS('', 'Symbol("_typeFormalCount")');

_functionType(definite, returnType, args, extra) => JS(
    '',
    '''(() => {
  // TODO(jmesserly): this is a bit of a retrofit, to easily fit
  // generic functions into all of the existing ways we generate function
  // signatures. Given `(T) => [T, [T]]` we'll return a function that does
  // `(T) => _functionType(definite, T, [T])` ... we could do this in the
  // compiler instead, at a slight cost to code size.
  if ($args === void 0 && $extra === void 0) {
    const fnTypeParts = $returnType;
    // A closure that computes the remaining arguments.
    // Return a function that makes the type.
    function makeGenericFnType(...types) {
      let parts = fnTypeParts.apply(null, types);
      return $FunctionType.create($definite, parts[0], parts[1], parts[2]);
    }
    makeGenericFnType[$_typeFormalCount] = fnTypeParts.length;
    return makeGenericFnType;
  }
  return $FunctionType.create($definite, $returnType, $args, $extra);
})()''');

///
/// Create a "fuzzy" function type.  If any arguments are dynamic
/// they will be replaced with bottom.
///
functionType(returnType, args, extra) =>
    _functionType(false, returnType, args, extra);

///
/// Create a definite function type. No substitution of dynamic for
/// bottom occurs.
///
definiteFunctionType(returnType, args, extra) =>
    _functionType(true, returnType, args, extra);

bool isType(obj) => JS(
    '',
    '''(() => {
  return $_getRuntimeType($obj) === $Type;
  })()''');

String typeName(type) => JS(
    '',
    '''(() => {
  if ($type === void 0) return "undefined type";
  if ($type === null) return "null type";
  // Non-instance types
  if ($type instanceof $TypeRep) {
    if ($type instanceof $Typedef) {
      return $type.name + "(" + $type.functionType.toString() + ")";
    }
    return $type.toString();
  }

  // Wrapped types
  if ($type instanceof $WrappedType) {
    return "Wrapped(" + $unwrapType($type) + ")";
  }

  // Instance types
  let tag = $_getRuntimeType($type);
  if (tag === $Type) {
    let name = $type.name;
    let args = $getGenericArgs($type);
    if (!args) return name;

    let result = name;
    let allDynamic = true;

    result += '<';
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) result += ', ';

      let argName = $typeName(args[i]);
      if (argName != 'dynamic') allDynamic = false;

      result += argName;
    }
    result += '>';

    // Don't print the type arguments if they are all dynamic. Show "raw"
    // types as just the bare type name.
    if (allDynamic) return name;
    return result;
  }
  if (tag) return "Not a type: " + tag.name;
  return "JSObject<" + $type.name + ">";
})()''');

/// Get the underlying function type, potentially from the call method
/// for a class type.
getImplicitFunctionType(type) {
  if (isFunctionType(type)) return type;
  return getMethodType(type, 'call');
}

bool isFunctionType(type) => JS('bool', '# instanceof # || # === #', type,
    AbstractFunctionType, type, Function);

isLazyJSSubtype(LazyJSType t1, LazyJSType t2, isCovariant) {
  if (t1 == t2) return true;

  // All anonymous JS types are subtypes of each other.
  if (t1._jsTypeCallback == null || t2._jsTypeCallback == null) return true;
  return isClassSubType(t1._rawJSType, t2._rawJSType, isCovariant);
}

/// Returns true if [ft1] <: [ft2].
/// Returns false if [ft1] </: [ft2] in both spec and strong mode
/// Returns null if [ft1] </: [ft2] in strong mode, but spec mode
/// may differ
/// If [isCovariant] is true, then we are checking subtyping in a covariant
/// position, and hence the direction of the check for function types
/// corresponds to the direction of the check according to the Dart spec.
isFunctionSubtype(ft1, ft2, isCovariant) => JS(
    '',
    '''(() => {
  if ($ft2 === $Function) {
    return true;
  }

  if ($ft1 === $Function) {
    return false;
  }

  let ret1 = $ft1.returnType;
  let ret2 = $ft2.returnType;

  let args1 = $ft1.args;
  let args2 = $ft2.args;

  if (args1.length > args2.length) {
    // If we're in a covariant position, then Dart's arity rules
    // agree with strong mode, otherwise we can't be sure.
    return ($isCovariant) ? false : null;
  }

  for (let i = 0; i < args1.length; ++i) {
    if (!$_isSubtype(args2[i], args1[i], !$isCovariant)) {
      // Even if isSubtype returns false, assignability
      // means that we can't be definitive
      return null;
    }
  }

  let optionals1 = $ft1.optionals;
  let optionals2 = $ft2.optionals;

  if (args1.length + optionals1.length < args2.length + optionals2.length) {
    return ($isCovariant) ? false : null;
  }

  let j = 0;
  for (let i = args1.length; i < args2.length; ++i, ++j) {
    if (!$_isSubtype(args2[i], optionals1[j], !$isCovariant)) {
      return null;
    }
  }

  for (let i = 0; i < optionals2.length; ++i, ++j) {
    if (!$_isSubtype(optionals2[i], optionals1[j], !$isCovariant)) {
      return null;
    }
  }

  let named1 = $ft1.named;
  let named2 = $ft2.named;

  let names = $getOwnPropertyNames(named2);
  for (let i = 0; i < names.length; ++i) {
    let name = names[i];
    let n1 = named1[name];
    let n2 = named2[name];
    if (n1 === void 0) {
      return ($isCovariant) ? false : null;
    }
    if (!$_isSubtype(n2, n1, !$isCovariant)) {
      return null;
    }
  }

  // Check return type last, so that arity mismatched functions can be
  // definitively rejected.

  // For `void` we will give the same answer as the VM, so don't return null.
  if (ret1 === $_void) return $_isTop(ret2);

  if (!$_isSubtype(ret1, ret2, $isCovariant)) return null;
  return true;
})()''');

/// TODO(leafp): This duplicates code in operations.dart.
/// I haven't found a way to factor it out that makes the
/// code generator happy though.
_subtypeMemo(f) => JS(
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

/// Returns true if [t1] <: [t2].
/// Returns false if [t1] </: [t2] in both spec and strong mode
/// Returns undefined if [t1] </: [t2] in strong mode, but spec
///  mode may differ
final isSubtype = JS(
    '', '$_subtypeMemo((t1, t2) => (t1 === t2) || $_isSubtype(t1, t2, true))');

_isBottom(type) => JS('bool', '# == # || # == #', type, bottom, type, Null);

_isTop(type) {
  if (_isFutureOr(type)) {
    return _isTop(JS('', '#[0]', getGenericArgs(type)));
  }
  return JS('bool', '# == # || # == # || # == #', type, Object, type, dynamic,
      type, _void);
}

bool _isFutureOr(type) =>
    JS('bool', '# === #', getGenericClass(type), getGenericClass(FutureOr));

_isSubtype(t1, t2, isCovariant) => JS(
    '',
    '''(() => {
  if ($t1 === $t2) return true;

  // Trivially true.
  if ($_isTop($t2) || $_isBottom($t1)) {
    return true;
  }

  // Trivially false.
  if ($_isBottom($t2)) return null;
  if ($_isTop($t1)) {
    if ($t1 === $dynamic) return null;
    return false;
  }

  // Handle FutureOr<T> union type.
  if ($_isFutureOr($t1)) {
    let t1TypeArg = $getGenericArgs($t1)[0];
    if ($_isFutureOr($t2)) {
      let t2TypeArg = $getGenericArgs($t2)[0];
      // FutureOr<A> <: FutureOr<B> iff A <: B
      return $_isSubtype(t1TypeArg, t2TypeArg, $isCovariant);
    }

    // given t1 is Future<A> | A, then:
    // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
    let t1Future = ${getGenericClass(Future)}(t1TypeArg);
    return $_isSubtype(t1Future, $t2, $isCovariant) &&
        $_isSubtype(t1TypeArg, $t2, $isCovariant);
  }

  if ($_isFutureOr($t2)) {
    // given t2 is Future<A> | A, then:
    // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
    let t2TypeArg = $getGenericArgs($t2)[0];
    var t2Future = ${getGenericClass(Future)}(t2TypeArg);
    let s1 = $_isSubtype($t1, t2Future, $isCovariant);
    let s2 = $_isSubtype($t1, t2TypeArg, $isCovariant);
    if (s1 === true || s2 === true) return true;
    if (s1 === null || s2 === null) return null;
    return false;
  }

  // "Traditional" name-based subtype check.  Avoid passing
  // function types to the class subtype checks, since we don't
  // currently distinguish between generic typedefs and classes.
  if (!($t1 instanceof $AbstractFunctionType) &&
      !($t2 instanceof $AbstractFunctionType)) {
    let result = $isClassSubType($t1, $t2, $isCovariant);
    if (result === true || result === null) return result;
  }

  // Function subtyping.

  // Handle Objects with call methods.  Those are functions
  // even if they do not *nominally* subtype core.Function.
  t1 = $getImplicitFunctionType(t1);
  if (!t1) return false;

  if ($isFunctionType($t1) && $isFunctionType($t2)) {
    return $isFunctionSubtype($t1, $t2, $isCovariant);
  }
  
  if ($t1 instanceof $LazyJSType && $t2 instanceof $LazyJSType) {
    return $isLazyJSSubtype($t1, $t2, $isCovariant);
  }
  
  return false;
})()''');

isClassSubType(t1, t2, isCovariant) => JS(
    '',
    '''(() => {
  // We support Dart's covariant generics with the caveat that we do not
  // substitute bottom for dynamic in subtyping rules.
  // I.e., given T1, ..., Tn where at least one Ti != dynamic we disallow:
  // - S !<: S<T1, ..., Tn>
  // - S<dynamic, ..., dynamic> !<: S<T1, ..., Tn>
  if ($t1 == $t2) return true;

  if ($t1 == $Object) return false;

  // If t1 is a JS Object, we may not hit core.Object.
  if ($t1 == null) return $t2 == $Object || $t2 == $dynamic;

  // Check if t1 and t2 have the same raw type.  If so, check covariance on
  // type parameters.
  let raw1 = $getGenericClass($t1);
  let raw2 = $getGenericClass($t2);
  if (raw1 != null && raw1 == raw2) {
    let typeArguments1 = $getGenericArgs($t1);
    let typeArguments2 = $getGenericArgs($t2);
    let length = typeArguments1.length;
    if (typeArguments2.length == 0) {
      // t2 is the raw form of t1
      return true;
    } else if (length == 0) {
      // t1 is raw, but t2 is not
      if (typeArguments2.every($_isTop)) return true;
      return null;
    }
    $assert_(length == typeArguments2.length);
    for (let i = 0; i < length; ++i) {
      let result =
          $_isSubtype(typeArguments1[i], typeArguments2[i], $isCovariant);
      if (!result) {
        return result;
      }
    }
    return true;
  }

  let indefinite = false;
  function definitive(t1, t2) {
    let result = $isClassSubType(t1, t2, $isCovariant);
    if (result == null) {
      indefinite = true;
      return false;
    }
    return result;
  }

  if (definitive($t1.__proto__, $t2)) return true;

  // Check mixins.
  let mixins = $getMixins($t1);
  if (mixins) {
    for (let m1 of mixins) {
      // TODO(jmesserly): remove the != null check once we can load core libs.
      if (m1 != null && definitive(m1, $t2)) return true;
    }
  }

  // Check interfaces.
  let getInterfaces = $getImplements($t1);
  if (getInterfaces) {
    for (let i1 of getInterfaces()) {
      // TODO(jmesserly): remove the != null check once we can load core libs.
      if (i1 != null && definitive(i1, $t2)) return true;
    }
  }

  // We found no definite supertypes, and at least one indefinite supertype
  // so the answer is indefinite.
  if (indefinite) return null;
  // We found no definite supertypes and no indefinite supertypes, so we
  // can return false.
  return false;
})()''');

// TODO(jmesserly): this isn't currently used, but it could be if we want
// `obj is NonGroundType<T,S>` to be rejected at runtime instead of compile
// time.
isGroundType(type) => JS(
    '',
    '''(() => {
  // TODO(vsm): Cache this if we start using it at runtime.

  if ($type instanceof $AbstractFunctionType) {
    if (!$_isTop($type.returnType)) return false;
    for (let i = 0; i < $type.args.length; ++i) {
      if (!$_isBottom($type.args[i])) return false;
    }
    for (let i = 0; i < $type.optionals.length; ++i) {
      if (!$_isBottom($type.optionals[i])) return false;
    }
    let names = $getOwnPropertyNames($type.named);
    for (let i = 0; i < names.length; ++i) {
      if (!$_isBottom($type.named[names[i]])) return false;
    }
    return true;
  }

  let typeArgs = $getGenericArgs($type);
  if (!typeArgs) return true;
  for (let t of typeArgs) {
    if (t != $Object && t != $dynamic) return false;
  }
  return true;
})()''');
