// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';

import 'mock_sdk.dart';
import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisServerTest);
  });
}

@reflectiveTest
class AnalysisServerTest {
  MockServerChannel channel;
  AnalysisServer server;
  MemoryResourceProvider resourceProvider;
  MockPackageMapProvider packageMapProvider;

  /**
   * Verify that getAnalysisContextForSource returns the correct contexts even
   * for sources that are included by multiple contexts.
   *
   * See dartbug.com/21898
   */
  Future fail_getAnalysisContextForSource_crossImports() {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = [ServerService.STATUS].toSet();
    // Analyze project foo containing foo.dart and project bar containing
    // bar.dart.
    resourceProvider.newFolder('/foo');
    resourceProvider.newFolder('/bar');
    File foo = resourceProvider.newFile(
        '/foo/foo.dart',
        '''
libary foo;
import "../bar/bar.dart";
''');
    Source fooSource = foo.createSource();
    File bar = resourceProvider.newFile(
        '/bar/bar.dart',
        '''
library bar;
import "../foo/foo.dart";
''');
    Source barSource = bar.createSource();
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    return server.onAnalysisComplete.then((_) {
      expect(server.statusAnalyzing, isFalse);
      // Make sure getAnalysisContext returns the proper context for each.
      AnalysisContext fooContext =
          server.getAnalysisContextForSource(fooSource);
      expect(fooContext, isNotNull);
      AnalysisContext barContext =
          server.getAnalysisContextForSource(barSource);
      expect(barContext, isNotNull);
      expect(fooContext, isNot(same(barContext)));
      expect(fooContext.getKindOf(fooSource), SourceKind.LIBRARY);
      expect(fooContext.getKindOf(barSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(fooSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(barSource), SourceKind.LIBRARY);
    });
  }

  /**
   * Verify that getAnalysisContextForSource returns the correct contexts even
   * for sources that haven't been analyzed yet.
   *
   * See dartbug.com/21898
   */
  Future fail_getAnalysisContextForSource_unanalyzed() {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = [ServerService.STATUS].toSet();
    // Analyze project foo containing foo.dart and project bar containing
    // bar.dart.
    resourceProvider.newFolder('/foo');
    resourceProvider.newFolder('/bar');
    File foo = resourceProvider.newFile('/foo/foo.dart', 'library lib;');
    Source fooSource = foo.createSource();
    File bar = resourceProvider.newFile('/bar/bar.dart', 'library lib;');
    Source barSource = bar.createSource();
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    AnalysisContext fooContext = server.getAnalysisContextForSource(fooSource);
    expect(fooContext, isNotNull);
    AnalysisContext barContext = server.getAnalysisContextForSource(barSource);
    expect(barContext, isNotNull);
    expect(fooContext, isNot(same(barContext)));
    return server.onAnalysisComplete.then((_) {
      expect(server.statusAnalyzing, isFalse);
      // Make sure getAnalysisContext returned the proper context for each.
      expect(fooContext.getKindOf(fooSource), SourceKind.LIBRARY);
      expect(fooContext.getKindOf(barSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(fooSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(barSource), SourceKind.LIBRARY);
    });
  }

  void processRequiredPlugins(ServerPlugin serverPlugin) {
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(serverPlugin);

    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
  }

  void setUp() {
    ServerPlugin serverPlugin = new ServerPlugin();
    processRequiredPlugins(serverPlugin);
    channel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    packageMapProvider = new MockPackageMapProvider();
    server = new AnalysisServer(
        channel,
        resourceProvider,
        packageMapProvider,
        null,
        serverPlugin,
        new AnalysisServerOptions(),
        new DartSdkManager('/', false),
        InstrumentationService.NULL_SERVICE,
        rethrowExceptions: true);
  }

  Future test_contextDisposed() {
    resourceProvider.newFolder('/foo');
    resourceProvider.newFile('/foo/bar.dart', 'library lib;');
    server.setAnalysisRoots('0', ['/foo'], [], {});
    AnalysisContext context;
    return pumpEventQueue()
        .then((_) {
          context = server.getAnalysisContext('/foo/bar.dart');
          server.setAnalysisRoots('1', [], [], {});
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(context.isDisposed, isTrue);
        });
  }

  Future test_contextsChangedEvent() {
    resourceProvider.newFolder('/foo');

    bool wasAdded = false;
    bool wasChanged = false;
    bool wasRemoved = false;
    server.onContextsChanged.listen((ContextsChangedEvent event) {
      wasAdded = event.added.length == 1;
      if (wasAdded) {
        expect(event.added[0], isNotNull);
      }
      wasChanged = event.changed.length == 1;
      if (wasChanged) {
        expect(event.changed[0], isNotNull);
      }
      wasRemoved = event.removed.length == 1;
      if (wasRemoved) {
        expect(event.removed[0], isNotNull);
      }
    });

    server.setAnalysisRoots('0', ['/foo'], [], {});
    return pumpEventQueue().then((_) {
      expect(wasAdded, isTrue);
      expect(wasChanged, isFalse);
      expect(wasRemoved, isFalse);

      wasAdded = false;
      wasChanged = false;
      wasRemoved = false;
      server.setAnalysisRoots('0', ['/foo'], [], {'/foo': '/bar'});
      return pumpEventQueue();
    }).then((_) {
      expect(wasAdded, isFalse);
      expect(wasChanged, isTrue);
      expect(wasRemoved, isFalse);

      wasAdded = false;
      wasChanged = false;
      wasRemoved = false;
      server.setAnalysisRoots('0', [], [], {});
      return pumpEventQueue();
    }).then((_) {
      expect(wasAdded, isFalse);
      expect(wasChanged, isFalse);
      expect(wasRemoved, isTrue);
    });
  }

  Future test_echo() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'echo');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNull);
    });
  }

  Future test_getAnalysisContextForSource() {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = [ServerService.STATUS].toSet();
    // Analyze project foo containing foo.dart and project bar containing
    // bar.dart.
    resourceProvider.newFolder('/foo');
    resourceProvider.newFolder('/bar');
    File foo = resourceProvider.newFile('/foo/foo.dart', 'library lib;');
    Source fooSource = foo.createSource();
    File bar = resourceProvider.newFile('/bar/bar.dart', 'library lib;');
    Source barSource = bar.createSource();
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    return server.onAnalysisComplete.then((_) {
      expect(server.statusAnalyzing, isFalse);
      // Make sure getAnalysisContext returns the proper context for each.
      AnalysisContext fooContext =
          server.getAnalysisContextForSource(fooSource);
      expect(fooContext, isNotNull);
      AnalysisContext barContext =
          server.getAnalysisContextForSource(barSource);
      expect(barContext, isNotNull);
      expect(fooContext, isNot(same(barContext)));
      expect(fooContext.getKindOf(fooSource), SourceKind.LIBRARY);
      expect(fooContext.getKindOf(barSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(fooSource), SourceKind.UNKNOWN);
      expect(barContext.getKindOf(barSource), SourceKind.LIBRARY);
    });
  }

  test_getContextSourcePair_nested() {
    String dir1Path = '/dir1';
    String dir2Path = dir1Path + '/dir2';
    String filePath = dir2Path + '/file.dart';
    resourceProvider.newFile('$dir1Path/.packages', '');
    resourceProvider.newFile('$dir2Path/.packages', '');
    resourceProvider.newFile(filePath, 'library lib;');
    // create contexts
    server.setAnalysisRoots('0', [dir1Path], [], {});
    // get pair
    ContextSourcePair pair = server.getContextSourcePair(filePath);
    _assertContextOfFolder(pair.context, dir2Path);
    Source source = pair.source;
    expect(source, isNotNull);
    expect(source.uri.scheme, 'file');
    expect(source.fullName, filePath);
  }

  test_getContextSourcePair_nonFile() {
    String dirPath = '/dir';
    Folder dir = resourceProvider.newFolder(dirPath);

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    _configureSourceFactory(context);
    server.folderMap[dir] = context;

    ContextSourcePair pair = server.getContextSourcePair(dirPath);
    expect(pair, isNotNull);
    expect(pair.context, isNull);
    expect(pair.source, isNull);
  }

  test_getContextSourcePair_simple() {
    String dirPath = '/dir';
    String filePath = dirPath + '/file.dart';
    resourceProvider.newFile(filePath, 'library lib;');
    // create contexts
    server.setAnalysisRoots('0', [dirPath], [], {});
    // get pair
    ContextSourcePair pair = server.getContextSourcePair(filePath);
    _assertContextOfFolder(pair.context, dirPath);
    Source source = pair.source;
    expect(source, isNotNull);
    expect(source.uri.scheme, 'file');
    expect(source.fullName, filePath);
  }

  test_getContextSourcePair_withPackagesFile() {
    String dirPath = '/dir';
    String packagesFilePath = dirPath + '/.packages';
    resourceProvider.newFile(packagesFilePath, 'dir:lib/');
    String filePath = dirPath + '/lib/file.dart';
    resourceProvider.newFile(filePath, 'library lib;');
    // create contexts
    server.setAnalysisRoots('0', [dirPath], [], {});
    // get pair
    ContextSourcePair pair = server.getContextSourcePair(filePath);
    _assertContextOfFolder(pair.context, dirPath);
    Source source = pair.source;
    expect(source, isNotNull);
    expect(source.uri.scheme, 'package');
    expect(source.fullName, filePath);
  }

  /**
   * Test that having multiple analysis contexts analyze the same file doesn't
   * cause that file to receive duplicate notifications when it's modified.
   */
  Future test_no_duplicate_notifications() async {
    // Subscribe to STATUS so we'll know when analysis is done.
    server.serverServices = [ServerService.STATUS].toSet();
    resourceProvider.newFolder('/foo');
    resourceProvider.newFolder('/bar');
    resourceProvider.newFile('/foo/foo.dart', 'import "../bar/bar.dart";');
    File bar = resourceProvider.newFile('/bar/bar.dart', 'library bar;');
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    Map<AnalysisService, Set<String>> subscriptions =
        <AnalysisService, Set<String>>{};
    for (AnalysisService service in AnalysisService.VALUES) {
      subscriptions[service] = <String>[bar.path].toSet();
    }
    server.setAnalysisSubscriptions(subscriptions);
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    channel.notificationsReceived.clear();
    server.updateContent(
        '0', {bar.path: new AddContentOverlay('library bar; void f() {}')});
    await server.onAnalysisComplete;
    expect(server.statusAnalyzing, isFalse);
    expect(channel.notificationsReceived, isNotEmpty);
    Set<String> notificationTypesReceived = new Set<String>();
    for (Notification notification in channel.notificationsReceived) {
      String notificationType = notification.event;
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

  test_operationsRemovedOnContextDisposal() async {
    resourceProvider.newFolder('/foo');
    resourceProvider.newFile('/foo/baz.dart', 'library lib;');
    resourceProvider.newFolder('/bar');
    resourceProvider.newFile('/bar/baz.dart', 'library lib;');
    server.setAnalysisRoots('0', ['/foo', '/bar'], [], {});
    await pumpEventQueue();
    AnalysisContext contextFoo = server.getAnalysisContext('/foo/baz.dart');
    AnalysisContext contextBar = server.getAnalysisContext('/bar/baz.dart');
    _MockServerOperation operationFoo = new _MockServerOperation(contextFoo);
    _MockServerOperation operationBar = new _MockServerOperation(contextBar);
    server.scheduleOperation(operationFoo);
    server.scheduleOperation(operationBar);
    server.setAnalysisRoots('1', ['/foo'], [], {});
    await pumpEventQueue();
    expect(operationFoo.isComplete, isTrue);
    expect(operationBar.isComplete, isFalse);
  }

  Future test_prioritySourcesChangedEvent() {
    resourceProvider.newFolder('/foo');

    int eventCount = 0;
    Source firstSource = null;
    server.onPriorityChange.listen((PriorityChangeEvent event) {
      ++eventCount;
      firstSource = event.firstSource;
    });

    server.setAnalysisRoots('0', ['/foo'], [], {});
    return pumpEventQueue().then((_) {
      expect(eventCount, 0);

      server.setPriorityFiles('1', ['/foo/bar.dart']);
      return pumpEventQueue();
    }).then((_) {
      expect(eventCount, 1);
      expect(firstSource.fullName, '/foo/bar.dart');

      server.setPriorityFiles('2', ['/foo/b1.dart', '/foo/b2.dart']);
      return pumpEventQueue();
    }).then((_) {
      expect(eventCount, 2);
      expect(firstSource.fullName, '/foo/b1.dart');

      server.setPriorityFiles('17', []);
      return pumpEventQueue();
    }).then((_) {
      expect(eventCount, 3);
      expect(firstSource, isNull);
    });
  }

  void test_rethrowExceptions() {
    Exception exceptionToThrow = new Exception('test exception');
    MockServerOperation operation =
        new MockServerOperation(ServerOperationPriority.ANALYSIS, (_) {
      throw exceptionToThrow;
    });
    server.operationQueue.add(operation);
    server.performOperationPending = true;
    try {
      server.performOperation();
      fail('exception not rethrown');
    } on AnalysisException catch (exception) {
      expect(exception.cause.exception, equals(exceptionToThrow));
    }
  }

  Future test_serverStatusNotifications() {
    MockAnalysisContext context = new MockAnalysisContext('context');
    MockSource source = new MockSource('source');
    when(source.fullName).thenReturn('foo.dart');
    when(source.isInSystemLibrary).thenReturn(false);
    ChangeNoticeImpl notice = new ChangeNoticeImpl(source);
    notice.setErrors([], new LineInfo([0]));
    AnalysisResult firstResult = new AnalysisResult([notice], 0, '', 0);
    AnalysisResult lastResult = new AnalysisResult(null, 1, '', 1);
    when(context.analysisOptions).thenReturn(new AnalysisOptionsImpl());
    when(context.performAnalysisTask)
        .thenReturnList([firstResult, firstResult, firstResult, lastResult]);
    server.serverServices.add(ServerService.STATUS);
    server.schedulePerformAnalysisOperation(context);
    // Pump the event queue to make sure the server has finished any
    // analysis.
    return pumpEventQueue().then((_) {
      List<Notification> notifications = channel.notificationsReceived;
      expect(notifications, isNotEmpty);
      // expect at least one notification indicating analysis is in progress
      expect(notifications.any((Notification notification) {
        if (notification.event == SERVER_STATUS) {
          var params = new ServerStatusParams.fromNotification(notification);
          return params.analysis.isAnalyzing;
        }
        return false;
      }), isTrue);
      // the last notification should indicate that analysis is complete
      Notification notification = notifications[notifications.length - 1];
      var params = new ServerStatusParams.fromNotification(notification);
      expect(params.analysis.isAnalyzing, isFalse);
    });
  }

  test_setAnalysisSubscriptions_fileInIgnoredFolder_newOptions() async {
    String path = '/project/samples/sample.dart';
    resourceProvider.newFile(path, '');
    resourceProvider.newFile(
        '/project/analysis_options.yaml',
        r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', ['/project'], [], {});
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: new Set<String>.from([path])
    });
    // the file is excluded, so no navigation notification
    await server.onAnalysisComplete;
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NAVIGATION;
    }), isFalse);
  }

  test_setAnalysisSubscriptions_fileInIgnoredFolder_oldOptions() async {
    String path = '/project/samples/sample.dart';
    resourceProvider.newFile(path, '');
    resourceProvider.newFile(
        '/project/.analysis_options',
        r'''
analyzer:
  exclude:
    - 'samples/**'
''');
    server.setAnalysisRoots('0', ['/project'], [], {});
    server.setAnalysisSubscriptions(<AnalysisService, Set<String>>{
      AnalysisService.NAVIGATION: new Set<String>.from([path])
    });
    // the file is excluded, so no navigation notification
    await server.onAnalysisComplete;
    expect(channel.notificationsReceived.any((notification) {
      return notification.event == ANALYSIS_NAVIGATION;
    }), isFalse);
  }

  Future test_shutdown() {
    server.handlers = [new ServerDomainHandler(server)];
    var request = new Request('my28', SERVER_SHUTDOWN);
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my28'));
      expect(response.error, isNull);
    });
  }

  Future test_unknownRequest() {
    server.handlers = [new EchoHandler()];
    var request = new Request('my22', 'randomRequest');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('my22'));
      expect(response.error, isNotNull);
    });
  }

  void _assertContextOfFolder(
      AnalysisContext context, String expectedFolderPath) {
    Folder expectedFolder = resourceProvider.newFolder(expectedFolderPath);
    ContextInfo expectedContextInfo =
        (server.contextManager as ContextManagerImpl)
            .getContextInfoFor(expectedFolder);
    expect(expectedContextInfo, isNotNull);
    expect(context, same(expectedContextInfo.context));
  }

  void _configureSourceFactory(AnalysisContext context) {
    var resourceUriResolver = new ResourceUriResolver(resourceProvider);
    var packageUriResolver = new PackageMapUriResolver(
        resourceProvider, packageMapProvider.packageMap);
    context.sourceFactory =
        new SourceFactory([packageUriResolver, resourceUriResolver]);
  }
}

class EchoHandler implements RequestHandler {
  @override
  Response handleRequest(Request request) {
    if (request.method == 'echo') {
      return new Response(request.id, result: {'echo': true});
    }
    return null;
  }
}

/**
 * A [ServerOperation] that does nothing but keep track of whether or not it
 * has been performed.
 */
class _MockServerOperation implements ServerOperation {
  final AnalysisContext context;
  bool isComplete = false;

  _MockServerOperation(this.context);

  @override
  ServerOperationPriority get priority => ServerOperationPriority.ANALYSIS;

  @override
  void perform(AnalysisServer server) {
    isComplete = true;
  }
}
