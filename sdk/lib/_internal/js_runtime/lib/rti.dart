// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

/// This library contains support for runtime type information.
library rti;

import 'dart:_foreign_helper'
    show
        getInterceptor,
        getJSArrayInteropRti,
        JS,
        JS_BUILTIN,
        JS_EMBEDDED_GLOBAL,
        JS_GET_FLAG,
        JS_GET_NAME,
        RAW_DART_FUNCTION_REF,
        TYPE_REF,
        LEGACY_TYPE_REF;

import 'dart:_interceptors'
    show JavaScriptFunction, JSArray, JSUnmodifiableArray;

import 'dart:_js_names' show unmangleGlobalNameIfPreservedAnyways;

import 'dart:_js_embedded_names'
    show
        JsBuiltin,
        JsGetName,
        RtiUniverseFieldNames,
        CONSTRUCTOR_RTI_CACHE_PROPERTY_NAME,
        RTI_UNIVERSE,
        TYPES;

import 'dart:_recipe_syntax';

/// An Rti object represents both a type (e.g `Map<int, String>`) and a type
/// environment (`Map<int, String>` binds `Map.K=int` and `Map.V=String`).
///
/// There is a single [Rti] class to help reduce polymorphism in the JavaScript
/// runtime. The class has a default constructor and no final fields so it can
/// be created before much of the runtime exists.
///
/// The fields are declared in an order that gets shorter minified names for the
/// more commonly used fields. (TODO: we should exploit the fact that an Rti
/// instance never appears in a dynamic context, so does not need field names to
/// be distinct from dynamic selectors).
///
class Rti {
  /// JavaScript method for 'as' check. The method is called from generated code,
  /// e.g. `o as T` generates something like `rtiForT._as(o)`.
  @pragma('dart2js:noElision')
  dynamic _as;

  /// JavaScript method for type check.  The method is called from generated
  /// code, e.g. parameter check for `T param` generates something like
  /// `rtiForT._check(param)`.
  @pragma('dart2js:noElision')
  dynamic _check;

  /// JavaScript method for 'is' test.  The method is called from generated
  /// code, e.g. `o is T` generates something like `rtiForT._is(o)`.
  @pragma('dart2js:noElision')
  dynamic _is;

  static void _setAsCheckFunction(Rti rti, fn) {
    rti._as = fn;
  }

  static void _setTypeCheckFunction(Rti rti, fn) {
    rti._check = fn;
  }

  static void _setIsTestFunction(Rti rti, fn) {
    rti._is = fn;
  }

  @pragma('dart2js:tryInline')
  static bool _isCheck(Rti rti, object) {
    return JS(
        'bool', '#.#(#)', rti, JS_GET_NAME(JsGetName.RTI_FIELD_IS), object);
  }

  /// Method called from generated code to evaluate a type environment recipe in
  /// `this` type environment.
  Rti _eval(recipe) {
    // TODO(sra): Clone the fast-path of _Universe.evalInEnvironment to here.
    return _rtiEval(this, _Utils.asString(recipe));
  }

  /// Method called from generated code to extend `this` type environment (an
  /// interface or binding Rti) with function type arguments (a singleton
  /// argument or tuple of arguments).
  Rti _bind(typeOrTuple) => _rtiBind(this, _castToRti(typeOrTuple));

  /// Method called from generated code to extend `this` type (as a singleton
  /// type environment) with function type arguments (a singleton argument or
  /// tuple of arguments).
  Rti _bind1(Rti typeOrTuple) => _rtiBind1(this, typeOrTuple);

  // Precomputed derived types. These fields are used to hold derived types that
  // are computed eagerly.
  // TODO(sra): Implement precomputed type optimizations.

  /// If kind == kindInterface, holds the first type argument (if any).
  /// If kind == kindFutureOr, holds Future<T> where T is the base type.
  /// - This case is lazily initialized during subtype checks.
  /// If kind == kindStar, holds T? where T is the base type.
  /// - This case is lazily initialized during subtype checks.
  @pragma('dart2js:noElision')
  dynamic _precomputed1;

  static Object _getPrecomputed1(Rti rti) => rti._precomputed1;

  static void _setPrecomputed1(Rti rti, precomputed) {
    rti._precomputed1 = precomputed;
  }

  static Rti _getQuestionFromStar(universe, Rti rti) {
    assert(_getKind(rti) == kindStar);
    Rti question = _castToRtiOrNull(_getPrecomputed1(rti));
    if (question == null) {
      question =
          _Universe._lookupQuestionRti(universe, _getStarArgument(rti), true);
      Rti._setPrecomputed1(rti, question);
    }
    return question;
  }

  static Rti _getFutureFromFutureOr(universe, Rti rti) {
    assert(_getKind(rti) == kindFutureOr);
    Rti future = _castToRtiOrNull(_getPrecomputed1(rti));
    if (future == null) {
      future = _Universe._lookupFutureRti(universe, _getFutureOrArgument(rti));
      Rti._setPrecomputed1(rti, future);
    }
    return future;
  }

  dynamic _precomputed2;
  dynamic _precomputed3;
  dynamic _precomputed4;

  // Data value used by some tests.
  @pragma('dart2js:noElision')
  Object _specializedTestResource;

  static Object _getSpecializedTestResource(Rti rti) {
    return rti._specializedTestResource;
  }

  static void _setSpecializedTestResource(Rti rti, Object value) {
    rti._specializedTestResource = value;
  }

  // The Type object corresponding to this Rti.
  Object _cachedRuntimeType;
  static _Type _getCachedRuntimeType(Rti rti) =>
      JS('_Type|Null', '#', rti._cachedRuntimeType);
  static void _setCachedRuntimeType(Rti rti, _Type type) {
    rti._cachedRuntimeType = type;
  }

  /// The kind of Rti `this` is, one of the kindXXX constants below.
  ///
  /// We don't use an enum since we need to create Rti objects very early.
  ///
  /// The zero initializer ensures dart2js type analysis considers [_kind] is
  /// non-nullable.
  Object /*int*/ _kind = 0;

  static int _getKind(Rti rti) => _Utils.asInt(rti._kind);
  static void _setKind(Rti rti, int kind) {
    rti._kind = kind;
  }

  // Terminal terms.
  static const kindNever = 1;
  static const kindDynamic = 2;
  static const kindVoid = 3; // TODO(sra): Use `dynamic` instead?
  static const kindAny = 4; // Dart1-style 'dynamic' for JS-interop.
  static const kindErased = 5;
  // Unary terms.
  static const kindStar = 6;
  static const kindQuestion = 7;
  static const kindFutureOr = 8;
  // More complex terms.
  static const kindInterface = 9;
  // A vector of type parameters from enclosing functions and closures.
  static const kindBinding = 10;
  static const kindFunction = 11;
  static const kindGenericFunction = 12;
  static const kindGenericFunctionParameter = 13;

  static bool _isUnionOfFunctionType(Rti rti) {
    int kind = Rti._getKind(rti);
    if (kind == kindStar || kind == kindQuestion || kind == kindFutureOr) {
      return _isUnionOfFunctionType(_castToRti(_getPrimary(rti)));
    }
    return kind == kindFunction || kind == kindGenericFunction;
  }

  /// Primary data associated with type.
  ///
  /// - Minified name of interface for interface types.
  /// - Underlying type for unary terms.
  /// - Class part of a type environment inside a generic class, or `null` for
  ///   type tuple.
  /// - Return type of a function type.
  /// - Underlying function type for a generic function.
  /// - de Bruijn index for a generic function parameter.
  dynamic _primary;

  static Object _getPrimary(Rti rti) => rti._primary;
  static void _setPrimary(Rti rti, value) {
    rti._primary = value;
  }

  /// Additional data associated with type.
  ///
  /// - The type arguments of an interface type.
  /// - The type arguments from enclosing functions and closures for a
  ///   kindBinding.
  /// - The [_FunctionParameters] of a function type.
  /// - The type parameter bounds of a generic function.
  dynamic _rest;

  static Object _getRest(Rti rti) => rti._rest;
  static void _setRest(Rti rti, value) {
    rti._rest = value;
  }

  static String _getInterfaceName(Rti rti) {
    assert(_getKind(rti) == kindInterface);
    return _Utils.asString(_getPrimary(rti));
  }

  static JSArray _getInterfaceTypeArguments(Rti rti) {
    // The array is a plain JavaScript Array, otherwise we would need the type
    // `JSArray<Rti>` to exist before we could create the type `JSArray<Rti>`.
    assert(_getKind(rti) == kindInterface);
    return JS('JSUnmodifiableArray', '#', _getRest(rti));
  }

  static Rti _getBindingBase(Rti rti) {
    assert(_getKind(rti) == kindBinding);
    return _castToRti(_getPrimary(rti));
  }

  static JSArray _getBindingArguments(Rti rti) {
    assert(_getKind(rti) == kindBinding);
    return JS('JSUnmodifiableArray', '#', _getRest(rti));
  }

  static Rti _getStarArgument(Rti rti) {
    assert(_getKind(rti) == kindStar);
    return _castToRti(_getPrimary(rti));
  }

  static Rti _getQuestionArgument(Rti rti) {
    assert(_getKind(rti) == kindQuestion);
    return _castToRti(_getPrimary(rti));
  }

  static Rti _getFutureOrArgument(Rti rti) {
    assert(_getKind(rti) == kindFutureOr);
    return _castToRti(_getPrimary(rti));
  }

  static Rti _getReturnType(Rti rti) {
    assert(_getKind(rti) == kindFunction);
    return _castToRti(_getPrimary(rti));
  }

  static _FunctionParameters _getFunctionParameters(Rti rti) {
    assert(_getKind(rti) == kindFunction);
    return JS('_FunctionParameters', '#', _getRest(rti));
  }

  static Rti _getGenericFunctionBase(Rti rti) {
    assert(_getKind(rti) == kindGenericFunction);
    return _castToRti(_getPrimary(rti));
  }

  static JSArray _getGenericFunctionBounds(Rti rti) {
    assert(_getKind(rti) == kindGenericFunction);
    return JS('JSUnmodifiableArray', '#', _getRest(rti));
  }

  static int _getGenericFunctionParameterIndex(Rti rti) {
    assert(_getKind(rti) == kindGenericFunctionParameter);
    return _Utils.asInt(_getPrimary(rti));
  }

  /// On [Rti]s that are type environments*, derived types are cached on the
  /// environment to ensure fast canonicalization. Ground-term types (i.e. not
  /// dependent on class or function type parameters) are cached in the
  /// universe. This field starts as `null` and the cache is created on demand.
  ///
  /// *Any Rti can be a type environment, since we use the type for a function
  /// type environment. The ambiguity between 'generic class is the environment'
  /// and 'generic class is a singleton type argument' is resolved by using
  /// different indexing in the recipe.
  Object _evalCache;

  static Object _getEvalCache(Rti rti) => rti._evalCache;
  static void _setEvalCache(Rti rti, value) {
    rti._evalCache = value;
  }

  /// On [Rti]s that are type environments*, extended environments are cached on
  /// the base environment to ensure fast canonicalization.
  ///
  /// This field starts as `null` and the cache is created on demand.
  ///
  /// *This is valid only on kindInterface and kindBinding Rtis. The ambiguity
  /// between 'generic class is the base environment' and 'generic class is a
  /// singleton type argument' is resolved [TBD] (either (1) a bind1 cache, or
  /// (2)using `env._eval("@<0>")._bind(args)` in place of `env._bind1(args)`).
  ///
  /// On [Rti]s that are generic function types, results of instantiation are
  /// cached on the generic function type to ensure fast repeated
  /// instantiations.
  Object _bindCache;

  static Object _getBindCache(Rti rti) => rti._bindCache;
  static void _setBindCache(Rti rti, value) {
    rti._bindCache = value;
  }

  static Rti allocate() {
    return new Rti();
  }

  Object _canonicalRecipe;

  static String _getCanonicalRecipe(Rti rti) {
    Object s = rti._canonicalRecipe;
    assert(_Utils.isString(s), 'Missing canonical recipe');
    return _Utils.asString(s);
  }

  static void _setCanonicalRecipe(Rti rti, String s) {
    rti._canonicalRecipe = s;
  }
}

class _FunctionParameters {
  // TODO(fishythefish): Support required named parameters.

  static _FunctionParameters allocate() => _FunctionParameters();

  Object _requiredPositional;
  static JSArray _getRequiredPositional(_FunctionParameters parameters) =>
      JS('JSUnmodifiableArray', '#', parameters._requiredPositional);
  static void _setRequiredPositional(
      _FunctionParameters parameters, Object requiredPositional) {
    parameters._requiredPositional = requiredPositional;
  }

  Object _optionalPositional;
  static JSArray _getOptionalPositional(_FunctionParameters parameters) =>
      JS('JSUnmodifiableArray', '#', parameters._optionalPositional);
  static void _setOptionalPositional(
      _FunctionParameters parameters, Object optionalPositional) {
    parameters._optionalPositional = optionalPositional;
  }

  /// These are alternating name/type pairs; that is, the optional named
  /// parameters of the function
  ///
  ///   void foo({int bar, double baz})
  ///
  /// would be encoded as ["bar", int, "baz", double], where the even indices are
  /// the name [String]s and the odd indices are the type [Rti]s.
  ///
  /// Invariant: These pairs are sorted by name in lexicographically ascending order.
  Object _optionalNamed;
  static JSArray _getOptionalNamed(_FunctionParameters parameters) =>
      JS('JSUnmodifiableArray', '#', parameters._optionalNamed);
  static void _setOptionalNamed(
      _FunctionParameters parameters, Object optionalNamed) {
    parameters._optionalNamed = optionalNamed;
  }
}

