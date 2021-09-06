// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/flutter/flutter/issues/84691

// @dart = 2.9

import "dart:async";
import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";


class B<T> {}
class D<S> extends B<D> {}

main() {
  asyncStart();
  var port;
  port = new RawReceivePort((message) {
    var list = message as List<D<String>>;
    var element = list[0] as D<String>;

    port.close();
    asyncEnd();
  });


  var list = <D<String>>[ new D() ];
  port.sendPort.send(list);
}
