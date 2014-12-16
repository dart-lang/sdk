// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis_server;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/operation/operation.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import 'mock_sdk.dart';
import 'mocks.dart';
import 'reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisServerTest);
}

@ReflectiveTestCase()
class AnalysisServerTest {
  MockServerChannel channel;
  AnalysisServer server;
  MemoryResourceProvider resourceProvider;

  void setUp() {
    channel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        channel,
        resourceProvider,
        new MockPackageMapProvider(),
        null,
        new AnalysisServerOptions(),
        new MockSdk(),
        InstrumentationService.NULL_SERVICE,
        rethrowExceptions: true);
  }

  Future test_contextDisposed() {
    resourceProvider.newFolder('/foo');
    resourceProvider.newFile('/foo/bar.dart', 'library lib;');
    server.setAnalysisRoots('0', ['/foo'], [], {});
    AnalysisContext context;
    return pumpEventQueue().then((_) {
      context = server.getAnalysisContext('/foo/bar.dart');
      server.setAnalysisRoots('1', [], [], {});
    }).then((_) => pumpEventQueue()).then((_) {
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
      server.setAnalysisRoots('0', ['/foo'], [], {
        '/foo': '/bar'
      });
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
    when(
        context.performAnalysisTask).thenReturnList(
            [firstResult, firstResult, firstResult, lastResult]);
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
}

class EchoHandler implements RequestHandler {
  @override
  Response handleRequest(Request request) {
    if (request.method == 'echo') {
      return new Response(request.id, result: {
        'echo': true
      });
    }
    return null;
  }
}
