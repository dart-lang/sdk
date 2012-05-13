// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('RequestAnimationFrameTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();

  asyncTest('oneShot', 1, () {
      window.webkitRequestAnimationFrame((timestamp) { callbackDone(); });
      layoutTestController.display();
    });

  asyncTest('twoShot', 1, () {
      window.webkitRequestAnimationFrame(
          (timestamp1) {
            window.webkitRequestAnimationFrame(
                (timestamp2) {
                  // Not monotonic on Safari and IE.
                  //Expect.isTrue(timestamp2 > timestamp1, 'timestamps ordered');
                  callbackDone();
                });
            layoutTestController.display();
          });
      layoutTestController.display();
    });
}
