// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=packages/

library package_isolate_test;

import 'package:shared.dart' as shared;
import 'dart:isolate';
import '../../../pkg/async_helper/lib/async_helper.dart';
import '../../../pkg/expect/lib/expect.dart';

expectResponse() {
  asyncStart();
  var receivePort = new ReceivePort();
  receivePort.first.then((msg) {
    Expect.equals('isolate', msg);
    Expect.equals('main', shared.output);
    asyncEnd();
  });
  return receivePort;
}

void main() {
  {
    var replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawn(isolate_main, replyPort);
  }

  {
    // Package in spawnUri() of sibling file.
    var replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawnUri(Uri.parse('sibling_isolate.dart'), [], replyPort);
  }

  {
    // Package in spawnUri() of file in folder.
    var replyPort = expectResponse().sendPort;
    shared.output = 'main';
    Isolate.spawnUri(
        Uri.parse('test_folder/folder_isolate.dart'), [], replyPort);
  }
}

void isolate_main(SendPort replyTo) {
  shared.output = 'isolate';
  replyTo.send(shared.output);
}
