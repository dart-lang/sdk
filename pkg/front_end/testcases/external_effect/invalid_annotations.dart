// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('external-effect')
external int a;

@pragma('external-effect')
external int get b;

@pragma('external-effect')
external set c(int value);

@pragma('external-effect')
void d(Object? o) {}

@pragma('external-effect')
external void e(Object o);

const z = 'external-effect';

@pragma(z)
external void f(Object? o);

class A {
  @pragma('external-effect')
  external void a(Object? o);

  @pragma('external-effect')
  external static int b(Object? o);

  @pragma('external-effect')
  external static void c(Object? o, Object? x);

  @pragma('external-effect')
  external static void d(int i);

  @pragma('external-effect')
  external static void e([Object? o = const Object()]);

  @pragma('external-effect')
  external static void f({required Object? o});

  @pragma('external-effect')
  external static void g({Object? o = 3});

  @pragma('external-effect')
  external static void h<T>(T? t);
}

void main() {}