Object _theUniverse() => JS_EMBEDDED_GLOBAL('', RTI_UNIVERSE);

Rti _rtiEval(Rti environment, String recipe) {
  return _Universe.evalInEnvironment(_theUniverse(), environment, recipe);
}

Rti _rtiBind1(Rti environment, Rti types) {
  return _Universe.bind1(_theUniverse(), environment, types);
}

Rti _rtiBind(Rti environment, Rti types) {
  return _Universe.bind(_theUniverse(), environment, types);
}

/// Evaluate a ground-term type.
/// Called from generated code.
Rti findType(String recipe) {
  // Since [findType] should only be called on recipes computed during
  // compilation, we can assume that the recipe is already normalized (since all
  // [DartType]s are normalized. This allows us to avoid an unfortunate cycle:
  //
  // If we attempt to normalize here, then during the course of normalization,
  // we may attempt to access a [TYPE_REF]. This uses the `type$` object, and
  // the values of this object are calls to [findType]. Thus, if we're currently
  // in one of these calls, then `type$` will appear to be undefined.
  return _Universe.eval(_theUniverse(), recipe, false);
}

/// Evaluate a type recipe in the environment of an instance.
Rti evalInInstance(instance, String recipe) {
  return _rtiEval(instanceType(instance), recipe);
}

/// Returns [genericFunctionRti] with type parameters bound to those specified
/// by [instantiationRti].
///
/// [genericFunctionRti] must be an rti representation with a number of generic
/// type parameters matching the number of types provided by [instantiationRti].
///
/// Called from generated code.
@pragma('dart2js:noInline')
Rti instantiatedGenericFunctionType(
    Rti genericFunctionRti, Rti instantiationRti) {
  // If --lax-runtime-type-to-string is enabled and we never check the function
  // type, then the function won't have a signature, so its RTI will be null. In
  // this case, there is nothing to instantiate, so we return `null` and the
  // instantiation appears to be an interface type instead.
  if (genericFunctionRti == null) return null;
  var bounds = Rti._getGenericFunctionBounds(genericFunctionRti);
  var typeArguments = Rti._getInterfaceTypeArguments(instantiationRti);
  assert(_Utils.arrayLength(bounds) == _Utils.arrayLength(typeArguments));

  var cache = Rti._getBindCache(genericFunctionRti);
  if (cache == null) {
    cache = JS('', 'new Map()');
    Rti._setBindCache(genericFunctionRti, cache);
  }
  String key = Rti._getCanonicalRecipe(instantiationRti);
  var probe = _Utils.mapGet(cache, key);
  if (probe != null) return _castToRti(probe);
  Rti rti = _instantiate(_theUniverse(),
      Rti._getGenericFunctionBase(genericFunctionRti), typeArguments, 0);
  _Utils.mapSet(cache, key, rti);
  return rti;
}

/// Substitutes [typeArguments] for generic function parameters in [rti].
///
/// Generic function parameters are de Bruijn indices counting up through the
/// parameters' scopes to index into [typeArguments].
///
/// [depth] is the number of subsequent generic function parameters that are in
/// scope. This is subtracted off the de Bruijn index for the type parameter to
/// arrive at an potential index into [typeArguments].
Rti _instantiate(universe, Rti rti, Object typeArguments, int depth) {
  int kind = Rti._getKind(rti);
  switch (kind) {
    case Rti.kindErased:
    case Rti.kindNever:
    case Rti.kindDynamic:
    case Rti.kindVoid:
    case Rti.kindAny:
      return rti;
    case Rti.kindStar:
      Rti baseType = _castToRti(Rti._getPrimary(rti));
      Rti instantiatedBaseType =
          _instantiate(universe, baseType, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedBaseType, baseType)) return rti;
      return _Universe._lookupStarRti(universe, instantiatedBaseType, true);
    case Rti.kindQuestion:
      Rti baseType = _castToRti(Rti._getPrimary(rti));
      Rti instantiatedBaseType =
          _instantiate(universe, baseType, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedBaseType, baseType)) return rti;
      return _Universe._lookupQuestionRti(universe, instantiatedBaseType, true);
    case Rti.kindFutureOr:
      Rti baseType = _castToRti(Rti._getPrimary(rti));
      Rti instantiatedBaseType =
          _instantiate(universe, baseType, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedBaseType, baseType)) return rti;
      return _Universe._lookupFutureOrRti(universe, instantiatedBaseType, true);
    case Rti.kindInterface:
      Object interfaceTypeArguments = Rti._getInterfaceTypeArguments(rti);
      Object instantiatedInterfaceTypeArguments = _instantiateArray(
          universe, interfaceTypeArguments, typeArguments, depth);
      if (_Utils.isIdentical(
          instantiatedInterfaceTypeArguments, interfaceTypeArguments))
        return rti;
      return _Universe._lookupInterfaceRti(universe, Rti._getInterfaceName(rti),
          instantiatedInterfaceTypeArguments);
    case Rti.kindBinding:
      Rti base = Rti._getBindingBase(rti);
      Rti instantiatedBase = _instantiate(universe, base, typeArguments, depth);
      Object arguments = Rti._getBindingArguments(rti);
      Object instantiatedArguments =
          _instantiateArray(universe, arguments, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedBase, base) &&
          _Utils.isIdentical(instantiatedArguments, arguments)) return rti;
      return _Universe._lookupBindingRti(
          universe, instantiatedBase, instantiatedArguments);
    case Rti.kindFunction:
      Rti returnType = Rti._getReturnType(rti);
      Rti instantiatedReturnType =
          _instantiate(universe, returnType, typeArguments, depth);
      _FunctionParameters functionParameters = Rti._getFunctionParameters(rti);
      _FunctionParameters instantiatedFunctionParameters =
          _instantiateFunctionParameters(
              universe, functionParameters, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedReturnType, returnType) &&
          _Utils.isIdentical(
              instantiatedFunctionParameters, functionParameters)) return rti;
      return _Universe._lookupFunctionRti(
          universe, instantiatedReturnType, instantiatedFunctionParameters);
    case Rti.kindGenericFunction:
      Object bounds = Rti._getGenericFunctionBounds(rti);
      depth += _Utils.arrayLength(bounds);
      Object instantiatedBounds =
          _instantiateArray(universe, bounds, typeArguments, depth);
      Rti base = Rti._getGenericFunctionBase(rti);
      Rti instantiatedBase = _instantiate(universe, base, typeArguments, depth);
      if (_Utils.isIdentical(instantiatedBounds, bounds) &&
          _Utils.isIdentical(instantiatedBase, base)) return rti;
      return _Universe._lookupGenericFunctionRti(
          universe, instantiatedBase, instantiatedBounds);
    case Rti.kindGenericFunctionParameter:
      int index = Rti._getGenericFunctionParameterIndex(rti);
      if (index < depth) return null;
      return _castToRti(_Utils.arrayAt(typeArguments, index - depth));
    default:
      throw AssertionError(
          'Attempted to instantiate unexpected RTI kind $kind');
  }
}

Object _instantiateArray(
    universe, Object rtiArray, Object typeArguments, int depth) {
  bool changed = false;
  int length = _Utils.arrayLength(rtiArray);
  Object result = JS('', '[]');
  for (int i = 0; i < length; i++) {
    Rti rti = _castToRti(_Utils.arrayAt(rtiArray, i));
    Rti instantiatedRti = _instantiate(universe, rti, typeArguments, depth);
    if (_Utils.isNotIdentical(instantiatedRti, rti)) {
      changed = true;
    }
    _Utils.arrayPush(result, instantiatedRti);
  }
  return changed ? result : rtiArray;
}

Object _instantiateNamed(
    universe, Object namedArray, Object typeArguments, int depth) {
  bool changed = false;
  int length = _Utils.arrayLength(namedArray);
  assert(length.isEven);
  Object result = JS('', '[]');
  for (int i = 0; i < length; i += 2) {
    String name = _Utils.asString(_Utils.arrayAt(namedArray, i));
    Rti rti = _castToRti(_Utils.arrayAt(namedArray, i + 1));
    Rti instantiatedRti = _instantiate(universe, rti, typeArguments, depth);
    if (_Utils.isNotIdentical(instantiatedRti, rti)) {
      changed = true;
    }
    _Utils.arrayPush(result, name);
    _Utils.arrayPush(result, instantiatedRti);
  }
  return changed ? result : namedArray;
}

// TODO(fishythefish): Support required named parameters.
_FunctionParameters _instantiateFunctionParameters(universe,
    _FunctionParameters functionParameters, Object typeArguments, int depth) {
  Object requiredPositional =
      _FunctionParameters._getRequiredPositional(functionParameters);
  Object instantiatedRequiredPositional =
      _instantiateArray(universe, requiredPositional, typeArguments, depth);
  Object optionalPositional =
      _FunctionParameters._getOptionalPositional(functionParameters);
  Object instantiatedOptionalPositional =
      _instantiateArray(universe, optionalPositional, typeArguments, depth);
  Object optionalNamed =
      _FunctionParameters._getOptionalNamed(functionParameters);
  Object instantiatedOptionalNamed =
      _instantiateNamed(universe, optionalNamed, typeArguments, depth);
  if (_Utils.isIdentical(instantiatedRequiredPositional, requiredPositional) &&
      _Utils.isIdentical(instantiatedOptionalPositional, optionalPositional) &&
      _Utils.isIdentical(instantiatedOptionalNamed, optionalNamed))
    return functionParameters;
  _FunctionParameters result = _FunctionParameters.allocate();
  _FunctionParameters._setRequiredPositional(
      result, instantiatedRequiredPositional);
  _FunctionParameters._setOptionalPositional(
      result, instantiatedOptionalPositional);
  _FunctionParameters._setOptionalNamed(result, instantiatedOptionalNamed);
  return result;
}

bool _isDartObject(object) => _Utils.instanceOf(object,
    JS_BUILTIN('depends:none;effects:none;', JsBuiltin.dartObjectConstructor));

bool _isClosure(object) => _Utils.instanceOf(object,
    JS_BUILTIN('depends:none;effects:none;', JsBuiltin.dartClosureConstructor));

/// Returns the structural function [Rti] of [closure], or `null`.
/// [closure] must be a subclass of [Closure].
/// Called from generated code.
Rti closureFunctionType(closure) {
  var signatureName = JS_GET_NAME(JsGetName.SIGNATURE_NAME);
  var signature = JS('', '#[#]', closure, signatureName);
  if (signature != null) {
    if (JS('bool', 'typeof # == "number"', signature)) {
      return getTypeFromTypesTable(_Utils.asInt(signature));
    }
    return _castToRti(JS('', '#[#]()', closure, signatureName));
  }
  return null;
}

/// Returns the Rti type of [object]. Closures have both an interface type
/// (Closures implement `Function`) and a structural function type. Uses
/// [testRti] to choose the appropriate type.
///
/// Called from generated code.
Rti instanceOrFunctionType(object, Rti testRti) {
  if (Rti._isUnionOfFunctionType(testRti)) {
    if (_isClosure(object)) {
      // If [testRti] is e.g. `FutureOr<Action>` (where `Action` is some
      // function type), we don't need to worry about the `Future<Action>`
      // branch because closures can't be `Future`s.
      Rti rti = closureFunctionType(object);
      if (rti != null) return rti;
    }
  }
  return instanceType(object);
}

/// Returns the Rti type of [object].
/// This is the general entry for obtaining the interface type of any value.
/// Called from generated code.
Rti instanceType(object) {
  // TODO(sra): Add interceptor-based specializations of this method. Inject a
  // _getRti method into (Dart)Object, JSArray, and Interceptor. Then calls to
  // this method can be generated as `getInterceptor(o)._getRti(o)`, allowing
  // interceptor optimizations to select the specialization. If the only use of
  // `getInterceptor` is for calling `_getRti`, then `instanceType` can be
  // called, similar to a one-shot interceptor call. This would improve type
  // lookup in ListMixin code as the interceptor is JavaScript 'this'.

  if (_isDartObject(object)) {
    return _instanceType(object);
  }

  if (_Utils.isArray(object)) {
    return _arrayInstanceType(object);
  }

  var interceptor = getInterceptor(object);
  return _instanceTypeFromConstructor(interceptor);
}

/// Returns the Rti type of JavaScript Array [object].
/// Called from generated code.
Rti _arrayInstanceType(object) {
  // A JavaScript Array can come from three places:
  //   1. This Dart program.
  //   2. Another Dart program loaded in the JavaScript environment.
  //   3. From outside of a Dart program.
  //
  // In case 3 we default to a fixed type for all external Arrays.  To protect
  // against an Array passed between two Dart programs loaded into the same
  // JavaScript isolate (communicating e.g. via JS-interop), we check that the
  // stored value is 'our' Rti type.
  //
  // TODO(40175): Investigate if it is more efficient to have each Dart program
  // use a unique JavaScript property so that both case 2 and case 3 look like a
  // missing value. In ES6 we could use a globally named JavaScript Symbol. For
  // IE11 we would have to synthesise a String property-name with almost zero
  // chance of conflict.

  var rti = JS('', r'#[#]', object, JS_GET_NAME(JsGetName.RTI_NAME));
  var defaultRti = getJSArrayInteropRti();

  // Case 3.
  if (rti == null) return _castToRti(defaultRti);

  // Case 2 and perhaps case 3. Check constructor of extracted type against a
  // known instance of Rti - this is an easy way to get the constructor.
  if (JS('bool', '#.constructor !== #.constructor', rti, defaultRti)) {
    return _castToRti(defaultRti);
  }

  // Case 1.
  return _castToRti(rti);
}

