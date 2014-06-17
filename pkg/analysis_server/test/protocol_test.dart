// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'declarative_tests.dart';

main() {
  addTestSuite(NotificationTest);
  addTestSuite(RequestTest);
  addTestSuite(RequestErrorTest);
  addTestSuite(RequestDatumTest);
  addTestSuite(ResponseTest);
}

class NotificationTest {
  @runTest
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

  @runTest
  static void getParameter_undefined() {
    Notification notification = new Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
    expect(notification.toJson(), equals({
      'event' : 'foo'
    }));
  }

  @runTest
  static void fromJson() {
    Notification original = new Notification('foo');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
  }

  @runTest
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
  @runTest
  static void getParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getParameter(name, null).datum, equals(value));
  }

  @runTest
  static void getParameter_undefined() {
    String name = 'name';
    String defaultValue = 'default value';
    Request request = new Request('0', '');
    expect(request.getParameter(name, defaultValue).datum, equals(defaultValue));
  }

  @runTest
  static void getRequiredParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getRequiredParameter(name).datum, equals(value));
  }

  @runTest
  static void getRequiredParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(() => request.getRequiredParameter(name), _throwsRequestFailure);
  }

  @runTest
  static void fromJson() {
    Request original = new Request('one', 'aMethod');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
  }

  @runTest
  static void fromJson_invalidId() {
    String json = '{"id":{"one":"two"},"method":"aMethod","params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_invalidMethod() {
    String json = '{"id":"one","method":{"boo":"aMethod"},"params":{"foo":"bar"}}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_invalidParams() {
    String json = '{"id":"one","method":"aMethod","params":"foobar"}';
    Request request = new Request.fromString(json);
    expect(request, isNull);
  }

  @runTest
  static void fromJson_withParams() {
    Request original = new Request('one', 'aMethod');
    original.setParameter('foo', 'bar');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.getParameter('foo', null).asString(), equals('bar'));
  }

  @runTest
  static void toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID : 'one',
      Request.METHOD : 'aMethod'
    }));
  }

  @runTest
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
  @runTest
  static void create() {
    RequestError error = new RequestError(42, 'msg');
    expect(error.code, 42);
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      RequestError.CODE: 42,
      RequestError.MESSAGE: "msg"
    }));
  }

  @runTest
  static void create_parseError() {
    RequestError error = new RequestError.parseError();
    expect(error.code, RequestError.CODE_PARSE_ERROR);
    expect(error.message, "Parse error");
  }

  @runTest
  static void create_methodNotFound() {
    RequestError error = new RequestError.methodNotFound();
    expect(error.code, RequestError.CODE_METHOD_NOT_FOUND);
    expect(error.message, "Method not found");
  }

  @runTest
  static void create_invalidParameters() {
    RequestError error = new RequestError.invalidParameters();
    expect(error.code, RequestError.CODE_INVALID_PARAMS);
    expect(error.message, "Invalid parameters");
  }

  @runTest
  static void create_invalidRequest() {
    RequestError error = new RequestError.invalidRequest();
    expect(error.code, RequestError.CODE_INVALID_REQUEST);
    expect(error.message, "Invalid request");
  }

  @runTest
  static void create_internalError() {
    RequestError error = new RequestError.internalError();
    expect(error.code, RequestError.CODE_INTERNAL_ERROR);
    expect(error.message, "Internal error");
  }

  @runTest
  static void create_serverAlreadyStarted() {
    RequestError error = new RequestError.serverAlreadyStarted();
    expect(error.code, RequestError.CODE_SERVER_ALREADY_STARTED);
    expect(error.message, "Server already started");
  }

  @runTest
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

  @runTest
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

class InvalidParameterResponseMatcher extends Matcher {
  static const int ERROR_CODE = -2;

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

class RequestDatumTest {
  static Request request;

  static Matcher _throwsInvalidParameter = throwsA(
      new InvalidParameterResponseMatcher());
  static Matcher isRequestDatum = new isInstanceOf<RequestDatum>("RequestDatum"
      );

  static void setUp() {
    request = new Request('myId', 'myMethod');
  }

  static RequestDatum makeDatum(dynamic datum) {
    return new RequestDatum(request, 'myPath', datum);
  }

  @runTest
  static void indexOperator_nonMap() {
    setUp();
    expect(() => makeDatum(1)['foo'], _throwsInvalidParameter);
  }

  @runTest
  static void indexOperator_missingKey() {
    setUp();
    expect(() => makeDatum({
      'foo': 'bar'
    })['baz'], _throwsInvalidParameter);
  }

  @runTest
  static void indexOperator_hasKey() {
    setUp();
    var indexResult = makeDatum({
      'foo': 'bar'
    })['foo'];
    expect(indexResult, isRequestDatum);
    expect(indexResult.datum, equals('bar'));
    expect(indexResult.path, equals('myPath.foo'));
  }

  @runTest
  static void hasKey() {
    setUp();
    var datum = makeDatum({
      'foo': 'bar'
    });
    expect(datum.hasKey('foo'), isTrue);
    expect(datum.hasKey('bar'), isFalse);
    expect(datum.hasKey('baz'), isFalse);
  }

  @runTest
  static void forEachMap_nonMap() {
    setUp();
    expect(() => makeDatum(1).forEachMap((key, value) {
      fail('Non-map should not be iterated');
    }), _throwsInvalidParameter);
  }

  @runTest
  static void forEachMap_emptyMap() {
    setUp();
    makeDatum({}).forEachMap((key, value) {
      fail('Empty map should not be iterated');
    });
  }

  @runTest
  static void forEachMap_oneElementMap() {
    setUp();
    int callCount = 0;
    makeDatum({
      'key': 'value'
    }).forEachMap((key, value) {
      callCount++;
      expect(key, equals('key'));
      expect(value, isRequestDatum);
      expect(value.datum, equals('value'));
    });
    expect(callCount, equals(1));
  }

