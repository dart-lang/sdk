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
///     association can be queried via the "classes" module".
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
  String get name => this.toString();

  // TODO(jmesserly): these should never be reached.
  @JSExportName('is')
  bool is_T(object) => instanceOf(object, this);

  @JSExportName('as')
  as_T(object) => cast(object, this, false);

  @JSExportName('_check')
  check_T(object) => cast(object, this, true);
}

class Dynamic extends TypeRep {
  toString() => 'dynamic';

  @JSExportName('is')
  bool is_T(object) => true;

  @JSExportName('as')
  as_T(object) => object;

  @JSExportName('_check')
  check_T(object) => object;
}

class LazyJSType extends TypeRep {
  final Function() _rawJSType;
  final String _dartName;

  LazyJSType(this._rawJSType, this._dartName);

  toString() => typeName(_rawJSType());

  rawJSTypeForCheck() {
    var raw = _rawJSType();
    if (raw != null) return raw;
    _warn('Cannot find native JavaScript type ($_dartName) for type check');
    return JS('', '#.Object', global_);
  }

  @JSExportName('is')
  bool is_T(obj) {
    return JS('bool', '# instanceof #', obj, rawJSTypeForCheck());
  }

  @JSExportName('as')
  as_T(obj) =>
      JS('bool', '# instanceof #', obj, rawJSTypeForCheck()) || obj == null
          ? obj
          : castError(obj, this, false);

  @JSExportName('_check')
  check_T(obj) =>
      JS('bool', '# instanceof #', obj, rawJSTypeForCheck()) || obj == null
          ? obj
          : castError(obj, this, true);
}

/// An anonymous JS type
///
/// For the purposes of subtype checks, these match any JS type.
class AnonymousJSType extends TypeRep {
  final String _dartName;
  AnonymousJSType(this._dartName);
  toString() => _dartName;

  @JSExportName('is')
  bool is_T(obj) => JS('bool', '# === # || #', getReifiedType(obj), jsobject,
      instanceOf(obj, this));

  @JSExportName('as')
  as_T(obj) =>
      JS('bool', '# == null || # === #', obj, getReifiedType(obj), jsobject)
          ? obj
          : cast(obj, this, false);

  @JSExportName('_check')
  check_T(obj) =>
      JS('bool', '# == null || # === #', obj, getReifiedType(obj), jsobject)
          ? obj
          : cast(obj, this, true);
}

void _warn(arg) {
  JS('void', 'console.warn(#)', arg);
}

var _lazyJSTypes = JS('', 'new Map()');
var _anonymousJSTypes = JS('', 'new Map()');

lazyJSType(Function() getJSTypeCallback, String name) {
  var ret = JS('', '#.get(#)', _lazyJSTypes, name);
  if (ret == null) {
    ret = new LazyJSType(getJSTypeCallback, name);
    JS('', '#.set(#, #)', _lazyJSTypes, name, ret);
  }
  return ret;
}

anonymousJSType(String name) {
  var ret = JS('', '#.get(#)', _anonymousJSTypes, name);
  if (ret == null) {
    ret = new AnonymousJSType(name);
    JS('', '#.set(#, #)', _anonymousJSTypes, name, ret);
  }
  return ret;
}

@JSExportName('dynamic')
final _dynamic = new Dynamic();

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

// Marker class for generic functions, typedefs, and non-generic functions.
abstract class AbstractFunctionType extends TypeRep {}

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