/// Returns the Rti type of user-defined class [object].
/// [object] must not be an intercepted class or a closure.
/// Called from generated code.
Rti _instanceType(object) {
  var rti = JS('', r'#[#]', object, JS_GET_NAME(JsGetName.RTI_NAME));
  return rti != null ? _castToRti(rti) : _instanceTypeFromConstructor(object);
}

String instanceTypeName(object) {
  Rti rti = instanceType(object);
  return _rtiToString(rti, null);
}

Rti _instanceTypeFromConstructor(instance) {
  var constructor = JS('', '#.constructor', instance);
  var probe = JS('', r'#[#]', constructor, CONSTRUCTOR_RTI_CACHE_PROPERTY_NAME);
  if (probe != null) return _castToRti(probe);
  return _instanceTypeFromConstructorMiss(instance, constructor);
}

@pragma('dart2js:noInline')
Rti _instanceTypeFromConstructorMiss(instance, constructor) {
  // Subclasses of Closure are synthetic classes. The synthetic classes all
  // extend a 'normal' class (Closure, BoundClosure, StaticClosure), so make
  // them appear to be the superclass. Instantiations have a `$ti` field so
  // don't reach here.
  //
  // TODO(39214): This will need fixing if we ever use instances of
  // StaticClosure for static tear-offs.
  //
  // TODO(sra): Can this test be avoided, e.g. by putting $ti on the
  // prototype of Closure/BoundClosure/StaticClosure classes?
  var effectiveConstructor = _isClosure(instance)
      ? JS('', '#.__proto__.__proto__.constructor', instance)
      : constructor;
  Rti rti = _Universe.findErasedType(
      _theUniverse(), JS('String', '#.name', effectiveConstructor));
  JS('', r'#[#] = #', constructor, CONSTRUCTOR_RTI_CACHE_PROPERTY_NAME, rti);
  return rti;
}

/// Returns the structural function type of [object], or `null` if the object is
/// not a closure.
Rti _instanceFunctionType(object) =>
    _isClosure(object) ? closureFunctionType(object) : null;

/// Returns Rti from types table. The types table is initialized with recipe
/// strings.
Rti getTypeFromTypesTable(/*int*/ _index) {
  int index = _Utils.asInt(_index);
  var table = JS_EMBEDDED_GLOBAL('', TYPES);
  var type = _Utils.arrayAt(table, index);
  if (_Utils.isString(type)) {
    Rti rti = findType(_Utils.asString(type));
    _Utils.arraySetAt(table, index, rti);
    return rti;
  }
  return _castToRti(type);
}

Type getRuntimeType(object) {
  Rti rti = _instanceFunctionType(object) ?? instanceType(object);
  return createRuntimeType(rti);
}

/// Called from generated code.
Type createRuntimeType(Rti rti) {
  _Type type = Rti._getCachedRuntimeType(rti);
  if (type != null) return type;
  // TODO(fishythefish, https://github.com/dart-lang/language/issues/428) For
  // NNBD transition, canonicalization may be needed. It might be possible to
  // generate a star-free recipe from the canonical recipe and evaluate that.
  type = _Type(rti);
  Rti._setCachedRuntimeType(rti, type);
  return type;
}

/// Called from generated code in the constant pool.
Type typeLiteral(String recipe) {
  return createRuntimeType(findType(recipe));
}

/// Implementation of [Type] based on Rti.
class _Type implements Type {
  final Rti _rti;
  int _hashCode;

  _Type(this._rti);

  int get hashCode => _hashCode ??= Rti._getCanonicalRecipe(_rti).hashCode;

  @pragma('dart2js:noInline')
  bool operator ==(other) {
    return (other is _Type) && identical(_rti, other._rti);
  }

  @override
  String toString() => _rtiToString(_rti, null);
}

/// Called from generated code.
///
/// The first time the default `_is` method is called, it replaces itself with a
/// specialized version.
// TODO(sra): Emit code to force-replace the `_is` method, generated dependent
// on the types used in the program. e.g.
//
//     findType("bool")._is = H._isBool;
//
// This could be omitted if (1) the `bool` rti is not used directly for a test
// (e.g. we lower a check to a direct helper), and (2) `bool` does not flow to a
// tested type parameter. The trick will be to ensure that `H._isBool` is
// generated.
bool _installSpecializedIsTest(object) {
  // This static method is installed on an Rti object as a JavaScript instance
  // method. The Rti object is 'this'.
  Rti testRti = _castToRti(JS('', 'this'));
  int kind = Rti._getKind(testRti);

  var isFn = RAW_DART_FUNCTION_REF(_generalIsTestImplementation);

  if (isTopType(testRti)) {
    isFn = RAW_DART_FUNCTION_REF(_isTop);
    var asFn = RAW_DART_FUNCTION_REF(_asTop);
    Rti._setAsCheckFunction(testRti, asFn);
    Rti._setTypeCheckFunction(testRti, asFn);
  } else if (kind == Rti.kindInterface) {
    String key = Rti._getCanonicalRecipe(testRti);

    if (JS_GET_NAME(JsGetName.INT_RECIPE) == key) {
      isFn = RAW_DART_FUNCTION_REF(_isInt);
    } else if (JS_GET_NAME(JsGetName.DOUBLE_RECIPE) == key) {
      isFn = RAW_DART_FUNCTION_REF(_isNum);
    } else if (JS_GET_NAME(JsGetName.NUM_RECIPE) == key) {
      isFn = RAW_DART_FUNCTION_REF(_isNum);
    } else if (JS_GET_NAME(JsGetName.STRING_RECIPE) == key) {
      isFn = RAW_DART_FUNCTION_REF(_isString);
    } else if (JS_GET_NAME(JsGetName.BOOL_RECIPE) == key) {
      isFn = RAW_DART_FUNCTION_REF(_isBool);
    } else {
      String name = Rti._getInterfaceName(testRti);
      var arguments = Rti._getInterfaceTypeArguments(testRti);
      if (JS(
          'bool', '#.every(#)', arguments, RAW_DART_FUNCTION_REF(isTopType))) {
        String propertyName =
            '${JS_GET_NAME(JsGetName.OPERATOR_IS_PREFIX)}${name}';
        Rti._setSpecializedTestResource(testRti, propertyName);
        isFn = RAW_DART_FUNCTION_REF(_isTestViaProperty);
      }
    }
  }

  Rti._setIsTestFunction(testRti, isFn);
  return Rti._isCheck(testRti, object);
}

/// Called from generated code.
bool _generalIsTestImplementation(object) {
  // This static method is installed on an Rti object as a JavaScript instance
  // method. The Rti object is 'this'.
  Rti testRti = _castToRti(JS('', 'this'));
  Rti objectRti = instanceOrFunctionType(object, testRti);
  return isSubtype(_theUniverse(), objectRti, testRti);
}

/// Called from generated code.
bool _isTestViaProperty(object) {
  // This static method is installed on an Rti object as a JavaScript instance
  // method. The Rti object is 'this'.
  Rti testRti = _castToRti(JS('', 'this'));
  var tag = Rti._getSpecializedTestResource(testRti);

  // This test is redundant with getInterceptor below, but getInterceptor does
  // the tests in the wrong order for most tags, so it is usually faster to have
  // this check.
  if (_isDartObject(object)) {
    return JS('bool', '!!#[#]', object, tag);
  }

  var interceptor = getInterceptor(object);
  return JS('bool', '!!#[#]', interceptor, tag);
}

/// Called from generated code.
_generalAsCheckImplementation(object) {
  if (object == null) return object;
  // This static method is installed on an Rti object as a JavaScript instance
  // method. The Rti object is 'this'.
  Rti testRti = _castToRti(JS('', 'this'));
  if (Rti._isCheck(testRti, object)) return object;

  Rti objectRti = instanceOrFunctionType(object, testRti);
  String message =
      _Error.compose(object, objectRti, _rtiToString(testRti, null));
  throw _CastError.fromMessage(message);
}

/// Called from generated code.
_generalTypeCheckImplementation(object) {
  if (object == null) return object;
  // This static method is installed on an Rti object as a JavaScript instance
  // method. The Rti object is 'this'.
  Rti testRti = _castToRti(JS('', 'this'));
  if (Rti._isCheck(testRti, object)) return object;

  Rti objectRti = instanceOrFunctionType(object, testRti);
  String message =
      _Error.compose(object, objectRti, _rtiToString(testRti, null));
  throw _TypeError.fromMessage(message);
}

/// Called from generated code.
checkTypeBound(Rti type, Rti bound, variable, methodName) {
  if (isSubtype(_theUniverse(), type, bound)) return type;
  String message = "The type argument '${_rtiToString(type, null)}' is not"
      " a subtype of the type variable bound '${_rtiToString(bound, null)}'"
      " of type variable '${_Utils.asString(variable)}' in '$methodName'.";
  throw _TypeError.fromMessage(message);
}

/// Base class to _CastError and _TypeError.
class _Error extends Error {
  final String _message;
  _Error(this._message);

  static String compose(object, objectRti, checkedTypeDescription) {
    String objectDescription = Error.safeToString(object);
    objectRti ??= instanceType(object);
    String objectTypeDescription = _rtiToString(objectRti, null);
    return "${objectDescription}:"
        " type '${objectTypeDescription}'"
        " is not a subtype of type '${checkedTypeDescription}'";
  }

  @override
  String toString() => _message;
}

class _CastError extends _Error implements CastError {
  _CastError.fromMessage(String message) : super('CastError: $message');

  factory _CastError.forType(object, String type) {
    return _CastError.fromMessage(_Error.compose(object, null, type));
  }
}

class _TypeError extends _Error implements TypeError {
  _TypeError.fromMessage(String message) : super('TypeError: $message');

  factory _TypeError.forType(object, String type) {
    return _TypeError.fromMessage(_Error.compose(object, null, type));
  }

  @override
  String get message => _message;
}

// Specializations.
//
// Specializations can be placed on Rti objects as the _as, _check and _is
// 'methods'. They can also be called directly called from generated code.

/// Specialization for 'is dynamic' and other top types.
/// Called from generated code via Rti `_is` method.
bool _isTop(object) {
  return true;
}

/// Specialization for 'as dynamic' and other top types.
/// Called from generated code via Rti `_as` and `_check` methods.
dynamic _asTop(object) {
  return object;
}

/// Specialization for 'is bool'.
/// Called from generated code.
bool _isBool(object) {
  return true == object || false == object;
}

/// Specialization for 'as bool?'.
/// Called from generated code.
bool /*?*/ _asBoolNullable(object) {
  if (_isBool(object)) return _Utils.asBool(object);
  if (object == null) return object;
  throw _CastError.forType(object, 'bool');
}

/// Specialization for check on 'bool?'.
/// Called from generated code.
bool /*?*/ _checkBoolNullable(object) {
  if (_isBool(object)) return _Utils.asBool(object);
  if (object == null) return object;
  throw _TypeError.forType(object, 'bool');
}

/// Specialization for 'as double?'.
/// Called from generated code.
double /*?*/ _asDoubleNullable(object) {
  if (_isNum(object)) return _Utils.asDouble(object);
  if (object == null) return object;
  throw _CastError.forType(object, 'double');
}

/// Specialization for check on 'double?'.
/// Called from generated code.
double /*?*/ _checkDoubleNullable(object) {
  if (_isNum(object)) return _Utils.asDouble(object);
  if (object == null) return object;
  throw _TypeError.forType(object, 'double');
}

/// Specialization for 'is int'.
/// Called from generated code.
bool _isInt(object) {
  return JS('bool', 'typeof # == "number"', object) &&
      JS('bool', 'Math.floor(#) === #', object, object);
}

/// Specialization for 'as int?'.
/// Called from generated code.
int /*?*/ _asIntNullable(object) {
  if (_isInt(object)) return _Utils.asInt(object);
  if (object == null) return object;
  throw _CastError.forType(object, 'int');
}

/// Specialization for check on 'int?'.
/// Called from generated code.
int /*?*/ _checkIntNullable(object) {
  if (_isInt(object)) return _Utils.asInt(object);
  if (object == null) return object;
  throw _TypeError.forType(object, 'int');
}

/// Specialization for 'is num' and 'is double'.
/// Called from generated code.
bool _isNum(object) {
  return JS('bool', 'typeof # == "number"', object);
}

/// Specialization for 'as num?'.
/// Called from generated code.
num /*?*/ _asNumNullable(object) {
  if (_isNum(object)) return _Utils.asNum(object);
  if (object == null) return object;
  throw _CastError.forType(object, 'num');
}

/// Specialization for check on 'num?'.
/// Called from generated code.
num /*?*/ _checkNumNullable(object) {
  if (_isNum(object)) return _Utils.asNum(object);
  if (object == null) return object;
  throw _TypeError.forType(object, 'num');
}

