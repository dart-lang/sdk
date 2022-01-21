// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analysis_server/src/utilities/progress.dart';
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
  late AnalysisServer server;

  /// Test that having multiple analysis contexts analyze the same file doesn't
  /// cause that file to receive duplicate notifications when it's modified.
  Future do_not_test_no_duplicate_notifications() async {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = {ServerService.STATUS};
    newFolder('/foo');
    newFolder('/bar');
    newFile('/foo/foo.dart', content: 'import "../bar/bar.dart";');
    var bar = newFile('/bar/bar.dart', content: 'library bar;');
    await server.setAnalysisRoots('0', ['/foo', '/bar'], []);
    var subscriptions = <AnalysisService, Set<String>>{};
    for (var service in AnalysisService.VALUES) {
      subscriptions[service] = <String>{bar.path};
    }
    // The following line causes the isolate to continue running even though the
    // test completes.
    server.setAnalysisSubscriptions(subscriptions);
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    channel.notificationsReceived.clear();
    server.updateContent(
        '0', {bar.path: AddContentOverlay('library bar; void f() {}')});
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    expect(channel.notificationsReceived, isNotEmpty);
    var notificationTypesReceived = <String>{};
    for (var notification in channel.notificationsReceived) {
      var notificationType = notification.event;
      switch (notificationType) {
        case 'server.status':
        case 'analysis.errors':
          // It's normal for these notifications to be sent multiple times.
          break;
        case 'analysis.outline':
          // It's normal for this notification to be sent twice.
          // TODO(paulberry): why?
          break;
        default:
          if (!notificationTypesReceived.add(notificationType)) {
            fail('Notification type $notificationType received more than once');
          }
          break;
      }
    }
  }

  void setUp() {
    channel = MockServerChannel();

    // Create an SDK in the mock file system.
    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    server = AnalysisServer(
        channel,
        resourceProvider,
        AnalysisServerOptions(),
        DartSdkManager(sdkRoot.path),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
  }

  /// Test that modifying package_config again while a context rebuild is in
  /// progress does not get lost due to a gap between creating a file watcher
  /// and it raising events.
  /// https://github.com/Dart-Code/Dart-Code/issues/3438
  Future test_concurrentContextRebuilds() async {
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
      content: r'''
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
    channel.notificationController.stream
        .where((notification) => notification.event == 'analysis.errors')
        .listen((notificaton) {
      final params = AnalysisErrorsParams.fromNotification(notificaton);
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
    config.add(name: 'foo', rootPath: fooLibFolder.parent2.path);
    writePackageConfig(projectPackageConfigFile, config);
    await pumpEventQueue(times: 1); // Allow server to begin processing.
    config.add(name: 'bar', rootPath: barLibFolder.parent2.path);
    writePackageConfig(projectPackageConfigFile, config);

    // Allow the server to catch up with everything.
    await pumpEventQueue(times: 5000);
    await server.onAnalysisComplete;

    // Expect both errors are gone.
    expect(await getUriNotExistErrors(), hasLength(0));
  }

  Future test_echo() {
    server.handlers = [EchoHandler(server)];
    var request = Request('my22', 'echo');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNull);
    });
  }

  Future test_serverStatusNotifications_hasFile() async {
    server.serverServices.add(ServerService.STATUS);

    newFile('/test/lib/a.dart', content: r'''
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

  Future test_serverStatusNotifications_noFiles() async {
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
    newFile(path);
    newAnalysisOptionsYamlFile('/project', content: r'''
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
    newFile(path);
    newAnalysisOptionsYamlFile('/project', content: r'''
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

  Future test_shutdown() {
    server.handlers = [ServerDomainHandler(server)];
    var request = Request('my28', SERVER_REQUEST_SHUTDOWN);
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my28'));
      expect(response.error, isNull);
    });
  }

  Future test_slowEcho_cancelled() async {
    server.handlers = [
      ServerDomainHandler(server),
      EchoHandler(server),
    ];
    // Send the normal request.
    var responseFuture = channel.sendRequest(Request('my22', 'slowEcho'));
    // Send a cancellation for it for waiting for it to complete.
    channel.sendRequest(
      Request(
        'my23',
        'server.cancelRequest',
        {'id': 'my22'},
      ),
    );
    var response = await responseFuture;
    expect(response.id, equals('my22'));
    expect(response.error, isNull);
    expect(response.result!['cancelled'], isTrue);
  }

  Future test_slowEcho_notCancelled() {
    server.handlers = [EchoHandler(server)];
    var request = Request('my22', 'slowEcho');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNull);
      expect(response.result!['cancelled'], isFalse);
    });
  }

  Future test_unknownRequest() {
    server.handlers = [EchoHandler(server)];
    var request = Request('my22', 'randomRequest');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNotNull);
    });
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(path, content: config.toContent(toUriStr: toUriStr));
  }

  /// Creates a simple package named [name] with [content] in the file at
  /// `package:$name/$name.dart`.
  ///
  /// Returns a [Folder] that represents the packages `lib` folder.
  Folder _addSimplePackage(String name, String content) {
    final packagePath = '/packages/$name';
    final file = newFile('$packagePath/lib/$name.dart', content: content);
    return file.parent2;
  }
}

class EchoHandler implements RequestHandler {
  final AnalysisServer server;

  EchoHandler(this.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    if (request.method == 'echo') {
      return Response(request.id, result: {'echo': true});
    } else if (request.method == 'slowEcho') {
      _slowEcho(request, cancellationToken);
      return Response.DELAYED_RESPONSE;
    }
    return null;
  }

  void _slowEcho(Request request, CancellationToken cancellationToken) async {
    for (var i = 0; i < 100; i++) {
      if (cancellationToken.isCancellationRequested) {
        server.sendResponse(Response(request.id, result: {'cancelled': true}));
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
    server.sendResponse(Response(request.id, result: {'cancelled': false}));
  }
}
