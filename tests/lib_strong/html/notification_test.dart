// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported_notification', () {
    test('supported', () {
      expect(Notification.supported, true);
    });
  });

  group('constructors', () {
    // Test that we create the notification and that the parameters have
    // the expected values. Note that these won't actually display, because
    // we haven't asked for permission, which would have to be done
    // interactively, so can't run on a bot.
    test('Notification', () {
      var expectation = Notification.supported ? returnsNormally : throws;
      expect(() {
        var allDefaults = new Notification("Hello world");
        var allSpecified = new Notification("Deluxe notification",
            dir: "rtl",
            body: 'All parameters set',
            icon: 'icon.png',
            tag: 'tag',
            lang: 'en_US');
        expect(allDefaults is Notification, isTrue);
        expect(allSpecified is Notification, isTrue);
        expect(allDefaults.title, "Hello world");
        expect(allSpecified.title, "Deluxe notification");
        expect(allSpecified.dir, "rtl");
        expect(allSpecified.body, "All parameters set");
        var icon = allSpecified.icon;
        var tail = Uri.parse(icon).pathSegments.last;
        expect(tail, "icon.png");
        expect(allSpecified.tag, "tag");
        expect(allSpecified.lang, "en_US");
      }, expectation);
    });
  });
}
