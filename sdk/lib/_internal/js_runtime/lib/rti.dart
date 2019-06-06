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

  String get interfaceName {
    assert(_kind == kindInterface);
    return JS('String', '#', _primary);
  }

  /// Additional data associated with type.
  ///
  /// - The type arguments of an interface type.
  /// - The type arguments from enclosing functions and closures for a
  ///   kindBinding.
  /// - TBD for kindFunction and kindGenericFunction.
  dynamic _rest;

  JSArray get interfaceTypeArguments {
    // The array is a plain JavaScript Array, otherwise we would need the type
    // `JSArray<Rti>` to exist before we could create the type `JSArray<Rti>`.
    assert(_kind == kindInterface);
    return JS('JSUnmodifiableArray', '#', _primary);
  }

  /// On [Rti]s that are type environments, derived types are cached on the
  /// environment to ensure fast canonicalization. Ground-term types (i.e. not
  /// dependent on class or function type parameters) are cached in the
  /// universe. This field starts as `null` and the cache is created on demand.
  dynamic _evalCache;
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

// Entry points for testing

String testingRtiToString(dynamic rti) {
  return 'Rti';
}
