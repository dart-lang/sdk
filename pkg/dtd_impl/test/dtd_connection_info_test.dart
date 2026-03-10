// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dtd_impl/src/dtd_connection_info.dart';
import 'package:test/test.dart';

void main() {
  group('DTDConnectionInfo', () {
    test('fromJson parses correctly', () {
      final json = <String, Object?>{
        'wsUri': 'ws://127.0.0.1:12345/abc',
        'epoch': 1710000000000,
        'pid': 1234,
        'dartVersion': '3.4.0',
        'workspaceRoot': '/users/foo/workspace',
      };

      final info = DTDConnectionInfo.fromJson(json);

      expect(info.wsUri, 'ws://127.0.0.1:12345/abc');
      expect(info.epoch, 1710000000000);
      expect(info.pid, 1234);
      expect(info.dartVersion, '3.4.0');
      expect(info.workspaceRoot, '/users/foo/workspace');
    });

    test('fromJson handles missing values with fallbacks', () {
      final info = DTDConnectionInfo.fromJson(<String, Object?>{});

      expect(info.wsUri, '');
      expect(info.epoch, 0);
      expect(info.pid, 0);
      expect(info.dartVersion, '');
      expect(info.workspaceRoot, '');
    });

    test('toJson serializes correctly', () {
      final info = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: 1710000000000,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );

      final json = info.toJson();

      expect(json['wsUri'], 'ws://127.0.0.1:12345/abc');
      expect(json['epoch'], 1710000000000);
      expect(json['pid'], 1234);
      expect(json['dartVersion'], '3.4.0');
      expect(json['workspaceRoot'], '/users/foo/workspace');
    });

    test('toString formatting includes ago extension logic', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Test 5 minutes ago
      final info5m = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now - const Duration(minutes: 5).inMilliseconds,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(info5m.toString(), contains('5 minutes ago'));

      // Test 1 minute ago
      final info1m = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now - const Duration(minutes: 1).inMilliseconds,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(info1m.toString(), contains('1 minute ago'));

      // Test less than a minute ago
      final infoNow = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(infoNow.toString(), contains('less than a minute ago'));

      // Test hours ago
      final info2h = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now - const Duration(hours: 2).inMilliseconds,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(info2h.toString(), contains('2 hours ago'));

      // Test days ago
      final info2d = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now - const Duration(days: 2).inMilliseconds,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(info2d.toString(), contains('2 days ago'));

      // Test months ago
      final info2mo = DTDConnectionInfo(
        wsUri: 'ws://127.0.0.1:12345/abc',
        epoch: now - const Duration(days: 64).inMilliseconds,
        pid: 1234,
        dartVersion: '3.4.0',
        workspaceRoot: '/users/foo/workspace',
      );
      expect(info2mo.toString(), contains('2 months ago'));
    });
  });
}