_memoizeArray(map, arr, create) => JS('', '''(() => {
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
_normalizeParameter(a) => JS('', '''(() => {
  if ($a instanceof Array) {
    let result = [];
    result.push(($a[0] == $dynamic) ? $bottom : $a[0]);
    result.push($a.slice(1));
    return result;
  }
  return ($a == $dynamic) ? $bottom : $a;
})()''');

List _canonicalizeArray(definite, array, map) => JS('', '''(() => {
  let arr = ($definite)
     ? $array
     : $array.map($_normalizeParameter);
  return $_memoizeArray($map, arr, () => arr);
})()''');

// TODO(leafp): This only canonicalizes of the names are
// emitted in a consistent order.
_canonicalizeNamed(definite, named, map) => JS('', '''(() => {
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

_lookupNonTerminal(map, key) => JS('', '''(() => {
  let result = $map.get($key);
  if (result !== void 0) return result;
  $map.set($key, result = new Map());
  return result;
})()''');

// TODO(leafp): This handles some low hanging fruit, but
// really we should make all of this faster, and also
// handle more cases here.
_createSmall(count, definite, returnType, required) => JS('', '''(() => {
  let map = $_fnTypeSmallMap[$count];
  let args = ($definite) ? $required
    : $required.map($_normalizeParameter);
  for (var i = 0; i < $count; ++i) {
    map = $_lookupNonTerminal(map, args[i]);
 }
 let result = map.get($returnType);
 if (result !== void 0) return result;
 result = new $FunctionType.new($returnType, args, [], {});
 map.set($returnType, result);
 return result;
})()''');

class FunctionType extends AbstractFunctionType {
  final returnType;
  List args;
  List optionals;
  final named;
  // TODO(vsm): This is just parameter metadata for now.
  List metadata = [];
  String _stringValue;

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
  static create(definite, returnType, List args, extra) {
    // Note that if extra is ever passed as an empty array
    // or an empty map, we can end up with semantically
    // identical function types that don't canonicalize
    // to the same object since we won't fall into this
    // fast path.
    if (extra == null && JS('bool', '#.length < 3', args)) {
      return _createSmall(JS('', '#.length', args), definite, returnType, args);
    }
    args = _canonicalizeArray(definite, args, _fnTypeArrayArgMap);
    var keys;
    var create;
    if (extra == null) {
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

  List _process(List array) {
    var result = [];
    for (var i = 0; JS('bool', '# < #.length', i, array); ++i) {
      var arg = JS('', '#[#]', array, i);
      if (JS('bool', '# instanceof Array', arg)) {
        JS('', '#.push(#.slice(1))', metadata, arg);
        JS('', '#.push(#[0])', result, arg);
      } else {
        JS('', '#.push([])', metadata);
        JS('', '#.push(#)', result, arg);
      }
    }
    return result;
  }

  FunctionType(this.returnType, this.args, this.optionals, this.named) {
    this.args = _process(this.args);
    this.optionals = _process(this.optionals);
    // TODO(vsm): Add named arguments.
  }

  toString() => name;

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
      for (var i = 0; JS('bool', '# < #.length', i, names); ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        var typeNameString = typeName(JS('', '#[#[#]]', named, names, i));
        buffer += '$typeNameString ${JS('', '#[#]', names, i)}';
      }
      buffer += '}';
    }

    var returnTypeName = typeName(returnType);
    buffer += ') => $returnTypeName';
    _stringValue = buffer;
    return buffer;
  }

  @JSExportName('is')
  bool is_T(obj) {
    if (JS('bool', 'typeof # == "function"', obj)) {
      var actual = JS('', '#[#]', obj, _runtimeType);
      // If there's no actual type, it's a JS function.
      // Allow them to subtype all Dart function types.
      return JS('bool', '# == null || !!#', actual, isSubtype(actual, this));
    }
    return false;
  }

  static final void Function(Object, Object) _logIgnoredCast =
      JS('', '''(() => $_ignoreMemo((actual, expected) => {
        console.warn('Ignoring cast fail from ' + $typeName(actual) +
                     ' to ' + $typeName(expected));
        return null;
        }))()''');

  @JSExportName('as')
  as_T(obj, [bool typeError]) {
    if (obj == null) return obj;
    if (JS('bool', 'typeof # == "function"', obj)) {
      var actual = JS('', '#[#]', obj, _runtimeType);
      // If there's no actual type, it's a JS function.
      // Allow them to subtype all Dart function types.
      if (actual == null) return obj;
      var result = isSubtype(actual, this);
      if (result == true) return obj;
      if (result == null && JS('bool', 'dart.__ignoreWhitelistedErrors')) {
        _logIgnoredCast(actual, this);
        return obj;
      }
    }
    return castError(obj, this, typeError);
  }

  @JSExportName('_check')
  check_T(obj) => as_T(obj, true);
}

class Typedef extends AbstractFunctionType {
  dynamic _name;
  AbstractFunctionType Function() _closure;
  AbstractFunctionType _functionType;

  Typedef(this._name, this._closure) {}

  toString() {
    var typeArgs = getGenericArgs(this);
    if (typeArgs == null) return name;

    var result = name + '<';
    var allDynamic = true;
    for (var i = 0, n = JS('int', '#.length', typeArgs); i < n; ++i) {
      if (i > 0) result += ', ';
      var typeArg = JS('', '#[#]', typeArgs, i);
      if (JS('bool', '# !== #', typeArg, _dynamic)) allDynamic = false;
      result += typeName(typeArg);
    }
    result += '>';
    return allDynamic ? name : result;
  }

  String get name => JS('String', '#', _name);

  AbstractFunctionType get functionType {
    var ft = _functionType;
    return ft == null ? _functionType = _closure() : ft;
  }

  @JSExportName('is')
  bool is_T(object) => functionType.is_T(object);

  @JSExportName('as')
  as_T(object) => functionType.as_T(object);

  @JSExportName('_check')
  check_T(object) => functionType.check_T(object);
}

/// A type variable, used by [GenericFunctionType] to represent a type formal.
class TypeVariable extends TypeRep {
  final String name;

  TypeVariable(this.name);

  toString() => name;
}

class GenericFunctionType extends AbstractFunctionType {
  final bool definite;
  final _instantiateTypeParts;
  final int formalCount;
  final _instantiateTypeBounds;
  List<TypeVariable> _typeFormals;

  GenericFunctionType(
      this.definite, instantiateTypeParts, this._instantiateTypeBounds)
      : _instantiateTypeParts = instantiateTypeParts,
        formalCount = JS('int', '#.length', instantiateTypeParts);

  List<TypeVariable> get typeFormals {
    if (_typeFormals != null) return _typeFormals;

    // Extract parameter names from the function parameters.
    //
    // This is not robust in general for user-defined JS functions, but it
    // should handle the functions generated by our compiler.
    //
    // TODO(jmesserly): names of TypeVariables are only used for display
    // purposes, such as when an error happens or if someone calls
    // `Type.toString()`. So we could recover them lazily rather than eagerly.
    // Alternatively we could synthesize new names.
    var str = JS('String', '#.toString()', _instantiateTypeParts);
    var hasParens = str[0] == '(';
    var end = str.indexOf(hasParens ? ')' : '=>');
    if (hasParens) {
      _typeFormals = str
          .substring(1, end)
          .split(',')
          .map((n) => new TypeVariable(n.trim()))
          .toList();
    } else {
      _typeFormals = [new TypeVariable(str.substring(0, end).trim())];
    }
    return _typeFormals;
  }

  checkBounds(List typeArgs) {
    var bounds = instantiateTypeBounds(typeArgs);
    var typeFormals = this.typeFormals;
    for (var i = 0; i < typeArgs.length; i++) {
      checkTypeBound(typeArgs[i], bounds[i], typeFormals[i]);
    }
  }

  instantiate(typeArgs) {
    var parts = JS('', '#.apply(null, #)', _instantiateTypeParts, typeArgs);
    return JS('', '#.create(#, #[0], #[1], #[2])', FunctionType, definite,
        parts, parts, parts);
  }

  List instantiateTypeBounds(List typeArgs) {
    var boundsFn = _instantiateTypeBounds;
    if (boundsFn == null) {
      // The Dart 1 spec says omitted type parameters have an upper bound of
      // Object. However strong mode assumes `dynamic` for all purposes
      // (such as instantiate to bounds) so we use that here.
      return new List.filled(formalCount, _dynamic);
    }
    // If bounds are recursive, we need to apply type formals and return them.
    return JS('List', '#.apply(null, #)', boundsFn, typeArgs);
  }

  toString() {
    String s = "<";
    var typeFormals = this.typeFormals;
    var typeBounds = instantiateTypeBounds(typeFormals);
    for (int i = 0, n = typeFormals.length; i < n; i++) {
      if (i != 0) s += ", ";
      s += JS('String', '#[#].name', typeFormals, i);
      var typeBound = typeBounds[i];
      if (!identical(typeBound, _dynamic)) {
        s += " extends $typeBound";
      }
    }
    s += ">" + instantiate(typeFormals).toString();
    return s;
  }

  /// Given a [DartType] [type], if [type] is an uninstantiated
  /// parameterized type then instantiate the parameters to their
  /// bounds and return those type arguments.
  ///
  /// See the issue for the algorithm description:
  /// <https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397>
  List instantiateDefaultBounds() {
    var typeFormals = this.typeFormals;

    // All type formals
    var all = new HashMap<Object, int>.identity();
    // ground types, by index.
    //
    // For each index, this will be a ground type for the corresponding type
    // formal if known, or it will be the original TypeVariable if we are still
    // solving for it. This array is passed to `instantiateToBounds` as we are
    // progressively solving for type variables.
    var defaults = new List<Object>(typeFormals.length);
    // not ground
    var partials = new Map<TypeVariable, Object>.identity();

    var typeBounds = this.instantiateTypeBounds(typeFormals);
    for (var i = 0; i < typeFormals.length; i++) {
      var typeFormal = typeFormals[i];
      var bound = typeBounds[i];
      all[typeFormal] = i;
      if (identical(bound, _dynamic)) {
        defaults[i] = bound;
      } else {
        defaults[i] = typeFormal;
        partials[typeFormal] = bound;
      }
    }

    bool hasFreeFormal(Object t) {
      if (partials.containsKey(t)) return true;

      // Generic classes and typedefs.
      var typeArgs = getGenericArgs(t);
      if (typeArgs != null) return typeArgs.any(hasFreeFormal);

      if (t is GenericFunctionType) {
        return hasFreeFormal(t.instantiate(t.typeFormals));
      }

      if (t is FunctionType) {
        return hasFreeFormal(t.returnType) || t.args.any(hasFreeFormal);
      }

      return false;
    }

    var hasProgress = true;
    while (hasProgress) {
      hasProgress = false;
      for (var typeFormal in partials.keys) {
        var partialBound = partials[typeFormal];
        if (!hasFreeFormal(partialBound)) {
          int index = all[typeFormal];
          defaults[index] = instantiateTypeBounds(defaults)[index];
          partials.remove(typeFormal);
          hasProgress = true;
          break;
        }
      }
    }

    // If we stopped making progress, and not all types are ground,
    // then the whole type is malbounded and an error should be reported
    // if errors are requested, and a partially completed type should
    // be returned.
    if (partials.isNotEmpty) {
      throwTypeError('Instantiate to bounds failed for type with '
          'recursive generic bounds: ${typeName(this)}. '
          'Try passing explicit type arguments.');
    }
    return defaults;
  }

  @JSExportName('is')
  bool is_T(obj) {
    if (JS('bool', 'typeof # == "function"', obj)) {
      var actual = JS('', '#[#]', obj, _runtimeType);
      return JS('bool', '# != null && !!#', actual, isSubtype(actual, this));
    }
    return false;
  }

  @JSExportName('as')
  as_T(obj) {
    if (obj == null || JS('bool', '#', is_T(obj))) return obj;
    return castError(obj, this, false);
  }

  @JSExportName('_check')
  check_T(obj) {
    if (obj == null || JS('bool', '#', is_T(obj))) return obj;
    return castError(obj, this, true);
  }
}

typedef(name, AbstractFunctionType Function() closure) =>
    new Typedef(name, closure);

/// Create a definite function type.
///
/// No substitution of dynamic for bottom occurs.
fnType(returnType, List args, [extra = undefined]) =>
    FunctionType.create(true, returnType, args, extra);

/// Create a "fuzzy" function type.
///
/// If any arguments are dynamic they will be replaced with bottom.
fnTypeFuzzy(returnType, List args, [extra = undefined]) =>
    FunctionType.create(false, returnType, args, extra);

/// Creates a definite generic function type.
///
/// A function type consists of two things: an instantiate function, and an
/// function that returns a list of upper bound constraints for each
/// the type formals. Both functions accept the type parameters, allowing us
/// to substitute values. The upper bound constraints can be omitted if all
/// of the type parameters use the default upper bound.
///
/// For example given the type <T extends Iterable<T>>(T) -> T, we can declare
/// this type with `gFnType(T => [T, [T]], T => [Iterable$(T)])`.\
gFnType(instantiateFn, typeBounds) =>
    new GenericFunctionType(true, instantiateFn, typeBounds);

gFnTypeFuzzy(instantiateFn, typeBounds) =>
    new GenericFunctionType(false, instantiateFn, typeBounds);

/// TODO(vsm): Remove when mirrors is deprecated.
/// This is a temporary workaround to support dart:mirrors, which doesn't
/// understand generic methods.
getFunctionTypeMirror(AbstractFunctionType type) {
  if (type is GenericFunctionType) {
    var typeArgs = new List.filled(type.formalCount, dynamic);
    return type.instantiate(typeArgs);
  }
  return type;
}

bool isType(obj) => JS('', '# === #', _getRuntimeType(obj), Type);

void checkTypeBound(type, bound, name) {
  if (JS('bool', '#', isSubtype(type, bound))) return;

  throwTypeError('type `$type` does not extend `$bound`'
      ' of `$name`.');
}

String typeName(type) => JS('', '''(() => {
  if ($type === void 0) return "undefined type";
  if ($type === null) return "null type";
  // Non-instance types
  if ($type instanceof $TypeRep) {
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

/// Returns `true` if we have a non-generic function type representation or the
/// type for `Function`, which is a supertype of all functions in Dart.
bool _isFunctionType(type) => JS('bool', '# instanceof # || # === #', type,
    AbstractFunctionType, type, Function);

/// Returns true if [ft1] <: [ft2].
/// Returns false if [ft1] </: [ft2] in both spec and strong mode
/// Returns null if [ft1] </: [ft2] in strong mode, but spec mode
/// may differ
/// If [isCovariant] is true, then we are checking subtyping in a covariant
/// position, and hence the direction of the check for function types
/// corresponds to the direction of the check according to the Dart spec.
isFunctionSubtype(ft1, ft2, isCovariant) => JS('', '''(() => {
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

/// Returns true if [t1] <: [t2].
/// Returns false if [t1] </: [t2] in both spec and strong mode
/// Returns undefined if [t1] </: [t2] in strong mode, but spec
///  mode may differ
bool isSubtype(t1, t2) {
  // TODO(leafp): This duplicates code in operations.dart.
  // I haven't found a way to factor it out that makes the
  // code generator happy though.
  var map;
  bool result;
  if (JS('bool', '!#.hasOwnProperty(#)', t1, _subtypeCache)) {
    JS('', '#[#] = # = new Map()', t1, _subtypeCache, map);
  } else {
    map = JS('', '#[#]', t1, _subtypeCache);
    result = JS('bool|Null', '#.get(#)', map, t2);
    if (JS('bool', '# !== void 0', result)) return result;
  }
  result =
      JS('bool|Null', '# === # || #(#, #, true)', t1, t2, _isSubtype, t1, t2);
  JS('', '#.set(#, #)', map, t2, result);
  return result;
}

final _subtypeCache = JS('', 'Symbol("_subtypeCache")');

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

bool _isSubtype(t1, t2, isCovariant) => JS('', '''(() => {
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

  if ($t2 instanceof $AnonymousJSType) {
    // All JS types are subtypes of anonymous JS types.
    return $t1 === $jsobject;
  }
  if ($t2 instanceof $LazyJSType) {
    return $_isSubtype($t1, $t2.rawJSTypeForCheck(), isCovariant);
  }

  // Function subtyping.

  // Handle Objects with call methods.  Those are functions
  // even if they do not *nominally* subtype core.Function.
  if (!$_isFunctionType($t1)) {
    $t1 = $getMethodType($t1, 'call');
    if ($t1 == null) return false;
  }

  // Unwrap typedefs.
  if ($t1 instanceof $Typedef) $t1 = $t1.functionType;
  if ($t2 instanceof $Typedef) $t2 = $t2.functionType;

  // Handle generic functions.
  if ($t1 instanceof $GenericFunctionType) {
    if (!($t2 instanceof $GenericFunctionType)) return false;

    // Given generic functions g1 and g2, g1 <: g2 iff:
    //
    //     g1<TFresh> <: g2<TFresh>
    //
    // where TFresh is a list of fresh type variables that both g1 and g2 will
    // be instantiated with.
    if ($t1.formalCount !== $t2.formalCount) return false;

    // Using either function's type formals will work as long as they're both
    // instantiated with the same ones. The instantiate operation is guaranteed
    // to avoid capture because it does not depend on its TypeVariable objects,
    // rather it uses JS function parameters to ensure correct binding.
    let fresh = $t2.typeFormals;

    // Check the bounds of the type parameters of g1 and g2.
    // given a type parameter `T1 extends U1` from g1, and a type parameter
    // `T2 extends U2` from g2, we must ensure that:
    //
    //      U2 <: U1
    //
    // (Note the reversal of direction -- type formal bounds are contravariant,
    // similar to the function's formal parameter types).
    //
    let t1Bounds = $t1.instantiateTypeBounds(fresh);
    let t2Bounds = $t2.instantiateTypeBounds(fresh);
    // TODO(jmesserly): we could optimize for the common case of no bounds.
    for (let i = 0; i < $t1.formalCount; i++) {
      if (!$_isSubtype(t2Bounds[i], t1Bounds[i], !$isCovariant)) {
        return false;
      }
    }

    return $isFunctionSubtype(
        $t1.instantiate(fresh), $t2.instantiate(fresh), $isCovariant);
  }

  if ($t2 instanceof $GenericFunctionType) return false;

  // Handle non-generic functions.
  if ($_isFunctionType($t1) && $_isFunctionType($t2)) {
    return $isFunctionSubtype($t1, $t2, $isCovariant);
  }

  return false;
})()''');

isClassSubType(t1, t2, isCovariant) => JS('', '''(() => {
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
    if (length != typeArguments2.length) $assertFailed();
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

  // Check mixin.
  let m1 = $getMixin($t1);
  if (m1 != null) {
    if (definitive(m1, $t2)) return true;
  }

  // Check interfaces.
  let getInterfaces = $getImplements($t1);
  if (getInterfaces) {
    for (let i1 of getInterfaces()) {
      if (definitive(i1, $t2)) return true;
    }
  }

  // We found no definite supertypes, and at least one indefinite supertype
  // so the answer is indefinite.
  if (indefinite) return null;
  // We found no definite supertypes and no indefinite supertypes, so we
  // can return false.
  return false;
})()''');

Object extractTypeArguments<T>(T instance, Function f) {
  if (instance == null) {
    throw new ArgumentError('Cannot extract type of null instance.');
  }
  var type = unwrapType(T);
  if (type is AbstractFunctionType || _isFutureOr(type)) {
    throw new ArgumentError('Cannot extract from non-class type ($type).');
  }
  var typeArguments = getGenericArgs(type);
  if (typeArguments.isEmpty) {
    throw new ArgumentError('Cannot extract from non-generic type ($type).');
  }
  List typeArgs = _extractTypes(getReifiedType(instance), type, typeArguments);
  // The signature of this method guarantees that instance is a T, so we
  // should have a valid non-empty list at this point.
  assert(typeArgs != null && typeArgs.isNotEmpty);
  return _checkAndCall(
      f, _getRuntimeType(f), JS('', 'void 0'), typeArgs, [], 'call');
}

// Let t2 = T<T1, ..., Tn>
// If t1 </: T<T1, ..., Tn>
// - return null
// If t1 <: T<T1, ..., Tn>
// - return [S1, ..., Sn] such that there exists no Ri where
//   Ri != Si && Ri <: Si && t1 <: T<S1, ..., Ri, ..., Sn>
//
// Note: In Dart 1, there isn't necessarily a unique solution to the above -
// t1 <: Foo<int> and t1 <: Foo<String> could both be true.  Dart 2 will
// statically disallow.  Until then, this could return either [int] or
// [String] depending on which it hits first.
//
// TODO(vsm): Consider merging with similar isClassSubType logic.
List _extractTypes(Type t1, Type t2, List typeArguments2) => JS('', '''(() => {
  if ($t1 == $t2) return typeArguments2;

  if ($t1 == $Object) return null;

  // If t1 is a JS Object, we may not hit core.Object.
  if ($t1 == null) return null;

  // Check if t1 and t2 have the same raw type.  If so, check covariance on
  // type parameters.
  let raw1 = $getGenericClass($t1);
  let raw2 = $getGenericClass($t2);
  if (raw1 != null && raw1 == raw2) {
    let typeArguments1 = $getGenericArgs($t1);
    let length = typeArguments1.length;
    if (length == 0 || length != typeArguments2.length) $assertFailed();
    // TODO(vsm): Remove this subtyping check if/when we eliminate the ability
    // to implement multiple versions of the same interface
    // (e.g., Foo<int>, Foo<String>).
    for (let i = 0; i < length; ++i) {
      let result =
          $_isSubtype(typeArguments1[i], typeArguments2[i], true);
      if (!result) {
        return null;
      }
    }
    return typeArguments1;
  }

  var result = $_extractTypes($t1.__proto__, $t2, $typeArguments2);
  if (result) return result;

  // Check mixin.
  let m1 = $getMixin($t1);
  if (m1 != null) {
    result = $_extractTypes(m1, $t2, $typeArguments2);
    if (result) return result;
  }

  // Check interfaces.
  let getInterfaces = $getImplements($t1);
  if (getInterfaces) {
    for (let i1 of getInterfaces()) {
      result = $_extractTypes(i1, $t2, $typeArguments2);
      if (result) return result;
    }
  }

  return null;
})()''');
