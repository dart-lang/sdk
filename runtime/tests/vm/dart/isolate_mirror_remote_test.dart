// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of MirrorSystem when
// inspecting a remote isolate.

library isolate_mirror_local_test;

import "package:expect/expect.dart";
import 'dart:isolate';
import 'dart:mirrors';

void isolateMain(SendPort replyTo) {
  var port = new ReceivePort();
  replyTo.send(port.sendPort);
}

void testMirrorSystem(MirrorSystem mirror) {
  Expect.fail('Should not reach here.  Remote isolates not implemented.');
}

void main() {
  var response = new ReceivePort();
  Isolate.spawn(isolateMain, response.sendPort);
  response.first.then((sp) {
    try {
      mirrorSystemOf(sp).then(testMirrorSystem);
      Expect.fail('Should not reach here.  Remote isolates not implemented.');
    } catch (exception) {
      Expect.isTrue(exception is UnimplementedError);
    }
  });
}
