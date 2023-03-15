// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the representation of runtime types.
part of dart._runtime;

/// Returns the state of [flag] that is determined at compile time.
///
/// The constant value itself is inlined by the compiler in place of the call
/// to this method.
// TODO(nshahan) Remove in favor of `JS_GET_FLAG()`.
@notNull
external bool compileTimeFlag(String flag);

_throwInvalidFlagError(String message) =>
    throw UnsupportedError('Invalid flag combination.\n$message');

/// When running the new runtime type system with weak null safety this flag
/// gets toggled to change the behavior of the dart:_rti library when performing
/// `is` and `as` checks.
///
/// This allows DDC to produce optional warnings or errors when tests pass but
/// would fail in sound null safety.
@notNull
bool legacyTypeChecks = !compileTimeFlag("soundNullSafety");

@notNull
bool _weakNullSafetyWarnings = false;

/// Sets the runtime mode to show warnings when types violate sound null safety.
///
/// This option is not compatible with weak null safety errors or sound null
/// safety (the warnings will be errors).
void weakNullSafetyWarnings(bool showWarnings) {
  if (showWarnings && compileTimeFlag('soundNullSafety')) {
    _throwInvalidFlagError(
        'Null safety violations cannot be shown as warnings when running with '
        'sound null safety.');
  }

  _weakNullSafetyWarnings = showWarnings;
}

@notNull
bool _weakNullSafetyErrors = false;

/// Sets the runtime mode to throw errors when types violate sound null safety.
///
/// This option is not compatible with weak null safety warnings (the warnings
/// are now errors) or sound null safety (the errors are already errors).
void weakNullSafetyErrors(bool showErrors) {
  if (showErrors && compileTimeFlag('soundNullSafety')) {
    _throwInvalidFlagError(
        'Null safety violations are already thrown as errors when running with '
        'sound null safety.');
  }

  if (showErrors && _weakNullSafetyWarnings) {
    _throwInvalidFlagError(
        'Null safety violations can be shown as warnings or thrown as errors, '
        'not both.');
  }

  _weakNullSafetyErrors = showErrors;
}

@notNull
bool _nonNullAsserts = false;

/// Sets the runtime mode to insert non-null assertions on non-nullable method
/// parameters.
///
/// When [weakNullSafetyWarnings] is also `true` the assertions will fail
/// instead of printing a warning for the non-null parameters.
void nonNullAsserts(bool enable) {
  _nonNullAsserts = enable;
}

@notNull
bool _nativeNonNullAsserts = compileTimeFlag('soundNullSafety');

/// Enables null assertions on native APIs to make sure values returned from the
/// browser are sound.
///
/// These apply to dart:html and similar web libraries. Note that these only are
/// added in sound null-safety only.
void nativeNonNullAsserts(bool enable) {
  if (enable && !compileTimeFlag('soundNullSafety')) {
    _warn('Enabling `native-null-assertions` is only supported when sound null '
        'safety is enabled.');
  }
  // This value is only read from `checkNativeNonNull` and calls to that method
  // are only generated in sound null safe code.
  _nativeNonNullAsserts = enable;
}

/// A JavaScript Symbol used to store the Rti object on a native array.
final arrayRti = JS('', r'Symbol("$ti")');

final metadata = JS('', 'Symbol("metadata")');

/// A javascript Symbol used to store a canonical version of T? on T.
final _cachedNullable = JS('', 'Symbol("cachedNullable")');

/// A javascript Symbol used to store a canonical version of T* on T.
final _cachedLegacy = JS('', 'Symbol("cachedLegacy")');

/// A javascript Symbol used to store prior subtype checks and their results.
final _subtypeCache = JS('', 'Symbol("_subtypeCache")');

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
///   - All other types are represented as instances of class [DartType],
///     defined in this module.
///     - Dynamic, Void, and Bottom are singleton instances of sentinel
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
///
/// By convention, we used named JavaScript functions for these methods with the
/// name 'is_X' and 'as_X' for various X to indicate the type or the
/// implementation strategy for the test (e.g 'is_String', 'is_G' for generic
/// types, etc.)
// TODO(jmesserly): we shouldn't implement Type here. It should be moved down
// to AbstractFunctionType.
class DartType implements Type {
  String get name => this.toString();

  // TODO(jmesserly): these should never be reached, can be make them abstract?
  @notNull
  @JSExportName('is')
  bool is_T(object) => instanceOf(object, this);

  @JSExportName('as')
  as_T(object) => cast(object, this);

  DartType() {
    if (!JS_GET_FLAG('NEW_RUNTIME_TYPES')) {
      // Every instance of a DartType requires a set of type caches.
      JS('', '#(this)', addTypeCaches);
    }
  }
}

class DynamicType extends DartType {
  toString() => 'dynamic';

  @notNull
  @JSExportName('is')
  bool is_T(object) => true;

  @JSExportName('as')
  Object? as_T(Object? object) => object;
}

@notNull
bool _isJsObject(obj) =>
    JS('!', '# === #', getReifiedType(obj), typeRep<LegacyJavaScriptObject>());

/// Asserts that [f] is a native JS functions and returns it if so.
///
/// This function should be used to ensure that a function is a native JS
/// function before it is passed to native JS code.
@NoReifyGeneric()
F assertInterop<F extends Function?>(F f) {
  assert(
      _isJsObject(f) ||
          !JS<bool>('bool', '# instanceof #.Function', f, global_),
      'Dart function requires `allowInterop` to be passed to JavaScript.');
  return f;
}

bool isDartFunction(obj) =>
    JS<bool>('!', '# instanceof Function', obj) &&
    JS<bool>('!', '#[#] != null', obj, _runtimeType);

Expando<Function> _assertInteropExpando = Expando<Function>();

@NoReifyGeneric()
F tearoffInterop<F extends Function?>(F f) {
  // Wrap a JS function with a closure that ensures all function arguments are
  // native JS functions.
  if (!_isJsObject(f) || f == null) return f;
  var ret = _assertInteropExpando[f];
  if (ret == null) {
    ret = JS(
        '',
        'function (...arguments) {'
            ' var args = arguments.map(#);'
            ' return #.apply(this, args);'
            '}',
        assertInterop,
        f);
    _assertInteropExpando[f] = ret;
  }
  // Suppress a cast back to F.
  return JS('', '#', ret);
}

/// Base type for all `package:js` classes.
abstract class PackageJSType extends DartType {
  final String _dartName;
  PackageJSType(this._dartName);

  @override
  String toString() => _dartName;

  @notNull
  @JSExportName('is')
  bool is_T(obj) =>
      obj != null &&
      (_isJsObject(obj) || isSubtypeOf(getReifiedType(obj), this));

  @JSExportName('as')
  as_T(obj) => is_T(obj) ? obj : castError(obj, this);
}

/// Dart type that represents a non-`@staticInterop` package:js class type.
///
/// This may include types annotated with `@JS` and `@anonymous`, but not
/// `@staticInterop`. For the purposes of subtype checks, these match any
/// JS object that doesn't have a `@Native` class.
class NonStaticInteropType extends PackageJSType {
  NonStaticInteropType(super._dartName);
}

/// Dart type that represents a `@staticInterop` package:js class type.
///
/// This is type-equivalent to `JavaScriptObject`. Therefore, this type is a
/// supertype of all JS objects that don't have a `@Native` class and classes
/// that implement `JavaScriptObject` e.g. `dart:html` types.
class StaticInteropType extends PackageJSType {
  StaticInteropType(super._dartName);
}

void _warn(arg) {
  JS('void', 'console.warn(#)', arg);
}

void _nullWarn(message) {
  if (_weakNullSafetyWarnings) {
    _warn('$message\n'
        'This will become a failure when runtime null safety is enabled.');
  } else if (_weakNullSafetyErrors) {
    throw TypeErrorImpl(message);
  }
}

/// Tracks objects that have been compared against null (i.e., null is Type).
/// Separating this null set out from _cacheMaps lets us fast-track common
/// legacy type checks.
/// TODO: Delete this set when legacy nullability is phased out.
var _nullComparisonSet = JS<Object>('', 'new Set()');

/// Warn on null cast failures when casting to a particular non-nullable
/// `type`.  Note, we cache by type to avoid excessive warning messages at
/// runtime.
/// TODO(vsm): Consider changing all invocations to pass / cache on location
/// instead.  That gives more useful feedback to the user.
void _nullWarnOnType(type) {
  bool result = JS('', '#.has(#)', _nullComparisonSet, type);
  if (!result) {
    JS('', '#.add(#)', _nullComparisonSet, type);
    _nullWarn("Null is not a subtype of $type.");
  }
}

// `@staticInterop` and non-`@staticInterop` package:js classes can use the same
// name. Since these two types of classes have different types, we need to keep
// them in different maps.
final _nonStaticInteropTypes = JS<Object>('', 'new Map()');
final _staticInteropTypes = JS<Object>('', 'new Map()');

@notNull
Object packageJSType(@notNull String name, @notNull bool staticInterop) {
  var map = staticInterop ? _staticInteropTypes : _nonStaticInteropTypes;
  var ret = JS('', '#.get(#)', map, name);
  if (ret == null) {
    ret = staticInterop ? StaticInteropType(name) : NonStaticInteropType(name);
    JS('', '#.set(#, #)', map, name, ret);
  }
  return ret;
}

