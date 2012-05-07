// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror.

#library('isolate_mirror_self_test');

#import('dart:isolate');
#import('dart:mirrors');

ReceivePort rp;

void testIsolateMirror(port) {
  isolateMirrorOf(port).then((IsolateMirror mirror) {
      Expect.isTrue(mirror.debugName.contains("main"));
      rp.close();
    });
}

void main() {
  // Test that I can reflect on myself.
  rp = new ReceivePort();
  testIsolateMirror(rp.toSendPort());
}