  @runTest
  static void forEachMap_twoElementMap() {
    setUp();
    int callCount = 0;
    Map<String, String> map = {
      'key1': 'value1',
      'key2': 'value2'
    };
    Map iterationResult = {};
    makeDatum(map).forEachMap((key, value) {
      callCount++;
      expect(value, isRequestDatum);
      iterationResult[key] = value.datum;
    });
    expect(callCount, equals(2));
    expect(iterationResult, equals(map));
  }

  @runTest
  static void asBool() {
    setUp();
    expect(makeDatum(true).asBool(), isTrue);
    expect(makeDatum(false).asBool(), isFalse);
    expect(makeDatum('true').asBool(), isTrue);
    expect(makeDatum('false').asBool(), isFalse);
    expect(() => makeDatum('abc').asBool(), _throwsInvalidParameter);
  }

  @runTest
  static void asInt() {
    setUp();
    expect(makeDatum(1).asInt(), equals(1));
    expect(makeDatum('2').asInt(), equals(2));
    expect(() => makeDatum('xxx').asInt(), _throwsInvalidParameter);
    expect(() => makeDatum(true).asInt(), _throwsInvalidParameter);
  }

  @runTest
  static void asList_nonList() {
    setUp();
    expect(() => makeDatum(3).asList((datum) => null), _throwsInvalidParameter);
  }

  @runTest
  static void asList_emptyList() {
    setUp();
    expect(makeDatum([]).asList((datum) => datum.asString()), equals([]));
  }

  @runTest
  static void asList_nonEmptyList() {
    setUp();
    expect(makeDatum(['foo', 'bar']).asList((datum) => datum.asString()), equals(['foo', 'bar']));
  }

  @runTest
  static void asString() {
    setUp();
    expect(makeDatum('foo').asString(), equals('foo'));
    expect(() => makeDatum(3).asString(), _throwsInvalidParameter);
  }

  @runTest
  static void asStringList() {
    setUp();
    expect(makeDatum(['foo', 'bar']).asStringList(), equals(['foo', 'bar']));
    expect(makeDatum([]).asStringList(), equals([]));
    expect(() => makeDatum(['foo', 1]).asStringList(), _throwsInvalidParameter);
    expect(() => makeDatum({}).asStringList(), _throwsInvalidParameter);
  }

  @runTest
  static void asStringMap() {
    setUp();
    expect(makeDatum({
      'key1': 'value1',
      'key2': 'value2'
    }).asStringMap(), equals({
      'key1': 'value1',
      'key2': 'value2'
    }));
    expect(makeDatum({}).asStringMap(), equals({}));
    expect(() => makeDatum({
      'key1': 'value1',
      'key2': 2
    }).asStringMap(), _throwsInvalidParameter);
    expect(() => makeDatum({
      'key1': 1,
      'key2': 2
    }).asStringMap(), _throwsInvalidParameter);
    expect(() => makeDatum([]).asStringMap(), _throwsInvalidParameter);
  }

  @runTest
  static void asStringListMap() {
    setUp();
    {
      var map = {
        'key1': ['value11', 'value12'],
        'key2': ['value21', 'value22']
      };
      expect(makeDatum(map).asStringListMap(), map);
    }
    {
      var map = {
        'key1': 10,
        'key2': 20
      };
      expect(() => makeDatum(map).asStringListMap(), _throwsInvalidParameter);
    }
    {
      var map = {
        'key1': [11, 12],
        'key2': [21, 22]
      };
      expect(() => makeDatum(map).asStringListMap(), _throwsInvalidParameter);
    }
  }
}

class ResponseTest {
  @runTest
  static void create_contextDoesNotExist() {
    Response response = new Response.contextDoesNotExist(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -1, 'message': 'Context does not exist'}
    }));
  }

  @runTest
  static void create_invalidRequestFormat() {
    Response response = new Response.invalidRequestFormat();
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '',
      Response.ERROR: {'code': -4, 'message': 'Invalid request'}
    }));
  }

  @runTest
  static void create_missingRequiredParameter() {
    Response response = new Response.missingRequiredParameter(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -5, 'message': 'Missing required parameter: x'}
    }));
  }

  @runTest
  static void create_unknownAnalysisOption() {
    Response response = new Response.unknownAnalysisOption(new Request('0', ''), 'x');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -6, 'message': 'Unknown analysis option: "x"'}
    }));
  }

  @runTest
  static void create_unknownRequest() {
    Response response = new Response.unknownRequest(new Request('0', ''));
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -7, 'message': 'Unknown request'}
    }));
  }

  @runTest
  static void create_unanalyzedPriorityFiles() {
    Response response = new Response.unanalyzedPriorityFiles(new Request('0', ''), 'file list');
    expect(response.id, equals('0'));
    expect(response.error, isNotNull);
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.ERROR: {'code': -11, 'message': "Unanalyzed files cannot be a priority: 'file list'"}
    }));
  }

  @runTest
  static void setResult() {
    String resultName = 'name';
    String resultValue = 'value';
    Response response = new Response('0');
    response.setResult(resultName, resultValue);
    expect(response.getResult(resultName), same(resultValue));
    expect(response.toJson(), equals({
      Response.ID: '0',
      Response.RESULT: {
        resultName: resultValue
      }
    }));
  }

  @runTest
  static void fromJson() {
    Response original = new Response('myId');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
  }

  @runTest
  static void fromJson_withError() {
    Response original = new Response.invalidRequestFormat();
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals(''));
    expect(response.error, isNotNull);
    RequestError error = response.error;
    expect(error.code, equals(-4));
    expect(error.message, equals('Invalid request'));
  }

  @runTest
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
