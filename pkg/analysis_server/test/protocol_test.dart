// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.protocol;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';
import 'package:unittest/unittest.dart';

main() {
  group('Request', () {
    test('getParameter_defined', RequestTest.getParameter_defined);
    test('getParameter_undefined', RequestTest.getParameter_undefined);
    test('getRequiredParameter_defined', RequestTest.getRequiredParameter_defined);
    test('getRequiredParameter_undefined', RequestTest.getRequiredParameter_undefined);
    test('toJson', RequestTest.toJson);
  });
  group('Response', () {
    test('create_contextDoesNotExist', ResponseTest.create_contextDoesNotExist);
    test('create_invalidRequestFormat', ResponseTest.create_invalidRequestFormat);
    test('create_missingRequiredParameter', ResponseTest.create_missingRequiredParameter);
    test('create_unknownRequest', ResponseTest.create_unknownRequest);
    test('setResult', ResponseTest.setResult);
  });
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

  static void toJson() {
    Request original = new Request('one', 'aMethod');
    expect(original.toJson(), equals({
      Request.ID: 'one',
      Request.METHOD : 'aMethod'
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
}
