// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('RequestAnimationFrameTest');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();

  asyncTest('oneShot', 1, () {
      var frame = window.requestAnimationFrame(
          (timestamp) { callbackDone(); });
    });

  asyncTest('twoShot', 1, () {
      var frame = window.requestAnimationFrame(
          (timestamp1) {
            window.requestAnimationFrame(
                (timestamp2) {
                  Expect.isTrue(timestamp2 > timestamp1, 'timestamps ordered');
                  callbackDone();
                });
          });
    });
}
