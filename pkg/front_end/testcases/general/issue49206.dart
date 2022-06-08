// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {}

fn1<T>() => const <A<T>>[];
fn2<T>() => const <A<T>>{};
fn3<T>() => const <A<T>, String>{};
fn4<T>() => const <int, A<T>>{};
fn5<T>() => const <A<T>, A<T>>{};

main() {}
