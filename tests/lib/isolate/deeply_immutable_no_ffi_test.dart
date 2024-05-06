// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These checks are not implemented in the analyzer. If we ever decide to
// implement the static checks in the analyzer, move this test into the
// static_checks subdir to prevent analyzer errors showing up in the IDE.

import 'dart:async';
import 'dart:isolate';

@pragma('vm:deeply-immutable')
final class Foo {
  dynamic myMutableField;
  //      ^
  // [cfe] Deeply immutable classes must only have final non-late instance fields.
  // [cfe] Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', and classes annotated with `@pragma('vm:deeply-immutable')`.
}

Future<T> sendReceive<T>(T o) async {
  final r = ReceivePort();
  final si = StreamIterator(r);

  r.sendPort.send(o);
  await si.moveNext();
  final o2 = si.current;

  si.cancel();
  return o2;
}

main() async {
  final o = Foo();
  final o2 = await sendReceive(o);
  if (!identical(o, o2)) throw 'not identical';

  throw 'we could share mutable objects - oh no!';
}
