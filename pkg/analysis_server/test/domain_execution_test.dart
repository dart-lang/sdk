// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.execution;

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/protocol.dart';
import 'mock_sdk.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';
import 'operation/operation_queue_test.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'dart:async';

main() {
  group('ExecutionDomainHandler', () {
    AnalysisServer server;
    ExecutionDomainHandler handler;

    setUp(() {
      server = new AnalysisServer(
          new MockServerChannel(),
          PhysicalResourceProvider.INSTANCE,
          new MockPackageMapProvider(),
          null,
          new MockSdk());
      handler = new ExecutionDomainHandler(server);
    });

    group('createContext/deleteContext', () {
      test('create/delete multiple contexts', () {
        Request request =
            new ExecutionCreateContextParams('/a/b.dart').toRequest('0');
        Response response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
        ExecutionCreateContextResult result =
            new ExecutionCreateContextResult.fromResponse(response);
        String id0 = result.id;

        request = new ExecutionCreateContextParams('/c/d.dart').toRequest('1');
        response = handler.handleRequest(request);
        expect(response, isResponseSuccess('1'));
        result = new ExecutionCreateContextResult.fromResponse(response);
        String id1 = result.id;

        expect(id0 == id1, isFalse);

        request = new ExecutionDeleteContextParams(id0).toRequest('2');
        response = handler.handleRequest(request);
        expect(response, isResponseSuccess('2'));

        request = new ExecutionDeleteContextParams(id1).toRequest('3');
        response = handler.handleRequest(request);
        expect(response, isResponseSuccess('3'));
      });

      test('delete non-existent context', () {
        Request request = new ExecutionDeleteContextParams('13').toRequest('0');
        Response response = handler.handleRequest(request);
        // TODO(brianwilkerson) It isn't currently specified to be an error if a
        // client attempts to delete a context that doesn't exist. Should it be?
//        expect(response, isResponseFailure('0'));
        expect(response, isResponseSuccess('0'));
      });
    });

//    group('mapUri', () {
//      String contextId;
//
//      setUp(() {
//        Request request =
//            new ExecutionCreateContextParams('/a/b.dart').toRequest('0');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('0'));
//        ExecutionCreateContextResult result =
//            new ExecutionCreateContextResult.fromResponse(response);
//        contextId = result.id;
//      });
//
//      tearDown(() {
//        Request request =
//            new ExecutionDeleteContextParams(contextId).toRequest('1');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('1'));
//      });
//
//      test('file to URI', () {
//        Request request =
//            new ExecutionMapUriParams(contextId, file: '/a/b.dart').toRequest('2');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('2'));
//        ExecutionMapUriResult result =
//            new ExecutionMapUriResult.fromResponse(response);
//        expect(result.file, isNull);
//        expect(result.uri, isNotNull);
//        // TODO(brianwilkerson) Test for the correct result.
//      });
//
//      test('URI to file', () {
//        Request request =
//            new ExecutionMapUriParams(contextId, uri: '/a/b.dart').toRequest('3');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('3'));
//        ExecutionMapUriResult result =
//            new ExecutionMapUriResult.fromResponse(response);
//        expect(result.file, isNotNull);
//        expect(result.uri, isNull);
//        // TODO(brianwilkerson) Test for the correct result.
//      });
//
//      test('invalid context id', () {
//        Request request =
//            new ExecutionMapUriParams('xxx', uri: '').toRequest('4');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseFailure('4'));
//      });
//
//      test('both file and uri', () {
//        Request request =
//            new ExecutionMapUriParams('xxx', file: '', uri: '').toRequest('5');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseFailure('5'));
//      });
//    });

    group('setSubscriptions', () {
      test('failure - invalid service name', () {
        expect(handler.onFileAnalyzed, isNull);

        Request request = new Request('0', EXECUTION_SET_SUBSCRIPTIONS, {
          SUBSCRIPTIONS: ['noSuchService']
        });
        Response response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
        expect(handler.onFileAnalyzed, isNull);
      });

      test('success - setting and clearing', () {
        expect(handler.onFileAnalyzed, isNull);

        Request request = new ExecutionSetSubscriptionsParams(
            [ExecutionService.LAUNCH_DATA]).toRequest('0');
        Response response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
        expect(handler.onFileAnalyzed, isNotNull);

        request = new ExecutionSetSubscriptionsParams([]).toRequest('0');
        response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
        expect(handler.onFileAnalyzed, isNull);
      });
    });

    test('onAnalysisComplete - success - setting and clearing', () {
      Source source1 = new TestSource('/a.dart');
      Source source2 = new TestSource('/b.dart');
      Source source3 = new TestSource('/c.dart');
      Source source4 = new TestSource('/d.dart');
      Source source5 = new TestSource('/e.html');
      Source source6 = new TestSource('/f.html');
      Source source7 = new TestSource('/g.html');

      AnalysisContext context = new AnalysisContextMock();
      when(context.launchableClientLibrarySources)
          .thenReturn([source1, source2]);
      when(context.launchableServerLibrarySources)
          .thenReturn([source2, source3]);
      when(context.librarySources).thenReturn([source4]);
      when(context.htmlSources).thenReturn([source5]);
      when(context.getLibrariesReferencedFromHtml(anyObject))
          .thenReturn([source6, source7]);

      AnalysisServer server = new AnalysisServerMock();
      when(server.getAnalysisContexts()).thenReturn([context]);
      when(server.isAnalysisComplete()).thenReturn(false);

      StreamController controller = new StreamController.broadcast(sync: true);
      when(server.onFileAnalyzed).thenReturn(controller.stream);

      List<String> unsentNotifications = <String>[
          source1.fullName, source2.fullName, source3.fullName,
          source4.fullName, source5.fullName];
      when(server.sendNotification(anyObject))
          .thenInvoke((Notification notification) {
        ExecutionLaunchDataParams params =
            new ExecutionLaunchDataParams.fromNotification(notification);

        String fileName = params.file;
        expect(unsentNotifications.remove(fileName), isTrue);

        if (fileName == source1.fullName) {
          expect(params.kind, ExecutableKind.CLIENT);
        } else if (fileName == source2.fullName) {
          expect(params.kind, ExecutableKind.EITHER);
        } else if (fileName == source3.fullName) {
          expect(params.kind, ExecutableKind.SERVER);
        } else if (fileName == source4.fullName) {
          expect(params.kind, ExecutableKind.NOT_EXECUTABLE);
        } else if (fileName == source5.fullName) {
          var referencedFiles = params.referencedFiles;
          expect(referencedFiles, isNotNull);
          expect(referencedFiles.length, equals(2));
          expect(referencedFiles[0], equals(source6.fullName));
          expect(referencedFiles[1], equals(source7.fullName));
        }
      });

      ExecutionDomainHandler handler = new ExecutionDomainHandler(server);
      Request request = new ExecutionSetSubscriptionsParams(
          [ExecutionService.LAUNCH_DATA]).toRequest('0');
      Response response = handler.handleRequest(request);

//      controller.add(null);
      expect(unsentNotifications, isEmpty);
    });
  });
}

/**
 * A [Source] that knows it's [fullName].
 */
class TestSource implements Source {
  String fullName;

  TestSource(this.fullName);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Return a matcher that will match an [ExecutableFile] if it has the given
 * [source] and [kind].
 */
Matcher isExecutableFile(Source source, ExecutableKind kind) {
  return new IsExecutableFile(source.fullName, kind);
}

/**
 * A matcher that will match an [ExecutableFile] if it has a specified [source]
 * and [kind].
 */
class IsExecutableFile extends Matcher {
  String expectedFile;
  ExecutableKind expectedKind;

  IsExecutableFile(this.expectedFile, this.expectedKind);

  @override
  Description describe(Description description) {
    return description.add('ExecutableFile($expectedFile, $expectedKind)');
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! ExecutableFile) {
      return false;
    }
    ExecutableFile file = item;
    return item.file == expectedFile && item.kind == expectedKind;
  }
}
