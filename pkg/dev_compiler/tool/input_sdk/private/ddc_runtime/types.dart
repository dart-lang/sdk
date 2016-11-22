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

_isInstanceOfLazyJSType(o, LazyJSType t) {
  if (t._jsTypeCallback != null) {
    return JS('bool', 'dart.is(#, #)', o, t._rawJSType);
  }
  if (o == null) return false;
  // Anonymous case: match any JS type.
  return _isJSObject(o);
}

_asInstanceOfLazyJSType(o, LazyJSType t) {
  if (t._jsTypeCallback != null) {
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

final AbstractFunctionType = JS(
    '',
    '''
  class AbstractFunctionType extends $TypeRep {
    constructor() {
      super();
      this._stringValue = null;
    }

    toString() { return this.name; }

    get name() {
      if (this._stringValue) return this._stringValue;

      let buffer = '(';
      for (let i = 0; i < this.args.length; ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += $typeName(this.args[i]);
      }
      if (this.optionals.length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '[';
        for (let i = 0; i < this.optionals.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += $typeName(this.optionals[i]);
        }
        buffer += ']';
      } else if (Object.keys(this.named).length > 0) {
        if (this.args.length > 0) buffer += ', ';
        buffer += '{';
        let names = $getOwnPropertyNames(this.named).sort();
        for (let i = 0; i < names.length; ++i) {
          if (i > 0) {
            buffer += ', ';
          }
          buffer += names[i] + ': ' + $typeName(this.named[names[i]]);
        }
        buffer += '}';
      }

      buffer += ') -> ' + $typeName(this.returnType);
      this._stringValue = buffer;
      return buffer;
    }
  }
''');

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
final _fnTypeSmallMap = JS('', '[new Map(), new Map(), new Map()]');

final FunctionType = JS(
    '',
    '''
  class FunctionType extends $AbstractFunctionType {
    static _memoizeArray(map, arr, create) {
      let len = arr.length;
      map = FunctionType._lookupNonTerminal(map, len);
      for (var i = 0; i < len-1; ++i) {
        map = FunctionType._lookupNonTerminal(map, arr[i]);
      }
      let result = map.get(arr[len-1]);
      if (result !== void 0) return result;
      map.set(arr[len-1], result = create());
      return result;
    }

    // Map dynamic to bottom. If meta-data is present,
    // we slice off the remaining meta-data and make
    // it the second element of a packet for processing
    // later on in the constructor.
    static _normalizeParameter(a) {
      if (a instanceof Array) {
        let result = [];
        result.push((a[0] == $dynamic) ? $bottom : a[0]);
        result.push(a.slice(1));
        return result;
      }
      return (a == $dynamic) ? $bottom : a;
    }

    static _canonicalizeArray(definite, array, map) {
      let arr = (definite)
         ? array
         : array.map(FunctionType._normalizeParameter);
      return FunctionType._memoizeArray(map, arr, () => arr);
    }

    // TODO(leafp): This only canonicalizes of the names are
    // emitted in a consistent order.
    static _canonicalizeNamed(definite, named, map) {
      let key = [];
      let names = $getOwnPropertyNames(named);
      let r = {};
      for (var i = 0; i < names.length; ++i) {
        let name = names[i];
        let type = named[name];
        if (!definite) r[name] = type = FunctionType._normalizeParameter(type);
        key.push(name);
        key.push(type);
      }
      if (!definite) named = r;
      return FunctionType._memoizeArray(map, key, () => named);
    }

    static _lookupNonTerminal(map, key) {
      let result = map.get(key);
      if (result !== void 0) return result;
      map.set(key, result = new Map());
      return result;
    }

    // TODO(leafp): This handles some low hanging fruit, but
    // really we should make all of this faster, and also
    // handle more cases here.
    static _createSmall(count, definite, returnType, required) {
      let map = $_fnTypeSmallMap[count];
      let args = (definite) ? required
        : required.map(FunctionType._normalizeParameter);
      for (var i = 0; i < count; ++i) {
        map = FunctionType._lookupNonTerminal(map, args[i]);
     }
     let result = map.get(returnType);
     if (result !== void 0) return result;
     result = new FunctionType(returnType, args, [], {});
     map.set(returnType, result);
     return result;
    }
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
      if (extra === void 0 && args.length < 3) {
        return FunctionType._createSmall(
          args.length, definite, returnType, args);
      }
      args = FunctionType._canonicalizeArray(
        definite, args, $_fnTypeArrayArgMap);
      let keys;
      let create;
      if (extra === void 0) {
        keys = [returnType, args];
        create = () => new FunctionType(returnType, args, [], {});
      } else if (extra instanceof Array) {
        let optionals =
          FunctionType._canonicalizeArray(definite, extra, $_fnTypeArrayArgMap);
        keys = [returnType, args, optionals];
        create =
          () => new FunctionType(returnType, args, optionals, {});
      } else {
        let named =
          FunctionType._canonicalizeNamed(definite, extra, $_fnTypeNamedArgMap);
        keys = [returnType, args, named];
        create = () => new FunctionType(returnType, args, [], named);
      }
      return FunctionType._memoizeArray($_fnTypeTypeMap, keys, create);
    }

    constructor(returnType, args, optionals, named) {
      super();
      this.returnType = returnType;
      this.args = args;
      this.optionals = optionals;
      this.named = named;

      // TODO(vsm): This is just parameter metadata for now.
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
      // TODO(vsm): Add named arguments.
    }
  }
''');

final Typedef = JS(
    '',
    '''
  class Typedef extends $AbstractFunctionType {
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

    get metadata() {
      return this.functionType.metadata;
    }
  }
''');

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

typedef(name, closure) => JS('', 'new #(#, #)', Typedef, name, closure);

typeName(type) => JS(
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
  return getMethodTypeFromType(type, 'call');
}

bool isFunctionType(type) => JS('bool', '# instanceof # || # === #', type,
    AbstractFunctionType, type, Function);

isLazyJSSubtype(LazyJSType t1, LazyJSType t2, covariant) {
  if (t1 == t2) return true;

  // All anonymous JS types are subtypes of each other.
  if (t1._jsTypeCallback == null || t2._jsTypeCallback == null) return true;
  return isClassSubType(t1._rawJSType, t2._rawJSType, covariant);
}

/// Returns true if [ft1] <: [ft2].
/// Returns false if [ft1] </: [ft2] in both spec and strong mode
/// Returns null if [ft1] </: [ft2] in strong mode, but spec mode
/// may differ
/// If [covariant] is true, then we are checking subtyping in a covariant
/// position, and hence the direction of the check for function types
/// corresponds to the direction of the check according to the Dart spec.
isFunctionSubtype(ft1, ft2, covariant) => JS(
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
    return ($covariant) ? false : null;
  }

  for (let i = 0; i < args1.length; ++i) {
    if (!$_isSubtype(args2[i], args1[i], !$covariant)) {
      // Even if isSubtype returns false, assignability
      // means that we can't be definitive
      return null;
    }
  }

  let optionals1 = $ft1.optionals;
  let optionals2 = $ft2.optionals;

  if (args1.length + optionals1.length < args2.length + optionals2.length) {
    return ($covariant) ? false : null;
  }

  let j = 0;
  for (let i = args1.length; i < args2.length; ++i, ++j) {
    if (!$_isSubtype(args2[i], optionals1[j], !$covariant)) {
      return null;
    }
  }

  for (let i = 0; i < optionals2.length; ++i, ++j) {
    if (!$_isSubtype(optionals2[i], optionals1[j], !$covariant)) {
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
      return ($covariant) ? false : null;
    }
    if (!$_isSubtype(n2, n1, !$covariant)) {
      return null;
    }
  }

  // Check return type last, so that arity mismatched functions can be
  // definitively rejected.

  // We allow any type to subtype a void return type, but not vice versa
  if (ret2 === $_void) return true;
  // Dart allows void functions to subtype dynamic functions, but not
  // other functions.
  if (ret1 === $_void) return (ret2 === $dynamic);
  if (!$_isSubtype(ret1, ret2, $covariant)) return null;
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

_isBottom(type) => JS('bool', '# == #', type, bottom);

_isTop(type) => JS('bool', '# == # || # == #', type, Object, type, dynamic);

_isSubtype(t1, t2, covariant) => JS(
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

  // "Traditional" name-based subtype check.  Avoid passing
  // function types to the class subtype checks, since we don't
  // currently distinguish between generic typedefs and classes.
  if (!($t1 instanceof $AbstractFunctionType) &&
      !($t2 instanceof $AbstractFunctionType)) {
    let result = $isClassSubType($t1, $t2, $covariant);
    if (result === true || result === null) return result;
  }

  // Function subtyping.

  // Handle Objects with call methods.  Those are functions
  // even if they do not *nominally* subtype core.Function.
  t1 = $getImplicitFunctionType(t1);
  if (!t1) return false;

  if ($isFunctionType($t1) && $isFunctionType($t2)) {
    return $isFunctionSubtype($t1, $t2, $covariant);
  }
  
  if ($t1 instanceof $LazyJSType && $t2 instanceof $LazyJSType) {
    return $isLazyJSSubtype($t1, $t2, $covariant);
  }
  
  return false;
})()''');

isClassSubType(t1, t2, covariant) => JS(
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
          $_isSubtype(typeArguments1[i], typeArguments2[i], $covariant);
      if (!result) {
        return result;
      }
    }
    return true;
  }

  let indefinite = false;
  function definitive(t1, t2) {
    let result = $isClassSubType(t1, t2, $covariant);
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
