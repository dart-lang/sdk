// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:dwds/data/data_types.dart';
import 'package:dwds/data/debug_info.dart';
import 'package:dwds/data/devtools_request.dart';
import 'package:dwds/data/extension_request.dart';
import 'package:dwds/data/ping_request.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionRequest', () {
    test('serializes and deserializes', () {
      final request = ExtensionRequest(
        id: 1,
        command: 'command',
        commandParams: 'params',
      );
      final json = jsonEncode(request);
      final decoded = ExtensionRequest.fromJson(jsonDecode(json) as List);
      expect(decoded, request);
    });
  });

  group('ExtensionResponse', () {
    test('serializes and deserializes', () {
      final response = ExtensionResponse(
        id: 1,
        success: true,
        result: 'result',
        error: 'error',
      );
      final json = jsonEncode(response);
      final decoded = ExtensionResponse.fromJson(jsonDecode(json) as List);
      expect(decoded, response);
    });
  });

  group('ExtensionEvent', () {
    test('serializes and deserializes', () {
      final event = ExtensionEvent(method: 'method', params: 'params');
      final json = jsonEncode(event);
      final decoded = ExtensionEvent.fromJson(jsonDecode(json) as List);
      expect(decoded, event);
    });
  });

  group('BatchedEvents', () {
    test('serializes and deserializes', () {
      final event = ExtensionEvent(method: 'method', params: 'params');
      final batch = BatchedEvents(events: [event]);
      final json = jsonEncode(batch);
      final decoded = BatchedEvents.fromJson(jsonDecode(json) as List);
      expect(decoded, batch);
    });

    test('supports both standard and flat extension event wire formats', () {
      final jsonList = [
        'BatchedEvents',
        'events',
        [
          // Standard format with header
          ['ExtensionEvent', 'params', '{"foo":"bar"}', 'method', 'methodName'],
          // Flat format without header and params is a Map Object
          [
            'params',
            {'baz': 'qux'},
            'method',
            'anotherMethod',
          ],
        ],
      ];
      final decoded = BatchedEvents.fromJson(jsonList);
      expect(decoded.events.length, 2);
      expect(decoded.events[0].method, 'methodName');
      expect(decoded.events[0].params, '{"foo":"bar"}');
      expect(decoded.events[1].method, 'anotherMethod');
      expect(decoded.events[1].params, '{"baz":"qux"}');

      final json = jsonEncode(decoded);
      final reDecoded = BatchedEvents.fromJson(jsonDecode(json) as List);
      expect(reDecoded, decoded);
    });
  });

  group('DevToolsRequest', () {
    test('serializes and deserializes', () {
      final request = DevToolsRequest(
        appId: 'appId',
        instanceId: 'instanceId',
        contextId: 1,
        tabUrl: 'tabUrl',
        uriOnly: true,
        client: 'client',
      );
      final json = jsonEncode(request);
      final decoded = DevToolsRequest.fromJson(jsonDecode(json) as List);
      expect(decoded, request);
    });
  });

  group('DevToolsResponse', () {
    test('serializes and deserializes', () {
      final response = DevToolsResponse(
        success: true,
        promptExtension: true,
        error: 'error',
      );
      final json = jsonEncode(response);
      final decoded = DevToolsResponse.fromJson(jsonDecode(json) as List);
      expect(decoded, response);
    });
  });

  group('ConnectFailure', () {
    test('serializes and deserializes', () {
      final failure = ConnectFailure(tabId: 1, reason: 'reason');
      final json = jsonEncode(failure);
      final decoded = ConnectFailure.fromJson(jsonDecode(json) as List);
      expect(decoded, failure);
    });
  });

  group('DevToolsOpener', () {
    test('serializes and deserializes', () {
      final opener = DevToolsOpener(newWindow: true);
      final json = jsonEncode(opener);
      final decoded = DevToolsOpener.fromJson(jsonDecode(json) as List);
      expect(decoded, opener);
    });
  });

  group('DevToolsUrl', () {
    test('serializes and deserializes', () {
      final url = DevToolsUrl(tabId: 1, url: 'url');
      final json = jsonEncode(url);
      final decoded = DevToolsUrl.fromJson(jsonDecode(json) as List);
      expect(decoded, url);
    });
  });

  group('DebugStateChange', () {
    test('serializes and deserializes', () {
      final change = DebugStateChange(
        tabId: 1,
        newState: 'newState',
        reason: 'reason',
      );
      final json = jsonEncode(change);
      final decoded = DebugStateChange.fromJson(jsonDecode(json) as List);
      expect(decoded, change);
    });
  });

  group('DebugInfo', () {
    test('serializes and deserializes', () {
      final info = const DebugInfo(
        appEntrypointPath: 'appEntrypointPath',
        appId: 'appId',
        appInstanceId: 'appInstanceId',
        appOrigin: 'appOrigin',
        appUrl: 'appUrl',
        authUrl: 'authUrl',
        dwdsVersion: 'dwdsVersion',
        extensionUrl: 'extensionUrl',
        isInternalBuild: true,
        isFlutterApp: true,
        workspaceName: 'workspaceName',
        tabUrl: 'tabUrl',
        tabId: 1,
      );
      final json = jsonEncode(info);
      final decoded = DebugInfo.fromJson(jsonDecode(json) as List);
      expect(decoded, info);
    });
  });

  group('PingRequest', () {
    test('serializes and deserializes', () {
      final request = PingRequest();
      final json = jsonEncode(request);
      final decoded = PingRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      expect(decoded, request);
    });
  });
}
