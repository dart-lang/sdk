// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Checks that you can send and receive regex in a message.

import "dart:async";
import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main(args) async {
  asyncStart();
  final rp = ReceivePort();
  final r = RegExp('b');
  final match = r.firstMatch('bb');
  Expect.equals(match != null ? match.start : null, 0);
  rp.sendPort.send(r);

  final si = StreamIterator(rp);
  await si.moveNext();
  final x = si.current as RegExp;
  final matchX = x.firstMatch('bb');
  Expect.equals(matchX != null ? matchX.start : null, 0);
  rp.close();
  asyncEnd();
}
