// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

class Base {
  var myMutableField;
}

@pragma('vm:deeply-immutable')
final class Foo extends Base {}
//          ^^^
// [cfe] The super type of deeply immutable classes must be deeply immutable.

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
