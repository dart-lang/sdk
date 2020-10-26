// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/analytics.dart';
import 'package:test/test.dart';

import 'utils.dart';

List<Map> extractAnalytics(ProcessResult result) {
  return LineSplitter.split(result.stderr)
      .where((line) => line.startsWith('[analytics]: '))
      .map((line) => json.decode(line.substring('[analytics]: '.length)) as Map)
      .toList();
}

void main() {
  group('DisabledAnalytics', disabledAnalyticsObject);

  group('Sending analytics', () {
    test('help', () {
      final p = project(logAnalytics: true);
      final result = p.runSync('help', []);
      expect(extractAnalytics(result), [
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'help',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });
    test('create', () {
      final p = project(logAnalytics: true);
      final result = p.runSync('create', ['-tpackage-simple', 'name']);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'create'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'create',
            'label': null,
            'value': null,
            'cd1': '0',
            'cd3': ''
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'create',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });

    test('pub get', () {
      final p = project(logAnalytics: true);
      final result = p.runSync('pub', ['get', '--dry-run']);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'pub/get'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'pub/get',
            'label': null,
            'value': null,
            'cd1': '0',
            'cd2': '',
            'cd3': '',
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'pub',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });

    test('format', () {
      final p = project(logAnalytics: true);
      final result = p.runSync('format', ['-l80']);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'format'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'format',
            'label': null,
            'value': null,
            'cd1': '0',
            // TODO(sigurdm): We should filter out the value here.
            'cd3': '-l80',
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'format',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });
  });
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
