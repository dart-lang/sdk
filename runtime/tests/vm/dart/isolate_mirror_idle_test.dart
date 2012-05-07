// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror.

#library('isolate_mirror_idle_test');

#import('dart:isolate');
#import('dart:mirrors');

class IdleIsolate extends Isolate {
  void main() {
    // This isolate goes idle waiting for a message which never arrives.
    port.receive((message, replyTo) {
        print("IdleIsolate received $message");
        Expect.isTrue(false);
      });
  }
}

void testIsolateMirror(port) {
  isolateMirrorOf(port).then((IsolateMirror mirror) {
      Expect.isTrue(mirror.debugName.contains("IdleIsolate"));
    });
}

void main() {
  // Test that I can reflect on a busy isolate.
  new IdleIsolate().spawn().then(testIsolateMirror);
}
