// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart' as analyzer;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:http/src/response.dart' as http;
import 'package:linter/src/rules.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unified_analytics/src/enums.dart';
import 'package:unified_analytics/unified_analytics.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyticsManagerTest);
  });
}

@reflectiveTest
class AnalyticsManagerTest with ResourceProviderMixin {
  final analytics = _MockAnalytics();
  late final manager = AnalyticsManager(analytics);

  Folder get testPackageRoot => getFolder('/home/package');

  String get testPackageRootPath => testPackageRoot.path;

  DateTime get _startUpTime => DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch - 5);

  Future<void> test_createAnalysisContexts_lints() async {
    _createAnalysisOptionsFile(lints: [
      'avoid_dynamic_calls',
      'await_only_futures',
      'unawaited_futures'
    ]);
    var collection = _createContexts();
    _defaultStartup();
    manager.createdAnalysisContexts(collection.contexts);
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.lintUsageCount(eventData: {
        'count': 1,
        'name': 'avoid_dynamic_calls',
      }),
      _ExpectedEvent.lintUsageCount(eventData: {
        'count': 1,
        'name': 'await_only_futures',
      }),
      _ExpectedEvent.lintUsageCount(eventData: {
        'count': 1,
        'name': 'unawaited_futures',
      }),
    ]);
  }

  Future<void> test_createAnalysisContexts_severityAdjustments() async {
    _createAnalysisOptionsFile(errors: {
      'avoid_dynamic_calls': 'error',
      'await_only_futures': 'ignore',
    });
    var collection = _createContexts();
    _defaultStartup();
    manager.createdAnalysisContexts(collection.contexts);
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.severityAdjustment(eventData: {
        'diagnostic': 'AVOID_DYNAMIC_CALLS',
        'adjustments': '{"ERROR":1}',
      }),
      _ExpectedEvent.severityAdjustment(eventData: {
        'diagnostic': 'AWAIT_ONLY_FUTURES',
        'adjustments': '{"ignore":1}',
      }),
    ]);
  }

  Future<void> test_plugin_request() async {
    _defaultStartup();
    PluginManager.pluginResponseTimes[_pluginInfo('a')] = {
      'analysis.getNavigation': PercentileCalculator(),
    };
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.pluginRequest(eventData: {
        'pluginId': 'a',
        'method': 'analysis.getNavigation',
        'duration': _IsPercentiles(),
      }),
    ]);
    PluginManager.pluginResponseTimes.clear();
  }

  Future<void> test_server_notification() async {
    _defaultStartup();
    manager.handledNotificationMessage(
        notification: NotificationMessage(
            clientRequestTime: 2,
            jsonrpc: '',
            method: Method.workspace_didCreateFiles),
        startTime: _now(),
        endTime: _now());
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.notification(eventData: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_didCreateFiles.toString(),
        'duration': _IsPercentiles(),
      }),
    ]);
  }

  Future<void> test_server_request_analysisDidChangeWorkspaceFolders() async {
    _defaultStartup();
    var params = DidChangeWorkspaceFoldersParams(
        event: WorkspaceFoldersChangeEvent(added: [], removed: []));
    var request = RequestMessage(
        jsonrpc: '',
        id: Either2.t1(1),
        method: Method.workspace_didChangeWorkspaceFolders,
        params: params.toJson());
    manager.startedRequestMessage(request: request, startTime: _now());
    manager
        .changedWorkspaceFolders(added: ['a', 'b', 'c'], removed: ['d', 'e']);
    manager.sentResponseMessage(
        response: ResponseMessage(jsonrpc: '', id: Either2.t1(1)));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_didChangeWorkspaceFolders.toString(),
        'duration': _IsPercentiles(),
        'added': '{"count":1,"percentiles":[3,3,3,3,3]}',
        'removed': '{"count":1,"percentiles":[2,2,2,2,2]}',
      }),
    ]);
  }

  Future<void> test_server_request_analysisSetAnalysisRoots() async {
    _defaultStartup();
    var params = AnalysisSetAnalysisRootsParams(['a', 'b', 'c'], ['d', 'e']);
    var request =
        Request('1', ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedSetAnalysisRoots(params);
    manager.sentResponse(response: Response('1'));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        'duration': _IsPercentiles(),
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_INCLUDED:
            '{"count":1,"percentiles":[3,3,3,3,3]}',
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_EXCLUDED:
            '{"count":1,"percentiles":[2,2,2,2,2]}',
      }),
    ]);
  }

  Future<void> test_server_request_analysisSetPriorityFiles() async {
    _defaultStartup();
    var params = AnalysisSetPriorityFilesParams(['a']);
    var request =
        Request('1', ANALYSIS_REQUEST_SET_PRIORITY_FILES, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedSetPriorityFiles(params);
    manager.sentResponse(response: Response('1'));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': ANALYSIS_REQUEST_SET_PRIORITY_FILES,
        'duration': _IsPercentiles(),
        ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES:
            '{"count":1,"percentiles":[1,1,1,1,1]}',
      }),
    ]);
  }

  @FailingTest(reason: 'We are currently unable to send refactoring events')
  Future<void> test_server_request_editGetRefactoring() async {
    _defaultStartup();
    var params =
        EditGetRefactoringParams(RefactoringKind.RENAME, '', 0, 0, true);
    var request = Request('1', EDIT_REQUEST_GET_REFACTORING, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedGetRefactoring(params);
    manager.sentResponse(response: Response('1'));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': EDIT_REQUEST_GET_REFACTORING,
        'duration': _IsPercentiles(),
        EDIT_REQUEST_GET_REFACTORING_KIND: '{"RENAME":1}',
      }),
    ]);
  }

  Future<void> test_server_request_initialize() async {
    _defaultStartup();
    var params = InitializeParams(
        capabilities: ClientCapabilities(),
        initializationOptions: {
          'closingLabels': true,
          'notAnOption': true,
          'onlyAnalyzeProjectsWithOpenFiles': true,
        });
    manager.initialize(params);
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(eventData: {
        'parameters':
            'closingLabels,onlyAnalyzeProjectsWithOpenFiles,suggestFromUnimportedLibraries',
      }),
    ]);
  }

  Future<void> test_server_request_initialized() async {
    _defaultStartup();
    var params = InitializedParams();
    var request = RequestMessage(
        jsonrpc: '',
        id: Either2.t1(1),
        method: Method.initialized,
        params: params.toJson());
    manager.startedRequestMessage(request: request, startTime: _now());
    manager.initialized(openWorkspacePaths: ['a', 'b', 'c']);
    manager.sentResponseMessage(
        response: ResponseMessage(jsonrpc: '', id: Either2.t1(1)));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': Method.initialized.toString(),
        'duration': _IsPercentiles(),
        'openWorkspacePaths': '{"count":1,"percentiles":[3,3,3,3,3]}',
      }),
    ]);
  }

  Future<void> test_server_request_noAdditional() async {
    _defaultStartup();
    manager.startedRequest(
        request: Request('1', SERVER_REQUEST_SHUTDOWN), startTime: _now());
    manager.sentResponse(response: Response('1'));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': SERVER_REQUEST_SHUTDOWN,
        'duration': _IsPercentiles(),
      }),
    ]);
  }

  Future<void> test_server_request_workspaceExecuteCommand() async {
    _defaultStartup();
    var params = ExecuteCommandParams(command: 'doIt');
    var request = RequestMessage(
        jsonrpc: '',
        id: Either2.t1(1),
        method: Method.workspace_executeCommand,
        params: params.toJson());
    manager.startedRequestMessage(request: request, startTime: _now());
    manager.executedCommand('doIt');
    manager.executedCommand('doIt');
    manager.sentResponseMessage(
        response: ResponseMessage(jsonrpc: '', id: Either2.t1(1)));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(eventData: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_executeCommand.toString(),
        'duration': _IsPercentiles(),
      }),
      _ExpectedEvent.commandExecuted(eventData: {
        'name': 'doIt',
        'count': 2,
      }),
    ]);
  }

  Future<void> test_shutdownWithoutStartup() async {
    await manager.shutdown();
    analytics.assertNoEvents();
  }

  Future<void> test_startup_withoutVersion() async {
    var arguments = ['a', 'b'];
    var clientId = 'clientId';
    manager.startUp(
        time: _startUpTime,
        arguments: arguments,
        clientId: clientId,
        clientVersion: null);
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(eventData: {
        'flags': arguments.join(','),
        'clientId': clientId,
        'clientVersion': '',
        'duration': _IsPositiveInt(),
      }),
    ]);
  }

  Future<void> test_startup_withPlugins() async {
    _defaultStartup();
    manager.changedPlugins(_MockPluginManager(plugins: [
      _pluginInfo('a'),
      _pluginInfo('b'),
    ]));
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(eventData: {}),
      _ExpectedEvent.pluginUse(eventData: {
        'count': 1,
        'pluginId': 'a',
        'enabled': _IsPercentiles(),
      }),
      _ExpectedEvent.pluginUse(eventData: {
        'count': 1,
        'pluginId': 'b',
        'enabled': _IsPercentiles(),
      }),
    ]);
  }

  Future<void> test_startup_withVersion() async {
    var arguments = ['a', 'b'];
    var clientId = 'clientId';
    var clientVersion = 'clientVersion';
    manager.startUp(
        time: _startUpTime,
        arguments: arguments,
        clientId: clientId,
        clientVersion: clientVersion);
    await manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(eventData: {
        'flags': arguments.join(','),
        'clientId': clientId,
        'clientVersion': clientVersion,
        'duration': _IsPositiveInt(),
      }),
    ]);
  }

  /// Create an analysis options file based on the given arguments.
  void _createAnalysisOptionsFile({
    String? path,
    Map<String, String>? errors,
    List<String>? experiments,
    List<String>? lints,
  }) {
    path ??= '$testPackageRootPath/analysis_options.yaml';
    var buffer = StringBuffer();

    if (errors != null || experiments != null) {
      buffer.writeln('analyzer:');
    }

    if (errors != null) {
      buffer.writeln('  errors:');
      for (var entry in errors.entries) {
        buffer.writeln('    ${entry.key}: ${entry.value}');
      }
    }

    if (experiments != null) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }

    if (lints != null) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    newFile(path, buffer.toString());
  }

  AnalysisContextCollection _createContexts() {
    var sdkRoot = getFolder('/sdk');
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);
    registerLintRules();
    return AnalysisContextCollection(
        resourceProvider: resourceProvider,
        includedPaths: [testPackageRootPath],
        sdkPath: sdkRoot.path);
  }

  void _defaultStartup() {
    manager.startUp(
        time: DateTime.now(), arguments: [], clientId: '', clientVersion: null);
  }

  DateTime _now() => DateTime.now();

  _MockPluginInfo _pluginInfo(String name) => _MockPluginInfo(
      path.join('.pub-cache', 'pub.dev', name, 'tools', 'analyzer_plugin'));
}

