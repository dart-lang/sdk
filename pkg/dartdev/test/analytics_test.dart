// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartdev/src/analytics.dart';
import 'package:test/test.dart';

void main() {
  group('DisabledAnalytics', disabledAnalyticsObject);
  group('utils', utils);
}

void disabledAnalyticsObject() {
  test('object', () {
    var diabledAnalytics = DisabledAnalytics('trackingId', 'appName');
    expect(diabledAnalytics.trackingId, 'trackingId');
    expect(diabledAnalytics.applicationName, 'appName');
    expect(diabledAnalytics.enabled, isFalse);
    expect(diabledAnalytics.firstRun, isFalse);
  });
}

void utils() {
  test('getCommandStr', () {
    var commands = <String>['help', 'foo', 'bar', 'baz'];

    // base cases
    expect(getCommandStr(['help'], commands), 'help');
    expect(getCommandStr(['bar', 'help'], commands), 'help');
    expect(getCommandStr(['help', 'bar'], commands), 'help');
    expect(getCommandStr(['bar', '-h'], commands), 'help');
    expect(getCommandStr(['bar', '--help'], commands), 'help');

    // non-trivial tests
    expect(getCommandStr(['foo'], commands), 'foo');
    expect(getCommandStr(['bar', 'baz'], commands), 'bar');
    expect(getCommandStr(['bazz'], commands), '<unknown>');
  });
}
