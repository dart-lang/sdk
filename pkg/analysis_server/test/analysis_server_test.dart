// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/analytics/noop_analytics.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisServerTest);
  });
}

@reflectiveTest
class AnalysisServerTest with ResourceProviderMixin {
  @override
  MemoryResourceProvider resourceProvider = MemoryResourceProvider(
    // Force the in-memory file watchers to be slowly initialized to emulate
    // the physical watchers (for test_concurrentContextRebuilds).
    delayWatcherInitialization: Duration(milliseconds: 1),
  );

  late MockServerChannel channel;
  late LegacyAnalysisServer server;

  void setUp() {
    channel = MockServerChannel();

    // Create an SDK in the mock file system.
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    server = LegacyAnalysisServer(
        channel,
        resourceProvider,
        AnalysisServerOptions(),
        DartSdkManager(sdkRoot.path),
        AnalyticsManager(NoopAnalytics()),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
  }

  /// See https://github.com/dart-lang/sdk/issues/50496
  Future<void> test_caching_mixin_superInvokedNames_setter_change() async {
    var lib = convertPath('/lib');
    newFolder(lib);
    var foo = newFile('/lib/foo.dart', '''
class A {
  set foo(int _) {}
}
mixin M on A {
  void bar() {
    super.boo = 0;
  }
}
class X extends A with M {}
''');
    await server.setAnalysisRoots('0', [lib], []);
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    channel.notificationsReceived.clear();

    server.updateContent('0', {
      foo.path: AddContentOverlay('''
class A {
  set foo(int _) {}
}
mixin M on A {
  void bar() {
    super.foo = 0;
  }
}
class X extends A with M {}
''')
    });
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    var notifications = channel.notificationsReceived;
    expect(notifications, hasLength(1));
    var notification = notifications.first;
    expect(notification.event, 'analysis.errors');
    var params = notification.params!;
    var errors = params['errors'] as List<Map<String, Object?>>;
    expect(errors, isEmpty);
  }

  /// Test that modifying package_config again while a context rebuild is in
  /// progress does not get lost due to a gap between creating a file watcher
  /// and it raising events.
  /// https://github.com/Dart-Code/Dart-Code/issues/3438
  Future<void> test_concurrentContextRebuilds() async {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = {ServerService.STATUS};
    final projectRoot = convertPath('/foo');
    final projectTestFile = convertPath('/foo/test.dart');
    final projectPackageConfigFile =
        convertPath('/foo/.dart_tool/package_config.json');

    // Create a file that references two packages, which will we write to
    // package_config.json individually.
    newFolder(projectRoot);
    newFile(
      projectTestFile,
      r'''
      import "package:foo/foo.dart";'
      import "package:bar/bar.dart";'
      ''',
    );

    // Ensure the packages and package_config exist.
    var fooLibFolder = _addSimplePackage('foo', '');
    var barLibFolder = _addSimplePackage('bar', '');
    final config = PackageConfigFileBuilder();
    writePackageConfig(projectPackageConfigFile, config);

    // Track diagnostics that arrive.
    final errorsByFile = <String, List<AnalysisError>>{};
    channel.notifications
        .where((notification) => notification.event == 'analysis.errors')
        .listen((notification) {
      final params = AnalysisErrorsParams.fromNotification(notification);
      errorsByFile[params.file] = params.errors;
    });

    /// Helper that waits for analysis then returns the relevant errors.
    Future<List<AnalysisError>> getUriNotExistErrors() async {
      await server.onAnalysisComplete;
      expect(server.statusAnalyzing, isFalse);
      return errorsByFile[projectTestFile]!
          .where((error) => error.code == 'uri_does_not_exist')
          .toList();
    }

    // Set roots and expect 2 uri_does_not_exist errors.
    await server.setAnalysisRoots('0', [projectRoot], []);
    expect(await getUriNotExistErrors(), hasLength(2));

    // Write both packages, in two events so that the first one will trigger
    // a rebuild.
    config.add(name: 'foo', rootPath: fooLibFolder.parent.path);
    writePackageConfig(projectPackageConfigFile, config);
    await pumpEventQueue(times: 1); // Allow server to begin processing.
    config.add(name: 'bar', rootPath: barLibFolder.parent.path);
    writePackageConfig(projectPackageConfigFile, config);

    // Allow the server to catch up with everything.
    await pumpEventQueue(times: 5000);
    await server.onAnalysisComplete;

    // Expect both errors are gone.
    expect(await getUriNotExistErrors(), hasLength(0));
  }

  Future<void> test_serverStatusNotifications_hasFile() async {
    server.serverServices.add(ServerService.STATUS);

    newFile('/test/lib/a.dart', r'''
class A {}
''');
    await server.setAnalysisRoots('0', [convertPath('/test')], []);

    // Pump the event queue, so that the server has finished any analysis.
    await pumpEventQueue(times: 5000);

    var notifications = channel.notificationsReceived;
    expect(notifications, isNotEmpty);

    // At least one notification indicating analysis is in progress.
    expect(notifications.any((Notification notification) {
      if (notification.event == SERVER_NOTIFICATION_STATUS) {
        var params = ServerStatusParams.fromNotification(notification);
        var analysis = params.analysis;
        if (analysis != null) {
          return analysis.isAnalyzing;
        }
      }
      return false;
    }), isTrue);

    // The last notification should indicate that analysis is complete.
    var notification = notifications[notifications.length - 1];
    var params = ServerStatusParams.fromNotification(notification);
    expect(params.analysis!.isAnalyzing, isFalse);
  }

  Future<void> test_serverStatusNotifications_noFiles() async {
    server.serverServices.add(ServerService.STATUS);

    newFolder('/test');
    await server.setAnalysisRoots('0', [convertPath('/test')], []);

    // Pump the event queue, so that the server has finished any analysis.
    await pumpEventQueue(times: 5000);

    var notifications = channel.notificationsReceived;
    expect(notifications, isNotEmpty);

    // At least one notification indicating analysis is in progress.
    expect(notifications.any((Notification notification) {
      if (notification.event == SERVER_NOTIFICATION_STATUS) {
        var params = ServerStatusParams.fromNotification(notification);
        var analysis = params.analysis;
        if (analysis != null) {
          return analysis.isAnalyzing;
        }
      }
      return false;
    }), isTrue);

    // The last notification should indicate that analysis is complete.
    var notification = notifications[notifications.length - 1];
    var params = ServerStatusParams.fromNotification(notification);
    expect(params.analysis!.isAnalyzing, isFalse);
  }

  Future<void>
      test_setAnalysisSubscriptions_fileInIgnoredFolder_newOptions() async {
    var path = convertPath('/project/samples/sample.dart');
    newFile(path, '');
    newAnalysisOptionsYamlFile('/project', r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    await server.setAnalysisRoots('0', [convertPath('/project')], []);
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: <String>{path}
    });

    // We respect subscriptions, even for excluded files.
    await pumpEventQueue(times: 5000);
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  Future<void>
      test_setAnalysisSubscriptions_fileInIgnoredFolder_oldOptions() async {
    var path = convertPath('/project/samples/sample.dart');
    newFile(path, '');
    newAnalysisOptionsYamlFile('/project', r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    await server.setAnalysisRoots('0', [convertPath('/project')], []);
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: <String>{path}
    });

    // We respect subscriptions, even for excluded files.
    await pumpEventQueue(times: 5000);
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NOTIFICATION_NAVIGATION;
    }), isTrue);
  }

  Future<void> test_shutdown() {
    var request = Request('my28', SERVER_REQUEST_SHUTDOWN);
    return channel.simulateRequestFromClient(request).then((Response response) {
      expect(response.id, equals('my28'));
      expect(response.error, isNull);
    });
  }

  Future<void> test_unknownRequest() {
    var request = Request('my22', 'randomRequest');
    return channel.simulateRequestFromClient(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNotNull);
    });
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, config.toContent(toUriStr: toUriStr));
  }

  /// Creates a simple package named [name] with [content] in the file at
  /// `package:$name/$name.dart`.
  ///
  /// Returns a [Folder] that represents the packages `lib` folder.
  Folder _addSimplePackage(String name, String content) {
    final packagePath = '/packages/$name';
    final file = newFile('$packagePath/lib/$name.dart', content);
    return file.parent;
  }
}
