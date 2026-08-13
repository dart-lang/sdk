// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T f<T>(T t) => t;

T g<T>(T? t) => t!;

T h<T extends Object>(T? t) => t!;

foo(dynamic d, void v, Object? onull, Object o, String? snull, String s) {
  f(d);
  f(v);
  f(onull);
  f(o);
  f(snull);
  f(s);

  g(d);
  g(v);
  g(onull);
  g(o);
  g(snull);
  g(s);

  h(d);
  h(v);
  h(onull);
  h(o);
  h(snull);
  h(s);
}

main() {}
