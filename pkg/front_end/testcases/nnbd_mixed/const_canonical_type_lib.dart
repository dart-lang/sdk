// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'dart:async';

class A<X> {
  const A();
}

typedef F1 = A<FutureOr<dynamic>> Function();
typedef F2 = A<dynamic> Function();
typedef F3 = A<FutureOr<FutureOr<dynamic>>> Function();
typedef F4 = A Function();

const c = A;
var v = A;

const a1 = A<List<F1>>();
const a2 = A<List<F2>>();
const a3 = A<List<F3>>();
const a4 = A<List<F4>>();
