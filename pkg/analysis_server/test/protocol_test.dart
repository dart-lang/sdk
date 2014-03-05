// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';
import 'package:unittest/unittest.dart';
import 'dart:convert';

main() {
  group('Notification', () {
    test('getParameter_defined', NotificationTest.getParameter_defined);
    test('getParameter_undefined', NotificationTest.getParameter_undefined);
    test('fromJson', NotificationTest.fromJson);
    test('fromJson_withParams', NotificationTest.fromJson_withParams);
  });
  group('Request', () {
    test('getParameter_defined', RequestTest.getParameter_defined);
    test('getParameter_undefined', RequestTest.getParameter_undefined);
    test('getRequiredParameter_defined', RequestTest.getRequiredParameter_defined);
    test('getRequiredParameter_undefined', RequestTest.getRequiredParameter_undefined);
    test('fromJson', RequestTest.fromJson);
    test('fromJson_invalidId', RequestTest.fromJson_invalidId);
    test('fromJson_invalidMethod', RequestTest.fromJson_invalidMethod);
    test('fromJson_invalidParams', RequestTest.fromJson_invalidParams);
    test('fromJson_withParams', RequestTest.fromJson_withParams);
    test('toJson', RequestTest.toJson);
    test('toJson_withParams', RequestTest.toJson_withParams);
  });
  group('Response', () {
    test('create_contextDoesNotExist', ResponseTest.create_contextDoesNotExist);
    test('create_invalidRequestFormat', ResponseTest.create_invalidRequestFormat);
    test('create_missingRequiredParameter', ResponseTest.create_missingRequiredParameter);
    test('create_unknownRequest', ResponseTest.create_unknownRequest);
    test('setResult', ResponseTest.setResult);
    test('fromJson', ResponseTest.fromJson);
    test('fromJson_withError', ResponseTest.fromJson_withError);
    test('fromJson_withResult', ResponseTest.fromJson_withResult);
  });
}

class NotificationTest {
  static void getParameter_defined() {
    Notification notification = new Notification('foo');
    notification.setParameter('x', 'y');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
    expect(notification.toJson(), equals({
      'event' : 'foo',
      'params' : {'x' : 'y'}
    }));
  }

  static void getParameter_undefined() {
    Notification notification = new Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
    expect(notification.toJson(), equals({
      'event' : 'foo'
    }));
  }

  static void fromJson() {
    Notification original = new Notification('foo');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
  }

  static void fromJson_withParams() {
    Notification original = new Notification('foo');
    original.setParameter('x', 'y');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
  }
}

class RequestTest {
  static void getParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getParameter(name), equals(value));
  }

  static void getParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(request.getParameter(name), isNull);
  }

  static void getRequiredParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getRequiredParameter(name), equals(value));
  }

  static void getRequiredParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(() => request.getRequiredParameter(name), throwsA(new isInstanceOf<RequestFailure>()));
  }

  static void fromJson() {
    Request original = new Request('one', 'aMethod');
    String json = new JsonEncoder(null).convert(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
  }

  static void fromJson_invalidId() {
    String json = '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  static void fromJson_invalidMethod() {
    String json = '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  static void fromJson_invalidParams() {
    String json = '{"id":"one","method":"aMethod","params":"foobar"}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  static void fromJson_withParams() {
    Request original = new Request('one', 'aMethod');
    original.setParameter('foo', 'bar');
    String json = new JsonEncoder(null).convert(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.getParameter('foo'), equals('bar'));
  }

  static void toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID : 'one',
      Request.METHOD : 'aMethod'
    }));
  }

  static void toJson_withParams() {
    Request request = new Request('one', 'aMethod');
    request.setParameter('foo', 'bar');
    expect(request.toJson(), equals({
      Request.ID : 'one',
      Request.METHOD : 'aMethod',
      Request.PARAMS : {'foo' : 'bar'}
    }));
  }
}

class ResponseTest {
  static void create_contextDoesNotExist() {
    Response response = new Response.contextDoesNotExist(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -1, 'message': 'Context does not exist'}
    }));
  }

  static void create_invalidRequestFormat() {
    Response response = new Response.invalidRequestFormat();
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '',
      Response.ERROR: {'code': -4, 'message': 'Invalid request'}
    }));
  }

  static void create_missingRequiredParameter() {
    Response response = new Response.missingRequiredParameter(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -5, 'message': 'Missing required parameter: x'}
    }));
  }

  static void create_unknownRequest() {
    Response response = new Response.unknownRequest(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -7, 'message': 'Unknown request'}
    }));
  }

  static void setResult() {
    String resultName = 'name';
    String resultValue = 'value';
    Response response = new Response('0');
    response.setResult(resultName, resultValue);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: null,
      Response.RESULT: {
        resultName: resultValue
      }
    }));
  }

  static void fromJson() {
    Response original = new Response('myId');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  static void fromJson_withError() {
    Response original = new Response.invalidRequestFormat();
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    RequestError error = response.error;
    expect(error.code, equals(-4));
    expect(error.message, equals('Invalid request'));
  }

  static void fromJson_withResult() {
    Response original = new Response('myId');
    original.setResult('foo', 'bar');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result = response.result;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }
}
