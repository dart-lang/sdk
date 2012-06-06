// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TransferableTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  asyncTest('TransferableTest', 1, () {
    window.on.message.add((messageEvent) {
      expect(messageEvent.data is ArrayBuffer).isTrue();
      callbackDone();
    });
    final buffer = (new Float32Array(3)).buffer;
    window.webkitPostMessage(buffer, '*', [buffer]);
  });
}
