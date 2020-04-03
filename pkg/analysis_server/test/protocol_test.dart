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
    var original = Notification('foo');
    var notification = Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.toJson().keys, isNot(contains('params')));
  }

  void test_fromJson_withParams() {
    var original = Notification('foo', {'x': 'y'});
    var notification = Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.toJson()['params'], equals({'x': 'y'}));
  }

  void test_toJson_noParams() {
    var notification = Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.toJson().keys, isNot(contains('params')));
    expect(notification.toJson(), equals({'event': 'foo'}));
  }

  void test_toJson_withParams() {
    var notification = Notification('foo', {'x': 'y'});
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
    var error = RequestError(RequestErrorCode.INVALID_REQUEST, 'msg');
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
    var error = RequestError.fromJson(ResponseDecoder(null), '', json);
    expect(error.code, RequestErrorCode.INVALID_PARAMETER);
    expect(error.message, 'foo');
    expect(error.stackTrace, trace);
  }

  void test_toJson() {
    var trace = 'a stack trace\r\nbar';
    var error = RequestError(RequestErrorCode.UNKNOWN_REQUEST, 'msg',
        stackTrace: trace);
    expect(error.toJson(),
        {CODE: 'UNKNOWN_REQUEST', MESSAGE: 'msg', STACK_TRACE: trace});
  }
}

@reflectiveTest
class RequestTest {
  void test_fromJson() {
    var original = Request('one', 'aMethod');
    var jsonData = json.encode(original.toJson());
    var request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.clientRequestTime, isNull);
  }

  void test_fromJson_invalidId() {
    var json = '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    var request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidMethod() {
    var json = '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    var request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_invalidParams() {
    var json = '{"id":"one","method":"aMethod","params":"foobar"}';
    var request = Request.fromString(json);
    expect(request, isNull);
  }

  void test_fromJson_withBadClientTime() {
    var original = Request('one', 'aMethod', null, 347);
    var map = original.toJson();
    // Insert bad value - should be int but client sent string instead
    map[Request.CLIENT_REQUEST_TIME] = '347';
    var jsonData = json.encode(map);
    var request = Request.fromString(jsonData);
    expect(request, isNull);
  }

  void test_fromJson_withClientTime() {
    var original = Request('one', 'aMethod', null, 347);
    var jsonData = json.encode(original.toJson());
    var request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.clientRequestTime, 347);
  }

  void test_fromJson_withParams() {
    var original = Request('one', 'aMethod', {'foo': 'bar'});
    var jsonData = json.encode(original.toJson());
    var request = Request.fromString(jsonData);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.toJson()['params'], equals({'foo': 'bar'}));
  }

  void test_toJson() {
    var request = Request('one', 'aMethod');
    expect(request.toJson(),
        equals({Request.ID: 'one', Request.METHOD: 'aMethod'}));
  }

  void test_toJson_withParams() {
    var request = Request('one', 'aMethod', {'foo': 'bar'});
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
    var response = Response.invalidRequestFormat();
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
    var response = Response.unknownRequest(Request('0', ''));
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
    var original = Response('myId');
    var response = Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  void test_fromJson_withError() {
    var original = Response.invalidRequestFormat();
    var response = Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    var error = response.error;
    expect(error.code, equals(RequestErrorCode.INVALID_REQUEST));
    expect(error.message, equals('Invalid request'));
  }

  void test_fromJson_withResult() {
    var original = Response('myId', result: {'foo': 'bar'});
    var response = Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    var result = response.toJson()['result'] as Map<String, Object>;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}