/// Represents all non-`@staticInterop` package:js types, as they're all
/// subtypes of one another and subtypes of `LegacyJavaScriptObject`.
///
/// Used only when a concrete NonStaticInteropType is not available i.e. when
/// neither the object nor the target type is a NonStaticInteropType. Avoids
/// initializing a new type every time. Note that we don't add it to the set of
/// JS types, since it's not an actual JS class.
final _nonStaticInteropTypeForSubtyping = NonStaticInteropType('');

/// Represents all `@staticInterop` package:js types, as they're all subtypes of
/// one another and type-equivalent to `JavaScriptObject`.
///
/// Similar to [_nonStaticInteropTypeForSubtyping], except with
/// StaticInteropType instead.
final _staticInteropTypeForSubtyping = StaticInteropType('');

/// Returns a nullable (question, ?) version of [type].
///
/// The resulting type returned in a normalized form based on the rules from the
/// normalization doc:
/// https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md
@notNull
Object nullable(@notNull Object type) {
  // Check if a nullable version of this type has already been created.
  var cached = JS<Object>('', '#[#]', type, _cachedNullable);
  if (JS<bool>('!', '# !== void 0', cached)) {
    return cached;
  }

  // Cache a canonical nullable version of this type on this type.
  Object cachedType = _computeNullable(type);
  JS('', '#[#] = #', type, _cachedNullable, cachedType);
  return cachedType;
}

Object _computeNullable(@notNull Object type) {
  // *? normalizes to ?.
  if (_jsInstanceOf(type, LegacyType)) {
    return nullable(JS<Object>('!', '#.type', type));
  }
  if (_jsInstanceOf(type, NullableType) ||
      _isTop(type) ||
      _equalType(type, Null) ||
      // Normalize FutureOr<T?>? --> FutureOr<T?>
      // All other runtime FutureOr normalization is in `normalizeFutureOr()`.
      ((_isFutureOr(type)) &&
          _jsInstanceOf(
              JS<Object>('!', '#[0]', getGenericArgs(type)), NullableType))) {
    return type;
  }
  if (_equalType(type, Never)) return unwrapType(Null);
  return NullableType(JS<Type>('!', '#', type));
}

/// Returns a legacy (star, *) version of [type].
///
/// The resulting type returned in a normalized form based on the rules from the
/// normalization doc:
/// https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md
@notNull
Object legacy(@notNull Object type) {
  // Check if a legacy version of this type has already been created.
  var cached = JS<Object>('', '#[#]', type, _cachedLegacy);
  if (JS<bool>('!', '# !== void 0', cached)) {
    return cached;
  }

  // Cache a canonical legacy version of this type on this type.
  Object cachedType = _computeLegacy(type);
  JS('', '#[#] = #', type, _cachedLegacy, cachedType);
  return cachedType;
}

Object _computeLegacy(@notNull Object type) {
  // Note: ?* normalizes to ?, so we cache type? at type?[_cachedLegacy].
  if (_jsInstanceOf(type, LegacyType) ||
      _jsInstanceOf(type, NullableType) ||
      _isTop(type) ||
      _equalType(type, Null)) {
    return type;
  }
  return LegacyType(JS<Type>('!', '#', type));
}

/// A wrapper to identify a nullable (question, ?) type of the form [type]?.
class NullableType extends DartType {
  final Type type;

  NullableType(@notNull this.type);

  @override
  String get name => _jsInstanceOf(type, FunctionType) ? '($type)?' : '$type?';

  @override
  String toString() => name;

  @JSExportName('is')
  bool is_T(obj) => obj == null || JS<bool>('!', '#.is(#)', type, obj);

  @JSExportName('as')
  as_T(obj) => obj == null || JS<bool>('!', '#.is(#)', type, obj)
      ? obj
      : cast(obj, this);
}

/// A wrapper to identify a legacy (star, *) type of the form [type]*.
class LegacyType extends DartType {
  final Type type;

  LegacyType(@notNull this.type);

  @override
  String get name => '$type';

  @override
  String toString() => name;

  @JSExportName('is')
  bool is_T(obj) {
    if (obj == null) {
      // Object and Never are trivially legacy types that should return true if
      // obj is `null`.
      if (_equalType(type, Object) || _equalType(type, Never)) return true;

      return _isFutureOr(type) &&
          JS<bool>('!', '#[0].is(#)', getGenericArgs(type), obj);
    }
    return JS<bool>('!', '#.is(#)', type, obj);
  }

  @JSExportName('as')
  as_T(obj) => obj == null || JS<bool>('!', '#.is(#)', type, obj)
      ? obj
      : cast(obj, this);
}

// TODO(nshahan) Add override optimizations for is and as?
class NeverType extends DartType {
  @override
  toString() => 'Never';
}

@JSExportName('Never')
final _never = NeverType();

@JSExportName('dynamic')
final _dynamic = DynamicType();

class VoidType extends DartType {
  toString() => 'void';

  @notNull
  @JSExportName('is')
  bool is_T(object) => true;

  @JSExportName('as')
  Object? as_T(Object? object) => object;
}

@JSExportName('void')
final void_ = VoidType();

// TODO(nshahan): Cleanup and consolidate NeverType, BottomType, bottom, _never.
class BottomType extends DartType {
  toString() => 'bottom';
}

final bottom = unwrapType(Null);

/// Dev Compiler's implementation of Type, wrapping its internal [_type].
class _Type extends Type {
  /// The internal type representation, either a [DartType] or class constructor
  /// function.
  // TODO(jmesserly): introduce InterfaceType so we don't have to special case
  // classes
  @notNull
  final Object _type;

  _Type(this._type);

  toString() => typeName(_type);

  Type get runtimeType => Type;
}

/// Given an internal runtime type object [type], wraps it in a `_Type` object
/// that implements the dart:core Type interface.
///
/// [isNormalized] is true when [type] is known to be in a canonicalized
/// normal form, so the algorithm can directly wrap and return the value.
Type wrapType(type, [@notNull bool isNormalized = false]) {
  // If we've already wrapped this type once, use the previous wrapper. This
  // way, multiple references to the same type return an identical Type.
  if (JS('!', '#.hasOwnProperty(#)', type, _typeObject)) {
    return JS('', '#[#]', type, _typeObject);
  }
  var result = isNormalized
      ? _Type(type)
      : (_jsInstanceOf(type, LegacyType)
          ? wrapType(JS<Object>('!', '#.type', type))
          : _canonicalizeNormalizedTypeObject(type));
  JS('', '#[#] = #', type, _typeObject, result);
  return result;
}

/// Constructs a normalized version of a type.
///
/// Used for type object identity. Normalization requires us to return a
/// canonicalized version of the input with all legacy wrappers removed.
Type _canonicalizeNormalizedTypeObject(type) {
  assert(!_jsInstanceOf(type, LegacyType));
  // We don't call _canonicalizeNormalizedTypeObject recursively but call wrap
  // + unwrap to handle legacy types automatically and force caching the
  // canonicalized type under the _typeObject cache property directly. This
  // way we ensure we always use the canonical normalized instance for each
  // type term.
  Object normalizeHelper(a) => unwrapType(wrapType(a));

  // GenericFunctionTypeIdentifiers are implicitly normalized.
  if (_jsInstanceOf(type, GenericFunctionTypeIdentifier)) {
    return wrapType(type, true);
  }
  if (_jsInstanceOf(type, RecordType)) {
    var normTypes = type.types.map(normalizeHelper).toList();
    var normType = recordType(type.shape, normTypes);
    return wrapType(normType, true);
  }
  if (_jsInstanceOf(type, FunctionType)) {
    var normReturnType = normalizeHelper(type.returnType);
    var normArgs = type.args.map(normalizeHelper).toList();
    if (JS<bool>('!', '#.Object.keys(#).length === 0', global_, type.named) &&
        JS<bool>('!', '#.Object.keys(#).length === 0', global_,
            type.requiredNamed)) {
      if (type.optionals.isEmpty) {
        var normType = fnType(normReturnType, normArgs);
        return wrapType(normType, true);
      }
      var normOptionals = type.optionals.map(normalizeHelper).toList();
      var normType = fnType(normReturnType, normArgs, normOptionals);
      return wrapType(normType, true);
    }
    var normNamed = JS('', '{}');
    _transformJSObject(type.named, normNamed, normalizeHelper);
    var normRequiredNamed = JS('', '{}');
    _transformJSObject(type.requiredNamed, normRequiredNamed, normalizeHelper);
    var normType =
        fnType(normReturnType, normArgs, normNamed, normRequiredNamed);
    return wrapType(normType, true);
  }
  if (_jsInstanceOf(type, GenericFunctionType)) {
    var formals = _getCanonicalTypeFormals(type.typeFormals.length);
    List<dynamic> normBounds =
        type.instantiateTypeBounds(formals).map(normalizeHelper).toList();

    var substitutedTypes = [];
    if (normBounds.contains(_never)) {
      // Normalize type arguments that are bounded by Never to Never at their
      // use site in the function type signature.
      for (var i = 0; i < formals.length; i++) {
        var substitutedType = normBounds[i];
        while (formals.contains(substitutedType)) {
          substitutedType = normBounds[formals.indexOf(substitutedType)];
        }
        if (substitutedType == _never) {
          substitutedTypes.add(_never);
        } else {
          substitutedTypes.add(formals[i]);
        }
      }
    } else {
      substitutedTypes = formals;
    }

    var normFunc =
        normalizeHelper(type.instantiate(substitutedTypes)) as FunctionType;
    // Create a comparison key for structural identity.
    var typeObjectIdKey = JS('', '[]');
    JS('', '#.push(...#)', typeObjectIdKey, normBounds);
    JS('', '#.push(#)', typeObjectIdKey, normFunc);
    var memoizedId = _memoizeArray(_gFnTypeTypeMap, typeObjectIdKey,
        () => GenericFunctionTypeIdentifier(formals, normBounds, normFunc));
    return wrapType(memoizedId, true);
  }
  var args = getGenericArgs(type);
  var normType;
  if (args == null || args.isEmpty) {
    normType = type;
  } else {
    var genericClass = getGenericClass(type);
    var normArgs = args.map(normalizeHelper).toList();
    normType = JS('!', '#(...#)', genericClass, normArgs);
  }
  return wrapType(normType, true);
}

