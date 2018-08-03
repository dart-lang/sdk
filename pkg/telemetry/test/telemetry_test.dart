// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:telemetry/telemetry.dart';
import 'package:test/test.dart';
import 'package:usage/usage.dart';

void main() {
  group('telemetry', () {
    test('getDartStorageDirectory', () {
      Directory dir = getDartStorageDirectory();
      expect(dir, isNotNull);
    });

    test('getDartVersion', () {
      expect(getDartVersion(), isNotNull);
    });

    test('createAnalyticsInstance', () {
      Analytics analytics = createAnalyticsInstance('UA-0', 'test-app');
      expect(analytics, isNotNull);
      expect(analytics.trackingId, 'UA-0');
      expect(analytics.getSessionValue('an'), 'test-app');
      expect(analytics.getSessionValue('av'), isNotNull);
      expect(analytics.clientId, isNotNull);
    });
  });
}