/// Specialization for 'is String'.
/// Called from generated code.
bool _isString(object) {
  return JS('bool', 'typeof # == "string"', object);
}

/// Specialization for 'as String?'.
/// Called from generated code.
String /*?*/ _asStringNullable(object) {
  if (_isString(object)) return _Utils.asString(object);
  if (object == null) return object;
  throw _CastError.forType(object, 'String');
}

/// Specialization for check on 'String?'.
/// Called from generated code.
String /*?*/ _checkStringNullable(object) {
  if (_isString(object)) return _Utils.asString(object);
  if (object == null) return object;
  throw _TypeError.forType(object, 'String');
}

String _rtiArrayToString(Object array, List<String> genericContext) {
  String s = '', sep = '';
  for (int i = 0; i < _Utils.arrayLength(array); i++) {
    s += sep +
        _rtiToString(_castToRti(_Utils.arrayAt(array, i)), genericContext);
    sep = ', ';
  }
  return s;
}

String _functionRtiToString(Rti functionType, List<String> genericContext,
    {Object bounds = null}) {
  String typeParametersText = '';
  int outerContextLength;

  if (bounds != null) {
    int boundsLength = _Utils.arrayLength(bounds);
    if (genericContext == null) {
      genericContext = <String>[];
    } else {
      outerContextLength = genericContext.length;
    }
    int offset = genericContext.length;
    for (int i = boundsLength; i > 0; i--) {
      genericContext.add('T${offset + i}');
    }

    String typeSep = '';
    typeParametersText = '<';
    for (int i = 0; i < boundsLength; i++) {
      typeParametersText += typeSep;
      typeParametersText += genericContext[genericContext.length - 1 - i];
      Rti boundRti = _castToRti(_Utils.arrayAt(bounds, i));
      if (!isTopType(boundRti)) {
        typeParametersText +=
            ' extends ' + _rtiToString(boundRti, genericContext);
      }
      typeSep = ', ';
    }
    typeParametersText += '>';
  }

  // TODO(fishythefish): Support required named parameters.
  Rti returnType = Rti._getReturnType(functionType);
  _FunctionParameters parameters = Rti._getFunctionParameters(functionType);
  var requiredPositional =
      _FunctionParameters._getRequiredPositional(parameters);
  int requiredPositionalLength = _Utils.arrayLength(requiredPositional);
  var optionalPositional =
      _FunctionParameters._getOptionalPositional(parameters);
  int optionalPositionalLength = _Utils.arrayLength(optionalPositional);
  var optionalNamed = _FunctionParameters._getOptionalNamed(parameters);
  int optionalNamedLength = _Utils.arrayLength(optionalNamed);
  assert(optionalPositionalLength == 0 || optionalNamedLength == 0);

  String returnTypeText = _rtiToString(returnType, genericContext);

  String argumentsText = '';
  String sep = '';
  for (int i = 0; i < requiredPositionalLength; i++) {
    argumentsText += sep +
        _rtiToString(
            _castToRti(_Utils.arrayAt(requiredPositional, i)), genericContext);
    sep = ', ';
  }

  if (optionalPositionalLength > 0) {
    argumentsText += sep + '[';
    sep = '';
    for (int i = 0; i < optionalPositionalLength; i++) {
      argumentsText += sep +
          _rtiToString(_castToRti(_Utils.arrayAt(optionalPositional, i)),
              genericContext);
      sep = ', ';
    }
    argumentsText += ']';
  }

  if (optionalNamedLength > 0) {
    argumentsText += sep + '{';
    sep = '';
    for (int i = 0; i < optionalNamedLength; i += 2) {
      argumentsText += sep +
          _rtiToString(_castToRti(_Utils.arrayAt(optionalNamed, i + 1)),
              genericContext) +
          ' ' +
          _Utils.asString(_Utils.arrayAt(optionalNamed, i));
      sep = ', ';
    }
    argumentsText += '}';
  }

  if (outerContextLength != null) {
    // Pop all of the generic type parameters.
    JS('', '#.length = #', genericContext, outerContextLength);
  }

  // TODO(fishythefish): Below is the same format as the VM. Change to:
  //
  //     return '${returnTypeText} Function${typeParametersText}(${argumentsText})';
  //
  return '${typeParametersText}(${argumentsText}) => ${returnTypeText}';
}

String _rtiToString(Rti rti, List<String> genericContext) {
  int kind = Rti._getKind(rti);

  if (kind == Rti.kindErased) return 'erased';
  if (kind == Rti.kindDynamic) return 'dynamic';
  if (kind == Rti.kindVoid) return 'void';
  if (kind == Rti.kindNever) return 'Never';
  if (kind == Rti.kindAny) return 'any';

  if (kind == Rti.kindStar) {
    Rti starArgument = Rti._getStarArgument(rti);
    String s = _rtiToString(starArgument, genericContext);
    int argumentKind = Rti._getKind(starArgument);
    if (argumentKind == Rti.kindFunction ||
        argumentKind == Rti.kindGenericFunction) {
      s = '(' + s + ')';
    }
    return s + '*';
  }

  if (kind == Rti.kindQuestion) {
    Rti questionArgument = Rti._getQuestionArgument(rti);
    String s = _rtiToString(questionArgument, genericContext);
    int argumentKind = Rti._getKind(questionArgument);
    if (argumentKind == Rti.kindFunction ||
        argumentKind == Rti.kindGenericFunction) {
      s = '(' + s + ')';
    }
    return s + '?';
  }

  if (kind == Rti.kindFutureOr) {
    Rti futureOrArgument = Rti._getFutureOrArgument(rti);
    return 'FutureOr<${_rtiToString(futureOrArgument, genericContext)}>';
  }

  if (kind == Rti.kindInterface) {
    String name = Rti._getInterfaceName(rti);
    name = _unminifyOrTag(name);
    var arguments = Rti._getInterfaceTypeArguments(rti);
    if (arguments.length != 0) {
      name += '<' + _rtiArrayToString(arguments, genericContext) + '>';
    }
    return name;
  }

  if (kind == Rti.kindFunction) {
    return _functionRtiToString(rti, genericContext);
  }

  if (kind == Rti.kindGenericFunction) {
    Rti baseFunctionType = Rti._getGenericFunctionBase(rti);
    Object bounds = Rti._getGenericFunctionBounds(rti);
    return _functionRtiToString(baseFunctionType, genericContext,
        bounds: bounds);
  }

  if (kind == Rti.kindGenericFunctionParameter) {
    int index = Rti._getGenericFunctionParameterIndex(rti);
    return genericContext[genericContext.length - 1 - index];
  }

  return '?';
}

String _unminifyOrTag(String rawClassName) {
  String preserved = unmangleGlobalNameIfPreservedAnyways(rawClassName);
  if (preserved != null) return preserved;
  return JS_GET_FLAG('MINIFIED') ? 'minified:$rawClassName' : rawClassName;
}

String _rtiArrayToDebugString(Object array) {
  String s = '[', sep = '';
  for (int i = 0; i < _Utils.arrayLength(array); i++) {
    s += sep + _rtiToDebugString(_castToRti(_Utils.arrayAt(array, i)));
    sep = ', ';
  }
  return s + ']';
}

String functionParametersToString(_FunctionParameters parameters) {
  // TODO(fishythefish): Support required named parameters.
  String s = '(', sep = '';
  var requiredPositional =
      _FunctionParameters._getRequiredPositional(parameters);
  int requiredPositionalLength = _Utils.arrayLength(requiredPositional);
  var optionalPositional =
      _FunctionParameters._getOptionalPositional(parameters);
  int optionalPositionalLength = _Utils.arrayLength(optionalPositional);
  var optionalNamed = _FunctionParameters._getOptionalNamed(parameters);
  int optionalNamedLength = _Utils.arrayLength(optionalNamed);
  assert(optionalPositionalLength == 0 || optionalNamedLength == 0);

  for (int i = 0; i < requiredPositionalLength; i++) {
    s += sep +
        _rtiToDebugString(_castToRti(_Utils.arrayAt(requiredPositional, i)));
    sep = ', ';
  }

  if (optionalPositionalLength > 0) {
    s += sep + '[';
    sep = '';
    for (int i = 0; i < optionalPositionalLength; i++) {
      s += sep +
          _rtiToDebugString(_castToRti(_Utils.arrayAt(optionalPositional, i)));
      sep = ', ';
    }
    s += ']';
  }

  if (optionalNamedLength > 0) {
    s += sep + '{';
    sep = '';
    for (int i = 0; i < optionalNamedLength; i += 2) {
      s += sep +
          _rtiToDebugString(_castToRti(_Utils.arrayAt(optionalNamed, i + 1))) +
          ' ' +
          _Utils.asString(_Utils.arrayAt(optionalNamed, i));
      sep = ', ';
    }
    s += '}';
  }

  return s + ')';
}

String _rtiToDebugString(Rti rti) {
  int kind = Rti._getKind(rti);

  if (kind == Rti.kindErased) return 'erased';
  if (kind == Rti.kindDynamic) return 'dynamic';
  if (kind == Rti.kindVoid) return 'void';
  if (kind == Rti.kindNever) return 'Never';
  if (kind == Rti.kindAny) return 'any';

  if (kind == Rti.kindStar) {
    Rti starArgument = Rti._getStarArgument(rti);
    return 'star(${_rtiToDebugString(starArgument)})';
  }

  if (kind == Rti.kindQuestion) {
    Rti questionArgument = Rti._getQuestionArgument(rti);
    return 'question(${_rtiToDebugString(questionArgument)})';
  }

  if (kind == Rti.kindFutureOr) {
    Rti futureOrArgument = Rti._getFutureOrArgument(rti);
    return 'FutureOr(${_rtiToDebugString(futureOrArgument)})';
  }

  if (kind == Rti.kindInterface) {
    String name = Rti._getInterfaceName(rti);
    var arguments = Rti._getInterfaceTypeArguments(rti);
    if (_Utils.arrayLength(arguments) == 0) {
      return 'interface("$name")';
    } else {
      return 'interface("$name", ${_rtiArrayToDebugString(arguments)})';
    }
  }

  if (kind == Rti.kindBinding) {
    Rti base = Rti._getBindingBase(rti);
    var arguments = Rti._getBindingArguments(rti);
    return 'binding(${_rtiToDebugString(base)}, ${_rtiArrayToDebugString(arguments)})';
  }

  if (kind == Rti.kindFunction) {
    Rti returnType = Rti._getReturnType(rti);
    _FunctionParameters parameters = Rti._getFunctionParameters(rti);
    return 'function(${_rtiToDebugString(returnType)}, ${functionParametersToString(parameters)})';
  }

  if (kind == Rti.kindGenericFunction) {
    Rti baseFunctionType = Rti._getGenericFunctionBase(rti);
    Object bounds = Rti._getGenericFunctionBounds(rti);
    return 'genericFunction(${_rtiToDebugString(baseFunctionType)}, ${_rtiArrayToDebugString(bounds)})';
  }

  if (kind == Rti.kindGenericFunctionParameter) {
    int index = Rti._getGenericFunctionParameterIndex(rti);
    return 'genericFunctionParameter($index)';
  }

  return 'other(kind=$kind)';
}

/// Class of static methods for the universe of Rti objects.
///
/// The universe is the manager object for the Rti instances.
///
/// The universe itself is allocated at startup before any types or Dart objects
/// can be created, so it does not have a Dart type.
class _Universe {
  _Universe._() {
    throw UnimplementedError('_Universe is static methods only');
  }

  @pragma('dart2js:noInline')
  static Object create() {
    // This needs to be kept in sync with `FragmentEmitter.createRtiUniverse` in
    // `fragment_emitter.dart`.
    return JS(
        '',
        '{'
            '#: new Map(),'
            '#: {},'
            '#: {},'
            '#: {},'
            '#: [],' // shared empty array.
            '}',
        RtiUniverseFieldNames.evalCache,
        RtiUniverseFieldNames.typeRules,
        RtiUniverseFieldNames.erasedTypes,
        RtiUniverseFieldNames.typeParameterVariances,
        RtiUniverseFieldNames.sharedEmptyArray);
  }

  // Field accessors.

  static evalCache(universe) =>
      JS('', '#.#', universe, RtiUniverseFieldNames.evalCache);

  static Object typeRules(universe) =>
      JS('', '#.#', universe, RtiUniverseFieldNames.typeRules);

  static Object erasedTypes(universe) =>
      JS('', '#.#', universe, RtiUniverseFieldNames.erasedTypes);

  static Object typeParameterVariances(universe) =>
      JS('', '#.#', universe, RtiUniverseFieldNames.typeParameterVariances);

  static Object _findRule(universe, String targetType) =>
      JS('', '#.#', typeRules(universe), targetType);

  static Object findRule(universe, String targetType) {
    Object rule = _findRule(universe, targetType);
    while (_Utils.isString(rule)) {
      rule = _findRule(universe, _Utils.asString(rule));
    }
    return rule;
  }

  static Rti findErasedType(universe, String cls) {
    Object metadata = erasedTypes(universe);
    var probe = JS('', '#.#', metadata, cls);
    if (probe == null) {
      return eval(universe, cls, false);
    } else if (_Utils.isNum(probe)) {
      int length = _Utils.asInt(probe);
      Rti erased = _lookupErasedRti(universe);
      Object arguments = JS('', '[]');
      for (int i = 0; i < length; i++) {
        _Utils.arrayPush(arguments, erased);
      }
      Rti interface = _lookupInterfaceRti(universe, cls, arguments);
      JS('', '#.# = #', metadata, cls, interface);
      return interface;
    } else {
      return _castToRti(probe);
    }
  }

