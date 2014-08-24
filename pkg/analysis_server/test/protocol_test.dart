// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


Matcher _throwsRequestFailure = throwsA(new isInstanceOf<RequestFailure>());


main() {
  groupSep = ' | ';
  runReflectiveTests(NotificationTest);
  runReflectiveTests(RequestTest);
  runReflectiveTests(RequestErrorTest);
  runReflectiveTests(ResponseTest);
}


@ReflectiveTestCase()
class InvalidParameterResponseMatcher extends Matcher {
  static const String ERROR_CODE = 'INVALID_PARAMETER';

  @override
  Description describe(Description description) => description.add(
      "an 'invalid parameter' response (code $ERROR_CODE)");

  @override
  bool matches(item, Map matchState) {
    if (item is! RequestFailure) {
      return false;
    }
    var response = item.response;
    if (response is! Response) {
      return false;
    }
    if (response.error is! RequestError) {
      return false;
    }
    RequestError requestError = response.error;
    if (requestError.code != ERROR_CODE) {
      return false;
    }
    return true;
  }
}


@ReflectiveTestCase()
class NotificationTest {
  void test_fromJson() {
    Notification original = new Notification('foo');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params, isNull);
  }

  void test_fromJson_withParams() {
    Notification original = new Notification('foo');
    original.setParameter('x', 'y');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params, equals({'x': 'y'}));
  }

  void test_toJson_withParams() {
    Notification notification = new Notification('foo');
    notification.setParameter('x', 'y');
    expect(notification.event, equals('foo'));
    expect(notification.params, equals({'x': 'y'}));
    expect(notification.toJson(), equals({
      'event': 'foo',
      'params': {
        'x': 'y'
      }
    }));
  }

  void test_toJson_noParams() {
    Notification notification = new Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.params, isNull);
    expect(notification.toJson(), equals({
      'event': 'foo'
    }));
  }

  void test_setParameter_HasToJson() {
    Notification notification = new Notification('foo');
    notification.setParameter('my', new _MyHasToJsonObject(42));
    expect(notification.toJson(), equals({
      'event': 'foo',
      'params': {
        'my': {
          'offset': 42
        }
      }
    }));
  }

  void test_setParameter_Iterable_HasToJson() {
    Notification notification = new Notification('foo');
    notification.setParameter('my', [
      new _MyHasToJsonObject(1),
      new _MyHasToJsonObject(2),
      new _MyHasToJsonObject(3)]);
    expect(notification.toJson(), equals({
      'event': 'foo',
      'params': {
        'my': [{'offset': 1}, {'offset': 2}, {'offset': 3}]
      }
    }));
  }
}


class _MyHasToJsonObject implements HasToJson {
  int offset;
  _MyHasToJsonObject(this.offset);
  Map<String, Object> toJson() => {'offset': offset};
}


@ReflectiveTestCase()
class RequestErrorTest {
  void test_create() {
    RequestError error = new RequestError('ERROR_CODE', 'msg');
    expect(error.code, 'ERROR_CODE');
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      RequestError.CODE: 'ERROR_CODE',
      RequestError.MESSAGE: "msg"
    }));
  }

  void test_create_internalError() {
    RequestError error = new RequestError.internalError();
    expect(error.code, RequestError.CODE_INTERNAL_ERROR);
    expect(error.message, "Internal error");
  }

  void test_create_invalidParameters() {
    RequestError error = new RequestError.invalidParameters();
    expect(error.code, RequestError.CODE_INVALID_PARAMS);
    expect(error.message, "Invalid parameters");
  }

  void test_create_invalidRequest() {
    RequestError error = new RequestError.invalidRequest();
    expect(error.code, RequestError.CODE_INVALID_REQUEST);
    expect(error.message, "Invalid request");
  }

  void test_create_methodNotFound() {
    RequestError error = new RequestError.methodNotFound();
    expect(error.code, RequestError.CODE_METHOD_NOT_FOUND);
    expect(error.message, "Method not found");
  }

  void test_create_parseError() {
    RequestError error = new RequestError.parseError();
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "Parse error");
  }

  void test_create_serverAlreadyStarted() {
    RequestError error = new RequestError.serverAlreadyStarted();
    expect(error.code, RequestError.CODE_SERVER_ALREADY_STARTED);
    expect(error.message, "Server already started");
  }

  void test_fromJson() {
    var json = {
      RequestError.CODE: RequestError.CODE_PARSE_ERROR,
      RequestError.MESSAGE: 'foo',
      RequestError.DATA: {
        'ints': [1, 2, 3]
      }
    };
    RequestError error = new RequestError.fromJson(json);
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "foo");
    expect(error.data['ints'], [1, 2, 3]);
    expect(error.getData('ints'), [1, 2, 3]);
  }

  void test_toJson() {
    RequestError error = new RequestError('ERROR_CODE', 'msg');
    error.setData('answer', 42);
    error.setData('question', 'unknown');
    expect(error.toJson(), {
      RequestError.CODE: 'ERROR_CODE',
      RequestError.MESSAGE: 'msg',
      RequestError.DATA: {
        'answer': 42,
        'question': 'unknown'
      }
    });
  }
}


