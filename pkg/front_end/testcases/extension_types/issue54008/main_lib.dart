// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const libString0 = ExtString('hello');

const libString1 = ExtString.named('hello');

extension type const ExtString(String s) {
  const ExtString.named(String s) : s = '$s world';
}

const libNullable0 = ExtNullable(null);

const libNullable1 = ExtNullable('hello');

extension type const ExtNullable(String? s) {}

const libGeneric0 = ExtGeneric<String>('hello');

const libGeneric1 = ExtGeneric<String?>(null);

const libGeneric2 = ExtGeneric<String?>('hello');

extension type const ExtGeneric<T>(T s) {}
