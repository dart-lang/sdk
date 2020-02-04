// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'constants.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotificationTest);
    defineReflectiveTests(RequestTest);
    defineReflectiveTests(RequestErrorTest);
    defineReflectiveTests(ResponseTest);
  });
}

@reflectiveTest
class NotificationTest {
  void test_fromJson() {
    Notification original = Notification('foo');
    Notification notification = Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.toJson().keys, isNot(contains('params')));
  }

  void test_fromJson_withParams() {
    Notification original = Notification('foo', {'x': 'y'});
    Notification notification = Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.toJson()['params'], equals({'x': 'y'}));
  }

  void test_toJson_noParams() {
    Notification notification = Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.toJson().keys, isNot(contains('params')));
    expect(notification.toJson(), equals({'event': 'foo'}));
  }

  void test_toJson_withParams() {
    Notification notification = Notification('foo', {'x': 'y'});
    expect(notification.event, equals('foo'));
    expect(notification.toJson()['params'], equals({'x': 'y'}));
    expect(
        notification.toJson(),
        equals({
          'event': 'foo',
          'params': {'x': 'y'}
        }));
  }
}

@reflectiveTest
class RequestErrorTest {
  void test_create() {
    RequestError error = RequestError(RequestErrorCode.INVALID_REQUEST, 'msg');
    expect(error.code, RequestErrorCode.INVALID_REQUEST);
    expect(error.message, 'msg');
    expect(error.toJson(), equals({CODE: 'INVALID_REQUEST', MESSAGE: 'msg'}));
  }

  void test_fromJson() {
    var trace = 'a stack trace\r\nfoo';
    var json = {
      CODE: RequestErrorCode.INVALID_PARAMETER.name,
      MESSAGE: 'foo',
      STACK_TRACE: trace
    };
    RequestError error = RequestError.fromJson(ResponseDecoder(null), '', json);
    expect(error.code, RequestErrorCode.INVALID_PARAMETER);
    expect(error.message, 'foo');
    expect(error.stackTrace, trace);
  }

  void test_toJson() {
    var trace = 'a stack trace\r\nbar';
    RequestError error = RequestError(RequestErrorCode.UNKNOWN_REQUEST, 'msg',
        stackTrace: trace);
    expect(error.toJson(),
        {CODE: 'UNKNOWN_REQUEST', MESSAGE: 'msg', STACK_TRACE: trace});
  }
}

@reflectiveTest
class RequestTest {
  void test_fromJson() {
    Request original = Request('one', 'aMethod');
    String jsonData = json.encode(original.toJson());
    Request request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.clientRequestTime, isNull);
  }

  void test_fromJson_invalidId() {
    String json =
        '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    Request request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidMethod() {
    String json =
        '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    Request request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidParams() {
    String json = '{"id":"one","method":"aMethod","params":"foobar"}';
    Request request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_withBadClientTime() {
    Request original = Request('one', 'aMethod', null, 347);
    Map<String, Object> map = original.toJson();
    // Insert bad value - should be int but client sent string instead
    map[Request.CLIENT_REQUEST_TIME] = '347';
    String jsonData = json.encode(map);
    Request request = Request.fromString(jsonData);
    expect(request, isNull);
  }

  void test_fromJson_withClientTime() {
    Request original = Request('one', 'aMethod', null, 347);
    String jsonData = json.encode(original.toJson());
    Request request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.clientRequestTime, 347);
  }

  void test_fromJson_withParams() {
    Request original = Request('one', 'aMethod', {'foo': 'bar'});
    String jsonData = json.encode(original.toJson());
    Request request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.toJson()['params'], equals({'foo': 'bar'}));
  }

  void test_toJson() {
    Request request = Request('one', 'aMethod');
    expect(request.toJson(),
        equals({Request.ID: 'one', Request.METHOD: 'aMethod'}));
  }

  void test_toJson_withParams() {
    Request request = Request('one', 'aMethod', {'foo': 'bar'});
    expect(
        request.toJson(),
        equals({
          Request.ID: 'one',
          Request.METHOD: 'aMethod',
          Request.PARAMS: {'foo': 'bar'}
        }));
  }
}

@reflectiveTest
class ResponseTest {
  void test_create_invalidRequestFormat() {
    Response response = Response.invalidRequestFormat();
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    expect(
        response.toJson(),
        equals({
          Response.ID: '',
          Response.ERROR: {
            'code': 'INVALID_REQUEST',
            'message': 'Invalid request'
          }
        }));
  }

  void test_create_unknownRequest() {
    Response response = Response.unknownRequest(Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(
        response.toJson(),
        equals({
          Response.ID: '0',
          Response.ERROR: {
            'code': 'UNKNOWN_REQUEST',
            'message': 'Unknown request'
          }
        }));
  }

  void test_fromJson() {
    Response original = Response('myId');
    Response response = Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  void test_fromJson_withError() {
    Response original = Response.invalidRequestFormat();
    Response response = Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    RequestError error = response.error;
    expect(error.code, equals(RequestErrorCode.INVALID_REQUEST));
    expect(error.message, equals('Invalid request'));
  }

  void test_fromJson_withResult() {
    Response original = Response('myId', result: {'foo': 'bar'});
    Response response = Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result =
        response.toJson()['result'] as Map<String, Object>;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}
