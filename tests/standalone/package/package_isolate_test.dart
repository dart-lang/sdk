// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=tests/standalone/package/packages/

library package_isolate_test;
import 'package:shared.dart' as shared;
import 'dart:isolate';
import '../../../pkg/unittest/lib/unittest.dart';

expectResponse() {
  port.receive(expectAsync2((msg, r) {
    expect('isolate', msg);
    expect('main', shared.output);
    port.close();
  }));
}

void main() {
  test("package in spawnFunction()", () {
    expectResponse();
    shared.output = 'main';
    var sendPort = spawnFunction(isolate_main);
    sendPort.send("sendPort", port.toSendPort());
  });
  
  test("package in spawnUri() of sibling file", () {
    expectResponse();
    shared.output = 'main';
    var sendPort = spawnUri('sibling_isolate.dart');
    sendPort.send('sendPort', port.toSendPort());
  });

  test("package in spawnUri() of file in folder", () {
    expectResponse();
    shared.output = 'main';
    var sendPort = spawnUri('test_folder/folder_isolate.dart');
    sendPort.send('sendPort', port.toSendPort());
  });
}

void isolate_main() {
  shared.output = 'isolate';
  port.receive((msg, replyTo) {
    replyTo.send(shared.output);
  });
}
