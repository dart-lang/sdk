// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library TypedDataIsolateTest;

import 'dart:io';
import 'dart:isolate';

second() {
 print('spawned');
 port.receive((data, replyTo) {
   print('got data');
   print(data);
   print('printed data');
   replyTo.send('OK');
   port.close();
 });
}

main() {
 new File(new Options().script).readAsBytes().then((List<int> data) {
   spawnFunction(second).call(data).then((reply) {
     print('got reply');
     port.close();
   });
 });
}

