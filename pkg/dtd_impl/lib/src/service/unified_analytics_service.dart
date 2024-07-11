// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:file/memory.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as path;
import 'package:unified_analytics/unified_analytics.dart';

import '../dtd_client.dart';
import 'internal_service.dart';

class UnifiedAnalyticsService extends InternalService {
  UnifiedAnalyticsService({bool fake = false}) : _useFake = fake;

  @override
  String get serviceName => 'UnifiedAnalytics';

  final bool _useFake;

  @override
  void register(DTDClient client) {
    client
      ..registerServiceMethod(
        serviceName,
        'getConsentMessage',
        _getConsentMessage,
      )
      ..registerServiceMethod(
        serviceName,
        'shouldShowMessage',
        _shouldShowMessage,
      )
      ..registerServiceMethod(
        serviceName,
        'clientShowedMessage',
        _clientShowedMessage,
      )
      ..registerServiceMethod(
        serviceName,
        'telemetryEnabled',
        _telemetryEnabled,
      )
      ..registerServiceMethod(
        serviceName,
        'setTelemetry',
        _setTelemetry,
      )
      ..registerServiceMethod(
        serviceName,
        'send',
        _send,
      );

    // If we are using fake analytics instances, register a method for listing
    // the fake events.
    if (_useFake) {
      client.registerServiceMethod(
        serviceName,
        'listFakeAnalyticsSentEvents',
        _listFakeAnalyticsSentEvents,
      );
    }
  }

  /// Contains an [Analytics] instance for each [DashTool] client that uses
  /// DTD to manage analytics.
  final _analyticsInstances = <DashTool, Analytics>{};

  Analytics _analyticsForTool(DashTool tool) {
    return _analyticsInstances.putIfAbsent(
      tool,
      () => _useFake
          ? _initializeFakeAnalytics(tool)
          : _initializeAnalytics(tool),
    );
  }

  Analytics _analyticsFromParams(Parameters parameters) {
    final tool = _extractTool(parameters);
    return _analyticsForTool(tool);
  }

  // DTD service implementations of methods from package:unified_analytics.

  Map<String, Object?> _getConsentMessage(Parameters parameters) {
    final analytics = _analyticsFromParams(parameters);
    final consentMessage = analytics.getConsentMessage;
    return StringResponse(consentMessage).toJson();
  }

  Map<String, Object?> _shouldShowMessage(Parameters parameters) {
    final analytics = _analyticsFromParams(parameters);
    final shouldShow = analytics.shouldShowMessage;
    return BoolResponse(shouldShow).toJson();
  }

  Map<String, Object?> _clientShowedMessage(Parameters parameters) {
    final analytics = _analyticsFromParams(parameters);
    analytics.clientShowedMessage();
    return Success().toJson();
  }

  Map<String, Object?> _telemetryEnabled(Parameters parameters) {
    final analytics = _analyticsFromParams(parameters);
    final enabled = analytics.telemetryEnabled;
    return BoolResponse(enabled).toJson();
  }

  Map<String, Object?> _setTelemetry(Parameters parameters) {
    final enable = parameters['enable'].asBool;
    final analytics = _analyticsFromParams(parameters);
    analytics.setTelemetry(enable);
    return Success().toJson();
  }

  Map<String, Object?> _send(Parameters parameters) {
    final event = parameters['event'].asString;
    final analytics = _analyticsFromParams(parameters);
    analytics.send(Event.fromJson(event)!);
    return Success().toJson();
  }

  DashTool _extractTool(Parameters parameters) {
    final toolString = parameters['tool'].asString;
    try {
      return DashTool.fromLabel(toolString);
    } catch (e) {
      throw RpcErrorCodes.buildRpcException(RpcErrorCodes.kInvalidParams);
    }
  }

  static String? _cachedDartVersion;
  static String? _cachedFlutterVersion;
  static String? _cachedFlutterChannel;

  /// Provides an instance of [Analytics] with the Dart SDK version, as well as
  /// the Flutter version and channel if the running dart executable is from the
  /// Flutter SDK.
  static Analytics _initializeAnalytics(DashTool tool) {
    // Use helper method from package:unified_analytics to return
    // a cleaned dart sdk verison
    final dartVersion =
        _cachedDartVersion ??= parseDartSDKVersion(Platform.version);

    if (_cachedFlutterChannel == null || _cachedFlutterVersion == null) {
      // The location for the dart executable in the following path
      //  /path/to/dart-sdk/bin/dart
      final dartExecutableFile = File(Platform.resolvedExecutable);

      // The flutter version file can also be found if we are running the
      // dart sdk that is shipped with flutter in the following path
      //  /path/to/flutter/bin/cache/dart-sdk/bin/dart
      final flutterVersionFile = File(
        path.join(
          dartExecutableFile.parent.path,
          '..',
          '..',
          'flutter.version.json',
        ),
      );

      // If the dart sdk being used is vendored with the flutter sdk, we can
      // expect this file to exist
      if (flutterVersionFile.existsSync()) {
        try {
          final flutterObj = jsonDecode(flutterVersionFile.readAsStringSync())
              as Map<String, Object?>;
          _cachedFlutterChannel = flutterObj['channel'] as String?;
          _cachedFlutterVersion = flutterObj['frameworkVersion'] as String?;
        } catch (_) {
          // Leave the flutter channel and version info null
        }
      }
    }

    return Analytics(
      tool: tool,
      dartVersion: dartVersion,
      // TODO(eliasyishak): pass this information (https://github.com/flutter/devtools/issues/7230)
      // clientIde: 'TBD',
      // These fields may be null if the Dart SDK being run is not the SDK
      // shipped with Flutter.
      flutterChannel: _cachedFlutterChannel,
      flutterVersion: _cachedFlutterVersion,
    );
  }

  /// Provides an instance of [FakeAnalytics] for use in tests.
  ///
  /// This is used when [UnifiedAnalyticsService._useFake] is true, which is
  /// determined based on the value of the
  /// [DartToolingDaemonOptions.fakeAnalytics] argument passed to DTD at
  /// startup. This flag is hidden by default, and should only be used from
  /// tests.
  ///
  /// The code to swap out real [Analytics] instances with [FakeAnalytics]
  /// instances must live in package:dtd_impl so that we can test the
  /// UnifiedAnalytics service calls from package:dtd.
  static Analytics _initializeFakeAnalytics(DashTool tool) {
    final fs = MemoryFileSystem.test();
    // Delete the directory and re-create it to ensure tests in package:dtd are
    // hermetic.
    final homeDirectory = fs.directory('/')
      ..deleteSync()
      ..createSync();
    final dartVersion = parseDartSDKVersion(Platform.version);

    FakeAnalytics createFakeAnalyticsHelper() {
      // ignore: invalid_use_of_visible_for_testing_member, fakes used for testing in package:dtd
      return Analytics.fake(
        tool: tool,
        homeDirectory: homeDirectory,
        dartVersion: dartVersion,
        fs: fs,
        enableAsserts: false,
      );
    }

    // An initial instance will first be created and will let
    // package:unified_analytics know that the consent message has been shown.
    // After confirming on the first instance, then a second instance will be
    // generated and returned. This second instance will be able to send events.
    createFakeAnalyticsHelper().clientShowedMessage();

    return createFakeAnalyticsHelper();
  }

  Map<String, Object?> _listFakeAnalyticsSentEvents(Parameters parameters) {
    final analytics = _analyticsFromParams(parameters) as FakeAnalytics;
    final events = analytics.sentEvents.map((e) => e.toString()).toList();
    return StringListResponse(events).toJson();
  }
}