/// A record of an event that was reported to analytics.
class _ExpectedEvent {
  final DashEvent eventName;
  final Map<String, Object?>? eventData;

  _ExpectedEvent(this.eventName, this.eventData);

  _ExpectedEvent.commandExecuted({Map<String, Object?>? eventData})
      : this(DashEvent.commandExecuted, eventData);

  _ExpectedEvent.lintUsageCount({Map<String, Object?>? eventData})
      : this(DashEvent.lintUsageCount, eventData);

  _ExpectedEvent.notification({Map<String, Object?>? eventData})
      : this(DashEvent.clientNotification, eventData);

  _ExpectedEvent.pluginRequest({Map<String, Object?>? eventData})
      : this(DashEvent.pluginRequest, eventData);

  _ExpectedEvent.pluginUse({Map<String, Object?>? eventData})
      : this(DashEvent.pluginUse, eventData);

  _ExpectedEvent.request({Map<String, Object?>? eventData})
      : this(DashEvent.clientRequest, eventData);

  _ExpectedEvent.session({Map<String, Object?>? eventData})
      : this(DashEvent.serverSession, eventData);

  _ExpectedEvent.severityAdjustment({Map<String, Object?>? eventData})
      : this(DashEvent.severityAdjustment, eventData);

  /// Compare the expected event with the [actual] event, failing if the actual
  /// doesn't match the expected.
  void matches(Event actual) {
    expect(actual.eventName, eventName);
    final actualData = actual.eventData;
    final expectedData = eventData;
    if (expectedData != null) {
      for (var expectedKey in expectedData.keys) {
        var actualValue = actualData[expectedKey];
        var expectedValue = expectedData[expectedKey];
        if (!(actualValue == expectedValue ||
            (expectedValue is Matcher &&
                expectedValue.matches(actualValue, {})))) {
          var buffer = StringBuffer();
          buffer.writeln('Incorrect event data.');
          buffer.writeln('Expected:');
          writeMap(buffer, expectedData);
          buffer.writeln('Actual:');
          writeMap(buffer, actualData);
          fail(buffer.toString());
        }
        expect(actualValue, expectedValue, reason: 'For key $expectedKey');
      }
    }
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write('eventData: ');
    buffer.writeln(eventData);
    var data = eventData;
    if (data != null) {
      for (var entry in data.entries) {
        buffer.write('value: ');
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }

  void writeMap(StringBuffer buffer, Map<String, Object?> map) {
    for (var entry in map.entries) {
      buffer.write('  ');
      buffer.write(entry.key);
      buffer.write(': ');
      buffer.writeln(entry.value);
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
  bool matches(Object? item, Map<Object?, Object?> matchState) {
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
    if (percentiles is! List || percentiles.length != 5) {
      return false;
    }
    return !percentiles.any((element) => element is! int);
  }
}

/// A matcher for strings containing positive integer values.
class _IsPositiveInt extends Matcher {
  const _IsPositiveInt();

  @override
  Description describe(Description description) =>
      description.add('a positive integer');

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    return item is int && item >= 0;
  }
}

/// An implementation of [Analytics] specialized for testing.
class _MockAnalytics implements NoOpAnalytics {
  List<Event> events = [];

  _MockAnalytics();

  @override
  Map<String, ToolInfo> get parsedTools => throw UnimplementedError();

  @override
  bool get shouldShowMessage => false;

  @override
  bool get telemetryEnabled => false;

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
    // Ignored
  }

  @override
  LogFileStats? logFileStats() {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<http.Response>? send(Event event) async {
    events.add(event);
    return http.Response('', 200);
  }

  @override
  void suppressTelemetry() {}
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
