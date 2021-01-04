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
      final result = p.runSync(['help']);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'help'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'help',
            'label': null,
            'value': null
          }
        },
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
      final result = p.runSync(['create', '-tpackage-simple', 'name']);
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
            'cd3': ' template ',
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
      final result = p.runSync(['pub', 'get', '--dry-run']);
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
            'cd3': ' dry-run '
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'pub/get',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });

    test('format', () {
      final p = project(logAnalytics: true);
      final result = p.runSync(['format', '-l80']);
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
            'cd3': ' line-length ',
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

    test('run', () {
      final p = project(
          mainSrc: 'void main(List<String> args) => print(args)',
          logAnalytics: true);
      final result = p.runSync([
        'run',
        '--no-pause-isolates-on-exit',
        '--enable-asserts',
        'lib/main.dart',
        '--argument'
      ]);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'run'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'run',
            'label': null,
            'value': null,
            'cd1': '0',
            'cd3': ' enable-asserts pause-isolates-on-exit ',
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'run',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });

    test('run --enable-experiments', () {
      final p = project(
          mainSrc: 'void main(List<String> args) => print(args);',
          logAnalytics: true);
      final result = p.runSync([
        'run',
        '--enable-experiment=non-nullable',
        'lib/main.dart',
      ]);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'run'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'run',
            'label': null,
            'value': null,
            'cd1': '0',
            'cd2': ' non-nullable ',
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'run',
            'time': isA<int>(),
            'category': 'commands',
            'label': null
          }
        }
      ]);
    });

    test('compile', () {
      final p = project(
          mainSrc: 'void main(List<String> args) => print(args);',
          logAnalytics: true);
      final result = p
          .runSync(['compile', 'kernel', 'lib/main.dart', '-o', 'main.kernel']);
      expect(extractAnalytics(result), [
        {
          'hitType': 'screenView',
          'message': {'viewName': 'compile/kernel'}
        },
        {
          'hitType': 'event',
          'message': {
            'category': 'dartdev',
            'action': 'compile/kernel',
            'label': null,
            'value': null,
            'cd1': '0',
            'cd3': ' output ',
          }
        },
        {
          'hitType': 'timing',
          'message': {
            'variableName': 'compile/kernel',
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