  static Object findTypeParameterVariances(universe, String cls) =>
      JS('', '#.#', typeParameterVariances(universe), cls);

  static void addRules(universe, rules) =>
      _Utils.objectAssign(typeRules(universe), rules);

  static void addErasedTypes(universe, types) =>
      _Utils.objectAssign(erasedTypes(universe), types);

  static void addTypeParameterVariances(universe, variances) =>
      _Utils.objectAssign(typeParameterVariances(universe), variances);

  static Object sharedEmptyArray(universe) =>
      JS('JSArray', '#.#', universe, RtiUniverseFieldNames.sharedEmptyArray);

  /// Evaluates [recipe] in the global environment.
  static Rti eval(Object universe, String recipe, bool normalize) {
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, recipe);
    if (probe != null) return _castToRti(probe);
    Rti rti = _parseRecipe(universe, null, recipe, normalize);
    _cacheSet(cache, recipe, rti);
    return rti;
  }

  static Rti evalInEnvironment(
      Object universe, Rti environment, String recipe) {
    var cache = Rti._getEvalCache(environment);
    if (cache == null) {
      cache = JS('', 'new Map()');
      Rti._setEvalCache(environment, cache);
    }
    var probe = _cacheGet(cache, recipe);
    if (probe != null) return _castToRti(probe);
    Rti rti = _parseRecipe(universe, environment, recipe, true);
    _cacheSet(cache, recipe, rti);
    return rti;
  }

  static Rti bind(Object universe, Rti environment, Rti argumentsRti) {
    var cache = Rti._getBindCache(environment);
    if (cache == null) {
      cache = JS('', 'new Map()');
      Rti._setBindCache(environment, cache);
    }
    String argumentsRecipe = Rti._getCanonicalRecipe(argumentsRti);
    var probe = _cacheGet(cache, argumentsRecipe);
    if (probe != null) return _castToRti(probe);
    var argumentsArray;
    if (Rti._getKind(argumentsRti) == Rti.kindBinding) {
      argumentsArray = Rti._getBindingArguments(argumentsRti);
    } else {
      argumentsArray = JS('', '[#]', argumentsRti);
    }
    Rti rti = _lookupBindingRti(universe, environment, argumentsArray);
    _cacheSet(cache, argumentsRecipe, rti);
    return rti;
  }

  static Rti bind1(Object universe, Rti environment, Rti argumentsRti) {
    throw UnimplementedError('_Universe.bind1');
  }

  static Rti evalTypeVariable(Object universe, Rti environment, String name) {
    int kind = Rti._getKind(environment);
    if (kind == Rti.kindBinding) {
      environment = Rti._getBindingBase(environment);
    }

    String interfaceName = Rti._getInterfaceName(environment);
    Object rule = _Universe.findRule(universe, interfaceName);
    assert(rule != null);
    String recipe = TypeRule.lookupTypeVariable(rule, name);
    if (recipe == null) {
      throw 'No "$name" in "${Rti._getCanonicalRecipe(environment)}"';
    }
    return _Universe.evalInEnvironment(universe, environment, recipe);
  }

  static _cacheGet(cache, key) => JS('', '#.get(#)', cache, key);
  static void _cacheSet(cache, key, value) {
    JS('', '#.set(#, #)', cache, key, value);
  }

  static Rti _parseRecipe(
      Object universe, Object environment, String recipe, bool normalize) {
    Object parser = _Parser.create(universe, environment, recipe, normalize);
    Rti rti = _Parser.parse(parser);
    if (rti != null) return rti;
    throw UnimplementedError('_Universe._parseRecipe("$recipe")');
  }

  static Rti _installTypeTests(Object universe, Rti rti) {
    // Set up methods to perform type tests. The general as-check / type-check
    // methods use the is-test method. The is-test method on first use
    // overwrites itself, and possibly the as-check / type-check methods, with a
    // specialized version.
    var checkFn = RAW_DART_FUNCTION_REF(_generalTypeCheckImplementation);
    var asFn = RAW_DART_FUNCTION_REF(_generalAsCheckImplementation);
    var isFn = RAW_DART_FUNCTION_REF(_installSpecializedIsTest);
    Rti._setAsCheckFunction(rti, asFn);
    Rti._setTypeCheckFunction(rti, checkFn);
    Rti._setIsTestFunction(rti, isFn);
    return rti;
  }

  static Rti _installRti(Object universe, String key, Rti rti) {
    _cacheSet(evalCache(universe), key, rti);
    return rti;
  }

  // For each kind of Rti there are three methods:
  //
  // * `lookupXXX` which takes the component parts and returns an existing Rti
  //   object if it exists.
  // * `canonicalRecipeOfXXX` that returns the compositional canonical recipe
  //   for the proposed type.
  // * `createXXX` to create the type if it does not exist.
  //
  // The create method performs normalization before allocating a new Rti. Cache
  // keys are not normalized, so if multiple recipes normalize to the same type,
  // then their corresponding cache entries will point to the same value. This
  // prevents us from having to normalize on every lookup instead of every
  // allocation.

  static String _canonicalRecipeOfErased() => Recipe.pushErasedString;
  static String _canonicalRecipeOfDynamic() => Recipe.pushDynamicString;
  static String _canonicalRecipeOfVoid() => Recipe.pushVoidString;
  static String _canonicalRecipeOfNever() =>
      Recipe.pushNeverExtensionString + Recipe.extensionOpString;
  static String _canonicalRecipeOfAny() =>
      Recipe.pushAnyExtensionString + Recipe.extensionOpString;

  static String _canonicalRecipeOfStar(Rti baseType) =>
      Rti._getCanonicalRecipe(baseType) + Recipe.wrapStarString;
  static String _canonicalRecipeOfQuestion(Rti baseType) =>
      Rti._getCanonicalRecipe(baseType) + Recipe.wrapQuestionString;
  static String _canonicalRecipeOfFutureOr(Rti baseType) =>
      Rti._getCanonicalRecipe(baseType) + Recipe.wrapFutureOrString;

  static String _canonicalRecipeOfGenericFunctionParameter(int index) =>
      '$index' + Recipe.genericFunctionTypeParameterIndexString;

  static Rti _lookupErasedRti(universe) {
    return _lookupTerminalRti(
        universe, Rti.kindErased, _canonicalRecipeOfErased());
  }

  static Rti _lookupDynamicRti(universe) {
    return _lookupTerminalRti(
        universe, Rti.kindDynamic, _canonicalRecipeOfDynamic());
  }

  static Rti _lookupVoidRti(universe) {
    return _lookupTerminalRti(universe, Rti.kindVoid, _canonicalRecipeOfVoid());
  }

  static Rti _lookupNeverRti(universe) {
    return _lookupTerminalRti(
        universe, Rti.kindNever, _canonicalRecipeOfNever());
  }

  static Rti _lookupAnyRti(universe) {
    return _lookupTerminalRti(universe, Rti.kindAny, _canonicalRecipeOfAny());
  }

  static Rti _lookupTerminalRti(universe, int kind, String key) {
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(universe, key, _createTerminalRti(universe, kind, key));
  }

  static Rti _createTerminalRti(universe, int kind, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, kind);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static Rti _lookupStarRti(universe, Rti baseType, bool normalize) {
    String key = _canonicalRecipeOfStar(baseType);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(
        universe, key, _createStarRti(universe, baseType, key, normalize));
  }

  static Rti _createStarRti(
      universe, Rti baseType, String key, bool normalize) {
    if (normalize) {
      int baseKind = Rti._getKind(baseType);
      if (isTopType(baseType) ||
          isNullType(baseType) ||
          baseKind == Rti.kindQuestion ||
          baseKind == Rti.kindStar) {
        return baseType;
      }
    }
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindStar);
    Rti._setPrimary(rti, baseType);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static Rti _lookupQuestionRti(universe, Rti baseType, bool normalize) {
    String key = _canonicalRecipeOfQuestion(baseType);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(
        universe, key, _createQuestionRti(universe, baseType, key, normalize));
  }

  static Rti _createQuestionRti(
      universe, Rti baseType, String key, bool normalize) {
    if (normalize) {
      int baseKind = Rti._getKind(baseType);
      if (isStrongTopType(baseType) ||
          isNullType(baseType) ||
          baseKind == Rti.kindQuestion ||
          baseKind == Rti.kindFutureOr &&
              isNullable(Rti._getFutureOrArgument(baseType))) {
        return baseType;
      } else if (baseKind == Rti.kindNever) {
        return TYPE_REF<Null>();
      } else if (baseKind == Rti.kindStar) {
        Rti starArgument = Rti._getStarArgument(baseType);
        int starArgumentKind = Rti._getKind(starArgument);
        if (starArgumentKind == Rti.kindNever) {
          return TYPE_REF<Null>();
        } else if (starArgumentKind == Rti.kindFutureOr &&
            isNullable(Rti._getFutureOrArgument(starArgument))) {
          return starArgument;
        } else {
          return Rti._getQuestionFromStar(universe, baseType);
        }
      }
    }
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindQuestion);
    Rti._setPrimary(rti, baseType);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static Rti _lookupFutureOrRti(universe, Rti baseType, bool normalize) {
    String key = _canonicalRecipeOfFutureOr(baseType);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(
        universe, key, _createFutureOrRti(universe, baseType, key, normalize));
  }

  static Rti _createFutureOrRti(
      universe, Rti baseType, String key, bool normalize) {
    if (normalize) {
      int baseKind = Rti._getKind(baseType);
      if (isTopType(baseType) || isObjectType(baseType)) {
        return baseType;
      } else if (baseKind == Rti.kindNever) {
        return _lookupFutureRti(universe, baseType);
      } else if (isNullType(baseType)) {
        return JS_GET_FLAG('NNBD')
            ? _lookupQuestionRti(universe, TYPE_REF<Future<Null>>(), false)
            : TYPE_REF<Future<Null>>();
      }
    }
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindFutureOr);
    Rti._setPrimary(rti, baseType);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static Rti _lookupGenericFunctionParameterRti(universe, int index) {
    String key = _canonicalRecipeOfGenericFunctionParameter(index);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(universe, key,
        _createGenericFunctionParameterRti(universe, index, key));
  }

  static Rti _createGenericFunctionParameterRti(
      universe, int index, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindGenericFunctionParameter);
    Rti._setPrimary(rti, index);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static String _canonicalRecipeJoin(Object arguments) {
    String s = '', sep = '';
    int length = _Utils.arrayLength(arguments);
    for (int i = 0; i < length; i++) {
      Rti argument = _castToRti(_Utils.arrayAt(arguments, i));
      String subrecipe = Rti._getCanonicalRecipe(argument);
      s += sep + subrecipe;
      sep = Recipe.separatorString;
    }
    return s;
  }

  static String _canonicalRecipeJoinNamed(Object arguments) {
    String s = '', sep = '';
    int length = _Utils.arrayLength(arguments);
    assert(length.isEven);
    for (int i = 0; i < length; i += 2) {
      String name = _Utils.asString(_Utils.arrayAt(arguments, i));
      Rti type = _castToRti(_Utils.arrayAt(arguments, i + 1));
      String subrecipe = Rti._getCanonicalRecipe(type);
      s += sep + name + Recipe.nameSeparatorString + subrecipe;
      sep = Recipe.separatorString;
    }
    return s;
  }

  static String _canonicalRecipeOfInterface(String name, Object arguments) {
    assert(_Utils.isString(name));
    String s = _Utils.asString(name);
    int length = _Utils.arrayLength(arguments);
    if (length != 0) {
      s += Recipe.startTypeArgumentsString +
          _canonicalRecipeJoin(arguments) +
          Recipe.endTypeArgumentsString;
    }
    return s;
  }

  static Rti _lookupInterfaceRti(
      Object universe, String name, Object arguments) {
    String key = _canonicalRecipeOfInterface(name, arguments);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(
        universe, key, _createInterfaceRti(universe, name, arguments, key));
  }

  static Rti _createInterfaceRti(
      Object universe, String name, Object typeArguments, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindInterface);
    Rti._setPrimary(rti, name);
    Rti._setRest(rti, typeArguments);
    int length = _Utils.arrayLength(typeArguments);
    if (length > 0) {
      Rti._setPrecomputed1(rti, _Utils.arrayAt(typeArguments, 0));
    }
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static Rti _lookupFutureRti(Object universe, Rti base) => _lookupInterfaceRti(
      universe,
      JS_GET_NAME(JsGetName.FUTURE_CLASS_TYPE_NAME),
      JS('', '[#]', base));

  static String _canonicalRecipeOfBinding(Rti base, Object arguments) {
    String s = Rti._getCanonicalRecipe(base);
    s += Recipe
        .toTypeString; // TODO(sra): Omit when base encoding is Rti without ToType.
    s += Recipe.startTypeArgumentsString +
        _canonicalRecipeJoin(arguments) +
        Recipe.endTypeArgumentsString;
    return s;
  }

  /// [arguments] becomes owned by the created Rti.
  static Rti _lookupBindingRti(Object universe, Rti base, Object arguments) {
    Rti newBase = base;
    Object newArguments = arguments;
    if (Rti._getKind(base) == Rti.kindBinding) {
      newBase = Rti._getBindingBase(base);
      newArguments =
          _Utils.arrayConcat(Rti._getBindingArguments(base), arguments);
    }
    String key = _canonicalRecipeOfBinding(newBase, newArguments);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(
        universe, key, _createBindingRti(universe, newBase, newArguments, key));
  }

  static Rti _createBindingRti(
      Object universe, Rti base, Object arguments, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindBinding);
    Rti._setPrimary(rti, base);
    Rti._setRest(rti, arguments);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static String _canonicalRecipeOfFunction(
          Rti returnType, _FunctionParameters parameters) =>
      Rti._getCanonicalRecipe(returnType) +
      _canonicalRecipeOfFunctionParameters(parameters);

  // TODO(fishythefish): Support required named parameters.
  static String _canonicalRecipeOfFunctionParameters(
      _FunctionParameters parameters) {
    var requiredPositional =
        _FunctionParameters._getRequiredPositional(parameters);
    int requiredPositionalLength = _Utils.arrayLength(requiredPositional);
    var optionalPositional =
        _FunctionParameters._getOptionalPositional(parameters);
    int optionalPositionalLength = _Utils.arrayLength(optionalPositional);
    var optionalNamed = _FunctionParameters._getOptionalNamed(parameters);
    int optionalNamedLength = _Utils.arrayLength(optionalNamed);
    assert(optionalPositionalLength == 0 || optionalNamedLength == 0);

    String recipe = Recipe.startFunctionArgumentsString +
        _canonicalRecipeJoin(requiredPositional);

    if (optionalPositionalLength > 0) {
      String sep = requiredPositionalLength > 0 ? Recipe.separatorString : '';
      recipe += sep +
          Recipe.startOptionalGroupString +
          _canonicalRecipeJoin(optionalPositional) +
          Recipe.endOptionalGroupString;
    }

    if (optionalNamedLength > 0) {
      String sep = requiredPositionalLength > 0 ? Recipe.separatorString : '';
      recipe += sep +
          Recipe.startNamedGroupString +
          _canonicalRecipeJoinNamed(optionalNamed) +
          Recipe.endNamedGroupString;
    }

    return recipe + Recipe.endFunctionArgumentsString;
  }

  static Rti _lookupFunctionRti(
      Object universe, Rti returnType, _FunctionParameters parameters) {
    String key = _canonicalRecipeOfFunction(returnType, parameters);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(universe, key,
        _createFunctionRti(universe, returnType, parameters, key));
  }

  static Rti _createFunctionRti(Object universe, Rti returnType,
      _FunctionParameters parameters, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindFunction);
    Rti._setPrimary(rti, returnType);
    Rti._setRest(rti, parameters);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }

  static String _canonicalRecipeOfGenericFunction(
          Rti baseFunctionType, Object bounds) =>
      Rti._getCanonicalRecipe(baseFunctionType) +
      Recipe.startTypeArgumentsString +
      _canonicalRecipeJoin(bounds) +
      Recipe.endTypeArgumentsString;

  // TODO(fishythefish): Normalize `X extends Never` to `Never`.
  static Rti _lookupGenericFunctionRti(
      Object universe, Rti baseFunctionType, Object bounds) {
    String key = _canonicalRecipeOfGenericFunction(baseFunctionType, bounds);
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, key);
    if (probe != null) return _castToRti(probe);
    return _installRti(universe, key,
        _createGenericFunctionRti(universe, baseFunctionType, bounds, key));
  }

  static Rti _createGenericFunctionRti(
      Object universe, Rti baseFunctionType, Object bounds, String key) {
    Rti rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindGenericFunction);
    Rti._setPrimary(rti, baseFunctionType);
    Rti._setRest(rti, bounds);
    Rti._setCanonicalRecipe(rti, key);
    return _installTypeTests(universe, rti);
  }
}

