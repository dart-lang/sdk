// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';

main() {
  useHtmlIndividualConfiguration();

  group('GeoLocation', () {
    test('getCurrentPosition', () {
      return window.navigator.geolocation.getCurrentPosition().then((position) {
        expect(position.coords.latitude, isNotNull);
        expect(position.coords.longitude, isNotNull);
        expect(position.coords.accuracy, isNotNull);
      });
    });

    test('watchPosition', () {
      return window.navigator.geolocation
          .watchPosition()
          .first
          .then((position) {
        expect(position.coords.latitude, isNotNull);
        expect(position.coords.longitude, isNotNull);
        expect(position.coords.accuracy, isNotNull);
      });
    });
  });
}
