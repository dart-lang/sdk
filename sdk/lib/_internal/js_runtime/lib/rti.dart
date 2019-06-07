// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains support for runtime type information.
library rti;

import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JSArray, JSUnmodifiableArray;

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
  dynamic _as;

  /// JavaScript method for type check.  The method is called from generated
  /// code, e.g. parameter check for `T param` generates something like
  /// `rtiForT._check(param)`.
  dynamic _check;

  /// JavaScript method for 'is' test.  The method is called from generated
  /// code, e.g. `o is T` generates something like `rtiForT._is(o)`.
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

  /// Method called from generated code to evaluate a type environment recipe in
  /// `this` type environment.
  Rti _eval(String recipe) => _rtiEval(this, recipe);

  /// Method called from generated code to extend `this` type environment with a
  /// function type parameter.
  Rti _bind1(Rti type) => _rtiBind1(this, type);

  /// Method called from generated code to extend `this` type environment with a
  /// tuple of function type parameters.
  Rti _bind(Rti typeTuple) => _rtiBind(this, typeTuple);

  // Precomputed derived types. These fields are used to hold derived types that
  // are computed eagerly.
  // TODO(sra): Implement precomputed type optimizations.
  dynamic _precomputed1;
  dynamic _precomputed2;
  dynamic _precomputed3;
  dynamic _precomputed4;

  // The Type object corresponding to this Rti.
  Type _typeCache;

  /// The kind of Rti `this` is, one of the kindXXX constants below.
  ///
  /// We don't use an enum since we need to create Rti objects very early.
  ///
  /// The zero initializer ensures dart2js type analysis considers [_kind] is
  /// non-nullable.
  int _kind = 0;

  static int _getKind(Rti rti) => rti._kind;
  static void _setKind(Rti rti, int kind) {
    rti._kind = kind;
  }

  // Terminal terms.
  static const kindNever = 1;
  static const kindDynamic = 2;
  static const kindVoid = 3; // TODO(sra): Use `dynamic` instead?
  static const kindAny = 4; // Dart1-style 'dynamic' for JS-interop.
  // Unary terms.
  static const kindStar = 5;
  static const kindQuestion = 6;
  static const kindFutureOr = 7;
  // More complex terms.
  static const kindInterface = 8;
  // A vector of type parameters from enclosing functions and closures.
  static const kindBinding = 9;
  static const kindFunction = 10;
  static const kindGenericFunction = 11;

  /// Primary data associated with type.
  ///
  /// - Minified name of interface for interface types.
  /// - Underlying type for unary terms.
  /// - Class part of a type environment inside a generic class, or `null` for
  ///   type tuple.
  /// - Return type of function types.
  dynamic _primary;

  static _getPrimary(Rti rti) => rti._primary;

  /// Additional data associated with type.
  ///
  /// - The type arguments of an interface type.
  /// - The type arguments from enclosing functions and closures for a
  ///   kindBinding.
  /// - TBD for kindFunction and kindGenericFunction.
  dynamic _rest;

  static JSArray _getInterfaceTypeArguments(rti) {
    // The array is a plain JavaScript Array, otherwise we would need the type
    // `JSArray<Rti>` to exist before we could create the type `JSArray<Rti>`.
    assert(_getKind(rti) == kindInterface);
    return JS('JSUnmodifiableArray', '#', _getPrimary(rti));
  }

  /// On [Rti]s that are type environments, derived types are cached on the
  /// environment to ensure fast canonicalization. Ground-term types (i.e. not
  /// dependent on class or function type parameters) are cached in the
  /// universe. This field starts as `null` and the cache is created on demand.
  dynamic _evalCache;

  static Rti allocate() {
    return new Rti();
  }
}

Rti _rtiEval(Rti environment, String recipe) {
  throw UnimplementedError('_rtiEval');
}

Rti _rtiBind1(Rti environment, Rti type) {
  throw UnimplementedError('_rtiBind1');
}

Rti _rtiBind(Rti environment, Rti typeTuple) {
  throw UnimplementedError('_rtiBind');
}

Type getRuntimeType(object) {
  throw UnimplementedError('getRuntimeType');
}

String _rtiToString(Rti rti, List<String> genericContext) {
  int kind = Rti._getKind(rti);
  if (kind == Rti.kindDynamic) return 'dynamic';
  return '?';
}

/// Class of static methods for the universe of Rti objects.
///
/// The universe itself is allocated at startup before any types or Dart objects
/// can be created, so it does not have a Dart type.
class Universe {
  Universe._() {
    throw UnimplementedError('Universe is static methods only');
  }

  @pragma('dart2js:noInline')
  static Object create() {
    // TODO(sra): For consistency, this expression should be a JS_BUILTIN that
    // uses the same template as emitted by the emitter.
    return JS(
        '',
        '{'
            'evalCache: new Map(),'
            'unprocessedRules:[],'
            ''
            '}');
  }

  static evalCache(universe) => JS('', '#.evalCache', universe);

  static void addRules(universe, String rules) {
    JS('', '#.unprocessedRules.push(#)', universe, rules);
  }

  static eval(universe, String recipe) {
    var cache = evalCache(universe);
    var probe = _cacheGet(cache, recipe);
    if (probe != null) return probe;
    var rti = _parseRecipe(universe, recipe);
    _cacheSet(cache, recipe, rti);
    return rti;
  }

  static _cacheGet(cache, key) => JS('', '#.get(#)', cache, key);
  static void _cacheSet(cache, key, value) {
    JS('', '#.set(#, #)', cache, key, value);
  }

  static _parseRecipe(universe, recipe) {
    if (recipe == 'dynamic') return _createDynamicRti(universe);
    throw UnimplementedError('Universe._parseRecipe("$recipe")');
  }

  static _createDynamicRti(universe) {
    var rti = Rti.allocate();
    Rti._setKind(rti, Rti.kindDynamic);
    var alwaysPasses = JS('', 'function(o) { return o; }');
    Rti._setAsCheckFunction(rti, alwaysPasses);
    Rti._setTypeCheckFunction(rti, alwaysPasses);
    Rti._setIsTestFunction(rti, JS('', 'function(o) { return true; }'));
    return rti;
  }
}

// -------- Subtype tests ------------------------------------------------------

// Future entry point from compiled code.
bool isSubtype(Rti s, Rti t) {
  return _isSubtype(s, null, t, null);
}

bool _isSubtype(Rti s, var sEnv, Rti t, var tEnv) {
  if (_isIdentical(s, t)) return true;
  int tKind = Rti._getKind(t);
  if (tKind == Rti.kindDynamic) return true;
  if (tKind == Rti.kindNever) return false;
  return false;
}

/// Unchecked cast to Rti.
Rti _castToRti(s) => JS('Rti', '#', s);

bool _isIdentical(s, t) => JS('bool', '# === #', s, t);

// -------- Entry points for testing -------------------------------------------

String testingRtiToString(rti) {
  return _rtiToString(_castToRti(rti), null);
}

String testingRtiToDebugString(rti) {
  // TODO(sra): Create entty point for structural formatting of Rti tree.
  return 'Rti';
}

Object testingCreateUniverse() {
  return Universe.create();
}

Object testingAddRules(universe, String rules) {
  Universe.addRules(universe, rules);
}

bool testingIsSubtype(rti1, rti2) {
  return isSubtype(_castToRti(rti1), _castToRti(rti2));
}

Object testingUniverseEval(universe, String recipe) {
  return Universe.eval(universe, recipe);
}