/// Class of static methods implementing recipe parser.
///
/// The recipe is a sequence of operations on a stack machine. The operations
/// are described below using the format
///
///      operation: stack elements before --- stack elements after
///
/// integer:  --- integer-value
///
/// identifier:  --- string-value
///
/// identifier-with-one-period:  --- type-variable-value
///
///   Period may be in any position, including first and last e.g. `.x`.
///
/// ',':  ---
///
///   Ignored. Used to separate elements.
///
/// ';': item  ---  ToType(item)
///
///   Used to separate elements.
///
/// '#': --- erasedType
///
/// '@': --- dynamicType
///
/// '~': --- voidType
///
/// '?':  type  ---  type?
///
/// '&':  0  ---  NeverType
/// '&':  1  ---  anyType
///
///   Escape op-code with small integer values for encoding rare operations.
///
/// '<':  --- position
///
///   Saves (pushes) position register, sets position register to end of stack.
///
/// '>':  name saved-position type ... type  ---  name<type, ..., type>
/// '>':  type saved-position type ... type  ---  binding(type, type, ..., type)
///
///   When first element is a String: Creates interface type from string 'name'
///   and the types pushed since the position register was last set. The types
///   are converted with a ToType operation. Restores position register to
///   previous saved value.
///
///   When first element is an Rti: Creates binding Rti wrapping the first
///   element. Binding Rtis are flattened: if the first element is a binding
///   Rti, the new binding Rti has the concatentation of the first element
///   bindings and new type.
///
///
/// The ToType operation coerces an item to an Rti. This saves encoding looking
/// up simple interface names and indexed variables.
///
///   ToType(string): Creates an interface Rti for the non-generic class.
///   ToType(integer): Indexes into the environment.
///   ToType(Rti): Same Rti
///
///
/// Notes on enviroments and indexing.
///
/// To avoid creating a binding Rti for a single function type parameter, the
/// type is passed without creating a 1-tuple object. This means that the
/// interface Rti for, say, `Map<num,dynamic>` serves as two environments with
/// different shapes. It is a class environment (K=num, V=dynamic) and a simple
/// 1-tuple environment. This is supported by index '0' refering to the whole
/// type, and '1 and '2' refering to K and V positionally:
///
///     interface("Map", [num,dynamic])
///     0                 1   2
///
/// Thus the type expression `List<K>` encodes as `List<1>` and in this
/// environment evaluates to `List<num>`. `List<Map<K,V>>` could be encoded as
/// either `List<0>` or `List<Map<1,2>>` (and in this environment evaluates to
/// `List<Map<num,dynamic>>`).
///
/// When `Map<num,dynamic>` is combined with a binding `<int,bool>` (e.g. inside
/// the instance method `Map<K,V>.cast<RK,RV>()`), '0' refers to the base object
/// of the binding, and then the numbering counts the bindings followed by the
/// class parameters.
///
///     binding(interface("Map", [num,dynamic]), [int, bool])
///             0                 3   4           1    2
///
/// Any environment can be reconstructed via a recipe. The above enviroment for
/// method `cast` can be constructed as the ground term
/// `Map<num,dynamic><int,bool>`, or (somewhat pointlessly) reconstructed via
/// `0<1,2>` or `Map<3,4><1,2>`. The ability to construct an environment
/// directly rather than via `bind` calls is used in folding sequences of `eval`
/// and `bind` calls.
///
/// While a single type parameter is passed as the type, multiple type
/// parameters are passed as a tuple. Tuples are encoded as a binding with an
/// ignored base. `dynamic` can be used as the base, giving an encoding like
/// `@<int,bool>`.
///
/// Bindings flatten, so `@<int><bool><num>` is the same as `@<int,bool,num>`.
///
/// The base of a binding does not have to have type parameters. Consider
/// `CodeUnits`, which mixes in `ListMixin<int>`. The environment inside of
/// `ListMixin.fold` (from the call `x.codeUnits.fold<bool>(...)`) would be
///
///     binding(interface("CodeUnits", []), [bool])
///
/// This can be encoded as `CodeUnits;<bool>` (note the `;` to force ToType to
/// avoid creating an interface type Rti with a single class type
/// argument). Metadata about the supertypes is used to resolve the recipe
/// `ListMixin.E` to `int`.

class _Parser {
  _Parser._() {
    throw UnimplementedError('_Parser is static methods only');
  }

  /// Creates a parser object for parsing a recipe against an environment in a
  /// universe.
  ///
  /// Marked as no-inline so the object literal is not cloned by inlining.
  @pragma('dart2js:noInline')
  static Object create(
      Object universe, Object environment, String recipe, bool normalize) {
    return JS(
        '',
        '{'
            'u:#,' // universe
            'e:#,' // environment
            'r:#,' // recipe
            's:[],' // stack
            'p:0,' // position of sequence start
            'n:#,' // whether to normalize
            '}',
        universe,
        environment,
        recipe,
        normalize);
  }

  // Field accessors for the parser.
  static Object universe(Object parser) => JS('', '#.u', parser);
  static Rti environment(Object parser) => JS('Rti', '#.e', parser);
  static String recipe(Object parser) => JS('String', '#.r', parser);
  static Object stack(Object parser) => JS('', '#.s', parser);
  static int position(Object parser) => JS('int', '#.p', parser);
  static void setPosition(Object parser, int p) {
    JS('', '#.p = #', parser, p);
  }

  static bool normalize(Object parser) => JS('bool', '#.n', parser);

  static int charCodeAt(String s, int i) => JS('int', '#.charCodeAt(#)', s, i);
  static void push(Object stack, Object value) {
    JS('', '#.push(#)', stack, value);
  }

  static Object pop(Object stack) => JS('', '#.pop()', stack);

  static Rti parse(Object parser) {
    String source = _Parser.recipe(parser);
    Object stack = _Parser.stack(parser);
    int i = 0;
    while (i < source.length) {
      int ch = charCodeAt(source, i);
      if (Recipe.isDigit(ch)) {
        i = handleDigit(i + 1, ch, source, stack);
      } else if (Recipe.isIdentifierStart(ch)) {
        i = handleIdentifier(parser, i, source, stack, false);
      } else if (ch == Recipe.period) {
        i = handleIdentifier(parser, i, source, stack, true);
      } else {
        i++;
        switch (ch) {
          case Recipe.separator:
            break;

          case Recipe.nameSeparator:
            break;

          case Recipe.toType:
            push(stack,
                toType(universe(parser), environment(parser), pop(stack)));
            break;

          case Recipe.genericFunctionTypeParameterIndex:
            push(stack,
                toGenericFunctionParameter(universe(parser), pop(stack)));
            break;

          case Recipe.pushErased:
            push(stack, _Universe._lookupErasedRti(universe(parser)));
            break;

          case Recipe.pushDynamic:
            push(stack, _Universe._lookupDynamicRti(universe(parser)));
            break;

          case Recipe.pushVoid:
            push(stack, _Universe._lookupVoidRti(universe(parser)));
            break;

          case Recipe.startTypeArguments:
            pushStackFrame(parser, stack);
            break;

          case Recipe.endTypeArguments:
            handleTypeArguments(parser, stack);
            break;

          case Recipe.extensionOp:
            handleExtendedOperations(parser, stack);
            break;

          case Recipe.wrapStar:
            Object u = universe(parser);
            push(
                stack,
                _Universe._lookupStarRti(
                    u,
                    toType(u, environment(parser), pop(stack)),
                    normalize(parser)));
            break;

          case Recipe.wrapQuestion:
            Object u = universe(parser);
            push(
                stack,
                _Universe._lookupQuestionRti(
                    u,
                    toType(u, environment(parser), pop(stack)),
                    normalize(parser)));
            break;

          case Recipe.wrapFutureOr:
            Object u = universe(parser);
            push(
                stack,
                _Universe._lookupFutureOrRti(
                    u,
                    toType(u, environment(parser), pop(stack)),
                    normalize(parser)));
            break;

          case Recipe.startFunctionArguments:
            pushStackFrame(parser, stack);
            break;

          case Recipe.endFunctionArguments:
            handleFunctionArguments(parser, stack);
            break;

          case Recipe.startOptionalGroup:
            pushStackFrame(parser, stack);
            break;

          case Recipe.endOptionalGroup:
            handleOptionalGroup(parser, stack);
            break;

          case Recipe.startNamedGroup:
            pushStackFrame(parser, stack);
            break;

          case Recipe.endNamedGroup:
            handleNamedGroup(parser, stack);
            break;

          default:
            JS('', 'throw "Bad character " + #', ch);
        }
      }
    }
    Object item = pop(stack);
    return toType(universe(parser), environment(parser), item);
  }

  static void pushStackFrame(Object parser, Object stack) {
    push(stack, position(parser));
    setPosition(parser, _Utils.arrayLength(stack));
  }

  static int handleDigit(int i, int digit, String source, Object stack) {
    int value = Recipe.digitValue(digit);
    for (; i < source.length; i++) {
      int ch = charCodeAt(source, i);
      if (!Recipe.isDigit(ch)) break;
      value = value * 10 + Recipe.digitValue(ch);
    }
    push(stack, value);
    return i;
  }

  static int handleIdentifier(
      Object parser, int start, String source, Object stack, bool hasPeriod) {
    int i = start + 1;
    for (; i < source.length; i++) {
      int ch = charCodeAt(source, i);
      if (ch == Recipe.period) {
        if (hasPeriod) break;
        hasPeriod = true;
      } else if (Recipe.isIdentifierStart(ch) || Recipe.isDigit(ch)) {
        // Accept.
      } else {
        break;
      }
    }
    String string = _Utils.substring(source, start, i);
    if (hasPeriod) {
      push(
          stack,
          _Universe.evalTypeVariable(
              universe(parser), environment(parser), string));
    } else {
      push(stack, string);
    }
    return i;
  }

