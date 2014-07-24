// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'dart:convert';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/json.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';


Matcher _throwsRequestFailure = throwsA(new isInstanceOf<RequestFailure>());


main() {
  groupSep = ' | ';
  runReflectiveTests(NotificationTest);
  runReflectiveTests(RequestTest);
  runReflectiveTests(RequestErrorTest);
  runReflectiveTests(RequestDatumTest);
  runReflectiveTests(ResponseTest);
}


@ReflectiveTestCase()
class InvalidParameterResponseMatcher extends Matcher {
  static const int ERROR_CODE = -2;

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
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
  }

  void test_fromJson_withParams() {
    Notification original = new Notification('foo');
    original.setParameter('x', 'y');
    Notification notification = new Notification.fromJson(original.toJson());
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
  }

  void test_getParameter_defined() {
    Notification notification = new Notification('foo');
    notification.setParameter('x', 'y');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(1));
    expect(notification.getParameter('x'), equals('y'));
    expect(notification.toJson(), equals({
      'event': 'foo',
      'params': {
        'x': 'y'
      }
    }));
  }

  void test_getParameter_undefined() {
    Notification notification = new Notification('foo');
    expect(notification.event, equals('foo'));
    expect(notification.params.length, equals(0));
    expect(notification.getParameter('x'), isNull);
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
class RequestDatumTest {
  static Matcher isRequestDatum = new isInstanceOf<RequestDatum>(
      "RequestDatum");

  static Request request;
  static Matcher _throwsInvalidParameter = throwsA(
      new InvalidParameterResponseMatcher());

  void setUp() {
    request = new Request('myId', 'myMethod');
  }

  void test_asBool() {
    expect(makeDatum(true).asBool(), isTrue);
    expect(makeDatum(false).asBool(), isFalse);
    expect(makeDatum('true').asBool(), isTrue);
    expect(makeDatum('false').asBool(), isFalse);
    expect(() => makeDatum('abc').asBool(), _throwsInvalidParameter);
  }

  void test_asInt() {
    expect(makeDatum(1).asInt(), equals(1));
    expect(makeDatum('2').asInt(), equals(2));
    expect(() => makeDatum('xxx').asInt(), _throwsInvalidParameter);
    expect(() => makeDatum(true).asInt(), _throwsInvalidParameter);
  }

  void test_asList_emptyList() {
    expect(makeDatum([]).asList((datum) => datum.asString()), equals([]));
  }

  void test_asList_nonEmptyList() {
    expect(makeDatum(['foo', 'bar']).asList((datum) => datum.asString()),
        equals(['foo', 'bar']));
  }

  void test_asList_nonList() {
    expect(() => makeDatum(3).asList((datum) => null), _throwsInvalidParameter);
  }

  void test_asList_null() {
    expect(makeDatum(null).asList((datum) => datum.asString()), equals([]));
  }

  void test_asString() {
    expect(makeDatum('foo').asString(), equals('foo'));
    expect(() => makeDatum(3).asString(), _throwsInvalidParameter);
  }

  void test_asStringList() {
    expect(makeDatum(['foo', 'bar']).asStringList(), equals(['foo', 'bar']));
    expect(makeDatum([]).asStringList(), equals([]));
    expect(makeDatum(null).asStringList(), equals([]));
    expect(() => makeDatum(['foo', 1]).asStringList(), _throwsInvalidParameter);
    expect(() => makeDatum({}).asStringList(), _throwsInvalidParameter);
  }

  void test_asStringListMap() {
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

  void test_asStringMap() {
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

  void test_forEachMap_emptyMap() {
    makeDatum({}).forEachMap((key, value) {
      fail('Empty map should not be iterated');
    });
  }

  void test_forEachMap_nonMap() {
    expect(() => makeDatum(1).forEachMap((key, value) {
      fail('Non-map should not be iterated');
    }), _throwsInvalidParameter);
  }

  void test_forEachMap_null() {
    makeDatum(null).forEachMap((key, value) {
      fail('Empty map should not be iterated');
    });
  }

  void test_forEachMap_oneElementMap() {
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

  void test_forEachMap_twoElementMap() {
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

  void test_hasKey() {
    var datum = makeDatum({
      'foo': 'bar'
    });
    expect(datum.hasKey('foo'), isTrue);
    expect(datum.hasKey('bar'), isFalse);
    expect(datum.hasKey('baz'), isFalse);
  }

  void test_hasKey_null() {
    expect(makeDatum(null).hasKey('foo'), isFalse);
  }

   void test_indexOperator_hasKey() {
    var indexResult = makeDatum({
      'foo': 'bar'
    })['foo'];
    expect(indexResult, isRequestDatum);
    expect(indexResult.datum, equals('bar'));
    expect(indexResult.path, equals('myPath.foo'));
  }

  void test_indexOperator_missingKey() {
    expect(() => makeDatum({
      'foo': 'bar'
    })['baz'], _throwsInvalidParameter);
  }

  void test_indexOperator_nonMap() {
    expect(() => makeDatum(1)['foo'], _throwsInvalidParameter);
  }

  void test_indexOperator_null() {
    expect(() => makeDatum(null)['foo'], _throwsInvalidParameter);
  }

  void test_isList() {
    expect(makeDatum(3).isList, isFalse);
    expect(makeDatum(null).isList, isTrue);
    expect(makeDatum([]).isList, isTrue);
    expect(makeDatum(['foo', 'bar']).isList, isTrue);
  }

  void test_isMap() {
    expect(makeDatum({
      'key1': 'value1',
      'key2': 'value2'
    }).isMap, isTrue);
    expect(makeDatum({}).isMap, isTrue);
    expect(makeDatum(null).isMap, isTrue);
    expect(makeDatum({
      'key1': 'value1',
      'key2': 2
    }).isMap, isTrue);
    expect(makeDatum({
      'key1': 1,
      'key2': 2
    }).isMap, isTrue);
    expect(makeDatum([]).isMap, isFalse);
  }

  void test_isStringList() {
    expect(makeDatum(['foo', 'bar']).isStringList, isTrue);
    expect(makeDatum([]).isStringList, isTrue);
    expect(makeDatum(null).isStringList, isTrue);
    expect(makeDatum(['foo', 1]).isStringList, isFalse);
    expect(makeDatum({}).isStringList, isFalse);
  }

  void test_isStringListMap() {
    expect(makeDatum({
      'key1': ['value11', 'value12'],
      'key2': ['value21', 'value22']
    }).isStringListMap, isTrue);
    expect(makeDatum({
      'key1': 10,
      'key2': 20
    }).isStringListMap, isFalse);
    expect(makeDatum({
      'key1': [11, 12],
      'key2': [21, 22]
    }).isStringListMap, isFalse);
    expect(makeDatum({}).isStringListMap, isTrue);
    expect(makeDatum(null).isStringListMap, isTrue);
    expect(makeDatum(3).isStringListMap, isFalse);
  }

  void test_isStringMap() {
    expect(makeDatum({
      'key1': 'value1',
      'key2': 'value2'
    }).isStringMap, isTrue);
    expect(makeDatum({}).isStringMap, isTrue);
    expect(makeDatum(null).isStringMap, isTrue);
    expect(makeDatum({
      'key1': 'value1',
      'key2': 2
    }).isStringMap, isFalse);
    expect(makeDatum({
      'key1': 1,
      'key2': 2
    }).isStringMap, isFalse);
    expect(makeDatum([]).isMap, isFalse);
  }

  static RequestDatum makeDatum(dynamic datum) {
    return new RequestDatum(request, 'myPath', datum);
  }
}


@ReflectiveTestCase()
class RequestErrorTest {
  void test_create() {
    RequestError error = new RequestError(42, 'msg');
    expect(error.code, 42);
    expect(error.message, "msg");
    expect(error.toJson(), equals({
      RequestError.CODE: 42,
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
    RequestError error = new RequestError(0, 'msg');
    error.setData('answer', 42);
    error.setData('question', 'unknown');
    expect(error.toJson(), {
      RequestError.CODE: 0,
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
    Request original = new Request('one', 'aMethod');
    original.setParameter('foo', 'bar');
    String json = JSON.encode(original.toJson());
    Request request = new Request.fromString(json);
    expect(request.id, equals('one'));
    expect(request.method, equals('aMethod'));
    expect(request.getParameter('foo', null).asString(), equals('bar'));
  }

  void test_getParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getParameter(name, null).datum, equals(value));
  }

   void test_getParameter_null() {
    String name = 'name';
    Request request = new Request('0', '');
    request.setParameter(name, null);
    expect(request.getParameter(name, 'default').datum, equals(null));
  }

  void test_getParameter_undefined() {
    String name = 'name';
    String defaultValue = 'default value';
    Request request = new Request('0', '');
    expect(request.getParameter(name, defaultValue).datum, equals(
        defaultValue));
  }

  void test_getRequiredParameter_defined() {
    String name = 'name';
    String value = 'value';
    Request request = new Request('0', '');
    request.setParameter(name, value);
    expect(request.getRequiredParameter(name).datum, equals(value));
  }

   void test_getRequiredParameter_null() {
    String name = 'name';
    Request request = new Request('0', '');
    request.setParameter(name, null);
    expect(request.getRequiredParameter(name).datum, equals(null));
  }

  void test_getRequiredParameter_undefined() {
    String name = 'name';
    Request request = new Request('0', '');
    expect(() => request.getRequiredParameter(name), _throwsRequestFailure);
  }

  void test_toJson() {
    Request request = new Request('one', 'aMethod');
    expect(request.toJson(), equals({
      Request.ID: 'one',
      Request.METHOD: 'aMethod'
    }));
  }

  void test_toJson_withParams() {
    Request request = new Request('one', 'aMethod');
    request.setParameter('foo', 'bar');
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
        'code': -1,
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
        'code': -4,
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
        'code': -5,
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
        'code': -11,
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
        'code': -6,
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
        'code': -7,
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
    expect(error.code, equals(-4));
    expect(error.message, equals('Invalid request'));
  }

  void test_fromJson_withResult() {
    Response original = new Response('myId');
    original.setResult('foo', 'bar');
    Response response = new Response.fromJson(original.toJson());
    expect(response.id, equals('myId'));
    Map<String, Object> result = response.result;
    expect(result.length, equals(1));
    expect(result['foo'], equals('bar'));
  }

  void test_setResult() {
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
}
