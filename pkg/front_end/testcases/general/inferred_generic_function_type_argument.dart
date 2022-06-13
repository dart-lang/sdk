// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

typedef F = void Function<T>();

T method<T>() => throw '';

test(F f) {
  f = method();
  var list = [f];
  var set = {f};
  var map1 = {f: 1};
  var map2 = {1: f};
}

main() {}