  static void handleTypeArguments(Object parser, Object stack) {
    Object universe = _Parser.universe(parser);
    Object arguments = collectArray(parser, stack);
    Object head = pop(stack);
    if (_Utils.isString(head)) {
      String name = _Utils.asString(head);
      push(stack, _Universe._lookupInterfaceRti(universe, name, arguments));
    } else {
      Rti base = toType(universe, environment(parser), head);
      switch (Rti._getKind(base)) {
        case Rti.kindFunction:
          push(stack,
              _Universe._lookupGenericFunctionRti(universe, base, arguments));
          break;

        default:
          push(stack, _Universe._lookupBindingRti(universe, base, arguments));
          break;
      }
    }
  }

  static const int optionalPositionalSentinel = -1;
  static const int optionalNamedSentinel = -2;

  static void handleFunctionArguments(Object parser, Object stack) {
    Object universe = _Parser.universe(parser);
    _FunctionParameters parameters = _FunctionParameters.allocate();
    var optionalPositional = _Universe.sharedEmptyArray(universe);
    var optionalNamed = _Universe.sharedEmptyArray(universe);

    Object head = pop(stack);
    if (_Utils.isNum(head)) {
      int sentinel = _Utils.asInt(head);
      switch (sentinel) {
        case optionalPositionalSentinel:
          optionalPositional = pop(stack);
          break;

        case optionalNamedSentinel:
          optionalNamed = pop(stack);
          break;

        default:
          push(stack, head);
          break;
      }
    } else {
      push(stack, head);
    }

    _FunctionParameters._setRequiredPositional(
        parameters, collectArray(parser, stack));
    _FunctionParameters._setOptionalPositional(parameters, optionalPositional);
    _FunctionParameters._setOptionalNamed(parameters, optionalNamed);
    Rti returnType = toType(universe, environment(parser), pop(stack));
    push(stack, _Universe._lookupFunctionRti(universe, returnType, parameters));
  }

  static void handleOptionalGroup(Object parser, Object stack) {
    Object parameters = collectArray(parser, stack);
    push(stack, parameters);
    push(stack, optionalPositionalSentinel);
  }

  static void handleNamedGroup(Object parser, Object stack) {
    Object parameters = collectNamed(parser, stack);
    push(stack, parameters);
    push(stack, optionalNamedSentinel);
  }

  static void handleExtendedOperations(Object parser, Object stack) {
    Object top = pop(stack);
    if (0 == top) {
      push(stack, _Universe._lookupNeverRti(universe(parser)));
      return;
    }
    if (1 == top) {
      push(stack, _Universe._lookupAnyRti(universe(parser)));
      return;
    }
    throw AssertionError('Unexpected extended operation $top');
  }

  static Object collectArray(Object parser, Object stack) {
    var array = _Utils.arraySplice(stack, position(parser));
    toTypes(_Parser.universe(parser), environment(parser), array);
    setPosition(parser, _Utils.asInt(pop(stack)));
    return array;
  }

  static Object collectNamed(Object parser, Object stack) {
    var array = _Utils.arraySplice(stack, position(parser));
    toTypesNamed(_Parser.universe(parser), environment(parser), array);
    setPosition(parser, _Utils.asInt(pop(stack)));
    return array;
  }

  /// Coerce a stack item into an Rti object. Strings are converted to interface
  /// types, integers are looked up in the type environment.
  static Rti toType(Object universe, Rti environment, Object item) {
    if (_Utils.isString(item)) {
      String name = _Utils.asString(item);
      return _Universe._lookupInterfaceRti(
          universe, name, _Universe.sharedEmptyArray(universe));
    } else if (_Utils.isNum(item)) {
      return _Parser.indexToType(universe, environment, _Utils.asInt(item));
    } else {
      return _castToRti(item);
    }
  }

  static void toTypes(Object universe, Rti environment, Object items) {
    int length = _Utils.arrayLength(items);
    for (int i = 0; i < length; i++) {
      var item = _Utils.arrayAt(items, i);
      Rti type = toType(universe, environment, item);
      _Utils.arraySetAt(items, i, type);
    }
  }

  static void toTypesNamed(Object universe, Rti environment, Object items) {
    int length = _Utils.arrayLength(items);
    assert(length.isEven);
    for (int i = 1; i < length; i += 2) {
      var item = _Utils.arrayAt(items, i);
      Rti type = toType(universe, environment, item);
      _Utils.arraySetAt(items, i, type);
    }
  }

  static Rti indexToType(Object universe, Rti environment, int index) {
    int kind = Rti._getKind(environment);
    if (kind == Rti.kindBinding) {
      if (index == 0) return Rti._getBindingBase(environment);
      var typeArguments = Rti._getBindingArguments(environment);
      int len = _Utils.arrayLength(typeArguments);
      if (index <= len) {
        return _castToRti(_Utils.arrayAt(typeArguments, index - 1));
      }
      // Is index into interface Rti in base.
      index -= len;
      environment = Rti._getBindingBase(environment);
      kind = Rti._getKind(environment);
    } else {
      if (index == 0) return environment;
    }
    if (kind != Rti.kindInterface) {
      throw AssertionError('Indexed base must be an interface type');
    }
    var typeArguments = Rti._getInterfaceTypeArguments(environment);
    int len = _Utils.arrayLength(typeArguments);
    if (index <= len) {
      return _castToRti(_Utils.arrayAt(typeArguments, index - 1));
    }
    throw AssertionError('Bad index $index for $environment');
  }

  static Rti toGenericFunctionParameter(Object universe, Object item) {
    assert(_Utils.isNum(item));
    return _Universe._lookupGenericFunctionParameterRti(
        universe, _Utils.asInt(item));
  }
}

/// Represents the set of supertypes and type variable bindings for a given
/// target type. The target type itself is not stored on the [TypeRule].
class TypeRule {
  TypeRule._() {
    throw UnimplementedError("TypeRule is static methods only.");
  }

  static String lookupTypeVariable(rule, String typeVariable) =>
      JS('', '#.#', rule, typeVariable);

  static JSArray lookupSupertype(rule, String supertype) =>
      JS('', '#.#', rule, supertype);
}

// This needs to be kept in sync with `Variance` in `entities.dart`.
class Variance {
  // TODO(fishythefish): Try bitmask representation.
  static const legacyCovariant = 0;
  static const covariant = 1;
  static const contravariant = 2;
  static const invariant = 3;
}

// -------- Subtype tests ------------------------------------------------------

// Future entry point from compiled code.
bool isSubtype(universe, Rti s, Rti t) {
  return _isSubtype(universe, s, null, t, null);
}

/// Based on
/// https://github.com/dart-lang/language/blob/master/resources/type-system/subtyping.md#rules
/// and https://github.com/dart-lang/language/pull/388.
/// In particular, the bulk of the structure is derived from the former
/// resource, with a few adaptations taken from the latter.
/// - We freely skip subcases which would have already been handled by a
/// previous case.
/// - Some rules are reordered in conjunction with the previous point to reduce
/// the amount of casework.
/// - Left Type Variable Bound in particular is split into two pieces: an
/// optimistic check performed early in the algorithm to reduce the number of
/// backtracking cases when a union appears on the right, and a pessimistic
/// check performed at the usual place in order to completely eliminate the
/// case.
/// - Function type rules are applied before interface type rules.
///
/// [s] is considered a legacy subtype of [t] if [s] would be a subtype of [t]
/// in a modification of the NNBD rules in which `?` on types were ignored, `*`
/// were added to each time, and `required` parameters were treated as
/// optional. In effect, `Never` is equivalent to `Null`, `Null` is restored to
/// the bottom of the type hierarchy, `Object` is treated as nullable, and
/// `required` is ignored on named parameters. This should provide the same
/// subtyping results as pre-NNBD Dart.
bool _isSubtype(universe, Rti s, sEnv, Rti t, tEnv) {
  bool isLegacy = JS_GET_FLAG('LEGACY');

  // Reflexivity:
  if (_Utils.isIdentical(s, t)) return true;

  // Right Top:
  if (isTopType(t)) return true;

  int sKind = Rti._getKind(s);
  if (sKind == Rti.kindAny) return true;

  // Left Top:
  if (isStrongTopType(s)) return false;

  // Left Bottom:
  if (isLegacy) {
    if (isNullType(s)) return true;
  } else {
    if (sKind == Rti.kindNever) return true;
  }

  // Left Type Variable Bound 1:
  bool leftTypeVariable = sKind == Rti.kindGenericFunctionParameter;
  if (leftTypeVariable) {
    int index = Rti._getGenericFunctionParameterIndex(s);
    Rti bound = _castToRti(_Utils.arrayAt(sEnv, index));
    if (_isSubtype(universe, bound, sEnv, t, tEnv)) return true;
  }

  int tKind = Rti._getKind(t);

  // Left Null:
  // Note: Interchanging the Left Null and Right Object rules allows us to
  // reduce casework.
  if (!isLegacy && isNullType(s)) {
    if (tKind == Rti.kindFutureOr) {
      return _isSubtype(universe, s, sEnv, Rti._getFutureOrArgument(t), tEnv);
    }
    return isNullType(t) || tKind == Rti.kindQuestion || tKind == Rti.kindStar;
  }

  // Right Object:
  if (!isLegacy && isObjectType(t)) {
    if (sKind == Rti.kindFutureOr) {
      return _isSubtype(universe, Rti._getFutureOrArgument(s), sEnv, t, tEnv);
    }
    if (sKind == Rti.kindStar) {
      return _isSubtype(universe, Rti._getStarArgument(s), sEnv, t, tEnv);
    }
    return sKind != Rti.kindQuestion;
  }

  // Left Legacy:
  if (sKind == Rti.kindStar) {
    return _isSubtype(universe, Rti._getStarArgument(s), sEnv, t, tEnv);
  }

  // Right Legacy:
  if (tKind == Rti.kindStar) {
    return _isSubtype(
        universe,
        s,
        sEnv,
        isLegacy
            ? Rti._getStarArgument(t)
            : Rti._getQuestionFromStar(universe, t),
        tEnv);
  }

  // Left FutureOr:
  if (sKind == Rti.kindFutureOr) {
    if (!_isSubtype(universe, Rti._getFutureOrArgument(s), sEnv, t, tEnv)) {
      return false;
    }
    return _isSubtype(
        universe, Rti._getFutureFromFutureOr(universe, s), sEnv, t, tEnv);
  }

  // Left Nullable:
  if (sKind == Rti.kindQuestion) {
    return (isLegacy ||
            _isSubtype(universe, TYPE_REF<Null>(), sEnv, t, tEnv)) &&
        _isSubtype(universe, Rti._getQuestionArgument(s), sEnv, t, tEnv);
  }

  // Type Variable Reflexivity 1 is subsumed by Reflexivity and therefore
  // elided.
  // Type Variable Reflexivity 2 does not apply at runtime.
  // Right Promoted Variable does not apply at runtime.

  // Right FutureOr:
  if (tKind == Rti.kindFutureOr) {
    if (_isSubtype(universe, s, sEnv, Rti._getFutureOrArgument(t), tEnv)) {
      return true;
    }
    return _isSubtype(
        universe, s, sEnv, Rti._getFutureFromFutureOr(universe, t), tEnv);
  }

  // Right Nullable:
  if (tKind == Rti.kindQuestion) {
    return (!isLegacy &&
            _isSubtype(universe, s, sEnv, TYPE_REF<Null>(), tEnv)) ||
        _isSubtype(universe, s, sEnv, Rti._getQuestionArgument(t), tEnv);
  }

  // Left Promoted Variable does not apply at runtime.

  // Left Type Variable Bound 2:
  if (leftTypeVariable) return false;

  // Function Type/Function:
  if ((sKind == Rti.kindFunction || sKind == Rti.kindGenericFunction) &&
      isFunctionType(t)) {
    return true;
  }

  // Positional Function Types + Named Function Types:
  // TODO(fishythefish): Disallow JavaScriptFunction as a subtype of function
  // types using features inaccessible from JavaScript.
  if (tKind == Rti.kindGenericFunction) {
    if (isJsFunctionType(s)) return true;
    if (sKind != Rti.kindGenericFunction) return false;

    var sBounds = Rti._getGenericFunctionBounds(s);
    var tBounds = Rti._getGenericFunctionBounds(t);
    int sLength = _Utils.arrayLength(sBounds);
    int tLength = _Utils.arrayLength(tBounds);
    if (sLength != tLength) return false;

    sEnv = sEnv == null ? sBounds : _Utils.arrayConcat(sBounds, sEnv);
    tEnv = tEnv == null ? tBounds : _Utils.arrayConcat(tBounds, tEnv);

    for (int i = 0; i < sLength; i++) {
      var sBound = _Utils.arrayAt(sBounds, i);
      var tBound = _Utils.arrayAt(tBounds, i);
      if (!_isSubtype(universe, sBound, sEnv, tBound, tEnv) ||
          !_isSubtype(universe, tBound, tEnv, sBound, sEnv)) {
        return false;
      }
    }

    return _isFunctionSubtype(universe, Rti._getGenericFunctionBase(s), sEnv,
        Rti._getGenericFunctionBase(t), tEnv);
  }
  if (tKind == Rti.kindFunction) {
    if (isJsFunctionType(s)) return true;
    if (sKind != Rti.kindFunction) return false;
    return _isFunctionSubtype(universe, s, sEnv, t, tEnv);
  }

  // Interface Compositionality + Super-Interface:
  if (sKind == Rti.kindInterface) {
    if (tKind != Rti.kindInterface) return false;
    return _isInterfaceSubtype(universe, s, sEnv, t, tEnv);
  }

  return false;
}