/// Generates new values by applying [transform] to the values of [srcObject],
/// storing them in [dstObject] with the same key.
void _transformJSObject(srcObject, dstObject, Function transform) {
  for (Object key in JS('!', '#.Object.keys(#)', global_, srcObject)) {
    JS('', '#[#] = #', dstObject, key,
        transform(JS('', '#[#]', srcObject, key)));
  }
}

/// The symbol used to store the cached `Type` object associated with a class.
final _typeObject = JS('', 'Symbol("typeObject")');

/// Given a WrappedType, return the internal runtime type object.
Object unwrapType(Type obj) => JS<_Type>('', '#', obj)._type;

// Marker class for generic functions, typedefs, and non-generic functions.
abstract class AbstractFunctionType extends DartType {}

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

/// Memo table for generic function types. The index path consists of the
/// type parameters' bounds and the underlying function instantiated to its
/// bounds, subject to the same restrictions mentioned in _fnTypeTypeMap.
final _gFnTypeTypeMap = JS('', 'new Map()');

/// Pre-initialized type variables used to ensure that generic functions with
/// the same generic relationship structure but different names canonicalize
/// correctly.
final _typeVariablePool = <TypeVariable>[];

/// Returns a canonicalized sequence of type variables of size [count].
List<TypeVariable> _getCanonicalTypeFormals(int count) {
  while (count > _typeVariablePool.length) {
    _fillTypeVariable();
  }
  return _typeVariablePool.sublist(0, count);
}

/// Inserts a new type variable into _typeVariablePool according to a
/// pre-determined pattern.
///
/// The first 26 generics are alphanumerics; the remainder are represented as
/// T$N, where N increments from 0.
void _fillTypeVariable() {
  if (_typeVariablePool.length < 26) {
    _typeVariablePool
        .add(TypeVariable(String.fromCharCode(65 + _typeVariablePool.length)));
  } else {
    _typeVariablePool.add(TypeVariable('T${_typeVariablePool.length - 26}'));
  }
}

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

