// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=packages/

library package_isolate_test;
import 'package:shared.dart' as shared;
import 'dart:isolate';
import '../../../pkg/unittest/lib/unittest.dart';

expectResponse() {
  var receivePort = new ReceivePort();
  receivePort.receive(expectAsync2((msg, r) {
    expect('isolate', msg);
    expect('main', shared.output);
    receivePort.close();
  }));
  return receivePort;
}

void main() {
  test("package in spawnFunction()", () {
    var replyPort = expectResponse().toSendPort();
    shared.output = 'main';
    var sendPort = spawnFunction(isolate_main);
    sendPort.send("sendPort", replyPort);
  });
  
  test("package in spawnUri() of sibling file", () {
    var replyPort = expectResponse().toSendPort();
    shared.output = 'main';
    var sendPort = spawnUri('sibling_isolate.dart');
    sendPort.send('sendPort', replyPort);
  });

  test("package in spawnUri() of file in folder", () {
    var replyPort = expectResponse().toSendPort();
    shared.output = 'main';
    var sendPort = spawnUri('test_folder/folder_isolate.dart');
    sendPort.send('sendPort', replyPort);
  });
}

void isolate_main() {
  shared.output = 'isolate';
  port.receive((msg, replyTo) {
    replyTo.send(shared.output);
  });
}
