// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1a<T extends (int, String)>(T t) => t.$1; // Ok
method1b<T extends (int, String)>(T t) => t.$2; // Ok
method1c<T extends (int, String)>(T t) => t.$3; // Error
method1d<T extends (int, String)>(T t) => t.a; // Error

method2a<T extends (int, {String a})>(T t) => t.$1; // Ok
method2b<T extends (int, {String a})>(T t) => t.a; // Ok
method2c<T extends (int, {String a})>(T t) => t.$2; // Error
method2d<T extends (int, {String a})>(T t) => t.b; // Error

method3a<T extends (int, String), S extends T>(S t) => t.$1; // Ok
method3b<T extends (int, String), S extends T>(S t) => t.$2; // Ok
method3c<T extends (int, String), S extends T>(S t) => t.$3; // Error
method3d<T extends (int, String), S extends T>(S t) => t.a; // Error

void method1<T>(T t) {
  if (t is (int, String)) t.$1; // Ok
  if (t is (int, String)) t.$2; // Ok
  if (t is (int, String))  t.$3; // Error
  if (t is (int, String))  t.a; // Error

  if (t is (int, {String a})) t.$1; // Ok
  if (t is (int, {String a})) t.a; // Ok
  if (t is (int, {String a})) t.$2; // Error
  if (t is (int, {String a})) t.b; // Error
}

void method2(Object t) {
  if (t is (int, String)) t.$1; // Ok
  if (t is (int, String)) t.$2; // Ok
  if (t is (int, String))  t.$3; // Error
  if (t is (int, String))  t.a; // Error

  if (t is (int, {String a})) t.$1; // Ok
  if (t is (int, {String a})) t.a; // Ok
  if (t is (int, {String a})) t.$2; // Error
  if (t is (int, {String a})) t.b; // Error
}