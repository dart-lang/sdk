// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/analytics/google_analytics_manager.dart';
import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:telemetry/telemetry.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GoogleAnalyticsManagerTest);
  });
}

@reflectiveTest
class GoogleAnalyticsManagerTest {
  final analytics = _MockAnalytics();
  late final manager = GoogleAnalyticsManager(analytics);

  void test_plugin_request() {
    _defaultStartup();
    PluginManager.pluginResponseTimes[_MockPluginInfo('a')] = {
      'analysis.getNavigation': PercentileCalculator(),
    };
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.pluginRequest(parameters: {
        'pluginId': 'a',
        'method': 'analysis.getNavigation',
        'duration': _IsPercentiles(),
      }),
    ]);
    PluginManager.pluginResponseTimes.clear();
  }

  void test_server_notification() {
    _defaultStartup();
    manager.handledNotificationMessage(
        notification: NotificationMessage(
            clientRequestTime: 2,
            jsonrpc: '',
            method: Method.workspace_didCreateFiles),
        startTime: _now(),
        endTime: _now());
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.notification(parameters: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_didCreateFiles.toString(),
        'duration': _IsPercentiles(),
      }),
    ]);
  }

  void test_server_request() {
    _defaultStartup();
    manager.startedRequest(
        request: Request('1', 'server.shutdown'), startTime: _now());
    manager.sentResponse(response: Response('1'));
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': 'server.shutdown',
        'duration': _IsPercentiles(),
      }),
    ]);
  }

  void test_shutdownWithoutStartup() {
    manager.shutdown();
    analytics.assertNoEvents();
  }

  void test_startup_withoutVersion() {
    var arguments = ['a', 'b'];
    var clientId = 'clientId';
    var sdkVersion = 'sdkVersion';
    manager.startUp(
        time: DateTime.now(),
        arguments: arguments,
        clientId: clientId,
        clientVersion: null,
        sdkVersion: sdkVersion);
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(parameters: {
        'flags': arguments.join(' '),
        'clientId': clientId,
        'clientVersion': '',
        'sdkVersion': sdkVersion,
        'duration': _IsStringEncodedPositiveInt(),
      }),
    ]);
  }

  void test_startup_withPlugins() {
    _defaultStartup();
    manager.changedPlugins(_MockPluginManager(plugins: [
      _MockPluginInfo('a'),
      _MockPluginInfo('b'),
    ]));
    manager.shutdown();
    var counts =
        '{"count":1,"percentiles":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}';
    analytics.assertEvents([
      _ExpectedEvent.session(parameters: {
        'plugins': '{"recordCount":1,"rootCounts":{"a":$counts,"b":$counts}}'
      }),
    ]);
  }

  void test_startup_withVersion() {
    var arguments = ['a', 'b'];
    var clientId = 'clientId';
    var clientVersion = 'clientVersion';
    var sdkVersion = 'sdkVersion';
    manager.startUp(
        time: DateTime.now(),
        arguments: arguments,
        clientId: clientId,
        clientVersion: clientVersion,
        sdkVersion: sdkVersion);
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(parameters: {
        'flags': arguments.join(' '),
        'clientId': clientId,
        'clientVersion': clientVersion,
        '': isNull,
        'sdkVersion': sdkVersion,
        'duration': _IsStringEncodedPositiveInt(),
      }),
    ]);
  }

  void _defaultStartup() {
    manager.startUp(
        time: DateTime.now(),
        arguments: [],
        clientId: '',
        clientVersion: null,
        sdkVersion: '');
  }

  DateTime _now() => DateTime.now();
}

/// A record of an event that was reported to analytics.
class _Event {
  final String category;
  final String action;
  final String? label;
  final int? value;
  final Map<String, String>? parameters;

  _Event(this.category, this.action, this.label, this.value, this.parameters);
}

/// A record of an event that was reported to analytics.
class _ExpectedEvent {
  final String category;
  final String action;
  final String? label;
  final int? value;
  final Map<String, Object>? parameters;

  _ExpectedEvent(this.category, this.action,
      {this.label, // ignore: unused_element
      this.value, // ignore: unused_element
      this.parameters});

  _ExpectedEvent.notification({Map<String, Object>? parameters})
      : this('language_server', 'notification', parameters: parameters);

  _ExpectedEvent.pluginRequest({Map<String, Object>? parameters})
      : this('language_server', 'pluginRequest', parameters: parameters);

  _ExpectedEvent.request({Map<String, Object>? parameters})
      : this('language_server', 'request', parameters: parameters);

  _ExpectedEvent.session({Map<String, Object>? parameters})
      : this('language_server', 'session', parameters: parameters);

  /// Compare the expected event with the [actual] event, failing if the actual
  /// doesn't match the expected.
  void matches(_Event actual) {
    expect(actual.category, category);
    expect(actual.action, action);
    if (label != null) {
      expect(actual.label, label);
    }
    if (value != null) {
      expect(actual.value, value);
    }
    final actualParameters = actual.parameters;
    final expectedParameters = parameters;
    if (expectedParameters != null) {
      if (actualParameters == null) {
        fail('Expected parameters but found none');
      }
      for (var expectedKey in expectedParameters.keys) {
        var actualValue = actualParameters[expectedKey];
        var expectedValue = expectedParameters[expectedKey];
        expect(actualValue, expectedValue, reason: 'For key $expectedKey');
      }
    }
  }
}

/// A matcher for strings containing positive integer values.
class _IsPercentiles extends Matcher {
  const _IsPercentiles();

  @override
  Description describe(Description description) =>
      description.add('percentiles');

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! String) {
      return false;
    }
    var map = json.decode(item);
    if (map is! Map || map.length != 2) {
      return false;
    }
    if (map['count'] is! int) {
      return false;
    }
    var percentiles = map['percentiles'];
    if (percentiles is! List || percentiles.length != 20) {
      return false;
    }
    return !percentiles.any((element) => element is! int);
  }
}

/// A matcher for strings containing positive integer values.
class _IsStringEncodedPositiveInt extends Matcher {
  const _IsStringEncodedPositiveInt();

  @override
  Description describe(Description description) =>
      description.add('a string encoded positive integer');

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! String) {
      return false;
    }
    try {
      var value = int.parse(item);
      return value >= 0;
    } catch (exception) {
      return false;
    }
  }
}

/// An implementation of [Analytics] specialized for testing.
class _MockAnalytics implements Analytics {
  List<_Event> events = [];

  _MockAnalytics();

  void assertEvents(List<_ExpectedEvent> expectedEvents) {
    var expectedCount = expectedEvents.length;
    expect(events, hasLength(expectedCount));
    for (int i = 0; i < expectedCount; i++) {
      expectedEvents[i].matches(events[i]);
    }
  }

  void assertNoEvents() {
    expect(events, isEmpty);
  }

  @override
  void close() {
    // ignored
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future sendEvent(String category, String action,
      {String? label, int? value, Map<String, String>? parameters}) async {
    events.add(_Event(category, action, label, value, parameters));
  }

  @override
  Future waitForLastPing({Duration? timeout}) async {
    // ignored
  }
}

class _MockPluginInfo implements PluginInfo {
  @override
  String pluginId;

  _MockPluginInfo(this.pluginId);

  @override
  Set<analyzer.ContextRoot> get contextRoots => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPluginManager implements PluginManager {
  @override
  List<PluginInfo> plugins;

  _MockPluginManager({this.plugins = const []});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