// TODO(fishythefish): Support required named parameters.
bool _isFunctionSubtype(universe, Rti s, sEnv, Rti t, tEnv) {
  assert(Rti._getKind(s) == Rti.kindFunction);
  assert(Rti._getKind(t) == Rti.kindFunction);

  Rti sReturnType = Rti._getReturnType(s);
  Rti tReturnType = Rti._getReturnType(t);
  if (!_isSubtype(universe, sReturnType, sEnv, tReturnType, tEnv)) {
    return false;
  }

  _FunctionParameters sParameters = Rti._getFunctionParameters(s);
  _FunctionParameters tParameters = Rti._getFunctionParameters(t);

  var sRequiredPositional =
      _FunctionParameters._getRequiredPositional(sParameters);
  var tRequiredPositional =
      _FunctionParameters._getRequiredPositional(tParameters);
  int sRequiredPositionalLength = _Utils.arrayLength(sRequiredPositional);
  int tRequiredPositionalLength = _Utils.arrayLength(tRequiredPositional);
  if (sRequiredPositionalLength > tRequiredPositionalLength) return false;
  int requiredPositionalDelta =
      tRequiredPositionalLength - sRequiredPositionalLength;

  var sOptionalPositional =
      _FunctionParameters._getOptionalPositional(sParameters);
  var tOptionalPositional =
      _FunctionParameters._getOptionalPositional(tParameters);
  int sOptionalPositionalLength = _Utils.arrayLength(sOptionalPositional);
  int tOptionalPositionalLength = _Utils.arrayLength(tOptionalPositional);
  if (sRequiredPositionalLength + sOptionalPositionalLength <
      tRequiredPositionalLength + tOptionalPositionalLength) return false;

  for (int i = 0; i < sRequiredPositionalLength; i++) {
    Rti sParameter = _castToRti(_Utils.arrayAt(sRequiredPositional, i));
    Rti tParameter = _castToRti(_Utils.arrayAt(tRequiredPositional, i));
    if (!_isSubtype(universe, tParameter, tEnv, sParameter, sEnv)) {
      return false;
    }
  }

  for (int i = 0; i < requiredPositionalDelta; i++) {
    Rti sParameter = _castToRti(_Utils.arrayAt(sOptionalPositional, i));
    Rti tParameter = _castToRti(
        _Utils.arrayAt(tRequiredPositional, sRequiredPositionalLength + i));
    if (!_isSubtype(universe, tParameter, tEnv, sParameter, sEnv)) {
      return false;
    }
  }

  for (int i = 0; i < tOptionalPositionalLength; i++) {
    Rti sParameter = _castToRti(
        _Utils.arrayAt(sOptionalPositional, requiredPositionalDelta + i));
    Rti tParameter = _castToRti(_Utils.arrayAt(tOptionalPositional, i));
    if (!_isSubtype(universe, tParameter, tEnv, sParameter, sEnv)) {
      return false;
    }
  }

  var sOptionalNamed = _FunctionParameters._getOptionalNamed(sParameters);
  var tOptionalNamed = _FunctionParameters._getOptionalNamed(tParameters);
  int sOptionalNamedLength = _Utils.arrayLength(sOptionalNamed);
  int tOptionalNamedLength = _Utils.arrayLength(tOptionalNamed);

  for (int i = 0, j = 0; j < tOptionalNamedLength; j += 2) {
    String sName;
    String tName = _Utils.asString(_Utils.arrayAt(tOptionalNamed, j));
    do {
      if (i >= sOptionalNamedLength) return false;
      sName = _Utils.asString(_Utils.arrayAt(sOptionalNamed, i));
      i += 2;
    } while (_Utils.stringLessThan(sName, tName));
    if (_Utils.stringLessThan(tName, sName)) return false;
    Rti sType = _castToRti(_Utils.arrayAt(sOptionalNamed, i - 1));
    Rti tType = _castToRti(_Utils.arrayAt(tOptionalNamed, j + 1));
    if (!_isSubtype(universe, tType, tEnv, sType, sEnv)) return false;
  }

  return true;
}

bool _isInterfaceSubtype(universe, Rti s, sEnv, Rti t, tEnv) {
  String sName = Rti._getInterfaceName(s);
  String tName = Rti._getInterfaceName(t);

  // Interface Compositionality:
  if (sName == tName) {
    var sArgs = Rti._getInterfaceTypeArguments(s);
    var tArgs = Rti._getInterfaceTypeArguments(t);
    int length = _Utils.arrayLength(sArgs);
    assert(length == _Utils.arrayLength(tArgs));

    var sVariances;
    bool hasVariances;
    if (JS_GET_FLAG("VARIANCE")) {
      sVariances = _Universe.findTypeParameterVariances(universe, sName);
      hasVariances = sVariances != null;
      assert(!hasVariances || length == _Utils.arrayLength(sVariances));
    }

    for (int i = 0; i < length; i++) {
      Rti sArg = _castToRti(_Utils.arrayAt(sArgs, i));
      Rti tArg = _castToRti(_Utils.arrayAt(tArgs, i));
      if (JS_GET_FLAG("VARIANCE")) {
        int sVariance = hasVariances
            ? _Utils.asInt(_Utils.arrayAt(sVariances, i))
            : Variance.legacyCovariant;
        switch (sVariance) {
          case Variance.legacyCovariant:
          case Variance.covariant:
            if (!_isSubtype(universe, sArg, sEnv, tArg, tEnv)) {
              return false;
            }
            break;
          case Variance.contravariant:
            if (!_isSubtype(universe, tArg, tEnv, sArg, sEnv)) {
              return false;
            }
            break;
          case Variance.invariant:
            if (!_isSubtype(universe, sArg, sEnv, tArg, tEnv) ||
                !_isSubtype(universe, tArg, tEnv, sArg, sEnv)) {
              return false;
            }
            break;
          default:
            throw StateError(
                "Unknown variance given for subtype check: $sVariance");
        }
      } else {
        if (!_isSubtype(universe, sArg, sEnv, tArg, tEnv)) {
          return false;
        }
      }
    }
    return true;
  }

  // The Super-Interface rule says that if [s] has superinterfaces C0,...,Cn,
  // then we need to check if for some i, Ci <: [t]. However, this requires us
  // to iterate over the superinterfaces. Instead, we can perform case
  // analysis on [t]. By this point, [t] can only be Never, a type variable,
  // or an interface type. (Bindings do not participate in subtype checks and
  // all other cases have been eliminated.) If [t] is not an interface, then
  // [s] </: [t]. Therefore, the only remaining case is that [t] is an
  // interface, so rather than iterating over the Ci, we can instead look up
  // [t] in our ruleset.
  // TODO(fishythefish): Handle variance correctly.
  Object rule = _Universe.findRule(universe, sName);
  if (rule == null) return false;
  var supertypeArgs = TypeRule.lookupSupertype(rule, tName);
  if (supertypeArgs == null) return false;
  int length = _Utils.arrayLength(supertypeArgs);
  var tArgs = Rti._getInterfaceTypeArguments(t);
  assert(length == _Utils.arrayLength(tArgs));
  for (int i = 0; i < length; i++) {
    String recipe = _Utils.asString(_Utils.arrayAt(supertypeArgs, i));
    Rti supertypeArg = _Universe.evalInEnvironment(universe, s, recipe);
    Rti tArg = _castToRti(_Utils.arrayAt(tArgs, i));
    if (!_isSubtype(universe, supertypeArg, sEnv, tArg, tEnv)) {
      return false;
    }
  }
  return true;
}

bool isNullable(Rti t) {
  int kind = Rti._getKind(t);
  return isNullType(t) ||
      isStrongTopType(t) ||
      kind == Rti.kindQuestion ||
      kind == Rti.kindStar && isNullable(Rti._getStarArgument(t)) ||
      kind == Rti.kindFutureOr && isNullable(Rti._getFutureOrArgument(t));
}

bool isTopType(Rti t) => isStrongTopType(t) || isLegacyObjectType(t);

bool isStrongTopType(Rti t) {
  int kind = Rti._getKind(t);
  return kind == Rti.kindDynamic ||
      kind == Rti.kindVoid ||
      kind == Rti.kindAny ||
      kind == Rti.kindErased ||
      !JS_GET_FLAG('NNBD') && isObjectType(t) ||
      isNullableObjectType(t);
}

bool isObjectType(Rti t) => _Utils.isIdentical(t, TYPE_REF<Object>());
bool isLegacyObjectType(Rti t) =>
    _Utils.isIdentical(t, LEGACY_TYPE_REF<Object>());
bool isNullableObjectType(Rti t) =>
    Rti._getKind(t) == Rti.kindQuestion &&
    isObjectType(Rti._getQuestionArgument(t));
bool isNullType(Rti t) => _Utils.isIdentical(t, TYPE_REF<Null>());
bool isFunctionType(Rti t) => _Utils.isIdentical(t, TYPE_REF<Function>());
bool isJsFunctionType(Rti t) =>
    _Utils.isIdentical(t, TYPE_REF<JavaScriptFunction>());

/// Unchecked cast to Rti.
Rti _castToRti(s) => JS('Rti', '#', s);
Rti /*?*/ _castToRtiOrNull(s) => JS('Rti|Null', '#', s);

class _Utils {
  static bool asBool(Object o) => JS('bool', '#', o);
  static double asDouble(Object o) => JS('double', '#', o);
  static int asInt(Object o) => JS('int', '#', o);
  static num asNum(Object o) => JS('num', '#', o);
  static String asString(Object o) => JS('String', '#', o);

  static bool isString(Object o) => JS('bool', 'typeof # == "string"', o);
  static bool isNum(Object o) => JS('bool', 'typeof # == "number"', o);

  static bool instanceOf(Object o, Object constructor) =>
      JS('bool', '# instanceof #', o, constructor);

  static bool isIdentical(s, t) => JS('bool', '# === #', s, t);
  static bool isNotIdentical(s, t) => JS('bool', '# !== #', s, t);

  static JSArray objectKeys(Object o) =>
      JS('returns:JSArray;new:true;', 'Object.keys(#)', o);

  static void objectAssign(Object o, Object other) {
    // TODO(fishythefish): Use `Object.assign()` when IE11 is deprecated.
    var keys = objectKeys(other);
    int length = arrayLength(keys);
    for (int i = 0; i < length; i++) {
      String key = asString(arrayAt(keys, i));
      JS('', '#[#] = #[#]', o, key, other, key);
    }
  }

  static bool isArray(Object o) => JS('bool', 'Array.isArray(#)', o);

  static int arrayLength(Object array) => JS('int', '#.length', array);

  static Object arrayAt(Object array, int i) => JS('', '#[#]', array, i);

  static void arraySetAt(Object array, int i, Object value) {
    JS('', '#[#] = #', array, i, value);
  }

  static JSArray arrayShallowCopy(Object array) =>
      JS('JSArray', '#.slice()', array);

  static JSArray arraySplice(Object array, int position) =>
      JS('JSArray', '#.splice(#)', array, position);

  static JSArray arrayConcat(Object a1, Object a2) =>
      JS('JSArray', '#.concat(#)', a1, a2);

  static void arrayPush(Object array, Object value) {
    JS('', '#.push(#)', array, value);
  }

  static String substring(String s, int start, int end) =>
      JS('String', '#.substring(#, #)', s, start, end);

  static bool stringLessThan(String s1, String s2) =>
      JS('bool', '# < #', s1, s2);

  static mapGet(cache, key) => JS('', '#.get(#)', cache, key);

  static void mapSet(cache, key, value) {
    JS('', '#.set(#, #)', cache, key, value);
  }
}
// -------- Entry points for testing -------------------------------------------

String testingCanonicalRecipe(rti) {
  return Rti._getCanonicalRecipe(rti);
}

String testingRtiToString(rti) {
  return _rtiToString(_castToRti(rti), null);
}

String testingRtiToDebugString(rti) {
  return _rtiToDebugString(_castToRti(rti));
}

Object testingCreateUniverse() {
  return _Universe.create();
}

void testingAddRules(universe, rules) {
  _Universe.addRules(universe, rules);
}

void testingAddTypeParameterVariances(universe, variances) {
  _Universe.addTypeParameterVariances(universe, variances);
}

bool testingIsSubtype(universe, rti1, rti2) {
  return isSubtype(universe, _castToRti(rti1), _castToRti(rti2));
}

Object testingUniverseEval(universe, String recipe) {
  return _Universe.eval(universe, recipe, true);
}

void testingUniverseEvalOverride(universe, String recipe, Rti rti) {
  var cache = _Universe.evalCache(universe);
  _Universe._cacheSet(cache, recipe, rti);
}

Object testingEnvironmentEval(universe, environment, String recipe) {
  return _Universe.evalInEnvironment(universe, _castToRti(environment), recipe);
}

Object testingEnvironmentBind(universe, environment, arguments) {
  return _Universe.bind(
      universe, _castToRti(environment), _castToRti(arguments));
}
