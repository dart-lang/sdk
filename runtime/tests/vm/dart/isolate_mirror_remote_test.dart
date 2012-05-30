// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror when
// inspecting a remote isolate.

#library('isolate_mirror_local_test');

#import('dart:isolate');
#import('dart:mirrors');

void isolateMain() {
  port.receive(
      (msg, replyPort) {
        Expect.fail('Received unexpected message $msg in remote isolate.');
      });
}

void testIsolateMirror(IsolateMirror mirror) {
  Expect.fail('Should not reach here.  Remote isolates not implemented.');
}

void main() {
  SendPort sp = spawnFunction(isolateMain);
  try {
    isolateMirrorOf(sp).then(testIsolateMirror);
    Expect.fail('Should not reach here.  Remote isolates not implemented.');
  } catch (var exception) {
    Expect.isTrue(exception is NotImplementedException);
  }
}
