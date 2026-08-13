// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

const sameString0 = SameString('hello');

const sameString1 = SameString.named('hello');

extension type const SameString(String s) {
  const SameString.named(String s) : s = '$s world';
}

const sameNullable0 = SameNullable(null);

const sameNullable1 = SameNullable('hello');

extension type const SameNullable(String? s) {}

const sameGeneric0 = SameGeneric<String>('hello');

const sameGeneric1 = SameGeneric<String?>(null);

const sameGeneric2 = SameGeneric<String?>('hello');

extension type const SameGeneric<T>(T s) {}

sameLibrary() {
  SameString x0 = sameString0;
  sameString('hello', x0);

  SameString x1 = sameString1;
  sameString('hello world', x1);

  SameNullable y0 = sameNullable0;
  sameNullable(null, y0);

  SameNullable y1 = sameNullable1;
  sameNullable('hello', y1);

  SameGeneric<String> z0 = sameGeneric0;
  sameGeneric('hello', z0);

  SameGeneric<String?> z1 = sameGeneric1;
  sameGeneric(null, z1);

  SameGeneric<String?> z2 = sameGeneric2;
  sameGeneric('hello', z2);
}

void sameString(expected, SameString es) {
  expect(expected, es);
}

void sameNullable(expected, SameNullable es) {
  expect(expected, es);
}

void sameGeneric<T>(expected, SameGeneric<T> es) {
  expect(expected, es);
}

const valString0 = ExtString('hello');

const valString1 = ExtString.named('hello');

const valNullable0 = ExtNullable(null);

const valNullable1 = ExtNullable('hello');

const valGeneric0 = ExtGeneric<String>('hello');

const valGeneric1 = ExtGeneric<String?>(null);

const valGeneric2 = ExtGeneric<String?>('hello');

otherLibrary() {
  ExtString x0 = valString0;
  extString('hello', x0);

  ExtString x1 = valString1;
  extString('hello world', x1);

  ExtNullable y0 = valNullable0;
  extNullable(null, y0);

  ExtNullable y1 = valNullable1;
  extNullable('hello', y1);

  ExtGeneric<String> z0 = valGeneric0;
  extGeneric('hello', z0);

  ExtGeneric<String?> z1 = valGeneric1;
  extGeneric(null, z1);

  ExtGeneric<String?> z2 = valGeneric2;
  extGeneric('hello', z2);
}

imported() {
  ExtString x0 = libString0;
  extString('hello', x0);

  ExtString x1 = libString1;
  extString('hello world', x1);

  ExtNullable y0 = libNullable0;
  extNullable(null, y0);

  ExtNullable y1 = libNullable1;
  extNullable('hello', y1);

  ExtGeneric<String> z0 = libGeneric0;
  extGeneric('hello', z0);

  ExtGeneric<String?> z1 = libGeneric1;
  extGeneric(null, z1);

  ExtGeneric<String?> z2 = libGeneric2;
  extGeneric('hello', z2);
}

void extString(expected, ExtString es) {
  expect(expected, es);
}

void extNullable(expected, ExtNullable es) {
  expect(expected, es);
}

void extGeneric<T>(expected, ExtGeneric<T> es) {
  expect(expected, es);
}

main() {
  sameLibrary();
  otherLibrary();
  imported();
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
