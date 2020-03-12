// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

import 'generic_function_type_equality_null_safe_lib.dart';

void fn<X>() => null;
R voidToR<R>() => null as R;
void positionalRToVoid<R>(R i) => null;
void optionalRToVoid<R>([List<R> i]) => null;
void namedRToVoid<R>({List<R> i}) => null;
void hn<T, S>(T b, [List<S> i]) => null;
void kn<T, S>(T b, {List<S> i}) => null;

void positionalTToVoidWithBound<T extends B>(T i) => null;
void optionalTToVoidWithBound<T extends B>([List<T> i]) => null;
void namedTToVoidWithBound<T extends B>({List<T> i}) => null;

class A<T extends B> {
  void fn(T i) => null;
}

var rawAFnTearoff = A().fn;
