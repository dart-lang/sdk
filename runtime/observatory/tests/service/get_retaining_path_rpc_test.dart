// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass();
  var x;
  var y;
}

var target1 = new _TestClass();
var target2 = new _TestClass();
var target3 = new _TestClass();
var target4 = new _TestClass();
var target5 = new _TestClass();
var globalObject = new _TestClass();
var globalList = new List(100);
var globalMap1 = new Map();
var globalMap2 = new Map();

void warmup() {
  globalObject.x = target1;
  globalObject.y = target2;
  globalList[12] = target3;
  globalMap1['key'] = target4;
  globalMap2[target5] = 'value';
}

eval(Isolate isolate, String expression) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var tests = <IsolateTest>[
  // simple path
  (Isolate isolate) async {
    var obj = await eval(isolate, 'globalObject');
    var params = {
      'targetId': obj['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['elements'].length, equals(2));
    expect(result['elements'][1]['value']['name'], equals('globalObject'));
  },

  // missing limit.
  (Isolate isolate) async {
    var obj = await eval(isolate, 'globalObject');
    var params = {
      'targetId': obj['id'],
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data['details'],
          "_getRetainingPath expects the \'limit\' parameter");
    }
    expect(caughtException, isTrue);
  },

  (Isolate isolate) async {
    var target1 = await eval(
        isolate, '() { var tmp = target1; target1 = null; return tmp;} ()');
    var params = {
      'targetId': target1['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentField']['name'], equals('x'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target2 = await eval(
        isolate, '() { var tmp = target2; target2 = null; return tmp;} ()');
    var params = {
      'targetId': target2['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentField']['name'], equals('y'));
    expect(result['elements'][2]['value']['name'], equals('globalObject'));
  },

  (Isolate isolate) async {
    var target3 = await eval(
        isolate, '() { var tmp = target3; target3 = null; return tmp;} ()');
    var params = {
      'targetId': target3['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentListIndex'], equals(12));
    expect(result['elements'][2]['value']['name'], equals('globalList'));
  },

  (Isolate isolate) async {
    var target4 = await eval(
        isolate, '() { var tmp = target4; target4 = null; return tmp;} ()');
    var params = {
      'targetId': target4['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(
        result['elements'][1]['parentMapKey']['valueAsString'], equals('key'));
    expect(result['elements'][2]['value']['name'], equals('globalMap1'));
  },

  (Isolate isolate) async {
    var target5 = await eval(
        isolate, '() { var tmp = target5; target5 = null; return tmp;} ()');
    var params = {
      'targetId': target5['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(3));
    expect(result['elements'][1]['parentMapKey']['class']['name'],
        equals('_TestClass'));
    expect(result['elements'][2]['value']['name'], equals('globalMap2'));
  }
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
