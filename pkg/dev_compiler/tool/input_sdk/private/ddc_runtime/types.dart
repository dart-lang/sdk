// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the representation of runtime types.
part of dart._runtime;

final metadata = JS('', 'Symbol("metadata")');

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

class DynamicType extends TypeRep {
  toString() => 'dynamic';

  @JSExportName('is')
  bool is_T(object) => true;

  @JSExportName('as')
  as_T(object) => object;

  @JSExportName('_check')
  check_T(object) => object;
}

bool _isJsObject(obj) => JS('bool', '# === #', getReifiedType(obj), jsobject);

class LazyJSType extends TypeRep {
  final Function() _rawJSType;
  final String _dartName;

  LazyJSType(this._rawJSType, this._dartName);

  toString() => typeName(_rawJSType());

  _raw() {
    var raw = _rawJSType();
    if (raw == null) {
      _warn('Cannot find native JavaScript type ($_dartName) for type check');
    }
    return raw;
  }

  rawJSTypeForCheck() {
    var raw = _raw();
    if (raw != null) return raw;
    // Treat as anonymous: return true for any JS object.
    return jsobject;
  }

  bool isRawType(obj) {
    var raw = _raw();
    if (raw != null) return JS('bool', '# instanceof #', obj, raw);
    // Treat as anonymous: return true for any JS object.
    return _isJsObject(obj);
  }

  @JSExportName('is')
  bool is_T(obj) => isRawType(obj) || instanceOf(obj, this);

  @JSExportName('as')
  as_T(obj) => obj == null || is_T(obj) ? obj : castError(obj, this, false);

  @JSExportName('_check')
  check_T(obj) => obj == null || is_T(obj) ? obj : castError(obj, this, true);
}

/// An anonymous JS type
///
/// For the purposes of subtype checks, these match any JS type.
class AnonymousJSType extends TypeRep {
  final String _dartName;
  AnonymousJSType(this._dartName);
  toString() => _dartName;

  @JSExportName('is')
  bool is_T(obj) => _isJsObject(obj) || instanceOf(obj, this);

  @JSExportName('as')
  as_T(obj) => obj == null || _isJsObject(obj) ? obj : cast(obj, this, false);

