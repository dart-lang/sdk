// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'reflective_tests.dart';
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
  Description describe(Description description) =>
      description.add("an 'invalid parameter' response (code $ERROR_CODE)");

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
    expect(notification.toJson().keys, isNot(contains('params')));
  }

  void test_fromJson_withParams() {
    Notification original = new Notification('foo', {
      'x': 'y'
    });
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.toJson()['params'], equals({
      'x': 'y'
    }));
  }

  void test_toJson_withParams() {
    Notification notification = new Notification('foo', {
      'x': 'y'
    });
    expect(notification.event, equals('foo'));
    expect(notification.toJson()['params'], equals({
      'x': 'y'
    }));
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
    expect(notification.toJson().keys, isNot(contains('params')));
    expect(notification.toJson(), equals({
      'event': 'foo'
    }));
  }
}


@ReflectiveTestCase()
class RequestErrorTest {
  void test_create() {
    RequestError error =
        new RequestError(RequestErrorCode.INVALID_REQUEST, 'msg');
    expect(error.code, RequestErrorCode.INVALID_REQUEST);
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      CODE: 'INVALID_REQUEST',
      MESSAGE: "msg"
    }));
  }

  void test_fromJson() {
    var trace = 'a stack trace\r\nfoo';
    var json = {
      CODE: RequestErrorCode.INVALID_PARAMETER.name,
      MESSAGE: 'foo',
      STACK_TRACE: trace
    };
    RequestError error =
        new RequestError.fromJson(new ResponseDecoder(null), '', json);
    expect(error.code, RequestErrorCode.INVALID_PARAMETER);
    expect(error.message, "foo");
    expect(error.stackTrace, trace);
  }

  void test_toJson() {
    var trace = 'a stack trace\r\nbar';
    RequestError error =
        new RequestError(RequestErrorCode.UNKNOWN_REQUEST, 'msg', stackTrace: trace);
    expect(error.toJson(), {
      CODE: 'UNKNOWN_REQUEST',
      MESSAGE: 'msg',
      STACK_TRACE: trace
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
    Request original = new Request('one', 'aMethod', {
      'foo': 'bar'
    });
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.toJson()['params'], equals({
      'foo': 'bar'
    }));
  }

  void test_toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID: 'one',
      Request.METHOD: 'aMethod'
    }));
  }

  void test_toJson_withParams() {
    Request request = new Request('one', 'aMethod', {
      'foo': 'bar'
    });
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

  void test_create_unanalyzedPriorityFiles() {
    Response response =
        new Response.unanalyzedPriorityFiles(new Request('0', ''), 'file list');
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
    expect(error.code, equals(RequestErrorCode.INVALID_REQUEST));
    expect(error.message, equals('Invalid request'));
  }

  void test_fromJson_withResult() {
    Response original = new Response('myId', result: {
      'foo': 'bar'
    });
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result = response.toJson()['result'];
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}
