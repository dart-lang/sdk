// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('RequestAnimationFrameTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('oneShot', () {
      var frame = window.requestAnimationFrame(
          expectAsync1((timestamp) { }));
    });

  test('twoShot', () {
      var frame = window.requestAnimationFrame(
          expectAsync1((timestamp1) {
            window.requestAnimationFrame(
                expectAsync1((timestamp2) {
                    // Not monotonic on Safari and IE.
                    // Expect.isTrue(timestamp2 > timestamp1, 'timestamps ordered');
                  }));
          }));
    });


  // How do we test that a callback is never called?  We can't wrap the uncalled
  // callback with 'expectAsync1'.  Will request several frames and try
  // cancelling the one that is not the last.
  test('cancel1', () {
      var frame1 = window.requestAnimationFrame(
          (timestamp1) {
            throw new Exception('Should have been cancelled');
          });
      var frame2 = window.requestAnimationFrame(
          expectAsync1((timestamp2) { }));
      window.cancelAnimationFrame(frame1);
    });

  test('cancel2', () {
      var frame1 = window.requestAnimationFrame(
          expectAsync1((timestamp1) { }));
      var frame2 = window.requestAnimationFrame(
          (timestamp2) {
            throw new Exception('Should have been cancelled');
          });
      var frame3 = window.requestAnimationFrame(
          expectAsync1((timestamp3) { }));
      window.cancelAnimationFrame(frame2);
    });
}
