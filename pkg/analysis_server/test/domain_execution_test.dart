// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_execution.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExecutionDomainTest);
  });
  // group('ExecutionDomainHandler', () {
  //   var provider = MemoryResourceProvider();
  //   late AnalysisServer server;
  //   late ExecutionDomainHandler handler;
  //
  //   setUp(() {
  //     server = AnalysisServer(
  //         MockServerChannel(),
  //         provider,
  //         AnalysisServerOptions(),
  //         DartSdkManager(''),
  //         CrashReportingAttachmentsBuilder.empty,
  //         InstrumentationService.NULL_SERVICE);
  //     handler = ExecutionDomainHandler(server, server.executionContext);
  //   });
  //
  //  // TODO(brianwilkerson) Re-enable these tests if we re-enable the
  //  // execution.mapUri request.
//    group('mapUri', () {
//      String contextId;
//
//      void createExecutionContextIdForFile(String path) {
//        Request request = new ExecutionCreateContextParams(path).toRequest('0');
//        Response response = handler.handleRequest(request, NotCancelableToken());
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
//        Response response = handler.handleRequest(request, NotCancelableToken());
//        expect(response, isResponseSuccess('1'));
//      });
//
//      group('file to URI', () {
//        test('does not exist', () {
//          Request request =
//              new ExecutionMapUriParams(contextId, file: '/a/c.dart')
//                  .toRequest('2');
//          Response response = handler.handleRequest(request, NotCancelableToken());
//          expect(response, isResponseFailure('2'));
//        });
//
//        test('directory', () {
//          provider.newFolder('/a/d');
//          Request request =
//              new ExecutionMapUriParams(contextId, file: '/a/d').toRequest('2');
//          Response response = handler.handleRequest(request, NotCancelableToken());
//          expect(response, isResponseFailure('2'));
//        });
//      });
//
//      group('URI to file', () {
//        test('invalid', () {
//          Request request =
//              new ExecutionMapUriParams(contextId, uri: 'foo:///a/b.dart')
//                  .toRequest('2');
//          Response response = handler.handleRequest(request, NotCancelableToken());
//          expect(response, isResponseFailure('2'));
//        });
//      });
//
//      test('invalid context id', () {
//        Request request =
//            new ExecutionMapUriParams('xxx', uri: '').toRequest('4');
//        Response response = handler.handleRequest(request, NotCancelableToken());
//        expect(response, isResponseFailure('4'));
//      });
//
//      test('both file and uri', () {
//        Request request =
//            new ExecutionMapUriParams('xxx', file: '', uri: '').toRequest('5');
//        Response response = handler.handleRequest(request, NotCancelableToken());
//        expect(response, isResponseFailure('5'));
//      });
//
//      test('neither file nor uri', () {
//        Request request = new ExecutionMapUriParams('xxx').toRequest('6');
//        Response response = handler.handleRequest(request, NotCancelableToken());
//        expect(response, isResponseFailure('6'));
//      });
//    });
//   });
}

@reflectiveTest
class ExecutionDomainTest extends AbstractAnalysisTest {
  late String contextId;

  @override
  Future<void> setUp() async {
    super.setUp();
    await createProject();
    handler = ExecutionDomainHandler(server, server.executionContext);
    await _createExecutionContext(testFile);
  }

  @override
  Future<void> tearDown() async {
    await _disposeExecutionContext();
    super.tearDown();
  }

  Future<void> test_createAndDeleteMultipleContexts() async {
    var request = ExecutionCreateContextParams('/a/b.dart').toRequest('0');
    var response = await waitResponse(request);
    expect(response, isResponseSuccess('0'));
    var result = ExecutionCreateContextResult.fromResponse(response);
    var id0 = result.id;

    request = ExecutionCreateContextParams('/c/d.dart').toRequest('1');
    response = await waitResponse(request);
    expect(response, isResponseSuccess('1'));
    result = ExecutionCreateContextResult.fromResponse(response);
    var id1 = result.id;

    expect(id0 == id1, isFalse);

    request = ExecutionDeleteContextParams(id0).toRequest('2');
    response = await waitResponse(request);
    expect(response, isResponseSuccess('2'));

    request = ExecutionDeleteContextParams(id1).toRequest('3');
    response = await waitResponse(request);
    expect(response, isResponseSuccess('3'));
  }

  Future<void> test_deleteNonExistentContext() async {
    var request = ExecutionDeleteContextParams('13').toRequest('0');
    var response = await waitResponse(request);
    // TODO(brianwilkerson) It isn't currently specified to be an error if a
    // client attempts to delete a context that doesn't exist. Should it be?
//        expect(response, isResponseFailure('0'));
    expect(response, isResponseSuccess('0'));
  }

  Future<void> test_getSuggestions() async {
    var code = r'''
class A {
  int foo;
}

void contextFunction() {
  var a = new A();
  // context line
}
''';

    var path = newFile2('/test.dart', '').path;
    newFile2(path, code);

    var request = ExecutionGetSuggestionsParams(
        'a.',
        2,
        path,
        code.indexOf('// context line'),
        <RuntimeCompletionVariable>[]).toRequest('0');
    var response = await waitResponse(request);

    var result = ExecutionGetSuggestionsResult.fromResponse(response);
//    expect(result.suggestions, isNotEmpty);
//
//    expect(
//        result.suggestions,
//        contains(
//            predicate<CompletionSuggestion>((s) => s.completion == 'foo')));

    // TODO(brianwilkerson) Restore the expectations above (and delete the line
    // below) after the functionality has been re-enabled.
    expect(result.suggestions, isEmpty);
  }

  Future<void> test_mapUri_file() async {
    var path = newFile2('/a/b.dart', '').path;
    // map the file
    var result = await _mapUri(file: path);
    expect(result.file, isNull);
    expect(result.uri, Uri.file(path).toString());
  }

  Future<void> test_mapUri_file_dartUriKind() async {
    var path = (await _mapUri(uri: 'dart:async')).file;
    // map file
    var result = await _mapUri(file: path);
    expect(result.file, isNull);
    expect(result.uri, 'dart:async');
  }

  Future<void> test_mapUri_uri() async {
    var path = newFile2('/a/b.dart', '').path;
    // map the uri
    var result = await _mapUri(uri: Uri.file(path).toString());
    expect(result.file, convertPath('/a/b.dart'));
    expect(result.uri, isNull);
  }

  Future<void> _createExecutionContext(String path) async {
    var request = ExecutionCreateContextParams(path).toRequest('0');
    var response = await waitResponse(request);
    expect(response, isResponseSuccess('0'));
    var result = ExecutionCreateContextResult.fromResponse(response);
    contextId = result.id;
  }

  Future<void> _disposeExecutionContext() async {
    var request = ExecutionDeleteContextParams(contextId).toRequest('1');
    var response = await waitResponse(request);
    expect(response, isResponseSuccess('1'));
  }

  Future<ExecutionMapUriResult> _mapUri({String? file, String? uri}) async {
    var request =
        ExecutionMapUriParams(contextId, file: file, uri: uri).toRequest('2');
    var response = await waitResponse(request);
    expect(response, isResponseSuccess('2'));
    return ExecutionMapUriResult.fromResponse(response);
  }
}