  @JSExportName('_check')
  check_T(obj) => obj == null || _isJsObject(obj) ? obj : cast(obj, this, true);
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
final _dynamic = new DynamicType();

class VoidType extends TypeRep {
  toString() => 'void';
}

@JSExportName('void')
final void_ = new VoidType();

class BottomType extends TypeRep {
  toString() => 'bottom';
}

final bottom = new BottomType();

class JSObjectType extends TypeRep {
  toString() => 'NativeJavaScriptObject';
}

final jsobject = new JSObjectType();

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

@NoReifyGeneric()
T _memoizeArray<T>(map, arr, T create()) => JS('', '''(() => {
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

List _canonicalizeArray(List array, map) =>
    _memoizeArray(map, array, () => array);

// TODO(leafp): This only canonicalizes of the names are
// emitted in a consistent order.
_canonicalizeNamed(named, map) => JS('', '''(() => {
  let key = [];
  let names = $getOwnPropertyNames($named);
  for (var i = 0; i < names.length; ++i) {
    let name = names[i];
    let type = $named[name];
    key.push(name);
    key.push(type);
  }
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
FunctionType _createSmall(returnType, List required) => JS('', '''(() => {
  let count = $required.length;
  let map = $_fnTypeSmallMap[count];
  for (var i = 0; i < count; ++i) {
    map = $_lookupNonTerminal(map, $required[i]);
 }
 let result = map.get($returnType);
 if (result !== void 0) return result;
 result = ${new FunctionType(returnType, required, [], JS('', '{}'))};
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
   * Construct a function type.
   *
   * We eagerly normalize the argument types to avoid having to deal with
   * this logic in multiple places.
   *
   * This code does best effort canonicalization.  It does not guarantee
   * that all instances will share.
   *
   */
  static FunctionType create(returnType, List args, extra) {
    // Note that if extra is ever passed as an empty array
    // or an empty map, we can end up with semantically
    // identical function types that don't canonicalize
    // to the same object since we won't fall into this
    // fast path.
    if (extra == null && JS('bool', '#.length < 3', args)) {
      return _createSmall(returnType, args);
    }
    args = _canonicalizeArray(args, _fnTypeArrayArgMap);
    var keys;
    FunctionType Function() create;
    if (extra == null) {
      keys = [returnType, args];
      create = () => new FunctionType(returnType, args, [], JS('', '{}'));
    } else if (JS('bool', '# instanceof Array', extra)) {
      var optionals =
          _canonicalizeArray(JS('', '#', extra), _fnTypeArrayArgMap);
      keys = [returnType, args, optionals];
      create =
          () => new FunctionType(returnType, args, optionals, JS('', '{}'));
    } else {
      var named = _canonicalizeNamed(extra, _fnTypeNamedArgMap);
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

  int get requiredParameterCount => args.length;
  int get positionalParameterCount => args.length + optionals.length;

  getPositionalParameter(int i) {
    int n = args.length;
    return i < n ? args[i] : optionals[i + n];
  }

  Map<String, Object> getNamedParameters() {
    var result = <String, Object>{};
    var names = getOwnPropertyNames(named);
    JS('', '#.sort()', names);
    for (var i = 0; JS('bool', '# < #.length', i, names); ++i) {
      String name = JS('!', '#[#]', names, i);
      result[name] = JS('', '#[#]', named, name);
    }
    return result;
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
    for (int i = 0, n = JS('!', '#.length', typeArgs); i < n; ++i) {
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
  final _instantiateTypeParts;
  final int formalCount;
  final _instantiateTypeBounds;
  List<TypeVariable> _typeFormals;

  GenericFunctionType(instantiateTypeParts, this._instantiateTypeBounds)
      : _instantiateTypeParts = instantiateTypeParts,
        formalCount = JS('int', '#.length', instantiateTypeParts);

  List<TypeVariable> get typeFormals {
    if (_typeFormals != null) return _typeFormals;
    return _typeFormals = _typeFormalsFromFunction(_instantiateTypeParts);
  }

  checkBounds(List typeArgs) {
    var bounds = instantiateTypeBounds(typeArgs);
    var typeFormals = this.typeFormals;
    for (var i = 0; i < typeArgs.length; i++) {
      checkTypeBound(typeArgs[i], bounds[i], typeFormals[i]);
    }
  }

  FunctionType instantiate(typeArgs) {
    var parts = JS('', '#.apply(null, #)', _instantiateTypeParts, typeArgs);
    return FunctionType.create(
        JS('', '#[0]', parts), JS('', '#[1]', parts), JS('', '#[2]', parts));
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
      s += JS<String>('!', '#[#].name', typeFormals, i);
      var bound = typeBounds[i];
      if (JS('bool', '# !== # && # !== #', bound, dynamic, bound, Object)) {
        s += " extends $bound";
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

List<TypeVariable> _typeFormalsFromFunction(Object typeConstructor) {
  // Extract parameter names from the function parameters.
  //
  // This is not robust in general for user-defined JS functions, but it
  // should handle the functions generated by our compiler.
  //
  // TODO(jmesserly): names of TypeVariables are only used for display
  // purposes, such as when an error happens or if someone calls
  // `Type.toString()`. So we could recover them lazily rather than eagerly.
  // Alternatively we could synthesize new names.
  String str = JS('!', '#.toString()', typeConstructor);
  var hasParens = str[0] == '(';
  var end = str.indexOf(hasParens ? ')' : '=>');
  if (hasParens) {
    return str
        .substring(1, end)
        .split(',')
        .map((n) => new TypeVariable(n.trim()))
        .toList();
  } else {
    return [new TypeVariable(str.substring(0, end).trim())];
  }
}

Typedef typedef(name, AbstractFunctionType Function() closure) =>
    new Typedef(name, closure);

/// Create a function type.
FunctionType fnType(returnType, List args, [extra = undefined]) =>
    FunctionType.create(returnType, args, extra);

/// Creates a generic function type.
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
    new GenericFunctionType(instantiateFn, typeBounds);

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

bool isType(obj) => JS('', '#[#] === #', obj, _runtimeType, Type);

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

  // Instance types
  let tag = $type[$_runtimeType];
  if (tag === $Type) {
    let name = $type.name;
    let args = ${getGenericArgs(type)};
    if (args == null) return name;

    if (${getGenericClass(type)} == ${getGenericClass(JSArray)}) name = 'List';

    let result = name;
    result += '<';
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) result += ', ';
      result += $typeName(args[i]);
    }
    result += '>';
    return result;
  }
  if (tag) return "Not a type: " + tag.name;
  return "JSObject<" + $type.name + ">";
})()''');

/// Returns true if [ft1] <: [ft2].
/// Returns false if [ft1] </: [ft2] in both spec and strong mode
/// Returns null if [ft1] </: [ft2] in strong mode, but spec mode
/// may differ
/// If [isCovariant] is true, then we are checking subtyping in a covariant
/// position, and hence the direction of the check for function types
/// corresponds to the direction of the check according to the Dart spec.
_isFunctionSubtype(ft1, ft2, isCovariant) => JS('', '''(() => {
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
  if (ret1 === $void_) return $_isTop(ret2);

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
      type, void_);
}

bool _isFutureOr(type) =>
    identical(getGenericClass(type), getGenericClass(FutureOr));

bool _isSubtype(t1, t2, isCovariant) => JS('', '''(() => {
  if ($t1 === $t2) return true;

  // Trivially true.
  if (${_isTop(t2)} || ${_isBottom(t1)}) {
    return true;
  }

  // Trivially false.
  if (${_isBottom(t2)}) return null;
  if (${_isTop(t1)}) {
    if ($t1 === $dynamic) return null;
    return false;
  }

  // Handle FutureOr<T> union type.
  if (${_isFutureOr(t1)}) {
    let t1TypeArg = ${getGenericArgs(t1)}[0];
    if (${_isFutureOr(t2)}) {
      let t2TypeArg = ${getGenericArgs(t2)}[0];
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
    let t2TypeArg = ${getGenericArgs(t2)}[0];
    let t2Future = ${getGenericClass(Future)}(t2TypeArg);
    let s1 = $_isSubtype($t1, t2Future, $isCovariant);
    let s2 = $_isSubtype($t1, t2TypeArg, $isCovariant);
    if (s1 === true || s2 === true) return true;
    if (s1 === null || s2 === null) return null;
    return false;
  }

  // "Traditional" name-based subtype check.  Avoid passing
  // function types to the class subtype checks, since we don't
  // currently distinguish between generic typedefs and classes.
  if (!($t2 instanceof $AbstractFunctionType)) {
    // t2 is an interface type.

    if ($t1 instanceof $AbstractFunctionType) {
      // Function types are only subtypes of interface types `Function` (and top
      // types, handled already above).
      return $t2 === $Function;
    }

    // All JS types are subtypes of anonymous JS types.
    if ($t1 === $jsobject && $t2 instanceof $AnonymousJSType) return true;

    // Compare two interface types:
    return ${_isInterfaceSubtype(t1, t2, isCovariant)};
  }

  // Function subtyping.
  if (!($t1 instanceof $AbstractFunctionType)) return false;

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
    let formalCount = $t1.formalCount;
    if (formalCount !== $t2.formalCount) return false;

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
    for (let i = 0; i < formalCount; i++) {
      if (!$_isSubtype(t2Bounds[i], t1Bounds[i], !$isCovariant)) {
        return false;
      }
    }

    $t1 = $t1.instantiate(fresh);
    $t2 = $t2.instantiate(fresh);
  } else if ($t2 instanceof $GenericFunctionType) {
    return false;
  }

  // Handle non-generic functions.
  return ${_isFunctionSubtype(t1, t2, isCovariant)};
})()''');

_isInterfaceSubtype(t1, t2, isCovariant) => JS('', '''(() => {
  // We support Dart's covariant generics with the caveat that we do not
  // substitute bottom for dynamic in subtyping rules.
  // I.e., given T1, ..., Tn where at least one Ti != dynamic we disallow:
  // - S !<: S<T1, ..., Tn>
  // - S<dynamic, ..., dynamic> !<: S<T1, ..., Tn>
  
  // If we have lazy JS types, unwrap them.  This will effectively
  // reduce to a prototype check below.
  if ($t1 instanceof $LazyJSType) $t1 = $t1.rawJSTypeForCheck();
  if ($t2 instanceof $LazyJSType) $t2 = $t2.rawJSTypeForCheck();

  if ($t1 === $t2) return true;
  if ($t1 === $Object) return false;

  // Classes cannot subtype `Function` or vice versa.
  if ($t1 === $Function || $t2 === $Function) return false;

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
    let result = $_isInterfaceSubtype(t1, t2, $isCovariant);
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
  var supertype = _getMatchingSupertype(getReifiedType(instance), type);
  // The signature of this method guarantees that instance is a T, so we
  // should have a valid non-empty list at this point.
  assert(supertype != null);
  var typeArgs = getGenericArgs(supertype);
  assert(typeArgs != null && typeArgs.isNotEmpty);
  return dgcall(f, typeArgs, []);
}

/// Infers type variables based on a series of [trySubtypeMatch] calls, followed
/// by [getInferredTypes] to return the type.
class _TypeInferrer {
  final Map<TypeVariable, TypeConstraint> _typeVariables;

  /// Creates a [TypeConstraintGatherer] which is prepared to gather type
  /// constraints for the given type parameters.
  _TypeInferrer(Iterable<TypeVariable> typeVariables)
      : _typeVariables = new Map.fromIterables(
            typeVariables, typeVariables.map((_) => new TypeConstraint()));

  /// Returns the inferred types based on the current constraints.
  List<Object> getInferredTypes() {
    var result = new List<Object>();
    for (var constraint in _typeVariables.values) {
      // Prefer the known bound, if any.
      if (constraint.lower != null) {
        result.add(constraint.lower);
      } else if (constraint.upper != null) {
        result.add(constraint.upper);
      } else {
        return null;
      }
    }
    return result;
  }

  /// Tries to match [subtype] against [supertype].
  ///
  /// If the match succeeds, the resulting type constraints are recorded for
  /// later use by [computeConstraints].  If the match fails, the set of type
  /// constraints is unchanged.
  bool trySubtypeMatch(Object subtype, Object supertype) =>
      _isSubtypeMatch(subtype, supertype);

  void _constrainLower(TypeVariable parameter, Object lower) {
    _typeVariables[parameter]._constrainLower(lower);
  }

  void _constrainUpper(TypeVariable parameter, Object upper) {
    _typeVariables[parameter]._constrainUpper(upper);
  }

  bool _isFunctionSubtypeMatch(FunctionType subtype, FunctionType supertype) {
    // A function type `(M0,..., Mn, [M{n+1}, ..., Mm]) -> R0` is a subtype
    // match for a function type `(N0,..., Nk, [N{k+1}, ..., Nr]) -> R1` with
    // respect to `L` under constraints `C0 + ... + Cr + C`
    // - If `R0` is a subtype match for a type `R1` with respect to `L` under
    //   constraints `C`:
    // - If `n <= k` and `r <= m`.
    // - And for `i` in `0...r`, `Ni` is a subtype match for `Mi` with respect
    //   to `L` under constraints `Ci`.
    // Function types with named parameters are treated analogously to the
    // positional parameter case above.
    // A generic function type `<T0 extends B0, ..., Tn extends Bn>F0` is a
    // subtype match for a generic function type `<S0 extends B0, ..., Sn
    // extends Bn>F1` with respect to `L` under constraints `Cl`:
    // - If `F0[Z0/T0, ..., Zn/Tn]` is a subtype match for `F0[Z0/S0, ...,
    //   Zn/Sn]` with respect to `L` under constraints `C`, where each `Zi` is a
    //   fresh type variable with bound `Bi`.
    // - And `Cl` is `C` with each constraint replaced with its closure with
    //   respect to `[Z0, ..., Zn]`.
    if (subtype.requiredParameterCount > supertype.requiredParameterCount) {
      return false;
    }
    if (subtype.positionalParameterCount < supertype.positionalParameterCount) {
      return false;
    }
    // Test the return types.
    if (supertype.returnType is! VoidType &&
        !_isSubtypeMatch(subtype.returnType, supertype.returnType)) {
      return false;
    }

    // Test the parameter types.
    for (int i = 0, n = supertype.positionalParameterCount; i < n; ++i) {
      if (!_isSubtypeMatch(supertype.getPositionalParameter(i),
          subtype.getPositionalParameter(i))) {
        return false;
      }
    }
    var supertypeNamed = supertype.getNamedParameters();
    var subtypeNamed = supertype.getNamedParameters();
    for (var name in supertypeNamed.keys) {
      var subtypeParamType = subtypeNamed[name];
      if (subtypeParamType == null) return false;
      if (!_isSubtypeMatch(supertypeNamed[name], subtypeParamType)) {
        return false;
      }
    }
    return true;
  }

  bool _isInterfaceSubtypeMatch(Object subtype, Object supertype) {
    // A type `P<M0, ..., Mk>` is a subtype match for `P<N0, ..., Nk>` with
    // respect to `L` under constraints `C0 + ... + Ck`:
    // - If `Mi` is a subtype match for `Ni` with respect to `L` under
    //   constraints `Ci`.
    // A type `P<M0, ..., Mk>` is a subtype match for `Q<N0, ..., Nj>` with
    // respect to `L` under constraints `C`:
    // - If `R<B0, ..., Bj>` is the superclass of `P<M0, ..., Mk>` and `R<B0,
    //   ..., Bj>` is a subtype match for `Q<N0, ..., Nj>` with respect to `L`
    //   under constraints `C`.
    // - Or `R<B0, ..., Bj>` is one of the interfaces implemented by `P<M0, ...,
    //   Mk>` (considered in lexical order) and `R<B0, ..., Bj>` is a subtype
    //   match for `Q<N0, ..., Nj>` with respect to `L` under constraints `C`.
    // - Or `R<B0, ..., Bj>` is a mixin into `P<M0, ..., Mk>` (considered in
    //   lexical order) and `R<B0, ..., Bj>` is a subtype match for `Q<N0, ...,
    //   Nj>` with respect to `L` under constraints `C`.

    // Note that since kernel requires that no class may only appear in the set
    // of supertypes of a given type more than once, the order of the checks
    // above is irrelevant; we just need to find the matched superclass,
    // substitute, and then iterate through type variables.
    var matchingSupertype = _getMatchingSupertype(subtype, supertype);
    if (matchingSupertype == null) return false;

    var matchingTypeArgs = getGenericArgs(matchingSupertype);
    var supertypeTypeArgs = getGenericArgs(supertype);
    for (int i = 0; i < supertypeTypeArgs.length; i++) {
      if (!_isSubtypeMatch(matchingTypeArgs[i], supertypeTypeArgs[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isNull(Object type) => identical(type, unwrapType(Null));

  /// Attempts to match [subtype] as a subtype of [supertype], gathering any
  /// constraints discovered in the process.
  ///
  /// If a set of constraints was found, `true` is returned and the caller
  /// may proceed to call [computeConstraints].  Otherwise, `false` is returned.
  ///
  /// In the case where `false` is returned, some bogus constraints may have
  /// been added to [_protoConstraints].  It is the caller's responsibility to
  /// discard them if necessary.
  bool _isSubtypeMatch(Object subtype, Object supertype) {
    // A type variable `T` in `L` is a subtype match for any type schema `Q`:
    // - Under constraint `T <: Q`.
    if (subtype is TypeVariable && _typeVariables.containsKey(subtype)) {
      _constrainUpper(subtype, supertype);
      return true;
    }
    // A type schema `Q` is a subtype match for a type variable `T` in `L`:
    // - Under constraint `Q <: T`.
    if (supertype is TypeVariable && _typeVariables.containsKey(supertype)) {
      _constrainLower(supertype, subtype);
      return true;
    }
    // Any two equal types `P` and `Q` are subtype matches under no constraints.
    // Note: to avoid making the algorithm quadratic, we just check for
    // identical().  If P and Q are equal but not identical, recursing through
    // the types will give the proper result.
    if (identical(subtype, supertype)) return true;
    // Any type `P` is a subtype match for `dynamic`, `Object`, or `void` under
    // no constraints.
    if (_isTop(supertype)) return true;
    // `Null` is a subtype match for any type `Q` under no constraints.
    // Note that nullable types will change this.
    if (_isNull(subtype)) return true;

    // Handle FutureOr<T> union type.
    if (_isFutureOr(subtype)) {
      var subtypeArg = getGenericArgs(subtype)[0];
      if (_isFutureOr(supertype)) {
        // `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to `L`
        // under constraints `C`:
        // - If `P` is a subtype match for `Q` with respect to `L` under constraints
        //   `C`.
        var supertypeArg = getGenericArgs(supertype)[0];
        return _isSubtypeMatch(subtypeArg, supertypeArg);
      }

      // `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
      // constraints `C0 + C1`:
      // - If `Future<P>` is a subtype match for `Q` with respect to `L` under
      //   constraints `C0`.
      // - And `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C1`.
      var subtypeFuture = JS('!', '#(#)', getGenericClass(Future), subtypeArg);
      return _isSubtypeMatch(subtypeFuture, supertype) &&
          _isSubtypeMatch(subtypeArg, supertype);
    }

    if (_isFutureOr(supertype)) {
      // `P` is a subtype match for `FutureOr<Q>` with respect to `L` under
      // constraints `C`:
      // - If `P` is a subtype match for `Future<Q>` with respect to `L` under
      //   constraints `C`.
      // - Or `P` is not a subtype match for `Future<Q>` with respect to `L` under
      //   constraints `C`
      //   - And `P` is a subtype match for `Q` with respect to `L` under
      //     constraints `C`
      var supertypeArg = getGenericArgs(supertype)[0];
      var supertypeFuture =
          JS('!', '#(#)', getGenericClass(Future), supertypeArg);
      return _isSubtypeMatch(subtype, supertypeFuture) ||
          _isSubtypeMatch(subtype, supertypeArg);
    }

    // A type variable `T` not in `L` with bound `P` is a subtype match for the
    // same type variable `T` with bound `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is a subtype match for `Q` with respect to `L` under constraints
    //   `C`.
    if (subtype is TypeVariable) {
      return supertype is TypeVariable && identical(subtype, supertype);
    }
    if (subtype is GenericFunctionType) {
      if (supertype is GenericFunctionType) {
        // Given generic functions g1 and g2, g1 <: g2 iff:
        //
        //     g1<TFresh> <: g2<TFresh>
        //
        // where TFresh is a list of fresh type variables that both g1 and g2 will
        // be instantiated with.
        var formalCount = subtype.formalCount;
        if (formalCount != supertype.formalCount) return false;

        // Using either function's type formals will work as long as they're
        // both instantiated with the same ones. The instantiate operation is
        // guaranteed to avoid capture because it does not depend on its
        // TypeVariable objects, rather it uses JS function parameters to ensure
        // correct binding.
        var fresh = supertype.typeFormals;

        // Check the bounds of the type parameters of g1 and g2.
        // given a type parameter `T1 extends U1` from g1, and a type parameter
        // `T2 extends U2` from g2, we must ensure that:
        //
        //      U2 <: U1
        //
        // (Note the reversal of direction -- type formal bounds are
        // contravariant, similar to the function's formal parameter types).
        //
        var t1Bounds = subtype.instantiateTypeBounds(fresh);
        var t2Bounds = supertype.instantiateTypeBounds(fresh);
        // TODO(jmesserly): we could optimize for the common case of no bounds.
        for (var i = 0; i < formalCount; i++) {
          if (!_isSubtypeMatch(t2Bounds[i], t1Bounds[i])) {
            return false;
          }
        }
        return _isFunctionSubtypeMatch(
            subtype.instantiate(fresh), supertype.instantiate(fresh));
      } else {
        return false;
      }
    } else if (supertype is GenericFunctionType) {
      return false;
    }

    // A type `P` is a subtype match for `Function` with respect to `L` under no
    // constraints:
    // - If `P` implements a call method.
    // - Or if `P` is a function type.
    // TODO(paulberry): implement this case.
    // A type `P` is a subtype match for a type `Q` with respect to `L` under
    // constraints `C`:
    // - If `P` is an interface type which implements a call method of type `F`,
    //   and `F` is a subtype match for a type `Q` with respect to `L` under
    //   constraints `C`.
    // TODO(paulberry): implement this case.
    if (subtype is FunctionType) {
      if (supertype is! FunctionType) {
        if (identical(supertype, unwrapType(Function)) ||
            identical(supertype, unwrapType(Object))) {
          return true;
        } else {
          return false;
        }
      }
      if (supertype is FunctionType) {
        return _isFunctionSubtypeMatch(subtype, supertype);
      }
    }
    return _isInterfaceSubtypeMatch(subtype, supertype);
  }

  bool _isTop(Object type) =>
      identical(type, _dynamic) ||
      identical(type, void_) ||
      identical(type, unwrapType(Object));
}

/// A constraint on a type parameter that we're inferring.
class TypeConstraint {
  /// The lower bound of the type being constrained.  This bound must be a
  /// subtype of the type being constrained.
  Object lower;

  /// The upper bound of the type being constrained.  The type being constrained
  /// must be a subtype of this bound.
  Object upper;

  void _constrainLower(Object type) {
    if (lower != null) {
      if (isSubtype(lower, type)) {
        // nothing to do, existing lower bound is lower than the new one.
        return;
      }
      if (!isSubtype(type, lower)) {
        // Neither bound is lower and we don't have GLB, so use bottom type.
        type = unwrapType(Null);
      }
    }
    lower = type;
  }

  void _constrainUpper(Object type) {
    if (upper != null) {
      if (isSubtype(type, upper)) {
        // nothing to do, existing upper bound is higher than the new one.
        return;
      }
      if (!isSubtype(upper, type)) {
        // Neither bound is higher and we don't have LUB, so use top type.
        type = unwrapType(Object);
      }
    }
    upper = type;
  }

  String toString() => '${typeName(lower)} <: <type> <: ${typeName(upper)}';
}

/// Finds a supertype of [subtype] that matches the class [supertype], but may
/// contain different generic type arguments.
Object _getMatchingSupertype(Object subtype, Object supertype) {
  if (identical(subtype, supertype)) return supertype;
  if (subtype == null || subtype == unwrapType(Object)) return null;

  var subclass = getGenericClass(subtype);
  var superclass = getGenericClass(supertype);
  if (subclass != null && identical(subclass, superclass)) {
    return subtype; // matching supertype found!
  }

  var result = _getMatchingSupertype(JS('', '#.__proto__', subtype), supertype);
  if (result != null) return result;

  // Check mixin.
  var mixin = getMixin(subtype);
  if (mixin != null) {
    result = _getMatchingSupertype(mixin, supertype);
    if (result != null) return result;
  }

  // Check interfaces.
  var getInterfaces = getImplements(subtype);
  if (getInterfaces != null) {
    for (var iface in getInterfaces()) {
      result = _getMatchingSupertype(iface, supertype);
      if (result != null) return result;
    }
  }

  return null;
}
