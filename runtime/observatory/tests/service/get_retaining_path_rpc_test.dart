// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass();
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
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

@pragma("vm:entry-point")
getGlobalObject() => globalObject;

@pragma("vm:entry-point")
takeTarget1() {
  var tmp = target1;
  target1 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget2() {
  var tmp = target2;
  target2 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget3() {
  var tmp = target3;
  target3 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget4() {
  var tmp = target4;
  target4 = null;
  return tmp;
}

@pragma("vm:entry-point")
takeTarget5() {
  var tmp = target5;
  target5 = null;
  return tmp;
}

@pragma("vm:entry-point")
getTrue() => true;

invoke(Isolate isolate, String selector) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'selector': selector,
    'argumentIds': <String>[],
  };
  return await isolate.invokeRpcNoUpgrade('invoke', params);
}

var tests = <IsolateTest>[
  // simple path
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getGlobalObject');
    var params = {
      'targetId': obj['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['gcRootType'], 'static fields table');
    expect(result['elements'].length, equals(1));
    expect(result['elements'][0]['value']['type'], equals('@Instance'));
  },

  // missing limit.
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getGlobalObject');
    var params = {
      'targetId': obj['id'],
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data['details'],
          "getRetainingPath expects the \'limit\' parameter");
    }
    expect(caughtException, isTrue);
  },

  (Isolate isolate) async {
    var target1 = await invoke(isolate, 'takeTarget1');
    var params = {
      'targetId': target1['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'static fields table');
    expect(result['elements'].length, equals(2));
    expect(result['elements'][0]['value']['type'], equals('@Instance'));
    expect(result['elements'][1]['parentField'], equals('x'));
  },

  (Isolate isolate) async {
    var target2 = await invoke(isolate, 'takeTarget2');
    var params = {
      'targetId': target2['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'static fields table');
    expect(result['elements'].length, equals(2));
    expect(result['elements'][1]['parentField'], equals('y'));
    expect(result['elements'][1]['value']['type'], equals('@Instance'));
  },

  (Isolate isolate) async {
    var target3 = await invoke(isolate, 'takeTarget3');
    var params = {
      'targetId': target3['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'static fields table');
    expect(result['elements'].length, equals(2));
    expect(result['elements'][1]['parentListIndex'], equals(12));
    expect(result['elements'][1]['value']['type'], equals('@Instance'));
  },

  (Isolate isolate) async {
    var target4 = await invoke(isolate, 'takeTarget4');
    var params = {
      'targetId': target4['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['gcRootType'], 'static fields table');
    expect(result['elements'].length, equals(2));
    expect(
        result['elements'][1]['parentMapKey']['valueAsString'], equals('key'));
    expect(result['elements'][1]['value']['type'], equals('@Instance'));
  },

  (Isolate isolate) async {
    var target5 = await invoke(isolate, 'takeTarget5');
    var params = {
      'targetId': target5['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(2));
    expect(result['elements'][1]['parentMapKey']['class']['name'],
        equals('_TestClass'));
    expect(result['elements'][1]['value']['type'], equals('@Instance'));
  },

  // object store
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getTrue');
    var params = {
      'targetId': obj['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['gcRootType'], 'isolate_object store');
    expect(result['elements'].length, 0);
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