@ReflectiveTestCase()
class RequestTest {
  void test_fromJson() {
    Request original = new Request('one', 'aMethod');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
  }

  void test_fromJson_invalidId() {
    String json =
        '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidMethod() {
    String json =
        '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidParams() {
    String json = '{"id":"one","method":"aMethod","params":"foobar"}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_withParams() {
    Request original = new Request('one', 'aMethod', {'foo': 'bar'});
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.params, equals({'foo': 'bar'}));
  }

  void test_toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID: 'one',
      Request.METHOD: 'aMethod'
    }));
  }

  void test_toJson_withParams() {
    Request request = new Request('one', 'aMethod', {'foo': 'bar'});
    expect(request.toJson(), equals({
      Request.ID: 'one',
      Request.METHOD: 'aMethod',
      Request.PARAMS: {
        'foo': 'bar'
      }
    }));
  }
}


@ReflectiveTestCase()
class ResponseTest {
  void test_create_contextDoesNotExist() {
    Response response = new Response.contextDoesNotExist(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {
        'code': 'NONEXISTENT_CONTEXT',
        'message': 'Context does not exist'
      }
    }));
  }

  void test_create_invalidRequestFormat() {
    Response response = new Response.invalidRequestFormat();
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '',
      Response.ERROR: {
        'code': 'INVALID_REQUEST',
        'message': 'Invalid request'
      }
    }));
  }

  void test_create_missingRequiredParameter() {
    Response response = new Response.missingRequiredParameter(new Request('0',
        ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {
        'code': 'MISSING_PARAMETER',
        'message': 'Missing required parameter: x'
      }
    }));
  }

  void test_create_unanalyzedPriorityFiles() {
    Response response = new Response.unanalyzedPriorityFiles(new Request('0',
        ''), 'file list');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {
        'code': 'UNANALYZED_PRIORITY_FILES',
        'message': "Unanalyzed files cannot be a priority: 'file list'"
      }
    }));
  }

  void test_create_unknownAnalysisOption() {
    Response response = new Response.unknownAnalysisOption(new Request('0', ''),
        'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {
        'code': 'UNKNOWN_ANALYSIS_OPTION',
        'message': 'Unknown analysis option: "x"'
      }
    }));
  }

  void test_create_unknownRequest() {
    Response response = new Response.unknownRequest(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {
        'code': 'UNKNOWN_REQUEST',
        'message': 'Unknown request'
      }
    }));
  }

  void test_fromJson() {
    Response original = new Response('myId');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  void test_fromJson_withError() {
    Response original = new Response.invalidRequestFormat();
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    RequestError error = response.error;
    expect(error.code, equals('INVALID_REQUEST'));
    expect(error.message, equals('Invalid request'));
  }

  void test_fromJson_withResult() {
    Response original = new Response('myId', result: {'foo': 'bar'});
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result = response.result;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}
