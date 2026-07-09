// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void fn() => null;
void fn2() => null;
int voidToInt() => 42;
int voidToInt2() => 42;
int? voidToNullableInt() => 42;
int? voidToNullableInt2() => 42;
void positionalIntToVoid(int i) => null;
void positionalNullableIntToVoid(int? i) => null;
void positionalNullableIntToVoid2(int? i) => null;
void optionalIntToVoid([int i = 0]) => null;
void optionalIntToVoid2([int i = 0]) => null;
void optionalNullableIntToVoid([int? i]) => null;
void optionalNullableIntToVoid2([int? i]) => null;
void namedIntToVoid({int i = 0}) => null;
void namedIntToVoid2({int i = 0}) => null;
void namedNullableIntToVoid({int? i}) => null;
void namedNullableIntToVoid2({int? i}) => null;
void requiredIntToVoid({required int i}) => null;
void requiredIntToVoid2({required int i}) => null;
void requiredNullableIntToVoid({required int? i}) => null;
void requiredNullableIntToVoid2({required int? i}) => null;
void gn(bool b, [int i = 0]) => null;
void hn(bool b, {int i = 0}) => null;
