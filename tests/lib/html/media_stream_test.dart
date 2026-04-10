// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(f) => f;

main() {
  group('constructors', () {
    test('MediaStreamEvent', () {
      var expectation = globalContext.has('MediaStreamEvent')
          ? returnsNormally
          : throws;
      expect(() {
        var event = confuse(MediaStreamEvent('media'));
        expect(event is MediaStreamEvent, isTrue);
      }, expectation);
    });

    test('MediaStreamTrackEvent', () {
      var expectation = globalContext.has('MediaStreamTrackEvent')
          ? returnsNormally
          : throws;
      expect(() {
        var event = confuse(MediaStreamTrackEvent('media', {}));
        expect(event is MediaStreamTrackEvent, isTrue);
      }, expectation);
    });
  });
}
