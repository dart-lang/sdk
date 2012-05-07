// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for checking implemention of IsolateMirror.

#library('isolate_mirror_busy_test');

#import('dart:isolate');
#import('dart:mirrors');

class BusyIsolate extends Isolate {
  void busy() {
    // TODO(turnidge): Get rid of this function once we check for
    // interrupts on backwards branches.
  }
  void main() {
    while (true) {
      busy();
    }
  }
}

void testIsolateMirror(port) {
  isolateMirrorOf(port).then((IsolateMirror mirror) {
      Expect.isTrue(mirror.debugName.contains("BusyIsolate"));
    });
}

void main() {
  // Test that I can reflect on a busy isolate.
  new BusyIsolate().spawn().then(testIsolateMirror);
}
