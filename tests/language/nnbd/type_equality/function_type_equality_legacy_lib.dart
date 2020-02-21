// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

void fn() => null;
int voidToInt() => 42;
void positionalIntToVoid(int i) => null;
void optionalIntToVoid([int i]) => null;
void namedIntToVoid({int i}) => null;
void gn(bool b, [int i]) => null;
void hn(bool b, {int i}) => null;
