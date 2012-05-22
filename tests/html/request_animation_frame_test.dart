// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('RequestAnimationFrameTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('oneShot', () {
      var frame = window.requestAnimationFrame(
          expectAsync1((timestamp) { }));
    });

  test('twoShot', () {
      var frame = window.requestAnimationFrame(
          (timestamp1) {
            window.requestAnimationFrame(
                expectAsync1((timestamp2) {
                  // Not monotonic on Safari and IE.
                  // Expect.isTrue(timestamp2 > timestamp1, 'timestamps ordered');
                }));
          });
    });
}
