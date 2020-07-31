// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// Requirements=nnbd-weak

import 'dart:async';
import 'type_builder.dart';

// Tests for runtime type object normalization with legacy types

// TypeBuilder for legacy `*` types.  Note that the type parameter `S` may
// be a non-legacy type, but by passing it on as an argument to `build` here
// in a legacy library, a legacy `*` marker is added.
TypeBuilder $Star(TypeBuilder of) => (build) => of(<S>() => build<S>());

// These tests check that normalization handles `*` types correctly
void legacyTypeNormalizationTests() {
  // FutureOr<Object*> is Object*
  checkTypeEqualities($FutureOr($Star($Object)), $Star($Object));

  // Never*? is Null
  checkTypeEqualities($OrNull($Star($Never)), $Null);

  // FutureOr<R>* is FutureOr<R> if R is nullable
  checkTypeEqualities(
      $Star($FutureOr($OrNull($int))), $FutureOr($OrNull($int)));

  // R*? is R?
  checkTypeEqualities($OrNull($Star($int)), $OrNull($int));

  // Top* is Top
  checkTypeEqualities($Star($ObjectQ), $ObjectQ);
  checkTypeEqualities($Star($dynamic), $dynamic);
  checkTypeEqualities($Star($void), $void);

  // Null* is Null
  checkTypeEqualities($Star($Null), $Null);

  // R?* is R?
  checkTypeEqualities($Star($OrNull($int)), $OrNull($int));

  // R*** is R*
  checkTypeEqualities($Star($Star($Star($int))), $Star($int));
}

// These tests check that equality ignores `*` types in weak mode, but
// does not equate Null and Never and does not ignore required.
void weakModeTests() {
  // Object* is Object
  checkTypeEqualities($Star($Object), $Object);

  // int* is int
  checkTypeEqualities($Star($int), $int);

  // Null* is Null
  checkTypeEqualities($Star($Null), $Null);

  // Never* is Never
  checkTypeEqualities($Star($Never), $Never);

  // List<T> is List<S> if T is S
  checkTypeEqualities($List($Star($Object)), $List($Object));

  // List<T> is List<S> if T is S
  checkTypeEqualities($List($FutureOr($Star($Object))), $List($Object));

  // Never is not Null, even in weak mode
  checkTypeInequalities($Never, $Null);

  // Never* is not Null, even in weak mode
  checkTypeInequalities($Star($Never), $Null);

  // Object* is not Object?, even in weak mode
  checkTypeInequalities($Star($Object), $ObjectQ);

  // B Function(A) is D Function(C) if A is C and B is D
  checkTypeEqualities($Function1($Star($Object), $OrNull($Star($int))),
      $Function1($Object, $OrNull($int)));

  // B Function({A a}) is D Function({C a}) if A is C and B is D
  checkTypeEqualities(
      $FunctionOptionalNamedA($Star($Object), $OrNull($Star($int))),
      $FunctionOptionalNamedA($Object, $OrNull($int)));

  // B Function({required A a}) is D Function({required C a}) if A is C and B is D
  checkTypeEqualities(
      $FunctionRequiredNamedA($Star($Object), $OrNull($Star($int))),
      $FunctionRequiredNamedA($Object, $OrNull($int)));

  // B Function({required A a}) is not D Function({C a}) even if A is C and B is D
  checkTypeInequalities($FunctionRequiredNamedA($Object, $OrNull($int)),
      $FunctionOptionalNamedA($Object, $OrNull($int)));
}

void main() {
  legacyTypeNormalizationTests();
  weakModeTests();
}
