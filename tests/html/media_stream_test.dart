// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library media_stream_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported_media', () {
    test('supported', () {
      expect(MediaStream.supported, true);
    });
  });

  group('supported_MediaStreamEvent', () {
    test('supported', () {
      expect(MediaStreamEvent.supported, true);
    });
  });

  group('supported_MediaStreamTrackEvent', () {
    test('supported', () {
      expect(MediaStreamTrackEvent.supported, true);
    });
  });

  group('constructors', () {
    test('MediaStreamEvent', () {
      var expectation = MediaStreamEvent.supported ? returnsNormally : throws;
      expect(() {
        var event = new Event.eventType('MediaStreamEvent', 'media');
        expect(event is MediaStreamEvent, isTrue);
      }, expectation);
    });

    test('MediaStreamTrackEvent', () {
      var expectation =
          MediaStreamTrackEvent.supported ? returnsNormally : throws;
      expect(() {
        var event = new Event.eventType('MediaStreamTrackEvent', 'media');
        expect(event is MediaStreamTrackEvent, isTrue);
      }, expectation);
    });
  });
}
