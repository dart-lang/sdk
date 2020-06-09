// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'type_builder.dart';

// Tests for runtime type object normalization.

// Tests of non-generic function types.
void simpleTypeTests() {
  // Different top types are not runtime equal
  checkTypeInequalities($ObjectQ, $dynamic);
  checkTypeInequalities($ObjectQ, $void);
  checkTypeInequalities($dynamic, $void);

  // FutureOr^n of top type is that top type
  checkTypeEqualities($FutureOr($FutureOr($ObjectQ)), $ObjectQ);
  checkTypeEqualities($FutureOr($FutureOr($dynamic)), $dynamic);
  checkTypeEqualities($FutureOr($FutureOr($void)), $void);

  // FutureOr^n of top type is not a different top type
  checkTypeInequalities($FutureOr($FutureOr($ObjectQ)), $dynamic);
  checkTypeInequalities($FutureOr($FutureOr($ObjectQ)), $void);
  checkTypeInequalities($FutureOr($FutureOr($dynamic)), $void);

  // FutureOr of Object is Object
  checkTypeEqualities($FutureOr($Object), $Object);
  checkTypeEqualities($FutureOr($FutureOr($Object)), $Object);

  // FutureOr of Object is not a top type
  checkTypeInequalities($FutureOr($Object), $ObjectQ);
  checkTypeInequalities($FutureOr($FutureOr($Object)), $dynamic);
  checkTypeInequalities($FutureOr($FutureOr($FutureOr($Object))), $void);

  // FutureOr of Never is Future<Never>
  checkTypeEqualities($FutureOr($Never), $Future($Never));

  // FutureOr of Null is Future<Null>?
  checkTypeEqualities($FutureOr($Null), $OrNull($Future($Null)));

  // FutureOr of Null is not Future<Null>
  checkTypeInequalities($FutureOr($Null), $Future($Null));

  // Top type or Null is that top type
  checkTypeEqualities($OrNull($ObjectQ), $ObjectQ);
  checkTypeEqualities($OrNull($dynamic), $dynamic);
  checkTypeEqualities($OrNull($void), $void);
  checkTypeEqualities($OrNull($FutureOr($ObjectQ)), $ObjectQ);

  // Never is not Null
  checkTypeInequalities($Never, $Null);

  // Never? is Null
  checkTypeEqualities($OrNull($Never), $Null);

  // Null? is Null
  checkTypeEqualities($OrNull($Null), $Null);

  // FutureOr<T>? is FutureOr<T> if T is nullable
  checkTypeEqualities(
      $OrNull($FutureOr($OrNull($int))), $FutureOr($OrNull($int)));

  // FutureOr<T>? is not FutureOr<T> if T is not nullable
  checkTypeInequalities($OrNull($FutureOr($int)), $FutureOr($int));

  // FutureOr<T>? is not FutureOr<T?> if T is not nullable
  checkTypeInequalities($OrNull($FutureOr($int)), $FutureOr($OrNull($int)));

  // T?? is T?
  checkTypeEqualities($OrNull($OrNull($OrNull($int))), $OrNull($int));

  // Top?? is Top
  checkTypeEqualities($OrNull($OrNull($dynamic)), $dynamic);

  // List<T> is List<R> if T is R
  checkTypeEqualities($List($FutureOr($Never)), $List($Future($Never)));
  checkTypeEqualities($List($OrNull($Never)), $List($Null));
  checkTypeEqualities($List($FutureOr($Object)), $List($Object));

  // B Function(A) is D Function(C) if A is C and B is D
  checkTypeEqualities(
      $Function1(
          $OrNull($FutureOr($OrNull($Null))), $FutureOr($FutureOr($Object))),
      $Function1($OrNull($Future($Null)), $Object));

  // B Function({A a}) is D Function({C a}) if A is C and B is D
  checkTypeEqualities(
      $FunctionOptionalNamedA(
          $OrNull($FutureOr($OrNull($Null))), $FutureOr($FutureOr($Object))),
      $FunctionOptionalNamedA($OrNull($Future($Null)), $Object));

  // B Function({A a}) is not D Function({C b}) even if A is C and B is D
  checkTypeInequalities(
      $FunctionOptionalNamedA(
          $OrNull($FutureOr($OrNull($Null))), $FutureOr($FutureOr($Object))),
      $FunctionOptionalNamedB($OrNull($Future($Null)), $Object));

  // B Function({required A a}) is D Function({required C a}) if A is C and B is D
  checkTypeEqualities(
      $FunctionRequiredNamedA(
          $OrNull($FutureOr($OrNull($Null))), $FutureOr($FutureOr($Object))),
      $FunctionRequiredNamedA($OrNull($Future($Null)), $Object));

  // B Function({required A a}) is not D Function({C a}) even if A is C and B is D
  checkTypeInequalities(
      $FunctionRequiredNamedA(
          $OrNull($FutureOr($OrNull($Null))), $FutureOr($FutureOr($Object))),
      $FunctionOptionalNamedA($OrNull($Future($Null)), $Object));
}

void main() {
  simpleTypeTests();
}
