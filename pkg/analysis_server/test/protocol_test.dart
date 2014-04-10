// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

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
    test('toBool', RequestTest.toBool);
    test('toInt', RequestTest.toInt);
    test('toJson', RequestTest.toJson);
    test('toJson_withParams', RequestTest.toJson_withParams);
  });
  group('RequestError', () {
    test('create', RequestErrorTest.create);
    test('create_methodNotFound', RequestErrorTest.create_methodNotFound);
    test('create_invalidParameters', RequestErrorTest.create_invalidParameters);
    test('create_invalidRequest', RequestErrorTest.create_invalidRequest);
    test('create_internalError', RequestErrorTest.create_internalError);
    test('create_parseError', RequestErrorTest.create_parseError);
    test('fromJson', RequestErrorTest.fromJson);
    test('toJson', RequestErrorTest.toJson);
  });
  group('Response', () {
    test('create_contextDoesNotExist', ResponseTest.create_contextDoesNotExist);
    test('create_invalidRequestFormat', ResponseTest.create_invalidRequestFormat);
    test('create_missingRequiredParameter', ResponseTest.create_missingRequiredParameter);
    test('create_unknownAnalysisOption', ResponseTest.create_unknownAnalysisOption);
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
    expect(() => request.getRequiredParameter(name), _throwsRequestFailure);
  }

  static void fromJson() {
    Request original = new Request('one', 'aMethod');
    String json = JSON.encode(original.toJson());
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
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.getParameter('foo'), equals('bar'));
  }

  static void toBool() {
    Request request = new Request('0', '');
    expect(request.toBool(true), isTrue);
    expect(request.toBool(false), isFalse);
    expect(request.toBool('true'), isTrue);
    expect(request.toBool('false'), isFalse);
    expect(request.toBool('abc'), isFalse);
    expect(() => request.toBool(42), _throwsRequestFailure);
  }

  static void toInt() {
    Request request = new Request('0', '');
    expect(request.toInt(1), equals(1));
    expect(request.toInt('2'), equals(2));
    expect(() => request.toInt('xxx'), _throwsRequestFailure);
    expect(() => request.toInt(request), _throwsRequestFailure);
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

class RequestErrorTest {
  static void create() {
    RequestError error = new RequestError(42, 'msg');
    expect(error.code, 42);
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      RequestError.CODE: 42,
      RequestError.MESSAGE: "msg"
    }));
  }

  static void create_parseError() {
    RequestError error = new RequestError.parseError();
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "Parse error");
  }

  static void create_methodNotFound() {
    RequestError error = new RequestError.methodNotFound();
    expect(error.code, RequestError.CODE_METHOD_NOT_FOUND);
    expect(error.message, "Method not found");
  }

  static void create_invalidParameters() {
    RequestError error = new RequestError.invalidParameters();
    expect(error.code, RequestError.CODE_INVALID_PARAMS);
    expect(error.message, "Invalid parameters");
  }

  static void create_invalidRequest() {
    RequestError error = new RequestError.invalidRequest();
    expect(error.code, RequestError.CODE_INVALID_REQUEST);
    expect(error.message, "Invalid request");
  }

  static void create_internalError() {
    RequestError error = new RequestError.internalError();
    expect(error.code, RequestError.CODE_INTERNAL_ERROR);
    expect(error.message, "Internal error");
  }

  static void fromJson() {
    var json = {
        RequestError.CODE: RequestError.CODE_PARSE_ERROR,
        RequestError.MESSAGE: 'foo',
        RequestError.DATA: {'ints': [1, 2, 3]}
    };
    RequestError error = new RequestError.fromJson(json);
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "foo");
    expect(error.data['ints'], [1, 2, 3]);
    expect(error.getData('ints'), [1, 2, 3]);
  }

  static void toJson() {
    RequestError error = new RequestError(0, 'msg');
    error.setData('answer', 42);
    error.setData('question', 'unknown');
    expect(error.toJson(), {
        RequestError.CODE: 0,
        RequestError.MESSAGE: 'msg',
        RequestError.DATA: {'answer': 42, 'question': 'unknown'}
    });
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

  static void create_unknownAnalysisOption() {
    Response response = new Response.unknownAnalysisOption(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -6, 'message': 'Unknown analysis option: "x"'}
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
    expect(response.getResult(resultName), same(resultValue));
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

Matcher _throwsRequestFailure = throwsA(new isInstanceOf<RequestFailure>());
