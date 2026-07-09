// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:expect/expect.dart';

main() async {
  // Make large objects whose objects object can be copied in fast path but backing
  // store cannot.
  final foo = Foo();
  final objects = <dynamic>{};
  for (int i = 0; i < 1024 * 1024; ++i) {
    objects.add(i);
  }
  // Ensure there's at least one element that needs re-hashing when copying.
  objects.add(foo);
  foo.hashQueries = 0;

  final copyOfFoo = (await copy(objects)).last as Foo;
  Expect.equals(1, copyOfFoo.hashQueries);
}

Future<T> copy<T>(T value) async {
  final rp = ReceivePort();
  final sp = rp.sendPort;
  sp.send(value);
  return (await rp.first) as T;
}

class Foo {
  int hashQueries = 0;

  int get hashCode {
    hashQueries++;
    return super.hashCode;
  }
}
