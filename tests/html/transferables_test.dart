// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TransferableTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('TransferableTest', () {
    window.on.message.add(expectAsync1((messageEvent) {
      expect(messageEvent.data, new isInstanceOf<ArrayBuffer>());
    }));
    final buffer = (new Float32Array(3)).buffer;
    window.webkitPostMessage(buffer, '*', [buffer]);
  });
}
