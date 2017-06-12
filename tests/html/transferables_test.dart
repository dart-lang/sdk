// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TransferableTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  var isByteBuffer = predicate((x) => x is ByteBuffer, 'is an ByteBuffer');

  test('TransferableTest', () {
    if (!Platform.supportsTypedData) {
      return;
    }

    final buffer = (new Float32List(3)).buffer;
    window.postMessage(
        {'id': 'transferable data', 'buffer': buffer}, '*', [buffer]);

    return window.onMessage.firstWhere((e) {
      return e.data is Map && e.data['id'] == 'transferable data';
    }).then((messageEvent) {
      expect(messageEvent.data['buffer'], isByteBuffer);
    });
  });
}
