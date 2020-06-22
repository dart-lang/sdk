// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opted-in library for parameter_checks_test.dart.

import 'dart:async' show FutureOr;

foo1(int a) {}
foo2(int a, [int b = 1, String c = '']) {}
foo3({int a = 0, required int b}) {}
foo4a<T>(T a) {}
foo4b<T extends Object>(T a) {}
foo5a<T>(FutureOr<T> a) {}
foo5b<T extends Object>(FutureOr<T> a) {}
foo6a<T extends FutureOr<S>, S extends U, U extends int?>(T a) {}
foo6b<T extends FutureOr<S>, S extends U, U extends int>(T a) {}

void Function(int) bar() => (int x) {};
