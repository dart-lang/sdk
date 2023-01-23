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
import 'package:linter/src/rules.dart';
import 'package:telemetry/telemetry.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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

  void test_createAnalysisContexts_lints() {
    _createAnalysisOptionsFile(lints: [
      'avoid_dynamic_calls',
      'await_only_futures',
      'unawaited_futures'
    ]);
    var collection = _createContexts();
    _defaultStartup();
    manager.createdAnalysisContexts(collection.contexts);
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.lintUsageCounts(parameters: {
        'usageCounts':
            '{"avoid_dynamic_calls":1,"await_only_futures":1,"unawaited_futures":1}',
      }),
    ]);
  }

  void test_createAnalysisContexts_severityAdjustments() {
    _createAnalysisOptionsFile(errors: {
      'avoid_dynamic_calls': 'error',
      'await_only_futures': 'ignore',
    });
    var collection = _createContexts();
    _defaultStartup();
    manager.createdAnalysisContexts(collection.contexts);
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.severityAdjustments(parameters: {
        'adjustmentCounts':
            '{"AVOID_DYNAMIC_CALLS":{"ERROR":1},"AWAIT_ONLY_FUTURES":{"ignore":1}}',
      }),
    ]);
  }

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

  void test_server_request_analysisDidChangeWorkspaceFolders() {
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
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_didChangeWorkspaceFolders.toString(),
        'duration': _IsPercentiles(),
        'added':
            '{"count":1,"percentiles":[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]}',
        'removed':
            '{"count":1,"percentiles":[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]}',
      }),
    ]);
  }

  void test_server_request_analysisSetAnalysisRoots() {
    _defaultStartup();
    var params = AnalysisSetAnalysisRootsParams(['a', 'b', 'c'], ['d', 'e']);
    var request =
        Request('1', ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedSetAnalysisRoots(params);
    manager.sentResponse(response: Response('1'));
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        'duration': _IsPercentiles(),
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_INCLUDED:
            '{"count":1,"percentiles":[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]}',
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_EXCLUDED:
            '{"count":1,"percentiles":[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]}',
      }),
    ]);
  }

  void test_server_request_analysisSetPriorityFiles() {
    _defaultStartup();
    var params = AnalysisSetPriorityFilesParams(['a']);
    var request =
        Request('1', ANALYSIS_REQUEST_SET_PRIORITY_FILES, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedSetPriorityFiles(params);
    manager.sentResponse(response: Response('1'));
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': ANALYSIS_REQUEST_SET_PRIORITY_FILES,
        'duration': _IsPercentiles(),
        ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES:
            '{"count":1,"percentiles":[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]}',
      }),
    ]);
  }

  void test_server_request_editGetRefactoring() {
    _defaultStartup();
    var params =
        EditGetRefactoringParams(RefactoringKind.RENAME, '', 0, 0, true);
    var request = Request('1', EDIT_REQUEST_GET_REFACTORING, params.toJson());
    manager.startedRequest(request: request, startTime: _now());
    manager.startedGetRefactoring(params);
    manager.sentResponse(response: Response('1'));
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': EDIT_REQUEST_GET_REFACTORING,
        'duration': _IsPercentiles(),
        EDIT_REQUEST_GET_REFACTORING_KIND: '{"RENAME":1}',
      }),
    ]);
  }

  void test_server_request_initialize() {
    _defaultStartup();
    var params = InitializeParams(
        capabilities: ClientCapabilities(),
        initializationOptions: {
          'closingLabels': true,
          'notAnOption': true,
          'onlyAnalyzeProjectsWithOpenFiles': true,
        });
    manager.initialize(params);
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(parameters: {
        'parameters':
            'closingLabels,onlyAnalyzeProjectsWithOpenFiles,suggestFromUnimportedLibraries',
      }),
    ]);
  }

  void test_server_request_initialized() {
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
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': Method.initialized.toString(),
        'duration': _IsPercentiles(),
        'openWorkspacePaths':
            '{"count":1,"percentiles":[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3]}',
      }),
    ]);
  }

  void test_server_request_noAdditional() {
    _defaultStartup();
    manager.startedRequest(
        request: Request('1', SERVER_REQUEST_SHUTDOWN), startTime: _now());
    manager.sentResponse(response: Response('1'));
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': SERVER_REQUEST_SHUTDOWN,
        'duration': _IsPercentiles(),
      }),
    ]);
  }

  void test_server_request_workspaceExecuteCommand() {
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
    manager.shutdown();
    analytics.assertEvents([
      _ExpectedEvent.session(),
      _ExpectedEvent.request(parameters: {
        'latency': _IsPercentiles(),
        'method': Method.workspace_executeCommand.toString(),
        'duration': _IsPercentiles(),
        'command': '{"doIt":2}'
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
        'flags': arguments.join(','),
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
        'flags': arguments.join(','),
        'clientId': clientId,
        'clientVersion': clientVersion,
        '': isNull,
        'sdkVersion': sdkVersion,
        'duration': _IsStringEncodedPositiveInt(),
      }),
    ]);
  }

  /// Create an analysis options file based on the given arguments.
  void _createAnalysisOptionsFile({
    String? path,
    Map<String, String>? errors,
    List<String>? experiments,
    bool? implicitCasts,
    List<String>? lints,
  }) {
    path ??= '$testPackageRootPath/analysis_options.yaml';
    var buffer = StringBuffer();

    if (errors != null || experiments != null || implicitCasts != null) {
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

    if (implicitCasts != null) {
      buffer.writeln('  strong-mode:');
      buffer.writeln('    implicit-casts: $implicitCasts');
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

  _ExpectedEvent.lintUsageCounts({Map<String, Object>? parameters})
      : this('language_server', 'lintUsageCounts', parameters: parameters);

  _ExpectedEvent.notification({Map<String, Object>? parameters})
      : this('language_server', 'notification', parameters: parameters);

  _ExpectedEvent.pluginRequest({Map<String, Object>? parameters})
      : this('language_server', 'pluginRequest', parameters: parameters);

  _ExpectedEvent.request({Map<String, Object>? parameters})
      : this('language_server', 'request', parameters: parameters);

  _ExpectedEvent.session({Map<String, Object>? parameters})
      : this('language_server', 'session', parameters: parameters);

  _ExpectedEvent.severityAdjustments({Map<String, Object>? parameters})
      : this('language_server', 'severityAdjustments', parameters: parameters);

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

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write('category: ');
    buffer.writeln(category);
    buffer.write('action: ');
    buffer.writeln(action);
    buffer.write('label: ');
    buffer.writeln(label);
    buffer.write('value: ');
    buffer.writeln(value);
    var parameterMap = parameters;
    if (parameterMap != null) {
      for (var entry in parameterMap.entries) {
        buffer.write('value: ');
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
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
