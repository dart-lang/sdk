// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:isolate';

var subscription;

void onData(x) {
  print(x);
  subscription.cancel();
}

main() {
  var string = new String.fromCharCode(65); // External string factory.
  var port = new ReceivePort(); // External factory.
  subscription = port.listen(onData); // Dynamic call on external instance.
  port.sendPort.send(string);
}
