// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

import 'dart:ffi';
import 'dart:io';

typedef Free = NativeFunction<Void Function(Pointer)>;
final free = DynamicLibrary.process().lookup<Free>('free');

final _nativeFinalizer = NativeFinalizer(free);

class A implements Finalizable {
  A() {
    _nativeFinalizer.attach(this, Pointer.fromAddress(1),
        detach: this, externalSize: 1 << 32); // will crash, if it ever runs
  }
}

class B implements Finalizable {
  final A a;

  B(this.a);
}

Future<void> main() async {
  // ignore: unused_local_variable
  final b = B(A()); // I would expect b.a to live as long as b
  final l = <int>[];
  Future.doWhile(() {
    l.add(1); // put some pressure on GC
    return true;
  });
  await ProcessSignal.sigint.watch().first;
  // b still alive here, but what about b.a?
}