// TODO(leafp): This only canonicalizes if the names are emitted
// in a consistent order.
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
 result = ${new FunctionType(returnType, required, [], JS('', '{}'), JS('', '{}'))};
 map.set($returnType, result);
 return result;
})()''');

class FunctionType extends AbstractFunctionType {
  final Type returnType;
  final List args;
  final List optionals;
  // Named arguments native JS Object of the form { namedArgName: namedArgType }
  final named;
  final requiredNamed;
  String? _stringValue;

  /// Construct a function type.
  ///
  /// We eagerly normalize the argument types to avoid having to deal with this
  /// logic in multiple places.
  ///
  /// This code does best effort canonicalization.  It does not guarantee that
  /// all instances will share.
  ///
  /// Note: Generic function subtype checks assume types have been canonicalized
  /// when testing if type bounds are equal.
  static FunctionType create(
      returnType, List args, optionalArgs, requiredNamedArgs) {
    // Note that if optionalArgs is ever passed as an empty array or an empty
    // map, we can end up with semantically identical function types that don't
    // canonicalize to the same object since we won't fall into this fast path.
    var noOptionalArgs = optionalArgs == null && requiredNamedArgs == null;
    if (noOptionalArgs && JS<bool>('!', '#.length < 3', args)) {
      return _createSmall(returnType, args);
    }
    args = _canonicalizeArray(args, _fnTypeArrayArgMap);
    var keys = [];
    FunctionType Function() create;
    if (noOptionalArgs) {
      keys = [returnType, args];
      create =
          () => FunctionType(returnType, args, [], JS('', '{}'), JS('', '{}'));
    } else if (JS('!', '# instanceof Array', optionalArgs)) {
      var optionals =
          _canonicalizeArray(JS('', '#', optionalArgs), _fnTypeArrayArgMap);
      keys = [returnType, args, optionals];
      create = () =>
          FunctionType(returnType, args, optionals, JS('', '{}'), JS('', '{}'));
    } else {
      var named = _canonicalizeNamed(optionalArgs, _fnTypeNamedArgMap);
      var requiredNamed =
          _canonicalizeNamed(requiredNamedArgs, _fnTypeNamedArgMap);
      keys = [returnType, args, named, requiredNamed];
      create = () => FunctionType(returnType, args, [], named, requiredNamed);
    }
    return _memoizeArray(_fnTypeTypeMap, keys, create);
  }

  FunctionType(this.returnType, this.args, this.optionals, this.named,
      this.requiredNamed);

  toString() => name;

  int get requiredParameterCount => args.length;
  int get positionalParameterCount => args.length + optionals.length;

  getPositionalParameter(int i) {
    int n = args.length;
    return i < n ? args[i] : optionals[i + n];
  }

  /// Maps argument names to their canonicalized type.
  Map<String, Object> _createNameMap(List<Object?> names) {
    var result = <String, Object>{};
    // TODO: Remove this sort if ordering can be conserved.
    JS('', '#.sort()', names);
    for (var i = 0; JS<bool>('!', '# < #.length', i, names); ++i) {
      String name = JS('!', '#[#]', names, i);
      result[name] = JS('', '#[#]', named, name);
    }
    return result;
  }

  /// Maps optional named parameter names to their canonicalized type.
  Map<String, Object> getNamedParameters() =>
      _createNameMap(getOwnPropertyNames(named).toList());

  /// Maps required named parameter names to their canonicalized type.
  Map<String, Object> getRequiredNamedParameters() =>
      _createNameMap(getOwnPropertyNames(requiredNamed).toList());

  get name {
    if (_stringValue != null) return _stringValue!;
    var buffer = '(';
    for (var i = 0; JS<bool>('!', '# < #.length', i, args); ++i) {
      if (i > 0) {
        buffer += ', ';
      }
      buffer += typeName(JS('', '#[#]', args, i));
    }
    if (JS('!', '#.length > 0', optionals)) {
      if (JS('!', '#.length > 0', args)) buffer += ', ';
      buffer += '[';
      for (var i = 0; JS<bool>('!', '# < #.length', i, optionals); ++i) {
        if (i > 0) {
          buffer += ', ';
        }
        buffer += typeName(JS('', '#[#]', optionals, i));
      }
      buffer += ']';
    } else if (JS('!', 'Object.keys(#).length > 0 || Object.keys(#).length > 0',
        named, requiredNamed)) {
      if (JS('!', '#.length > 0', args)) buffer += ', ';
      buffer += '{';
      var names = getOwnPropertyNames(named);
      JS('', '#.sort()', names);
      for (var i = 0; JS<bool>('!', '# < #.length', i, names); i++) {
        if (i > 0) {
          buffer += ', ';
        }
        var typeNameString = typeName(JS('', '#[#[#]]', named, names, i));
        buffer += '$typeNameString ${JS('', '#[#]', names, i)}';
      }
      if (JS('!', 'Object.keys(#).length > 0 && #.length > 0', requiredNamed,
          names)) buffer += ', ';
      names = getOwnPropertyNames(requiredNamed);
      JS('', '#.sort()', names);
      for (var i = 0; JS<bool>('!', '# < #.length', i, names); i++) {
        if (i > 0) {
          buffer += ', ';
        }
        var typeNameString =
            typeName(JS('', '#[#[#]]', requiredNamed, names, i));
        buffer += 'required $typeNameString ${JS('', '#[#]', names, i)}';
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
    if (JS('!', 'typeof # == "function"', obj)) {
      var actual = JS('', '#[#]', obj, _runtimeType);
      // If there's no actual type, it's a JS function.
      // Allow them to subtype all Dart function types.
      return actual == null || isSubtypeOf(actual, this);
    }
    return false;
  }

  @JSExportName('as')
  as_T(obj) {
    if (is_T(obj)) return obj;
    // TODO(nshahan) This could directly call castError after we no longer allow
    // a cast of null to succeed in weak mode.
    return cast(obj, this);
  }
}

/// A type variable, used by [GenericFunctionType] to represent a type formal.
class TypeVariable extends DartType {
  final String name;

  TypeVariable(this.name);

  toString() => name;
}

/// A helper data class for the subtype check algorithm to represent a generic
/// function type variable with its bound.
///
/// Instances of this class are created during subtype check operations to pass
/// information deeper into the algorithm. They are not canonicalized and should
/// be discarded after use.
class TypeVariableForSubtype extends DartType {
  /// The position of this type variable in the type variable list of a generic
  /// function.
  final int index;

  /// The bound for this type variable.
  ///
  /// Only nullable to avoid the cost of a late field within the subtype check.
  /// Should not be null after initial creation algorithm is complete.
  DartType? bound;

  TypeVariableForSubtype(this.index);
}

class Variance {
  static const int unrelated = 0;
  static const int covariant = 1;
  static const int contravariant = 2;
  static const int invariant = 3;
}

/// Uniquely identifies the runtime type object of a generic function.
///
/// We require that all objects stored in this object not have legacy
/// nullability wrappers.
class GenericFunctionTypeIdentifier extends AbstractFunctionType {
  final typeFormals;
  final typeBounds;
  final FunctionType function;
  String? _stringValue;

  GenericFunctionTypeIdentifier(
      this.typeFormals, this.typeBounds, this.function);

  /// Returns the string-representation of the first generic function
  /// with this runtime type object canonicalization.
  ///
  /// Type formal names may not correspond to those of the originating type.
  /// We should consider auto-generating these to avoid confusion.
  toString() {
    if (_stringValue != null) return _stringValue!;
    String s = "<";
    var typeFormals = this.typeFormals;
    var typeBounds = this.typeBounds;
    for (int i = 0, n = typeFormals.length; i < n; i++) {
      if (i != 0) s += ", ";
      s += JS<String>('!', '#[#].name', typeFormals, i);
      var bound = typeBounds[i];
      if (_equalType(bound, dynamic) ||
          JS<bool>('!', '# === #', bound, nullable(unwrapType(Object))) ||
          (!compileTimeFlag('soundNullSafety') && _equalType(bound, Object))) {
        // Do not print the bound when it is a top type. In weak mode the bounds
        // of Object and Object* will also be elided.
        continue;
      }
      s += " extends $bound";
    }
    s += ">" + this.function.toString();
    return this._stringValue = s;
  }
}

class GenericFunctionType extends AbstractFunctionType {
  final _instantiateTypeParts;
  @notNull
  final int formalCount;
  final _instantiateTypeBounds;
  final List<TypeVariable> _typeFormals;

  GenericFunctionType(instantiateTypeParts, this._instantiateTypeBounds)
      : _instantiateTypeParts = instantiateTypeParts,
        formalCount = JS('!', '#.length', instantiateTypeParts),
        _typeFormals = _typeFormalsFromFunction(instantiateTypeParts);

  List<TypeVariable> get typeFormals => _typeFormals;

  /// `true` if there are bounds on any of the generic type parameters.
  bool get hasTypeBounds => _instantiateTypeBounds != null;

  /// Checks that [typeArgs] satisfies the upper bounds of the [typeFormals],
  /// and throws a [TypeError] if they do not.
  void checkBounds(List<Object> typeArgs) {
    // If we don't have explicit type parameter bounds, the bounds default to
    // a top type, so there's nothing to check here.
    if (!hasTypeBounds) return;

    var bounds = instantiateTypeBounds(typeArgs);
    var typeFormals = this.typeFormals;
    for (var i = 0; i < typeArgs.length; i++) {
      checkTypeBound(typeArgs[i], bounds[i], typeFormals[i].name);
    }
  }

  FunctionType instantiate(typeArgs) {
    var parts = JS('', '#.apply(null, #)', _instantiateTypeParts, typeArgs);
    return FunctionType.create(JS('', '#[0]', parts), JS('', '#[1]', parts),
        JS('', '#[2]', parts), JS('', '#[3]', parts));
  }

  List<Object> instantiateTypeBounds(List typeArgs) {
    if (!hasTypeBounds) {
      // We omit the a bound to represent Object*. Other bounds are explicitly
      // represented, including Object, Object? and dynamic.
      // TODO(nshahan) Revisit this representation when more libraries have
      // migrated to null safety.
      return List<Object>.filled(formalCount, legacy(unwrapType(Object)));
    }
    // Bounds can be recursive or depend on other type parameters, so we need to
    // apply type arguments and return the resulting bounds.
    return JS<List<Object>>(
        '!', '#.apply(null, #)', _instantiateTypeBounds, typeArgs);
  }

  toString() {
    String s = "<";
    var typeFormals = this.typeFormals;
    var typeBounds = instantiateTypeBounds(typeFormals);
    for (int i = 0, n = typeFormals.length; i < n; i++) {
      if (i != 0) s += ", ";
      s += JS<String>('!', '#[#].name', typeFormals, i);
      var bound = typeBounds[i];
      if (JS('!', '# !== # && # !== #', bound, dynamic, bound, Object)) {
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
    /// Returns `true` if the default value for the type bound should be
    /// `dynamic`.
    ///
    /// Dart 2 with null safety uses dynamic as the default value for types
    /// without explicit bounds.
    ///
    /// This is similar to [_isTop] but removes the check for `void` (it can't
    /// be written as a bound) and adds a check of `Object*` in weak mode.
    bool defaultsToDynamic(type) {
      // Technically this is wrong, only implicit bounds of `Object?` and
      // `Object*` should default to dynamic but code that observes the
      // difference is rare.
      if (_equalType(type, dynamic)) return true;
      if (_jsInstanceOf(type, NullableType) ||
          (!compileTimeFlag('soundNullSafety') &&
              _jsInstanceOf(type, LegacyType))) {
        return _equalType(JS('!', '#.type', type), Object);
      }
      return false;
    }

    var typeFormals = this.typeFormals;

    // All type formals
    var all = HashMap<TypeVariable, int>.identity();
    // ground types, by index.
    //
    // For each index, this will be a ground type for the corresponding type
    // formal if known, or it will be the original TypeVariable if we are still
    // solving for it. This array is passed to `instantiateToBounds` as we are
    // progressively solving for type variables.
    var defaults = List<Object?>.filled(typeFormals.length, null);
    // not ground
    var partials = Map<TypeVariable, Object>.identity();

    var typeBounds = this.instantiateTypeBounds(typeFormals);
    for (var i = 0; i < typeFormals.length; i++) {
      var typeFormal = typeFormals[i];
      var bound = typeBounds[i];
      all[typeFormal] = i;
      if (defaultsToDynamic(bound)) {
        // TODO(nshahan) Persist the actual default values into the runtime so
        // they can be used here instead of using dynamic for all top types
        // implicit or explicit.
        defaults[i] = _dynamic;
      } else {
        defaults[i] = typeFormal;
        partials[typeFormal] = bound;
      }
    }

    bool hasFreeFormal(t) {
      if (partials.containsKey(t)) return true;

      // Ignore nullability wrappers.
      if (_jsInstanceOf(t, LegacyType) || _jsInstanceOf(t, NullableType)) {
        return hasFreeFormal(JS<Object>('!', '#.type', t));
      }
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
        var partialBound = partials[typeFormal]!;
        if (!hasFreeFormal(partialBound)) {
          int index = all[typeFormal]!;
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

  @notNull
  @JSExportName('is')
  bool is_T(obj) {
    if (JS('!', 'typeof # == "function"', obj)) {
      var actual = JS('', '#[#]', obj, _runtimeType);
      return actual != null && isSubtypeOf(actual, this);
    }
    return false;
  }

  @JSExportName('as')
  as_T(obj) {
    if (is_T(obj)) return obj;
    // TODO(nshahan) This could directly call castError after we no longer allow
    // a cast of null to succeed in weak mode.
    return cast(obj, this);
  }
}

List<TypeVariable> _typeFormalsFromFunction(Object? typeConstructor) {
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
        .map((n) => TypeVariable(n.trim()))
        .toList();
  } else {
    return [TypeVariable(str.substring(0, end).trim())];
  }
}

/// Create a function type.
FunctionType fnType(returnType, List args,
        [@undefined optional, @undefined requiredNamed]) =>
    FunctionType.create(returnType, args, optional, requiredNamed);

/// Creates a generic function type from [instantiateFn] and [typeBounds].
///
/// A function type consists of two things:
/// * An instantiate function that takes type arguments and returns the
///   function signature in the form of a two element list. The first element
///   is the return type. The second element is a list of the argument types.
/// * A function that returns a list of upper bound constraints for each of
///   the type formals.
///
/// Both functions accept the type parameters, allowing us to substitute values.
/// The upper bound constraints can be omitted if all of the type parameters use
/// the default upper bound.
///
/// For example given the type <T extends Iterable<T>>(T) -> T, we can declare
/// this type with `gFnType(T => [T, [T]], T => [Iterable$(T)])`.
gFnType(instantiateFn, typeBounds) =>
    GenericFunctionType(instantiateFn, typeBounds);

/// Whether the given JS constructor [obj] is a Dart class type.
@notNull
bool isType(obj) => JS('', '#[#] === #', obj, _runtimeType, Type);

void checkTypeBound(
    @notNull Object type, @notNull Object bound, @notNull String name) {
  if (!isSubtypeOf(type, bound)) {
    throwTypeError('type `$type` does not extend `$bound` of `$name`.');
  }
}

@notNull
String typeName(type) {
  if (JS<bool>('!', '# === void 0', type)) return 'undefined type';
  if (JS<bool>('!', '# === null', type)) return 'null type';
  // Non-instance types
  if (_jsInstanceOf(type, DartType)) {
    return JS<String>('!', '#.toString()', type);
  }

  // Instance types
  var tag = JS('', '#[#]', type, _runtimeType);
  if (JS<bool>('!', '# === #', tag, Type)) {
    var name = JS<String>('!', '#.name', type);
    var args = getGenericArgs(type);
    if (args == null) return name;

    if (JS<bool>('!', '# == #', getGenericClass(type),
        getGenericClassStatic<JSArray>())) {
      name = 'List';
    }

    var result = name + '<';
    for (var i = 0; i < JS<int>('!', '#.length', args); ++i) {
      if (i > 0) result += ', ';
      result += typeName(JS('', '#[#]', args, i));
    }
    result += '>';
    return result;
  }
  // Test the JavaScript "truthiness" of `tag`.
  if (JS<bool>('!', '!!#', tag)) {
    return 'Not a type: ' + JS<String>('!', '#.name', tag);
  }
  return 'JSObject<' + JS<String>('!', '#.name', type) + '>';
}

/// Returns true if [t1] <: [t2].
@notNull
bool _isRecordSubtype(
    @notNull RecordType t1, @notNull RecordType t2, @notNull bool strictMode) {
  if (t1.shape != t2.shape) {
    return false;
  }
  var positionals = t1.shape.positionals;
  var types1 = t1.types;
  var types2 = t2.types;
  for (var i = 0; i < positionals; i++) {
    var type1 = JS('!', '#[#]', types1, i);
    var type2 = JS('!', '#[#]', types2, i);
    if (!_isSubtype(type1, type2, strictMode)) {
      return false;
    }
  }

  var named = t1.shape.named;
  if (named != null) {
    for (var i = 0; i < named.length; i++) {
      var index = positionals + i;
      var type1 = JS('!', '#[#]', types1, index);
      var type2 = JS('!', '#[#]', types2, index);
      if (!_isSubtype(type1, type2, strictMode)) {
        return false;
      }
    }
  }
  return true;
}

/// Returns true if [ft1] <: [ft2].
@notNull
bool _isFunctionSubtype(@notNull FunctionType ft1, @notNull FunctionType ft2,
    @notNull bool strictMode) {
  var ret1 = ft1.returnType;
  var ret2 = ft2.returnType;

  var args1 = ft1.args;
  var args1Length = JS<int>('!', '#.length', args1);
  var args2 = ft2.args;
  var args2Length = JS<int>('!', '#.length', args2);

  if (args1Length > args2Length) {
    return false;
  }

  for (var i = 0; i < args1Length; ++i) {
    if (!_isSubtype(
        JS('!', '#[#]', args2, i), JS('!', '#[#]', args1, i), strictMode)) {
      return false;
    }
  }

  var optionals1 = ft1.optionals;
  var optionals1Length = JS<int>('!', '#.length', optionals1);
  var optionals2 = ft2.optionals;
  var optionals2Length = JS<int>('!', '#.length', optionals2);

  if (args1Length + optionals1Length < args2Length + optionals2Length) {
    return false;
  }

  var j = 0;
  for (var i = args1Length; i < args2Length; ++i, ++j) {
    if (!_isSubtype(JS('!', '#[#]', args2, i), JS('!', '#[#]', optionals1, j),
        strictMode)) {
      return false;
    }
  }

  for (var i = 0; i < optionals2Length; ++i, ++j) {
    if (!_isSubtype(JS('!', '#[#]', optionals2, i),
        JS('!', '#[#]', optionals1, j), strictMode)) {
      return false;
    }
  }

  // Named parameter invariants:
  // 1) All named params in the superclass are named params in the subclass.
  // 2) All required named params in the subclass are required named params
  //    in the superclass.
  // 3) With strict null checking disabled, we treat required named params as
  //    optional named params.
  var named1 = ft1.named;
  var requiredNamed1 = ft1.requiredNamed;
  var named2 = ft2.named;
  var requiredNamed2 = ft2.requiredNamed;
  if (!strictMode) {
    // In weak mode, treat required named params as optional named params.
    named1 = JS('!', 'Object.assign({}, #, #)', named1, requiredNamed1);
    named2 = JS('!', 'Object.assign({}, #, #)', named2, requiredNamed2);
    requiredNamed1 = JS('!', '{}');
    requiredNamed2 = JS('!', '{}');
  }

  var names = getOwnPropertyNames(requiredNamed1);
  var namesLength = JS<int>('!', '#.length', names);
  for (var i = 0; i < namesLength; ++i) {
    var name = JS('!', '#[#]', names, i);
    var n2 = JS('!', '#[#]', requiredNamed2, name);
    if (JS<bool>('!', '# === void 0', n2)) {
      return false;
    }
  }
  names = getOwnPropertyNames(named2);
  namesLength = JS<int>('!', '#.length', names);
  for (var i = 0; i < namesLength; ++i) {
    var name = JS('!', '#[#]', names, i);
    var n1 = JS('!', '#[#]', named1, name);
    var n2 = JS('!', '#[#]', named2, name);
    if (JS<bool>('!', '# === void 0', n1)) {
      return false;
    }
    if (!_isSubtype(n2, n1, strictMode)) {
      return false;
    }
  }
  names = getOwnPropertyNames(requiredNamed2);
  namesLength = JS<int>('!', '#.length', names);
  for (var i = 0; i < namesLength; ++i) {
    var name = JS('!', '#[#]', names, i);
    var n1 = JS('!', '#[#] || #[#]', named1, name, requiredNamed1, name);
    var n2 = JS('!', '#[#]', requiredNamed2, name);
    if (JS<bool>('!', '# === void 0', n1)) {
      return false;
    }
    if (!_isSubtype(n2, n1, strictMode)) {
      return false;
    }
  }

  return _isSubtype(ret1, ret2, strictMode);
}

/// Number of generic function type variables encountered so far during a
/// subtype check.
///
/// This continues to increase through nested generic function types but should
/// always be reset before performing a new subtype check.
@notNull
var _typeVariableCount = 0;

/// Returns true if [t1] <: [t2].
@notNull
bool isSubtypeOf(@notNull t1, @notNull t2) {
  // TODO(jmesserly): we've optimized `is`/`as`/implicit type checks, so they're
  // dispatched on the type. Can we optimize the subtype relation too?
  var map = JS<Object>('!', '#[#]', t1, _subtypeCache);
  bool result = JS('', '#.get(#)', map, t2);
  if (JS('!', '# !== void 0', result)) return result;
  // Reset count before performing subtype check.
  _typeVariableCount = 0;
  var validSubtype = _isSubtype(t1, t2, true);
  if (!validSubtype && !compileTimeFlag('soundNullSafety')) {
    // Reset count before performing subtype check.
    _typeVariableCount = 0;
    validSubtype = _isSubtype(t1, t2, false);
    if (validSubtype) {
      // TODO(nshahan) Need more information to be helpful here.
      // File and line number that caused the subtype check?
      // Possibly break into debugger?
      _nullWarn("$t1 is not a subtype of $t2.");
    }
  }
  JS('', '#.set(#, #)', map, t2, validSubtype);
  return validSubtype;
}

@notNull
bool _isBottom(type, @notNull bool strictMode) =>
    _equalType(type, Never) || (!strictMode && _equalType(type, Null));

@notNull
bool _isTop(type) {
  if (_jsInstanceOf(type, NullableType))
    return JS('!', '#.type === #', type, Object);

  return _equalType(type, dynamic) || JS('!', '# === #', type, void_);
}

/// Wraps the JavaScript `instanceof` operator returning  `true` if [type] is an
/// instance of [cls].
///
/// This method is equivalent to:
///
///    JS<bool>('!', '# instanceof #', type, cls);
///
/// but the code is generated by the compiler directly (a low-tech way of
/// inlining).
@notNull
external bool _jsInstanceOf(type, cls);

/// Returns `true` if [type] is [cls].
///
/// This method is equivalent to:
///
///    JS<bool>('!', '# === #', type, unwrapType(cls));
///
/// but the code is generated by the compiler directly (a low-tech way of
/// inlining).
@notNull
external bool _equalType(type, cls);

/// Extracts the type argument as an unwrapped type preserving all forms of
/// nullability.
///
/// Acts as a way to bypass extra calls of [wrapType] and [unwrapType]. For
/// example `typeRep<Object?>()` emits `dart.nullable(core.Object)` directly.
@notNull
external Type typeRep<T>();

/// Extracts the type argument as an unwrapped type and performs a shallow
/// replacement of the nullability to a legacy type.
///
/// Acts as a way to bypass extra calls of [wrapType] and [unwrapType]. For
/// example `legacyTypeRep<Object>()` emits `dart.legacy(core.Object)` directly.
@notNull
external Type legacyTypeRep<T>();

@notNull
bool _isFutureOr(type) {
  var genericClass = getGenericClass(type);
  return JS<bool>('!', '!!# && # === #', genericClass, genericClass,
      getGenericClassStatic<FutureOr>());
}

@notNull
bool _isSubtype(t1, t2, @notNull bool strictMode) {
  if (!strictMode) {
    // Strip nullable types when performing check in weak mode.
    // TODO(nshahan) Investigate stripping off legacy types as well.
    if (_jsInstanceOf(t1, NullableType)) {
      t1 = JS<NullableType>('!', '#', t1).type;
    }
    if (_jsInstanceOf(t2, NullableType)) {
      t2 = JS<NullableType>('!', '#', t2).type;
    }
  }

  if (JS<bool>('!', '# === #', t1, t2)) {
    return true;
  }

  // Trivially true, "Right Top" or "Left Bottom".
  if (_isTop(t2) || _isBottom(t1, strictMode)) {
    return true;
  }

  // "Left Top".
  if (_equalType(t1, dynamic) || JS<bool>('!', '# === #', t1, void_)) {
    return _isSubtype(typeRep<Object?>(), t2, strictMode);
  }

  // "Right Object".
  if (_equalType(t2, Object)) {
    if (_isFutureOr(t1)) {
      var t1TypeArg = JS('', '#[0]', getGenericArgs(t1));
      return _isSubtype(t1TypeArg, typeRep<Object>(), strictMode);
    }

    if (_jsInstanceOf(t1, LegacyType)) {
      return _isSubtype(JS<LegacyType>('!', '#', t1).type, t2, strictMode);
    }

    if (_equalType(t1, Null) || _jsInstanceOf(t1, NullableType)) {
      // Checks for t1 is dynamic or void already performed in "Left Top" test.
      return false;
    }
    return true;
  }

  // "Left Null".
  if (_equalType(t1, Null)) {
    if (_isFutureOr(t2)) {
      var t2TypeArg = JS('', '#[0]', getGenericArgs(t2));
      return _isSubtype(typeRep<Null>(), t2TypeArg, strictMode);
    }

    return _equalType(t2, Null) ||
        _jsInstanceOf(t2, LegacyType) ||
        _jsInstanceOf(t2, NullableType);
  }

  // "Left Legacy".
  if (_jsInstanceOf(t1, LegacyType)) {
    return _isSubtype(JS<LegacyType>('!', '#', t1).type, t2, strictMode);
  }

  // "Right Legacy".
  if (_jsInstanceOf(t2, LegacyType)) {
    return _isSubtype(
        t1, nullable(JS<LegacyType>('!', '#', t2).type), strictMode);
  }

  // Handle FutureOr<T> union type.
  if (_isFutureOr(t1)) {
    var t1TypeArg = JS('!', '#[0]', getGenericArgs(t1));
    if (_isFutureOr(t2)) {
      var t2TypeArg = JS('!', '#[0]', getGenericArgs(t2));
      // FutureOr<A> <: FutureOr<B> if A <: B
      if (_isSubtype(t1TypeArg, t2TypeArg, strictMode)) {
        return true;
      }
    }

    // given t1 is Future<A> | A, then:
    // (Future<A> | A) <: t2 iff Future<A> <: t2 and A <: t2.
    var t1Future = JS('!', '#(#)', getGenericClassStatic<Future>(), t1TypeArg);
    // Known to handle the case FutureOr<Null> <: Future<Null>.
    return _isSubtype(t1Future, t2, strictMode) &&
        _isSubtype(t1TypeArg, t2, strictMode);
  }

  // "Left Nullable".
  if (_jsInstanceOf(t1, NullableType)) {
    return _isSubtype(JS<NullableType>('!', '#', t1).type, t2, strictMode) &&
        _isSubtype(typeRep<Null>(), t2, strictMode);
  }

  if (_isFutureOr(t2)) {
    // given t2 is Future<A> | A, then:
    // t1 <: (Future<A> | A) iff t1 <: Future<A> or t1 <: A
    var t2TypeArg = JS('!', '#[0]', getGenericArgs(t2));
    var t2Future = JS('!', '#(#)', getGenericClassStatic<Future>(), t2TypeArg);
    return _isSubtype(t1, t2Future, strictMode) ||
        _isSubtype(t1, t2TypeArg, strictMode);
  }

  // "Right Nullable".
  if (_jsInstanceOf(t2, NullableType)) {
    return _isSubtype(t1, JS<NullableType>('!', '#', t2).type, strictMode) ||
        _isSubtype(t1, typeRep<Null>(), strictMode);
  }

  // Abstract Record.
  if (_equalType(t2, Record)) {
    return _equalType(t1, Record) || _jsInstanceOf(t1, RecordType);
  }

  // Concrete record.
  if (_jsInstanceOf(t2, RecordType)) {
    if (_jsInstanceOf(t1, RecordType)) {
      return _isRecordSubtype(t1, t2, strictMode);
    }
    return false;
  }

  // "Traditional" name-based subtype check.  Avoid passing
  // function types to the class subtype checks, since we don't
  // currently distinguish between generic typedefs and classes.
  if (!_jsInstanceOf(t2, AbstractFunctionType)) {
    // t2 is an interface type.

    if (_jsInstanceOf(t1, AbstractFunctionType)) {
      // Function types are only subtypes of interface types `Function` (and top
      // types, handled already above).
      return _equalType(t2, Function);
    }

    // Even though `@JS` and `@anonymous` JS types are natural subtypes of
    // `LegacyJavaScriptObject`, these types should be treated as mutual
    // subtypes of each other.
    //
    // Therefore, the following relationships hold true:
    //
    // LegacyJavaScriptObject <: non-`@staticInterop` package:js types
    // non-`@staticInterop` package:js types <: LegacyJavaScriptObject

    if (_isInterfaceSubtype(
            t1, typeRep<LegacyJavaScriptObject>(), strictMode) &&
        // TODO(srujzs): We don't have a mechanism to determine if *some*
        // NonStaticInteropType implements t2. This will possibly require
        // keeping a map of these relationships for this subtyping check. For
        // now, this will only work if t2 is a package:js type.
        _isInterfaceSubtype(
            _nonStaticInteropTypeForSubtyping, t2, strictMode)) {
      return true;
    }

    if (_isInterfaceSubtype(
            t1, _nonStaticInteropTypeForSubtyping, strictMode) &&
        _isInterfaceSubtype(
            typeRep<LegacyJavaScriptObject>(), t2, strictMode)) {
      return true;
    }

    // `@staticInterop` types are mutual subtypes of `JavaScriptObject`:
    //
    // JavaScriptObject <: `@staticInterop` package:js types
    // `@staticInterop` package:js types <: JavaScriptObject
    //
    // This allows non-`@staticInterop` package:js types to interface any type
    // that implements `JavaScriptObject` e.g. all `package:js` types,
    // `dart:html` types.

    if (_isInterfaceSubtype(t1, typeRep<JavaScriptObject>(), strictMode) &&
        _isInterfaceSubtype(_staticInteropTypeForSubtyping, t2, strictMode)) {
      // TODO(srujzs): The limitations here around implements are the same as
      // those for non-`@staticInterop` package:js types above.
      return true;
    }

    if (_isInterfaceSubtype(t1, _staticInteropTypeForSubtyping, strictMode) &&
        _isInterfaceSubtype(typeRep<JavaScriptObject>(), t2, strictMode)) {
      return true;
    }

    // Compare two interface types.
    return _isInterfaceSubtype(t1, t2, strictMode);
  }

  // Function subtyping.
  if (!_jsInstanceOf(t1, AbstractFunctionType)) {
    return false;
  }

  // Handle generic functions.
  if (_jsInstanceOf(t1, GenericFunctionType)) {
    if (!_jsInstanceOf(t2, GenericFunctionType)) {
      return false;
    }

    // Given generic functions g1 and g2, g1 <: g2 iff:
    //
    //     g1<TFresh> <: g2<TFresh>
    //
    // where TFresh is a list of fresh type variables that both g1 and g2 will
    // be instantiated with.
    var formalCount = JS<GenericFunctionType>('!', '#', t1).formalCount;
    if (formalCount != JS<GenericFunctionType>('!', '#', t2).formalCount) {
      return false;
    }

    // Fresh type variables will be used to instantiate generic functions.
    List<Object> fresh1;
    List<Object> fresh2;

    // Without type bounds all will instantiate to dynamic. Only need to check
    // further if at least one of the functions has type bounds.
    if (JS<bool>('!', '#.hasTypeBounds || #.hasTypeBounds', t1, t2)) {
      // Create two sets of fresh type variables that can store their bounds so
      // they can be considered in recursive calls.
      fresh1 = JS('!', 'new Array(#)', formalCount);
      fresh2 = JS('!', 'new Array(#)', formalCount);
      for (var i = 0; i < formalCount; i++, _typeVariableCount++) {
        JS('!', '#[#] = #', fresh1, i,
            TypeVariableForSubtype(_typeVariableCount));
        JS('!', '#[#] = #', fresh2, i,
            TypeVariableForSubtype(_typeVariableCount));
      }
      var t1Bounds =
          JS<GenericFunctionType>('!', '#', t1).instantiateTypeBounds(fresh1);
      var t2Bounds =
          JS<GenericFunctionType>('!', '#', t2).instantiateTypeBounds(fresh2);

      for (var i = 0; i < formalCount; i++) {
        var t1Bound = JS<Object>('!', '#[#]', t1Bounds, i);
        var t2Bound = JS<Object>('!', '#[#]', t2Bounds, i);

        // Check the bounds of the type parameters of g1 and g2. Given a type
        // parameter `T1 extends B1` from g1, and a type parameter `T2 extends
        // B2` from g2, we must ensure that B1 and B2 are mutual subtypes.
        //
        // (Note there is no variance in the type bounds of type parameters of
        // generic functions).
        if (JS<bool>('!', '# != #', t1Bound, t2Bound)) {
          if (!(_isSubtype(t1Bound, t2Bound, strictMode) &&
              _isSubtype(t2Bound, t1Bound, strictMode))) {
            return false;
          }
        }
        // Assign bounds to be used in the `_isInterfaceSubtype` check later as
        // this subtype check continues.
        JS('', '#[#].bound = #', fresh1, i, t1Bound);
        JS('', '#[#].bound = #', fresh2, i, t2Bound);
      }
    } else {
      // Using either function's type formals will work as long as they're both
      // instantiated with the same ones. The instantiate operation is
      // guaranteed to avoid capture because it does not depend on its
      // TypeVariable objects, rather it uses JS function parameters to ensure
      // correct binding.
      fresh1 = JS<GenericFunctionType>('!', '#', t1).typeFormals;
      fresh2 = fresh1;
    }

    t1 = JS<GenericFunctionType>('!', '#', t1).instantiate(fresh1);
    t2 = JS<GenericFunctionType>('!', '#', t2).instantiate(fresh2);
  } else if (_jsInstanceOf(t2, GenericFunctionType)) {
    return false;
  }

  // Handle non-generic functions.
  return _isFunctionSubtype(JS<FunctionType>('!', '#', t1),
      JS<FunctionType>('!', '#', t2), strictMode);
}

@notNull
bool _isInterfaceSubtype(t1, t2, @notNull bool strictMode) {
  if (JS<bool>('!', '# === #', t1, t2)) {
    return true;
  }
  if (_equalType(t1, Object)) {
    return false;
  }

  // Classes cannot subtype `Function` or vice versa.
  if (_equalType(t1, Function) || _equalType(t2, Function)) {
    return false;
  }

  // If t1 is a JS Object, we may not hit core.Object.
  if (t1 == null) {
    return _equalType(t2, Object) || _equalType(t2, dynamic);
  }

  if (_jsInstanceOf(t1, TypeVariableForSubtype)) {
    if (_jsInstanceOf(t2, TypeVariableForSubtype)) {
      // Bounds were already checked to be subtypes of each other in the
      // generic function section of `_isSubtype()` so just check these type
      // variables share the same index in their respective signatures.
      return JS<TypeVariableForSubtype>('!', '#', t1).index ==
          JS<TypeVariableForSubtype>('!', '#', t2).index;
    }

    // If t1 <: bound <: t2 then t1 <: t2.
    return _isSubtype(
        JS<TypeVariableForSubtype>('!', '#', t1).bound, t2, strictMode);
  }

  // Note that the following subtype rules for interop types do not have the
  // following rule: any StaticInteropType <: any NonStaticInteropType. This
  // follows from LegacyJavaScriptObject <: JavaScriptObject and not vice-versa.

  // any NonStaticInteropType <: any StaticInteropType
  // any StaticInteropType <: any StaticInteropType
  if ((_jsInstanceOf(t1, NonStaticInteropType) ||
          _jsInstanceOf(t1, StaticInteropType)) &&
      _jsInstanceOf(t2, StaticInteropType)) {
    return true;
  }
  // any NonStaticInteropType <: any NonStaticInteropType
  if (_jsInstanceOf(t1, NonStaticInteropType) &&
      _jsInstanceOf(t2, NonStaticInteropType)) {
    return true;
  }

  // Check if t1 and t2 have the same raw type.  If so, check covariance on
  // type parameters.
  var raw1 = getGenericClass(t1);
  var raw2 = getGenericClass(t2);
  if (raw1 != null && JS<bool>('!', '# == #', raw1, raw2)) {
    var typeArguments1 = getGenericArgs(t1);
    var typeArguments2 = getGenericArgs(t2);
    if (JS<bool>('!', '#.length != #.length', typeArguments1, typeArguments2)) {
      assertFailed('Internal type check failure.');
    }
    var variances = getGenericArgVariances(t1);
    for (var i = 0; i < JS<int>('!', '#.length', typeArguments1); ++i) {
      // When using implicit variance, variances will be undefined and
      // considered covariant.
      var varianceType = JS('!', '# && #[#]', variances, variances, i);
      var typeArg1 = JS('!', '#[#]', typeArguments1, i);
      var typeArg2 = JS('!', '#[#]', typeArguments2, i);
      if (JS<bool>('!', '# === void 0 || # == #', varianceType, varianceType,
          Variance.covariant)) {
        if (!_isSubtype(typeArg1, typeArg2, strictMode)) {
          return false;
        }
      } else if (JS<bool>(
          '!', '# == #', varianceType, Variance.contravariant)) {
        if (!_isSubtype(typeArg2, typeArg1, strictMode)) {
          return false;
        }
      } else if (JS<bool>('!', '# == #', varianceType, Variance.invariant)) {
        if (!_isSubtype(typeArg1, typeArg2, strictMode) ||
            !_isSubtype(typeArg2, typeArg1, strictMode)) {
          return false;
        }
      }
    }
    return true;
  }

  if (_isInterfaceSubtype(JS('', '#.__proto__', t1), t2, strictMode)) {
    return true;
  }

  // Check mixin.
  var m1 = getMixin(t1);
  if (m1 != null && _isInterfaceSubtype(m1, t2, strictMode)) {
    return true;
  }

  // Check interfaces.
  var getInterfaces = getImplements(t1);
  if (getInterfaces != null) {
    for (var i1 in getInterfaces()) {
      if (_isInterfaceSubtype(i1, t2, strictMode)) {
        return true;
      }
    }
  }
  return false;
}

Object? extractTypeArguments<T>(T instance, Function f) {
  if (instance == null) {
    throw ArgumentError('Cannot extract type of null instance.');
  }
  var type = unwrapType(T);
  // Get underlying type from nullability wrappers if needed.
  type = JS<Object>('!', '#.type || #', type, type);

  if (type is AbstractFunctionType || _isFutureOr(type)) {
    throw ArgumentError('Cannot extract from non-class type ($type).');
  }
  var typeArguments = getGenericArgs(type);
  if (typeArguments!.isEmpty) {
    throw ArgumentError('Cannot extract from non-generic type ($type).');
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
      : _typeVariables = Map.fromIterables(
            typeVariables, typeVariables.map((_) => TypeConstraint()));

  /// Returns the inferred types based on the current constraints.
  List<Object>? getInferredTypes() {
    var result = <Object>[];
    for (var constraint in _typeVariables.values) {
      // Prefer the known bound, if any.
      if (constraint.lower != null) {
        result.add(constraint.lower!);
      } else if (constraint.upper != null) {
        result.add(constraint.upper!);
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
    _typeVariables[parameter]!._constrainLower(lower);
  }

  void _constrainUpper(TypeVariable parameter, Object upper) {
    _typeVariables[parameter]!._constrainUpper(upper);
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

    // Named parameter invariants:
    // 1) All named params in the superclass are named params in the subclass.
    // 2) All required named params in the subclass are required named params
    //    in the superclass.
    // 3) With strict null checking disabled, we treat required named params as
    //    optional named params.
    var supertypeNamed = supertype.getNamedParameters();
    var supertypeRequiredNamed = supertype.getRequiredNamedParameters();
    var subtypeNamed = supertype.getNamedParameters();
    var subtypeRequiredNamed = supertype.getRequiredNamedParameters();
    if (!compileTimeFlag('soundNullSafety')) {
      // In weak mode, treat required named params as optional named params.
      supertypeNamed = {...supertypeNamed, ...supertypeRequiredNamed};
      subtypeNamed = {...subtypeNamed, ...subtypeRequiredNamed};
      supertypeRequiredNamed = {};
      subtypeRequiredNamed = {};
    }
    for (var name in subtypeRequiredNamed.keys) {
      var supertypeParamType = supertypeRequiredNamed[name];
      if (supertypeParamType == null) return false;
    }
    for (var name in supertypeNamed.keys) {
      var subtypeParamType = subtypeNamed[name];
      if (subtypeParamType == null) return false;
      if (!_isSubtypeMatch(supertypeNamed[name]!, subtypeParamType)) {
        return false;
      }
    }
    for (var name in supertypeRequiredNamed.keys) {
      var subtypeParamType = subtypeRequiredNamed[name] ?? subtypeNamed[name]!;
      if (!_isSubtypeMatch(supertypeRequiredNamed[name]!, subtypeParamType)) {
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

    var matchingTypeArgs = getGenericArgs(matchingSupertype)!;
    var supertypeTypeArgs = getGenericArgs(supertype)!;
    for (int i = 0; i < supertypeTypeArgs.length; i++) {
      if (!_isSubtypeMatch(matchingTypeArgs[i], supertypeTypeArgs[i])) {
        return false;
      }
    }
    return true;
  }

  /// Attempts to match [subtype] as a subtype of [supertype], gathering any
  /// constraints discovered in the process.
  ///
  /// If a set of constraints was found, `true` is returned and the caller
  /// may proceed to call [computeConstraints].  Otherwise, `false` is returned.
  ///
  /// In the case where `false` is returned, some bogus constraints may have
  /// been added to [_protoConstraints].  It is the caller's responsibility to
  /// discard them if necessary.
  // TODO(#40326) Update to support null safety subtyping algorithm.
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
    if (_equalType(subtype, Null)) return true;

    // Handle FutureOr<T> union type.
    if (_isFutureOr(subtype)) {
      var subtypeArg = getGenericArgs(subtype)![0];
      if (_isFutureOr(supertype)) {
        // `FutureOr<P>` is a subtype match for `FutureOr<Q>` with respect to `L`
        // under constraints `C`:
        // - If `P` is a subtype match for `Q` with respect to `L` under constraints
        //   `C`.
        var supertypeArg = getGenericArgs(supertype)![0];
        return _isSubtypeMatch(subtypeArg, supertypeArg);
      }

      // `FutureOr<P>` is a subtype match for `Q` with respect to `L` under
      // constraints `C0 + C1`:
      // - If `Future<P>` is a subtype match for `Q` with respect to `L` under
      //   constraints `C0`.
      // - And `P` is a subtype match for `Q` with respect to `L` under
      //   constraints `C1`.
      var subtypeFuture =
          JS<Object>('!', '#(#)', getGenericClassStatic<Future>(), subtypeArg);
      return _isSubtypeMatch(subtypeFuture, supertype) &&
          _isSubtypeMatch(subtypeArg!, supertype);
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
      var supertypeArg = getGenericArgs(supertype)![0];
      var supertypeFuture = JS<Object>(
          '!', '#(#)', getGenericClassStatic<Future>(), supertypeArg);
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
        if (_equalType(supertype, Function) || _equalType(supertype, Object)) {
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
      _equalType(type, Object);
}

/// A constraint on a type parameter that we're inferring.
class TypeConstraint {
  /// The lower bound of the type being constrained.  This bound must be a
  /// subtype of the type being constrained.
  Object? lower;

  /// The upper bound of the type being constrained.  The type being constrained
  /// must be a subtype of this bound.
  Object? upper;

  void _constrainLower(Object type) {
    var _lower = lower;
    if (_lower != null) {
      if (isSubtypeOf(_lower, type)) {
        // nothing to do, existing lower bound is lower than the new one.
        return;
      }
      if (!isSubtypeOf(type, _lower)) {
        // Neither bound is lower and we don't have GLB, so use bottom type.
        type = unwrapType(Null);
      }
    }
    lower = type;
  }

  void _constrainUpper(Object type) {
    var _upper = upper;
    if (_upper != null) {
      if (isSubtypeOf(type, _upper)) {
        // nothing to do, existing upper bound is higher than the new one.
        return;
      }
      if (!isSubtypeOf(_upper, type)) {
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
Object? _getMatchingSupertype(Object? subtype, Object supertype) {
  if (identical(subtype, supertype)) return supertype;
  if (subtype == null || _equalType(subtype, Object)) return null;

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

/// Shapes consist of a count of positional elements and a sorted list of
/// named elements' names.
class Shape {
  int positionals;
  List<String>? named;
  Shape(this.positionals, this.named);

  String toString() {
    return 'Shape($positionals, [${named?.join(", ")}])';
  }
}

/// Internal base class for all concrete records.
final class _RecordImpl implements Record {
  Shape shape;
  List values;

  int? _hashCode;
  String? _printed;

  _RecordImpl(this.shape, this.values);

  @override
  bool operator ==(Object? other) {
    if (!(other is _RecordImpl)) return false;
    if (shape != other.shape) return false;
    if (values.length != other.values.length) {
      return false;
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i] != other.values[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    if (_hashCode == null) {
      _hashCode = Object.hashAll([shape, ...values]);
    }
    return _hashCode!;
  }

  @override
  String toString() {
    if (_printed == null) {
      var buffer = StringBuffer();
      var posCount = shape.positionals;
      var count = values.length;

      buffer.write('(');
      for (var i = 0; i < count; i++) {
        if (i >= posCount) {
          buffer.write('${shape.named![i - posCount]}');
          buffer.write(': ');
        }
        buffer.write('${values[i]}');
        if (i < count - 1) buffer.write(', ');
      }
      buffer.write(')');
      _printed = buffer.toString();
    }
    return _printed!;
  }
}

/// Cache for Record shapes. These are keyed by a distinct shape recipe,
/// which consists of an integer followed by space-separated named labels.
final _shapes = JS<Map<String, Shape>>('', 'new Map()');
final _records = JS('', 'new Map()');

Shape registerShape(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named) {
  var cached = JS<Shape?>('', '#.get(#)', _shapes, shapeRecipe);
  if (cached != null) {
    return cached;
  }

  var shape = Shape(positionals, named);
  JS('', '#.set(#, #)', _shapes, shapeRecipe, shape);
  return shape;
}

Object registerRecord(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named) {
  var cached = JS('', '#.get(#)', _records, shapeRecipe);
  if (cached != null) {
    return cached;
  }

  Object recordClass =
      JS('!', 'class _Record extends # {}', JS_CLASS_REF(_RecordImpl));
  // Add a 'new' function to be used instead of a constructor
  // (which is disallowed on dart objects).
  Object newRecord = JS(
      '!',
      '''
    #.new = function (shape, values) {
      #.__proto__.new.call(this, shape, values);
    }
  ''',
      recordClass,
      recordClass);

  JS('!', '#.prototype = #.prototype', newRecord, recordClass);
  var recordPrototype = JS('', '#.prototype', recordClass);

  _recordGet(@notNull int index) =>
      JS('!', 'function recordGet() {return this.values[#];}', index);

  // Add convenience getters for accessing the record's field values.
  var count = 0;
  while (count < positionals) {
    var name = '\$${count + 1}';
    defineAccessor(recordPrototype, name,
        get: _recordGet(count), enumerable: true);
    count++;
  }
  if (named != null) {
    for (final name in named) {
      defineAccessor(recordPrototype, name,
          get: _recordGet(count), enumerable: true);
      count++;
    }
  }

  JS('', '#.set(#, #)', _records, shapeRecipe, newRecord);
  return newRecord;
}

/// Creates a record type.
RecordType recordType(@notNull Shape shape, @notNull List types) =>
    RecordType.create(shape, types);

/// Creates a shape and binds it to [values].
///
/// [shapeRecipe] consists of a space-separated list of elements, where the
/// first element is the number of positional elements, followed by every
/// named element in sorted order.
Object recordLiteral(@notNull String shapeRecipe, @notNull int positionals,
    List<String>? named, @notNull List values) {
  var shape = registerShape(shapeRecipe, positionals, named);
  var record = registerRecord(shapeRecipe, positionals, named);
  return JS('!', 'new #(#, #)', record, shape, values);
}

/// Creates a shape and binds it to [types].
///
/// [shapeRecipe] consists of a space-separated list of elements, where the
/// first element is the number of positional elements, followed by every
/// named element in sorted order.
RecordType recordTypeLiteral(@notNull String shapeRecipe,
    @notNull int positionals, List<String>? named, @notNull List types) {
  var shape = registerShape(shapeRecipe, positionals, named);
  return recordType(shape, types);
}

/// Memo table for positional record field groups. A positional field packet
/// [type1, ..., typen] corresponds to the path n, type1, ...., typen.  The
/// element reached via this path (if any) is the canonical representative
/// for this packet.
/// TODO: unify with function argument types?
final _recordTypeArrayFieldMap = JS('', 'new Map()');

/// Memo table for function types. The index path consists of the
/// path length - 1, the returnType, the canonical positional argument
/// packet, and if present, the canonical optional or named argument
/// packet.  A level of indirection could be avoided here if desired.
final _recordTypeTypeMap = JS('', 'new Map()');

class RecordType extends DartType {
  final Shape shape;
  final List types;

  String? _printed;

  RecordType._(this.shape, this.types);

  /// Construct a record type.
  ///
  /// We eagerly normalize the field types to avoid having to deal with this
  /// logic in multiple places.
  ///
  /// Note: Generic record subtype checks assume types have been canonicalized
  /// when testing if type bounds are equal.
  static RecordType create(@notNull Shape shape, @notNull List types) {
    var canonicalized =
        _canonicalizeArray(JS('', '#', types), _recordTypeArrayFieldMap);
    var keys = JS('', '[#, #]', shape, canonicalized);
    var createType = () => RecordType._(shape, canonicalized);
    return _memoizeArray(_recordTypeTypeMap, keys, createType);
  }

  String toString() {
    if (_printed != null) return _printed!;

    var named = shape.named;
    var posCount = shape.positionals;
    var count = types.length;

    var buffer = StringBuffer();
    buffer.write('(');
    for (var i = 0; i < count; i++) {
      if (i < posCount) {
        buffer.write('${types[i]}');
      } else {
        if (i == posCount) {
          buffer.write('{');
        }
        buffer.write('${types[i]} ${named![i - posCount]}');
        if (i == count - 1) {
          buffer.write('}');
        }
      }
      if (i < count - 1) {
        buffer.write(', ');
      }
    }
    buffer.write(')');
    _printed = buffer.toString();
    return _printed!;
  }

  @JSExportName('is')
  bool is_T(obj) {
    if (obj is _RecordImpl) {
      var actual = getReifiedType(obj);
      return actual != null && isSubtypeOf(actual, this);
    }
    return false;
  }

  @JSExportName('as')
  as_T(obj) {
    if (is_T(obj)) return obj;
    // TODO(annagrin) This could directly call castError after we no longer
    // allow a cast of null to succeed in weak mode.
    return cast(obj, this);
  }
}
