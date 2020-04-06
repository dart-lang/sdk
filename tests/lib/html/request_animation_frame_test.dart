// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library RequestAnimationFrameTest;

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

Future testOneShot() async {
  final done = new Completer();
  window.requestAnimationFrame(done.complete);
  await done.future;
}

Future testTwoShot() async {
  final done = new Completer();
  window.requestAnimationFrame((timestamp1) {
    window.requestAnimationFrame((timestamp2) {
      // Not monotonic on Safari and IE.
      // expect(timestamp2, greaterThan(timestamp1),
      //    reason: 'timestamps ordered');
      done.complete();
    });
  });
  await done.future;
}

// How do we test that a callback is never called?  We can't wrap the uncalled
// callback with 'expectAsync'.  Will request several frames and try
// cancelling the one that is not the last.
Future testCancel1() async {
  final done = new Completer();
  var frame1 = window.requestAnimationFrame((timestamp1) {
    fail('Should have been cancelled');
  });
  var frame2 = window.requestAnimationFrame(done.complete);
  window.cancelAnimationFrame(frame1);
  await done.future;
}

Future testCancel2() async {
  final done1 = new Completer();
  final done2 = new Completer();
  var frame1 = window.requestAnimationFrame(done1.complete);
  var frame2 = window.requestAnimationFrame((timestamp2) {
    fail('Should have been cancelled');
  });
  var frame3 = window.requestAnimationFrame(done2.complete);
  window.cancelAnimationFrame(frame2);
  await Future.wait([done1.future, done2.future]);
}

main() async {
  await testOneShot();
  await testTwoShot();
  await testCancel1();
  await testCancel2();
}
