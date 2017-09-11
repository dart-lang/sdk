// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExecutionDomainTest);
  });
  group('ExecutionDomainHandler', () {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    AnalysisServer server;
    ExecutionDomainHandler handler;

    setUp(() {
      server = new AnalysisServer(
          new MockServerChannel(),
          provider,
          new MockPackageMapProvider(),
          new AnalysisServerOptions(),
          new DartSdkManager('', false),
          InstrumentationService.NULL_SERVICE);
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

    // TODO(brianwilkerson) Re-enable these tests if we re-enable the
    // execution.mapUri request.
//    group('mapUri', () {
//      String contextId;
//
//      void createExecutionContextIdForFile(String path) {
//        Request request = new ExecutionCreateContextParams(path).toRequest('0');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('0'));
//        ExecutionCreateContextResult result =
//            new ExecutionCreateContextResult.fromResponse(response);
//        contextId = result.id;
//      }
//
//      setUp(() {
//        Folder folder = provider.newFile('/a/b.dart', '').parent;
//        server.folderMap.putIfAbsent(folder, () {
//          SourceFactory factory =
//              new SourceFactory([new ResourceUriResolver(provider)]);
//          AnalysisContext context =
//              AnalysisEngine.instance.createAnalysisContext();
//          context.sourceFactory = factory;
//          return context;
//        });
//        createExecutionContextIdForFile('/a/b.dart');
//      });
//
//      tearDown(() {
//        Request request =
//            new ExecutionDeleteContextParams(contextId).toRequest('1');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('1'));
//      });
//
//      group('file to URI', () {
//        test('does not exist', () {
//          Request request =
//              new ExecutionMapUriParams(contextId, file: '/a/c.dart')
//                  .toRequest('2');
//          Response response = handler.handleRequest(request);
//          expect(response, isResponseFailure('2'));
//        });
//
//        test('directory', () {
//          provider.newFolder('/a/d');
//          Request request =
//              new ExecutionMapUriParams(contextId, file: '/a/d').toRequest('2');
//          Response response = handler.handleRequest(request);
//          expect(response, isResponseFailure('2'));
//        });
//      });
//
//      group('URI to file', () {
//        test('invalid', () {
//          Request request =
//              new ExecutionMapUriParams(contextId, uri: 'foo:///a/b.dart')
//                  .toRequest('2');
//          Response response = handler.handleRequest(request);
//          expect(response, isResponseFailure('2'));
//        });
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
//
//      test('neither file nor uri', () {
//        Request request = new ExecutionMapUriParams('xxx').toRequest('6');
//        Response response = handler.handleRequest(request);
//        expect(response, isResponseFailure('6'));
//      });
//    });
  });
}

@reflectiveTest
class ExecutionDomainTest extends AbstractAnalysisTest {
  String contextId;

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new ExecutionDomainHandler(server);
    _createExecutionContext(testFile);
  }

  @override
  void tearDown() {
    _disposeExecutionContext();
    super.tearDown();
  }

  void test_mapUri_file() {
    String path = '/a/b.dart';
    resourceProvider.newFile(path, '');
    // map the file
    ExecutionMapUriResult result = _mapUri(file: path);
    expect(result.file, isNull);
    expect(result.uri, 'file:///a/b.dart');
  }

  void test_mapUri_file_dartUriKind() {
    String path = server.findSdk().mapDartUri('dart:async').fullName;
    // hack - pretend that the SDK file exists in the project FS
    resourceProvider.newFile(path, '// hack');
    // map file
    ExecutionMapUriResult result = _mapUri(file: path);
    expect(result.file, isNull);
    expect(result.uri, 'dart:async');
  }

  void test_mapUri_uri() {
    String path = '/a/b.dart';
    resourceProvider.newFile(path, '');
    // map the uri
    ExecutionMapUriResult result = _mapUri(uri: 'file://$path');
    expect(result.file, '/a/b.dart');
    expect(result.uri, isNull);
  }

  void _createExecutionContext(String path) {
    Request request = new ExecutionCreateContextParams(path).toRequest('0');
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
    ExecutionCreateContextResult result =
        new ExecutionCreateContextResult.fromResponse(response);
    contextId = result.id;
  }

  void _disposeExecutionContext() {
    Request request =
        new ExecutionDeleteContextParams(contextId).toRequest('1');
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('1'));
  }

  ExecutionMapUriResult _mapUri({String file, String uri}) {
    Request request = new ExecutionMapUriParams(contextId, file: file, uri: uri)
        .toRequest('2');
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('2'));
    return new ExecutionMapUriResult.fromResponse(response);
  }
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
