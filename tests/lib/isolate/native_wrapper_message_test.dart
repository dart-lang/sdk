// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:nativewrappers';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

echo(msg) {
  var data = msg[0];
  var reply = msg[1];
  reply.send('echoing ${data(1)}}');
}

base class Test extends NativeFieldWrapperClass2 {
  Test(this.i, this.j);
  int i, j;
}

main() {
  var port = new RawReceivePort();
  var obj = new Test(1, 2);
  var msg = [obj, port.sendPort];
  var snd = Isolate.spawn(echo, msg);

  asyncStart();
  Future<Isolate?>.value(snd).catchError((e) {
    Expect.isTrue(e is ArgumentError);
    Expect.isTrue("$e".contains("Test"));
    port.close();
    asyncEnd();
  });
}
